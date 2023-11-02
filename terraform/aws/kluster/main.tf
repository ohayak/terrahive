locals {
  cluster_version = "1.27"
}

# data "aws_ami" "eks_default_bottlerocket" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["bottlerocket-aws-k8s-${local.cluster_version}-x86_64-*"]
#   }
# }

data "aws_ami" "eks_ubuntu_amd64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_${local.cluster_version}/images/hvm-ssd/ubuntu-focal-20.04-amd64-*"]
  }
}

data "aws_ami" "windows_nvidia" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Tesla-*"]
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.cluster_name
  cluster_version = local.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true

  cluster_enabled_log_types = []

  # Encryption key
  create_kms_key = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = false
  kms_key_enable_default_policy   = true

  manage_aws_auth_configmap = true



  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
    # use_custom_launch_template must be true, otherwise SG and instance name won't be set
    # disk size must be set using block_device_mappings, defaults to 20
    use_custom_launch_template = true
    ami_type                   = "BOTTLEROCKET_x86_64"
    platform                   = "bottlerocket"
    desired_size               = 1
    min_size                   = 1
  }

  eks_managed_node_groups = {
    default = {
      name           = "${var.cluster_name}-default"
      instance_types = ["t3a.large"]
    }

    gpu = {
      subnet_ids             = var.public_subnets
      vpc_security_group_ids = [aws_security_group.turn.id, aws_security_group.signalserver.id]
      name                   = "${var.cluster_name}-gpu"
      instance_types         = ["g4dn.xlarge"]
      # AL2_x86_64_NVIDIA not working well some driver issues with pixel stream
      # ami_type       = "AL2_x86_64"
      # ami_type       = "AL2_x86_64"
      ami_id                     = data.aws_ami.eks_ubuntu_amd64.image_id
      ami_type                   = "CUSTOM"
      platform                   = "linux"
      enable_bootstrap_user_data = true
      min_size                   = var.min_gpu_nodes
      max_size                   = var.max_gpu_nodes
      block_device_mappings = {
        root = {
          device_name = "/dev/sda1" # Valid for Ubuntu
          ebs = {
            volume_size           = 60
            volume_type           = "gp2"
            delete_on_termination = true
          }
        }
      }
      labels = {
        "nvidia.com/gpu"    = "true"
        # "nos.nebuly.com/gpu-partitioning" = "mps"
        # "k8s.amazonaws.com/accelerator" = "vgpu"
      }

      taints = [
        {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NO_SCHEDULE"
        }
      ]
      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "true"
      }
    }
  }

  node_security_group_enable_recommended_rules = true

  # Extend cluster security group rules
  # cluster_security_group_additional_rules = {
  #   egress_nodes_ephemeral_ports_tcp = {
  #     protocol                   = "-1"
  #     from_port                  = 0
  #     to_port                    = 0
  #     type                       = "egress"
  #     source_node_security_group = true
  #   }
  # }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_api_to_nodes = {
      description                   = "Cluster API access to Kubernetes Node"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }


  cluster_tags = {
    Name = var.cluster_name
  }

}

resource "aws_security_group" "turn" {
  name_prefix = "${var.cluster_name}-turn-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 49152
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "signalserver" {
  name_prefix = "${var.cluster_name}-signalserver-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# Tags for the ASG to support cluster-autoscaler scale up from 0
################################################################################

locals {

  # We need to lookup K8s taint effect from the AWS API value
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  cluster_autoscaler_label_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for label_name, label_value in coalesce(group.node_group_labels, {}) : "${name}|label|${label_name}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
        value             = label_value,
      }
    }
  ]...)

  cluster_autoscaler_taint_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for taint in coalesce(group.node_group_taints, []) : "${name}|taint|${taint.key}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}"
        value             = "${taint.value}:${local.taint_effects[taint.effect]}"
      }
    }
  ]...)

  cluster_autoscaler_asg_tags = merge(local.cluster_autoscaler_label_tags, local.cluster_autoscaler_taint_tags)
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_label_taint" {
  for_each = local.cluster_autoscaler_asg_tags

  autoscaling_group_name = each.value.autoscaling_group

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_autodiscovry" {
  for_each = toset([
    "k8s.io/cluster-autoscaler/enabled",
    "k8s.io/cluster-autoscaler/${var.cluster_name}"
  ])
  autoscaling_group_name = module.eks.eks_managed_node_groups["gpu"].node_group_autoscaling_group_names[0]
  tag {
    key                 = each.key
    value               = "true"
    propagate_at_launch = false
  }
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

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

# data "aws_ami" "eks_nvidia_bottlerocket" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["bottlerocket-aws-k8s-${local.cluster_version}-nvidia-*"]
#   }
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

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
    use_custom_launch_template = false
    iam_role_use_name_prefix   = false
    ami_type                   = "BOTTLEROCKET_x86_64"
    platform                   = "bottlerocket"
    desired_size               = 0
    min_size                   = 0
  }

  eks_managed_node_groups = {
    default = {
      name           = "${var.cluster_name}-default"
      instance_types = ["t3a.large"]
      disk_size      = 40
    }

    turn = {
      name           = "${var.cluster_name}-turn"
      instance_types = ["t3a.small"]
      labels = {
        "app.pixels/turn" = "true"
      }

      taints = [
        {
          key    = "app.pixels/turn"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    gpu = {
      name           = "${var.cluster_name}-gpu"
      instance_types = ["g4dn.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64_NVIDIA"
      disk_size      = 40
      labels = {
        "nvidia.com/gpu" = "true"
      }

      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

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
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }


  cluster_tags = {
    Name = var.cluster_name
  }

}

data "aws_ami" "ubuntu_arm" {
  provider = aws.ec1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-arm64-server-*"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-ECS_Optimized-*"]
  }
}

module "ec2_security_group_ec1" {
  providers = {
    aws = aws.ec1
  }
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "dev-machine"
  vpc_id = data.aws_vpc.default_ec1.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
}

module "ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "dev-machine"
  vpc_id = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
}

data "cloudinit_config" "b64_user_data" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = <<EOT
      #cloud-config
      runcmd:
        # Install Docker
        - apt update
        - apt install -y ca-certificates curl gnupg
        - install -m 0755 -d /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - chmod a+r /etc/apt/keyrings/docker.gpg
        - | 
          echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        - apt update
        - apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        - service docker start
        - usermod -a -G docker ubuntu
        # Install Nvidia
        - curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
        - curl -fsSL https://nvidia.github.io/nvidia-docker/ubuntu20.04/nvidia-docker.list > /etc/apt/sources.list.d/nvidia-docker.list
        - apt update
        - apt install -y unzip gcc make linux-headers-$(uname -r) dpkg-dev xorg-dev mesa-utils libvulkan1 libvulkan-dev vulkan-utils libgtk-3-0
        - apt install -y nvidia-driver-535-server nvidia-utils-535-server nvidia-docker2
        - nvidia-ctk runtime configure --runtime=docker || true
        - service docker restart
        # Install P4 (helix-cli)
        - curl -fsSL https://package.perforce.com/perforce.pubkey | gpg --dearmor -o /etc/apt/keyrings/perforce-archive-keyring.gpg
        - |
          echo "deb [signed-by=/etc/apt/keyrings/perforce-archive-keyring.gpg] http://package.perforce.com/apt/ubuntu \
          $(lsb_release -c -s) release" | tee /etc/apt/sources.list.d/perforce.list > /dev/null
        - apt update
        - apt install -y helix-cli python-is-python3
        - echo 'export P4CONFIG="$HOME/.p4config"' >> /home/ubuntu/.bashrc
        - curl -fsSL https://git.kernel.org/pub/scm/git/git.git/plain/git-p4.py -o /usr/local/bin/git-p4
        - chmod +x /usr/local/bin/git-p4
    EOT
  }
}

data "aws_subnet" "ec1" {
  provider = aws.ec1
  availability_zone = "eu-central-1c"
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_ec1.id]
  }
}

data "aws_subnet" "ew1" {
  availability_zone = "eu-west-1a"
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


module "dev_instance_graviton" {
  count = 0
  providers = {
    aws = aws.ec1
  }
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name                    = "ubuntu-nvidia-32g-arm"
  ignore_ami_changes      = true
  disable_api_termination = true
  ebs_optimized = true  
  monitoring = true

  ami                    = data.aws_ami.ubuntu_arm.id
  instance_type          = "g5g.4xlarge"
  subnet_id              = data.aws_subnet.ec1.id
  vpc_security_group_ids = [module.ec2_security_group_ec1.security_group_id]
  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  user_data                   = data.cloudinit_config.b64_user_data.rendered
  user_data_replace_on_change = false
  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 500
    }
  ]
}


module "dev_instance_small" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name                    = "ubuntu-nvidia-16g"
  ignore_ami_changes      = true
  disable_api_termination = true
  ebs_optimized = true 
  monitoring = true

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "g4dn.xlarge"
  subnet_id              = data.aws_subnet.ew1.id
  vpc_security_group_ids = [module.ec2_security_group.security_group_id]
  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  user_data                   = data.cloudinit_config.b64_user_data.rendered
  user_data_replace_on_change = false
  root_block_device = [
    {
      volume_type = "gp3"
      throughput  = 250
      volume_size = 500
    },
  ]
}

module "key_pair_windows_devtools" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "windows-devtools"
  create_private_key = true
}

module "key_pair_secret" {
  source = "terraform-aws-modules/ssm-parameter/aws"

  name        = "windows-ssh-key"
  value       = module.key_pair_windows_devtools.private_key_pem
  secure_type = true
}


module "dev_instance_windows" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name                    = "windows-nvidia-32g"
  ignore_ami_changes      = true
  disable_api_termination = true
  ebs_optimized = true 
  monitoring = true
  key_name = module.key_pair_windows_devtools.key_pair_name

  ami                    = "ami-09717bf353cfe2743" # data.aws_ami.windows.id
  instance_type          = "g4dn.2xlarge"
  subnet_id              = data.aws_subnet.ew1.id
  vpc_security_group_ids = [module.ec2_security_group.security_group_id]
  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }
  user_data_replace_on_change = false
  root_block_device = [
    {
      volume_type = "gp3"
      throughput  = 250
      volume_size = 500
    },
  ]
}


module "dev_instance_windows_small" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name                    = "windows-nvidia-16g"
  ignore_ami_changes      = true
  disable_api_termination = true
  ebs_optimized = true 
  monitoring = true
  key_name = module.key_pair_windows_devtools.key_pair_name

  ami                    = data.aws_ami.windows.id
  instance_type          = "g4dn.xlarge"
  subnet_id              = data.aws_subnet.ew1.id
  vpc_security_group_ids = [module.ec2_security_group.security_group_id]
  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }
  user_data_replace_on_change = false
  root_block_device = [
    {
      volume_type = "gp3"
      throughput  = 250
      volume_size = 500
    },
  ]
}
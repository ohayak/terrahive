generate "kube_provider" {
  path      = "kube_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "cluster_name" {
  type = string
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}
EOF
}

dependency "kluster" {
  config_path                             = "${get_original_terragrunt_dir()}/../../cloud/kluster"
  mock_outputs_allowed_terraform_commands = get_terraform_commands_that_need_input()
  mock_outputs = {
    cluster_endpoint       = "fake"
    cluster_ca_certificate = "fake"
  }
}

inputs = {
  cluster_endpoint       = dependency.kluster.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.kluster.outputs.cluster_ca_certificate
}
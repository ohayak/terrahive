generate "k8s_provider" {
  path      = "k8s_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubernetes" {
  config_context = "${get_env("KUBE_CTX")}"
  config_path = "${get_env("KUBE_CONFIG_PATH")}"
}

provider "kubectl" {
  config_context = "${get_env("KUBE_CTX")}"
  config_path = "${get_env("KUBE_CONFIG_PATH")}"
}

provider "helm" {
  kubernetes {
    config_context = "${get_env("KUBE_CTX")}"
    config_path = "${get_env("KUBE_CONFIG_PATH")}"
  }
}
EOF
}

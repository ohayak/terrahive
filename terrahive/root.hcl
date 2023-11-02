inputs = {
  module   = basename(get_original_terragrunt_dir())
  vpc_cidr = "10.0.0.0/16"
  azs      = 2
}

terragrunt_version_constraint = "~> 0.48.0"
terraform_version_constraint  = "~> 1.5.0"

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }

    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.13.0"
    }

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
EOF
}
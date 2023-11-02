locals {
  script_version = get_env("SCRIPT_VERSION")
}

generate "aws_provider" {
  path      = "aws_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "sid" {
  type = string
}

variable "tenant" {
  type = string
}

variable "env" {
  type = string
}

variable "module" {
  type = string
}

variable "region" {
  type = string
}

provider "aws" {
  region = var.region
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  default_tags {
    tags = {
      managed-by = "terraform"
      sid        = var.sid
      tenant     = var.tenant
      env        = var.env
      module     = var.module
      script-version = "${local.script_version}"
    }
  }
}
EOF
}

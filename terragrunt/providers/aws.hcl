locals {
  env    = get_env("TF_VAR_env")
  tenant = get_env("TF_VAR_tenant")
  sid    = get_env("TF_VAR_sid")
  region = get_env("TF_VAR_region")
  cloud  = get_env("TF_VAR_cloud")
  hive   = basename(dirname(get_terragrunt_dir()))
  module = basename(get_terragrunt_dir())
}


generate "aws_provider" {
  path      = "aws_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  default_tags {
    tags = {
      sid        = "${local.sid}"
      tenant     = "${local.tenant}"
      env        = "${local.env}"
      managed-by = "terraform"
      module     = "${basename(get_terragrunt_dir())}"
      hive       = "${basename(dirname(get_terragrunt_dir()))}"
      script-version = "${get_env("SCRIPT_VERSION")}"
    }
  }
}
EOF
}

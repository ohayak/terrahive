data "aws_vpc" "default" {
  default = true
}

data "aws_vpc" "default_ec1" {
  provider = aws.ec1
  default = true
}


provider "aws" {
  alias = "ec1"
  region = "eu-central-1"
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
      script-version = "0.1.0"
    }
  }
}

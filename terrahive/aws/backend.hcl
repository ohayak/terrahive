locals {
  project = get_env("TF_VAR_project")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt                     = true
    bucket                      = "terraform-state-${local.project}"
    key                         = "${path_relative_to_include()}.tfstate"
    region                      = "eu-west-1"
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_credentials_validation = true
    disable_bucket_update       = true
  }
}
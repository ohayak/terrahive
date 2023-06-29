inputs = {
  env      = get_env("TF_VAR_env")
  hive     = get_env("TF_VAR_hive")
  module   = basename(get_original_terragrunt_dir())
  vpc_cidr = "10.0.0.0/16"
  azs      = 2
}

terragrunt_version_constraint = "~> 0.47.0"
terraform_version_constraint  = "~> 1.5.0"

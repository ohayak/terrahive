locals {
  dirs_to_hive = split("/", get_parent_terragrunt_dir())
  length       = length(local.dirs_to_hive)
  tenant       = local.dirs_to_hive[local.length - 2]
  sid          = local.dirs_to_hive[local.length - 1]
}

inputs = {
  region       = "eu-west-1"
  tenant       = local.tenant
  sid          = local.sid
  cluster_name = "${local.tenant}-${local.sid}"
  subdomain    = "${local.tenant}-${local.sid}.${get_env("TF_VAR_env")}.${get_env("TF_VAR_domain")}"
  max_gpu_nodes = 200 / 8
}
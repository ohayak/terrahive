include "root" {
  path = "../../../root.hcl"
}

include "env" {
  path = "../../env.hcl"
}

include "cloud_provider" {
  path = "${get_repo_root()}/terragrunt/providers/${get_env("TF_VAR_cloud")}.hcl"
}

include "backend" {
  path = "${get_repo_root()}/terragrunt/backend/${get_env("TF_VAR_cloud")}.hcl"
}

include "module" {
  path = "${get_repo_root()}/terragrunt/${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}.hcl"
}

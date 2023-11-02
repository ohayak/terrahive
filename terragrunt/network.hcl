terraform {
  source = "${get_repo_root()}/terraform//${get_env("TF_VAR_cloud")}/network"
}

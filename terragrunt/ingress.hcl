terraform {
  source = "${get_repo_root()}/terraform//k8s/ingress"
}

dependency "secretstore" {
  config_path                             = "${get_repo_root()}/terrahive/${get_env("TF_VAR_cloud")}/${get_env("TF_VAR_env")}/secretstore" 
  mock_outputs_allowed_terraform_commands = get_terraform_commands_that_need_input()
}

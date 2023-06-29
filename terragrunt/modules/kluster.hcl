terraform {
  source = "${get_repo_root()}/terraform//${get_env("TF_VAR_cloud")}/kluster"
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_allowed_terraform_commands = get_terraform_commands_that_need_input()
  mock_outputs = {
    vpc_id             = "12345"
    private_subnet_ids = ["1234", "123456", "1234567"]
    intra_subnet_ids   = ["1234", "123456", "1234567"]
  }
}

inputs = {
  vpc_id          = dependency.network.outputs.vpc_id
  private_subnets = dependency.network.outputs.private_subnet_ids
  intra_subnets   = dependency.network.outputs.intra_subnet_ids
}

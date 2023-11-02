terraform {
  source = "${get_repo_root()}/terraform//aws/devtools"
}

inputs = {
  region = "eu-west-1"
  tenant = "nps"
  sid    = "ew1"
}
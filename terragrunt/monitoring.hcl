terraform {
  source = "${get_repo_root()}/terraform//k8s/monitoring"
}


dependencies {
  paths = [
    "${get_original_terragrunt_dir()}/../ingress"
  ]
}
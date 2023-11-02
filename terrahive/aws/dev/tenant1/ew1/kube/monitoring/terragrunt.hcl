include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

include "hive" {
  path = find_in_parent_folders("hive.hcl")
}

include "kube" {
  path = find_in_parent_folders("kube.hcl")
}

include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

include "module" {
  path = "${get_repo_root()}/terragrunt/${basename(get_terragrunt_dir())}.hcl"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

include "module" {
  path = "${get_repo_root()}/terragrunt/${basename(get_terragrunt_dir())}.hcl"
}

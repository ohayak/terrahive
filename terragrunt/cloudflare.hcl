generate "cloudflare_provider" {
  path      = "cloudflare_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "dns_solver_token" {
  type      = string
  sensitive = true
}

provider "cloudflare" {
  api_token = var.dns_solver_token
}
EOF
}

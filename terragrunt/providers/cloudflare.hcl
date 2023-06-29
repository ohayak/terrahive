generate "cloudflare_provider" {
  path      = "cloudflare_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.8.0"
    }
  }
}
EOF
}

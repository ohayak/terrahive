output "dockerconfigjson" {
  sensitive = true
  value = {
    auths = {
      "${var.docker_registry_endpoint}" = {
        "auth" = base64encode("${var.docker_registry_username}:${var.docker_registry_password}")
      }
    }
  }
}

output "dns_solver_token" {
  sensitive = true
  value     = var.cloudflare_api_token
}

output "noreplay_email_credentials" {
  sensitive = true
  value = {
    "email" : var.noreply_email
    "password" : var.noreply_email_password
  }
}

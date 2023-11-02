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
  value     = var.dns_solver_token
}

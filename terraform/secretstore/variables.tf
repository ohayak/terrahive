variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "noreply_email" {
  type      = string
  sensitive = true
}

variable "noreply_email_password" {
  type      = string
  sensitive = true
}

variable "docker_registry_password" {
  type      = string
  sensitive = true
}

variable "docker_registry_username" {
  type      = string
  sensitive = true
}

variable "docker_registry_endpoint" {
  type = string
}

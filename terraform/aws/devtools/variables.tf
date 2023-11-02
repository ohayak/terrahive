variable "domain" {
  type = string
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
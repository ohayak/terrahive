variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(any)
}

variable "private_subnets" {
  type = list(any)
}

variable "intra_subnets" {
  type = list(any)
}

variable "cluster_name" {
  type = string
}

variable "subdomain" {
  type = string
}
variable "domain" {
  type = string
}

variable "max_gpu_nodes" {
  type    = number
  default = 3
}

variable "min_gpu_nodes" {
  type    = number
  default = 1
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = number
  default = 2
}

variable "cluster_name" {
  type = string
}

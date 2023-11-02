output "vpc_id" {
  description = "vpc_id"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "private_subnet_ids"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "public_subnet_ids"
  value       = module.vpc.public_subnets
}

output "intra_subnet_ids" {
  description = "intra_subnet_ids"
  value       = module.vpc.intra_subnets
}

output "availability_zones" {
  description = "availability_zones"
  value       = module.vpc.azs
}

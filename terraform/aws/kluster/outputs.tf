output "cluster_name" {
  description = "cluster_name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "cluster_endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "cluster_arn"
  value       = module.eks.cluster_arn
}

output "cluster_ca_certificate" {
  description = "cluster_ca_certificate"
  sensitive   = true
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "cluster_oidc_issuer_url"
  value       = module.eks.cluster_oidc_issuer_url
}

output "kube_ctx" {
  value = local.kube_ctx
}

output "max_gpu_nodes" {
  value = var.max_gpu_nodes
}

# output "storage_bucket_name" {
#   value = aws_s3_bucket.storage.id
# }

# output "storage_bucket_domain_name" {
#   value = aws_s3_bucket.storage.bucket_domain_name
# }

# output "storage_bucket_arn" {
#   value = aws_s3_bucket.storage.arn
# }

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
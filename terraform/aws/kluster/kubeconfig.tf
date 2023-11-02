data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  kube_ctx = "${module.eks.cluster_name}-${var.env}"
}

resource "null_resource" "kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl config delete-context ${local.kube_ctx} || true
      aws eks update-kubeconfig \
      --region ${var.region} \
      --name ${module.eks.cluster_name} \
      --alias ${local.kube_ctx} \
      --role-arn ${data.aws_iam_session_context.current.issuer_arn}
    EOT
  }

  triggers = {
    timestamp = timestamp()
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

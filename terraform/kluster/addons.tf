resource "terraform_data" "helm_repo_update" {
  provisioner "local-exec" {
    command     = "./add-helm-repos.sh"
    interpreter = ["bash", "-c"]
  }
}

module "eks_blueprints_addons" {
  depends_on = [terraform_data.helm_repo_update]
  source     = "aws-ia/eks-blueprints-addons/aws"
  version    = "1.0.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    chart_version = "47.0.0"
  }

  enable_metrics_server = true
  metrics_server = {
    chart_version = "3.10.0"
  }

  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    chart_version = "9.29.1"
  }

  enable_ingress_nginx = true
  ingress_nginx = {
    chart_version = "4.7.0"
  }
}

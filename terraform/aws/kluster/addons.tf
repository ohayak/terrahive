module "eks_blueprints_addons" {
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.eks]
  source     = "aws-ia/eks-blueprints-addons/aws"
  version    = "1.3.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }

    # `endpoint_pod_names` this coredns parametre enables POD discovery 
    # using it's pod name when coupled with headless service
    coredns = {
      addon_version = "v1.10.1-eksbuild.2"
      configuration_values = jsonencode({
        corefile = <<-EOT
          .:53 {
              errors
              health
              ready
              kubernetes cluster.local in-addr.arpa ip6.arpa {
                  pods insecure
                  fallthrough in-addr.arpa ip6.arpa
                  ttl 30
                  endpoint_pod_names
              }
              prometheus :9153
              forward . /etc/resolv.conf
              cache 30
              loop
              reload
              loadbalance
          }    
        EOT
      })
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    repository    = "https://aws.github.io/eks-charts"
    chart_version = "1.5.5"
    set = [
      {
        name  = "vpcId"
        value = var.vpc_id
      },
      {
        name  = "clusterName"
        value = module.eks.cluster_name
      }
    ]
  }

  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    repository    = "https://kubernetes.github.io/autoscaler"
    chart_version = "9.29.1"
    set = [
      {
        name  = "autoDiscovery.clusterName"
        value = module.eks.cluster_name
      },
      {
        name  = "awsRegion"
        value = var.region
      }

    ]
    #   enable_aws_node_termination_handler = true
    #   aws_node_termination_handler = {
    #     chart_version = "0.21.0"
    #     values = [
    #         <<-EOT
    #         replicas: 2
    #         enablePrometheusServer: true
    #         enableSpotInterruptionDraining: true
    #         enableRebalanceMonitoring: true
    #         enableScheduledEventDraining: true
    #         taintNode: true
    #         emitKubernetesEvents: true
    #         EOT
    #       ]
    #   }

    #   aws_node_termination_handler_sqs = {
    #     create = false
    #   }
  }
}



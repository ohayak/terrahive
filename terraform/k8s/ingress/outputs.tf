data "kubernetes_service_v1" "ingress_nginx" {
  depends_on = [helm_release.nginx]
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.main.metadata[0].name
  }
}

locals {
  lb_hostname = data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
}

output "lb_hostname" {
  value = local.lb_hostname
}

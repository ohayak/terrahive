resource "kubernetes_ingress_v1" "grafana_ingress" {
  depends_on = [helm_release.prometheus]
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "monitoring.${var.subdomain}"
      http {
        path {
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                name = "http-web"
              }
            }
          }
        }
      }
    }
  }
}

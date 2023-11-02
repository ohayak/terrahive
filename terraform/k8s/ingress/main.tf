resource "kubernetes_namespace" "main" {
  metadata {
    name = "ingress"
  }
}

data "cloudflare_zone" "domain" {
  name = var.domain
}

resource "cloudflare_record" "ingress" {
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = "*.${var.subdomain}"
  value           = local.lb_hostname
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "cloudflare_certificate_pack" "ingress" {
  zone_id = data.cloudflare_zone.domain.zone_id
  type    = "advanced"
  hosts = [
    "monitoring.${var.subdomain}",
    "boringapp.${var.subdomain}",
    "*.boringapp.${var.subdomain}"
  ]
  validation_method      = "txt"
  validity_days          = 90
  certificate_authority  = "google"
  cloudflare_branding    = false
  wait_for_active_status = false
}


resource "helm_release" "nginx" {
  # depends_on = [kubernetes_config_map.udp_services, kubernetes_config_map.tcp_services]
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.main.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.7.1"
  wait       = true
  values = [<<-EOT
    controller:
      # extraArgs:
      #   default-ssl-certificate: ${kubernetes_namespace.main.metadata[0].name}/subdomain-cert
      service:
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-name: ${var.cluster_name}-ingress
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
          service.beta.kubernetes.io/aws-load-balancer-type: external
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      config:
        use-forwarded-headers: true
        compute-full-forwarded-for: true

    EOT
  ]
}

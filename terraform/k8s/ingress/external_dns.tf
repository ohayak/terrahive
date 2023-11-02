# resource "kubernetes_secret_v1" "dns_solver_token" {
#   metadata {
#     name      = "dns-solver-token"
#     namespace = kubernetes_namespace.main.metadata[0].name
#   }
#   data = {
#     cloudflare_api_token = var.dns_solver_token
#   }
# }

# resource "helm_release" "external_dns" {
#   name       = "external-dns"
#   namespace  = kubernetes_namespace.main.metadata[0].name
#   repository = "https://kubernetes-sigs.github.io/external-dns"
#   version    = "1.13.0"
#   chart      = "external-dns"
#   values = [<<-EOT
#     policy: sync
#     txtPrefix: "extdns.${var.subdomain}."
#     provider: cloudflare
#     env:
#       - name: CF_API_TOKEN
#         value: ${var.dns_solver_token}
#     domainFilters:
#       - ${var.domain}
#     sources:
#       - service
#     EOT
#   ]
# }

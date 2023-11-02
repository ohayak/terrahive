# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   namespace  = kubernetes_namespace.main.metadata[0].name
#   repository = "https://charts.jetstack.io"
#   version    = "1.12.3"
#   chart      = "cert-manager"
#   values = [<<-EOT
#     installCRDs: true
#     extraArgs:
#       - "--dns01-recursive-nameservers-only"
#     EOT
#   ]
# }

# resource "kubectl_manifest" "cluster_issuer" {
#   depends_on = [
#     helm_release.cert_manager
#   ]
#   yaml_body = <<EOF
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-prod
# spec:
#   acme:
#     email: tech@oniverse.io
#     privateKeySecretRef:
#       name: letsencrypt-prod
#     server: https://acme-v02.api.letsencrypt.org/directory
#     solvers:
#       - dns01:
#           cloudflare:
#             email: tech@oniverse.io
#             apiTokenSecretRef:
#               name: ${kubernetes_secret_v1.dns_solver_token.metadata[0].name}
#               key: cloudflare_api_token
#         selector:
#           dnsZones:
#             - "${var.domain}"
# EOF
# }

# resource "kubectl_manifest" "subdomain-cert" {
#   depends_on = [
#     kubectl_manifest.cluster_issuer
#   ]

#   yaml_body = yamlencode({
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "subdomain-cert"
#       namespace = "${kubernetes_namespace.main.metadata[0].name}"
#     }
#     spec = {
#       dnsNames = [
#         "${var.subdomain}",
#         "*.${var.subdomain}",
#       ]
#       issuerRef = {
#         name = "letsencrypt-prod"
#         kind = "ClusterIssuer"
#         # used with origin-ca
#         # group = "cert-manager.k8s.cloudflare.com"
#       }
#       secretName = "subdomain-cert"
#     }
#   })
# }

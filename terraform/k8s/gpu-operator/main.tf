resource "kubernetes_namespace" "main" {
  metadata {
    name = "gpu-operator"
  }
}

resource "helm_release" "nvidia_operator" {
  name       = "nvidia"
  namespace  = kubernetes_namespace.main.metadata[0].name
  repository = "https://nvidia.github.io/gpu-operator"
  chart      = "gpu-operator"
  version    = "v23.6.1"
  wait       = true
  # Provide driver version as image digest. The operator will not apply OS version suffix in that case
  # version: 535.104.05-centos7
  # version: sha256:15a2ccf991af5497ffaf4b62df7d3f30b256f7e689b06149d5c7fd3cf2565934
  values = [<<-EOT
    driver:
      enabled: true
    migManager:
      enabled: false
    toolkit:
      enabled: true
    devicePlugin:
      enabled: true
    EOT
  ]
}


# resource "helm_release" "device_plugin" {
#   depends_on = [ helm_release.nvidia_operator ]
#   name       = "nebuly-nvidia"
#   namespace  = kubernetes_namespace.main.metadata[0].name
#   chart      = "./nebuly-vgpu-plugin"
#   version    = "0.13.0"
#   wait       = true
#   values = [<<-EOT
#     config:
#       name: {}
#       map:
#         default: |-
#           flags:
#             migStrategy: none
#           sharing:
#             mps: 
#               failRequestsGreaterThanOne: true
#               resources:
#                 - name: nvidia.com/gpu
#                   rename: nvidia.com/gpu-6gb
#                   memoryGB: 6
#                   replicas: 4
#                   devices: ["0"]
#     nfd:
#       enabled: false
#     gfd:
#       enabled: false
#     EOT
#   ]
# }

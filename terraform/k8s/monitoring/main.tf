resource "kubernetes_namespace" "main" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "gpu-dashboard.json" = file("dashboards/gpu.json")
  }
}

resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.main.metadata[0].name
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "48.3.1"
  wait       = true
  values = [<<-EOT
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        additionalScrapeConfigs:
        # scrap with annotations
        - job_name: kubernetes-service-endpoints
          scrape_interval: 10s
          scrape_timeout: 10s
          kubernetes_sd_configs:
          - role: endpoints
          relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            separator: ;
            regex: "true"
            replacement: $1
            action: keep
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            separator: ;
            regex: (https?)
            target_label: __scheme__
            replacement: $1
            action: replace
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            separator: ;
            regex: (.+)
            target_label: __metrics_path__
            replacement: $1
            action: replace
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            separator: ;
            regex: ([^:]+)(?::\d+)?;(\d+)
            target_label: __address__
            replacement: $1:$2
            action: replace
          - separator: ;
            regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
            replacement: __param_$1
            action: labelmap
          - separator: ;
            regex: __meta_kubernetes_service_label_(.+)
            replacement: $1
            action: labelmap
          - source_labels: [__meta_kubernetes_namespace]
            separator: ;
            regex: (.*)
            target_label: namespace
            replacement: $1
            action: replace
          - source_labels: [__meta_kubernetes_service_name]
            separator: ;
            regex: (.*)
            target_label: service
            replacement: $1
            action: replace
          - source_labels: [__meta_kubernetes_pod_node_name]
            separator: ;
            regex: (.*)
            target_label: node
            replacement: $1
            action: replace
    
        # general pod scraping
        - job_name: kubernetes-pods
          scrape_interval: 10s
          kubernetes_sd_configs:
          - role: pod
          relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            separator: ;
            regex: "true"
            replacement: $1
            action: keep
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
            separator: ;
            regex: (https?)
            target_label: __scheme__
            replacement: $1
            action: replace
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            separator: ;
            regex: (.+)
            target_label: __metrics_path__
            replacement: $1
            action: replace
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            separator: ;
            regex: ([^:]+)(?::\d+)?;(\d+)
            target_label: __address__
            replacement: $1:$2
            action: replace
          - separator: ;
            regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
            replacement: __param_$1
            action: labelmap
          - separator: ;
            regex: __meta_kubernetes_pod_label_(.+)
            replacement: $1
            action: labelmap
          - source_labels: [__meta_kubernetes_namespace]
            separator: ;
            regex: (.*)
            target_label: namespace
            replacement: $1
            action: replace
          - source_labels: [__meta_kubernetes_pod_name]
            separator: ;
            regex: (.*)
            target_label: pod
            replacement: $1
            action: replace
          - source_labels: [__meta_kubernetes_pod_phase]
            separator: ;
            regex: Pending|Succeeded|Failed|Completed
            replacement: $1
            action: drop
          - source_labels: [__meta_kubernetes_pod_container_name]
            action: replace
            target_label: container

    grafana:
      dashboardsConfigMaps:
        kubernetes: ${kubernetes_config_map.grafana_dashboards.metadata[0].name}
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
          - name: 'default'
            orgId: 1
            folder: ''
            type: file
            disableDeletion: true
            allowUiUpdates: true
            options:
              path: /var/lib/grafana/dashboards
      dashboards:
        default:
          nvidia-dashboard:
            gnetId: 12239
            revision: 2
            datasource:
            - name: DS_PROMETHEUS
              value: Prometheus
    EOT
  ]
}

# resource "helm_release" "nvidia_operator" {
#   depends_on = [helm_release.prometheus]
#   name       = "nvidia"
#   namespace  = kubernetes_namespace.main.metadata[0].name
#   repository = "https://nvidia.github.io/gpu-operator"
#   chart      = "gpu-operator"
#   wait       = true
#   values = [<<-EOT
#     driver:
#       enabled: false
#     migManager:
#       enabled: false
#     EOT
#   ]
# }


# resource "helm_release" "dgcm_exporter" {
#   depends_on = [helm_release.prometheus]
#   name       = "dgcm-exporter"
#   namespace  = kubernetes_namespace.main.metadata[0].name
#   repository = "https://nvidia.github.io/dcgm-exporter/helm-charts"
#   chart      = "dcgm-exporter"
#   version    = "3.1.5"
#   wait       = true
#   values = [<<-EOT
#     podAnnotations:
#       prometheus.io/scrape: "true"
#       prometheus.io/port: "9400"

#     nodeSelector:
#       nvidia.com/gpu: "true"
#     EOT
#   ]
# }
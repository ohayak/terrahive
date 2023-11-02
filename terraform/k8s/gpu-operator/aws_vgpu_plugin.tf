resource "kubernetes_daemonset" "aws_vgpu_device_plugin" {
  metadata {
    name      = "aws-vgpu-device-plugin"
    namespace =  "kube-system"
  }

  spec {
    selector {
      match_labels = {
        name = "aws-vgpu-device-plugin"
      }
    }

    template {
      metadata {
        # This annotation is deprecated. Kept here for backward compatibility
        # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
        annotations = {
          "scheduler.alpha.kubernetes.io/critical-pod" = ""
        }

        labels = {
          name = "aws-vgpu-device-plugin"
        }
      }

      spec {
        volume {
          name = "device-plugin"

          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }

        volume {
          name = "nvidia-mps"

          host_path {
            path = "/tmp/nvidia-mps"
          }
        }

        volume {
          name = "run-nvidia-validations"
          host_path {
            path = "/run/nvidia/validations"
            type = "DirectoryOrCreate"
          }
        }

        init_container {
          name    = "set-compute-mode"
          image   = "nvidia/cuda:11.4.3-base-ubuntu20.04"
          command = ["nvidia-smi", "-c", "EXCLUSIVE_PROCESS"]

          security_context {
            capabilities {
              add = ["SYS_ADMIN"]
            }
          }
        }


        init_container {
          name    = "plugin-validator"
          image   = "busybox"
          args = ["/bin/sh", "-c", "touch /run/nvidia/validations/plugin-ready"]
          volume_mount {
            name = "run-nvidia-validations"
            mount_path = "/run/nvidia/validations"
          }

        }
        container {
          name  = "aws-vgpu-device-plugin"
          image = "amazon/aws-virtual-gpu-device-plugin:v0.1.1"

          # Max number of mps clients is 48 for a turing architecture
          # (https://docs.nvidia.com/deploy/mps/index.html#topic_3_3_5_1)
          args = ["/usr/bin/vgpu-device-plugin", "--vgpu=3"]

          volume_mount {
            name       = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }

          security_context {
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        container {
          name  = "mps"
          image = "nvidia/mps"

          env {
            name  = "CUDA_MPS_ACTIVE_THREAD_PERCENTAGE"
            value = "33"
          }

          volume_mount {
            name       = "nvidia-mps"
            mount_path = "/tmp/nvidia-mps"
          }
        }

        node_selector = {
          "nvidia.com/gpu.count" = "1"
          "nvidia.com/gpu-driver-upgrade-state" = "upgrade-done"
          "k8s.amazonaws.com/accelerator"    = "vgpu"
        }

        host_ipc = true

        # This toleration is deprecated. Kept here for backward compatibility
        # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }

        toleration {
          key      = "k8s.amazonaws.com/vgpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        # Mark this pod as a critical add-on; when enabled, the critical add-on
        # scheduler reserves resources for critical add-on pods so that they can
        # be rescheduled after a failure.
        # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
        priority_class_name = "system-node-critical"
      }
    }

    strategy {
      type = "RollingUpdate"
    }
  }
}
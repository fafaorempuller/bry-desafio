resource "kubernetes_namespace" "whoami_namespace" {
  metadata {
    name = "whoami"
  }
}

resource "kubernetes_deployment" "whoami_app" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.whoami_namespace.metadata[0].name
    labels = {
      app = "whoami"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "whoami"
      }
    }
    template {
      metadata {
        labels = {
          app = "whoami"
        }
      }
      spec {
        container {
          name  = "whoami"
          image = "jwilder/whoami"
          port {
            container_port = 8000
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8000
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami_service" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.whoami_namespace.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.whoami_app.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8000
    }
  }
}

resource "kubernetes_ingress_v1" "whoami_ingress" {
  metadata {
    name      = "whoami-ingress"
    namespace = kubernetes_namespace.whoami_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"      = "traefik"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }
  spec {
    rule {
      host = var.dominio_app
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.whoami_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      hosts       = [var.dominio_app]
      secret_name = "whoami-tls"
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  depends_on = [kubernetes_namespace.whoami_namespace] # Depende do namespace existir
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${var.email_contato}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
YAML
}

resource "kubernetes_network_policy" "whoami_network_policy" {
  metadata {
    name      = "whoami-allow-ingress"
    namespace = kubernetes_namespace.whoami_namespace.metadata[0].name
  }
  spec {
    pod_selector {
      match_labels = {
        app = kubernetes_deployment.whoami_app.metadata[0].labels.app
      }
    }
    policy_types = ["Ingress"]
    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "traefik"
          }
        }
      }
    }
  }
}


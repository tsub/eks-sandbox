resource "kubernetes_namespace" "app-2048" {
  depends_on = [module.eks.cluster_id]

  metadata {
    name = "2048-game"
  }
}

resource "kubernetes_deployment" "app-2048" {
  metadata {
    name      = "2048-deployment"
    namespace = kubernetes_namespace.app-2048.metadata[0].name

    labels = {
      name = "2048"
    }
  }

  spec {
    replicas = 5

    selector {
      match_labels = {
        name = "2048"
      }
    }

    template {
      metadata {
        labels = {
          name = "2048"
        }
      }

      spec {
        container {
          image             = "alexwhen/docker-2048"
          image_pull_policy = "Always"
          name              = "2048"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app-2048" {
  metadata {
    name      = "service-2048"
    namespace = kubernetes_namespace.app-2048.metadata[0].name
  }

  spec {
    selector = {
      name = "2048"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

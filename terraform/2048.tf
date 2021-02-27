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

resource "aws_acm_certificate" "app-2048" {
  domain_name       = "2048.sandbox.tsub.me"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "app-2048" {
  certificate_arn         = aws_acm_certificate.app-2048.arn
  validation_record_fqdns = [for record in aws_route53_record.app-2048-validation : record.fqdn]
}

resource "aws_route53_record" "app-2048-validation" {
  for_each = {
    for dvo in aws_acm_certificate.app-2048.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]

  zone_id = aws_route53_zone.sandbox.zone_id
  ttl     = "300"
}

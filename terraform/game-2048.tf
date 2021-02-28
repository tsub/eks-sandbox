resource "kubernetes_namespace" "game-2048" {
  depends_on = [module.eks.cluster_id]

  metadata {
    name = "game-2048"
  }
}

resource "kubernetes_deployment" "game-2048" {
  metadata {
    name      = "deployment-2048"
    namespace = kubernetes_namespace.game-2048.metadata[0].name
  }

  spec {
    replicas = 5

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app-2048"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app-2048"
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

resource "kubernetes_service" "game-2048" {
  metadata {
    name      = "service-2048"
    namespace = kubernetes_namespace.game-2048.metadata[0].name
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "app-2048"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "aws_lb_target_group" "game-2048" {
  name        = "${var.cluster_name}-game-2048"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener_rule" "game-2048" {
  listener_arn = aws_lb_listener.main-https.arn

  condition {
    host_header {
      values = ["2048.${var.route53_sandbox_zone}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.game-2048.arn
  }
}

resource "aws_lb_listener_certificate" "redash" {
  listener_arn    = aws_lb_listener.main-https.arn
  certificate_arn = aws_acm_certificate_validation.game-2048.certificate_arn
}

resource "null_resource" "target-group-binding-2048" {
  depends_on = [helm_release.aws-load-balancer-controller]

  triggers = {
    manifest = yamlencode({
      apiVersion = "elbv2.k8s.aws/v1beta1"
      kind       = "TargetGroupBinding"

      metadata = {
        name      = "target-group-binding-2048"
        namespace = "game-2048"
      }

      spec = {
        serviceRef = {
          name = "service-2048"
          port = 80
        }

        networking = {
          ingress = [{
            from = [{
              securityGroup = {
                groupID = aws_security_group.alb.id
              }
            }]

            ports = [{
              port = 80
            }]
          }]
        }

        targetGroupARN = aws_lb_target_group.game-2048.arn
        targetType     = "ip"
      }
    })
  }

  provisioner "local-exec" {
    command = "echo '${self.triggers.manifest}' | kubectl apply -f -"

    environment = {
      KUBECONFIG = "${path.module}/${module.eks.kubeconfig_filename}"
    }
  }
}

resource "aws_acm_certificate" "game-2048" {
  domain_name       = "2048.${var.route53_sandbox_zone}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "game-2048" {
  certificate_arn         = aws_acm_certificate.game-2048.arn
  validation_record_fqdns = [for record in aws_route53_record.game-2048-validation : record.fqdn]
}

resource "aws_route53_record" "game-2048-validation" {
  for_each = {
    for dvo in aws_acm_certificate.game-2048.domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "game-2048" {
  name    = "2048.${var.route53_sandbox_zone}"
  type    = "A"
  zone_id = aws_route53_zone.sandbox.zone_id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

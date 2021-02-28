output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.game-2048.certificate_arn
}

output "cluster_name" {
  value = var.cluster_name
}

output "route53_zone" {
  value = var.route53_sandbox_zone
}

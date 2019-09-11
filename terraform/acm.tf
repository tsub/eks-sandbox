resource "aws_acm_certificate" "app-2048" {
  domain_name       = "2048.sandbox.tsub.me"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "app-2048" {
  certificate_arn         = aws_acm_certificate.app-2048.arn
  validation_record_fqdns = [aws_route53_record.app-2048-validation.fqdn]
}

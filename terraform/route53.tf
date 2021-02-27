resource "aws_route53_zone" "sandbox" {
  name          = local.route53_zone
  force_destroy = true
}

# For ACM

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

  zone_id         = aws_route53_zone.sandbox.zone_id
  ttl             = "300"
  allow_overwrite = false
}

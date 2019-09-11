resource "aws_route53_zone" "sandbox" {
  name          = "${local.route53_zone}"
  force_destroy = true
}

# For ACM

resource "aws_route53_record" "app-2048-validation" {
  zone_id         = "${aws_route53_zone.sandbox.zone_id}"
  name            = "${aws_acm_certificate.app-2048.domain_validation_options.0.resource_record_name}"
  type            = "${aws_acm_certificate.app-2048.domain_validation_options.0.resource_record_type}"
  ttl             = "300"
  allow_overwrite = false

  records = ["${aws_acm_certificate.app-2048.domain_validation_options.0.resource_record_value}"]
}

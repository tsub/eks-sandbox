output "acm_certificate_arn" {
  value = "${aws_acm_certificate_validation.2048.certificate_arn}"
}

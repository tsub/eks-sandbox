output "acm_certificate_arn" {
  value = "${aws_acm_certificate_validation.2048.certificate_arn}"
}

output "cluster_name" {
  value = "${local.cluster_name}"
}

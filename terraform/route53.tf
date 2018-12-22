resource "aws_route53_zone" "sandbox" {
  name          = "${local.route53_zone}"
  force_destroy = true
}

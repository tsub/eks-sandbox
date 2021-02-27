locals {
  cluster_name         = "tsub-sandbox"
  route53_sandbox_zone = "sandbox.tsub.me"
  route53_main_zone    = "tsub.me"
  account_id           = data.aws_caller_identity.current.account_id
  oidc_provider        = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

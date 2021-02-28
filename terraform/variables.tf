variable "main_aws_profile" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "route53_main_zone" {
  type = string
}

variable "route53_sandbox_zone" {
  type = string
}

variable "aws_chatbot_arn_for_slack" {
  type = string
}

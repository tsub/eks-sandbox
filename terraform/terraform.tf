terraform {
  required_version = "v0.14.7"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.30.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tsub-sandbox"

    workspaces {
      name = "eks-sandbox"
    }
  }
}

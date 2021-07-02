terraform {
  required_version = "v1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.48.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.3"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.0.3"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }

  backend "local" {}

  # backend "s3" {
  #   bucket         = "tsub-tfstate"
  #   key            = "eks-sandbox/terraform.tfstate"
  #   dynamodb_table = "tsub-tfstate-locking"
  # }
}

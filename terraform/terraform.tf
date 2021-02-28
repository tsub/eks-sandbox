terraform {
  required_version = "v0.14.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.30.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.0.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }

  backend "s3" {
    bucket         = "tsub-tfstate"
    key            = "eks-sandbox/terraform.tfstate"
    dynamodb_table = "tsub-tfstate-locking"
  }
}

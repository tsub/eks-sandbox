terraform {
  required_version = "v0.12.8"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tsub-sandbox"

    workspaces {
      name = "eks-sandbox"
    }
  }
}

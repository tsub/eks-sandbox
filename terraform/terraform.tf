terraform {
  required_version = "v0.11.14"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tsub-sandbox"

    workspaces {
      name = "eks-sandbox"
    }
  }
}

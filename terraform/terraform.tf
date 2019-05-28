terraform {
  required_version = "v0.11.14"

  backend "s3" {
    bucket = "tsub-tfstate"
    key    = "eks-sandbox"
    region = "ap-northeast-1"
  }
}

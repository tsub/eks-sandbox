terraform {
  backend "s3" {
    bucket = "tsub-tfstate"
    key    = "eks-sandbox"
    region = "ap-northeast-1"
  }
}

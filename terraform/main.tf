module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.49.0"

  name = "tsub-sandbox"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "2.0.0"
  cluster_name    = "tsub-sandbox"
  subnets         = ["${module.vpc.public_subnets}"]
  vpc_id          = "${module.vpc.vpc_id}"

  worker_groups = [{
    asg_desired_capacity = 3
    instance_type        = "t2.small"
  }]

  config_output_path = "../kubernetes/"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

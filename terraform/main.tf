module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "tsub-sandbox"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  public_subnets  = ["10.0.96.0/20", "10.0.112.0/20", "10.0.128.0/20"]

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "14.0.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.19"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    main = {
      desired_capacity = 3
      instance_types   = ["t3.small"]
      subnets          = module.vpc.private_subnets
    }
  }

  config_output_path = "../kubernetes/"
  enable_irsa        = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route53_zone" "sandbox" {
  name          = local.route53_sandbox_zone
  force_destroy = true
}

resource "aws_route53_record" "sandbox-ns" {
  provider = aws.main

  name    = local.route53_sandbox_zone
  type    = "NS"
  records = aws_route53_zone.sandbox.name_servers
  zone_id = data.aws_route53_zone.main.zone_id
  ttl     = "300"
}

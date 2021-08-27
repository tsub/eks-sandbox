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
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "17.4.0"
  cluster_name       = var.cluster_name
  cluster_version    = "1.19"
  subnets            = module.vpc.public_subnets
  vpc_id             = module.vpc.vpc_id
  enable_irsa        = true
  config_output_path = "./kubeconfig"

  node_groups = {
    main = {
      desired_capacity = 3
      instance_types   = ["t3.small"]
      subnets          = module.vpc.private_subnets
    }
  }

  map_roles = [{
    rolearn  = replace(aws_iam_role.deployment-pipeline-codebuild.arn, "service-role/", "")
    username = "deployment-pipeline-codebuild"
    groups   = ["system:masters"]
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route53_zone" "sandbox" {
  name          = var.route53_sandbox_zone
  force_destroy = true
}

resource "aws_route53_record" "sandbox-ns" {
  provider = aws.main

  name    = var.route53_sandbox_zone
  type    = "NS"
  records = aws_route53_zone.sandbox.name_servers
  zone_id = data.aws_route53_zone.main.zone_id
  ttl     = "300"
}

resource "aws_lb" "main" {
  name               = var.cluster_name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.cluster_name}-alb"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_listener" "main-http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "main-https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.game-2048.certificate_arn # dummy

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}


provider "aws" {
  region = "us-west-2"
}

module "nlb" {
  source = "../../"

  name               = "example-nlb-tls"
  internal           = false
  vpc_id             = data.aws_vpc.default.id
  subnets            = data.aws_subnets.public.ids

  # TLS Listener
  listeners = {
    tls = {
      port            = 443
      protocol        = "TLS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = data.aws_acm_certificate.example.arn
      default_action = {
        type             = "forward"
        target_group_key = "main"
      }
    }
  }

  # Target Group
  target_groups = {
    main = {
      name        = "example-tg-tls"
      port        = 443
      protocol    = "TLS"
      target_type = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 3
        interval           = 30
        port               = 443
        protocol           = "HTTPS"
        timeout            = 10
        unhealthy_threshold = 3
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_acm_certificate" "example" {
  domain = "example.com"
}

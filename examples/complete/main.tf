# Complete ALB Example with multiple features
# This example demonstrates various features of the ALB module including:
# - Multiple listeners with rules
# - Multiple target groups
# - Health checks
# - Access logging
# - WAF integration
# - Custom security groups

provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "complete-alb-example-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "complete-example-alb-sg"
  description = "Security group for ALB with HTTP/HTTPS"
  vpc_id      = module.vpc.vpc_id

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

  tags = {
    Name = "complete-example-alb-sg"
  }
}

# ACM Certificate
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "example.com"
  zone_id     = "Z1234567890" # Replace with your Route53 zone ID

  wait_for_validation = true

  tags = {
    Environment = "dev"
  }
}

# S3 Bucket for Access Logs
module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "complete-example-alb-logs"
  acl    = "private"

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "log_expiration"
      enabled = true
      expiration = {
        days = 90
      }
    }
  ]

  # ALB access log policy
  attach_elb_log_delivery_policy = true
}

# Application Load Balancer
module "alb" {
  source = "../../"

  name               = "complete-example-alb"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.vpc.public_subnets
  vpc_id            = module.vpc.vpc_id

  # Enable deletion protection for production
  enable_deletion_protection = true

  # Enable cross-zone load balancing
  enable_cross_zone_load_balancing = true

  # Enable HTTP/2
  enable_http2 = true

  # Configure access logs
  access_logs_enabled = true
  access_logs_bucket  = module.log_bucket.s3_bucket_id
  access_logs_prefix  = "alb-logs"

  # Configure listeners
  listeners = {
    # HTTP listener with redirect to HTTPS
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    # HTTPS listener
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
      certificate_arn = module.acm.acm_certificate_arn
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Welcome to the ALB!"
          status_code  = "200"
        }
      }
    }
  }

  # Configure target groups
  target_groups = {
    # Main application target group
    app = {
      name        = "app-target-group"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path               = "/health"
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 6
        protocol          = "HTTP"
        matcher           = "200-399"
      }
      stickiness = {
        enabled         = true
        cookie_duration = 86400
        type           = "lb_cookie"
      }
    }
    # API target group
    api = {
      name        = "api-target-group"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path               = "/api/health"
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout            = 6
        protocol          = "HTTP"
        matcher           = "200"
      }
    }
  }

  # Configure listener rules
  listener_rules = {
    # Static files rule
    static = {
      listener_key = "https"
      priority     = 10
      actions = [
        {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Static content"
            status_code  = "200"
          }
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/static/*"]
          }
        }
      ]
    }
    # API rule
    api = {
      listener_key = "https"
      priority     = 20
      actions = [
        {
          type             = "forward"
          target_group_key = "api"
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/api/*"]
          }
        }
      ]
    }
    # Host-based routing rule
    host = {
      listener_key = "https"
      priority     = 30
      actions = [
        {
          type             = "forward"
          target_group_key = "app"
        }
      ]
      conditions = [
        {
          host_header = {
            values = ["app.example.com"]
          }
        }
      ]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "complete-example"
  }
}

# Outputs
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.lb_dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = module.alb.lb_zone_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.alb.target_group_arns
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = module.alb.listener_arns["https"]
}

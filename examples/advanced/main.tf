# Advanced ALB Example
# This example creates a complex ALB with multiple target groups, routing rules, and microservices architecture

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Data sources for existing VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "alb-advanced-sg-"
  vpc_id      = data.aws_vpc.default.id

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
    Name = "alb-advanced-security-group"
  }
}

# S3 bucket for access logs
resource "aws_s3_bucket" "logs" {
  bucket = "alb-access-logs-${random_string.suffix.result}"

  tags = {
    Name = "ALB Access Logs"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket policy for ALB access logs
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.logs.arn}/*"
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# ALB Module
module "alb" {
  source = "../../"

  name               = "advanced-alb-example"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids
  vpc_id             = data.aws_vpc.default.id

  # Access logs
  access_logs_enabled = true
  access_logs_bucket  = aws_s3_bucket.logs.id
  access_logs_prefix  = "alb-logs"

  # Enable additional features
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60

  # Listeners
  listeners = {
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
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
      certificate_arn = null # Set this to your ACM certificate ARN for production
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "No matching route found"
          status_code  = "404"
        }
      }
    }
  }

  # Target Groups for different services
  target_groups = {
    # Frontend application
    frontend-tg = {
      name        = "frontend-target-group"
      port        = 3000
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }

    # Backend API
    backend-tg = {
      name        = "backend-target-group"
      port        = 8080
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/api/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }

    # Admin panel
    admin-tg = {
      name        = "admin-target-group"
      port        = 4000
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/admin/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }

    # Static content (could be served by CDN or static server)
    static-tg = {
      name        = "static-target-group"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }
  }

  # Listener Rules for routing
  listener_rules = {
    # Frontend routes
    frontend-rule = {
      listener_key = "https"
      priority     = 100
      actions = [
        {
          type             = "forward"
          target_group_key = "frontend-tg"
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/", "/app/*", "/dashboard/*"]
          }
        }
      ]
    }

    # API routes
    api-rule = {
      listener_key = "https"
      priority     = 200
      actions = [
        {
          type             = "forward"
          target_group_key = "backend-tg"
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/api/*", "/v1/*", "/v2/*"]
          }
        }
      ]
    }

    # Admin routes
    admin-rule = {
      listener_key = "https"
      priority     = 300
      actions = [
        {
          type             = "forward"
          target_group_key = "admin-tg"
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/admin/*", "/management/*"]
          }
        }
      ]
    }

    # Static content routes
    static-rule = {
      listener_key = "https"
      priority     = 400
      actions = [
        {
          type             = "forward"
          target_group_key = "static-tg"
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/static/*", "/assets/*", "/images/*", "/css/*", "/js/*"]
          }
        }
      ]
    }

    # Health check endpoint
    health-rule = {
      listener_key = "https"
      priority     = 500
      actions = [
        {
          type = "fixed-response"
          fixed_response = {
            content_type = "application/json"
            message_body = jsonencode({
              status = "healthy"
              timestamp = "2024-01-01T00:00:00Z"
            })
            status_code = "200"
          }
        }
      ]
      conditions = [
        {
          path_pattern = {
            values = ["/health", "/ping"]
          }
        }
      ]
    }

    # Maintenance mode (example of redirect action)
    maintenance-rule = {
      listener_key = "https"
      priority     = 600
      actions = [
        {
          type = "redirect"
          redirect = {
            host        = "maintenance.example.com"
            path        = "/"
            port        = "443"
            protocol    = "HTTPS"
            query       = ""
            status_code = "HTTP_302"
          }
        }
      ]
      conditions = [
        {
          http_header = {
            http_header_name = "X-Maintenance-Mode"
            values           = ["true"]
          }
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "advanced-alb-module"
    ManagedBy   = "terraform"
    Component   = "load-balancer"
  }
} 
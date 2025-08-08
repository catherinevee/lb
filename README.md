# AWS Load Balancer Terraform Module

Creates AWS Network Load Balancers with TCP/TLS listeners and target groups. Handles common use cases including SSL termination, health checks, and traffic routing.

## Requirements

| Name | Version |
|------|---------|
| terraform | 1.13.0 |
| aws | 6.2.0 |
| terragrunt | 0.84.0 |

## What This Module Manages

| Resource | Purpose | Notes |
|----------|---------|--------|
| `aws_lb` | Load balancer instance | Network or Application type |
| `aws_lb_listener` | Port listeners for traffic routing | Supports HTTP, HTTPS, TCP, TLS |
| `aws_lb_target_group` | Backend target definitions | Instance, IP, or Lambda targets |

## Resources Not Included

You'll need to manage these separately:
- CloudWatch alarms and dashboards
- VPC Flow Logs for network debugging  
- Route 53 DNS records (use the `lb_dns_name` output)

## Resource Naming

Resources created by this module use the following naming convention:

| Resource | Format | Example |
|----------|--------|---------|
| Load Balancer | `{var.name}` | `my-application-lb` |
| Listener | `{var.name}-listener-{key}` | `my-application-lb-listener-https` |
| Target Group | `{target_group.name}` | `app-target-group` |

## Key Features

- Internal or internet-facing load balancers
- HTTP/HTTPS/TCP/TLS listener support with SSL termination
- Multiple target types: EC2 instances, IP addresses, Lambda functions
- Path and host-based routing rules with priority handling
- S3 access logging (configure bucket permissions separately)
- Security group and WAF integration
- Standard AWS tagging patterns

## Usage

### Basic Load Balancer

```hcl
module "alb" {
  source = "./lb"

  name               = "my-application-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  vpc_id             = aws_vpc.main.id

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Production Setup with HTTPS Redirect

```hcl
module "alb" {
  source = "./lb"

  name               = "my-application-lb"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  vpc_id             = aws_vpc.main.id

  # S3 bucket must exist with proper bucket policy
  access_logs_enabled = true
  access_logs_bucket  = aws_s3_bucket.logs.id
  access_logs_prefix  = "alb-logs"

  # Force HTTP to HTTPS - common security requirement
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
      certificate_arn = aws_acm_certificate.main.arn
      default_action = {
        type             = "forward"
        target_group_arn = "app-tg"
      }
    }
  }

  # Backend services
  target_groups = {
    app-tg = {
      name        = "app-target-group"
      port        = 80
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
    api-tg = {
      name        = "api-target-group"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"  # For container workloads
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
  }

  # Register targets with specific groups
  target_group_attachments = {
    app-instance-1 = {
      target_group_key = "app-tg"
      target_id        = aws_instance.app1.id
    }
    app-instance-2 = {
      target_group_key = "app-tg"
      target_id        = aws_instance.app2.id
    }
    api-container-1 = {
      target_group_key = "api-tg"
      target_id        = "10.0.1.10"  # Container IP
    }
  }

  # Path-based routing - evaluated by priority
  listener_rules = {
    api-rule = {
      listener_key = "https"
      priority     = 100  # Lower numbers = higher priority
      actions = [
        {
          type             = "forward"
          target_group_key = "api-tg"
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
    static-rule = {
      listener_key = "https"
      priority     = 200
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
  }

  tags = {
    Environment = "production"
    Project     = "my-app"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_lb | Controls if the ALB should be created | `bool` | `true` | no |
| name | Name of the Application Load Balancer | `string` | n/a | yes |
| internal | If true, the ALB will be internal | `bool` | `false` | no |
| security_groups | List of security group IDs for the ALB | `list(string)` | `[]` | no |
| subnets | List of subnet IDs for the ALB | `list(string)` | `[]` | no |
| vpc_id | VPC ID where the ALB will be created | `string` | n/a | yes |
| enable_deletion_protection | If true, deletion protection will be enabled | `bool` | `false` | no |
| enable_cross_zone_load_balancing | If true, cross-zone load balancing will be enabled | `bool` | `true` | no |
| enable_http2 | If true, HTTP/2 will be enabled | `bool` | `true` | no |
| idle_timeout | The time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| enable_waf_fail_open | If true, WAF fail open will be enabled | `bool` | `false` | no |
| drop_invalid_header_fields | If true, invalid header fields will be dropped | `bool` | `false` | no |
| preserve_host_header | If true, the host header will be preserved | `bool` | `false` | no |
| access_logs_bucket | S3 bucket for access logs | `string` | `null` | no |
| access_logs_prefix | S3 prefix for access logs | `string` | `null` | no |
| access_logs_enabled | If true, access logs will be enabled | `bool` | `false` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |
| listeners | Map of listener configurations | `map(object)` | `{}` | no |
| target_groups | Map of target group configurations | `map(object)` | `{}` | no |
| target_group_attachments | Map of target group attachment configurations | `map(object)` | `{}` | no |
| listener_rules | Map of listener rule configurations | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | The ID of the Application Load Balancer |
| lb_arn | The ARN of the Application Load Balancer |
| lb_dns_name | The DNS name of the Application Load Balancer |
| lb_zone_id | The canonical hosted zone ID of the Application Load Balancer |
| lb_arn_suffix | The ARN suffix of the Application Load Balancer |
| lb_name | The name of the Application Load Balancer |
| listener_ids | The IDs of the Application Load Balancer Listeners |
| listener_arns | The ARNs of the Application Load Balancer Listeners |
| target_group_ids | The IDs of the Target Groups |
| target_group_arns | The ARNs of the Target Groups |
| target_group_names | The names of the Target Groups |
| listener_rule_ids | The IDs of the Listener Rules |
| listener_rule_arns | The ARNs of the Listener Rules |

## Examples

### HTTP to HTTPS Redirect

```hcl
module "alb_basic" {
  source = "./lb"

  name            = "basic-alb"
  internal        = false
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public[*].id
  vpc_id          = aws_vpc.main.id

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
      certificate_arn = aws_acm_certificate.main.arn
      default_action = {
        type             = "forward"
        target_group_arn = "app-tg"
      }
    }
  }

  target_groups = {
    app-tg = {
      name        = "app-target-group"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
    }
  }
}
```

### Internal Load Balancer for Microservices

```hcl
module "alb_internal" {
  source = "./lb"

  name            = "internal-alb"
  internal        = true
  security_groups = [aws_security_group.alb_internal.id]
  subnets         = aws_subnet.private[*].id
  vpc_id          = aws_vpc.main.id

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "No matching route"
          status_code  = "404"
        }
      }
    }
  }

  target_groups = {
    frontend-tg = {
      name        = "frontend-tg"
      port        = 3000
      protocol    = "HTTP"
      target_type = "ip"  # Common for ECS/EKS workloads
    }
    backend-tg = {
      name        = "backend-tg"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
    }
  }

  listener_rules = {
    frontend-rule = {
      listener_key = "http"
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
            values = ["/", "/app/*"]
          }
        }
      ]
    }
    backend-rule = {
      listener_key = "http"
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
            values = ["/api/*"]
          }
        }
      ]
    }
  }
}
```

## Important Notes

### Security Groups
Configure appropriate inbound rules - ALBs don't automatically allow traffic

### SSL Certificates
Use ACM certificates for HTTPS listeners. Certificate must be in same region as load balancer

### S3 Access Logs
Requires bucket policy allowing ELB service to write. See AWS documentation for region-specific ELB account IDs

### Health Checks
Set realistic intervals and thresholds. Frequent checks can impact backend performance

### Costs
Cross-zone load balancing incurs additional data transfer charges for NLBs

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.
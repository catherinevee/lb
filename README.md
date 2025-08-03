# AWS Network Load Balancer Terraform Module

This Terraform module creates a comprehensive AWS Network Load Balancer (NLB) with support for TCP/TLS listeners and target groups. It follows AWS best practices and HashiCorp's Terraform Registry standards.

## Requirements

| Name | Version |
|------|---------|
| terraform | 1.13.0 |
| aws | 6.2.0 |
| terragrunt | 0.84.0 |

## Resource Map

This module manages the following AWS resources:

| Category | Resource | Purpose | Managed By Module |
|----------|----------|---------|------------------|
| Load Balancer | `aws_lb.this` | Network Load Balancer instance | Yes |
| Networking | `aws_lb_listener.this` | TCP/TLS listeners for the NLB | Yes |
| Target Management | `aws_lb_target_group.this` | Target groups for backend services | Yes |
| Health Checks | Health Check configuration | Configures TCP/HTTP health checks | Yes |
| Monitoring | CloudWatch Metrics | Load balancer metrics and alarms | No |
| Logging | VPC Flow Logs | Network traffic logging | No |
| DNS | Route 53 Aliases | DNS records for the NLB | No |

## Resource Types

This module creates the following AWS resources:

| Resource Type | Purpose |
|--------------|---------|
| `aws_lb` | Network Load Balancer instance |
| `aws_lb_listener` | TCP/TLS listeners for handling Layer 4 traffic |
| `aws_lb_target_group` | Target groups for routing traffic to backend targets |

## Resource Naming

Resources created by this module use the following naming convention:

| Resource | Format | Example |
|----------|--------|---------|
| Load Balancer | `{var.name}` | `my-application-lb` |
| Listener | `{var.name}-listener-{key}` | `my-application-lb-listener-https` |
| Target Group | `{target_group.name}` | `app-target-group` |

## Features

- **Application Load Balancer**: Create internal or internet-facing ALBs
- **Listeners**: Support for HTTP, HTTPS, and TCP listeners with SSL/TLS termination
- **Target Groups**: Multiple target group types (instance, IP, lambda) with health checks
- **Listener Rules**: Advanced routing rules with multiple conditions and actions
- **Access Logs**: Optional S3 access logging
- **Security**: Integration with security groups and WAF
- **Tags**: Comprehensive tagging support for cost management

## Usage

### Basic Example

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

### Complete Example with Listeners and Target Groups

```hcl
module "alb" {
  source = "./lb"

  name               = "my-application-lb"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  vpc_id             = aws_vpc.main.id

  # Access logs configuration
  access_logs_enabled = true
  access_logs_bucket  = aws_s3_bucket.logs.id
  access_logs_prefix  = "alb-logs"

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
      certificate_arn = aws_acm_certificate.main.arn
      default_action = {
        type             = "forward"
        target_group_arn = "app-tg"
      }
    }
  }

  # Target Groups
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
      target_type = "ip"
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

  # Target Group Attachments
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
      target_id        = "10.0.1.10"
    }
  }

  # Listener Rules
  listener_rules = {
    api-rule = {
      listener_key = "https"
      priority     = 100
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

### Basic ALB with HTTP to HTTPS Redirect

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

### Internal ALB for Microservices

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
      target_type = "ip"
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

## Security Considerations

1. **Security Groups**: Always configure appropriate security groups for the ALB
2. **SSL/TLS**: Use HTTPS listeners with proper SSL policies for production workloads
3. **Access Logs**: Enable access logs for monitoring and compliance
4. **WAF Integration**: Consider integrating with AWS WAF for additional security
5. **Deletion Protection**: Enable deletion protection for production load balancers

## Best Practices

1. **Naming Convention**: Use consistent naming conventions for all resources
2. **Tagging**: Implement comprehensive tagging for cost management and resource tracking
3. **Health Checks**: Configure appropriate health check paths and intervals
4. **Target Groups**: Use appropriate target types (instance, IP, lambda) based on your architecture
5. **Listener Rules**: Organize rules by priority and use specific path patterns
6. **Monitoring**: Set up CloudWatch alarms for ALB metrics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.
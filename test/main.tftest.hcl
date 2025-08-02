run "verify_alb_creation" {
  command = plan

  variables {
    name            = "test-alb"
    internal        = false
    vpc_id          = "vpc-12345678"
    subnets         = ["subnet-12345678", "subnet-87654321"]
    security_groups = ["sg-12345678"]
  }

  assert {
    condition     = aws_lb.this[0].name == "test-alb"
    error_message = "ALB name does not match input"
  }

  assert {
    condition     = aws_lb.this[0].internal == false
    error_message = "ALB internal flag does not match input"
  }

  assert {
    condition     = aws_lb.this[0].load_balancer_type == "application"
    error_message = "ALB type is not application"
  }
}

run "verify_listener_creation" {
  command = plan

  variables {
    name            = "test-alb"
    internal        = false
    vpc_id          = "vpc-12345678"
    subnets         = ["subnet-12345678", "subnet-87654321"]
    security_groups = ["sg-12345678"]
    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "OK"
            status_code  = "200"
          }
        }
      }
    }
  }

  assert {
    condition     = aws_lb_listener.this["http"].port == 80
    error_message = "HTTP listener port does not match input"
  }
}

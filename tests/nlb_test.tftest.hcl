variables {
  vpc_id = "vpc-12345678"
  subnets = ["subnet-12345678", "subnet-87654321"]
  name = "test-nlb"
}

run "validate_nlb_creation" {
  command = plan

  assert {
    condition = aws_lb.this[0].load_balancer_type == "network"
    error_message = "Load balancer type must be 'network'"
  }

  assert {
    condition = aws_lb.this[0].name == var.name
    error_message = "Load balancer name does not match input"
  }
}

run "validate_target_group" {
  command = plan

  assert {
    condition = alltrue([
      for key, tg in aws_lb_target_group.this : (
        tg.protocol == "TCP" || tg.protocol == "TLS"
      )
    ])
    error_message = "Target group protocol must be either TCP or TLS for Network Load Balancer"
  }
}

run "validate_listener" {
  command = plan

  assert {
    condition = alltrue([
      for key, listener in aws_lb_listener.this : (
        listener.protocol == "TCP" || listener.protocol == "TLS"
      )
    ])
    error_message = "Listener protocol must be either TCP or TLS for Network Load Balancer"
  }
}

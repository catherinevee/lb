# Target Groups
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      port               = health_check.value.port
      protocol           = health_check.value.protocol
      timeout            = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_group_attachments

  target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id        = each.value.target_id
  port             = each.value.port
}

# Network Load Balancer Listeners
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this[0].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = try(each.value.ssl_policy, null)
  certificate_arn   = try(each.value.certificate_arn, null)

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type             = default_action.value.type
      target_group_arn = try(aws_lb_target_group.this[default_action.value.target_group_key].arn, null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-listener-${each.key}"
    }
  )
}

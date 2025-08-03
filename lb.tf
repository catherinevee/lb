# Network Load Balancer
resource "aws_lb" "this" {
  count = var.create_lb ? 1 : 0

  name               = var.name
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnets

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type
  customer_owned_ipv4_pool        = var.customer_owned_ipv4_pool

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = var.access_logs_enabled
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
      Environment = var.environment
      Terraform   = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

output "lb_id" {
  description = "Load balancer ID"
  value       = try(aws_lb.this[0].id, null)
}

output "lb_arn" {
  description = "Load balancer ARN"
  value       = try(aws_lb.this[0].arn, null)
}

output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = try(aws_lb.this[0].dns_name, null)
}

output "lb_zone_id" {
  description = "Load balancer Route53 zone ID"
  value       = try(aws_lb.this[0].zone_id, null)
}

output "lb_arn_suffix" {
  description = "Load balancer ARN suffix for CloudWatch metrics"
  value       = try(aws_lb.this[0].arn_suffix, null)
}

output "lb_name" {
  description = "Load balancer name"
  value       = try(aws_lb.this[0].name, null)
}

output "listener_ids" {
  description = "Listener IDs by key"
  value       = { for k, v in aws_lb_listener.this : k => v.id }
}

output "listener_arns" {
  description = "Listener ARNs by key"
  value       = { for k, v in aws_lb_listener.this : k => v.arn }
}

output "target_group_ids" {
  description = "Target group IDs by key"
  value       = { for k, v in aws_lb_target_group.this : k => v.id }
}

output "target_group_arns" {
  description = "Target group ARNs by key"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_names" {
  description = "Target group names by key"
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}

output "listener_rule_ids" {
  description = "Listener rule IDs by key"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.id }
}

output "listener_rule_arns" {
  description = "Listener rule ARNs by key"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.arn }
} 
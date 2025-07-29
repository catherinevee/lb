output "lb_id" {
  description = "The ID of the Application Load Balancer"
  value       = try(aws_lb.this[0].id, null)
}

output "lb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = try(aws_lb.this[0].arn, null)
}

output "lb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = try(aws_lb.this[0].dns_name, null)
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the Application Load Balancer"
  value       = try(aws_lb.this[0].zone_id, null)
}

output "lb_arn_suffix" {
  description = "The ARN suffix of the Application Load Balancer"
  value       = try(aws_lb.this[0].arn_suffix, null)
}

output "lb_name" {
  description = "The name of the Application Load Balancer"
  value       = try(aws_lb.this[0].name, null)
}

output "listener_ids" {
  description = "The IDs of the Application Load Balancer Listeners"
  value       = { for k, v in aws_lb_listener.this : k => v.id }
}

output "listener_arns" {
  description = "The ARNs of the Application Load Balancer Listeners"
  value       = { for k, v in aws_lb_listener.this : k => v.arn }
}

output "target_group_ids" {
  description = "The IDs of the Target Groups"
  value       = { for k, v in aws_lb_target_group.this : k => v.id }
}

output "target_group_arns" {
  description = "The ARNs of the Target Groups"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_names" {
  description = "The names of the Target Groups"
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}

output "listener_rule_ids" {
  description = "The IDs of the Listener Rules"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.id }
}

output "listener_rule_arns" {
  description = "The ARNs of the Listener Rules"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.arn }
} 
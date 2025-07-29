output "alb_id" {
  description = "The ID of the Application Load Balancer"
  value       = module.alb.lb_id
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = module.alb.lb_arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.lb_dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the Application Load Balancer"
  value       = module.alb.lb_zone_id
}

output "listener_ids" {
  description = "The IDs of the Application Load Balancer Listeners"
  value       = module.alb.listener_ids
}

output "listener_arns" {
  description = "The ARNs of the Application Load Balancer Listeners"
  value       = module.alb.listener_arns
}

output "target_group_ids" {
  description = "The IDs of the Target Groups"
  value       = module.alb.target_group_ids
}

output "target_group_arns" {
  description = "The ARNs of the Target Groups"
  value       = module.alb.target_group_arns
}

output "target_group_names" {
  description = "The names of the Target Groups"
  value       = module.alb.target_group_names
}

output "listener_rule_ids" {
  description = "The IDs of the Listener Rules"
  value       = module.alb.listener_rule_ids
}

output "listener_rule_arns" {
  description = "The ARNs of the Listener Rules"
  value       = module.alb.listener_rule_arns
}

output "access_logs_bucket" {
  description = "The S3 bucket used for ALB access logs"
  value       = aws_s3_bucket.logs.id
} 
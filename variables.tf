variable "create_lb" {
  description = "Controls if the Network Load Balancer should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the Network Load Balancer"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.name))
    error_message = "Load balancer name must contain only alphanumeric characters and hyphens."
  }

  validation {
    condition     = length(var.name) <= 32
    error_message = "Load balancer name cannot exceed 32 characters."
  }
}

variable "environment" {
  description = "Environment tag for all resources"
  type        = string
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be: dev, staging, or prod."
  }
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing (NLB only, incurs data transfer costs)"
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "IP address type for load balancer subnets"
  type        = string
  default     = "ipv4"
  
  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "IP address type must be 'ipv4' or 'dualstack'."
  }
}

variable "customer_owned_ipv4_pool" {
  description = "Customer owned IPv4 pool ID for Outposts"
  type        = string
  default     = null
}

variable "internal" {
  description = "Create internal load balancer (private subnets only)"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "Security group IDs for ALB (required for Application Load Balancers)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.security_groups) > 0
    error_message = "At least one security group required for ALB."
  }

  validation {
    condition     = alltrue([for sg in var.security_groups : can(regex("^sg-[a-zA-Z0-9]+$", sg))])
    error_message = "Invalid security group ID format."
  }
}

variable "subnets" {
  description = "Subnet IDs for load balancer placement"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Prevent accidental load balancer deletion"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing (NLB only, incurs data transfer costs)"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2 protocol (ALB only)"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_waf_fail_open" {
  description = "Allow traffic when WAF is unreachable"
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid HTTP header fields"
  type        = bool
  default     = false
}

variable "preserve_host_header" {
  description = "Preserve original Host header in X-Forwarded-Host"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs (bucket must exist)"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 key prefix for access logs"
  type        = string
  default     = null
}

variable "access_logs_enabled" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Listener variables
variable "listeners" {
  description = "Listener configuration map"
  type = map(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    default_action = object({
      type             = string
      target_group_arn = optional(string)
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
      redirect = optional(object({
        host        = string
        path        = string
        port        = string
        protocol    = string
        query       = string
        status_code = string
      }))
    })
  }))
  default = {}
}

# Target group variables
variable "target_groups" {
  description = "Target group configuration map"
  type = map(object({
    name        = string
    port        = number
    protocol    = string
    target_type = string
    health_check = optional(object({
      enabled             = bool
      healthy_threshold   = number
      interval            = number
      matcher             = string
      path                = string
      port                = string
      protocol            = string
      timeout             = number
      unhealthy_threshold = number
    }))
    stickiness = optional(object({
      cookie_duration = number
      cookie_name     = string
      enabled         = bool
      type            = string
    }))
  }))
  default = {}
}

# Target group attachment variables
variable "target_group_attachments" {
  description = "Map of target group attachment configurations"
  type = map(object({
    target_group_key = string
    target_id        = string
    port             = optional(number)
  }))
  default = {}
}

# Listener rule variables
variable "listener_rules" {
  description = "Map of listener rule configurations"
  type = map(object({
    listener_key = string
    priority     = number
    actions = list(object({
      type             = string
      target_group_key = optional(string)
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
      redirect = optional(object({
        host        = string
        path        = string
        port        = string
        protocol    = string
        query       = string
        status_code = string
      }))
    }))
    conditions = list(object({
      host_header = optional(object({
        values = list(string)
      }))
      path_pattern = optional(object({
        values = list(string)
      }))
      http_header = optional(object({
        http_header_name = string
        values           = list(string)
      }))
      http_request_method = optional(object({
        values = list(string)
      }))
      query_string = optional(object({
        key   = string
        value = string
      }))
      source_ip = optional(object({
        values = list(string)
      }))
    }))
  }))
  default = {}
}
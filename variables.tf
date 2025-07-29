variable "create_lb" {
  description = "Controls if the ALB should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "internal" {
  description = "If true, the ALB will be internal"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "enable_deletion_protection" {
  description = "If true, deletion protection will be enabled"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing will be enabled"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "If true, HTTP/2 will be enabled"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "enable_waf_fail_open" {
  description = "If true, WAF fail open will be enabled"
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "If true, invalid header fields will be dropped"
  type        = bool
  default     = false
}

variable "preserve_host_header" {
  description = "If true, the host header will be preserved"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = null
}

variable "access_logs_enabled" {
  description = "If true, access logs will be enabled"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Listener variables
variable "listeners" {
  description = "Map of listener configurations"
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
  description = "Map of target group configurations"
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
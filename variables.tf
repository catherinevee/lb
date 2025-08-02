variable "create_lb" {
  description = "Controls if the ALB should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the Application Load Balancer. Must be unique within your AWS account and region"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.name))
    error_message = "The load balancer name must contain only alphanumeric characters and hyphens."
  }

  validation {
    condition     = length(var.name) <= 32
    error_message = "The load balancer name must be 32 characters or less."
  }
}

variable "internal" {
  description = "If true, the ALB will be internal"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "List of security group IDs for the ALB. At least one security group must be specified"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.security_groups) > 0
    error_message = "At least one security group must be specified."
  }

  validation {
    condition     = alltrue([for sg in var.security_groups : can(regex("^sg-[a-zA-Z0-9]+$", sg))])
    error_message = "All security group IDs must be valid and start with 'sg-'."
  }
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
# ==============================================================================
# Enhanced Load Balancer Configuration Variables
# ==============================================================================

variable "enable_waf" {
  description = "Whether to enable WAF integration"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF web ACL to associate"
  type        = string
  default     = null
}

variable "enable_shield" {
  description = "Whether to enable Shield protection"
  type        = bool
  default     = false
}

variable "shield_protection_arn" {
  description = "ARN of the Shield protection to associate"
  type        = string
  default     = null
}

variable "enable_tls_version_and_cipher_suite_headers" {
  description = "Whether to enable TLS version and cipher suite headers"
  type        = bool
  default     = false
}

variable "enable_xff_client_port" {
  description = "Whether to enable X-Forwarded-For client port"
  type        = bool
  default     = false
}

variable "enable_xff_header_processing" {
  description = "Whether to enable X-Forwarded-For header processing"
  type        = bool
  default     = false
}

variable "xff_header_processing_mode" {
  description = "X-Forwarded-For header processing mode"
  type        = string
  default     = "append"
  validation {
    condition     = contains(["append", "preserve", "remove"], var.xff_header_processing_mode)
    error_message = "XFF header processing mode must be one of: append, preserve, remove."
  }
}

variable "desync_mitigation_mode" {
  description = "Desync mitigation mode"
  type        = string
  default     = "defensive"
  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "Desync mitigation mode must be one of: monitor, defensive, strictest."
  }
}

variable "enable_access_logs_s3_bucket_versioning" {
  description = "Whether to enable S3 bucket versioning for access logs"
  type        = bool
  default     = false
}

variable "enable_access_logs_s3_bucket_encryption" {
  description = "Whether to enable S3 bucket encryption for access logs"
  type        = bool
  default     = false
}

variable "access_logs_s3_bucket_encryption_algorithm" {
  description = "S3 bucket encryption algorithm for access logs"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.access_logs_s3_bucket_encryption_algorithm)
    error_message = "Access logs S3 bucket encryption algorithm must be either 'AES256' or 'aws:kms'."
  }
}

variable "access_logs_s3_bucket_kms_key_id" {
  description = "KMS key ID for access logs S3 bucket encryption"
  type        = string
  default     = null
}

variable "enable_target_group_deregistration_delay" {
  description = "Whether to enable target group deregistration delay"
  type        = bool
  default     = false
}

variable "target_group_deregistration_delay" {
  description = "Target group deregistration delay in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.target_group_deregistration_delay >= 0 && var.target_group_deregistration_delay <= 3600
    error_message = "Target group deregistration delay must be between 0 and 3600 seconds."
  }
}

variable "enable_target_group_slow_start" {
  description = "Whether to enable target group slow start"
  type        = bool
  default     = false
}

variable "target_group_slow_start_duration" {
  description = "Target group slow start duration in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.target_group_slow_start_duration >= 30 && var.target_group_slow_start_duration <= 900
    error_message = "Target group slow start duration must be between 30 and 900 seconds."
  }
}

variable "enable_target_group_load_balancing_algorithm" {
  description = "Whether to enable custom load balancing algorithm"
  type        = bool
  default     = false
}

variable "target_group_load_balancing_algorithm" {
  description = "Target group load balancing algorithm"
  type        = string
  default     = "round_robin"
  validation {
    condition     = contains(["round_robin", "least_outstanding_requests"], var.target_group_load_balancing_algorithm)
    error_message = "Target group load balancing algorithm must be either 'round_robin' or 'least_outstanding_requests'."
  }
}

variable "enable_listener_ssl_policy" {
  description = "Whether to enable SSL policy for listeners"
  type        = bool
  default     = false
}

variable "listener_ssl_policy" {
  description = "SSL policy for listeners"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "enable_listener_alpn_policy" {
  description = "Whether to enable ALPN policy for listeners"
  type        = bool
  default     = false
}

variable "listener_alpn_policy" {
  description = "ALPN policy for listeners"
  type        = string
  default     = "HTTP2Preferred"
  validation {
    condition     = contains(["HTTP2Preferred", "HTTP2Only", "HTTP1Only"], var.listener_alpn_policy)
    error_message = "Listener ALPN policy must be one of: HTTP2Preferred, HTTP2Only, HTTP1Only."
  }
}

variable "enable_listener_default_action_forward" {
  description = "Whether to enable forward action for listener default action"
  type        = bool
  default     = false
}

variable "listener_default_action_forward_config" {
  description = "Forward configuration for listener default action"
  type = object({
    target_groups = list(object({
      arn = string
      weight = optional(number, 1)
    }))
    stickiness = optional(object({
      duration = number
      enabled = optional(bool, false)
    }), null)
  })
  default = null
}

variable "enable_listener_default_action_authenticate_cognito" {
  description = "Whether to enable Cognito authentication for listener default action"
  type        = bool
  default     = false
}

variable "listener_default_action_authenticate_cognito_config" {
  description = "Cognito authentication configuration for listener default action"
  type = object({
    user_pool_arn = string
    user_pool_client_id = string
    user_pool_domain = string
    scope = optional(string, null)
    session_cookie_name = optional(string, null)
    session_timeout = optional(number, null)
    on_unauthenticated_request = optional(string, null)
  })
  default = null
}

variable "enable_listener_default_action_authenticate_oidc" {
  description = "Whether to enable OIDC authentication for listener default action"
  type        = bool
  default     = false
}

variable "listener_default_action_authenticate_oidc_config" {
  description = "OIDC authentication configuration for listener default action"
  type = object({
    authorization_endpoint = string
    client_id = string
    client_secret = string
    issuer = string
    token_endpoint = string
    user_info_endpoint = string
    scope = optional(string, null)
    session_cookie_name = optional(string, null)
    session_timeout = optional(number, null)
    on_unauthenticated_request = optional(string, null)
  })
  default = null
}


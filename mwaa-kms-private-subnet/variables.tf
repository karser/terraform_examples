variable "project_prefix" {
  description = "Project name used as prefix"
  type        = string
  default     = "napilm"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "environment_class" {
  description = "MWAA instance class (small, medium, large)"
  type        = string
  default     = "mw1.small"
  validation {
    condition     = contains(["mw1.small", "mw1.medium", "mw1.large"], var.environment_class)
    error_message = "Must be one of: mw1.small, mw1.medium, mw1.large"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "existing_s3_bucket_arn" {
  description = "ARN of the existing S3 bucket for MWAA"
  type        = string
}

variable "existing_kms_key_arn" {
  description = "ARN of the existing KMS key associated with the S3 bucket"
  type        = string
}

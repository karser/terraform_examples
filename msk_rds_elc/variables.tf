variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (test or prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "santa"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "msk_instance_type" {
  description = "MSK broker instance type"
  type        = string
}

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.nano"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}

variable "docker_image" {
  description = "Docker image to run on the instances"
  type        = string
  default     = "filebrowser/filebrowser"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "id_rsa.pub"
}

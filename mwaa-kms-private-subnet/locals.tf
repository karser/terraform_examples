locals {
  account_id         = data.aws_caller_identity.current.account_id
  region             = data.aws_region.current.name
  name_prefix        = "${var.project_prefix}-${var.environment}"
  vpc_id             = data.aws_vpc.current_vpc.id
  private_subnet_ids = [data.aws_subnet.private_subnet_a.id, data.aws_subnet.private_subnet_b.id]
  common_tags = {
    Environment = var.environment
    Project     = var.project_prefix
    ManagedBy   = "Terraform"
  }
}

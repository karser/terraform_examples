locals {
  interface_endpoint_services = [
    "logs",         # CloudWatch Logs
    "monitoring",   # CloudWatch Metrics (optional but included)
    "kms",          # KMS
    "ecr.api",      # ECR API
    "ecr.dkr",      # ECR Docker
    "sqs",          # SQS
    "airflow.env",  # MWAA Environment
    "airflow.api"   # MWAA API
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = local.vpc_id
  service_name = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    data.aws_route_table.private_a.id,
    data.aws_route_table.private_b.id
  ]
  tags = local.common_tags
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each          = toset(local.interface_endpoint_services)
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnet_ids
  security_group_ids = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.key}-endpoint" })
}

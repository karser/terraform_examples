resource "aws_security_group" "endpoint_sg" {
  name        = "${local.name_prefix}-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.mwaa.mwaa_security_group_id]
  }

  tags = local.common_tags
}

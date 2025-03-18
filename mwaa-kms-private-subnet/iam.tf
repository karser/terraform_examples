resource "aws_iam_policy" "mwaa_kms_policy" {
  name        = "${local.name_prefix}-mwaa-kms-policy"
  description = "Policy for MWAA to use the existing KMS key"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.existing_kms_key_arn
      }
    ]
  })
}

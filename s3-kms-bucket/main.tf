# main.tf

# Configure the AWS Provider
provider "aws" {
  region     = var.aws_region
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

# Create a VPC for the subnets
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "nap-cloud-ilm-dev-vpc"
  }
}

# Create the first private subnet
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "nap-cloud-ilm-dev-private-${var.aws_region}a"
  }
}

# Create the second private subnet
resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "nap-cloud-ilm-dev-private-${var.aws_region}b"
  }
}

# Create a route table for private_subnet_a
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "nap-cloud-ilm-dev-private-rt-${var.aws_region}a"
  }
}

# Associate the route table with private_subnet_a
resource "aws_route_table_association" "private_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_a.id
}

# Create a route table for private_subnet_b
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "nap-cloud-ilm-dev-private-rt-${var.aws_region}b"
  }
}

# Associate the route table with private_subnet_b
resource "aws_route_table_association" "private_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_b.id
}

# Create KMS key for S3 bucket encryption
resource "aws_kms_key" "s3_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Add a friendly alias for the key
resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3_encryption_key.key_id
}

# Create S3 bucket with KMS encryption
resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = "s3-kms-bucket-${data.aws_caller_identity.current.account_id}"  # Ensure bucket name is unique
  force_destroy = true  # Allows bucket deletion even if it contains objects; set to false for production
}

# Configure server-side encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Get current AWS account identity
data "aws_caller_identity" "current" {}

# Output the bucket name and KMS key ARN
output "bucket_name" {
  value = aws_s3_bucket.encrypted_bucket.id
}

output "kms_key_arn" {
  value = aws_kms_key.s3_encryption_key.arn
}

output "mwaa_webserver_url" {
  description = "URL to access the Airflow Web UI"
  value       = module.mwaa.mwaa_webserver_url
}

output "mwaa_arn" {
  description = "The ARN of the MWAA Environment"
  value       = module.mwaa.mwaa_arn
}

output "mwaa_role_arn" {
  description = "IAM Role ARN of the MWAA Environment"
  value       = module.mwaa.mwaa_role_arn
}

output "existing_s3_bucket_arn" {
  description = "ARN of the existing S3 bucket used for MWAA"
  value       = var.existing_s3_bucket_arn
}

output "existing_kms_key_arn" {
  description = "ARN of the existing KMS key used for MWAA"
  value       = var.existing_kms_key_arn
}

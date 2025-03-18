module "mwaa" {
  source  = "aws-ia/mwaa/aws"
  version = "0.0.6"

  name                 = "${local.name_prefix}-airflow"
  airflow_version      = "2.10.1"
  environment_class    = var.environment_class
  vpc_id               = local.vpc_id
  private_subnet_ids   = local.private_subnet_ids
  source_bucket_arn    = var.existing_s3_bucket_arn
  kms_key              = var.existing_kms_key_arn
  create_s3_bucket     = false
  create_iam_role      = true
  iam_role_additional_policies = {
    "kms-policy" = aws_iam_policy.mwaa_kms_policy.arn
  }
  dag_s3_path           = "dags/"
  webserver_access_mode = "PRIVATE_ONLY"
  source_cidr           = [data.aws_vpc.current_vpc.cidr_block]
  min_workers           = 1
  max_workers           = 10

  logging_configuration = {
    dag_processing_logs = {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs = {
      enabled   = true
      log_level = "INFO"
    }
    task_logs = {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs = {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs = {
      enabled   = true
      log_level = "INFO"
    }
  }

  airflow_configuration_options = {
    "core.load_default_connections" = "false"
    "core.load_examples"            = "false"
    "webserver.dag_default_view"    = "tree"
    "webserver.dag_orientation"     = "TB"
    "logging.logging_level"         = "INFO"
  }

  tags = local.common_tags
}

resource "aws_security_group" "msk_sg" {
  name        = "${var.project_name}-${var.environment}-msk-sg"
  description = "Security group for MSK"
  vpc_id      = data.aws_vpc.santa_vpc.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_msk_cluster" "msk" {
  cluster_name           = "${var.project_name}-${var.environment}-msk"
  kafka_version          = "3.8.1"
  number_of_broker_nodes = 2
  broker_node_group_info {
    instance_type   = var.msk_instance_type
    storage_info {
      ebs_storage_info {
        volume_size = 1
      }
    }
    client_subnets  = data.aws_subnets.private_subnets.ids
    security_groups = [aws_security_group.msk_sg.id]
  }
}

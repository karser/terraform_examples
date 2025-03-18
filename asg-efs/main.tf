# Configure the AWS provider
provider "aws" {
  region = var.region
}

# Data sources for default VPC, subnets, and latest Amazon Linux 2 AMI
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security group for the ALB (allow HTTP from anywhere)
resource "aws_security_group" "alb_sg" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for instances (allow port 5000 from ALB)
data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = [var.region]
  services = ["ec2_instance_connect"]
}
resource "aws_security_group" "instance_sg" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for EFS (allow NFS from instances)
resource "aws_security_group" "efs_sg" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EFS File System
resource "aws_efs_file_system" "efs" {
  creation_token = "efs-token"
  tags = {
    Name = "efs-volume"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "mount_target" {
  for_each       = toset(data.aws_subnets.default.ids)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

# IAM Role for EC2 instances to access EFS
resource "aws_iam_role" "ec2_role" {
  name = "ec2-efs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "efs_policy" {
  name = "efs-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Effect   = "Allow"
        Resource = aws_efs_file_system.efs.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-efs-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch template for instances
resource "aws_launch_template" "template" {
  name_prefix   = "template-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name = var.ssh_key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
yum update -y
yum install -y docker
yum install -y amazon-efs-utils
systemctl start docker
systemctl enable docker
mkdir -p /mnt/efs
echo "${aws_efs_file_system.efs.id}.efs.${var.region}.amazonaws.com:/ /mnt/efs nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a
if mountpoint -q /mnt/efs; then
    echo "EFS mounted successfully"
else
    echo "EFS mount failed"
    exit 1
fi
docker run -d -p 5000:80 -v /mnt/efs:/srv ${var.docker_image}
EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
  }
}

# Autoscaling group
resource "aws_autoscaling_group" "asg" {
  name                      = "asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns         = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# Target group for ALB
resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
  }
}

# ALB listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

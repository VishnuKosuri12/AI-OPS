# 1. Database Subnet Group (Tells RDS which subnets to live in)
resource "aws_db_subnet_group" "default" {
  name       = "${var.environment}-${var.app_name}-subnet-group"
  subnet_ids = [aws_subnet.rds_1.id, aws_subnet.rds_2.id]

  tags = { Name = "RDS Subnet Group" }
}

# 2. Security Group for RDS (Allows access from ECS only)
resource "aws_security_group" "rds" {
  name        = "${var.environment}-${var.app_name}-rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow inbound traffic from ECS only"

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.ecs.id] # Only ECS can talk to DB
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. RDS Instance
resource "aws_db_instance" "default" { # FIXED NAME: Matches locals.tf
  allocated_storage      = var.db_default_settings.allocated_storage
  max_allocated_storage  = var.db_default_settings.max_allocated_storage
  db_name                = var.db_default_settings.db_name
  engine                 = "postgres"
  engine_version         = var.db_default_settings.engine_version
  instance_class         = var.db_default_settings.instance_class
  username               = var.db_default_settings.db_admin_username
  password               = var.db_password # Pulled from your new variable
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false # Set to true for production high availability
}

# 4. Secrets Manager (The "Safe" for the DB Link)
resource "aws_secretsmanager_secret" "db_link" {
  name       = "${var.environment}/${var.app_name}/db_link"
  kms_key_id = aws_kms_key.rds_kms.arn # Uses your KMS key
}

resource "aws_secretsmanager_secret_version" "db_link" {
  secret_id = aws_secretsmanager_secret.db_link.id
  # We construct the full SQLAlchemy URL here
  secret_string = "postgresql://${aws_db_instance.default.username}:${var.db_password}@${aws_db_instance.default.address}:${aws_db_instance.default.port}/${aws_db_instance.default.db_name}"
}

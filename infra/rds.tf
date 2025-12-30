# --- 1. SECURITY GROUP ---
resource "aws_security_group" "rds" {
  name        = "${var.environment}-${var.app_name}-rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow inbound access from ECS tasks only"

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    # This allows only the ECS Security Group to talk to the DB
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-rds-sg"
    Environment = var.environment
  }
}

# --- 2. DB SUBNET GROUP ---
resource "aws_db_subnet_group" "postgres" {
  name        = "${var.environment}-${var.app_name}-db-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = [aws_subnet.rds_1.id, aws_subnet.rds_2.id]

  tags = {
    Name        = "${var.environment}-${var.app_name}-db-subnet-group"
    Environment = var.environment
  }
}

# --- 3. PASSWORD GENERATION ---
resource "random_password" "dbs_random_string" {
  length           = 16
  special          = false # Avoiding special chars prevents URL encoding issues in connection strings
}

# --- 4. RDS POSTGRES INSTANCE ---
resource "aws_db_instance" "postgres" {
  identifier            = "${var.environment}-${var.app_name}-db"
  allocated_storage     = var.db_default_settings.allocated_storage
  max_allocated_storage = var.db_default_settings.max_allocated_storage
  engine                = "postgres"
  engine_version        = "14.15"
  instance_class        = "db.t3.micro"
  username              = "myadmin"
  password              = random_password.dbs_random_string.result
  port                  = 5432
  publicly_accessible   = false
  db_subnet_group_name  = aws_db_subnet_group.postgres.id
  ca_cert_identifier    = var.db_default_settings.ca_cert_name
  storage_encrypted     = true
  storage_type          = "gp3"
  kms_key_id            = aws_kms_key.rds_kms.arn
  skip_final_snapshot   = true # Set to false for production
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period    = var.db_default_settings.backup_retention_period
  db_name                    = var.db_default_settings.db_name
  auto_minor_version_upgrade = true
  deletion_protection        = false

  tags = {
    Name        = "${var.environment}-${var.app_name}-db"
    Environment = var.environment
  }
}

# --- 5. SECRETS MANAGER (THE SAFE) ---
resource "aws_secretsmanager_secret" "db_link" {
  name                    = "${var.environment}/${var.app_name}/db_connection_string"
  description             = "Full SQLAlchemy connection string for Flask"
  kms_key_id              = aws_kms_key.rds_kms.arn
  recovery_window_in_days = 7 # Lowered from 30 for easier testing/deletion
}

resource "aws_secretsmanager_secret_version" "dbs_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_link.id
  # We construct the URL that Flask (SQLAlchemy) expects
  secret_string = "postgresql://${aws_db_instance.postgres.username}:${random_password.dbs_random_string.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
}


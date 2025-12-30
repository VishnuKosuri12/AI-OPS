# 1. Create the Secret metadata (the container)
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.environment}-db-password"
  kms_key_id  = aws_kms_key.rds_kms.arn
  
  # This allows you to recreate the secret quickly if needed
  recovery_window_in_days = 0 
}

# 2. Create the Secret value (the actual password)
resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password

  # Use this to ensure the new password is fully "Put" before destroying the old one
  lifecycle {
    create_before_destroy = true
  }
}

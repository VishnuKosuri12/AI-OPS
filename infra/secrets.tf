# 1. Create the Secret metadata (the container)
resource "aws_secretsmanager_secret" "db_password" {
  name       = "${var.environment}-db-password"
  kms_key_id = aws_kms_key.rds_kms.arn # This links to your kms.tf
}

# 2. Create the Secret value (the actual password)
resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password # This will be sensitive!
}

locals {
  student_portal_services_vars = {
    # FIXED: Changed from student_portal_app to main
    aws_ecr_repository            = aws_ecr_repository.main.repository_url
    tag                           = var.tag
    container_name                = var.container_name
    container_port                = var.container_port
    aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-${var.app_name}"
    environment                   = var.environment
    
    # FIXED: db_link_arn is what ecs.tf expects for the secrets block
    db_link_arn                   = aws_secretsmanager_secret.db_link.arn
    
    # RDS Helpers (matching resource "aws_db_instance" "default" in rds.tf)
    db_host                       = aws_db_instance.default.address
  }

  app_deploy_vars = {
    # FIXED: Changed from student_portal_app to main
    IMAGE_REPO_NAME        = aws_ecr_repository.main.repository_url
    ECS_APP_CONTAINER_NAME = var.container_name
    ECS_TASK_DEFINITION    = "${var.environment}-${var.app_name}"
    ECS_SERVICE            = "${var.environment}-${var.app_name}-service"
    ECS_CLUSTER            = aws_ecs_cluster.main.id
    IMAGE_NAME             = "student-portal-app"
  }
}

resource "aws_secretsmanager_secret" "app_deploy_data" {
  name        = "${var.environment}-${var.app_name}-deploy-data"
  description = "Deployment data for the student portal app"
}

resource "aws_secretsmanager_secret_version" "app_deploy_data_version" {
  secret_id     = aws_secretsmanager_secret.app_deploy_data.id
  secret_string = jsonencode(local.app_deploy_vars)
}

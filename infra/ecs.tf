# 1. ADDING THE LOCALS BLOCK: This maps your variables to the template placeholders
locals {
  student_portal_services_vars = {
    container_name                = var.container_name
    # Replace 'aws_ecr_repository.main' with your actual ECR resource name
    aws_ecr_repository            = aws_ecr_repository.main.repository_url 
    tag                           = var.tag
    # Replace 'aws_cloudwatch_log_group.main' with your actual Log Group resource name
    aws_cloudwatch_log_group_name = aws_cloudwatch_log_group.main.name
    environment                   = var.environment
    # Replace 'aws_db_instance.default' with your actual RDS resource name
    db_link                       = aws_db_instance.default.address
  }
}

# Security Group for ECS
resource "aws_security_group" "ecs" {
  name        = "${var.environment}-${var.app_name}-sg"
  vpc_id      = aws_vpc.main.id
  description = "allow inbound access from the ALB only"

  ingress {
    protocol        = "tcp"
    from_port       = 8000
    to_port         = 8000
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"
}

# JSON Template Rendering
data "template_file" "services" {
  # FIXED: Pointing to student-portan.tpl to match your filename
  template = file("${path.module}/templates/student-portan.tpl")
  # FIXED: Using singular 'portal' to match the locals block above
  vars     = local.student_portal_services_vars
}

# ECS Task Definition
resource "aws_ecs_task_definition" "services" {
  family                   = "${var.environment}-${var.app_name}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.student_portal_app_cpu
  memory                   = var.student_portal_app_memory
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.services.rendered

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# ECS Service
resource "aws_ecs_service" "flask_app_service" {
  name                        = "${var.environment}-${var.app_name}-service"
  cluster                     = aws_ecs_cluster.main.id
  task_definition             = aws_ecs_task_definition.services.arn
  desired_count               = var.desired_container_count
  deployment_maximum_percent  = 250
  launch_type                 = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb.arn
    container_name   = var.container_name # FIXED: Matching the name used in Task Def
    container_port   = 8000
  }

  tags = {
    Environment = var.environment
    Application = "flask-app"
  }
}

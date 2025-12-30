# Security Group for ECS
resource "aws_security_group" "ecs" {
  name        = "${var.environment}-${var.app_name}-sg"
  vpc_id      = aws_vpc.main.id
  description = "allow inbound access from the ALB only"

  ingress {
    protocol        = "tcp"
    from_port       = 8000
    to_port         = 8000
    # This correctly references the Security Group in alb.tf
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

# ECS Task Definition
resource "aws_ecs_task_definition" "services" {
  family                   = "${var.environment}-${var.app_name}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.student_portal_app_cpu
  memory                   = var.student_portal_app_memory
  requires_compatibilities = ["FARGATE"]
  
  # This pulls the variables directly from your locals.tf file
  container_definitions = templatefile("${path.module}/templates/student-portal.tpl", local.student_portal_services_vars)

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# ECS Service
resource "aws_ecs_service" "flask_app_service" {
  name                                = "${var.environment}-${var.app_name}-service"
  cluster                             = aws_ecs_cluster.main.id
  task_definition                     = aws_ecs_task_definition.services.arn
  desired_count                       = var.desired_container_count
  deployment_maximum_percent          = 250
  launch_type                         = "FARGATE"
  health_check_grace_period_seconds   = 60

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb.arn
    container_name   = var.container_name
    container_port   = 8000
  }

  # This ensures the Load Balancer is ready before the app tries to start
  depends_on = [aws_lb_listener.http]
}

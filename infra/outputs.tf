# This pulls the name directly from the resource that was built using your variables
output "ecr_repository_name" {
  value = aws_ecr_repository.student_portal_app.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.flask_app_service.name
}

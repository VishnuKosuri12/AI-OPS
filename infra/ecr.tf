resource "aws_ecr_repository" "main" { # Changed from student_portal_app to main
  name                 = "${var.prefix}-${var.environment}-${var.app_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

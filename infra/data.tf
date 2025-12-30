data "aws_availability_zones" "available" {
  state = "available"
}

# This helps get your account ID automatically for the OIDC role
data "aws_caller_identity" "current" {}

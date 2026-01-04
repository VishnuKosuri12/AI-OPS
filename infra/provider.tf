terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "state-bucket-3128-4647-3135"
    key     = "lambda-rotation/terraform.tfstate"
    region  = "us-east-2" # Ohio (Where the bucket is)
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region # us-east-1 (Where the resources go)
}
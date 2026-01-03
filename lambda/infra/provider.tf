terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "vishnu-pooja-storage-2025"
    # Change the folder name here to isolate this project
    key    = "lambda-project/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

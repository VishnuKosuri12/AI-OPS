terraform {
  required_version = ">= 1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Owner = "vishnu"
      email = "vishnukosuri.com"
      repo  = "deploying_ecs_terraform"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "state-bucket-3128-4647-3135"
    key    = "terraform-state"
    region = "us-east-2"
  }
} ##

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "vishnu-pooja-storage-2025"
}

variable "sender_email" {
  description = "SES Verified email for Lambda alerts"
  type        = string
  default     = "srivishnukosuri94@gmail.com"
}

variable "project_tags" {
  type = map(string)
  default = {
    Environment = "Dev-Bootcamp"
    Project     = "Lambda-Rotation"
    LastUpdated = "Jan-01-2026"
  }
}

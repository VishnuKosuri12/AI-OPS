variable "aws_region" {
  default = "us-east-1"
}

variable "bucket_name" {
  default = "vishnu-pooja-storage-2025"
}

variable "user_names" {
  type    = list(string)
  default = ["poojaaishwaya.bonthhula", "vishnu.kosuri121212@gmail.com"]
}

variable "sender_email" {
  default = "srivishnukosuri94@gmail.com"
}
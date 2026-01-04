# 1. S3 Bucket
resource "aws_s3_bucket" "shared_storage" {
  bucket = "vishnu-pooja-storage-2025"

  tags = {
    Environment = "Dev-Bootcamp"
    Project     = "Lambda-Rotation"
    LastUpdated = "Jan-01-2026"
  }
}

# 2. IAM Users
resource "aws_iam_user" "project_users" {
  for_each = toset(["vishnu.kosuri121212@gmail.com", "poojaaishwaya.bonthhula"])
  name     = each.value

  tags = each.key == "vishnu.kosuri121212@gmail.com" ? {
    "AKIAURVY2K6X7MFRC22T" = "Sending access key"
  } : {}
}

# 3. IAM Policies
resource "aws_iam_policy" "user_restricted_policy" {
  name        = "UserS3AndKeyRotationPolicy"
  description = "Allows S3 operations and self-rotation of IAM keys"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::vishnu-pooja-storage-2025", "arn:aws:s3:::vishnu-pooja-storage-2025/*"]
      },
      {
        Action   = ["iam:CreateAccessKey", "iam:DeleteAccessKey", "iam:UpdateAccessKey", "iam:ListAccessKeys"]
        Effect   = "Allow"
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })
}

resource "aws_iam_policy" "vishnu_restricted_access" {
  name        = "VishnuProjectSpecificPolicy"
  description = "Permissions for S3, IAM, Lambda, SES, and EventBridge including Discovery"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*", "iam:*", "lambda:*", "ses:*", "events:*"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["events:ListTagsForResource", "iam:ListRolePolicies", "s3:GetBucketPolicy", "s3:GetEncryptionConfiguration"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# 4. IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "KeyRotationAlertRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 5. Policy Attachments
resource "aws_iam_role_policy_attachment" "lambda_iam_read" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ses_iam" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_user_policy_attachment" "business_user_attach" {
  for_each   = toset(["vishnu.kosuri121212@gmail.com", "poojaaishwaya.bonthhula"])
  user       = each.value
  policy_arn = aws_iam_policy.user_restricted_policy.arn
}

resource "aws_iam_user_policy_attachment" "vishnu_attach" {
  user       = "Vishnu"
  policy_arn = aws_iam_policy.vishnu_restricted_access.arn
}

# 6. Lambda Function
resource "aws_lambda_function" "rotation_alert" {
  filename      = "lambda_function.zip"
  function_name = "Happy_New_Year"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.Happy_new_year"
  runtime       = "python3.12"
  environment {
    variables = { SENDER_EMAIL = "srivishnukosuri94@gmail.com" }
  }
}

# 7. EventBridge (CloudWatch Events)
resource "aws_cloudwatch_event_rule" "daily_audit" {
  name                = "DailyIAMKeyAudit"
  description         = "Triggers at 03:25 AM daily to check for keys older than 3 days"
  schedule_expression = "cron(30 16 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_audit.name
  target_id = "TriggerRotationLambda"
  arn       = aws_lambda_function.rotation_alert.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_audit.arn
}
# 1. S3 Bucket
resource "aws_s3_bucket" "shared_storage" {
  bucket = var.bucket_name

  tags = {
    Environment = "Dev-Bootcamp"
    Project     = "Secure-Portal"
    LastUpdated = "Jan-03-2026"
  }
}

# 2. IAM Users
resource "aws_iam_user" "project_users" {
  for_each = toset(var.user_names)
  name     = each.value
}

# 3. Restricted Policy for Business User (Restricts to /Analyze folder)
resource "aws_iam_policy" "analyze_folder_policy" {
  name        = "AnalyzeFolderAccessOnly"
  description = "Allows external users to only manage the Analyze folder"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = ["arn:aws:s3:::${var.bucket_name}"]
        Condition = {
          StringLike = { "s3:prefix": ["Analyze/*", "Analyze/"] }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::${var.bucket_name}/Analyze/*"]
      }
    ]
  })
}

# Attach restricted policy to the specific user
resource "aws_iam_user_policy_attachment" "business_user_attach" {
  user       = "vishnu.ksouri121212@gmail.com" # Matches your student list
  policy_arn = aws_iam_policy.analyze_folder_policy.arn
}

# 4. Lambda Infrastructure (For the Daily Reminders)
resource "aws_iam_role" "lambda_exec_role" {
  name = "KeyRotationAlertRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_iam_read" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ses_iam" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_lambda_function" "rotation_alert" {
  filename      = "lambda_function.zip"
  function_name = "Happy_New_Year"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.Happy_new_year"
  runtime       = "python3.12"

  environment {
    variables = {
      SENDER_EMAIL = var.sender_email
    }
  }
}

# 5. EventBridge Cron (04:30 PM UTC)
resource "aws_cloudwatch_event_rule" "daily_audit" {
  name                = "DailyIAMKeyAudit"
  schedule_expression = "cron(30 16 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule = aws_cloudwatch_event_rule.daily_audit.name
  arn  = aws_lambda_function.rotation_alert.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_audit.arn
}

# 6. Admin Policy (Vishnu's full access)
resource "aws_iam_policy" "vishnu_restricted_access" {
  name = "VishnuAdminPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:*", "iam:*", "lambda:*", "ses:*", "events:*"], Resource = "*" }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "vishnu_attach" {
  user       = "Vishnu"
  policy_arn = aws_iam_policy.vishnu_restricted_access.arn
}

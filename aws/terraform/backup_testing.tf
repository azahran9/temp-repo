# Backup Testing Infrastructure

# SNS Topic for backup test notifications
resource "aws_sns_topic" "backup_test_notifications" {
  name = "${var.project_name}-backup-test-notifications-${var.environment}"
  
  tags = {
    Name        = "${var.project_name}-backup-test-notifications-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "backup_test_notifications" {
  arn    = aws_sns_topic.backup_test_notifications.arn
  policy = data.aws_iam_policy_document.backup_test_sns_policy.json
}

data "aws_iam_policy_document" "backup_test_sns_policy" {
  statement {
    actions = [
      "SNS:Publish",
      "SNS:Subscribe"
    ]
    
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "backup.amazonaws.com"]
    }
    
    resources = [
      aws_sns_topic.backup_test_notifications.arn
    ]
  }
}

# IAM Role for Backup Test Lambda
resource "aws_iam_role" "backup_test_lambda" {
  name = "${var.project_name}-backup-test-lambda-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-backup-test-lambda-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Backup Test Lambda
resource "aws_iam_policy" "backup_test_lambda" {
  name        = "${var.project_name}-backup-test-lambda-policy-${var.environment}"
  description = "Policy for backup test Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "backup:ListRecoveryPointsByBackupVault",
          "backup:StartRestoreJob",
          "backup:DescribeRestoreJob"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.backup_test_notifications.arn
      },
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.backup_test_metrics.arn
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DeleteDBInstance"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:DeleteTable"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DeleteVolume"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "backup_test_lambda" {
  role       = aws_iam_role.backup_test_lambda.name
  policy_arn = aws_iam_policy.backup_test_lambda.arn
}

# IAM Role for Backup Test Metrics Lambda
resource "aws_iam_role" "backup_test_metrics_lambda" {
  name = "${var.project_name}-backup-test-metrics-lambda-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-backup-test-metrics-lambda-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Backup Test Metrics Lambda
resource "aws_iam_policy" "backup_test_metrics_lambda" {
  name        = "${var.project_name}-backup-test-metrics-lambda-policy-${var.environment}"
  description = "Policy for backup test metrics Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "backup_test_metrics_lambda" {
  role       = aws_iam_role.backup_test_metrics_lambda.name
  policy_arn = aws_iam_policy.backup_test_metrics_lambda.arn
}

# Lambda function for backup test metrics
resource "aws_lambda_function" "backup_test_metrics" {
  function_name    = "${var.project_name}-backup-test-metrics-${var.environment}"
  role             = aws_iam_role.backup_test_metrics_lambda.arn
  handler          = "backup_test_metrics.handler"
  runtime          = "nodejs14.x"
  filename         = "${path.module}/lambda/backup_test_metrics.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/backup_test_metrics.zip")
  timeout          = 30
  memory_size      = 128
  
  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }
  
  tags = {
    Name        = "${var.project_name}-backup-test-metrics-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Lambda function for backup testing
resource "aws_lambda_function" "backup_test" {
  function_name    = "${var.project_name}-backup-test-${var.environment}"
  role             = aws_iam_role.backup_test_lambda.arn
  handler          = "backup_test.handler"
  runtime          = "nodejs14.x"
  filename         = "${path.module}/lambda/backup_test.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/backup_test.zip")
  timeout          = 900  # 15 minutes
  memory_size      = 256
  
  environment {
    variables = {
      BACKUP_VAULT_NAME  = aws_backup_vault.main.name
      SNS_TOPIC_ARN      = aws_sns_topic.backup_test_notifications.arn
      METRICS_LAMBDA_ARN = aws_lambda_function.backup_test_metrics.arn
      PROJECT_NAME       = var.project_name
      ENVIRONMENT        = var.environment
    }
  }
  
  tags = {
    Name        = "${var.project_name}-backup-test-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Event Rule for scheduled backup testing
resource "aws_cloudwatch_event_rule" "backup_test" {
  name                = "${var.project_name}-backup-test-schedule-${var.environment}"
  description         = "Scheduled backup testing"
  schedule_expression = "cron(0 3 ? * SUN *)"  # Run at 3:00 AM UTC every Sunday
  
  tags = {
    Name        = "${var.project_name}-backup-test-schedule-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Event Target for backup testing
resource "aws_cloudwatch_event_target" "backup_test" {
  rule      = aws_cloudwatch_event_rule.backup_test.name
  target_id = "backup-test-lambda"
  arn       = aws_lambda_function.backup_test.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "backup_test" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_test.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_test.arn
}

# CloudWatch Alarm for backup test failures
resource "aws_cloudwatch_metric_alarm" "backup_test_failure" {
  alarm_name          = "${var.project_name}-backup-test-failure-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TestSuccess"
  namespace           = "${var.project_name}/BackupTesting"
  period              = 86400  # 1 day
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "This alarm monitors backup test failures"
  alarm_actions       = [aws_sns_topic.backup_test_notifications.arn]
  ok_actions          = [aws_sns_topic.backup_test_notifications.arn]
  
  dimensions = {
    Environment = var.environment
  }
  
  tags = {
    Name        = "${var.project_name}-backup-test-failure-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# AWS Cost Explorer and Budgets configuration

# AWS Budget for monthly costs
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-monthly-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    TagKeyValue = "user:Environment$${var.environment}"
  }
}

# AWS Budget for EC2 costs
resource "aws_budgets_budget" "ec2" {
  name              = "${var.project_name}-ec2-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.ec2_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    Service = "Amazon Elastic Compute Cloud - Compute"
  }
}

# AWS Budget for Lambda costs
resource "aws_budgets_budget" "lambda" {
  name              = "${var.project_name}-lambda-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.lambda_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    Service = "AWS Lambda"
  }
}

# AWS Budget for S3 costs
resource "aws_budgets_budget" "s3" {
  name              = "${var.project_name}-s3-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.s3_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    Service = "Amazon Simple Storage Service"
  }
}

# AWS Budget for RDS costs
resource "aws_budgets_budget" "rds" {
  name              = "${var.project_name}-rds-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.rds_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    Service = "Amazon Relational Database Service"
  }
}

# AWS Budget for ElastiCache costs
resource "aws_budgets_budget" "elasticache" {
  name              = "${var.project_name}-elasticache-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.elasticache_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    Service = "Amazon ElastiCache"
  }
}

# AWS Budget for usage-based resources
resource "aws_budgets_budget" "usage" {
  name              = "${var.project_name}-usage-budget-${var.environment}"
  budget_type       = "USAGE"
  limit_amount      = var.ec2_instance_hours_budget
  limit_unit        = "Hours"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }
  
  cost_filters = {
    UsageType = "BoxUsage:t3.medium"
  }
}

# AWS Cost Anomaly Detection
resource "aws_ce_anomaly_monitor" "main" {
  name              = "${var.project_name}-anomaly-monitor-${var.environment}"
  monitor_type      = "DIMENSIONAL"
  
  dimension_value_attributes {
    dimensions {
      key           = "SERVICE"
      values        = ["Amazon Elastic Compute Cloud - Compute", "AWS Lambda", "Amazon Simple Storage Service", "Amazon Relational Database Service", "Amazon ElastiCache"]
      match_options = ["EQUALS"]
    }
  }
}

# AWS Cost Anomaly Subscription
resource "aws_ce_anomaly_subscription" "main" {
  name                 = "${var.project_name}-anomaly-subscription-${var.environment}"
  threshold            = 100
  frequency            = "DAILY"
  monitor_arn_list     = [aws_ce_anomaly_monitor.main.arn]
  subscriber_sns_topic_arns = [aws_sns_topic.alerts.arn]
}

# Lambda function for cost optimization
resource "aws_lambda_function" "cost_optimization" {
  function_name = "${var.project_name}-cost-optimization-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.cost_optimization_role.arn
  runtime       = "nodejs14.x"
  timeout       = 300
  
  filename         = "${path.module}/lambda/cost_optimization.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/cost_optimization.zip")
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
  
  tags = local.common_tags
}

# IAM role for cost optimization Lambda
resource "aws_iam_role" "cost_optimization_role" {
  name = "${var.project_name}-cost-optimization-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# IAM policy for cost optimization Lambda
resource "aws_iam_policy" "cost_optimization_policy" {
  name        = "${var.project_name}-cost-optimization-policy-${var.environment}"
  description = "Policy for cost optimization Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetReservationUtilization",
          "ce:GetSavingsPlansUtilization",
          "ce:GetRecommendationSummary",
          "ce:GetRightsizingRecommendation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeAddresses",
          "ec2:ModifyInstanceAttribute",
          "ec2:StopInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:ModifyCacheCluster"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach cost optimization policy to Lambda role
resource "aws_iam_role_policy_attachment" "cost_optimization_policy_attachment" {
  role       = aws_iam_role.cost_optimization_role.name
  policy_arn = aws_iam_policy.cost_optimization_policy.arn
}

# CloudWatch Event Rule for scheduled cost optimization
resource "aws_cloudwatch_event_rule" "cost_optimization" {
  name                = "${var.project_name}-cost-optimization-${var.environment}"
  description         = "Schedule for automated cost optimization"
  schedule_expression = "cron(0 1 * * ? *)" # 1 AM UTC every day
  
  tags = local.common_tags
}

# CloudWatch Event Target for cost optimization
resource "aws_cloudwatch_event_target" "cost_optimization" {
  rule      = aws_cloudwatch_event_rule.cost_optimization.name
  target_id = "cost-optimization-lambda"
  arn       = aws_lambda_function.cost_optimization.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "cost_optimization" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimization.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_optimization.arn
}

# AWS Cost Explorer Savings Plans Utilization Report
resource "aws_ce_cost_category" "environment" {
  name         = "${var.project_name}-environment-${var.environment}"
  rule_version = "1.0"
  
  rule {
    value = var.environment
    
    rule {
      dimension = "TAG"
      
      values {
        key   = "Environment"
        match = "EQUALS"
        values = [var.environment]
      }
    }
  }
}

# AWS Cost Allocation Tags
resource "aws_ce_cost_allocation_tag" "environment" {
  tag_key = "Environment"
  status  = "ACTIVE"
}

resource "aws_ce_cost_allocation_tag" "project" {
  tag_key = "Project"
  status  = "ACTIVE"
}

resource "aws_ce_cost_allocation_tag" "owner" {
  tag_key = "Owner"
  status  = "ACTIVE"
}

# IAM role for cost reports
resource "aws_iam_role" "cost_reports_role" {
  name = "${var.project_name}-cost-reports-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# IAM policy for cost reports
resource "aws_iam_policy" "cost_reports_policy" {
  name        = "${var.project_name}-cost-reports-policy-${var.environment}"
  description = "Policy for cost reports Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetTags",
          "ce:GetCostCategories"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.cost_reports.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach cost reports policy to role
resource "aws_iam_role_policy_attachment" "cost_reports_policy_attachment" {
  role       = aws_iam_role.cost_reports_role.name
  policy_arn = aws_iam_policy.cost_reports_policy.arn
}

# S3 bucket for cost reports
resource "aws_s3_bucket" "cost_reports" {
  bucket = "${var.project_name}-cost-reports-${var.environment}-${data.aws_caller_identity.current.account_id}"
  
  tags = local.common_tags
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  
  rule {
    id     = "archive-old-reports"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 730 # Delete after 2 years
    }
  }
}

# Lambda function for generating cost reports
resource "aws_lambda_function" "cost_reports" {
  function_name = "${var.project_name}-cost-reports-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.cost_reports_role.arn
  runtime       = "nodejs14.x"
  timeout       = 300
  
  filename         = "${path.module}/lambda/cost_reports.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/cost_reports.zip")
  
  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.cost_reports.id
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
      ENVIRONMENT    = var.environment
    }
  }
  
  tags = local.common_tags
}

# CloudWatch Event Rule for scheduled cost reports
resource "aws_cloudwatch_event_rule" "cost_reports" {
  name                = "${var.project_name}-cost-reports-${var.environment}"
  description         = "Schedule for generating cost reports"
  schedule_expression = "cron(0 2 1 * ? *)" # 2 AM UTC on the 1st of each month
  
  tags = local.common_tags
}

# CloudWatch Event Target for cost reports
resource "aws_cloudwatch_event_target" "cost_reports" {
  rule      = aws_cloudwatch_event_rule.cost_reports.name
  target_id = "cost-reports-lambda"
  arn       = aws_lambda_function.cost_reports.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "cost_reports" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reports.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_reports.arn
}

# Output budget ARNs
output "monthly_budget_arn" {
  description = "ARN of the monthly budget"
  value       = aws_budgets_budget.monthly.arn
}

output "cost_anomaly_monitor_arn" {
  description = "ARN of the cost anomaly monitor"
  value       = aws_ce_anomaly_monitor.main.arn
}

output "cost_reports_bucket" {
  description = "S3 bucket for cost reports"
  value       = aws_s3_bucket.cost_reports.id
}

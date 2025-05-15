# AWS Backup Vault
resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-backup-vault-${var.environment}"
  kms_key_arn = aws_kms_key.backup.arn
  
  tags = local.common_tags
}

# Secondary backup vault in another region for disaster recovery
resource "aws_backup_vault" "secondary" {
  provider    = aws.secondary_region
  name        = "${var.project_name}-backup-vault-${var.environment}-dr"
  kms_key_arn = aws_kms_key.backup_secondary.arn
  
  tags = local.common_tags
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  name = "${var.project_name}-backup-plan-${var.environment}"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 1 * * ? *)" # 1 AM UTC every day
    
    lifecycle {
      delete_after = 30 # Keep backups for 30 days
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn
      
      lifecycle {
        delete_after = 30 # Keep cross-region backups for 30 days
      }
    }
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 1 ? * SUN *)" # 1 AM UTC every Sunday
    
    lifecycle {
      delete_after = 90 # Keep weekly backups for 90 days
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn
      
      lifecycle {
        delete_after = 90 # Keep cross-region backups for 90 days
      }
    }
  }

  rule {
    rule_name         = "monthly-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 1 1 * ? *)" # 1 AM UTC on the 1st of every month
    
    lifecycle {
      delete_after = 365 # Keep monthly backups for 365 days
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn
      
      lifecycle {
        delete_after = 365 # Keep cross-region backups for 365 days
      }
    }
  }

  # Continuous backup with point-in-time recovery for critical resources
  rule {
    rule_name         = "continuous-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0/15 * * * ? *)" # Every 15 minutes
    
    lifecycle {
      delete_after = 7 # Keep continuous backups for 7 days
    }
    
    # Enable continuous backup for point-in-time recovery
    enable_continuous_backup = true
  }

  tags = local.common_tags
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS managed policy for AWS Backup
resource "aws_iam_role_policy_attachment" "backup_policy_attachment" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Attach AWS managed policy for AWS Backup restore
resource "aws_iam_role_policy_attachment" "restore_policy_attachment" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Custom policy for cross-region backup
resource "aws_iam_policy" "backup_cross_region_policy" {
  name        = "${var.project_name}-backup-cross-region-policy-${var.environment}"
  description = "Policy for AWS Backup cross-region operations"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "backup:CopyIntoBackupVault"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach cross-region backup policy
resource "aws_iam_role_policy_attachment" "backup_cross_region_policy_attachment" {
  role       = aws_iam_role.backup_role.name
  policy_arn = aws_iam_policy.backup_cross_region_policy.arn
}

# AWS Backup Selection
resource "aws_backup_selection" "main" {
  name         = "${var.project_name}-backup-selection-${var.environment}"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_elasticache_replication_group.redis.arn,
    module.documentdb.arn,
    aws_s3_bucket.app_bucket.arn,
    aws_rds_cluster.aurora_cluster.arn
  ]

  # Add tags to identify resources to backup
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# Enable automatic backups for Redis
resource "aws_elasticache_parameter_group" "redis_with_backup" {
  name   = "${var.project_name}-redis-params-${var.environment}"
  family = "redis6.x"

  parameter {
    name  = "snapshot-retention-limit"
    value = "7"
  }

  parameter {
    name  = "snapshot-window"
    value = "00:00-03:00" # Backup window from midnight to 3 AM UTC
  }
  
  tags = local.common_tags
}

# CloudWatch Event Rule for backup events
resource "aws_cloudwatch_event_rule" "backup_events" {
  name        = "${var.project_name}-backup-events-${var.environment}"
  description = "Capture AWS Backup events"
  
  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail_type = ["Backup Job State Change", "Copy Job State Change", "Restore Job State Change"]
    detail = {
      state = ["COMPLETED", "FAILED", "ABORTED", "EXPIRED"]
    }
  })
  
  tags = local.common_tags
}

# CloudWatch Event Target for backup events
resource "aws_cloudwatch_event_target" "backup_events" {
  rule      = aws_cloudwatch_event_rule.backup_events.name
  target_id = "backup-events-sns"
  arn       = aws_sns_topic.alerts.arn
  
  input_transformer {
    input_paths = {
      jobId     = "$.detail.jobId"
      state     = "$.detail.state"
      resourceType = "$.detail.resourceType"
      resourceArn  = "$.detail.resourceArn"
      accountId    = "$.account"
      region       = "$.region"
      time         = "$.time"
    }
    
    input_template = <<EOF
{
  "subject": "[${upper(var.environment)}] AWS Backup job <state>",
  "message": "AWS Backup job details:\n- Job ID: <jobId>\n- State: <state>\n- Resource Type: <resourceType>\n- Resource ARN: <resourceArn>\n- Account: <accountId>\n- Region: <region>\n- Time: <time>\n\nFor more details, check the AWS Backup console."
}
EOF
  }
}

# CloudWatch Event Rule for scheduled backup testing
resource "aws_cloudwatch_event_rule" "backup_testing" {
  name                = "${var.project_name}-backup-testing-${var.environment}"
  description         = "Schedule for automated backup testing"
  schedule_expression = "cron(0 3 ? * SAT#2 *)" # 3 AM UTC on the second Saturday of each month
  
  tags = local.common_tags
}

# Lambda function for backup testing
resource "aws_lambda_function" "backup_testing" {
  function_name = "${var.project_name}-backup-testing-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.backup_testing_role.arn
  runtime       = "nodejs14.x"
  timeout       = 300
  
  filename         = "${path.module}/lambda/backup_testing.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/backup_testing.zip")
  
  environment {
    variables = {
      BACKUP_VAULT_NAME = aws_backup_vault.main.name
      SNS_TOPIC_ARN     = aws_sns_topic.alerts.arn
      ENVIRONMENT       = var.environment
    }
  }
  
  tags = local.common_tags
}

# IAM role for backup testing Lambda
resource "aws_iam_role" "backup_testing_role" {
  name = "${var.project_name}-backup-testing-role-${var.environment}"
  
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

# IAM policy for backup testing Lambda
resource "aws_iam_policy" "backup_testing_policy" {
  name        = "${var.project_name}-backup-testing-policy-${var.environment}"
  description = "Policy for backup testing Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "backup:StartRestoreJob",
          "backup:DescribeRestoreJob",
          "backup:ListRecoveryPoints",
          "backup:DescribeRecoveryPoint"
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

# Attach backup testing policy to Lambda role
resource "aws_iam_role_policy_attachment" "backup_testing_policy_attachment" {
  role       = aws_iam_role.backup_testing_role.name
  policy_arn = aws_iam_policy.backup_testing_policy.arn
}

# CloudWatch Event Rule for scheduled backup testing
resource "aws_cloudwatch_event_rule" "backup_testing" {
  name                = "${var.project_name}-backup-testing-${var.environment}"
  description         = "Schedule for automated backup testing"
  schedule_expression = "cron(0 3 ? * SUN *)" # 3 AM UTC every Sunday
  
  tags = local.common_tags
}

# CloudWatch Event Target for backup testing
resource "aws_cloudwatch_event_target" "backup_testing" {
  rule      = aws_cloudwatch_event_rule.backup_testing.name
  target_id = "backup-testing-lambda"
  arn       = aws_lambda_function.backup_testing.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "backup_testing" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_testing.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_testing.arn
}

# Output backup vault ARNs
output "backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_secondary_arn" {
  description = "ARN of the secondary backup vault for disaster recovery"
  value       = aws_backup_vault.secondary.arn
}

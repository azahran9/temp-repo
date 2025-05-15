# Security Assessment Lambda Function and Supporting Resources

# Lambda function for security assessment
resource "aws_lambda_function" "security_assessment" {
  function_name    = "${var.project_name}-security-assessment-${var.environment}"
  filename         = "${path.module}/lambda/security_assessment.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/security_assessment.zip")
  handler          = "security_assessment.handler"
  runtime          = "nodejs14.x"
  timeout          = 300
  memory_size      = 512
  
  environment {
    variables = {
      PROJECT_NAME   = var.project_name
      ENVIRONMENT    = var.environment
      SNS_TOPIC_ARN  = aws_sns_topic.security_findings.arn
    }
  }
  
  role = aws_iam_role.security_assessment_lambda.arn
  
  tags = {
    Name        = "${var.project_name}-security-assessment-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM role for the security assessment Lambda function
resource "aws_iam_role" "security_assessment_lambda" {
  name = "${var.project_name}-security-assessment-role-${var.environment}"
  
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
    Name        = "${var.project_name}-security-assessment-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM policy for the security assessment Lambda function
resource "aws_iam_policy" "security_assessment_lambda" {
  name        = "${var.project_name}-security-assessment-policy-${var.environment}"
  description = "Policy for the security assessment Lambda function"
  
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
          "iam:ListUsers",
          "iam:ListAccessKeys",
          "iam:ListMFADevices",
          "iam:ListPolicies",
          "iam:GetPolicyVersion",
          "iam:ListGroupsForUser",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedGroupPolicies"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:GetBucketEncryption",
          "s3:GetBucketLogging"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBSnapshots"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.security_findings.arn
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "security_assessment_lambda" {
  role       = aws_iam_role.security_assessment_lambda.name
  policy_arn = aws_iam_policy.security_assessment_lambda.arn
}

# CloudWatch Event Rule to trigger the Lambda function daily
resource "aws_cloudwatch_event_rule" "security_assessment_schedule" {
  name                = "${var.project_name}-security-assessment-schedule-${var.environment}"
  description         = "Triggers the security assessment Lambda function daily"
  schedule_expression = "cron(0 3 * * ? *)"  # Run daily at 3:00 AM UTC
  
  tags = {
    Name        = "${var.project_name}-security-assessment-schedule-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Event Target to trigger the Lambda function
resource "aws_cloudwatch_event_target" "security_assessment_schedule" {
  rule      = aws_cloudwatch_event_rule.security_assessment_schedule.name
  target_id = "TriggerSecurityAssessmentLambda"
  arn       = aws_lambda_function.security_assessment.arn
}

# Permission for CloudWatch Events to invoke the Lambda function
resource "aws_lambda_permission" "security_assessment_schedule" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_assessment.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_assessment_schedule.arn
}

# CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "security_assessment" {
  name              = "/aws/lambda/${aws_lambda_function.security_assessment.function_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.project_name}-security-assessment-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Alarm for failed security assessments
resource "aws_cloudwatch_metric_alarm" "security_assessment_errors" {
  alarm_name          = "${var.project_name}-security-assessment-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 86400  # 24 hours
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors for errors in the security assessment Lambda function"
  
  dimensions = {
    FunctionName = aws_lambda_function.security_assessment.function_name
  }
  
  alarm_actions = [aws_sns_topic.security_findings.arn]
  ok_actions    = [aws_sns_topic.security_findings.arn]
  
  tags = {
    Name        = "${var.project_name}-security-assessment-errors-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Alarm for critical security findings
resource "aws_cloudwatch_metric_alarm" "critical_security_findings" {
  alarm_name          = "${var.project_name}-critical-security-findings-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CriticalFindings"
  namespace           = "SecurityAssessment"
  period              = 86400  # 24 hours
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This alarm monitors for critical security findings"
  
  dimensions = {
    Project     = var.project_name
    Environment = var.environment
  }
  
  alarm_actions = [aws_sns_topic.security_findings.arn]
  ok_actions    = [aws_sns_topic.security_findings.arn]
  
  tags = {
    Name        = "${var.project_name}-critical-security-findings-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Dashboard for Security Assessment
resource "aws_cloudwatch_dashboard" "security_assessment" {
  dashboard_name = "${var.project_name}-security-assessment-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Security Assessment Dashboard\nThis dashboard shows the results of the daily security assessment for the ${var.project_name} infrastructure in the ${var.environment} environment."
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["SecurityAssessment", "CriticalFindings", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "HighFindings", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "MediumFindings", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "LowFindings", "Project", var.project_name, "Environment", var.environment]
          ]
          region = var.aws_region
          title  = "Security Findings by Severity"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          view    = "pie"
          metrics = [
            ["SecurityAssessment", "CriticalFindings", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "HighFindings", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "MediumFindings", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "LowFindings", "Project", var.project_name, "Environment", var.environment]
          ]
          region = var.aws_region
          title  = "Security Findings Distribution"
          period = 86400
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 8
        width  = 24
        height = 1
        properties = {
          markdown = "## IAM Security"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["SecurityAssessment", "AccessKeysOlderThan90Days", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "UsersWithoutMFA", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "InactiveUsers", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "PoliciesWithFullAdmin", "Project", var.project_name, "Environment", var.environment]
          ]
          region = var.aws_region
          title  = "IAM Security Issues"
          period = 86400
        }
      },
      {
        type   = "text"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          markdown = "### IAM Security Best Practices\n\n- Rotate access keys every 90 days\n- Enable MFA for all IAM users\n- Remove inactive users (no activity in 90+ days)\n- Avoid policies with full administrative access\n- Use role-based access control\n- Apply the principle of least privilege\n- Regularly audit IAM permissions"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 15
        width  = 24
        height = 1
        properties = {
          markdown = "## S3 Security"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["SecurityAssessment", "PublicBuckets", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "UnencryptedBuckets", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "BucketsWithoutLogging", "Project", var.project_name, "Environment", var.environment]
          ]
          region = var.aws_region
          title  = "S3 Security Issues"
          period = 86400
        }
      },
      {
        type   = "text"
        x      = 12
        y      = 16
        width  = 12
        height = 6
        properties = {
          markdown = "### S3 Security Best Practices\n\n- Block public access to S3 buckets\n- Enable default encryption for all buckets\n- Enable access logging for all buckets\n- Use bucket policies to restrict access\n- Enable versioning for critical data\n- Use VPC endpoints for private access\n- Regularly audit bucket permissions"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 22
        width  = 24
        height = 1
        properties = {
          markdown = "## RDS Security"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 23
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["SecurityAssessment", "PubliclyAccessibleRDSInstances", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "UnencryptedRDSInstances", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "RDSInstancesWithoutBackup", "Project", var.project_name, "Environment", var.environment]
          ]
          region = var.aws_region
          title  = "RDS Security Issues"
          period = 86400
        }
      },
      {
        type   = "text"
        x      = 12
        y      = 23
        width  = 12
        height = 6
        properties = {
          markdown = "### RDS Security Best Practices\n\n- Disable public accessibility for RDS instances\n- Enable encryption for all RDS instances\n- Enable automated backups with appropriate retention\n- Use security groups to restrict access\n- Use IAM database authentication when possible\n- Regularly patch database engines\n- Monitor database activity"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 29
        width  = 24
        height = 1
        properties = {
          markdown = "## EC2 Security"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["SecurityAssessment", "EC2InstancesWithPublicIP", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "SecurityGroupsWithOpenPorts", "Project", var.project_name, "Environment", var.environment],
            ["SecurityAssessment", "UnencryptedEBSVolumes", "Project", var.project_name, "Environment", var.environment]
          ]
          region = var.aws_region
          title  = "EC2 Security Issues"
          period = 86400
        }
      },
      {
        type   = "text"
        x      = 12
        y      = 30
        width  = 12
        height = 6
        properties = {
          markdown = "### EC2 Security Best Practices\n\n- Minimize instances with public IPs\n- Restrict security group rules to specific IPs/CIDRs\n- Encrypt all EBS volumes\n- Use IMDSv2 for metadata service\n- Keep instances patched and updated\n- Use Systems Manager for management instead of SSH\n- Implement proper key rotation for SSH access"
        }
      }
    ]
  })
}

# Package.json file for the security assessment Lambda function
resource "local_file" "security_assessment_package_json" {
  content = jsonencode({
    name        = "security-assessment-lambda"
    version     = "1.0.0"
    description = "Lambda function for security assessment"
    main        = "security_assessment.js"
    dependencies = {
      "aws-sdk" = "^2.1130.0"
    }
  })
  filename = "${path.module}/lambda/security_assessment_package.json"
}

# Output the security assessment dashboard URL
output "security_assessment_dashboard_url" {
  description = "URL to the Security Assessment Dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security_assessment.dashboard_name}"
}

# AWS Security Hub for security posture management

# Enable Security Hub
resource "aws_securityhub_account" "main" {}

# Enable AWS Foundational Security Best Practices standard
resource "aws_securityhub_standards_subscription" "fsbp" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# Enable CIS AWS Foundations Benchmark standard
resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.2.0"
}

# Enable PCI DSS standard
resource "aws_securityhub_standards_subscription" "pci" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/pci-dss/v/3.2.1"
}

# Create a Security Hub action target for SNS
resource "aws_securityhub_action_target" "sns" {
  depends_on  = [aws_securityhub_account.main]
  name        = "Send to SNS"
  identifier  = "SendToSNS"
  description = "Sends findings to SNS topic"
}

# CloudWatch Event Rule for Security Hub findings
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name        = "${var.project_name}-securityhub-findings-${var.environment}"
  description = "Capture AWS Security Hub findings"
  
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail_type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
        Workflow = {
          Status = ["NEW"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })
  
  tags = local.common_tags
}

# CloudWatch Event Target for Security Hub findings
resource "aws_cloudwatch_event_target" "securityhub_findings" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "securityhub-findings-sns"
  arn       = aws_sns_topic.alerts.arn
}

# Lambda function for Security Hub findings processing
resource "aws_lambda_function" "securityhub_findings_processor" {
  function_name = "${var.project_name}-securityhub-findings-processor-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.securityhub_findings_processor_role.arn
  runtime       = "nodejs14.x"
  timeout       = 30
  
  filename         = "${path.module}/lambda/securityhub_findings_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/securityhub_findings_processor.zip")
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
  
  tags = local.common_tags
}

# IAM role for Security Hub findings processor Lambda
resource "aws_iam_role" "securityhub_findings_processor_role" {
  name = "${var.project_name}-securityhub-findings-processor-role-${var.environment}"
  
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

# IAM policy for Security Hub findings processor Lambda
resource "aws_iam_policy" "securityhub_findings_processor_policy" {
  name        = "${var.project_name}-securityhub-findings-processor-policy-${var.environment}"
  description = "Policy for Security Hub findings processor Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "securityhub:UpdateFindings"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach Security Hub findings processor policy to Lambda role
resource "aws_iam_role_policy_attachment" "securityhub_findings_processor_policy_attachment" {
  role       = aws_iam_role.securityhub_findings_processor_role.name
  policy_arn = aws_iam_policy.securityhub_findings_processor_policy.arn
}

# CloudWatch Event Target for Security Hub findings to Lambda
resource "aws_cloudwatch_event_target" "securityhub_findings_lambda" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "securityhub-findings-lambda"
  arn       = aws_lambda_function.securityhub_findings_processor.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "securityhub_findings" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.securityhub_findings_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.securityhub_findings.arn
}

# Security Hub Insight
resource "aws_securityhub_insight" "high_severity_findings" {
  depends_on = [aws_securityhub_account.main]
  
  filters {
    severity {
      product_name {
        comparison = "EQUALS"
        value      = "Security Hub"
      }
      
      normalized_severity_label {
        comparison = "EQUALS"
        value      = "HIGH"
      }
    }
    
    resource_type {
      comparison = "EQUALS"
      value      = "AwsEc2Instance"
    }
    
    workflow_status {
      comparison = "EQUALS"
      value      = "NEW"
    }
  }
  
  group_by_attribute = "ResourceId"
  name               = "High Severity EC2 Findings"
}

# Enable GuardDuty integration with Security Hub
resource "aws_securityhub_product_subscription" "guardduty" {
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${var.aws_region}::product/aws/guardduty"
}

# Enable Inspector integration with Security Hub
resource "aws_securityhub_product_subscription" "inspector" {
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${var.aws_region}::product/aws/inspector"
}

# Enable IAM Access Analyzer integration with Security Hub
resource "aws_securityhub_product_subscription" "iam_analyzer" {
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${var.aws_region}::product/aws/access-analyzer"
}

# Output Security Hub ARN
output "securityhub_arn" {
  description = "ARN of the Security Hub account"
  value       = aws_securityhub_account.main.id
}

output "securityhub_insight_arn" {
  description = "ARN of the Security Hub insight"
  value       = aws_securityhub_insight.high_severity_findings.id
}

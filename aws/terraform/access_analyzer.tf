# AWS IAM Access Analyzer for detecting unintended access to resources

# Enable IAM Access Analyzer
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.project_name}-analyzer-${var.environment}"
  type          = "ACCOUNT"
  
  tags = local.common_tags
}

# CloudWatch Event Rule for Access Analyzer findings
resource "aws_cloudwatch_event_rule" "access_analyzer_findings" {
  name        = "${var.project_name}-access-analyzer-findings-${var.environment}"
  description = "Capture AWS IAM Access Analyzer findings"
  
  event_pattern = jsonencode({
    source      = ["aws.access-analyzer"]
    detail_type = ["Access Analyzer Finding"]
    detail = {
      status = ["ACTIVE"]
    }
  })
  
  tags = local.common_tags
}

# CloudWatch Event Target for Access Analyzer findings
resource "aws_cloudwatch_event_target" "access_analyzer_findings" {
  rule      = aws_cloudwatch_event_rule.access_analyzer_findings.name
  target_id = "access-analyzer-findings-sns"
  arn       = aws_sns_topic.alerts.arn
}

# Lambda function for Access Analyzer findings processing
resource "aws_lambda_function" "access_analyzer_findings_processor" {
  function_name = "${var.project_name}-access-analyzer-findings-processor-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.access_analyzer_findings_processor_role.arn
  runtime       = "nodejs14.x"
  timeout       = 30
  
  filename         = "${path.module}/lambda/access_analyzer_findings_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/access_analyzer_findings_processor.zip")
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
  
  tags = local.common_tags
}

# IAM role for Access Analyzer findings processor Lambda
resource "aws_iam_role" "access_analyzer_findings_processor_role" {
  name = "${var.project_name}-access-analyzer-findings-processor-role-${var.environment}"
  
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

# IAM policy for Access Analyzer findings processor Lambda
resource "aws_iam_policy" "access_analyzer_findings_processor_policy" {
  name        = "${var.project_name}-access-analyzer-findings-processor-policy-${var.environment}"
  description = "Policy for Access Analyzer findings processor Lambda function"
  
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
          "access-analyzer:GetFinding",
          "access-analyzer:ListFindings"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach Access Analyzer findings processor policy to Lambda role
resource "aws_iam_role_policy_attachment" "access_analyzer_findings_processor_policy_attachment" {
  role       = aws_iam_role.access_analyzer_findings_processor_role.name
  policy_arn = aws_iam_policy.access_analyzer_findings_processor_policy.arn
}

# CloudWatch Event Target for Access Analyzer findings to Lambda
resource "aws_cloudwatch_event_target" "access_analyzer_findings_lambda" {
  rule      = aws_cloudwatch_event_rule.access_analyzer_findings.name
  target_id = "access-analyzer-findings-lambda"
  arn       = aws_lambda_function.access_analyzer_findings_processor.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "access_analyzer_findings" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.access_analyzer_findings_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.access_analyzer_findings.arn
}

# Output Access Analyzer ARN
output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.arn
}

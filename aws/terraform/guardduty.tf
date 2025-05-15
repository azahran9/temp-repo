# AWS GuardDuty for threat detection

# Enable GuardDuty
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
  
  tags = local.common_tags
}

# S3 bucket for GuardDuty findings
resource "aws_s3_bucket" "guardduty_findings" {
  bucket = "${var.project_name}-guardduty-findings-${var.environment}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-guardduty-findings-${var.environment}"
    }
  )
}

# Enable versioning for GuardDuty findings bucket
resource "aws_s3_bucket_versioning" "guardduty_findings" {
  bucket = aws_s3_bucket.guardduty_findings.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for GuardDuty findings bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_findings" {
  bucket = aws_s3_bucket.guardduty_findings.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# Block public access to the GuardDuty findings bucket
resource "aws_s3_bucket_public_access_block" "guardduty_findings" {
  bucket = aws_s3_bucket.guardduty_findings.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# GuardDuty publishing destination
resource "aws_guardduty_publishing_destination" "s3" {
  detector_id     = aws_guardduty_detector.main.id
  destination_arn = aws_s3_bucket.guardduty_findings.arn
  kms_key_arn     = aws_kms_key.s3.arn
  
  depends_on = [
    aws_s3_bucket_policy.guardduty_findings
  ]
}

# S3 bucket policy for GuardDuty findings
resource "aws_s3_bucket_policy" "guardduty_findings" {
  bucket = aws_s3_bucket.guardduty_findings.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow GuardDuty to use the getBucketLocation operation"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.guardduty_findings.arn
      },
      {
        Sid    = "Allow GuardDuty to upload objects to the bucket"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
      },
      {
        Sid    = "Deny unencrypted object uploads"
        Effect = "Deny"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "Deny incorrect encryption header"
        Effect = "Deny"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3.arn
          }
        }
      },
      {
        Sid    = "Deny non-HTTPS access"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# CloudWatch Event Rule for GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-guardduty-findings-${var.environment}"
  description = "Capture AWS GuardDuty findings"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail_type = ["GuardDuty Finding"]
    detail = {
      severity = [4, 4.0, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 5, 5.0, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 6, 6.0, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 7, 7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9]
    }
  })
  
  tags = local.common_tags
}

# CloudWatch Event Target for GuardDuty findings
resource "aws_cloudwatch_event_target" "guardduty_findings" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "guardduty-findings-sns"
  arn       = aws_sns_topic.alerts.arn
}

# Lambda function for GuardDuty findings processing
resource "aws_lambda_function" "guardduty_findings_processor" {
  function_name = "${var.project_name}-guardduty-findings-processor-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.guardduty_findings_processor_role.arn
  runtime       = "nodejs14.x"
  timeout       = 30
  
  filename         = "${path.module}/lambda/guardduty_findings_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/guardduty_findings_processor.zip")
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
  
  tags = local.common_tags
}

# IAM role for GuardDuty findings processor Lambda
resource "aws_iam_role" "guardduty_findings_processor_role" {
  name = "${var.project_name}-guardduty-findings-processor-role-${var.environment}"
  
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

# IAM policy for GuardDuty findings processor Lambda
resource "aws_iam_policy" "guardduty_findings_processor_policy" {
  name        = "${var.project_name}-guardduty-findings-processor-policy-${var.environment}"
  description = "Policy for GuardDuty findings processor Lambda function"
  
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
          "guardduty:GetFindings",
          "guardduty:ListFindings"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach GuardDuty findings processor policy to Lambda role
resource "aws_iam_role_policy_attachment" "guardduty_findings_processor_policy_attachment" {
  role       = aws_iam_role.guardduty_findings_processor_role.name
  policy_arn = aws_iam_policy.guardduty_findings_processor_policy.arn
}

# CloudWatch Event Target for GuardDuty findings to Lambda
resource "aws_cloudwatch_event_target" "guardduty_findings_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "guardduty-findings-lambda"
  arn       = aws_lambda_function.guardduty_findings_processor.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "guardduty_findings" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_findings_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

# Output GuardDuty detector ID
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "guardduty_findings_bucket_name" {
  description = "Name of the S3 bucket for GuardDuty findings"
  value       = aws_s3_bucket.guardduty_findings.bucket
}

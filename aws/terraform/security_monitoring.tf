# Security Monitoring and Compliance Infrastructure

# AWS GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
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
  
  tags = {
    Name        = "${var.project_name}-guardduty-detector-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config-recorder-${var.environment}"
  role_arn = aws_iam_role.config_recorder.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# AWS Config Recorder Status
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config-delivery-channel-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config_logs.id
  s3_key_prefix  = "config"
  
  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# S3 Bucket for Config Logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "${var.project_name}-config-logs-${var.environment}-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "${var.project_name}-config-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# S3 Bucket Policy for Config Logs
resource "aws_s3_bucket_policy" "config_logs" {
  bucket = aws_s3_bucket.config_logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.config_logs.id}"
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.config_logs.id}/config/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM Role for Config Recorder
resource "aws_iam_role" "config_recorder" {
  name = "${var.project_name}-config-recorder-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-config-recorder-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Config Recorder
resource "aws_iam_role_policy_attachment" "config_recorder" {
  role       = aws_iam_role.config_recorder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# AWS Config Rules
resource "aws_config_config_rule" "root_account_mfa" {
  name        = "${var.project_name}-root-account-mfa-${var.environment}"
  description = "Checks whether the root user of your AWS account requires multi-factor authentication for console sign-in."
  
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  name        = "${var.project_name}-iam-password-policy-${var.environment}"
  description = "Checks whether the account password policy for IAM users meets the specified requirements."
  
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  
  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols             = "true"
    RequireNumbers             = "true"
    MinimumPasswordLength      = "14"
    PasswordReusePrevention    = "24"
    MaxPasswordAge             = "90"
  })
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name        = "${var.project_name}-s3-bucket-public-read-prohibited-${var.environment}"
  description = "Checks that your S3 buckets do not allow public read access."
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name        = "${var.project_name}-s3-bucket-public-write-prohibited-${var.environment}"
  description = "Checks that your S3 buckets do not allow public write access."
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name        = "${var.project_name}-encrypted-volumes-${var.environment}"
  description = "Checks whether EBS volumes that are in an attached state are encrypted."
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name        = "${var.project_name}-rds-storage-encrypted-${var.environment}"
  description = "Checks whether storage encryption is enabled for your RDS DB instances."
  
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# AWS IAM Access Analyzer
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.project_name}-analyzer-${var.environment}"
  type          = "ACCOUNT"
  
  tags = {
    Name        = "${var.project_name}-analyzer-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# AWS Security Hub
resource "aws_securityhub_account" "main" {}

# Enable Security Hub Standards
resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.2.0"
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/pci-dss/v/3.2.1"
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# SNS Topic for Security Findings
resource "aws_sns_topic" "security_findings" {
  name = "${var.project_name}-security-findings-${var.environment}"
  
  tags = {
    Name        = "${var.project_name}-security-findings-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Event Rule for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-guardduty-findings-${var.environment}"
  description = "Event rule for GuardDuty findings"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [4, 4.0, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 5, 5.0, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 6, 6.0, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 7, 7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9]
    }
  })
}

# CloudWatch Event Target for GuardDuty Findings
resource "aws_cloudwatch_event_target" "guardduty_findings" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_findings.arn
  
  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      description = "$.detail.description"
      account     = "$.detail.accountId"
      region      = "$.region"
      finding_id  = "$.detail.id"
    }
    
    input_template = <<EOF
"GuardDuty Finding: [Severity: <severity>] <type> in account <account> (<region>)

Description: <description>

Finding ID: <finding_id>

For more details, visit the GuardDuty console:
https://<region>.console.aws.amazon.com/guardduty/home?region=<region>#/findings?macros=current&fId=<finding_id>"
EOF
  }
}

# CloudWatch Event Rule for Security Hub Findings
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name        = "${var.project_name}-securityhub-findings-${var.environment}"
  description = "Event rule for Security Hub findings"
  
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
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
}

# CloudWatch Event Target for Security Hub Findings
resource "aws_cloudwatch_event_target" "securityhub_findings" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_findings.arn
  
  input_transformer {
    input_paths = {
      severity    = "$.detail.findings[0].Severity.Label"
      title       = "$.detail.findings[0].Title"
      description = "$.detail.findings[0].Description"
      account     = "$.detail.findings[0].AwsAccountId"
      region      = "$.region"
      finding_id  = "$.detail.findings[0].Id"
    }
    
    input_template = <<EOF
"Security Hub Finding: [Severity: <severity>] <title> in account <account> (<region>)

Description: <description>

Finding ID: <finding_id>

For more details, visit the Security Hub console:
https://<region>.console.aws.amazon.com/securityhub/home?region=<region>#/findings?search=Id%3D<finding_id>"
EOF
  }
}

# AWS Inspector
resource "aws_inspector_assessment_template" "main" {
  name       = "${var.project_name}-inspector-template-${var.environment}"
  target_arn = aws_inspector_assessment_target.main.arn
  duration   = 3600
  
  rules_package_arns = [
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-gEjTy7T7",  # Security Best Practices
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-rExsr2X8",  # Runtime Behavior Analysis
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-JJOtZiqQ",  # CIS Operating System Security Configuration Benchmarks
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-vg5GGHSD"   # Common Vulnerabilities and Exposures
  ]
}

resource "aws_inspector_assessment_target" "main" {
  name = "${var.project_name}-inspector-target-${var.environment}"
  
  resource_group_arn = aws_inspector_resource_group.main.arn
}

resource "aws_inspector_resource_group" "main" {
  tags = {
    Inspect     = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Event Rule for Inspector Findings
resource "aws_cloudwatch_event_rule" "inspector_findings" {
  name        = "${var.project_name}-inspector-findings-${var.environment}"
  description = "Event rule for Inspector findings"
  
  event_pattern = jsonencode({
    source      = ["aws.inspector"]
    detail-type = ["Inspector Finding"]
    detail = {
      severity = ["High", "Critical"]
    }
  })
}

# CloudWatch Event Target for Inspector Findings
resource "aws_cloudwatch_event_target" "inspector_findings" {
  rule      = aws_cloudwatch_event_rule.inspector_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_findings.arn
  
  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      title       = "$.detail.title"
      description = "$.detail.description"
      instance_id = "$.detail.asset.instanceId"
      region      = "$.region"
      finding_id  = "$.detail.findingArn"
    }
    
    input_template = <<EOF
"Inspector Finding: [Severity: <severity>] <title> on instance <instance_id> (<region>)

Description: <description>

Finding ID: <finding_id>

For more details, visit the Inspector console:
https://<region>.console.aws.amazon.com/inspector/home?region=<region>#/findings"
EOF
  }
}

# CloudWatch Event Rule for scheduled Inspector scans
resource "aws_cloudwatch_event_rule" "inspector_schedule" {
  name                = "${var.project_name}-inspector-schedule-${var.environment}"
  description         = "Schedule for Inspector assessments"
  schedule_expression = "cron(0 0 ? * SUN *)"  # Run weekly on Sunday at midnight
}

# CloudWatch Event Target for scheduled Inspector scans
resource "aws_cloudwatch_event_target" "inspector_schedule" {
  rule      = aws_cloudwatch_event_rule.inspector_schedule.name
  target_id = "StartInspectorAssessment"
  arn       = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
  
  role_arn = aws_iam_role.inspector_events.arn
  
  input_transformer {
    input_paths = {
      region     = "$.region"
      account_id = "$.account"
    }
    
    input_template = <<EOF
{
  "source": "aws.events",
  "detail-type": "AWS API Call via CloudTrail",
  "detail": {
    "eventSource": "inspector.amazonaws.com",
    "eventName": "StartAssessmentRun",
    "requestParameters": {
      "assessmentTemplateArn": "${aws_inspector_assessment_template.main.arn}"
    }
  }
}
EOF
  }
}

# IAM Role for Inspector Events
resource "aws_iam_role" "inspector_events" {
  name = "${var.project_name}-inspector-events-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-inspector-events-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Inspector Events
resource "aws_iam_policy" "inspector_events" {
  name        = "${var.project_name}-inspector-events-policy-${var.environment}"
  description = "Policy for Inspector events"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "inspector:StartAssessmentRun"
        Effect   = "Allow"
        Resource = aws_inspector_assessment_template.main.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "inspector_events" {
  role       = aws_iam_role.inspector_events.name
  policy_arn = aws_iam_policy.inspector_events.arn
}

# Output for Security Findings SNS Topic
output "security_findings_sns_topic_arn" {
  description = "ARN of the SNS topic for security findings"
  value       = aws_sns_topic.security_findings.arn
}

# Output for GuardDuty Detector ID
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

# Output for Security Hub ARN
output "security_hub_arn" {
  description = "ARN of the Security Hub"
  value       = aws_securityhub_account.main.id
}

# Output for IAM Access Analyzer ARN
output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.arn
}

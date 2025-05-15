# AWS Config configuration for compliance monitoring

# S3 bucket for AWS Config logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "${var.project_name}-config-logs-${var.environment}"
  
  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-config-logs-${var.environment}"
    }
  )
}

# Enable versioning for Config logs bucket
resource "aws_s3_bucket_versioning" "config_logs" {
  bucket = aws_s3_bucket.config_logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for Config logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "config_logs" {
  bucket = aws_s3_bucket.config_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the Config logs bucket
resource "aws_s3_bucket_public_access_block" "config_logs" {
  bucket = aws_s3_bucket.config_logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Config S3 bucket policy
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
        Resource = aws_s3_bucket.config_logs.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-config-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach AWS managed policy for Config
resource "aws_iam_role_policy_attachment" "config_policy_attachment" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config-recorder-${var.environment}"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config-delivery-channel-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config_logs.id
  depends_on     = [aws_config_configuration_recorder.main]
  
  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
}

# Enable AWS Config Recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# AWS Config Rules
# 1. Check if EBS volumes are encrypted
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "${var.project_name}-encrypted-volumes-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 2. Check if S3 buckets have public read access
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "${var.project_name}-s3-bucket-public-read-prohibited-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 3. Check if S3 buckets have public write access
resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "${var.project_name}-s3-bucket-public-write-prohibited-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 4. Check if RDS instances are encrypted
resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "${var.project_name}-rds-storage-encrypted-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 5. Check if root account MFA is enabled
resource "aws_config_config_rule" "root_account_mfa_enabled" {
  name = "${var.project_name}-root-account-mfa-enabled-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 6. Check if CloudTrail is enabled
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "${var.project_name}-cloudtrail-enabled-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 7. Check if instances are in a VPC
resource "aws_config_config_rule" "instances_in_vpc" {
  name = "${var.project_name}-instances-in-vpc-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 8. Check if security groups allow unrestricted access
resource "aws_config_config_rule" "restricted_ssh" {
  name = "${var.project_name}-restricted-ssh-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 9. Check if security groups allow unrestricted access to specific ports
resource "aws_config_config_rule" "restricted_common_ports" {
  name = "${var.project_name}-restricted-common-ports-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# 10. Check if IAM password policy requires strong passwords
resource "aws_config_config_rule" "iam_password_policy" {
  name = "${var.project_name}-iam-password-policy-${var.environment}"
  
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

# CloudWatch Event Rule for Config compliance changes
resource "aws_cloudwatch_event_rule" "config_compliance" {
  name        = "${var.project_name}-config-compliance-${var.environment}"
  description = "Capture AWS Config compliance changes"
  
  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail_type = ["Config Rules Compliance Change"]
    detail = {
      messageType = ["ComplianceChangeNotification"]
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
  
  tags = local.common_tags
}

# CloudWatch Event Target for Config compliance changes
resource "aws_cloudwatch_event_target" "config_compliance" {
  rule      = aws_cloudwatch_event_rule.config_compliance.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
}

# AWS VPC Flow Logs configuration for network traffic monitoring

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn
  
  tags = local.common_tags
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.project_name}-vpc-flow-logs-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# IAM policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "${var.project_name}-vpc-flow-logs-policy-${var.environment}"
  role = aws_iam_role.vpc_flow_logs_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-logs-${var.environment}"
    }
  )
}

# CloudWatch Metric Filter for rejected traffic
resource "aws_cloudwatch_log_metric_filter" "rejected_packets" {
  name           = "${var.project_name}-rejected-packets-${var.environment}"
  pattern        = "{ $.action = \"REJECT\" }"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  
  metric_transformation {
    name      = "RejectedPackets"
    namespace = "${var.project_name}/VpcFlowLogs"
    value     = "1"
  }
}

# CloudWatch Alarm for rejected traffic
resource "aws_cloudwatch_metric_alarm" "rejected_packets" {
  alarm_name          = "${var.project_name}-rejected-packets-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RejectedPackets"
  namespace           = "${var.project_name}/VpcFlowLogs"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors rejected packets"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  tags = local.common_tags
}

# S3 bucket for VPC Flow Logs (optional)
resource "aws_s3_bucket" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs_s3 ? 1 : 0
  bucket = "${var.project_name}-vpc-flow-logs-${var.environment}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-logs-${var.environment}"
    }
  )
}

# Enable versioning for VPC Flow Logs bucket
resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs_s3 ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for VPC Flow Logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs_s3 ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# Block public access to the VPC Flow Logs bucket
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs_s3 ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for VPC Flow Logs
resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs_s3 ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.vpc_flow_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.vpc_flow_logs[0].arn
      }
    ]
  })
}

# VPC Flow Logs to S3 (optional)
resource "aws_flow_log" "s3" {
  count                = var.enable_vpc_flow_logs_s3 ? 1 : 0
  log_destination      = aws_s3_bucket.vpc_flow_logs[0].arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-logs-s3-${var.environment}"
    }
  )
}

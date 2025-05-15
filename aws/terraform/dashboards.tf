# AWS CloudWatch Dashboards for monitoring

# Main dashboard for overall system health
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-main-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${upper(var.environment)} Environment Dashboard"
        }
      },
      # EC2 metrics
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.app.name, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "EC2 CPU Utilization"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", aws_autoscaling_group.app.name, { "stat" = "Average" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", aws_autoscaling_group.app.name, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "EC2 Network Traffic"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", aws_autoscaling_group.app.name, { "stat" = "Sum" }],
            ["AWS/EC2", "StatusCheckFailed_Instance", "AutoScalingGroupName", aws_autoscaling_group.app.name, { "stat" = "Sum" }],
            ["AWS/EC2", "StatusCheckFailed_System", "AutoScalingGroupName", aws_autoscaling_group.app.name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "EC2 Status Checks"
          period = 300
        }
      },
      # ALB metrics
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app_lb.arn_suffix, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "ALB Request Count"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.app_lb.arn_suffix, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "ALB Response Time"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", aws_lb.app_lb.arn_suffix, { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.app_lb.arn_suffix, { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.app_lb.arn_suffix, { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app_lb.arn_suffix, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "ALB Error Codes"
          period = 300
        }
      },
      # Lambda metrics
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.api_handler.function_name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Lambda Invocations"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 13
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.api_handler.function_name, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Lambda Duration"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 13
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.api_handler.function_name, { "stat" = "Sum" }],
            ["AWS/Lambda", "Throttles", "FunctionName", aws_lambda_function.api_handler.function_name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Lambda Errors and Throttles"
          period = 300
        }
      },
      # Redis metrics
      {
        type   = "metric"
        x      = 0
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Redis CPU Utilization"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Redis Memory Usage"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Sum" }],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Redis Cache Hits/Misses"
          period = 300
        }
      },
      # API Gateway metrics
      {
        type   = "metric"
        x      = 0
        y      = 25
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.api.name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "API Gateway Request Count"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 25
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", aws_api_gateway_rest_api.api.name, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "API Gateway Latency"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 25
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiName", aws_api_gateway_rest_api.api.name, { "stat" = "Sum" }],
            ["AWS/ApiGateway", "5XXError", "ApiName", aws_api_gateway_rest_api.api.name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "API Gateway Errors"
          period = 300
        }
      }
    ]
  })
}

# Security dashboard
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-security-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${upper(var.environment)} Security Dashboard"
        }
      },
      # WAF metrics
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.main.name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "WAF Blocked Requests"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.main.name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "WAF Allowed Requests"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/WAFV2", "CountedRequests", "WebACL", aws_wafv2_web_acl.main.name, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "WAF Counted Requests"
          period = 300
        }
      },
      # GuardDuty findings
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/GuardDuty", "FindingCount", "Detector", aws_guardduty_detector.main.id, "Severity", "High", { "stat" = "Sum" }],
            ["AWS/GuardDuty", "FindingCount", "Detector", aws_guardduty_detector.main.id, "Severity", "Medium", { "stat" = "Sum" }],
            ["AWS/GuardDuty", "FindingCount", "Detector", aws_guardduty_detector.main.id, "Severity", "Low", { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "GuardDuty Findings"
          period = 300
        }
      },
      # Security Hub findings
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/SecurityHub", "FindingsCount", "Severity", "CRITICAL", { "stat" = "Sum" }],
            ["AWS/SecurityHub", "FindingsCount", "Severity", "HIGH", { "stat" = "Sum" }],
            ["AWS/SecurityHub", "FindingsCount", "Severity", "MEDIUM", { "stat" = "Sum" }],
            ["AWS/SecurityHub", "FindingsCount", "Severity", "LOW", { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Security Hub Findings"
          period = 300
        }
      },
      # VPC Flow Logs metrics
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${var.project_name}/VpcFlowLogs", "RejectedPackets", { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "VPC Flow Logs - Rejected Packets"
          period = 300
        }
      },
      # CloudTrail events
      {
        type   = "metric"
        x      = 12
        y      = 13
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/CloudTrail", "EventCount", { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "CloudTrail Events"
          period = 300
        }
      },
      # Shield DDoS metrics
      {
        type   = "metric"
        x      = 0
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/DDoSProtection", "DDoSDetected", "ResourceArn", aws_lb.app_lb.arn, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "DDoS Detected"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/DDoSProtection", "DDoSAttackPacketsPerSecond", "ResourceArn", aws_lb.app_lb.arn, { "stat" = "Maximum" }]
          ]
          region = var.aws_region
          title  = "DDoS Attack Packets/Second"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/DDoSProtection", "DDoSAttackBitsPerSecond", "ResourceArn", aws_lb.app_lb.arn, { "stat" = "Maximum" }]
          ]
          region = var.aws_region
          title  = "DDoS Attack Bits/Second"
          period = 300
        }
      },
      # GuardDuty Findings
      {
        type   = "text"
        x      = 0
        y      = 25
        width  = 24
        height = 1
        properties = {
          markdown = "## GuardDuty Findings"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 26
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingSeverity", "High", { "stat" = "Sum", "label": "High Severity" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingSeverity", "Medium", { "stat" = "Sum", "label": "Medium Severity" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingSeverity", "Low", { "stat" = "Sum", "label": "Low Severity" }]
          ]
          region = var.aws_region
          title  = "GuardDuty Findings by Severity"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 26
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingType", "UnauthorizedAccess", { "stat" = "Sum", "label": "Unauthorized Access" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingType", "Backdoor", { "stat" = "Sum", "label": "Backdoor" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingType", "Behavior", { "stat" = "Sum", "label": "Behavior" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingType", "Cryptocurrency", { "stat" = "Sum", "label": "Cryptocurrency" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingType", "Stealth", { "stat" = "Sum", "label": "Stealth" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "FindingType", "Trojan", { "stat" = "Sum", "label": "Trojan" }]
          ]
          region = var.aws_region
          title  = "GuardDuty Findings by Type"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 26
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "ResourceType", "AccessKey", { "stat" = "Sum", "label": "AccessKey" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "ResourceType", "Instance", { "stat" = "Sum", "label": "Instance" }],
            ["AWS/GuardDuty", "Finding", "Detector", "${var.project_name}-detector-${var.environment}", "ResourceType", "S3Bucket", { "stat" = "Sum", "label": "S3Bucket" }]
          ]
          region = var.aws_region
          title  = "GuardDuty Findings by Resource Type"
          period = 300
        }
      },
      # IAM Access Analyzer
      {
        type   = "text"
        x      = 0
        y      = 32
        width  = 24
        height = 1
        properties = {
          markdown = "## IAM Access Analyzer"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 33
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "FindingType", "ExternalAccess", { "stat" = "Maximum", "label": "External Access" }],
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "FindingType", "UnusedAccess", { "stat" = "Maximum", "label": "Unused Access" }]
          ]
          region = var.aws_region
          title  = "IAM Access Analyzer Findings"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 33
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "ResourceType", "AWS::S3::Bucket", { "stat" = "Maximum", "label": "S3 Buckets" }],
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "ResourceType", "AWS::IAM::Role", { "stat" = "Maximum", "label": "IAM Roles" }],
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "ResourceType", "AWS::KMS::Key", { "stat" = "Maximum", "label": "KMS Keys" }],
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "ResourceType", "AWS::SQS::Queue", { "stat" = "Maximum", "label": "SQS Queues" }],
            ["AWS/AccessAnalyzer", "FindingsCount", "AnalyzerName", "${var.project_name}-analyzer-${var.environment}", "ResourceType", "AWS::Lambda::Function", { "stat" = "Maximum", "label": "Lambda Functions" }]
          ]
          region = var.aws_region
          title  = "IAM Access Analyzer Findings by Resource Type"
          period = 300
        }
      },
      # AWS Shield
      {
        type   = "text"
        x      = 0
        y      = 39
        width  = 24
        height = 1
        properties = {
          markdown = "## AWS Shield Advanced"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 40
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Shield", "DDoSAttackCount", "ResourceArn", aws_lb.app_lb.arn, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Shield DDoS Attack Count"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 40
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Shield", "DDoSAttackVolume", "ResourceArn", aws_lb.app_lb.arn, "AttackVector", "SYNFlood", { "stat" = "Maximum", "label": "SYN Flood" }],
            ["AWS/Shield", "DDoSAttackVolume", "ResourceArn", aws_lb.app_lb.arn, "AttackVector", "UDPFlood", { "stat" = "Maximum", "label": "UDP Flood" }],
            ["AWS/Shield", "DDoSAttackVolume", "ResourceArn", aws_lb.app_lb.arn, "AttackVector", "TCPFlood", { "stat" = "Maximum", "label": "TCP Flood" }],
            ["AWS/Shield", "DDoSAttackVolume", "ResourceArn", aws_lb.app_lb.arn, "AttackVector", "ReflectionAttack", { "stat" = "Maximum", "label": "Reflection Attack" }]
          ]
          region = var.aws_region
          title  = "Shield DDoS Attack Volume by Vector"
          period = 300
        }
      }
    ]
  })
}

# Cost dashboard
resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "${var.project_name}-cost-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${upper(var.environment)} Cost Dashboard"
        }
      },
      # Monthly cost trend
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1" # Billing metrics are only available in us-east-1
          title  = "Monthly Estimated Charges (USD)"
          period = 86400 # 1 day
        }
      },
      # Service-specific costs
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "EC2 Estimated Charges (USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonRDS", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "RDS Estimated Charges (USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonElastiCache", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "ElastiCache Estimated Charges (USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonS3", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "S3 Estimated Charges (USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 13
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AWSLambda", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "Lambda Estimated Charges (USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 13
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonCloudFront", "Currency", "USD", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "CloudFront Estimated Charges (USD)"
          period = 86400
        }
      },
      # Cost Anomaly Detection
      {
        type   = "text"
        x      = 0
        y      = 19
        width  = 24
        height = 1
        properties = {
          markdown = "## Cost Anomaly Detection"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/CostExplorer", "AnomalyTotalImpact", { "stat" = "Maximum" }]
          ]
          region = "us-east-1"
          title  = "Cost Anomaly Total Impact (USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 20
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/CostExplorer", "AnomalyCount", { "stat" = "Sum" }]
          ]
          region = "us-east-1"
          title  = "Cost Anomaly Count"
          period = 86400
        }
      },
      # Budget Status
      {
        type   = "text"
        x      = 0
        y      = 26
        width  = 24
        height = 1
        properties = {
          markdown = "## Budget Status"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 27
        width  = 12
        height = 6
        properties = {
          view    = "gauge"
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", { "stat" = "Maximum", "label": "Current Spend" }]
          ],
          yAxis = {
            left = {
              min = 0,
              max = var.monthly_budget_amount
            }
          },
          region = "us-east-1"
          title  = "Monthly Budget Usage (${var.monthly_budget_amount} USD)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 27
        width  = 12
        height = 6
        properties = {
          view    = "pie"
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", "Currency", "USD", { "stat" = "Maximum", "label": "EC2" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonRDS", "Currency", "USD", { "stat" = "Maximum", "label": "RDS" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonElastiCache", "Currency", "USD", { "stat" = "Maximum", "label": "ElastiCache" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonS3", "Currency", "USD", { "stat" = "Maximum", "label": "S3" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AWSLambda", "Currency", "USD", { "stat" = "Maximum", "label": "Lambda" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonCloudFront", "Currency", "USD", { "stat" = "Maximum", "label": "CloudFront" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonRoute53", "Currency", "USD", { "stat" = "Maximum", "label": "Route53" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonCloudWatch", "Currency", "USD", { "stat" = "Maximum", "label": "CloudWatch" }]
          ],
          region = "us-east-1"
          title  = "Cost Distribution by Service"
          period = 86400
        }
      },
      # Cost Optimization Recommendations
      {
        type   = "text"
        x      = 0
        y      = 33
        width  = 24
        height = 1
        properties = {
          markdown = "## Cost Optimization Recommendations"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 34
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ComputeOptimizer", "EC2InstanceSavingsOpportunityPercentage", { "stat" = "Average" }]
          ],
          region = var.aws_region
          title  = "EC2 Savings Opportunity (%)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 34
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ComputeOptimizer", "LambdaFunctionSavingsOpportunityPercentage", { "stat" = "Average" }]
          ],
          region = var.aws_region
          title  = "Lambda Savings Opportunity (%)"
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 34
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ComputeOptimizer", "EBSVolumeSavingsOpportunityPercentage", { "stat" = "Average" }]
          ],
          region = var.aws_region
          title  = "EBS Volume Savings Opportunity (%)"
          period = 86400
        }
      }
    ]
  })
}

# Performance dashboard
resource "aws_cloudwatch_dashboard" "performance" {
  dashboard_name = "${var.project_name}-performance-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${upper(var.environment)} Performance Dashboard"
        }
      },
      # Application performance
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${var.project_name}/Application", "ResponseTime", "Environment", var.environment, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Application Response Time"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${var.project_name}/Application", "RequestCount", "Environment", var.environment, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Application Request Count"
          period = 60
        }
      },
      # Database performance
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", aws_rds_cluster.aurora_cluster.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Database CPU Utilization"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", aws_rds_cluster.aurora_cluster.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Database Connections"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", aws_rds_cluster.aurora_cluster.id, { "stat" = "Average" }],
            ["AWS/RDS", "WriteLatency", "DBClusterIdentifier", aws_rds_cluster.aurora_cluster.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Database Latency"
          period = 60
        }
      },
      # API endpoints performance
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${var.project_name}/API", "Latency", "Endpoint", "/jobs", { "stat" = "Average" }],
            ["${var.project_name}/API", "Latency", "Endpoint", "/users", { "stat" = "Average" }],
            ["${var.project_name}/API", "Latency", "Endpoint", "/matches", { "stat" = "Average" }],
            ["${var.project_name}/API", "Latency", "Endpoint", "/search", { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "API Endpoint Latency"
          period = 60
        }
      },
      # Cache performance
      {
        type   = "metric"
        x      = 0
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ElastiCache", "CacheHitRate", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Cache Hit Rate"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ElastiCache", "Evictions", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Sum" }]
          ]
          region = var.aws_region
          title  = "Cache Evictions"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 19
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", aws_elasticache_replication_group.redis.id, { "stat" = "Average" }]
          ]
          region = var.aws_region
          title  = "Cache CPU Utilization"
          period = 60
        }
      }
    ]
  })
}

# Output dashboard URLs
output "main_dashboard_url" {
  description = "URL for the main dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "security_dashboard_url" {
  description = "URL for the security dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
}

output "cost_dashboard_url" {
  description = "URL for the cost dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost.dashboard_name}"
}

output "performance_dashboard_url" {
  description = "URL for the performance dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.performance.dashboard_name}"
}

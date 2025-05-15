# AWS Shield Advanced for DDoS protection

# Enable AWS Shield Advanced
resource "aws_shield_protection" "alb" {
  count        = var.enable_shield_advanced ? 1 : 0
  name         = "${var.project_name}-alb-protection-${var.environment}"
  resource_arn = aws_lb.app_lb.arn
  
  tags = local.common_tags
}

resource "aws_shield_protection" "cloudfront" {
  count        = var.enable_shield_advanced ? 1 : 0
  name         = "${var.project_name}-cloudfront-protection-${var.environment}"
  resource_arn = aws_cloudfront_distribution.app_distribution.arn
  
  tags = local.common_tags
}

resource "aws_shield_protection" "route53" {
  count        = var.enable_shield_advanced && var.route53_zone_id != "" ? 1 : 0
  name         = "${var.project_name}-route53-protection-${var.environment}"
  resource_arn = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
  
  tags = local.common_tags
}

# AWS Shield Advanced Protection Group
resource "aws_shield_protection_group" "all_resources" {
  count               = var.enable_shield_advanced ? 1 : 0
  protection_group_id = "${var.project_name}-protection-group-${var.environment}"
  aggregation         = "MAX"
  pattern             = "ALL"
  
  tags = local.common_tags
}

# CloudWatch Alarm for DDoS events
resource "aws_cloudwatch_metric_alarm" "ddos_detected" {
  count               = var.enable_shield_advanced ? 1 : 0
  alarm_name          = "${var.project_name}-ddos-detected-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors for DDoS attacks"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ResourceArn = aws_lb.app_lb.arn
  }
  
  tags = local.common_tags
}

# CloudWatch Alarm for DDoS attack vectors
resource "aws_cloudwatch_metric_alarm" "ddos_attack_vectors" {
  count               = var.enable_shield_advanced ? 1 : 0
  alarm_name          = "${var.project_name}-ddos-attack-vectors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSAttackVectors"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors for DDoS attack vectors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ResourceArn = aws_lb.app_lb.arn
  }
  
  tags = local.common_tags
}

# CloudWatch Alarm for DDoS attack packets
resource "aws_cloudwatch_metric_alarm" "ddos_attack_packets" {
  count               = var.enable_shield_advanced ? 1 : 0
  alarm_name          = "${var.project_name}-ddos-attack-packets-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSAttackPacketsPerSecond"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "10000"
  alarm_description   = "This metric monitors for DDoS attack packets per second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ResourceArn = aws_lb.app_lb.arn
  }
  
  tags = local.common_tags
}

# CloudWatch Alarm for DDoS attack bits
resource "aws_cloudwatch_metric_alarm" "ddos_attack_bits" {
  count               = var.enable_shield_advanced ? 1 : 0
  alarm_name          = "${var.project_name}-ddos-attack-bits-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSAttackBitsPerSecond"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "100000000"
  alarm_description   = "This metric monitors for DDoS attack bits per second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ResourceArn = aws_lb.app_lb.arn
  }
  
  tags = local.common_tags
}

# CloudWatch Alarm for DDoS attack requests
resource "aws_cloudwatch_metric_alarm" "ddos_attack_requests" {
  count               = var.enable_shield_advanced ? 1 : 0
  alarm_name          = "${var.project_name}-ddos-attack-requests-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSAttackRequestsPerSecond"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "10000"
  alarm_description   = "This metric monitors for DDoS attack requests per second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ResourceArn = aws_lb.app_lb.arn
  }
  
  tags = local.common_tags
}

# Output Shield Advanced protection ARNs
output "shield_alb_protection_arn" {
  description = "ARN of the Shield Advanced protection for ALB"
  value       = var.enable_shield_advanced ? aws_shield_protection.alb[0].id : null
}

output "shield_cloudfront_protection_arn" {
  description = "ARN of the Shield Advanced protection for CloudFront"
  value       = var.enable_shield_advanced ? aws_shield_protection.cloudfront[0].id : null
}

output "shield_route53_protection_arn" {
  description = "ARN of the Shield Advanced protection for Route53"
  value       = var.enable_shield_advanced && var.route53_zone_id != "" ? aws_shield_protection.route53[0].id : null
}

output "shield_protection_group_id" {
  description = "ID of the Shield Advanced protection group"
  value       = var.enable_shield_advanced ? aws_shield_protection_group.all_resources[0].id : null
}

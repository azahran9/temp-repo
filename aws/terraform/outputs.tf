# Network Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "nat_gateway_ips" {
  description = "Elastic IP addresses of the NAT Gateways"
  value       = module.vpc.nat_public_ips
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the Application Load Balancer"
  value       = aws_lb.app_lb.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_lb.arn
}

# CloudFront Outputs
output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.app_distribution.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.app_distribution.id
}

# API Gateway Outputs
output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway"
  value       = "${aws_api_gateway_deployment.job_matching_deployment.invoke_url}${aws_api_gateway_resource.job_matching_resource.path}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.job_matching_api.id
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.job_matching_stage.stage_name
}

# Cache Outputs
output "redis_endpoint" {
  description = "Endpoint address of the Redis cluster"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Port of the Redis cluster"
  value       = aws_elasticache_replication_group.redis.port
}

# Compute Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.app_launch_template.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.app_launch_template.latest_version
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.job_matching.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.job_matching.arn
}

# CI/CD Outputs
output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.app_pipeline.name
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.app_pipeline.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.app_build.name
}

output "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.app_deploy.name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.app_deploy_group.deployment_group_name
}

output "artifact_bucket_name" {
  description = "Name of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.artifact_bucket.bucket
}

# Security Outputs
output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

# Monitoring Outputs
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

# Backup Outputs
output "backup_vault_name" {
  description = "Name of the AWS Backup vault"
  value       = aws_backup_vault.main.name
}

output "backup_plan_id" {
  description = "ID of the AWS Backup plan"
  value       = aws_backup_plan.main.id
}

# Domain Outputs
output "route53_record_names" {
  description = "The domain names created in Route 53"
  value       = [for record in aws_route53_record.app_dns : record.name]
}

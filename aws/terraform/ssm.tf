# AWS Systems Manager Parameter Store for storing configuration values
# These parameters will be used by the application to retrieve configuration at runtime

# MongoDB Connection String
resource "aws_ssm_parameter" "mongodb_uri" {
  name        = "/${var.project_name}/${var.environment}/MONGODB_URI"
  description = "MongoDB connection string"
  type        = "SecureString"
  value       = var.mongodb_uri
  
  tags = local.common_tags
}

# Redis Connection String
resource "aws_ssm_parameter" "redis_uri" {
  name        = "/${var.project_name}/${var.environment}/REDIS_URI"
  description = "Redis connection string"
  type        = "SecureString"
  value       = "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
  
  tags = local.common_tags
}

# JWT Secret
resource "random_password" "jwt_secret" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.project_name}/${var.environment}/JWT_SECRET"
  description = "JWT secret for authentication"
  type        = "SecureString"
  value       = random_password.jwt_secret.result
  
  tags = local.common_tags
}

# API URL
resource "aws_ssm_parameter" "api_url" {
  name        = "/${var.project_name}/${var.environment}/API_URL"
  description = "API URL for the application"
  type        = "String"
  value       = "https://${aws_lb.app_lb.dns_name}"
  
  tags = local.common_tags
}

# Lambda Function URL
resource "aws_ssm_parameter" "lambda_url" {
  name        = "/${var.project_name}/${var.environment}/LAMBDA_URL"
  description = "Lambda function URL for job matching"
  type        = "String"
  value       = "${aws_api_gateway_deployment.job_matching_deployment.invoke_url}${aws_api_gateway_resource.job_matching_resource.path}"
  
  tags = local.common_tags
}

# Environment
resource "aws_ssm_parameter" "node_env" {
  name        = "/${var.project_name}/${var.environment}/NODE_ENV"
  description = "Node.js environment"
  type        = "String"
  value       = var.environment
  
  tags = local.common_tags
}

# Port
resource "aws_ssm_parameter" "port" {
  name        = "/${var.project_name}/${var.environment}/PORT"
  description = "Application port"
  type        = "String"
  value       = var.app_port
  
  tags = local.common_tags
}

# CloudWatch Log Group
resource "aws_ssm_parameter" "log_group" {
  name        = "/${var.project_name}/${var.environment}/LOG_GROUP"
  description = "CloudWatch Log Group for the application"
  type        = "String"
  value       = aws_cloudwatch_log_group.app_log_group.name
  
  tags = local.common_tags
}

# Output all parameter names for reference
output "ssm_parameters" {
  description = "List of all SSM Parameter names"
  value = [
    aws_ssm_parameter.mongodb_uri.name,
    aws_ssm_parameter.redis_uri.name,
    aws_ssm_parameter.jwt_secret.name,
    aws_ssm_parameter.api_url.name,
    aws_ssm_parameter.lambda_url.name,
    aws_ssm_parameter.node_env.name,
    aws_ssm_parameter.port.name,
    aws_ssm_parameter.log_group.name
  ]
}

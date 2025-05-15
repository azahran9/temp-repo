# AWS Secrets Manager configuration for storing sensitive information

# Generate random password for database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Generate random password for Redis
resource "random_password" "redis_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Generate random password for application
resource "random_password" "app_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Database credentials secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/${var.environment}/db-credentials"
  description = "MongoDB database credentials"
  
  tags = local.common_tags
}

# Database credentials secret version
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    uri      = var.mongodb_uri
  })
}

# Redis credentials secret
resource "aws_secretsmanager_secret" "redis_credentials" {
  name        = "${var.project_name}/${var.environment}/redis-credentials"
  description = "Redis credentials"
  
  tags = local.common_tags
}

# Redis credentials secret version
resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id
  
  secret_string = jsonencode({
    password = random_password.redis_password.result
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = aws_elasticache_replication_group.redis.port
    uri      = "redis://:${random_password.redis_password.result}@${aws_elasticache_replication_group.redis.primary_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
  })
}

# Application credentials secret
resource "aws_secretsmanager_secret" "app_credentials" {
  name        = "${var.project_name}/${var.environment}/app-credentials"
  description = "Application credentials"
  
  tags = local.common_tags
}

# Application credentials secret version
resource "aws_secretsmanager_secret_version" "app_credentials" {
  secret_id = aws_secretsmanager_secret.app_credentials.id
  
  secret_string = jsonencode({
    jwt_secret     = random_password.jwt_secret.result
    api_key        = random_password.app_password.result
    admin_user     = "admin"
    admin_password = random_password.app_password.result
  })
}

# IAM policy for accessing secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-secrets-access-${var.environment}"
  description = "Policy for accessing Secrets Manager secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.redis_credentials.arn,
          aws_secretsmanager_secret.app_credentials.arn
        ]
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach secrets access policy to EC2 instance profile
resource "aws_iam_role_policy_attachment" "ec2_secrets_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Attach secrets access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_secrets_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Rotation schedule for database credentials
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}

# Lambda function for secret rotation
resource "aws_lambda_function" "secret_rotation" {
  function_name = "${var.project_name}-secret-rotation-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.secret_rotation_role.arn
  runtime       = "nodejs14.x"
  timeout       = 30
  
  filename         = "${path.module}/lambda/secret_rotation.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/secret_rotation.zip")
  
  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }
  
  tags = local.common_tags
}

# IAM role for secret rotation Lambda
resource "aws_iam_role" "secret_rotation_role" {
  name = "${var.project_name}-secret-rotation-role-${var.environment}"
  
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

# IAM policy for secret rotation Lambda
resource "aws_iam_policy" "secret_rotation_policy" {
  name        = "${var.project_name}-secret-rotation-policy-${var.environment}"
  description = "Policy for secret rotation Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.redis_credentials.arn,
          aws_secretsmanager_secret.app_credentials.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach secret rotation policy to Lambda role
resource "aws_iam_role_policy_attachment" "secret_rotation_policy_attachment" {
  role       = aws_iam_role.secret_rotation_role.name
  policy_arn = aws_iam_policy.secret_rotation_policy.arn
}

# Output secrets ARNs
output "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "redis_credentials_secret_arn" {
  description = "ARN of the Redis credentials secret"
  value       = aws_secretsmanager_secret.redis_credentials.arn
}

output "app_credentials_secret_arn" {
  description = "ARN of the application credentials secret"
  value       = aws_secretsmanager_secret.app_credentials.arn
}

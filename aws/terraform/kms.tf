# AWS KMS configuration for encryption

# KMS key for encrypting data
resource "aws_kms_key" "main" {
  description             = "${var.project_name} encryption key for ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to encrypt objects"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda to encrypt data"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# KMS key alias
resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "${var.project_name} S3 encryption key for ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# KMS key alias for S3
resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-s3-${var.environment}"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS key for EBS encryption
resource "aws_kms_key" "ebs" {
  description             = "${var.project_name} EBS encryption key for ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# KMS key alias for EBS
resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-ebs-${var.environment}"
  target_key_id = aws_kms_key.ebs.key_id
}

# KMS key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "${var.project_name} Secrets Manager encryption key for ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

# KMS key alias for Secrets Manager
resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets-${var.environment}"
  target_key_id = aws_kms_key.secrets.key_id
}

# IAM policy for KMS key usage
resource "aws_iam_policy" "kms_usage" {
  name        = "${var.project_name}-kms-usage-${var.environment}"
  description = "Policy for using KMS keys"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.main.arn,
          aws_kms_key.s3.arn,
          aws_kms_key.ebs.arn,
          aws_kms_key.secrets.arn
        ]
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach KMS usage policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_kms_usage" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.kms_usage.arn
}

# Attach KMS usage policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_kms_usage" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.kms_usage.arn
}

# Output KMS key ARNs
output "kms_key_arn" {
  description = "ARN of the main KMS key"
  value       = aws_kms_key.main.arn
}

output "s3_kms_key_arn" {
  description = "ARN of the S3 KMS key"
  value       = aws_kms_key.s3.arn
}

output "ebs_kms_key_arn" {
  description = "ARN of the EBS KMS key"
  value       = aws_kms_key.ebs.arn
}

output "secrets_kms_key_arn" {
  description = "ARN of the Secrets Manager KMS key"
  value       = aws_kms_key.secrets.arn
}

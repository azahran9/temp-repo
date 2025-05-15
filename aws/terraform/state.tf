# This file contains resources for Terraform state management
# Uncomment this file if you want to use S3 and DynamoDB for state management

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  count = 0 # Set to 1 to create these resources

  bucket = "${var.project_name}-terraform-state-${var.environment}"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-terraform-state-${var.environment}"
    }
  )
}

# Enable versioning so we can see the full revision history of our state files
resource "aws_s3_bucket_versioning" "terraform_state" {
  count = 0 # Set to 1 to create these resources

  bucket = aws_s3_bucket.terraform_state[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count = 0 # Set to 1 to create these resources

  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count = 0 # Set to 1 to create these resources

  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  count = 0 # Set to 1 to create these resources

  name         = "${var.project_name}-terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-terraform-locks-${var.environment}"
    }
  )
}

# Instructions for initializing Terraform with the S3 backend
# After creating these resources, you can initialize Terraform with the following command:
#
# terraform init \
#   -backend-config="bucket=${var.project_name}-terraform-state-${var.environment}" \
#   -backend-config="key=terraform.tfstate" \
#   -backend-config="region=${var.aws_region}" \
#   -backend-config="dynamodb_table=${var.project_name}-terraform-locks-${var.environment}" \
#   -backend-config="encrypt=true"
#
# Or, uncomment and configure the backend block in providers.tf

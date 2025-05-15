terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  # Uncomment this block to use Terraform Cloud/Enterprise for state management
  # backend "remote" {
  #   organization = "your-organization"
  #   workspaces {
  #     name = "job-matching-api-${var.environment}"
  #   }
  # }
  
  # Uncomment this block to use S3 for state management
  # backend "s3" {
  #   bucket         = "job-matching-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "job-matching-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Optional: Configure a second provider for multi-region deployments
# provider "aws" {
#   alias  = "us-west-2"
#   region = "us-west-2"
#   
#   default_tags {
#     tags = local.common_tags
#   }
# }

# Provider for creating the archive files for Lambda functions
provider "archive" {}

# Provider for generating random values
provider "random" {}

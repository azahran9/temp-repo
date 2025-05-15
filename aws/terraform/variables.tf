variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "job-matching"
}

variable "environment" {
  description = "Environment (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
}

# Security configuration
variable "enable_shield_advanced" {
  description = "Whether to enable AWS Shield Advanced for DDoS protection"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs_s3" {
  description = "Whether to enable VPC Flow Logs to S3 in addition to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string
  default     = ""
}

# Cost management configuration
variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 1000
}

variable "ec2_budget_amount" {
  description = "Monthly EC2 budget amount in USD"
  type        = number
  default     = 300
}

variable "lambda_budget_amount" {
  description = "Monthly Lambda budget amount in USD"
  type        = number
  default     = 50
}

variable "s3_budget_amount" {
  description = "Monthly S3 budget amount in USD"
  type        = number
  default     = 20
}

variable "rds_budget_amount" {
  description = "Monthly RDS budget amount in USD"
  type        = number
  default     = 200
}

variable "elasticache_budget_amount" {
  description = "Monthly ElastiCache budget amount in USD"
  type        = number
  default     = 100
}

variable "ec2_instance_hours_budget" {
  description = "Monthly EC2 instance hours budget"
  type        = number
  default     = 750
}

variable "budget_notification_emails" {
  description = "List of email addresses to notify for budget alerts"
  type        = list(string)
  default     = ["admin@example.com"]
}

# Disaster Recovery configuration
variable "dr_region" {
  description = "AWS region for disaster recovery"
  type        = string
  default     = "us-west-2" # Different from primary region
}

variable "vpc_cidr_dr" {
  description = "CIDR block for the VPC in DR region"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones_dr" {
  description = "Availability zones in DR region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnet_cidrs_dr" {
  description = "CIDR blocks for the private subnets in DR region"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnet_cidrs_dr" {
  description = "CIDR blocks for the public subnets in DR region"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "ec2_ami_dr" {
  description = "AMI ID for EC2 instances in DR region"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in us-west-2
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

variable "app_port" {
  description = "Port the application runs on"
  type        = number
  default     = 3000
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "job-matching-key"
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  sensitive   = true
  default     = "mongodb://localhost:27017/job-matching" # Replace with actual URI in tfvars
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate in ACM"
  type        = string
  default     = ""
}

variable "domain_names" {
  description = "List of domain names for the application"
  type        = list(string)
  default     = ["job-matching.example.com", "www.job-matching.example.com"]
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

# CI/CD Variables
variable "github_repository" {
  description = "GitHub repository for the application (format: owner/repo)"
  type        = string
  default     = "your-github-username/job-matching"
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection to GitHub"
  type        = string
  default     = ""
}

variable "notification_email" {
  description = "Email address to receive deployment notifications"
  type        = string
  default     = "admin@example.com"
}

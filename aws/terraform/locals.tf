locals {
  # Common name prefix for resources
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags to be applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    Application = "Job Matching API"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Security group rules
  sg_rules = {
    http = {
      port        = 80
      protocol    = "tcp"
      description = "HTTP traffic"
    }
    https = {
      port        = 443
      protocol    = "tcp"
      description = "HTTPS traffic"
    }
    ssh = {
      port        = 22
      protocol    = "tcp"
      description = "SSH access"
    }
    app = {
      port        = var.app_port
      protocol    = "tcp"
      description = "Application traffic"
    }
    redis = {
      port        = 6379
      protocol    = "tcp"
      description = "Redis traffic"
    }
  }
  
  # Availability zones
  az_count = length(var.availability_zones)
  
  # CIDR blocks
  vpc_cidr       = var.vpc_cidr
  private_cidrs  = var.private_subnet_cidrs
  public_cidrs   = var.public_subnet_cidrs
  
  # EC2 instance configuration
  ec2_config = {
    ami_id        = var.ami_id
    instance_type = var.instance_type
    key_name      = var.key_name
  }
  
  # Auto Scaling configuration
  asg_config = {
    min_size         = var.asg_min_size
    max_size         = var.asg_max_size
    desired_capacity = var.asg_desired_capacity
  }
  
  # Redis configuration
  redis_config = {
    node_type       = var.redis_node_type
    engine_version  = "6.x"
    parameter_group = "default.redis6.x"
  }
  
  # CI/CD configuration
  cicd_config = {
    github_repo     = var.github_repository
    github_branch   = var.github_branch
    codestar_arn    = var.codestar_connection_arn
    notification_email = var.notification_email
  }
  
  # Domain configuration
  domain_config = {
    domain_names    = var.domain_names
    certificate_arn = var.certificate_arn
    zone_id         = var.route53_zone_id
  }
  
  # WAF configuration
  waf_config = {
    rate_limit      = 2000
    scope           = "REGIONAL"
  }
  
  # Backup configuration
  backup_config = {
    daily_retention   = 30
    weekly_retention  = 90
    monthly_retention = 365
  }
  
  # Monitoring configuration
  monitoring_config = {
    dashboard_name     = "${var.project_name}-dashboard"
    log_retention_days = 30
    alarm_threshold = {
      cpu_high       = 80
      memory_high    = 80
      error_count    = 5
      response_time  = 2
    }
  }
}

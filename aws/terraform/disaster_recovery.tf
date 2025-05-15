# AWS Disaster Recovery Configuration

# Secondary region provider
provider "aws" {
  alias  = "secondary_region"
  region = var.dr_region
}

# KMS key for secondary region
resource "aws_kms_key" "backup_secondary" {
  provider                = aws.secondary_region
  description             = "KMS key for backup vault in secondary region"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  tags = local.common_tags
}

# KMS key alias for secondary region
resource "aws_kms_alias" "backup_secondary" {
  provider      = aws.secondary_region
  name          = "alias/${var.project_name}-backup-key-${var.environment}-dr"
  target_key_id = aws_kms_key.backup_secondary.key_id
}

# Secondary region VPC
module "vpc_dr" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  
  providers = {
    aws = aws.secondary_region
  }
  
  name = "${var.project_name}-vpc-${var.environment}-dr"
  cidr = var.vpc_cidr_dr
  
  azs             = var.availability_zones_dr
  private_subnets = var.private_subnet_cidrs_dr
  public_subnets  = var.public_subnet_cidrs_dr
  
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  one_nat_gateway_per_az = var.environment == "production"
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = local.common_tags
}

# Secondary region security group for EC2 instances
resource "aws_security_group" "app_sg_dr" {
  provider    = aws.secondary_region
  name        = "${var.project_name}-app-sg-${var.environment}-dr"
  description = "Security group for application servers in DR region"
  vpc_id      = module.vpc_dr.vpc_id
  
  dynamic "ingress" {
    for_each = local.app_security_group_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-app-sg-${var.environment}-dr"
    }
  )
}

# Secondary region ALB
resource "aws_lb" "app_lb_dr" {
  provider           = aws.secondary_region
  name               = "${var.project_name}-alb-${var.environment}-dr"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg_dr.id]
  subnets            = module.vpc_dr.public_subnets
  
  enable_deletion_protection = var.environment == "production"
  
  access_logs {
    bucket  = aws_s3_bucket.lb_logs_dr.id
    prefix  = "alb-logs"
    enabled = true
  }
  
  tags = local.common_tags
}

# S3 bucket for ALB logs in DR region
resource "aws_s3_bucket" "lb_logs_dr" {
  provider = aws.secondary_region
  bucket   = "${var.project_name}-lb-logs-${var.environment}-dr"
  
  tags = local.common_tags
}

# S3 bucket versioning for ALB logs in DR region
resource "aws_s3_bucket_versioning" "lb_logs_dr" {
  provider = aws.secondary_region
  bucket   = aws_s3_bucket.lb_logs_dr.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption for ALB logs in DR region
resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs_dr" {
  provider = aws.secondary_region
  bucket   = aws_s3_bucket.lb_logs_dr.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket policy for ALB logs in DR region
resource "aws_s3_bucket_policy" "lb_logs_dr" {
  provider = aws.secondary_region
  bucket   = aws_s3_bucket.lb_logs_dr.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.lb_logs_dr.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.lb_logs_dr.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.lb_logs_dr.arn
      }
    ]
  })
}

# Secondary region Auto Scaling Group
resource "aws_launch_template" "app_lt_dr" {
  provider      = aws.secondary_region
  name_prefix   = "${var.project_name}-lt-${var.environment}-dr-"
  image_id      = var.ec2_ami_dr
  instance_type = local.instance_type
  
  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }
  
  vpc_security_group_ids = [aws_security_group.app_sg_dr.id]
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    project_name = var.project_name
    environment  = var.environment
    region       = var.dr_region
  }))
  
  block_device_mappings {
    device_name = "/dev/sda1"
    
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  monitoring {
    enabled = true
  }
  
  tag_specifications {
    resource_type = "instance"
    
    tags = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-app-${var.environment}-dr"
      }
    )
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Secondary region Auto Scaling Group
resource "aws_autoscaling_group" "app_dr" {
  provider = aws.secondary_region
  name     = "${var.project_name}-asg-${var.environment}-dr"
  
  min_size         = 0
  max_size         = local.asg_max_size
  desired_capacity = 0 # Start with 0 instances in DR region
  
  vpc_zone_identifier = module.vpc_dr.private_subnets
  
  launch_template {
    id      = aws_launch_template.app_lt_dr.id
    version = "$Latest"
  }
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  target_group_arns = [aws_lb_target_group.app_tg_dr.arn]
  
  termination_policies = ["OldestLaunchTemplate", "OldestInstance"]
  
  dynamic "tag" {
    for_each = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-app-${var.environment}-dr"
      }
    )
    
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Secondary region ALB target group
resource "aws_lb_target_group" "app_tg_dr" {
  provider    = aws.secondary_region
  name        = "${var.project_name}-tg-${var.environment}-dr"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc_dr.vpc_id
  target_type = "instance"
  
  health_check {
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  
  tags = local.common_tags
}

# Secondary region ALB listener
resource "aws_lb_listener" "app_listener_dr" {
  provider          = aws.secondary_region
  load_balancer_arn = aws_lb.app_lb_dr.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert_dr.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg_dr.arn
  }
  
  tags = local.common_tags
}

# Secondary region ACM certificate
resource "aws_acm_certificate" "cert_dr" {
  provider          = aws.secondary_region
  domain_name       = "dr.${var.domain_name}"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = local.common_tags
}

# Secondary region Route53 record for ACM validation
resource "aws_route53_record" "cert_validation_dr" {
  provider = aws.secondary_region
  for_each = {
    for dvo in aws_acm_certificate.cert_dr.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Secondary region ACM certificate validation
resource "aws_acm_certificate_validation" "cert_dr" {
  provider                = aws.secondary_region
  certificate_arn         = aws_acm_certificate.cert_dr.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_dr : record.fqdn]
}

# Route53 failover record for primary region
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.app_lb.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-health-check-primary-${var.environment}"
    }
  )
}

# Route53 failover record for DR region
resource "aws_route53_health_check" "dr" {
  fqdn              = aws_lb.app_lb_dr.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-health-check-dr-${var.environment}"
    }
  )
}

# Route53 primary record
resource "aws_route53_record" "primary" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
  
  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}

# Route53 DR record
resource "aws_route53_record" "dr" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier  = "dr"
  health_check_id = aws_route53_health_check.dr.id
  
  alias {
    name                   = aws_lb.app_lb_dr.dns_name
    zone_id                = aws_lb.app_lb_dr.zone_id
    evaluate_target_health = true
  }
}

# Lambda function for DR testing
resource "aws_lambda_function" "dr_testing" {
  function_name = "${var.project_name}-dr-testing-${var.environment}"
  handler       = "index.handler"
  role          = aws_iam_role.dr_testing_role.arn
  runtime       = "nodejs14.x"
  timeout       = 300
  
  filename         = "${path.module}/lambda/dr_testing.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/dr_testing.zip")
  
  environment {
    variables = {
      PRIMARY_ASG_NAME = aws_autoscaling_group.app.name
      DR_ASG_NAME      = aws_autoscaling_group.app_dr.name
      SNS_TOPIC_ARN    = aws_sns_topic.alerts.arn
    }
  }
  
  tags = local.common_tags
}

# IAM role for DR testing Lambda
resource "aws_iam_role" "dr_testing_role" {
  name = "${var.project_name}-dr-testing-role-${var.environment}"
  
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

# IAM policy for DR testing Lambda
resource "aws_iam_policy" "dr_testing_policy" {
  name        = "${var.project_name}-dr-testing-policy-${var.environment}"
  description = "Policy for DR testing Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "route53:GetHealthCheck",
          "route53:UpdateHealthCheck"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
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

# Attach DR testing policy to Lambda role
resource "aws_iam_role_policy_attachment" "dr_testing_policy_attachment" {
  role       = aws_iam_role.dr_testing_role.name
  policy_arn = aws_iam_policy.dr_testing_policy.arn
}

# CloudWatch Event Rule for scheduled DR testing
resource "aws_cloudwatch_event_rule" "dr_testing" {
  name                = "${var.project_name}-dr-testing-${var.environment}"
  description         = "Schedule for automated DR testing"
  schedule_expression = "cron(0 2 ? * SUN#1 *)" # 2 AM UTC on the first Sunday of each month
  
  tags = local.common_tags
}

# CloudWatch Event Target for DR testing
resource "aws_cloudwatch_event_target" "dr_testing" {
  rule      = aws_cloudwatch_event_rule.dr_testing.name
  target_id = "dr-testing-lambda"
  arn       = aws_lambda_function.dr_testing.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "dr_testing" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_testing.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_testing.arn
}

# Output DR region resources
output "dr_vpc_id" {
  description = "ID of the VPC in the DR region"
  value       = module.vpc_dr.vpc_id
}

output "dr_alb_dns_name" {
  description = "DNS name of the ALB in the DR region"
  value       = aws_lb.app_lb_dr.dns_name
}

output "dr_asg_name" {
  description = "Name of the Auto Scaling Group in the DR region"
  value       = aws_autoscaling_group.app_dr.name
}

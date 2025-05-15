# Route53 DNS configuration for the Job Matching API

# Create DNS records for the ALB
resource "aws_route53_record" "app_dns" {
  for_each = { for idx, domain in var.domain_names : domain => idx }
  
  zone_id = var.route53_zone_id
  name    = each.key
  type    = "A"
  
  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}

# Create DNS records for the CloudFront distribution (optional)
resource "aws_route53_record" "cloudfront_dns" {
  count = var.certificate_arn != "" ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = "cdn.${var.domain_names[0]}"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.app_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.app_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create DNS records for the API Gateway (optional)
resource "aws_route53_record" "api_gateway_dns" {
  count = var.certificate_arn != "" ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = "api.${var.domain_names[0]}"
  type    = "A"
  
  alias {
    name                   = aws_api_gateway_domain_name.job_matching_domain[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.job_matching_domain[0].regional_zone_id
    evaluate_target_health = false
  }
}

# Custom domain for API Gateway (optional)
resource "aws_api_gateway_domain_name" "job_matching_domain" {
  count = var.certificate_arn != "" ? 1 : 0
  
  domain_name              = "api.${var.domain_names[0]}"
  regional_certificate_arn = var.certificate_arn
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = local.common_tags
}

# API Gateway base path mapping
resource "aws_api_gateway_base_path_mapping" "job_matching_mapping" {
  count = var.certificate_arn != "" ? 1 : 0
  
  api_id      = aws_api_gateway_rest_api.job_matching_api.id
  stage_name  = aws_api_gateway_stage.job_matching_stage.stage_name
  domain_name = aws_api_gateway_domain_name.job_matching_domain[0].domain_name
}

# Health check for the ALB
resource "aws_route53_health_check" "alb_health_check" {
  fqdn              = aws_lb.app_lb.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-health-check"
    }
  )
}

# DNS Failover Configuration (optional)
# Uncomment and configure if you want to set up DNS failover to a secondary region

# resource "aws_route53_record" "app_dns_primary" {
#   for_each = { for idx, domain in var.domain_names : domain => idx }
#   
#   zone_id = var.route53_zone_id
#   name    = each.key
#   type    = "A"
#   
#   failover_routing_policy {
#     type = "PRIMARY"
#   }
#   
#   set_identifier = "${each.key}-primary"
#   health_check_id = aws_route53_health_check.alb_health_check.id
#   
#   alias {
#     name                   = aws_lb.app_lb.dns_name
#     zone_id                = aws_lb.app_lb.zone_id
#     evaluate_target_health = true
#   }
# }
# 
# resource "aws_route53_record" "app_dns_secondary" {
#   for_each = { for idx, domain in var.domain_names : domain => idx }
#   
#   zone_id = var.route53_zone_id
#   name    = each.key
#   type    = "A"
#   
#   failover_routing_policy {
#     type = "SECONDARY"
#   }
#   
#   set_identifier = "${each.key}-secondary"
#   
#   alias {
#     name                   = "secondary-alb-dns-name"
#     zone_id                = "secondary-alb-zone-id"
#     evaluate_target_health = true
#   }
# }

# AWS Inspector configuration for security assessment

# Enable AWS Inspector
resource "aws_inspector_resource_group" "main" {
  tags = {
    Inspect = "true"
  }
}

# Create an assessment target
resource "aws_inspector_assessment_target" "main" {
  name               = "${var.project_name}-assessment-target-${var.environment}"
  resource_group_arn = aws_inspector_resource_group.main.arn
}

# Create an assessment template for network assessment
resource "aws_inspector_assessment_template" "network" {
  name       = "${var.project_name}-network-assessment-${var.environment}"
  target_arn = aws_inspector_assessment_target.main.arn
  duration   = 3600
  
  rules_package_arns = [
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-PmNV0Tcd"
  ]
  
  tags = local.common_tags
}

# Create an assessment template for security best practices
resource "aws_inspector_assessment_template" "security" {
  name       = "${var.project_name}-security-assessment-${var.environment}"
  target_arn = aws_inspector_assessment_target.main.arn
  duration   = 3600
  
  rules_package_arns = [
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-R01qwB5Q"
  ]
  
  tags = local.common_tags
}

# Create an assessment template for CIS benchmarks
resource "aws_inspector_assessment_template" "cis" {
  name       = "${var.project_name}-cis-assessment-${var.environment}"
  target_arn = aws_inspector_assessment_target.main.arn
  duration   = 3600
  
  rules_package_arns = [
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-rExsr2X8"
  ]
  
  tags = local.common_tags
}

# Create an assessment template for vulnerability assessment
resource "aws_inspector_assessment_template" "vulnerability" {
  name       = "${var.project_name}-vulnerability-assessment-${var.environment}"
  target_arn = aws_inspector_assessment_target.main.arn
  duration   = 3600
  
  rules_package_arns = [
    "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rulespackage/0-JJOtZiqQ"
  ]
  
  tags = local.common_tags
}

# Create an assessment run schedule for network assessment
resource "aws_cloudwatch_event_rule" "inspector_network_schedule" {
  name                = "${var.project_name}-inspector-network-schedule-${var.environment}"
  description         = "Schedule for AWS Inspector network assessment"
  schedule_expression = "rate(7 days)"
  
  tags = local.common_tags
}

# Create an assessment run schedule for security best practices
resource "aws_cloudwatch_event_rule" "inspector_security_schedule" {
  name                = "${var.project_name}-inspector-security-schedule-${var.environment}"
  description         = "Schedule for AWS Inspector security assessment"
  schedule_expression = "rate(7 days)"
  
  tags = local.common_tags
}

# Create an assessment run schedule for CIS benchmarks
resource "aws_cloudwatch_event_rule" "inspector_cis_schedule" {
  name                = "${var.project_name}-inspector-cis-schedule-${var.environment}"
  description         = "Schedule for AWS Inspector CIS assessment"
  schedule_expression = "rate(7 days)"
  
  tags = local.common_tags
}

# Create an assessment run schedule for vulnerability assessment
resource "aws_cloudwatch_event_rule" "inspector_vulnerability_schedule" {
  name                = "${var.project_name}-inspector-vulnerability-schedule-${var.environment}"
  description         = "Schedule for AWS Inspector vulnerability assessment"
  schedule_expression = "rate(7 days)"
  
  tags = local.common_tags
}

# Create an event target for network assessment
resource "aws_cloudwatch_event_target" "inspector_network_target" {
  rule      = aws_cloudwatch_event_rule.inspector_network_schedule.name
  target_id = "inspector-network-assessment"
  arn       = "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:target/${aws_inspector_assessment_target.main.id}/template/${aws_inspector_assessment_template.network.id}"
  role_arn  = aws_iam_role.inspector_event_role.arn
}

# Create an event target for security best practices
resource "aws_cloudwatch_event_target" "inspector_security_target" {
  rule      = aws_cloudwatch_event_rule.inspector_security_schedule.name
  target_id = "inspector-security-assessment"
  arn       = "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:target/${aws_inspector_assessment_target.main.id}/template/${aws_inspector_assessment_template.security.id}"
  role_arn  = aws_iam_role.inspector_event_role.arn
}

# Create an event target for CIS benchmarks
resource "aws_cloudwatch_event_target" "inspector_cis_target" {
  rule      = aws_cloudwatch_event_rule.inspector_cis_schedule.name
  target_id = "inspector-cis-assessment"
  arn       = "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:target/${aws_inspector_assessment_target.main.id}/template/${aws_inspector_assessment_template.cis.id}"
  role_arn  = aws_iam_role.inspector_event_role.arn
}

# Create an event target for vulnerability assessment
resource "aws_cloudwatch_event_target" "inspector_vulnerability_target" {
  rule      = aws_cloudwatch_event_rule.inspector_vulnerability_schedule.name
  target_id = "inspector-vulnerability-assessment"
  arn       = "arn:aws:inspector:${var.aws_region}:${data.aws_caller_identity.current.account_id}:target/${aws_inspector_assessment_target.main.id}/template/${aws_inspector_assessment_template.vulnerability.id}"
  role_arn  = aws_iam_role.inspector_event_role.arn
}

# Create an IAM role for CloudWatch Events to start Inspector assessments
resource "aws_iam_role" "inspector_event_role" {
  name = "${var.project_name}-inspector-event-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# Create an IAM policy for CloudWatch Events to start Inspector assessments
resource "aws_iam_policy" "inspector_event_policy" {
  name        = "${var.project_name}-inspector-event-policy-${var.environment}"
  description = "Policy for CloudWatch Events to start Inspector assessments"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "inspector:StartAssessmentRun"
        Resource = [
          aws_inspector_assessment_template.network.arn,
          aws_inspector_assessment_template.security.arn,
          aws_inspector_assessment_template.cis.arn,
          aws_inspector_assessment_template.vulnerability.arn
        ]
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "inspector_event_policy_attachment" {
  role       = aws_iam_role.inspector_event_role.name
  policy_arn = aws_iam_policy.inspector_event_policy.arn
}

# Create a CloudWatch Event rule for Inspector findings
resource "aws_cloudwatch_event_rule" "inspector_findings" {
  name        = "${var.project_name}-inspector-findings-${var.environment}"
  description = "Capture AWS Inspector findings"
  
  event_pattern = jsonencode({
    source      = ["aws.inspector"]
    detail_type = ["Inspector Finding"]
    detail = {
      severity = ["High", "Critical"]
    }
  })
  
  tags = local.common_tags
}

# Create a CloudWatch Event target for Inspector findings
resource "aws_cloudwatch_event_target" "inspector_findings_target" {
  rule      = aws_cloudwatch_event_rule.inspector_findings.name
  target_id = "inspector-findings-sns"
  arn       = aws_sns_topic.alerts.arn
}

# Output Inspector assessment template ARNs
output "inspector_network_template_arn" {
  description = "ARN of the Inspector network assessment template"
  value       = aws_inspector_assessment_template.network.arn
}

output "inspector_security_template_arn" {
  description = "ARN of the Inspector security assessment template"
  value       = aws_inspector_assessment_template.security.arn
}

output "inspector_cis_template_arn" {
  description = "ARN of the Inspector CIS assessment template"
  value       = aws_inspector_assessment_template.cis.arn
}

output "inspector_vulnerability_template_arn" {
  description = "ARN of the Inspector vulnerability assessment template"
  value       = aws_inspector_assessment_template.vulnerability.arn
}

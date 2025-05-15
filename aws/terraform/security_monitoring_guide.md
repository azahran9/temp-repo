# Security Monitoring and Compliance Guide

## Overview

This guide provides comprehensive information about the security monitoring and compliance infrastructure implemented for the Job Matching API. It covers the various security services, dashboards, automated assessments, and incident response procedures.

## Security Services

### AWS GuardDuty

GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect AWS accounts and workloads.

**Implementation Details:**
- Enabled with 15-minute finding publishing frequency
- Monitors S3 logs, Kubernetes audit logs, and EC2 instances for malware
- Findings are sent to an SNS topic for alerting
- Critical findings trigger CloudWatch alarms

**Dashboard Integration:**
- GuardDuty findings are displayed on the Security Dashboard
- Metrics include findings by severity, type, and resource

### AWS Config

AWS Config provides a detailed view of the configuration of AWS resources and their compliance with security rules.

**Implementation Details:**
- Records all supported resource types, including global resources
- Delivers configuration snapshots to an S3 bucket every 6 hours
- Configured with multiple security rules to enforce best practices

**Implemented Config Rules:**
- `ROOT_ACCOUNT_MFA_ENABLED`: Ensures the root account has MFA enabled
- `IAM_PASSWORD_POLICY`: Enforces a strong password policy
- `S3_BUCKET_PUBLIC_READ_PROHIBITED`: Prevents public read access to S3 buckets
- `S3_BUCKET_PUBLIC_WRITE_PROHIBITED`: Prevents public write access to S3 buckets
- `ENCRYPTED_VOLUMES`: Ensures EBS volumes are encrypted
- `RDS_STORAGE_ENCRYPTED`: Ensures RDS storage is encrypted

### AWS Security Hub

Security Hub provides a comprehensive view of security alerts and compliance status across AWS accounts.

**Implementation Details:**
- Enabled with multiple security standards:
  - CIS AWS Foundations Benchmark v1.2.0
  - PCI DSS v3.2.1
  - AWS Foundational Security Best Practices v1.0.0
- Findings are sent to an SNS topic for alerting
- Critical findings trigger CloudWatch alarms

**Dashboard Integration:**
- Security Hub findings are displayed on the Security Dashboard
- Metrics include compliance status and findings by standard

### AWS IAM Access Analyzer

IAM Access Analyzer helps identify resources shared with external entities, highlighting potential security risks.

**Implementation Details:**
- Configured to analyze the entire AWS account
- Findings are sent to an SNS topic for alerting

**Dashboard Integration:**
- Access Analyzer findings are displayed on the Security Dashboard
- Metrics include external access by resource type

### AWS Inspector

Inspector automatically assesses applications for vulnerabilities or deviations from best practices.

**Implementation Details:**
- Configured to run weekly assessments (Sundays at midnight UTC)
- Assesses resources tagged with `Inspect: true`
- Includes multiple rules packages:
  - Security Best Practices
  - Runtime Behavior Analysis
  - CIS Operating System Security Configuration Benchmarks
  - Common Vulnerabilities and Exposures (CVE)
- Findings are sent to an SNS topic for alerting

**Dashboard Integration:**
- Inspector findings are displayed on the Security Dashboard
- Metrics include findings by severity and type

## Automated Security Assessment

A custom Lambda function performs daily security assessments to identify potential security issues.

**Implementation Details:**
- Runs daily at 3:00 AM UTC
- Assesses IAM, S3, RDS, and EC2 security configurations
- Publishes metrics to CloudWatch
- Sends notifications for critical findings

**Assessment Areas:**

1. **IAM Security:**
   - Access keys older than 90 days
   - Users without MFA
   - Inactive users
   - Policies with full administrative access

2. **S3 Security:**
   - Public buckets
   - Unencrypted buckets
   - Buckets without logging

3. **RDS Security:**
   - Publicly accessible instances
   - Unencrypted instances
   - Instances without backup

4. **EC2 Security:**
   - Instances with public IPs
   - Security groups with open ports
   - Unencrypted EBS volumes

**Dashboard Integration:**
- A dedicated Security Assessment Dashboard displays the results
- Metrics are categorized by severity and service area
- Includes best practices for each service area

## Security Dashboards

### Main Security Dashboard

The main security dashboard provides a comprehensive view of the security posture across all AWS services.

**Widgets:**
- GuardDuty findings by severity
- Security Hub compliance status
- IAM Access Analyzer findings
- AWS Shield DDoS events
- WAF blocked requests
- CloudTrail API call volume
- Config compliance status
- Inspector findings by severity

### Security Assessment Dashboard

The security assessment dashboard displays the results of the daily automated security assessment.

**Widgets:**
- Security findings by severity
- Security findings distribution (pie chart)
- IAM security issues
- S3 security issues
- RDS security issues
- EC2 security issues
- Best practices for each service area

## Alerting and Notifications

Security alerts are sent through an SNS topic to notify the security team about potential issues.

**Alert Types:**
- GuardDuty findings (severity 4+)
- Security Hub findings (HIGH and CRITICAL)
- Inspector findings (HIGH and CRITICAL)
- Config rule non-compliance
- Security assessment critical findings
- Failed security assessments

**Notification Format:**
- Includes severity, finding type, and affected resource
- Provides a description of the issue
- Includes a link to the relevant console for further investigation

## Incident Response

The incident response process is documented in the [Security Incident Response Plan](./security_incident_response.md).

**Key Components:**
- Incident classification
- Incident response team roles
- Detection and analysis procedures
- Containment strategies
- Eradication and recovery processes
- Post-incident analysis

## Compliance Reporting

Compliance reports are generated automatically to demonstrate adherence to various security standards.

**Supported Standards:**
- CIS AWS Foundations Benchmark
- PCI DSS
- HIPAA
- SOC 2
- GDPR

**Report Generation:**
- Reports are generated monthly
- Stored in a dedicated S3 bucket
- Accessible through the AWS Console

## Security Monitoring Best Practices

### Regular Reviews

- Review security findings daily
- Conduct weekly security meetings to discuss findings
- Perform monthly compliance reviews
- Update security policies quarterly

### Continuous Improvement

- Regularly update security rules and policies
- Implement new AWS security features as they become available
- Conduct regular penetration testing
- Update incident response procedures based on lessons learned

### Documentation

- Keep all security documentation up to date
- Document all security incidents and resolutions
- Maintain an inventory of all security controls
- Document exceptions and compensating controls

## Terraform Implementation

The security monitoring infrastructure is implemented using Terraform in the following files:

- `security_monitoring.tf`: GuardDuty, Config, Security Hub, IAM Access Analyzer, Inspector
- `security_assessment.tf`: Automated security assessment Lambda function and dashboard
- `dashboards.tf`: Main security dashboard
- `lambda/security_assessment.js`: Security assessment Lambda function code

## Getting Started

To deploy the security monitoring infrastructure:

1. Review the Terraform configuration files
2. Package the Lambda functions:
   ```
   cd lambda
   ./package_security_assessment.sh  # or package_security_assessment.ps1 on Windows
   ```
3. Apply the Terraform configuration:
   ```
   terraform init
   terraform plan
   terraform apply
   ```
4. Access the security dashboards in the CloudWatch console

## Maintenance and Troubleshooting

### Common Issues

1. **Missing Metrics:**
   - Ensure the Lambda functions have the correct permissions
   - Check CloudWatch Logs for errors
   - Verify that the metrics namespace is correct

2. **False Positives:**
   - Review and update GuardDuty suppression rules
   - Adjust Security Hub control parameters
   - Update the security assessment logic as needed

3. **Alert Fatigue:**
   - Adjust severity thresholds for notifications
   - Implement better filtering for common issues
   - Consider implementing automated remediation for low-risk issues

### Regular Maintenance Tasks

1. **Weekly:**
   - Review and address all HIGH and CRITICAL findings
   - Verify that all scheduled assessments ran successfully

2. **Monthly:**
   - Review and update suppression rules
   - Check for new AWS security features to implement
   - Verify compliance with all required standards

3. **Quarterly:**
   - Conduct a full review of all security configurations
   - Update documentation and procedures
   - Test the incident response process

## Conclusion

This comprehensive security monitoring infrastructure provides continuous visibility into the security posture of the Job Matching API. By leveraging AWS security services and custom assessments, it helps identify and address security issues before they can be exploited.

Regular reviews of security findings, along with continuous improvement of security controls, will ensure that the infrastructure remains secure as it evolves over time.

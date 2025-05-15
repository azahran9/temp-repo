# Job Matching API AWS Infrastructure

This repository contains the Terraform configuration for deploying the Job Matching API infrastructure on AWS. The infrastructure is designed to be scalable, secure, and highly available.

## Architecture Overview

The Job Matching API infrastructure consists of the following components:

### Compute
- **EC2 Instances**: Application servers running in an Auto Scaling Group
- **Lambda Functions**: Serverless functions for job matching and other tasks

### Networking
- **VPC**: Virtual Private Cloud with public and private subnets
- **ALB**: Application Load Balancer for distributing traffic
- **CloudFront**: Content Delivery Network for static assets
- **API Gateway**: Managed API service for Lambda integration

### Database
- **MongoDB Atlas**: Managed MongoDB service for storing job and user data
- **ElastiCache (Redis)**: In-memory cache for session management and caching

### Storage
- **S3**: Object storage for static assets and artifacts

### Security
- **IAM**: Identity and Access Management for resource access control
- **WAF**: Web Application Firewall for protection against common web exploits
- **KMS**: Key Management Service for encryption
- **Secrets Manager**: Secure storage for sensitive information
- **Inspector**: Automated security assessment service
- **CloudTrail**: Audit logging for API calls
- **Config**: Configuration compliance monitoring
- **Shield Advanced**: DDoS protection for critical resources
- **GuardDuty**: Threat detection service
- **Security Hub**: Security posture management
- **IAM Access Analyzer**: Identifies unintended resource access
- **VPC Flow Logs**: Network traffic logging and analysis

### CI/CD
- **CodePipeline**: Continuous integration and delivery pipeline
- **CodeBuild**: Build service for compiling source code
- **CodeDeploy**: Deployment service for EC2 instances

### Monitoring
- **CloudWatch**: Monitoring and observability service
- **SNS**: Simple Notification Service for alerts
- **CloudWatch Dashboards**: Custom dashboards for security, cost, and performance monitoring

### Backup and Recovery
- **AWS Backup**: Centralized backup service for EC2, RDS, ElastiCache, and S3
- **Cross-Region Backup**: Secondary backup vault in another region for disaster recovery
- **Continuous Backup**: Point-in-time recovery for critical resources
- **Automated Backup Testing**: Regular validation of backup integrity

### Cost Management
- **AWS Budgets**: Budget tracking for overall and service-specific costs
- **Cost Explorer**: Cost analysis and optimization
- **Cost Anomaly Detection**: Automated detection of unusual spending patterns
- **Cost Reports**: Regular cost reports with resource allocation

## Directory Structure

```
terraform/
├── main.tf                  # Main Terraform configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── providers.tf             # Provider configuration
├── locals.tf                # Local values
├── vpc.tf                   # VPC configuration
├── ec2.tf                   # EC2 instances and Auto Scaling
├── alb.tf                   # Application Load Balancer
├── lambda.tf                # Lambda functions
├── api_gateway.tf           # API Gateway
├── cloudfront.tf            # CloudFront distribution
├── s3.tf                    # S3 buckets
├── elasticache.tf           # ElastiCache (Redis)
├── iam.tf                   # IAM roles and policies
├── waf.tf                   # Web Application Firewall
├── monitoring.tf            # CloudWatch dashboards and alarms
├── backup.tf                # AWS Backup
├── cicd.tf                  # CI/CD pipeline
├── route53.tf               # DNS configuration
├── cloudtrail.tf            # Audit logging
├── config.tf                # Configuration compliance
├── secrets.tf               # Secrets Manager
├── ssm.tf                   # Systems Manager Parameter Store
├── kms.tf                   # Key Management Service
├── inspector.tf             # Security assessment
├── state.tf                 # Terraform state management
├── terraform.tfvars.example # Example variables file
├── deploy.ps1               # PowerShell deployment script
├── deploy.sh                # Bash deployment script
├── user_data.sh             # EC2 user data script
├── cost_estimation.md       # Cost estimation
└── disaster_recovery.md     # Disaster recovery plan
```

## Prerequisites

- AWS CLI installed and configured
- Terraform v1.0.0 or later
- MongoDB Atlas account
- Domain name (optional)

## Deployment Instructions

### 1. Configure Variables

Copy the example variables file and update it with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to set your specific configuration values.

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan -out=tfplan
```

### 4. Apply the Configuration

```bash
terraform apply tfplan
```

### 5. Using Deployment Scripts

Alternatively, you can use the provided deployment scripts:

#### Windows

```powershell
.\deploy.ps1 -Action apply
```

#### Linux/macOS

```bash
chmod +x deploy.sh
./deploy.sh apply
```

## Security

### Identity and Access Management
- **IAM Roles and Policies** follow the principle of least privilege
- **IAM Access Analyzer** identifies unintended resource access
- **Service Control Policies** enforce organizational security standards
- **AWS SSO** for centralized access management

### Network Security
- **VPC Security Groups** restrict access to necessary ports only
- **Network ACLs** provide an additional layer of network security
- **VPC Flow Logs** capture and analyze network traffic
- **Private Subnets** for sensitive resources with no direct internet access
- **Transit Gateway** for secure VPC-to-VPC communication

### Data Protection
- **KMS** encrypts data at rest and in transit
- **Secrets Manager** securely stores and manages sensitive information
- **S3 Bucket Policies** enforce access controls and encryption
- **SSL/TLS** for all API communications

### Threat Detection and Prevention
- **AWS Shield Advanced** provides DDoS protection
- **WAF** protects against common web vulnerabilities (OWASP Top 10)
- **GuardDuty** offers continuous threat detection
- **Security Hub** centralizes security findings and compliance status

### Compliance and Auditing
- **CloudTrail** logs all API calls for audit purposes
- **AWS Config** monitors for compliance violations
- **Inspector** performs regular security assessments
- **Security Hub Standards** enforce compliance with industry standards (CIS, PCI DSS, etc.)

### Incident Response
- **CloudWatch Alarms** for security-related events
- **SNS Notifications** for immediate alerts
- **Lambda Functions** for automated remediation
- **Security Dashboards** for real-time security posture visualization

## Monitoring and Alerting

### Infrastructure Overview

### AWS Architecture

- **API Gateway**: Entry point for all API requests.
- **CloudFront**: CDN in front of API Gateway for caching and global delivery.
- **Application Layer**: Auto Scaling Group (EC2) or ECS Fargate runs the Node.js backend.
- **Database**: MongoDB Atlas (preferred) or AWS DocumentDB for high availability.
- **Lambda Function**: Serverless job-matching endpoint, integrated with API Gateway.
- **ElastiCache Redis**: For API caching and rate limiting.
- **IAM**: All resources use least privilege roles.
- **CloudWatch**: Logs, metrics, alarms for monitoring and alerting.

### Terraform Usage

1. Edit `terraform.tfvars` with your project and environment values.
2. Run:
   ```sh
   terraform init
   terraform plan
   terraform apply
   ```
3. Outputs will include ALB DNS, CloudFront URL, and API Gateway endpoint.

### CI/CD Pipeline

- GitHub Actions workflow runs tests and deploys via Terraform.
- Uses AWS credentials stored as GitHub secrets.
- Notifies on deployment status (Slack integration optional).

### Cost Optimization
- Use Fargate Spot/EC2 Spot or Reserved Instances for compute savings.
- Use managed MongoDB Atlas or DocumentDB for operational efficiency.
- Set up CloudWatch Budgets and alerts for cost monitoring.

### Monitoring
- CloudWatch metrics and alarms for ECS/EC2, API Gateway, Lambda, and costs.
- Log retention and error alerting enabled.

### Architecture Diagram
- See `architecture.drawio` and `architecture.png` for a visual overview.
- You can create/edit this diagram using [draw.io](https://draw.io).

### Infrastructure Monitoring
- **CloudWatch Dashboards** provide comprehensive visibility into the infrastructure:
  - **Main Dashboard**: Overall system health and performance metrics
  - **Security Dashboard**: WAF, GuardDuty, IAM Access Analyzer, and Shield metrics
  - **Cost Dashboard**: Budget tracking, anomaly detection, and optimization recommendations
  - **Performance Dashboard**: Application and database performance metrics
  - **Backup & DR Dashboard**: Backup job status, recovery point tracking, and test results
- **Custom Metrics** track application-specific performance indicators
- **Service Lens** for end-to-end service monitoring
- **Synthetics Canaries** for API and endpoint availability testing

### Alerting and Notifications
- **CloudWatch Alarms** trigger notifications for critical events and thresholds
- **SNS Topics** send alerts to email, SMS, and other endpoints
- **ChatOps Integration** with Slack and Microsoft Teams
- **PagerDuty Integration** for on-call management

### Logging and Analysis
- **CloudWatch Logs** centrally stores application and system logs
- **Log Insights** for advanced log analysis and querying
- **Contributor Insights** to identify top contributors to system load
- **X-Ray** for distributed tracing and performance analysis

### Anomaly Detection
- **CloudWatch Anomaly Detection** for identifying unusual patterns
- **Cost Anomaly Detection** for unusual spending patterns
- **GuardDuty Findings** for security anomalies
- **Machine Learning-based Alerting** to reduce false positives

## Backup and Disaster Recovery

### Backup Strategy
- **AWS Backup** creates regular backups of EC2 instances, RDS, ElastiCache, and S3
- **Daily, Weekly, and Monthly** backup schedules with appropriate retention periods
- **Continuous Backup** with point-in-time recovery for critical resources
- **Cross-Region Backup** to a secondary region for disaster recovery
- **Automated Backup Testing** to validate backup integrity on a regular schedule
- **Backup Notifications** via SNS for completion, failure, and other events

### Disaster Recovery Strategy
- **Multi-AZ Deployment** ensures high availability within a region
- **Cross-Region Infrastructure** in a secondary region for disaster recovery
- **Route53 Failover Routing** for automatic failover to the DR region
- **Regular DR Testing** via automated processes to ensure readiness
- **Recovery Time Objective (RTO)**: < 1 hour for critical components
- **Recovery Point Objective (RPO)**: < 15 minutes for critical data

Detailed recovery procedures and runbooks are available in the `disaster_recovery.md` document.

## Cost Optimization

### Budget Management
- **AWS Budgets** for overall and service-specific cost tracking
- **Budget Alerts** at 80%, 90%, and 100% thresholds
- **Usage-Based Budgets** for monitoring resource consumption

### Cost Analysis and Reporting
- **Cost Explorer Integration** for detailed cost analysis
- **Cost Anomaly Detection** to identify unusual spending patterns
- **Monthly Cost Reports** automatically generated and stored in S3
- **Cost Allocation Tags** for accurate attribution of costs to projects and teams

### Automated Cost Optimization
- **Lambda Functions** for automated cost optimization tasks:
  - Identifying idle resources
  - Right-sizing recommendations for EC2 instances
  - Stopping non-production resources outside business hours
  - Lifecycle policies for S3 objects
  - Identifying unattached EBS volumes and elastic IPs

### Cost-Efficient Architecture
- **Auto Scaling** adjusts capacity based on demand
- **Spot Instances** for non-critical, fault-tolerant workloads
- **Reserved Instances** for predictable workloads
- **Savings Plans** for long-term compute commitments
- **S3 Intelligent Tiering** for automatic storage class optimization

Detailed cost breakdown, optimization strategies, and ROI analysis are available in the `cost_estimation.md` document.

## CI/CD Pipeline

The infrastructure includes a CI/CD pipeline that:

1. Detects changes in the GitHub repository
2. Builds the application
3. Runs tests
4. Deploys to the target environment

## Maintenance and Updates

- Regular security patches are applied through the CI/CD pipeline
- Infrastructure updates can be applied using Terraform
- Monitoring and alerting ensure quick response to issues

## Troubleshooting

- Check CloudWatch Logs for application errors
- Review CloudTrail for API call issues
- Inspect CloudWatch dashboards for performance metrics
- Use AWS Systems Manager Session Manager for EC2 instance access

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Security Monitoring Infrastructure

A comprehensive security monitoring infrastructure has been implemented to provide continuous visibility into the security posture of the Job Matching API. This includes:

- **AWS GuardDuty**: Continuous threat detection and monitoring
- **AWS Config**: Configuration compliance monitoring
- **AWS Security Hub**: Centralized security findings and compliance checks
- **IAM Access Analyzer**: Identification of resources shared with external entities
- **Automated Security Assessment**: Daily security checks across IAM, S3, RDS, and EC2 resources

For detailed information about the security monitoring infrastructure, refer to the [Security Monitoring Guide](./security_monitoring_guide.md).

## CI/CD Pipeline

A CI/CD pipeline has been implemented using GitHub Actions to automate the deployment process. The pipeline includes:

- **Validation**: Terraform format check and validation
- **Testing**: Automated testing of Lambda functions
- **Security Scanning**: Static analysis of Terraform code using tfsec and checkov
- **Planning**: Generation of Terraform plan for review
- **Deployment**: Automated deployment to AWS
- **Notification**: Slack notifications for deployment status

The pipeline configuration is located in the `.github/workflows/terraform-ci.yml` file.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

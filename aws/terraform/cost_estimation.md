# Cost Estimation for Job Matching API Infrastructure

This document provides an estimated monthly cost breakdown for the AWS infrastructure deployed for the Job Matching API. These estimates are based on the AWS Pricing Calculator and assume the default configuration specified in the Terraform files.

## Cost Breakdown by Service

| Service | Configuration | Estimated Monthly Cost (USD) |
|---------|--------------|------------------------------|
| **EC2 Instances** | 2 x t3.micro, on-demand, Linux | $16.80 |
| **Application Load Balancer** | 1 ALB, 8,760 hours/month | $22.27 |
| **NAT Gateway** | 1 NAT Gateway, 8,760 hours/month | $32.85 |
| **ElastiCache Redis** | 1 x cache.t3.micro node | $13.14 |
| **Lambda Function** | 1M invocations/month, 128MB memory, 200ms avg. duration | $0.42 |
| **API Gateway** | 1M requests/month | $3.50 |
| **CloudFront** | 100GB data transfer, 1M requests | $10.00 |
| **Route53** | 1 hosted zone, 1M queries | $1.00 |
| **S3 Storage** | 5GB storage, 1,000 PUT/POST/LIST requests, 10,000 GET requests | $0.15 |
| **CloudWatch** | 5 dashboards, 10 alarms, 5GB logs | $13.00 |
| **AWS Backup** | 100GB backup storage | $5.00 |
| **CodePipeline** | 1 pipeline | $1.00 |
| **CodeBuild** | 100 build minutes/month | $0.50 |
| **CodeDeploy** | Free tier | $0.00 |
| **WAF** | 1M requests/month | $5.00 |
| **Systems Manager Parameter Store** | Standard parameters | $0.00 |
| **Total Estimated Monthly Cost** | | **$124.63** |

## Cost Optimization Strategies

1. **Reserved Instances**: Consider purchasing Reserved Instances for EC2 and ElastiCache to reduce costs by up to 75% for predictable workloads.

2. **Auto Scaling**: Configure Auto Scaling to scale down during periods of low traffic to reduce EC2 costs.

3. **Lambda Optimization**: Optimize Lambda function memory allocation and code efficiency to reduce execution duration and costs.

4. **CloudFront Caching**: Implement aggressive caching policies in CloudFront to reduce origin requests and data transfer costs.

5. **S3 Lifecycle Policies**: Implement lifecycle policies to transition infrequently accessed objects to cheaper storage classes.

6. **CloudWatch Logs Retention**: Set appropriate retention periods for CloudWatch Logs to reduce storage costs.

7. **NAT Gateway Sharing**: Consider sharing a single NAT Gateway across multiple subnets if high availability is not critical.

8. **Spot Instances**: For non-critical workloads, consider using Spot Instances to reduce EC2 costs by up to 90%.

## Environment-Specific Cost Estimates

### Development Environment

For development environments, you can reduce costs by:
- Using smaller instance types (t3.nano or t3.micro)
- Reducing the number of instances to 1
- Eliminating redundancy (e.g., single AZ deployment)
- Using a single NAT Gateway
- Reducing backup frequency and retention

**Estimated Monthly Cost for Development Environment**: $50-70

### Production Environment

For production environments, you might increase costs by:
- Using larger instance types (t3.small or t3.medium)
- Increasing the number of instances (3-5)
- Implementing full redundancy across multiple AZs
- Implementing more frequent backups with longer retention
- Adding additional monitoring and alerting

**Estimated Monthly Cost for Production Environment**: $200-300

## Cost Monitoring and Governance

### AWS Budgets Implementation

We've implemented the following budgets in our infrastructure:

1. **Monthly Overall Budget**: $150 with alerts at 80%, 90%, and 100% thresholds
2. **Service-Specific Budgets**:
   - EC2: $30/month
   - Lambda: $10/month
   - S3: $5/month
   - RDS: $25/month
   - ElastiCache: $15/month

### Cost Anomaly Detection

We've configured Cost Anomaly Detection with the following monitors:

1. **AWS Services Monitor**: Tracks anomalies across all AWS services
2. **Service-Specific Monitors**: Dedicated monitors for EC2, Lambda, and S3
3. **Tag-Based Monitors**: Separate monitors for production and development environments

Alerts are configured to notify the following:
- Email notifications to the finance team and technical leads
- SNS topic for integration with monitoring systems
- Daily summary reports for minor anomalies
- Immediate alerts for significant anomalies (>20% deviation)

### Automated Cost Optimization

We've implemented automated cost optimization through Lambda functions that:

1. **Identify Idle Resources**:
   - EC2 instances with <5% CPU utilization for 7 consecutive days
   - Unattached EBS volumes and Elastic IPs
   - Unused Elastic Load Balancers

2. **Right-Sizing Recommendations**:
   - EC2 instances that consistently use <40% of allocated resources
   - Over-provisioned RDS instances
   - Lambda functions with excessive memory allocation

3. **Schedule-Based Resource Management**:
   - Automatically stop non-production resources outside business hours
   - Scale down development environments during weekends

### Resource Tagging Strategy

We enforce the following tags on all resources:

| Tag Key | Description | Example Values |
|---------|-------------|----------------|
| `Environment` | Deployment environment | `production`, `staging`, `development` |
| `Project` | Project name | `job-matching-api` |
| `Owner` | Team or individual responsible | `backend-team`, `data-team` |
| `CostCenter` | Financial cost center | `marketing`, `engineering` |
| `Terraform` | Managed by Terraform | `true` |

### Regular Cost Reviews

We've established a process for regular cost reviews:

1. **Weekly Quick Reviews**: Brief check of current spending and anomalies
2. **Monthly Detailed Analysis**: Comprehensive review with optimization recommendations
3. **Quarterly Strategic Review**: Long-term cost trends and major optimization initiatives

## Disclaimer

These cost estimates are approximations based on AWS pricing at the time of writing. Actual costs may vary based on usage patterns, AWS pricing changes, and specific configuration choices. Always refer to the [AWS Pricing Calculator](https://calculator.aws.amazon.com/) for the most up-to-date estimates.

# Job Matching API - AWS Infrastructure

This directory contains the Terraform code to deploy the Job Matching API to AWS. The infrastructure is designed following AWS best practices for scalability, security, high availability, and cost optimization.

## Architecture Overview

![AWS Architecture Diagram](https://via.placeholder.com/800x600.png?text=Job+Matching+API+AWS+Architecture)

The infrastructure is designed to be scalable, secure, and highly available:

- **VPC**: Isolated network with public and private subnets across multiple availability zones
- **EC2 Instances**: Deployed in an Auto Scaling Group for high availability and scalability
- **Application Load Balancer**: Distributes traffic to EC2 instances
- **ElastiCache Redis**: For caching API responses and session management
- **Lambda Function**: For job matching algorithm, separated for better scalability
- **API Gateway**: Provides a RESTful API endpoint for the job matching Lambda function
- **CloudFront**: CDN for content delivery with edge caching
- **Route53**: DNS management for custom domain names
- **CloudWatch**: Monitoring and logging for all components
- **WAF**: Web Application Firewall for security
- **AWS Backup**: Automated backup solution
- **CodePipeline**: CI/CD pipeline for automated deployments

## Infrastructure Components

### Networking

- **VPC**: Isolated network environment with a CIDR block of 10.0.0.0/16
- **Subnets**: 3 public and 3 private subnets across different availability zones
- **NAT Gateway**: Allows instances in private subnets to access the internet
- **Internet Gateway**: Provides internet access for public subnets
- **Route Tables**: Configured for proper traffic routing

### Compute

- **EC2 Instances**: Deployed in an Auto Scaling Group for high availability
- **Launch Template**: Defines the instance configuration
- **Auto Scaling Policies**: Scale based on CPU utilization
- **Lambda Function**: Serverless compute for job matching algorithm

### Database and Caching

- **MongoDB Atlas**: External managed MongoDB service (not managed by Terraform)
- **ElastiCache Redis**: In-memory caching for improved performance

### Content Delivery

- **CloudFront**: CDN for static content delivery
- **Application Load Balancer**: Distributes traffic to backend instances
- **API Gateway**: Manages API endpoints for Lambda functions

### Security

- **Security Groups**: Restrict traffic to only necessary ports
- **IAM Roles**: Follow the principle of least privilege
- **WAF**: Protects against common web exploits
- **SSL/TLS**: All traffic is encrypted in transit

### Monitoring and Logging

- **CloudWatch Dashboards**: Visualize system performance
- **CloudWatch Alarms**: Alert on critical metrics
- **CloudWatch Logs**: Centralized logging for all components
- **SNS Topics**: Notification system for alerts

### CI/CD Pipeline

- **CodeBuild**: Builds and tests the application
- **CodeDeploy**: Deploys the application to EC2 instances
- **CodePipeline**: Orchestrates the CI/CD workflow
- **S3 Bucket**: Stores deployment artifacts

## Deployment Instructions

### Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. Terraform CLI installed (v1.0.0 or later)
3. MongoDB Atlas cluster set up (or other MongoDB provider)
4. SSL certificate in AWS Certificate Manager for your domain
5. GitHub repository with your application code
6. AWS CodeStar connection to your GitHub repository

### Configuration

1. Create a `terraform.tfvars` file with your specific configuration (use the provided `terraform.tfvars.example` as a template):

```hcl
aws_region       = "us-east-1"
project_name     = "job-matching"
environment      = "production"
mongodb_uri      = "mongodb+srv://username:password@cluster.mongodb.net/job-matching"
certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-ef56-gh78-ij90-klmnopqrstuv"
domain_names     = ["api.yourdomain.com"]
route53_zone_id  = "Z1234567890ABCDEFGHIJ"
github_repository = "your-github-username/job-matching"
github_branch     = "main"
codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/abcdef01-2345-6789-abcd-ef0123456789"
notification_email = "your-email@example.com"
```

2. Package the Lambda function:

```bash
cd terraform/lambda
npm install
zip -r ../job-matching.zip *
cd ..
```

### Deployment

1. Initialize Terraform:

```bash
cd terraform
terraform init
```

2. Plan the deployment:

```bash
terraform plan -out=tfplan
```

3. Apply the deployment:

```bash
terraform apply tfplan
```

### Post-Deployment

After deployment, Terraform will output important information:

- ALB DNS name
- CloudFront domain name
- API Gateway invoke URL
- Redis endpoint
- CI/CD pipeline URL

Update your application configuration to use these endpoints.

## Security Considerations

- **Network Security**: EC2 instances are in private subnets, not directly accessible from the internet
- **Traffic Encryption**: All traffic between components is encrypted using TLS
- **Access Control**: Security groups restrict traffic to only necessary ports
- **IAM Roles**: Follow the principle of least privilege
- **Secrets Management**: Sensitive data is stored in environment variables or AWS Systems Manager Parameter Store
- **WAF Protection**: Web Application Firewall protects against common web exploits
- **Rate Limiting**: Prevents abuse of the API

## Scaling Considerations

- **Horizontal Scaling**: Auto Scaling Group adjusts the number of EC2 instances based on CPU utilization
- **Vertical Scaling**: Instance types can be adjusted based on workload requirements
- **Caching**: ElastiCache Redis can be scaled vertically or horizontally as needed
- **Serverless**: Lambda functions automatically scale based on incoming requests
- **Content Delivery**: CloudFront provides edge caching to reduce load on the origin servers

## Monitoring and Logging

- **Centralized Logging**: CloudWatch Logs capture application logs
- **Performance Metrics**: CloudWatch Metrics track system performance
- **Alerting**: CloudWatch Alarms trigger scaling actions or notifications
- **Dashboards**: Custom CloudWatch dashboards provide visibility into system health
- **Distributed Tracing**: X-Ray can be enabled for distributed tracing

## Backup and Disaster Recovery

- **Automated Backups**: AWS Backup provides automated backups of critical resources
- **Multi-AZ Deployment**: Resources are deployed across multiple availability zones
- **Data Durability**: MongoDB Atlas provides built-in replication and backups
- **Recovery Procedures**: Documented procedures for disaster recovery

## Cost Optimization

- **Auto Scaling**: Resources scale up and down based on demand
- **Reserved Instances**: Consider purchasing Reserved Instances for predictable workloads
- **Spot Instances**: Consider using Spot Instances for non-critical workloads
- **CloudFront Caching**: Reduces origin requests and associated costs
- **Lambda Pricing**: Pay only for what you use with serverless computing

## Maintenance and Updates

- **CI/CD Pipeline**: Automated deployments reduce manual intervention
- **Infrastructure as Code**: All infrastructure is defined as code for easy updates
- **Blue/Green Deployments**: CodeDeploy supports blue/green deployments for zero-downtime updates
- **Patching**: Auto Scaling Groups can be configured for automatic instance refreshes

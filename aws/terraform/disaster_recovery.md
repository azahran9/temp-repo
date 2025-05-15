# Disaster Recovery Plan for Job Matching API

This document outlines the disaster recovery (DR) procedures for the Job Matching API infrastructure deployed on AWS. It provides guidance on how to respond to various failure scenarios and restore service operations.

## Recovery Objectives

- **Recovery Time Objective (RTO)**: 1 hour
- **Recovery Point Objective (RPO)**: 15 minutes

## Backup Strategy

### AWS Backup Implementation

We use AWS Backup as a centralized service to manage and automate backups across multiple AWS services. Our backup strategy includes:

#### Primary Region Backup Vault

| Resource Type | Backup Frequency | Retention Period | Notes |
|--------------|------------------|------------------|-------|
| **EC2 Instances** | Daily | 7 days | Full AMI snapshots |
| | Weekly | 30 days | Full AMI snapshots |
| | Monthly | 365 days | Full AMI snapshots |
| **ElastiCache Redis** | Daily | 7 days | Full snapshots |
| | Weekly | 30 days | Full snapshots |
| **RDS Databases** | Daily | 7 days | Full snapshots |
| | Continuous | 24 hours | Point-in-time recovery |
| **EFS File Systems** | Daily | 30 days | Full backups |
| **S3 Buckets** | Continuous | N/A | Versioning enabled |
| | N/A | 365 days | Lifecycle policy for non-current versions |

#### Secondary Region Backup Vault (Disaster Recovery)

A secondary backup vault is maintained in the DR region with the following configuration:

| Resource Type | Copy Frequency | Retention Period | Notes |
|--------------|----------------|------------------|-------|
| **EC2 Instances** | Weekly | 30 days | Cross-region copy of weekly backups |
| | Monthly | 365 days | Cross-region copy of monthly backups |
| **ElastiCache Redis** | Weekly | 30 days | Cross-region copy of weekly backups |
| **RDS Databases** | Weekly | 30 days | Cross-region copy of weekly backups |
| **EFS File Systems** | Weekly | 30 days | Cross-region copy of weekly backups |

### Backup Testing and Validation

To ensure the integrity and reliability of our backups, we have implemented:

1. **Automated Backup Testing**: Weekly Lambda function that:
   - Restores a sample EC2 instance from backup
   - Performs basic health checks
   - Validates application functionality
   - Reports results to CloudWatch and SNS

2. **Quarterly Full Recovery Tests**:
   - Complete restoration of critical systems in an isolated environment
   - Full application functionality testing
   - Performance benchmarking
   - Documentation of recovery time and any issues encountered

### Additional Backup Measures

1. **MongoDB Atlas**: Continuous backups with point-in-time recovery (managed by MongoDB Atlas)
   - 7-day point-in-time recovery window
   - Cross-region replication for disaster recovery

2. **Configuration Management**:
   - All infrastructure is defined as code in Terraform
   - Terraform state files backed up in versioned S3 buckets
   - Git repositories with complete history of infrastructure code

3. **Backup Monitoring**:
   - CloudWatch alarms for failed backup jobs
   - SNS notifications for backup events
   - Weekly backup status reports

## Failure Scenarios and Recovery Procedures

### 1. Single EC2 Instance Failure

**Detection**:
- CloudWatch alarms for instance health checks
- ALB health checks failing for a specific instance

**Recovery Procedure**:
1. Auto Scaling Group will automatically replace the failed instance
2. No manual intervention required
3. Monitor CloudWatch logs to ensure the new instance is functioning properly

**Estimated Recovery Time**: 5-10 minutes

### 2. Availability Zone Failure

**Detection**:
- Multiple CloudWatch alarms across services
- AWS Health Dashboard notifications

**Recovery Procedure**:
1. Auto Scaling Group will automatically launch new instances in healthy AZs
2. ALB will route traffic to healthy instances
3. Monitor CloudWatch logs to ensure the application is functioning properly

**Estimated Recovery Time**: 10-15 minutes

### 3. ElastiCache Redis Failure

**Detection**:
- CloudWatch alarms for Redis health
- Application logs showing Redis connection errors

**Recovery Procedure**:
1. For single node failure in a cluster, automatic failover occurs
2. For complete cluster failure:
   a. Create a new Redis cluster from the most recent backup
   b. Update the parameter store with the new Redis endpoint
   c. Restart the application to connect to the new Redis cluster

**Estimated Recovery Time**: 15-30 minutes

### 4. MongoDB Atlas Failure

**Detection**:
- MongoDB Atlas alerts
- Application logs showing database connection errors

**Recovery Procedure**:
1. MongoDB Atlas provides automatic failover for replica set failures
2. For regional outages affecting MongoDB Atlas:
   a. Contact MongoDB Atlas support to initiate cross-region failover
   b. Update the parameter store with the new MongoDB connection string if necessary
   c. Restart the application if necessary

**Estimated Recovery Time**: 15-30 minutes

### 5. Complete Region Failure

**Detection**:
- AWS Health Dashboard notifications
- Multiple service failures across the region
- CloudWatch cross-region alarms
- Route53 health checks failing for primary region endpoints

**Recovery Procedure**:

#### Automated Failover (Preferred Method)
1. Route53 health checks detect the primary region failure
2. Route53 failover routing policy automatically directs traffic to the secondary region
3. The secondary region infrastructure is already running in a scaled-down state (warm standby)
4. Auto Scaling Groups in the secondary region scale up to handle the increased load
5. CloudWatch alarms monitor the failover process and notify the operations team

#### Manual Failover (If Automated Failover Fails)
1. Determine if the outage is temporary or extended
2. For extended outages:
   a. Login to AWS Console or use AWS CLI from a secure location
   b. Manually update Route53 routing to direct traffic to the secondary region
   c. Scale up resources in the secondary region using Terraform if needed
   d. Verify that the application is functioning properly in the secondary region
   e. Update status page and notify stakeholders

**Estimated Recovery Time**: 
- Automated Failover: 5-15 minutes
- Manual Failover: 20-40 minutes

#### Secondary Region Infrastructure

The following infrastructure is maintained in the secondary region (as defined in `disaster_recovery.tf`):

1. **Network Infrastructure**:
   - VPC with public and private subnets
   - Security Groups
   - NAT Gateways
   - Transit Gateway connections (if applicable)

2. **Compute Resources**:
   - Auto Scaling Groups with minimal capacity (scaled up during failover)
   - Application Load Balancer
   - Lambda functions (if applicable)

3. **Database and Cache**:
   - ElastiCache Redis in standby mode
   - MongoDB Atlas with cross-region replication

4. **Storage**:
   - S3 buckets with cross-region replication
   - EBS volumes for EC2 instances

5. **Security**:
   - KMS keys for encryption
   - IAM roles and policies
   - WAF configurations

#### Failback Procedure

Once the primary region is operational again:

1. Verify that all services in the primary region are fully operational
2. Ensure data synchronization between regions is complete
3. Gradually shift traffic back to the primary region (10% increments)
4. Monitor application performance and error rates during the transition
5. Once traffic is fully shifted back, scale down the secondary region resources
6. Conduct a post-mortem analysis and update DR procedures if necessary

### 6. Accidental Data Deletion or Corruption

**Detection**:
- Application logs showing unexpected data behavior
- User reports of missing or incorrect data

**Recovery Procedure**:
1. Identify the scope and source of the data issue
2. For MongoDB data:
   a. Use MongoDB Atlas point-in-time recovery to restore to a state before the corruption
   b. Validate the data integrity after restoration
3. For Redis data:
   a. Restore from the most recent backup
   b. Rebuild cache data if necessary

**Estimated Recovery Time**: 30-45 minutes

### 7. CI/CD Pipeline Failure

**Detection**:
- Failed CodePipeline executions
- Failed CodeBuild or CodeDeploy jobs

**Recovery Procedure**:
1. Identify the specific failure point in the pipeline
2. Fix the issue (code, configuration, permissions)
3. Retry the pipeline
4. If deployment is corrupted, roll back to the previous version:
   a. Use CodeDeploy rollback feature
   b. Or manually deploy the previous known good version

## Automated Backup Testing

To ensure that our backups are valid and can be successfully restored when needed, we have implemented an automated backup testing system. This system regularly tests the restoration process and validates the integrity of backup data.

### Testing Process

1. **Scheduled Testing**: Automated tests run weekly (every Sunday at 3:00 AM UTC) to validate backup integrity
2. **Test Procedure**:
   - Selects the most recent recovery point from the backup vault
   - Initiates a test restore to a temporary environment
   - Validates the restored resource to ensure data integrity
   - Publishes metrics on test success/failure and duration
   - Cleans up temporary resources
3. **Monitoring and Alerting**:
   - Custom CloudWatch metrics track test results
   - CloudWatch alarms trigger notifications for test failures
   - Dedicated dashboard visualizes backup test history and performance

### Test Results and Reporting

1. **Success Metrics**:
   - Test success rate (percentage)
   - Test duration (seconds)
   - Resource-specific validation results
2. **Failure Handling**:
   - Immediate SNS notifications to the operations team
   - Detailed error logs for troubleshooting
   - Automatic retry mechanism for transient failures
3. **Reporting**:
   - Weekly summary report of all backup tests
   - Trend analysis of backup and restore performance
   - Recommendations for backup strategy optimization

The automated backup testing system is defined in `backup_testing.tf` and implemented through Lambda functions in the `lambda` directory.

**Estimated Recovery Time**: 15-30 minutes

## Disaster Recovery Testing

Regular DR testing should be conducted to ensure the effectiveness of the recovery procedures:

1. **Quarterly Testing Schedule**:
   - Simulate instance failures
   - Test recovery from backups
   - Validate RTO and RPO objectives

2. **Annual Full DR Exercise**:
   - Simulate a complete region failure
   - Deploy to a secondary region
   - Validate application functionality

3. **Documentation Updates**:
   - Update this DR plan after each test
   - Document lessons learned and improvements

## Roles and Responsibilities

| Role | Responsibilities |
|------|------------------|
| **DevOps Engineer** | - Monitor alerts<br>- Execute recovery procedures<br>- Maintain DR documentation |
| **Database Administrator** | - Manage database backups<br>- Execute database recovery procedures |
| **Application Developer** | - Assist with application-specific recovery<br>- Validate application functionality after recovery |
| **IT Manager** | - Coordinate DR efforts<br>- Communicate with stakeholders<br>- Make critical decisions during major outages |

## Communication Plan

During a disaster recovery event:

1. **Internal Communication**:
   - Use the designated emergency Slack channel
   - Schedule regular status update calls
   - Document all actions taken

2. **External Communication**:
   - Update the status page
   - Send email notifications to affected customers
   - Provide estimated resolution times when possible

## Recovery Verification

After executing recovery procedures:

1. **System Verification**:
   - Verify all services are running
   - Check CloudWatch metrics for normal patterns
   - Validate connectivity between services

2. **Application Verification**:
   - Run automated tests
   - Perform manual testing of critical paths
   - Verify data integrity

3. **Performance Verification**:
   - Monitor response times
   - Check for error rates
   - Ensure scalability is functioning

## Continuous Improvement

After each incident or DR test:

1. Conduct a post-mortem analysis
2. Identify areas for improvement
3. Update the DR plan
4. Implement preventive measures
5. Enhance monitoring and alerting

## Appendix: Recovery Checklists

### Quick Reference: EC2 Recovery

```
[ ] Verify Auto Scaling Group is replacing the instance
[ ] Check CloudWatch logs for startup errors
[ ] Verify the new instance is passing health checks
[ ] Confirm the application is functioning properly
```

### Quick Reference: Redis Recovery

```
[ ] Check if automatic failover occurred
[ ] If manual recovery is needed:
    [ ] Create new Redis cluster from backup
    [ ] Update parameter store with new endpoint
    [ ] Restart application servers
[ ] Verify cache functionality
```

### Quick Reference: Region Failover

```
[ ] Deploy infrastructure to secondary region
[ ] Restore Redis from backup
[ ] Confirm MongoDB Atlas failover
[ ] Update DNS records
[ ] Verify application functionality
[ ] Monitor performance in new region
```

/**
 * AWS Lambda function for performing automated security assessments
 * 
 * This function checks various security configurations and reports findings
 * to CloudWatch Metrics and an SNS topic for alerting.
 */

const AWS = require('aws-sdk');

// Initialize AWS clients
const iam = new AWS.IAM();
const s3 = new AWS.S3();
const rds = new AWS.RDS();
const ec2 = new AWS.EC2();
const cloudwatch = new AWS.CloudWatch();
const sns = new AWS.SNS();

// Environment variables
const PROJECT_NAME = process.env.PROJECT_NAME || 'job-matching-api';
const ENVIRONMENT = process.env.ENVIRONMENT || 'production';
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN || '';

// Main handler function
exports.handler = async (event) => {
    console.log('Starting security assessment...');
    
    try {
        // Run all security checks in parallel
        const [
            iamResults,
            s3Results,
            rdsResults,
            ec2Results
        ] = await Promise.all([
            checkIAMSecurity(),
            checkS3Security(),
            checkRDSSecurity(),
            checkEC2Security()
        ]);
        
        // Combine all results
        const allResults = {
            timestamp: new Date().toISOString(),
            iamResults,
            s3Results,
            rdsResults,
            ec2Results
        };
        
        // Publish metrics to CloudWatch
        await publishMetrics(allResults);
        
        // Send notification if there are high or critical findings
        const criticalFindings = findCriticalIssues(allResults);
        if (criticalFindings.length > 0) {
            await sendNotification(criticalFindings);
        }
        
        console.log('Security assessment completed successfully');
        return {
            statusCode: 200,
            body: JSON.stringify(allResults)
        };
    } catch (error) {
        console.error('Error during security assessment:', error);
        throw error;
    }
};

/**
 * Check IAM security configurations
 */
async function checkIAMSecurity() {
    console.log('Checking IAM security...');
    const results = {
        accessKeysOlderThan90Days: 0,
        usersWithoutMFA: 0,
        inactiveUsers: 0,
        policiesWithFullAdmin: 0,
        findings: []
    };
    
    // Get all IAM users
    const { Users } = await iam.listUsers().promise();
    
    // Check each user
    for (const user of Users) {
        // Check access key age
        const { AccessKeyMetadata } = await iam.listAccessKeys({ UserName: user.UserName }).promise();
        for (const key of AccessKeyMetadata) {
            const keyAge = Math.floor((new Date() - key.CreateDate) / (1000 * 60 * 60 * 24));
            if (keyAge > 90) {
                results.accessKeysOlderThan90Days++;
                results.findings.push({
                    severity: 'HIGH',
                    resource: `IAM User: ${user.UserName}`,
                    finding: `Access key ${key.AccessKeyId} is ${keyAge} days old (>90 days)`
                });
            }
        }
        
        // Check MFA status
        const { MFADevices } = await iam.listMFADevices({ UserName: user.UserName }).promise();
        if (MFADevices.length === 0) {
            results.usersWithoutMFA++;
            results.findings.push({
                severity: 'MEDIUM',
                resource: `IAM User: ${user.UserName}`,
                finding: 'User does not have MFA enabled'
            });
        }
        
        // Check for inactive users (no activity in last 90 days)
        if (user.PasswordLastUsed) {
            const lastActivity = Math.floor((new Date() - user.PasswordLastUsed) / (1000 * 60 * 60 * 24));
            if (lastActivity > 90) {
                results.inactiveUsers++;
                results.findings.push({
                    severity: 'LOW',
                    resource: `IAM User: ${user.UserName}`,
                    finding: `User has been inactive for ${lastActivity} days`
                });
            }
        }
    }
    
    // Check for policies with full admin access
    const { Policies } = await iam.listPolicies({ Scope: 'Local' }).promise();
    for (const policy of Policies) {
        const { PolicyVersion } = await iam.getPolicyVersion({
            PolicyArn: policy.Arn,
            VersionId: policy.DefaultVersionId
        }).promise();
        
        const document = JSON.parse(decodeURIComponent(PolicyVersion.Document));
        for (const statement of document.Statement) {
            if (
                statement.Effect === 'Allow' &&
                (statement.Action === '*' || 
                 (Array.isArray(statement.Action) && statement.Action.includes('*'))) &&
                (statement.Resource === '*' || 
                 (Array.isArray(statement.Resource) && statement.Resource.includes('*')))
            ) {
                results.policiesWithFullAdmin++;
                results.findings.push({
                    severity: 'HIGH',
                    resource: `IAM Policy: ${policy.PolicyName}`,
                    finding: 'Policy grants full administrative access (Action: *, Resource: *)'
                });
                break;
            }
        }
    }
    
    return results;
}

/**
 * Check S3 security configurations
 */
async function checkS3Security() {
    console.log('Checking S3 security...');
    const results = {
        publicBuckets: 0,
        unencryptedBuckets: 0,
        bucketsWithoutLogging: 0,
        findings: []
    };
    
    // Get all S3 buckets
    const { Buckets } = await s3.listBuckets().promise();
    
    // Check each bucket
    for (const bucket of Buckets) {
        const bucketName = bucket.Name;
        
        try {
            // Check bucket policy for public access
            try {
                const { Policy } = await s3.getBucketPolicy({ Bucket: bucketName }).promise();
                const policy = JSON.parse(Policy);
                
                // Check for public access in policy
                for (const statement of policy.Statement) {
                    if (
                        statement.Effect === 'Allow' &&
                        (statement.Principal === '*' || 
                         statement.Principal.AWS === '*' ||
                         (Array.isArray(statement.Principal.AWS) && statement.Principal.AWS.includes('*')))
                    ) {
                        results.publicBuckets++;
                        results.findings.push({
                            severity: 'CRITICAL',
                            resource: `S3 Bucket: ${bucketName}`,
                            finding: 'Bucket policy allows public access'
                        });
                        break;
                    }
                }
            } catch (error) {
                // No bucket policy is fine
                if (error.code !== 'NoSuchBucketPolicy') {
                    throw error;
                }
            }
            
            // Check bucket ACL for public access
            const { Grants } = await s3.getBucketAcl({ Bucket: bucketName }).promise();
            for (const grant of Grants) {
                if (
                    grant.Grantee.URI === 'http://acs.amazonaws.com/groups/global/AllUsers' ||
                    grant.Grantee.URI === 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers'
                ) {
                    results.publicBuckets++;
                    results.findings.push({
                        severity: 'CRITICAL',
                        resource: `S3 Bucket: ${bucketName}`,
                        finding: `Bucket ACL grants ${grant.Permission} permission to ${grant.Grantee.URI}`
                    });
                    break;
                }
            }
            
            // Check for encryption
            try {
                await s3.getBucketEncryption({ Bucket: bucketName }).promise();
            } catch (error) {
                if (error.code === 'ServerSideEncryptionConfigurationNotFoundError') {
                    results.unencryptedBuckets++;
                    results.findings.push({
                        severity: 'HIGH',
                        resource: `S3 Bucket: ${bucketName}`,
                        finding: 'Bucket does not have default encryption enabled'
                    });
                } else {
                    throw error;
                }
            }
            
            // Check for logging
            try {
                const { LoggingEnabled } = await s3.getBucketLogging({ Bucket: bucketName }).promise();
                if (!LoggingEnabled) {
                    results.bucketsWithoutLogging++;
                    results.findings.push({
                        severity: 'MEDIUM',
                        resource: `S3 Bucket: ${bucketName}`,
                        finding: 'Bucket does not have access logging enabled'
                    });
                }
            } catch (error) {
                throw error;
            }
        } catch (error) {
            console.error(`Error checking bucket ${bucketName}:`, error);
            // Continue with other buckets
        }
    }
    
    return results;
}

/**
 * Check RDS security configurations
 */
async function checkRDSSecurity() {
    console.log('Checking RDS security...');
    const results = {
        publiclyAccessibleInstances: 0,
        unencryptedInstances: 0,
        instancesWithoutBackup: 0,
        findings: []
    };
    
    // Get all RDS instances
    const { DBInstances } = await rds.describeDBInstances().promise();
    
    // Check each instance
    for (const instance of DBInstances) {
        // Check for public accessibility
        if (instance.PubliclyAccessible) {
            results.publiclyAccessibleInstances++;
            results.findings.push({
                severity: 'HIGH',
                resource: `RDS Instance: ${instance.DBInstanceIdentifier}`,
                finding: 'RDS instance is publicly accessible'
            });
        }
        
        // Check for encryption
        if (!instance.StorageEncrypted) {
            results.unencryptedInstances++;
            results.findings.push({
                severity: 'HIGH',
                resource: `RDS Instance: ${instance.DBInstanceIdentifier}`,
                finding: 'RDS instance storage is not encrypted'
            });
        }
        
        // Check for backups
        if (instance.BackupRetentionPeriod === 0) {
            results.instancesWithoutBackup++;
            results.findings.push({
                severity: 'MEDIUM',
                resource: `RDS Instance: ${instance.DBInstanceIdentifier}`,
                finding: 'RDS instance does not have automated backups enabled'
            });
        }
    }
    
    return results;
}

/**
 * Check EC2 security configurations
 */
async function checkEC2Security() {
    console.log('Checking EC2 security...');
    const results = {
        instancesWithPublicIp: 0,
        securityGroupsWithOpenPorts: 0,
        unencryptedVolumes: 0,
        findings: []
    };
    
    // Get all EC2 instances
    const { Reservations } = await ec2.describeInstances().promise();
    const instances = Reservations.flatMap(r => r.Instances);
    
    // Check each instance
    for (const instance of instances) {
        // Check for public IP
        if (instance.PublicIpAddress) {
            results.instancesWithPublicIp++;
            results.findings.push({
                severity: 'MEDIUM',
                resource: `EC2 Instance: ${instance.InstanceId}`,
                finding: `Instance has public IP: ${instance.PublicIpAddress}`
            });
        }
        
        // Check for unencrypted volumes
        for (const blockDevice of instance.BlockDeviceMappings) {
            if (blockDevice.Ebs) {
                const { Volumes } = await ec2.describeVolumes({
                    VolumeIds: [blockDevice.Ebs.VolumeId]
                }).promise();
                
                if (Volumes.length > 0 && !Volumes[0].Encrypted) {
                    results.unencryptedVolumes++;
                    results.findings.push({
                        severity: 'HIGH',
                        resource: `EC2 Volume: ${blockDevice.Ebs.VolumeId} (Instance: ${instance.InstanceId})`,
                        finding: 'EBS volume is not encrypted'
                    });
                }
            }
        }
    }
    
    // Check security groups
    const { SecurityGroups } = await ec2.describeSecurityGroups().promise();
    
    for (const sg of SecurityGroups) {
        // Check for open ports
        for (const ipPermission of sg.IpPermissions) {
            for (const ipRange of ipPermission.IpRanges) {
                if (ipRange.CidrIp === '0.0.0.0/0') {
                    const protocol = ipPermission.IpProtocol === '-1' ? 'All Traffic' : ipPermission.IpProtocol;
                    const portRange = ipPermission.FromPort === ipPermission.ToPort ? 
                        ipPermission.FromPort : 
                        `${ipPermission.FromPort}-${ipPermission.ToPort}`;
                    
                    results.securityGroupsWithOpenPorts++;
                    results.findings.push({
                        severity: 'HIGH',
                        resource: `Security Group: ${sg.GroupId} (${sg.GroupName})`,
                        finding: `Security group allows ${protocol} ${portRange || ''} from anywhere (0.0.0.0/0)`
                    });
                }
            }
        }
    }
    
    return results;
}

/**
 * Publish metrics to CloudWatch
 */
async function publishMetrics(results) {
    console.log('Publishing metrics to CloudWatch...');
    
    const metrics = [
        // IAM metrics
        {
            MetricName: 'AccessKeysOlderThan90Days',
            Value: results.iamResults.accessKeysOlderThan90Days,
            Unit: 'Count'
        },
        {
            MetricName: 'UsersWithoutMFA',
            Value: results.iamResults.usersWithoutMFA,
            Unit: 'Count'
        },
        {
            MetricName: 'InactiveUsers',
            Value: results.iamResults.inactiveUsers,
            Unit: 'Count'
        },
        {
            MetricName: 'PoliciesWithFullAdmin',
            Value: results.iamResults.policiesWithFullAdmin,
            Unit: 'Count'
        },
        
        // S3 metrics
        {
            MetricName: 'PublicBuckets',
            Value: results.s3Results.publicBuckets,
            Unit: 'Count'
        },
        {
            MetricName: 'UnencryptedBuckets',
            Value: results.s3Results.unencryptedBuckets,
            Unit: 'Count'
        },
        {
            MetricName: 'BucketsWithoutLogging',
            Value: results.s3Results.bucketsWithoutLogging,
            Unit: 'Count'
        },
        
        // RDS metrics
        {
            MetricName: 'PubliclyAccessibleRDSInstances',
            Value: results.rdsResults.publiclyAccessibleInstances,
            Unit: 'Count'
        },
        {
            MetricName: 'UnencryptedRDSInstances',
            Value: results.rdsResults.unencryptedInstances,
            Unit: 'Count'
        },
        {
            MetricName: 'RDSInstancesWithoutBackup',
            Value: results.rdsResults.instancesWithoutBackup,
            Unit: 'Count'
        },
        
        // EC2 metrics
        {
            MetricName: 'EC2InstancesWithPublicIP',
            Value: results.ec2Results.instancesWithPublicIp,
            Unit: 'Count'
        },
        {
            MetricName: 'SecurityGroupsWithOpenPorts',
            Value: results.ec2Results.securityGroupsWithOpenPorts,
            Unit: 'Count'
        },
        {
            MetricName: 'UnencryptedEBSVolumes',
            Value: results.ec2Results.unencryptedVolumes,
            Unit: 'Count'
        },
        
        // Summary metrics
        {
            MetricName: 'CriticalFindings',
            Value: countFindingsBySeverity(results, 'CRITICAL'),
            Unit: 'Count'
        },
        {
            MetricName: 'HighFindings',
            Value: countFindingsBySeverity(results, 'HIGH'),
            Unit: 'Count'
        },
        {
            MetricName: 'MediumFindings',
            Value: countFindingsBySeverity(results, 'MEDIUM'),
            Unit: 'Count'
        },
        {
            MetricName: 'LowFindings',
            Value: countFindingsBySeverity(results, 'LOW'),
            Unit: 'Count'
        }
    ];
    
    // Add dimensions to all metrics
    const metricsWithDimensions = metrics.map(metric => ({
        ...metric,
        Dimensions: [
            {
                Name: 'Project',
                Value: PROJECT_NAME
            },
            {
                Name: 'Environment',
                Value: ENVIRONMENT
            }
        ]
    }));
    
    // Split metrics into chunks of 20 (CloudWatch limit)
    const metricChunks = [];
    for (let i = 0; i < metricsWithDimensions.length; i += 20) {
        metricChunks.push(metricsWithDimensions.slice(i, i + 20));
    }
    
    // Publish each chunk
    for (const chunk of metricChunks) {
        await cloudwatch.putMetricData({
            Namespace: 'SecurityAssessment',
            MetricData: chunk
        }).promise();
    }
}

/**
 * Count findings by severity
 */
function countFindingsBySeverity(results, severity) {
    let count = 0;
    
    // Count IAM findings
    count += results.iamResults.findings.filter(f => f.severity === severity).length;
    
    // Count S3 findings
    count += results.s3Results.findings.filter(f => f.severity === severity).length;
    
    // Count RDS findings
    count += results.rdsResults.findings.filter(f => f.severity === severity).length;
    
    // Count EC2 findings
    count += results.ec2Results.findings.filter(f => f.severity === severity).length;
    
    return count;
}

/**
 * Find critical and high severity issues
 */
function findCriticalIssues(results) {
    const criticalFindings = [];
    
    // Add all critical and high findings
    ['CRITICAL', 'HIGH'].forEach(severity => {
        // IAM findings
        criticalFindings.push(...results.iamResults.findings.filter(f => f.severity === severity));
        
        // S3 findings
        criticalFindings.push(...results.s3Results.findings.filter(f => f.severity === severity));
        
        // RDS findings
        criticalFindings.push(...results.rdsResults.findings.filter(f => f.severity === severity));
        
        // EC2 findings
        criticalFindings.push(...results.ec2Results.findings.filter(f => f.severity === severity));
    });
    
    return criticalFindings;
}

/**
 * Send notification for critical findings
 */
async function sendNotification(criticalFindings) {
    if (!SNS_TOPIC_ARN) {
        console.log('SNS_TOPIC_ARN not set, skipping notification');
        return;
    }
    
    console.log('Sending notification for critical findings...');
    
    // Format message
    let message = `Security Assessment - Critical Findings (${new Date().toISOString()})\n\n`;
    message += `Found ${criticalFindings.length} critical or high severity issues:\n\n`;
    
    criticalFindings.forEach((finding, index) => {
        message += `${index + 1}. [${finding.severity}] ${finding.resource}\n`;
        message += `   ${finding.finding}\n\n`;
    });
    
    message += 'Please review these findings in the Security Dashboard and take appropriate action.\n';
    
    // Send SNS notification
    await sns.publish({
        TopicArn: SNS_TOPIC_ARN,
        Subject: `[${ENVIRONMENT.toUpperCase()}] Security Assessment - Critical Findings`,
        Message: message
    }).promise();
}

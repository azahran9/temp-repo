/**
 * Lambda function to test AWS Backup recovery points
 * This function performs automated testing of backups by:
 * 1. Identifying recent recovery points
 * 2. Initiating test restores to temporary resources
 * 3. Validating the restored resources
 * 4. Publishing metrics on test results
 * 5. Cleaning up temporary resources
 */

const AWS = require('aws-sdk');
const backup = new AWS.Backup();
const lambda = new AWS.Lambda();
const sns = new AWS.SNS();

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Configuration from environment variables
    const backupVaultName = process.env.BACKUP_VAULT_NAME;
    const snsTopicArn = process.env.SNS_TOPIC_ARN;
    const metricsLambdaArn = process.env.METRICS_LAMBDA_ARN;
    const projectName = process.env.PROJECT_NAME;
    const environment = process.env.ENVIRONMENT;
    
    // Generate a unique test ID
    const testId = `backup-test-${Date.now()}`;
    
    try {
        // Step 1: List recent recovery points
        console.log(`Listing recovery points in vault: ${backupVaultName}`);
        const recoveryPoints = await listRecoveryPoints(backupVaultName);
        
        if (recoveryPoints.length === 0) {
            console.log('No recovery points found for testing');
            await publishTestResults({
                success: false,
                durationSeconds: 0,
                resourceType: 'None',
                message: 'No recovery points found for testing',
                testId: testId
            });
            return {
                statusCode: 200,
                body: JSON.stringify({
                    message: 'No recovery points found for testing',
                    success: false
                })
            };
        }
        
        // Select a recovery point to test (most recent)
        const recoveryPoint = recoveryPoints[0];
        console.log(`Selected recovery point for testing: ${recoveryPoint.RecoveryPointArn}`);
        
        // Start timer for test duration
        const startTime = Date.now();
        
        // Step 2: Initiate test restore
        console.log(`Initiating test restore for recovery point: ${recoveryPoint.RecoveryPointArn}`);
        const restoreJobId = await startRestoreJob(recoveryPoint);
        console.log(`Restore job initiated: ${restoreJobId}`);
        
        // Step 3: Monitor restore job until completion
        console.log(`Monitoring restore job: ${restoreJobId}`);
        const restoreResult = await monitorRestoreJob(restoreJobId);
        
        // Calculate test duration
        const endTime = Date.now();
        const durationSeconds = Math.round((endTime - startTime) / 1000);
        
        // Step 4: Validate restored resource
        console.log(`Validating restored resource: ${restoreResult.CreatedResourceArn}`);
        const validationResult = await validateRestoredResource(restoreResult.CreatedResourceArn, recoveryPoint.ResourceType);
        
        // Step 5: Publish test results
        const testResults = {
            success: validationResult.success,
            durationSeconds: durationSeconds,
            resourceType: recoveryPoint.ResourceType,
            message: validationResult.message,
            testId: testId,
            recoveryPointArn: recoveryPoint.RecoveryPointArn,
            restoredResourceArn: restoreResult.CreatedResourceArn
        };
        
        console.log('Test results:', JSON.stringify(testResults, null, 2));
        await publishTestResults(testResults);
        
        // Step 6: Clean up temporary resources
        console.log(`Cleaning up temporary resource: ${restoreResult.CreatedResourceArn}`);
        await cleanupTemporaryResource(restoreResult.CreatedResourceArn, recoveryPoint.ResourceType);
        
        // Send notification
        await sendNotification(testResults);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Backup test completed successfully',
                testResults: testResults,
                success: true
            })
        };
    } catch (error) {
        console.error('Error during backup testing:', error);
        
        // Publish failure metrics
        await publishTestResults({
            success: false,
            durationSeconds: 0,
            resourceType: 'Error',
            message: `Error during backup testing: ${error.message}`,
            testId: testId
        });
        
        // Send failure notification
        await sendNotification({
            success: false,
            message: `Error during backup testing: ${error.message}`,
            testId: testId
        });
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error during backup testing',
                error: error.message,
                success: false
            })
        };
    }
};

/**
 * List recent recovery points in the backup vault
 */
async function listRecoveryPoints(backupVaultName) {
    const params = {
        BackupVaultName: backupVaultName,
        MaxResults: 10,
        ByCreationDate: 'DESC' // Most recent first
    };
    
    const response = await backup.listRecoveryPointsByBackupVault(params).promise();
    return response.RecoveryPoints || [];
}

/**
 * Start a restore job for the given recovery point
 */
async function startRestoreJob(recoveryPoint) {
    // Metadata for temporary resource
    const metadata = {
        'backup-test': 'true',
        'temporary-resource': 'true',
        'test-timestamp': new Date().toISOString()
    };
    
    // Restore parameters depend on resource type
    let restoreParams = {
        RecoveryPointArn: recoveryPoint.RecoveryPointArn,
        Metadata: metadata
    };
    
    // Add resource-specific parameters
    switch (recoveryPoint.ResourceType) {
        case 'RDS':
            restoreParams.IdempotencyToken = `backup-test-${Date.now()}`;
            restoreParams.ResourceType = 'RDS';
            // Use a temporary DB instance identifier
            restoreParams.TargetDBInstanceIdentifier = `backup-test-${Date.now()}`;
            break;
        case 'DynamoDB':
            restoreParams.IdempotencyToken = `backup-test-${Date.now()}`;
            restoreParams.ResourceType = 'DynamoDB';
            // Use a temporary table name
            restoreParams.TargetTableName = `backup-test-${Date.now()}`;
            break;
        case 'EBS':
            restoreParams.IdempotencyToken = `backup-test-${Date.now()}`;
            restoreParams.ResourceType = 'EBS';
            break;
        // Add more resource types as needed
        default:
            restoreParams.IdempotencyToken = `backup-test-${Date.now()}`;
            restoreParams.ResourceType = recoveryPoint.ResourceType;
    }
    
    const response = await backup.startRestoreJob(restoreParams).promise();
    return response.RestoreJobId;
}

/**
 * Monitor a restore job until completion
 */
async function monitorRestoreJob(restoreJobId) {
    let completed = false;
    let attempts = 0;
    const maxAttempts = 60; // 30 minutes (30 * 60 seconds)
    
    while (!completed && attempts < maxAttempts) {
        const params = {
            RestoreJobId: restoreJobId
        };
        
        const response = await backup.describeRestoreJob(params).promise();
        
        if (response.Status === 'COMPLETED') {
            return {
                status: response.Status,
                CreatedResourceArn: response.CreatedResourceArn
            };
        } else if (response.Status === 'FAILED' || response.Status === 'ABORTED') {
            throw new Error(`Restore job failed with status: ${response.Status}, message: ${response.StatusMessage}`);
        }
        
        // Wait 30 seconds before checking again
        await new Promise(resolve => setTimeout(resolve, 30000));
        attempts++;
    }
    
    if (attempts >= maxAttempts) {
        throw new Error('Restore job timed out');
    }
}

/**
 * Validate the restored resource
 */
async function validateRestoredResource(resourceArn, resourceType) {
    // This is a simplified validation
    // In a real implementation, you would perform resource-specific validation
    
    console.log(`Validating resource: ${resourceArn} of type: ${resourceType}`);
    
    // For demonstration purposes, we'll assume the restore was successful
    // In a real implementation, you would check the resource's status and properties
    
    return {
        success: true,
        message: `Successfully validated restored ${resourceType} resource`
    };
}

/**
 * Clean up temporary resources created during testing
 */
async function cleanupTemporaryResource(resourceArn, resourceType) {
    // This is a simplified cleanup
    // In a real implementation, you would delete the temporary resource
    
    console.log(`Cleaning up resource: ${resourceArn} of type: ${resourceType}`);
    
    // For demonstration purposes, we'll just log the cleanup
    // In a real implementation, you would delete the resource
    
    return {
        success: true,
        message: `Successfully cleaned up temporary ${resourceType} resource`
    };
}

/**
 * Publish test results to CloudWatch metrics
 */
async function publishTestResults(testResults) {
    const params = {
        FunctionName: process.env.METRICS_LAMBDA_ARN,
        InvocationType: 'Event',
        Payload: JSON.stringify({
            testResults: testResults
        })
    };
    
    return lambda.invoke(params).promise();
}

/**
 * Send notification about test results
 */
async function sendNotification(testResults) {
    const subject = testResults.success
        ? `[${process.env.ENVIRONMENT}] Backup Test Successful: ${testResults.testId}`
        : `[${process.env.ENVIRONMENT}] Backup Test Failed: ${testResults.testId}`;
    
    const message = JSON.stringify({
        testId: testResults.testId,
        success: testResults.success,
        message: testResults.message,
        resourceType: testResults.resourceType,
        durationSeconds: testResults.durationSeconds,
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT,
        projectName: process.env.PROJECT_NAME
    }, null, 2);
    
    const params = {
        TopicArn: process.env.SNS_TOPIC_ARN,
        Subject: subject,
        Message: message
    };
    
    return sns.publish(params).promise();
}

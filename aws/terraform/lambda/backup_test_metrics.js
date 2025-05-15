/**
 * Lambda function to publish custom metrics for backup testing
 * This function is triggered by the backup testing Lambda function
 * and publishes metrics to CloudWatch for monitoring backup test results
 */

const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    try {
        // Extract test results from the event
        const testResults = event.testResults || {};
        const testSuccess = testResults.success === true ? 100 : 0; // 100% for success, 0% for failure
        const testDuration = testResults.durationSeconds || 0;
        const resourceType = testResults.resourceType || 'Unknown';
        const testId = testResults.testId || 'Unknown';
        
        // Project name and environment from environment variables
        const projectName = process.env.PROJECT_NAME;
        const environment = process.env.ENVIRONMENT;
        
        // Publish metrics to CloudWatch
        const params = {
            MetricData: [
                {
                    MetricName: 'TestSuccess',
                    Dimensions: [
                        {
                            Name: 'Environment',
                            Value: environment
                        },
                        {
                            Name: 'ResourceType',
                            Value: resourceType
                        },
                        {
                            Name: 'TestId',
                            Value: testId
                        }
                    ],
                    Unit: 'Percent',
                    Value: testSuccess
                },
                {
                    MetricName: 'TestDuration',
                    Dimensions: [
                        {
                            Name: 'Environment',
                            Value: environment
                        },
                        {
                            Name: 'ResourceType',
                            Value: resourceType
                        },
                        {
                            Name: 'TestId',
                            Value: testId
                        }
                    ],
                    Unit: 'Seconds',
                    Value: testDuration
                }
            ],
            Namespace: `${projectName}/BackupTesting`
        };
        
        console.log('Publishing metrics:', JSON.stringify(params, null, 2));
        const result = await cloudwatch.putMetricData(params).promise();
        console.log('Metrics published successfully:', result);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Metrics published successfully',
                testId: testId,
                success: true
            })
        };
    } catch (error) {
        console.error('Error publishing metrics:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error publishing metrics',
                error: error.message,
                success: false
            })
        };
    }
};

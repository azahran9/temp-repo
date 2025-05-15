/**
 * AWS Lambda function for generating cost reports
 * 
 * This function:
 * 1. Retrieves cost data from AWS Cost Explorer
 * 2. Generates detailed cost reports
 * 3. Saves reports to S3
 * 4. Sends notifications via SNS
 */

const AWS = require('aws-sdk');

// Initialize AWS services
const ce = new AWS.CostExplorer({ region: 'us-east-1' }); // Cost Explorer is only available in us-east-1
const s3 = new AWS.S3();
const sns = new AWS.SNS();

// Environment variables
const S3_BUCKET_NAME = process.env.S3_BUCKET_NAME;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;
const ENVIRONMENT = process.env.ENVIRONMENT;

// Main handler
exports.handler = async (event) => {
    try {
        console.log('Starting cost report generation');
        
        // Get current date and format it
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const dateString = `${year}-${month}-${day}`;
        
        // Calculate date range for the report (last 30 days)
        const endDate = dateString;
        const startDate = calculateStartDate(now, 30);
        
        // Get cost data from Cost Explorer
        const costData = await getCostData(startDate, endDate);
        
        // Generate service breakdown report
        const serviceBreakdown = await getServiceBreakdown(startDate, endDate);
        
        // Generate tag-based cost allocation report
        const tagReport = await getTagReport(startDate, endDate);
        
        // Combine all reports
        const fullReport = {
            reportDate: dateString,
            environment: ENVIRONMENT,
            dateRange: {
                start: startDate,
                end: endDate
            },
            summary: costData,
            serviceBreakdown: serviceBreakdown,
            tagAllocation: tagReport
        };
        
        // Save report to S3
        const s3Key = `cost-reports/${ENVIRONMENT}/${year}/${month}/cost-report-${dateString}.json`;
        await saveReportToS3(fullReport, s3Key);
        
        // Send notification
        await sendNotification(dateString, fullReport.summary.totalCost);
        
        console.log('Cost report generation completed successfully');
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Cost report generated successfully',
                reportLocation: `s3://${S3_BUCKET_NAME}/${s3Key}`
            })
        };
    } catch (error) {
        console.error('Error generating cost report:', error);
        
        // Send error notification
        await sendErrorNotification(error.message);
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error generating cost report',
                error: error.message
            })
        };
    }
};

/**
 * Calculate start date by subtracting days from current date
 */
function calculateStartDate(currentDate, daysToSubtract) {
    const date = new Date(currentDate);
    date.setDate(date.getDate() - daysToSubtract);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

/**
 * Get cost data from AWS Cost Explorer
 */
async function getCostData(startDate, endDate) {
    const params = {
        TimePeriod: {
            Start: startDate,
            End: endDate
        },
        Granularity: 'MONTHLY',
        Metrics: ['UnblendedCost', 'UsageQuantity'],
        GroupBy: [
            {
                Type: 'DIMENSION',
                Key: 'SERVICE'
            }
        ]
    };
    
    const response = await ce.getCostAndUsage(params).promise();
    
    // Calculate total cost
    let totalCost = 0;
    response.ResultsByTime.forEach(result => {
        result.Groups.forEach(group => {
            totalCost += parseFloat(group.Metrics.UnblendedCost.Amount);
        });
    });
    
    return {
        totalCost: totalCost.toFixed(2),
        currency: response.ResultsByTime[0].Groups[0].Metrics.UnblendedCost.Unit,
        timePeriod: response.ResultsByTime.map(result => result.TimePeriod)
    };
}

/**
 * Get service breakdown from AWS Cost Explorer
 */
async function getServiceBreakdown(startDate, endDate) {
    const params = {
        TimePeriod: {
            Start: startDate,
            End: endDate
        },
        Granularity: 'MONTHLY',
        Metrics: ['UnblendedCost'],
        GroupBy: [
            {
                Type: 'DIMENSION',
                Key: 'SERVICE'
            }
        ]
    };
    
    const response = await ce.getCostAndUsage(params).promise();
    
    // Format service breakdown
    const serviceBreakdown = [];
    response.ResultsByTime.forEach(result => {
        result.Groups.forEach(group => {
            serviceBreakdown.push({
                service: group.Keys[0],
                cost: parseFloat(group.Metrics.UnblendedCost.Amount).toFixed(2),
                currency: group.Metrics.UnblendedCost.Unit
            });
        });
    });
    
    // Sort by cost (highest first)
    serviceBreakdown.sort((a, b) => parseFloat(b.cost) - parseFloat(a.cost));
    
    return serviceBreakdown;
}

/**
 * Get tag-based cost allocation report
 */
async function getTagReport(startDate, endDate) {
    const params = {
        TimePeriod: {
            Start: startDate,
            End: endDate
        },
        Granularity: 'MONTHLY',
        Metrics: ['UnblendedCost'],
        GroupBy: [
            {
                Type: 'TAG',
                Key: 'Environment'
            }
        ]
    };
    
    try {
        const response = await ce.getCostAndUsage(params).promise();
        
        // Format tag report
        const tagReport = [];
        response.ResultsByTime.forEach(result => {
            result.Groups.forEach(group => {
                const tagValue = group.Keys[0].includes('$') 
                    ? group.Keys[0].split('$')[1] 
                    : 'Untagged';
                
                tagReport.push({
                    tagKey: 'Environment',
                    tagValue: tagValue,
                    cost: parseFloat(group.Metrics.UnblendedCost.Amount).toFixed(2),
                    currency: group.Metrics.UnblendedCost.Unit
                });
            });
        });
        
        return tagReport;
    } catch (error) {
        console.warn('Error getting tag report:', error.message);
        return [{ error: 'Unable to retrieve tag data' }];
    }
}

/**
 * Save report to S3 bucket
 */
async function saveReportToS3(report, key) {
    const params = {
        Bucket: S3_BUCKET_NAME,
        Key: key,
        Body: JSON.stringify(report, null, 2),
        ContentType: 'application/json'
    };
    
    await s3.putObject(params).promise();
    console.log(`Report saved to S3: ${S3_BUCKET_NAME}/${key}`);
}

/**
 * Send notification about the generated report
 */
async function sendNotification(dateString, totalCost) {
    const message = {
        subject: `Cost Report Generated - ${ENVIRONMENT} - ${dateString}`,
        message: `
Cost report for ${ENVIRONMENT} environment has been generated and saved to S3.
Date: ${dateString}
Total Cost: $${totalCost}
Location: s3://${S3_BUCKET_NAME}/cost-reports/${ENVIRONMENT}/${dateString.substring(0, 7)}/cost-report-${dateString}.json
        `
    };
    
    const params = {
        TopicArn: SNS_TOPIC_ARN,
        Subject: message.subject,
        Message: message.message
    };
    
    await sns.publish(params).promise();
    console.log('Notification sent successfully');
}

/**
 * Send error notification
 */
async function sendErrorNotification(errorMessage) {
    const message = {
        subject: `ERROR: Cost Report Generation Failed - ${ENVIRONMENT}`,
        message: `
Cost report generation for ${ENVIRONMENT} environment has failed.
Error: ${errorMessage}
Timestamp: ${new Date().toISOString()}
        `
    };
    
    const params = {
        TopicArn: SNS_TOPIC_ARN,
        Subject: message.subject,
        Message: message.message
    };
    
    try {
        await sns.publish(params).promise();
        console.log('Error notification sent successfully');
    } catch (error) {
        console.error('Failed to send error notification:', error);
    }
}

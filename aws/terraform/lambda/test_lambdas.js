/**
 * Test script for Lambda functions
 * 
 * This script tests the Lambda functions locally to ensure they work correctly
 * before deploying them to AWS.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Mock AWS SDK
const mockAWS = {
  S3: function() {
    return {
      listBuckets: () => ({ promise: () => Promise.resolve({ Buckets: [] }) }),
      getBucketPolicy: () => ({ promise: () => Promise.reject({ code: 'NoSuchBucketPolicy' }) }),
      getBucketAcl: () => ({ promise: () => Promise.resolve({ Grants: [] }) }),
      getBucketEncryption: () => ({ promise: () => Promise.reject({ code: 'ServerSideEncryptionConfigurationNotFoundError' }) }),
      getBucketLogging: () => ({ promise: () => Promise.resolve({ LoggingEnabled: null }) })
    };
  },
  IAM: function() {
    return {
      listUsers: () => ({ promise: () => Promise.resolve({ Users: [] }) }),
      listAccessKeys: () => ({ promise: () => Promise.resolve({ AccessKeyMetadata: [] }) }),
      listMFADevices: () => ({ promise: () => Promise.resolve({ MFADevices: [] }) }),
      listPolicies: () => ({ promise: () => Promise.resolve({ Policies: [] }) }),
      getPolicyVersion: () => ({ promise: () => Promise.resolve({ PolicyVersion: { Document: '%7B%22Statement%22%3A%5B%5D%7D' } }) })
    };
  },
  RDS: function() {
    return {
      describeDBInstances: () => ({ promise: () => Promise.resolve({ DBInstances: [] }) })
    };
  },
  EC2: function() {
    return {
      describeInstances: () => ({ promise: () => Promise.resolve({ Reservations: [] }) }),
      describeSecurityGroups: () => ({ promise: () => Promise.resolve({ SecurityGroups: [] }) }),
      describeVolumes: () => ({ promise: () => Promise.resolve({ Volumes: [] }) })
    };
  },
  CloudWatch: function() {
    return {
      putMetricData: () => ({ promise: () => Promise.resolve() })
    };
  },
  SNS: function() {
    return {
      publish: () => ({ promise: () => Promise.resolve() })
    };
  },
  Backup: function() {
    return {
      listBackupJobs: () => ({ promise: () => Promise.resolve({ BackupJobs: [] }) }),
      listRestoreJobs: () => ({ promise: () => Promise.resolve({ RestoreJobs: [] }) }),
      listRecoveryPointsByBackupVault: () => ({ promise: () => Promise.resolve({ RecoveryPoints: [] }) }),
      startRestoreJob: () => ({ promise: () => Promise.resolve({ RestoreJobId: 'test-restore-job-id' }) })
    };
  },
  CostExplorer: function() {
    return {
      getCostAndUsage: () => ({ promise: () => Promise.resolve({ 
        ResultsByTime: [{ 
          TimePeriod: { Start: '2023-01-01', End: '2023-01-02' },
          Groups: [],
          Total: { UnblendedCost: { Amount: '100', Unit: 'USD' } }
        }] 
      }) }),
      getReservationUtilization: () => ({ promise: () => Promise.resolve({ 
        Total: { 
          UtilizationPercentage: '75',
          PurchasedHours: '100',
          TotalAmortizedFee: '200'
        },
        UtilizationsByTime: []
      }) }),
      getSavingsPlansPurchaseRecommendation: () => ({ promise: () => Promise.resolve({
        SavingsPlansPurchaseRecommendation: {
          EstimatedMonthlySavingsAmount: '300',
          EstimatedSavingsPercentage: '25',
          EstimatedROI: '100'
        }
      }) })
    };
  }
};

// Set up mock environment
global.AWS = mockAWS;
process.env.PROJECT_NAME = 'test-project';
process.env.ENVIRONMENT = 'test';
process.env.SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:123456789012:test-topic';
process.env.BACKUP_VAULT_NAME = 'test-vault';
process.env.METRICS_LAMBDA_ARN = 'arn:aws:lambda:us-east-1:123456789012:function:test-metrics-lambda';

// Test functions
const testFunctions = [
  {
    name: 'security_assessment',
    event: {},
    expectedResult: (result) => {
      if (!result || !result.statusCode || result.statusCode !== 200) {
        throw new Error('Expected statusCode 200');
      }
      const body = JSON.parse(result.body);
      if (!body.iamResults || !body.s3Results || !body.rdsResults || !body.ec2Results) {
        throw new Error('Missing expected result sections');
      }
      console.log('✅ security_assessment test passed');
    }
  },
  {
    name: 'backup_test',
    event: {
      source: 'aws.events',
      'detail-type': 'Scheduled Event',
      resources: ['arn:aws:events:us-east-1:123456789012:rule/test-rule']
    },
    expectedResult: (result) => {
      if (!result || !result.statusCode || result.statusCode !== 200) {
        throw new Error('Expected statusCode 200');
      }
      if (!result.message || !result.message.includes('completed')) {
        throw new Error('Expected completion message');
      }
      console.log('✅ backup_test test passed');
    }
  },
  {
    name: 'backup_test_metrics',
    event: {
      testResults: {
        success: true,
        duration: 120,
        resourceType: 'RDS',
        resourceId: 'test-db',
        backupJobId: 'test-backup-job',
        restoreJobId: 'test-restore-job'
      }
    },
    expectedResult: (result) => {
      if (!result || !result.statusCode || result.statusCode !== 200) {
        throw new Error('Expected statusCode 200');
      }
      if (!result.message || !result.message.includes('published')) {
        throw new Error('Expected metrics published message');
      }
      console.log('✅ backup_test_metrics test passed');
    }
  },
  {
    name: 'cost_reports',
    event: {
      source: 'aws.events',
      'detail-type': 'Scheduled Event',
      resources: ['arn:aws:events:us-east-1:123456789012:rule/test-rule']
    },
    expectedResult: (result) => {
      if (!result || !result.statusCode || result.statusCode !== 200) {
        throw new Error('Expected statusCode 200');
      }
      if (!result.message || !result.message.includes('Cost report generated')) {
        throw new Error('Expected cost report message');
      }
      console.log('✅ cost_reports test passed');
    }
  }
];

// Run tests
async function runTests() {
  console.log('Starting Lambda function tests...');
  
  let passedTests = 0;
  let failedTests = 0;
  
  for (const test of testFunctions) {
    try {
      console.log(`\nTesting ${test.name}...`);
      
      // Check if the file exists
      const filePath = path.join(__dirname, `${test.name}.js`);
      if (!fs.existsSync(filePath)) {
        console.log(`❌ ${test.name} test failed: File not found`);
        failedTests++;
        continue;
      }
      
      // Require the Lambda function
      const lambdaFunction = require(`./${test.name}.js`);
      
      // Execute the Lambda function
      const result = await lambdaFunction.handler(test.event);
      
      // Validate the result
      test.expectedResult(result);
      passedTests++;
    } catch (error) {
      console.error(`❌ ${test.name} test failed:`, error.message);
      failedTests++;
    }
  }
  
  // Print summary
  console.log('\n--- Test Summary ---');
  console.log(`Total tests: ${testFunctions.length}`);
  console.log(`Passed: ${passedTests}`);
  console.log(`Failed: ${failedTests}`);
  
  // Return exit code based on test results
  process.exit(failedTests > 0 ? 1 : 0);
}

// Run the tests
runTests().catch(error => {
  console.error('Error running tests:', error);
  process.exit(1);
});

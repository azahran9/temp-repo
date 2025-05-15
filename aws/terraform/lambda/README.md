# Lambda Security Assessment Package

This directory contains the AWS Lambda function and supporting scripts for automated security assessment as part of the Job Matching API infrastructure.

## Components
- **security_assessment.js**: Main Lambda handler. Performs security checks on IAM, S3, RDS, and EC2. Publishes findings to CloudWatch and sends notifications via SNS.
- **test_lambdas.js**: Local test runner with AWS SDK mocks. Validates Lambda logic before deployment.
- **package_security_assessment.js**: Script to zip Lambda code for deployment (creates `security_assessment.zip`).
- **security_assessment_package.json**: Declares dependencies, scripts, and metadata for the Lambda package.

## Usage
1. **Install dependencies**
   ```sh
   npm install
   ```
2. **Run tests**
   ```sh
   npm test
   ```
3. **Package for deployment**
   ```sh
   npm run package
   # Output: security_assessment.zip
   ```
4. **Deploy to AWS Lambda**
   - Use the AWS Console, CLI, or Terraform to deploy `security_assessment.zip` as the function code.

## Environment Variables
- `PROJECT_NAME`: Project identifier (default: `job-matching-api`)
- `ENVIRONMENT`: Environment name (default: `production`)
- `SNS_TOPIC_ARN`: SNS topic ARN for critical finding notifications

## Integration
- Lambda is triggered on a schedule (CloudWatch Events) or via CI/CD pipeline.
- Findings are published to CloudWatch Metrics and SNS for alerting.

## Security
- See `../SECURITY.md` for incident response and compliance documentation.

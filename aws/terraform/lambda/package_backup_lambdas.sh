#!/bin/bash
# Script to package the backup testing Lambda functions

# Create temporary directories
tempDirTest="./temp_backup_test"
tempDirMetrics="./temp_backup_metrics"

# Clean up existing directories if they exist
rm -rf $tempDirTest
rm -rf $tempDirMetrics

# Create new directories
mkdir -p $tempDirTest
mkdir -p $tempDirMetrics

# Create package.json files
cat > $tempDirTest/package.json << 'EOF'
{
  "name": "backup-test-lambda",
  "version": "1.0.0",
  "description": "Lambda function for testing AWS backups",
  "main": "backup_test.js",
  "dependencies": {
    "aws-sdk": "^2.1130.0"
  }
}
EOF

cat > $tempDirMetrics/package.json << 'EOF'
{
  "name": "backup-test-metrics-lambda",
  "version": "1.0.0",
  "description": "Lambda function for publishing backup test metrics",
  "main": "backup_test_metrics.js",
  "dependencies": {
    "aws-sdk": "^2.1130.0"
  }
}
EOF

# Copy Lambda function files
cp ./backup_test.js $tempDirTest/
cp ./backup_test_metrics.js $tempDirMetrics/

# Install dependencies
echo "Installing dependencies for backup_test Lambda..."
cd $tempDirTest
npm install --production
cd ..

echo "Installing dependencies for backup_test_metrics Lambda..."
cd $tempDirMetrics
npm install --production
cd ..

# Create zip files
echo "Creating zip files..."
cd $tempDirTest
zip -r ../backup_test.zip ./*
cd ..

cd $tempDirMetrics
zip -r ../backup_test_metrics.zip ./*
cd ..

# Clean up
rm -rf $tempDirTest
rm -rf $tempDirMetrics

echo "Lambda functions packaged successfully:"
echo "- backup_test.zip"
echo "- backup_test_metrics.zip"

#!/bin/bash
# Script to package the security assessment Lambda function

# Create temporary directory
tempDir="./temp_security_assessment"

# Clean up existing directory if it exists
rm -rf $tempDir

# Create new directory
mkdir -p $tempDir

# Copy Lambda function file
cp ./security_assessment.js $tempDir/

# Create package.json
cat > $tempDir/package.json << 'EOF'
{
  "name": "security-assessment-lambda",
  "version": "1.0.0",
  "description": "Lambda function for security assessment",
  "main": "security_assessment.js",
  "dependencies": {
    "aws-sdk": "^2.1130.0"
  }
}
EOF

# Install dependencies
echo "Installing dependencies for security assessment Lambda..."
cd $tempDir
npm install --production
cd ..

# Create zip file
echo "Creating zip file..."
cd $tempDir
zip -r ../security_assessment.zip ./*
cd ..

# Clean up
rm -rf $tempDir

echo "Lambda function packaged successfully: security_assessment.zip"

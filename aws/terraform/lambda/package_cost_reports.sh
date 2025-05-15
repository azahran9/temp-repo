#!/bin/bash
# Script to package the cost_reports Lambda function

# Create a temporary directory
tempDir="./temp_cost_reports"
rm -rf $tempDir
mkdir -p $tempDir

# Copy the cost_reports.js file to the temp directory
cp ./cost_reports.js $tempDir/index.js
cp ./cost_reports_package.json $tempDir/package.json

# Navigate to the temp directory
cd $tempDir

# Install dependencies
npm install --production

# Create the zip file
zip -r ../cost_reports.zip ./*

# Clean up
cd ..
rm -rf $tempDir

echo "Lambda function packaged successfully: cost_reports.zip"

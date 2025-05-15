# Script to package the backup testing Lambda functions

# Create temporary directories
$tempDirTest = ".\temp_backup_test"
$tempDirMetrics = ".\temp_backup_metrics"

# Clean up existing directories if they exist
if (Test-Path $tempDirTest) {
    Remove-Item -Recurse -Force $tempDirTest
}
if (Test-Path $tempDirMetrics) {
    Remove-Item -Recurse -Force $tempDirMetrics
}

# Create new directories
New-Item -ItemType Directory -Path $tempDirTest | Out-Null
New-Item -ItemType Directory -Path $tempDirMetrics | Out-Null

# Create package.json files
$packageJsonTest = @"
{
  "name": "backup-test-lambda",
  "version": "1.0.0",
  "description": "Lambda function for testing AWS backups",
  "main": "backup_test.js",
  "dependencies": {
    "aws-sdk": "^2.1130.0"
  }
}
"@

$packageJsonMetrics = @"
{
  "name": "backup-test-metrics-lambda",
  "version": "1.0.0",
  "description": "Lambda function for publishing backup test metrics",
  "main": "backup_test_metrics.js",
  "dependencies": {
    "aws-sdk": "^2.1130.0"
  }
}
"@

# Write package.json files
Set-Content -Path "$tempDirTest\package.json" -Value $packageJsonTest
Set-Content -Path "$tempDirMetrics\package.json" -Value $packageJsonMetrics

# Copy Lambda function files
Copy-Item -Path ".\backup_test.js" -Destination "$tempDirTest\backup_test.js"
Copy-Item -Path ".\backup_test_metrics.js" -Destination "$tempDirMetrics\backup_test_metrics.js"

# Install dependencies
Write-Host "Installing dependencies for backup_test Lambda..."
Push-Location $tempDirTest
npm install --production
Pop-Location

Write-Host "Installing dependencies for backup_test_metrics Lambda..."
Push-Location $tempDirMetrics
npm install --production
Pop-Location

# Create zip files
Write-Host "Creating zip files..."
Compress-Archive -Path "$tempDirTest\*" -DestinationPath ".\backup_test.zip" -Force
Compress-Archive -Path "$tempDirMetrics\*" -DestinationPath ".\backup_test_metrics.zip" -Force

# Clean up
Remove-Item -Recurse -Force $tempDirTest
Remove-Item -Recurse -Force $tempDirMetrics

Write-Host "Lambda functions packaged successfully:"
Write-Host "- backup_test.zip"
Write-Host "- backup_test_metrics.zip"

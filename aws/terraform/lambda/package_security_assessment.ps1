# Script to package the security assessment Lambda function

# Create temporary directory
$tempDir = ".\temp_security_assessment"

# Clean up existing directory if it exists
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}

# Create new directory
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy Lambda function file
Copy-Item -Path ".\security_assessment.js" -Destination "$tempDir\security_assessment.js"

# Create package.json
$packageJson = @"
{
  "name": "security-assessment-lambda",
  "version": "1.0.0",
  "description": "Lambda function for security assessment",
  "main": "security_assessment.js",
  "dependencies": {
    "aws-sdk": "^2.1130.0"
  }
}
"@

# Write package.json file
Set-Content -Path "$tempDir\package.json" -Value $packageJson

# Install dependencies
Write-Host "Installing dependencies for security assessment Lambda..."
Push-Location $tempDir
npm install --production
Pop-Location

# Create zip file
Write-Host "Creating zip file..."
Compress-Archive -Path "$tempDir\*" -DestinationPath ".\security_assessment.zip" -Force

# Clean up
Remove-Item -Recurse -Force $tempDir

Write-Host "Lambda function packaged successfully: security_assessment.zip"

# Script to package the cost_reports Lambda function

# Create a temporary directory
$tempDir = ".\temp_cost_reports"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy the cost_reports.js file to the temp directory
Copy-Item -Path ".\cost_reports.js" -Destination "$tempDir\index.js"
Copy-Item -Path ".\cost_reports_package.json" -Destination "$tempDir\package.json"

# Navigate to the temp directory
Push-Location $tempDir

# Install dependencies
npm install --production

# Create the zip file
Compress-Archive -Path ".\*" -DestinationPath "..\cost_reports.zip" -Force

# Clean up
Pop-Location
Remove-Item -Recurse -Force $tempDir

Write-Host "Lambda function packaged successfully: cost_reports.zip"

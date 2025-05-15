# Script to package all Lambda functions

# Define the list of Lambda functions to package
$lambdaFunctions = @(
    @{
        Name = "cost_reports"
        MainFile = "cost_reports.js"
        PackageJsonFile = "cost_reports_package.json"
    },
    @{
        Name = "backup_test"
        MainFile = "backup_test.js"
        Dependencies = @("aws-sdk")
    },
    @{
        Name = "backup_test_metrics"
        MainFile = "backup_test_metrics.js"
        Dependencies = @("aws-sdk")
    },
    @{
        Name = "security_assessment"
        MainFile = "security_assessment.js"
        Dependencies = @("aws-sdk")
    }
    # Add more Lambda functions as needed
)

# Function to package a Lambda function
function Package-Lambda {
    param (
        [string]$Name,
        [string]$MainFile,
        [string]$PackageJsonFile = "",
        [array]$Dependencies = @()
    )
    
    Write-Host "Packaging Lambda function: $Name"
    
    # Create a temporary directory
    $tempDir = ".\temp_$Name"
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Copy the main file
    if ($MainFile -ne "") {
        Copy-Item -Path ".\$MainFile" -Destination "$tempDir\index.js"
    }
    
    # Use existing package.json if specified
    if ($PackageJsonFile -ne "") {
        Copy-Item -Path ".\$PackageJsonFile" -Destination "$tempDir\package.json"
    }
    # Otherwise create a new package.json
    elseif ($Dependencies.Count -gt 0) {
        $packageJson = @{
            name = "$Name-lambda"
            version = "1.0.0"
            description = "Lambda function for $Name"
            main = "index.js"
            dependencies = @{}
        }
        
        foreach ($dep in $Dependencies) {
            $packageJson.dependencies[$dep] = "^2.1130.0"
        }
        
        $packageJsonContent = ConvertTo-Json $packageJson -Depth 10
        Set-Content -Path "$tempDir\package.json" -Value $packageJsonContent
    }
    
    # Install dependencies if package.json exists
    if ((Test-Path "$tempDir\package.json")) {
        Push-Location $tempDir
        npm install --production
        Pop-Location
    }
    
    # Create the zip file
    Compress-Archive -Path "$tempDir\*" -DestinationPath ".\$Name.zip" -Force
    
    # Clean up
    Remove-Item -Recurse -Force $tempDir
    
    Write-Host "Lambda function packaged successfully: $Name.zip"
}

# Package each Lambda function
foreach ($lambda in $lambdaFunctions) {
    Package-Lambda -Name $lambda.Name -MainFile $lambda.MainFile -PackageJsonFile $lambda.PackageJsonFile -Dependencies $lambda.Dependencies
}

Write-Host "All Lambda functions packaged successfully!"

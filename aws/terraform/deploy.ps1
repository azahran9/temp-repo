# PowerShell script for deploying the Job Matching API infrastructure

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version
    Write-Host "AWS CLI is installed: $awsVersion"
}
catch {
    Write-Host "AWS CLI is not installed. Please install it before proceeding." -ForegroundColor Red
    Write-Host "Visit https://aws.amazon.com/cli/ for installation instructions."
    exit 1
}

# Check if Terraform is installed
try {
    $terraformVersion = terraform --version
    Write-Host "Terraform is installed: $terraformVersion"
}
catch {
    Write-Host "Terraform is not installed. Please install it before proceeding." -ForegroundColor Red
    Write-Host "Visit https://www.terraform.io/downloads.html for installation instructions."
    exit 1
}

# Check if AWS credentials are configured
try {
    $awsIdentity = aws sts get-caller-identity
    Write-Host "AWS credentials are configured. Using account: $($awsIdentity | ConvertFrom-Json | Select-Object -ExpandProperty Account)"
}
catch {
    Write-Host "AWS credentials are not configured or invalid. Please configure them before proceeding." -ForegroundColor Red
    Write-Host "Run 'aws configure' to set up your credentials."
    exit 1
}

# Check if terraform.tfvars exists
if (-not (Test-Path -Path "terraform.tfvars")) {
    Write-Host "terraform.tfvars file not found. Creating a template from terraform.tfvars.example..." -ForegroundColor Yellow
    if (Test-Path -Path "terraform.tfvars.example") {
        Copy-Item -Path "terraform.tfvars.example" -Destination "terraform.tfvars"
        Write-Host "terraform.tfvars created. Please edit this file with your specific configuration values." -ForegroundColor Yellow
        Write-Host "After editing, run this script again." -ForegroundColor Yellow
        exit 0
    }
    else {
        Write-Host "terraform.tfvars.example not found. Please create a terraform.tfvars file manually." -ForegroundColor Red
        exit 1
    }
}

# Function to package Lambda function
function Package-Lambda {
    Write-Host "Packaging Lambda function..." -ForegroundColor Cyan
    
    # Check if lambda directory exists
    if (Test-Path -Path "lambda") {
        Set-Location -Path "lambda"
        
        # Install dependencies
        Write-Host "Installing Lambda dependencies..." -ForegroundColor Cyan
        npm install
        
        # Create zip file
        Write-Host "Creating Lambda deployment package..." -ForegroundColor Cyan
        Compress-Archive -Path * -DestinationPath "../job-matching.zip" -Force
        
        Set-Location -Path ".."
        Write-Host "Lambda function packaged successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Lambda directory not found. Skipping Lambda packaging." -ForegroundColor Yellow
    }
}

# Main deployment function
function Deploy-Infrastructure {
    param (
        [switch]$Init,
        [switch]$Plan,
        [switch]$Apply,
        [switch]$Destroy,
        [switch]$Output
    )
    
    # Initialize Terraform
    if ($Init) {
        Write-Host "Initializing Terraform..." -ForegroundColor Cyan
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Terraform initialization failed." -ForegroundColor Red
            exit 1
        }
        Write-Host "Terraform initialized successfully." -ForegroundColor Green
    }
    
    # Package Lambda function
    Package-Lambda
    
    # Plan deployment
    if ($Plan) {
        Write-Host "Planning Terraform deployment..." -ForegroundColor Cyan
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Terraform plan failed." -ForegroundColor Red
            exit 1
        }
        Write-Host "Terraform plan created successfully." -ForegroundColor Green
    }
    
    # Apply deployment
    if ($Apply) {
        Write-Host "Applying Terraform deployment..." -ForegroundColor Cyan
        if (Test-Path -Path "tfplan") {
            terraform apply tfplan
        }
        else {
            Write-Host "No plan file found. Creating and applying plan..." -ForegroundColor Yellow
            terraform apply -auto-approve
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Terraform apply failed." -ForegroundColor Red
            exit 1
        }
        Write-Host "Terraform deployment completed successfully." -ForegroundColor Green
    }
    
    # Destroy infrastructure
    if ($Destroy) {
        Write-Host "WARNING: You are about to destroy all infrastructure. This action cannot be undone." -ForegroundColor Red
        $confirmation = Read-Host "Are you sure you want to proceed? (yes/no)"
        if ($confirmation -eq "yes") {
            Write-Host "Destroying infrastructure..." -ForegroundColor Cyan
            terraform destroy -auto-approve
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Terraform destroy failed." -ForegroundColor Red
                exit 1
            }
            Write-Host "Infrastructure destroyed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Destroy operation cancelled." -ForegroundColor Yellow
        }
    }
    
    # Show outputs
    if ($Output) {
        Write-Host "Retrieving Terraform outputs..." -ForegroundColor Cyan
        terraform output
    }
}

# Parse command line arguments
$action = $args[0]

switch ($action) {
    "init" {
        Deploy-Infrastructure -Init
    }
    "plan" {
        Deploy-Infrastructure -Plan
    }
    "apply" {
        Deploy-Infrastructure -Apply
    }
    "destroy" {
        Deploy-Infrastructure -Destroy
    }
    "output" {
        Deploy-Infrastructure -Output
    }
    "all" {
        Deploy-Infrastructure -Init -Plan -Apply
    }
    default {
        Write-Host "Usage: ./deploy.ps1 [init|plan|apply|destroy|output|all]" -ForegroundColor Yellow
        Write-Host "  init     - Initialize Terraform"
        Write-Host "  plan     - Create a Terraform plan"
        Write-Host "  apply    - Apply the Terraform plan"
        Write-Host "  destroy  - Destroy the infrastructure"
        Write-Host "  output   - Show Terraform outputs"
        Write-Host "  all      - Run init, plan, and apply in sequence"
    }
}

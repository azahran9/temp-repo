#!/bin/bash

# Bash script for deploying the Job Matching API infrastructure

# Set error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it before proceeding.${NC}"
    echo "Visit https://aws.amazon.com/cli/ for installation instructions."
    exit 1
else
    echo -e "${GREEN}AWS CLI is installed: $(aws --version)${NC}"
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it before proceeding.${NC}"
    echo "Visit https://www.terraform.io/downloads.html for installation instructions."
    exit 1
else
    echo -e "${GREEN}Terraform is installed: $(terraform --version | head -n 1)${NC}"
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS credentials are not configured or invalid. Please configure them before proceeding.${NC}"
    echo "Run 'aws configure' to set up your credentials."
    exit 1
else
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}AWS credentials are configured. Using account: ${ACCOUNT_ID}${NC}"
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}terraform.tfvars file not found. Creating a template from terraform.tfvars.example...${NC}"
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${YELLOW}terraform.tfvars created. Please edit this file with your specific configuration values.${NC}"
        echo -e "${YELLOW}After editing, run this script again.${NC}"
        exit 0
    else
        echo -e "${RED}terraform.tfvars.example not found. Please create a terraform.tfvars file manually.${NC}"
        exit 1
    fi
fi

# Function to package Lambda function
package_lambda() {
    echo -e "${CYAN}Packaging Lambda function...${NC}"
    
    # Check if lambda directory exists
    if [ -d "lambda" ]; then
        cd lambda
        
        # Install dependencies
        echo -e "${CYAN}Installing Lambda dependencies...${NC}"
        npm install
        
        # Create zip file
        echo -e "${CYAN}Creating Lambda deployment package...${NC}"
        zip -r ../job-matching.zip ./*
        
        cd ..
        echo -e "${GREEN}Lambda function packaged successfully.${NC}"
    else
        echo -e "${YELLOW}Lambda directory not found. Skipping Lambda packaging.${NC}"
    fi
}

# Main deployment function
deploy_infrastructure() {
    local init=$1
    local plan=$2
    local apply=$3
    local destroy=$4
    local output=$5
    
    # Initialize Terraform
    if [ "$init" = true ]; then
        echo -e "${CYAN}Initializing Terraform...${NC}"
        terraform init
        if [ $? -ne 0 ]; then
            echo -e "${RED}Terraform initialization failed.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Terraform initialized successfully.${NC}"
    fi
    
    # Package Lambda function
    package_lambda
    
    # Plan deployment
    if [ "$plan" = true ]; then
        echo -e "${CYAN}Planning Terraform deployment...${NC}"
        terraform plan -out=tfplan
        if [ $? -ne 0 ]; then
            echo -e "${RED}Terraform plan failed.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Terraform plan created successfully.${NC}"
    fi
    
    # Apply deployment
    if [ "$apply" = true ]; then
        echo -e "${CYAN}Applying Terraform deployment...${NC}"
        if [ -f "tfplan" ]; then
            terraform apply tfplan
        else
            echo -e "${YELLOW}No plan file found. Creating and applying plan...${NC}"
            terraform apply -auto-approve
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Terraform apply failed.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Terraform deployment completed successfully.${NC}"
    fi
    
    # Destroy infrastructure
    if [ "$destroy" = true ]; then
        echo -e "${RED}WARNING: You are about to destroy all infrastructure. This action cannot be undone.${NC}"
        read -p "Are you sure you want to proceed? (yes/no) " confirmation
        if [ "$confirmation" = "yes" ]; then
            echo -e "${CYAN}Destroying infrastructure...${NC}"
            terraform destroy -auto-approve
            if [ $? -ne 0 ]; then
                echo -e "${RED}Terraform destroy failed.${NC}"
                exit 1
            fi
            echo -e "${GREEN}Infrastructure destroyed successfully.${NC}"
        else
            echo -e "${YELLOW}Destroy operation cancelled.${NC}"
        fi
    fi
    
    # Show outputs
    if [ "$output" = true ]; then
        echo -e "${CYAN}Retrieving Terraform outputs...${NC}"
        terraform output
    fi
}

# Parse command line arguments
action=$1

case "$action" in
    "init")
        deploy_infrastructure true false false false false
        ;;
    "plan")
        deploy_infrastructure false true false false false
        ;;
    "apply")
        deploy_infrastructure false false true false false
        ;;
    "destroy")
        deploy_infrastructure false false false true false
        ;;
    "output")
        deploy_infrastructure false false false false true
        ;;
    "all")
        deploy_infrastructure true true true false false
        ;;
    *)
        echo -e "${YELLOW}Usage: ./deploy.sh [init|plan|apply|destroy|output|all]${NC}"
        echo "  init     - Initialize Terraform"
        echo "  plan     - Create a Terraform plan"
        echo "  apply    - Apply the Terraform plan"
        echo "  destroy  - Destroy the infrastructure"
        echo "  output   - Show Terraform outputs"
        echo "  all      - Run init, plan, and apply in sequence"
        ;;
esac

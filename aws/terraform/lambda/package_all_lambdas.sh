#!/bin/bash
# Script to package all Lambda functions

# Function to package a Lambda function
package_lambda() {
    local name=$1
    local main_file=$2
    local package_json_file=$3
    local dependencies=$4
    
    echo "Packaging Lambda function: $name"
    
    # Create a temporary directory
    local temp_dir="./temp_$name"
    rm -rf $temp_dir
    mkdir -p $temp_dir
    
    # Copy the main file
    if [ ! -z "$main_file" ]; then
        cp ./$main_file $temp_dir/index.js
    fi
    
    # Use existing package.json if specified
    if [ ! -z "$package_json_file" ]; then
        cp ./$package_json_file $temp_dir/package.json
    # Otherwise create a new package.json
    elif [ ! -z "$dependencies" ]; then
        cat > $temp_dir/package.json << EOF
{
  "name": "${name}-lambda",
  "version": "1.0.0",
  "description": "Lambda function for ${name}",
  "main": "index.js",
  "dependencies": {
EOF
        
        # Add dependencies
        IFS=',' read -ra DEPS <<< "$dependencies"
        local first=true
        for dep in "${DEPS[@]}"; do
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> $temp_dir/package.json
            fi
            echo "    \"$dep\": \"^2.1130.0\"" >> $temp_dir/package.json
        done
        
        cat >> $temp_dir/package.json << EOF
  }
}
EOF
    fi
    
    # Install dependencies if package.json exists
    if [ -f "$temp_dir/package.json" ]; then
        (cd $temp_dir && npm install --production)
    fi
    
    # Create the zip file
    (cd $temp_dir && zip -r ../$name.zip *)
    
    # Clean up
    rm -rf $temp_dir
    
    echo "Lambda function packaged successfully: $name.zip"
}

# Package each Lambda function
package_lambda "cost_reports" "cost_reports.js" "cost_reports_package.json" ""
package_lambda "backup_test" "backup_test.js" "" "aws-sdk"
package_lambda "backup_test_metrics" "backup_test_metrics.js" "" "aws-sdk"
package_lambda "security_assessment" "security_assessment.js" "" "aws-sdk"
# Add more Lambda functions as needed

echo "All Lambda functions packaged successfully!"

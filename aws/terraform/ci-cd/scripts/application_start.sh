#!/bin/bash
set -e

# Start the backend application with PM2
cd /opt/job-matching
pm2 start src/server.js --name=job-matching --env=production
pm2 save

# Ensure PM2 starts on system boot
pm2 startup | grep -v PM2 | bash

# Start nginx
systemctl start nginx
systemctl enable nginx

# Configure CloudWatch agent for logs if not already done
if [ ! -f /opt/aws/amazon-cloudwatch-agent/bin/config.json ]; then
    # Install CloudWatch agent if not already installed
    if ! command -v amazon-cloudwatch-agent-ctl &> /dev/null; then
        yum install -y amazon-cloudwatch-agent
    fi
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << EOL
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/root/.pm2/logs/job-matching-out.log",
            "log_group_name": "/job-matching/production/application",
            "log_stream_name": "{instance_id}-application-out",
            "retention_in_days": 7
          },
          {
            "file_path": "/root/.pm2/logs/job-matching-error.log",
            "log_group_name": "/job-matching/production/application",
            "log_stream_name": "{instance_id}-application-error",
            "retention_in_days": 7
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/job-matching/production/nginx",
            "log_stream_name": "{instance_id}-nginx-access",
            "retention_in_days": 7
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/job-matching/production/nginx",
            "log_stream_name": "{instance_id}-nginx-error",
            "retention_in_days": 7
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ]
      }
    },
    "append_dimensions": {
      "InstanceId": "\${aws:InstanceId}"
    }
  }
}
EOL

    # Start the CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
fi

# Send deployment notification
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws sns publish \
  --topic-arn "arn:aws:sns:$(curl -s http://169.254.169.254/latest/meta-data/placement/region):$(aws sts get-caller-identity --query Account --output text):job-matching-deployments" \
  --message "Application successfully deployed to instance ${INSTANCE_ID}" \
  --subject "Deployment Success: job-matching"

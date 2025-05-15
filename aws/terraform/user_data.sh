#!/bin/bash
set -e

# Update system packages
yum update -y
yum install -y git curl

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_14.x | bash -
yum install -y nodejs

# Install PM2 globally
npm install -g pm2

# Create app directory
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Clone the application repository (replace with your actual repository URL)
git clone https://github.com/yourusername/${project_name}.git .

# Install dependencies
npm install --production

# Create environment file
cat > .env << EOL
PORT=${app_port}
NODE_ENV=${environment}
MONGO_URI=${mongodb_uri}
REDIS_URI=${redis_uri}:6379
USE_REDIS=true
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRATION=86400
EOL

# Start the application with PM2
pm2 start src/server.js --name=${project_name} --env=${environment}
pm2 startup
pm2 save

# Configure CloudWatch agent for logs
yum install -y amazon-cloudwatch-agent
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
            "file_path": "/root/.pm2/logs/${project_name}-out.log",
            "log_group_name": "/${project_name}/${environment}/application",
            "log_stream_name": "{instance_id}-application-out",
            "retention_in_days": 7
          },
          {
            "file_path": "/root/.pm2/logs/${project_name}-error.log",
            "log_group_name": "/${project_name}/${environment}/application",
            "log_stream_name": "{instance_id}-application-error",
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

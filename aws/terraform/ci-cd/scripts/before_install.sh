#!/bin/bash
set -e

# Update system packages
yum update -y

# Install Node.js if not already installed
if ! command -v node &> /dev/null; then
    curl -sL https://rpm.nodesource.com/setup_14.x | bash -
    yum install -y nodejs
fi

# Install PM2 globally if not already installed
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
fi

# Install nginx if not already installed
if ! command -v nginx &> /dev/null; then
    amazon-linux-extras install nginx1 -y
fi

# Create application directories if they don't exist
mkdir -p /opt/job-matching
mkdir -p /var/www/html

# Stop application if running
if pm2 list | grep -q "job-matching"; then
    pm2 stop job-matching
fi

# Stop nginx if running
if systemctl is-active nginx; then
    systemctl stop nginx
fi

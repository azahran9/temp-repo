#!/bin/bash
set -e

# Navigate to the backend directory
cd /opt/job-matching

# Install backend dependencies
npm install --production

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    # Get parameters from SSM Parameter Store
    MONGODB_URI=$(aws ssm get-parameter --name /job-matching/mongodb-uri --with-decryption --query Parameter.Value --output text)
    REDIS_URI=$(aws ssm get-parameter --name /job-matching/redis-uri --with-decryption --query Parameter.Value --output text)
    JWT_SECRET=$(aws ssm get-parameter --name /job-matching/jwt-secret --with-decryption --query Parameter.Value --output text)
    
    # Create .env file
    cat > .env << EOL
PORT=3000
NODE_ENV=production
MONGO_URI=${MONGODB_URI}
REDIS_URI=${REDIS_URI}
USE_REDIS=true
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRATION=86400
EOL
fi

# Configure nginx
cat > /etc/nginx/conf.d/job-matching.conf << EOL
server {
    listen 80;
    server_name _;
    
    # Frontend static files
    location / {
        root /var/www/html;
        try_files \$uri \$uri/ /index.html;
        expires 30d;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Remove default nginx configuration
rm -f /etc/nginx/conf.d/default.conf

# Test nginx configuration
nginx -t

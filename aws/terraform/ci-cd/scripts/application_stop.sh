#!/bin/bash

# Stop the application gracefully
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "job-matching"; then
        pm2 stop job-matching || true
    fi
fi

# Stop nginx
if command -v nginx &> /dev/null; then
    if systemctl is-active nginx &> /dev/null; then
        systemctl stop nginx || true
    fi
fi

# Exit with success even if commands fail
exit 0

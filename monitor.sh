#!/bin/bash

# API Test Dashboard Monitoring Script
# This script will:
# 1. Check if the application is running
# 2. Check if Nginx is running
# 3. Check if the application is accessible
# 4. Send an email if there are any issues

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function
log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warning() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Configuration variables
APP_NAME="api-test-dashboard"
APP_PORT=3000
EMAIL="admin@example.com"  # Change this to your email
HOSTNAME=$(hostname)
ISSUES=0

log "Starting monitoring for $APP_NAME..."

# Step 1: Check if the application service is running
if ! systemctl is-active --quiet $APP_NAME.service; then
  error "Application service is not running"
  ISSUES=$((ISSUES+1))
  SERVICE_STATUS="NOT RUNNING"
else
  log "Application service is running"
  SERVICE_STATUS="RUNNING"
fi

# Step 2: Check if Nginx is running
if ! systemctl is-active --quiet nginx; then
  error "Nginx is not running"
  ISSUES=$((ISSUES+1))
  NGINX_STATUS="NOT RUNNING"
else
  log "Nginx is running"
  NGINX_STATUS="RUNNING"
fi

# Step 3: Check if the application is accessible
if ! curl -s --head http://localhost:$APP_PORT > /dev/null; then
  error "Application is not accessible on port $APP_PORT"
  ISSUES=$((ISSUES+1))
  APP_STATUS="NOT ACCESSIBLE"
else
  log "Application is accessible on port $APP_PORT"
  APP_STATUS="ACCESSIBLE"
fi

# Step 4: Check if the application is accessible through Nginx
if ! curl -s --head http://localhost > /dev/null; then
  error "Application is not accessible through Nginx"
  ISSUES=$((ISSUES+1))
  NGINX_PROXY_STATUS="NOT ACCESSIBLE"
else
  log "Application is accessible through Nginx"
  NGINX_PROXY_STATUS="ACCESSIBLE"
fi

# Step 5: Send an email if there are any issues
if [ $ISSUES -gt 0 ]; then
  log "Sending email notification..."
  
  # Create email content
  EMAIL_SUBJECT="[$HOSTNAME] $APP_NAME Monitoring Alert"
  EMAIL_BODY="
Monitoring alert for $APP_NAME on $HOSTNAME

Issues detected: $ISSUES

Service Status: $SERVICE_STATUS
Nginx Status: $NGINX_STATUS
Application Status: $APP_STATUS
Nginx Proxy Status: $NGINX_PROXY_STATUS

Timestamp: $(date)
  "
  
  # Send email (requires mail command to be installed)
  if command -v mail > /dev/null; then
    echo "$EMAIL_BODY" | mail -s "$EMAIL_SUBJECT" $EMAIL
    log "Email notification sent to $EMAIL"
  else
    warning "mail command not found. Email notification not sent."
  fi
fi

# Step 6: Final message
if [ $ISSUES -eq 0 ]; then
  log "Monitoring completed successfully. No issues detected."
else
  error "Monitoring completed. $ISSUES issues detected."
fi

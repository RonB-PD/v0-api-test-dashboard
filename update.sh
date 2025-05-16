#!/bin/bash

# API Test Dashboard Update Script
# This script will:
# 1. Pull the latest changes from the repository
# 2. Install dependencies
# 3. Build the application
# 4. Restart the service

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
  exit 1
}

warning() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  error "Please run as root (use sudo)"
fi

# Configuration variables
APP_NAME="api-test-dashboard"
APP_DIR="/var/www/$APP_NAME"

log "Starting update for $APP_NAME..."

# Step 1: Navigate to app directory
cd $APP_DIR || error "Failed to change to app directory"

# Step 2: Install dependencies
log "Installing dependencies..."
npm install || error "Failed to install dependencies"

# Step 3: Build the application
log "Building the application..."
npm run build || error "Failed to build the application"

# Step 4: Set permissions
log "Setting correct permissions..."
chown -R www-data:www-data $APP_DIR || error "Failed to set permissions"

# Step 5: Restart the service
log "Restarting the service..."
systemctl restart $APP_NAME.service || error "Failed to restart the service"

# Step 6: Final message
log "Update completed successfully!"
log "To check the status of the application, run: systemctl status $APP_NAME"

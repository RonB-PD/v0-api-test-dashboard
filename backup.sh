#!/bin/bash

# API Test Dashboard Backup Script
# This script will:
# 1. Create a backup of the application
# 2. Compress the backup
# 3. Store it in a backup directory

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

# Configuration variables
APP_NAME="api-test-dashboard"
APP_DIR="/var/www/$APP_NAME"
BACKUP_DIR="/var/backups/$APP_NAME"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_FILE="$BACKUP_DIR/$APP_NAME-$TIMESTAMP.tar.gz"

log "Starting backup for $APP_NAME..."

# Step 1: Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR || error "Failed to create backup directory"

# Step 2: Create the backup
log "Creating backup..."
tar -czf $BACKUP_FILE -C /var/www $APP_NAME || error "Failed to create backup"

# Step 3: Set permissions
log "Setting correct permissions..."
chmod 600 $BACKUP_FILE || error "Failed to set permissions"

# Step 4: Clean up old backups (keep last 5)
log "Cleaning up old backups..."
ls -t $BACKUP_DIR/$APP_NAME-*.tar.gz | tail -n +6 | xargs -r rm

# Step 5: Final message
log "Backup completed successfully!"
log "Backup file: $BACKUP_FILE"
log "Total backups: $(ls $BACKUP_DIR/$APP_NAME-*.tar.gz | wc -l)"

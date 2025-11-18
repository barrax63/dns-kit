#!/bin/bash
################################################################################
# Pi-hole mmotti Regex Filter Auto-Installation Script
# For use with /custom-cont-init.d directory
################################################################################
# This script automatically installs mmotti regex filters on first container start
#
# Directory structure:
#   ./pihole-init/01-install-regex.sh  (this file)
#
# Mount in docker-compose.yml:
#   volumes:
#     - ./pihole-init:/custom-cont-init.d:ro
#
# The script:
#   - Runs automatically on container startup
#   - Only executes once (uses marker file)
#   - Installs Python3 and curl if needed
#   - Downloads and runs mmotti regex installer
#   - Updates gravity database
################################################################################

set -e  # Exit on error

# Logging function
log() {
    echo "[REGEX-INIT] $1"
}

log "========================================"
log "mmotti Regex Filter Installation"
log "========================================"

# Check if already installed (prevents re-running on every restart)
MARKER_FILE="/etc/pihole/regex_installed"
if [ -f "$MARKER_FILE" ]; then
    log "✓ Regex filters already installed (marker found)"
    log "  To reinstall, delete: $MARKER_FILE"
    log "  Command: docker-compose exec pihole rm $MARKER_FILE"
    exit 0
fi

log "First run detected - installing regex filters..."

# Wait for Pi-hole to be ready
log "Waiting for Pi-hole to initialize..."
sleep 15

# Check if gravity database exists
GRAVITY_DB="/etc/pihole/gravity.db"
RETRIES=0
MAX_RETRIES=30

while [ ! -f "$GRAVITY_DB" ] && [ $RETRIES -lt $MAX_RETRIES ]; do
    log "Waiting for gravity.db to be created... ($RETRIES/$MAX_RETRIES)"
    sleep 2
    RETRIES=$((RETRIES + 1))
done

if [ ! -f "$GRAVITY_DB" ]; then
    log "✗ ERROR: gravity.db not found after waiting. Aborting."
    exit 1
fi

log "✓ Pi-hole database ready"

# Install required packages if not present
if ! command -v python3 &> /dev/null; then
    log "Installing Python3..."
    apk add --no-cache python3 > /dev/null 2>&1
    log "✓ Python3 installed"
fi

if ! command -v curl &> /dev/null; then
    log "Installing curl..."
    apk add --no-cache curl > /dev/null 2>&1
    log "✓ curl installed"
fi

# Download and run the mmotti installation script
log "Downloading mmotti regex installer..."
if curl -sSl https://raw.githubusercontent.com/mmotti/pihole-regex/master/install.py | python3; then
    log "✓ Regex filters installed successfully!"
    
    # Create marker file to prevent re-installation
    touch "$MARKER_FILE"
    echo "Installed on: $(date)" > "$MARKER_FILE"
    echo "Source: https://github.com/mmotti/pihole-regex" >> "$MARKER_FILE"
    
    # Update gravity to apply the new regex filters
    log "Updating gravity database..."
    pihole updateGravity > /dev/null 2>&1 &
    
    log "========================================"
    log "✓ Installation complete!"
    log "========================================"
    log "Regex filters are now active."
    log "View them at: http://your-pi-hole/admin → Domains → Regex Filters"
else
    log "✗ Installation failed!"
    log "Check the logs above for details."
    exit 1
fi

exit 0
#!/bin/bash

# Pi-hole Auto-Configure Blocklists
# This script runs during container initialization

GRAVITY_DB="/etc/pihole/gravity.db"
ADLIST_TABLE_CHECK="SELECT COUNT(*) FROM adlist;"

echo "[INIT] Checking if blocklists need to be configured..."

# Check if adlists are already configured
ADLIST_COUNT=$(sqlite3 "$GRAVITY_DB" "$ADLIST_TABLE_CHECK" 2>/dev/null || echo "0")

if [ "$ADLIST_COUNT" -eq 0 ]; then
    echo "[INIT] No blocklists found. Adding default blocklists..."
    
    # Add blocklists to the database
    sqlite3 "$GRAVITY_DB" <<EOF
-- Essential Blocklists (Low false positives)
INSERT OR IGNORE INTO adlist (address, enabled, comment) 
VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts', 1, 'StevenBlack Unified - Ads & Malware');
EOF

    if [ $? -eq 0 ]; then
        echo "[INIT] ✓ Successfully added blocklist to database"
        echo "[INIT] Blocklist will be downloaded on first gravity update"
    else
        echo "[INIT] ✗ Failed to add blocklist"
    fi
else
    echo "[INIT] ✓ Blocklist already configured ($ADLIST_COUNT lists found)"
fi

echo "[INIT] Blocklist configuration complete"

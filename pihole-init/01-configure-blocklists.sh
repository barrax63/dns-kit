#!/bin/bash

#==============================================================================
# Pi-hole Regex List Importer
# Automatically imports regex blocklists from mmotti/pihole-regex
#==============================================================================

set -e

REGEX_URL="https://raw.githubusercontent.com/mmotti/pihole-regex/master/regex.list"
GRAVITY_DB="/etc/pihole/gravity.db"
TEMP_FILE="/tmp/regex_import.txt"

echo "[i] Pi-hole Regex List Importer"
echo "[i] Source: mmotti/pihole-regex"
echo ""

# Wait for gravity database to be ready
echo "[i] Waiting for gravity database..."
COUNTER=0
while [ ! -f "$GRAVITY_DB" ] || [ ! -s "$GRAVITY_DB" ]; do
    if [ $COUNTER -gt 30 ]; then
        echo "[✗] Gravity database not found after 30 seconds"
        exit 1
    fi
    sleep 1
    COUNTER=$((COUNTER + 1))
done
echo "[✓] Gravity database ready"
echo ""

# Download the regex list
echo "[i] Downloading regex list from GitHub..."
if ! curl -sS -o "$TEMP_FILE" "$REGEX_URL"; then
    echo "[✗] Failed to download regex list"
    exit 1
fi

# Check if file was downloaded and is not empty
if [ ! -s "$TEMP_FILE" ]; then
    echo "[✗] Downloaded file is empty"
    exit 1
fi

TOTAL_REGEX=$(wc -l < "$TEMP_FILE")
echo "[✓] Downloaded $TOTAL_REGEX regex patterns"
echo ""

# Import regex patterns into Pi-hole database
echo "[i] Importing regex patterns into Pi-hole..."
IMPORTED=0
SKIPPED=0
FAILED=0

while IFS= read -r regex_pattern; do
    # Skip empty lines and comments
    if [ -z "$regex_pattern" ] || [[ "$regex_pattern" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Clean the pattern (remove leading/trailing whitespace)
    regex_pattern=$(echo "$regex_pattern" | xargs)
    
    # Check if regex already exists
    EXISTS=$(sqlite3 "$GRAVITY_DB" "SELECT COUNT(*) FROM domainlist WHERE type = 3 AND domain = '$regex_pattern';" 2>/dev/null || echo "0")
    
    if [ "$EXISTS" -gt 0 ]; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi
    
    # Insert regex into database
    # type = 3 (regex blocklist)
    # enabled = 1 (active)
    # comment = source attribution
    if sqlite3 "$GRAVITY_DB" "INSERT INTO domainlist (type, domain, enabled, comment) VALUES (3, '$regex_pattern', 1, 'mmotti/pihole-regex');" 2>/dev/null; then
        IMPORTED=$((IMPORTED + 1))
    else
        FAILED=$((FAILED + 1))
        echo "[!] Failed to import: $regex_pattern"
    fi
done < "$TEMP_FILE"

# Clean up
rm -f "$TEMP_FILE"

echo ""
echo "[✓] Import complete!"
echo "    - Imported: $IMPORTED new patterns"
echo "    - Skipped:  $SKIPPED existing patterns"
echo "    - Failed:   $FAILED patterns"
echo ""

# Reload Pi-hole to apply changes
if [ "$IMPORTED" -gt 0 ]; then
    echo "[i] Reloading Pi-hole to apply changes..."
    pihole restartdns reload-lists
    echo "[✓] Pi-hole reloaded"
else
    echo "[i] No new patterns imported, reload not needed"
fi

echo ""
echo "[✓] All done!"

#!/usr/bin/env bash

TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"

if [[ $EUID -ne 0 ]]; then
    echo "tcc-cleanup requires sudo"
    exit 1
fi

deleted=0

while IFS='|' read -r service client client_type; do
    if [[ ! -e "$client" ]]; then
        sqlite3 "$TCC_DB" "DELETE FROM access WHERE service='$service' AND client='$client' AND client_type=$client_type;"
        echo "Removed: $client ($service)"
        ((deleted++))
    fi
done < <(sqlite3 "$TCC_DB" "SELECT service, client, client_type FROM access WHERE client_type=1;")

if [[ $deleted -eq 0 ]]; then
    echo "No stale TCC entries found"
else
    echo "Removed $deleted stale entries"
fi

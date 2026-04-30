#!/usr/bin/env bash
set -euo pipefail

local_file="/etc/os-release.local"
base_file="/usr/lib/os-release"
out_file="/etc/os-release"
tmp_file="$(mktemp)"

# Ensure cleanup on failure or exit
trap 'rm -f "$tmp_file"' EXIT

# 1. Use an associative array to track keys defined in the local file
declare -A local_keys

if [[ -f "$local_file" ]]; then
    # We use '|| [[ -n $line ]]' to handle files missing a trailing newline
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([A-Z_]+)= ]]; then
            local_keys["${BASH_REMATCH[1]}"]=1
        fi
    done < "$local_file"
    
    # Start the temp file with the local overrides
    cat "$local_file" > "$tmp_file"
    echo "" >> "$tmp_file" # Add a separator
fi

# 2. Process the base file
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([A-Z_]+)= ]]; then
        key="${BASH_REMATCH[1]}"
        # Only append from base if NOT present in local_keys
        if [[ -z "${local_keys[$key]:-}" ]]; then
            echo "$line" >> "$tmp_file"
        fi
    else
        # Preserve comments and empty lines from the base file
        echo "$line" >> "$tmp_file"
    fi
done < "$base_file"

# 3. Use 'cat' into the file to preserve symlinks and permissions
# This is safer than 'mv' for system config files
cat "$tmp_file" > "$out_file"

#!/usr/bin/env bash
set -euo pipefail

local_file="/etc/os-release.local"
base_file="/usr/lib/os-release"
out_file="/etc/os-release"
tmp_file="$(mktemp)"

# Start with the local overrides
cp "$local_file" "$tmp_file"

# Collect keys already declared in the local file
declared_keys=()

# Start with the local overrides if any
if [[ -f "$local_file" ]]; then
    cp "$local_file" "$tmp_file"
    while IFS= read -r line; do
        [[ "$line" =~ ^([A-Z_]+)= ]] && declared_keys+=("${BASH_REMATCH[1]}")
    done < "$local_file"
fi

# Append anything missing from the base file
while IFS= read -r line; do
    if [[ "$line" =~ ^([A-Z_]+)= ]]; then
        key="${BASH_REMATCH[1]}"
        if [[ ! " ${declared_keys[*]} " =~ " ${key} " ]]; then
            echo "$line" >> "$tmp_file"
        fi
    fi
done < "$base_file"

# Atomically replace /etc/os-release (breaks the symlink, creates a real file)
mv "$tmp_file" "$out_file"

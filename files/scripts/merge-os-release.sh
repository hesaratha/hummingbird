#!/usr/bin/env bash
set -euo pipefail

# Collect keys already declared in /etc/os-release
declared_keys=()
while IFS= read -r line; do
    [[ "$line" =~ ^([A-Z_]+)= ]] && declared_keys+=("${BASH_REMATCH[1]}")
done < /etc/os-release.local

# Append anything missing from /usr/lib/os-release
while IFS= read -r line; do
    if [[ "$line" =~ ^([A-Z_]+)= ]]; then
        key="${BASH_REMATCH[1]}"
        if [[ ! " ${declared_keys[*]} " =~ " ${key} " ]]; then
            echo "$line" >> /etc/os-release
        fi
    fi
done < /usr/lib/os-release

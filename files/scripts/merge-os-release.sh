#!/usr/bin/env bash
set -euo pipefail

local_file="/etc/os-release.local"
base_file="/usr/lib/os-release"
out_file="/etc/os-release"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

declared_keys=()
if [[ -f "$local_file" ]]; then
    cp "$local_file" "$tmp_file"
    while IFS= read -r line; do
        [[ "$line" =~ ^([A-Z_]+)= ]] && declared_keys+=("${BASH_REMATCH[1]}")
    done < "$local_file"
fi

while IFS= read -r line; do
    if [[ "$line" =~ ^([A-Z_]+)= ]]; then
        key="${BASH_REMATCH[1]}"
        if [[ ! " ${declared_keys[*]} " =~ " ${key} " ]]; then
            echo "$line" >> "$tmp_file"
        fi
    fi
done < "$base_file"

mv "$tmp_file" "$out_file"

#!/usr/bin/env bash
set -euo pipefail

# ── Single source of truth ────────────────────────────────────────────────────
CUSTOM_NAME="Anchiornis"
# Maps to: NAME, ID, VERSION_CODENAME, VARIANT_ID (lowercase), IMAGE_ID (lowercase),
#          DEFAULT_HOSTNAME (lowercase), and CPE_NAME vendor field.
# PRETTY_NAME → "$CUSTOM_NAME $IMAGE_VERSION"  (IMAGE_VERSION read from base)
# CPE_NAME    → "cpe:/o:hesaratha:<name_lower>:$VERSION_ID"
# URLs are dropped entirely (HOME_URL, DOCUMENTATION_URL, SUPPORT_URL, BUG_REPORT_URL)

ANSI_COLOR="0;38;2;198;135;0"   # #C68700
# ─────────────────────────────────────────────────────────────────────────────

base_file="/usr/lib/os-release"
out_file="/etc/os-release"
tmp_file="$(mktemp)"

trap 'rm -f "$tmp_file"' EXIT

# Pull IMAGE_VERSION and VERSION_ID from the base file
IMAGE_VERSION=""
VERSION_ID=""
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^IMAGE_VERSION=[\'\"]*([^\'\"]*)[\'\"]* ]]; then
        IMAGE_VERSION="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^VERSION_ID=[\'\"]*([^\'\"]*)[\'\"]* ]]; then
        VERSION_ID="${BASH_REMATCH[1]}"
    fi
    [[ -n "$IMAGE_VERSION" && -n "$VERSION_ID" ]] && break
done < "$base_file"

# Keys replaced with our own values
declare -A override_keys=(
    [NAME]=1
    [ID]=1
    [PRETTY_NAME]=1
    [VERSION_CODENAME]=1
    [VARIANT_ID]=1
    [IMAGE_ID]=1
    [CPE_NAME]=1
    [DEFAULT_HOSTNAME]=1
    [ANSI_COLOR]=1
)

# Keys dropped entirely (no replacement)
declare -A drop_keys=(
    [HOME_URL]=1
    [DOCUMENTATION_URL]=1
    [SUPPORT_URL]=1
    [BUG_REPORT_URL]=1
)

# Write our custom overrides first
cat >> "$tmp_file" <<EOF
NAME="${CUSTOM_NAME}"
ID=${CUSTOM_NAME}
PRETTY_NAME="${CUSTOM_NAME} ${IMAGE_VERSION}"
VERSION_CODENAME="${CUSTOM_NAME}"
VARIANT_ID=${CUSTOM_NAME,,}
IMAGE_ID=${CUSTOM_NAME,,}
CPE_NAME="cpe:/o:hesaratha:${CUSTOM_NAME,,}:${VERSION_ID}"
DEFAULT_HOSTNAME="${CUSTOM_NAME,,}"
ANSI_COLOR="${ANSI_COLOR}"
EOF

echo "" >> "$tmp_file"  # separator

# Append every non-overridden, non-dropped key from the base file
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([A-Z_]+)= ]]; then
        key="${BASH_REMATCH[1]}"
        if [[ -z "${override_keys[$key]:-}" && -z "${drop_keys[$key]:-}" ]]; then
            echo "$line" >> "$tmp_file"
        fi
    else
        # Preserve comments and blank lines
        echo "$line" >> "$tmp_file"
    fi
done < "$base_file"

# Write into place, preserving symlinks and permissions
cat "$tmp_file" > "$out_file"

#!/usr/bin/env bash
# Apply a new Coolify API token to the local coolify-cli context after you create
# (and revoke the old one) in the UI: Security → API tokens.
#
# Usage:
#   ./rotate-coolify-token.sh '1|your_new_token_here'
#   COOLIFY_NEW_TOKEN='1|...' ./rotate-coolify-token.sh
#
# Optional env:
#   COOLIFY_CONTEXT_NAME=localhost   (default)
#   COOLIFY_URL=http://51.77.144.18:8000

set -euo pipefail

NEW_TOKEN="${1:-${COOLIFY_NEW_TOKEN:-}}"
CONTEXT_NAME="${COOLIFY_CONTEXT_NAME:-localhost}"
BASE_URL="${COOLIFY_URL:-http://51.77.144.18:8000}"

if [[ -z "${NEW_TOKEN}" ]]; then
  cat <<'EOF'
Usage:
  rotate-coolify-token.sh '<new_api_token>'

Or:
  COOLIFY_NEW_TOKEN='<new_api_token>' rotate-coolify-token.sh

Steps:
  1. Open Coolify → Security → API tokens → Create (copy once; use * permissions if needed).
  2. Revoke/delete the old token in the same screen.
  3. Run this script with the new token.

The coolify CLI cannot create API tokens; it only stores them via:
  coolify context update <name> --url <url> --token <token>
EOF
  exit 1
fi

if ! command -v coolify >/dev/null 2>&1; then
  echo "coolify CLI not found in PATH" >&2
  exit 1
fi

coolify context update "${CONTEXT_NAME}" --url "${BASE_URL}" --token "${NEW_TOKEN}"
coolify context verify

echo ""
echo "CLI context '${CONTEXT_NAME}' updated. If you use Claude MCP, set COOLIFY_ACCESS_TOKEN in ~/.claude.json to the same token."

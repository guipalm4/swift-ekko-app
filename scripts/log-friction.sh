#!/usr/bin/env bash
# Log a friction entry without reading the file first.
# Usage: bash scripts/log-friction.sh <type> "<description → resolution>"
# Types: edit-fail | unicode | cmd-adjust | multi-step | path-error | repeated-read | other
#
# Example:
#   bash scripts/log-friction.sh edit-fail "Edit failed on tasks.md (unicode) → used Python str.replace()"

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: bash scripts/log-friction.sh <type> \"<description → resolution>\"" >&2
  exit 1
fi

TYPE="$1"
DESC="$2"
DATE=$(date +%Y-%m-%d)
FRICTION_FILE="$(cd "$(dirname "$0")/.." && pwd)/.claude/friction.md"

echo "[${DATE}] [${TYPE}] ${DESC}" >> "$FRICTION_FILE"
echo "logged: [${DATE}] [${TYPE}] ${DESC}"

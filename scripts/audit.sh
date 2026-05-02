#!/usr/bin/env bash
# Naming audit — finds Ekka* occurrences that are NOT intentional contrast lines.
# Usage: ./scripts/audit.sh
# Exit code 0 = clean. Exit code 1 = real errors found.

set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "═══════════════════════════════════════"
echo "  Naming Audit  (Ekka* → should be Ekko*)"
echo "═══════════════════════════════════════"
echo ""

# Gather all Ekka* hits. Excludes:
# - .claude/playbook.md  (meta-file documenting the audit itself)
# - build artifacts, IDE state
raw=$(grep -rn "Ekka" \
  "$REPO/Sources/" \
  "$REPO/Tests/" \
  "$REPO/Package.swift" \
  "$REPO/CLAUDE.md" \
  "$REPO/.claude/napkin.md" \
  "$REPO/.specs/" \
  "$REPO/EkkoApp/EkkoApp/" \
  2>/dev/null \
  | grep -v ".build/" \
  | grep -v "xcuserstate" \
  | grep -v "Binary file" \
  || true)

if [ -z "$raw" ]; then
  echo "  ✅  No Ekka* occurrences found"
  echo ""
  echo "═══════════════════════════════════════"
  echo ""
  exit 0
fi

# Intentional lines always contain BOTH EkkaPlatform and EkkoPlatform
# (contrast pairs like "EkkaPlatform ≠ EkkoPlatform" or "EkkaPlatform→EkkoPlatform").
# Filter them out — any line with both names is a contrast/historical note, not a bug.
errors=$(echo "$raw" | grep -v "EkkaPlatform.*EkkoPlatform\|EkkoPlatform.*EkkaPlatform" || true)
skipped=$(echo "$raw" | grep -c "EkkaPlatform.*EkkoPlatform\|EkkoPlatform.*EkkaPlatform" || echo 0)

if [ -n "$errors" ] && echo "$errors" | grep -q "Ekka"; then
  echo "  ❌  Real errors (must fix):"
  echo "$errors"
  echo ""
  [ "$skipped" -gt 0 ] && echo "  ℹ️   Intentional contrast lines skipped: $skipped"
  echo ""
  echo "═══════════════════════════════════════"
  echo ""
  exit 1
else
  echo "  ✅  No real errors (${skipped} intentional contrast line(s) skipped)"
  echo ""
  echo "═══════════════════════════════════════"
  echo ""
  exit 0
fi

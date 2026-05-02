#!/usr/bin/env bash
# Phase DOD gate runner.
# Usage: ./scripts/check.sh [--no-app]
# Prints PASS/FAIL per gate. Exit code 0 only if all gates pass.
# --no-app: skip xcodebuild (use before T14 is done)

set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
FAIL=0

pass() { echo "  ✅  $1"; }
fail() { echo "  ❌  $1"; FAIL=1; }

echo ""
echo "═══════════════════════════════════════"
echo "  Phase DOD Check"
echo "═══════════════════════════════════════"

# ── 1. Full test suite ──────────────────────────────────────────────────────
echo ""
echo "① Swift tests"
result=$(DEVELOPER_DIR="$XCODE_DEV" swift test --package-path "$REPO" 2>&1)
summary=$(echo "$result" | grep "Test run with" || true)
if echo "$result" | grep -q "passed after"; then
  pass "$summary"
else
  fail "Test suite failed"
  echo "$result" | grep -E "error:|FAILED" | head -10
fi

# ── 2. Architecture purity ──────────────────────────────────────────────────
echo ""
echo "② EkkoCore purity (no AppKit/SwiftUI/ServiceManagement)"
violations=$(grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" \
  "$REPO/Sources/EkkoCore/" 2>/dev/null || true)
if [ -z "$violations" ]; then
  pass "Zero violations"
else
  fail "Violations found:"
  echo "$violations"
fi

# ── 3. Compiler warnings ────────────────────────────────────────────────────
echo ""
echo "③ Compiler warnings"
warnings=$(DEVELOPER_DIR="$XCODE_DEV" swift build --package-path "$REPO" 2>&1 \
  | grep "warning:" | grep -v "^Build complete" || true)
if [ -z "$warnings" ]; then
  pass "Zero warnings"
else
  fail "$(echo "$warnings" | wc -l | tr -d ' ') warning(s):"
  echo "$warnings" | head -10
fi

# ── 4. EkkoApp build (optional) ─────────────────────────────────────────────
XCODEPROJ="$REPO/EkkoApp/EkkoApp.xcodeproj"
if [[ "${1:-}" != "--no-app" ]] && [ -d "$XCODEPROJ" ]; then
  echo ""
  echo "④ EkkoApp xcodebuild"
  app_result=$(DEVELOPER_DIR="$XCODE_DEV" \
    xcodebuild build -scheme EkkoApp -destination 'platform=macOS' \
    -project "$XCODEPROJ" 2>&1)
  if echo "$app_result" | grep -q "BUILD SUCCEEDED"; then
    pass "BUILD SUCCEEDED"
  else
    fail "BUILD FAILED"
    echo "$app_result" | grep "error:" | head -10
  fi
elif [[ "${1:-}" == "--no-app" ]]; then
  echo ""
  echo "④ EkkoApp xcodebuild — skipped (--no-app)"
fi

# ── 5. CLI smoke test ────────────────────────────────────────────────────────
echo ""
echo "⑤ EkkoCLI smoke test"
CLI="$REPO/.build/debug/EkkoCLI"
if [ -f "$CLI" ]; then
  version=$("$CLI" --version 2>&1)
  if [ -n "$version" ]; then
    pass "--version → $version"
  else
    fail "--version returned empty"
  fi
else
  echo "  ⚠️   CLI binary not built yet — run: swift build --product EkkoCLI"
fi

# ── 6. TODO/FIXME/SPEC_DEVIATION ─────────────────────────────────────────────
echo ""
echo "⑥ TODO / FIXME / SPEC_DEVIATION in source"
findings=$(grep -rn "TODO\|FIXME\|HACK\|SPEC_DEVIATION" \
  "$REPO/Sources/" "$REPO/Tests/" 2>/dev/null \
  | grep -v ".build/" || true)
if [ -z "$findings" ]; then
  pass "None found"
else
  echo "  ⚠️   Found (review before merging):"
  echo "$findings"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
if [ "$FAIL" -eq 0 ]; then
  echo "  ✅  All gates passed"
else
  echo "  ❌  One or more gates failed"
fi
echo "═══════════════════════════════════════"
echo ""

exit "$FAIL"

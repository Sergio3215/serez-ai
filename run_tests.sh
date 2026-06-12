#!/usr/bin/env bash
# ── serez-ai Test Runner (Linux/macOS) ────────────────────────────────────────
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
SZ="${1:-}"; FILTER="${2:-}"

if [ -z "$SZ" ]; then
    for c in "$REPO/../Serez-code/target/release/sz" "$REPO/../Serez-code/target/debug/sz"; do
        [ -f "$c" ] && { SZ="$c"; break; }
    done
fi
[ -z "$SZ" ] || [ ! -f "$SZ" ] && { echo "sz no encontrado."; exit 1; }

FW="$REPO/tests/framework.sz"; PASS=0; FAIL=0

for f in "$REPO/tests/"*.sz; do
    name="$(basename "$f")"
    [ "$name" = "framework.sz" ] && continue
    [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]] && continue
    TMP="$(mktemp /tmp/sz_test_XXXXXX.sz)"
    cat "$FW" "$f" > "$TMP"
    if out="$(cd "$REPO" && timeout 60 "$SZ" "$TMP" 2>&1)"; then
        if echo "$out" | grep -q '\[FAIL\]'; then
            echo "[FAIL] $name"; FAIL=$((FAIL+1))
        else
            echo "[PASS] $name"; PASS=$((PASS+1))
        fi
    else
        echo "[FAIL] $name (exit $?)"; FAIL=$((FAIL+1))
    fi
    rm -f "$TMP"
done
echo "TOTAL: $PASS passed  $FAIL failed"
[ "$FAIL" -gt 0 ] && exit 1 || exit 0

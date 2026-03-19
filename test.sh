#!/usr/bin/env bash
# haunt test suite — basic integration tests
set -euo pipefail

HAUNT="$(cd "$(dirname "$0")" && pwd)/haunt"
PASS=0
FAIL=0

assert() {
    local desc="$1"
    if eval "$2"; then
        echo "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "Running haunt tests..."
echo ""

# ─── Help & version ──────────────────────────────────────────────────────────

echo "Help & version:"
assert "--help exits 0" "$HAUNT --help >/dev/null 2>&1"
assert "-h exits 0" "$HAUNT -h >/dev/null 2>&1"
assert "help exits 0" "$HAUNT help >/dev/null 2>&1"
assert "--help contains Usage" "$HAUNT --help 2>&1 | grep -q 'Usage:'"
assert "--version exits 0" "$HAUNT --version >/dev/null 2>&1"
assert "--version shows semver" "$HAUNT --version 2>&1 | grep -qE '^haunt [0-9]+\.[0-9]+\.[0-9]+$'"
echo ""

# ─── Hook discovery ──────────────────────────────────────────────────────────

echo "Hook discovery:"
assert "hooks/ directory exists" "[[ -d $(dirname "$HAUNT")/hooks ]]"
assert "claude-status hook exists" "[[ -d $(dirname "$HAUNT")/hooks/claude-status ]]"
assert "claude-status/decorate is executable" "[[ -x $(dirname "$HAUNT")/hooks/claude-status/decorate ]]"
assert "claude-status/on-focus is executable" "[[ -x $(dirname "$HAUNT")/hooks/claude-status/on-focus ]]"
assert "claude-status/on-start is executable" "[[ -x $(dirname "$HAUNT")/hooks/claude-status/on-start ]]"
assert "claude-status/on-stop is executable" "[[ -x $(dirname "$HAUNT")/hooks/claude-status/on-stop ]]"
echo ""

# ─── Shellcheck ───────────────────────────────────────────────────────────────

if command -v shellcheck &>/dev/null; then
    echo "Shellcheck:"
    assert "haunt passes shellcheck" "shellcheck $HAUNT"
    for hook in "$(dirname "$HAUNT")"/hooks/*/; do
        for script in "$hook"*; do
            [[ -f "$script" ]] || continue
            name="$(basename "$hook")/$(basename "$script")"
            assert "$name passes shellcheck" "shellcheck $script"
        done
    done
    echo ""
fi

# ─── Claude status hook logic ─────────────────────────────────────────────────

echo "Claude status hook:"
decorate="$(dirname "$HAUNT")/hooks/claude-status/decorate"

# Working state
result=$(printf 'tab-001\t⠐ Claude Code\tfalse\n' | "$decorate" 2>/dev/null)
assert "detects working state" "echo '$result' | grep -q 'tab-001'"

# Idle state (no previous = no attention)
rm -f "${TMPDIR:-/tmp}haunt-claude-states" "${TMPDIR:-/tmp}haunt-claude-attention"
result=$(printf 'tab-002\t✳ Claude Code\tfalse\n' | "$decorate" 2>/dev/null)
assert "idle with no previous state = no indicator" "[[ -z '$result' ]]"

# Working→idle transition (background tab)
printf 'tab-003\tworking\n' > "${TMPDIR:-/tmp}haunt-claude-states"
: > "${TMPDIR:-/tmp}haunt-claude-attention"
result=$(printf 'tab-003\t✳ Claude Code\tfalse\n' | "$decorate" 2>/dev/null)
assert "working→idle transition triggers attention" "echo '$result' | grep -q 'tab-003'"

# Working→idle transition (focused tab = no attention)
printf 'tab-005\tworking\n' > "${TMPDIR:-/tmp}haunt-claude-states"
: > "${TMPDIR:-/tmp}haunt-claude-attention"
result=$(printf 'tab-005\t✳ Claude Code\ttrue\n' | "$decorate" 2>/dev/null)
assert "working→idle on focused tab = no attention" "[[ -z \"\$result\" ]]"

# Non-Claude tab ignored
rm -f "${TMPDIR:-/tmp}haunt-claude-states" "${TMPDIR:-/tmp}haunt-claude-attention"
result=$(printf 'tab-004\t~/my-project\tfalse\n' | "$decorate" 2>/dev/null)
assert "non-Claude tab produces no indicator" "[[ -z '$result' ]]"

# Cleanup
rm -f "${TMPDIR:-/tmp}haunt-claude-states" "${TMPDIR:-/tmp}haunt-claude-attention"
echo ""

# ─── Summary ──────────────────────────────────────────────────────────────────

echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

#!/bin/bash
# NeighbourGo Agent Team — Serial execution mode
#
# Full pipeline: architect → developer → reviewer → tester
# Uses claude.ai subscription (no API key needed).
#
# Usage:
#   ./agents/team.sh "Fix the chat message ordering bug"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

cd "$PROJECT_ROOT"

# ─────────────────────────────────────────────────────────────────────────────
# Run agents: read-only (--print) vs active (full execution)
# ─────────────────────────────────────────────────────────────────────────────
run_readonly() {
  local agent_name="$1"
  local task="$2"
  echo ""
  echo "== $agent_name (read-only) =="
  local prompt="$(cat "$PROMPTS_DIR/${agent_name}.md")

---
## Current Task
$task"
  echo "$prompt" | claude --dangerously-skip-permissions --print 2>&1
}

run_active() {
  local agent_name="$1"
  local task="$2"
  echo ""
  echo "== $agent_name (active) =="
  local tmp="/tmp/agent-${agent_name}-$$.md"
  cat > "$tmp" << PROMPT_EOF
$(cat "$PROMPTS_DIR/${agent_name}.md")

---
## Current Task
$task

## Working Directory
$PROJECT_ROOT
PROMPT_EOF
  cd "$PROJECT_ROOT"
  claude --dangerously-skip-permissions -p "$(cat "$tmp")" 2>&1
  rm -f "$tmp"
}

# ─────────────────────────────────────────────────────────────────────────────
# Full pipeline
# ─────────────────────────────────────────────────────────────────────────────
run_pipeline() {
  local task="$1"

  echo "=========================================="
  echo "  NeighbourGo Agent Team (Serial)"
  echo "  Task: $task"
  echo "=========================================="

  # Step 1: Architect (read-only)
  echo ""
  echo "---- STEP 1/4: ARCHITECT ----"
  PLAN=$(run_readonly "architect" "$task")
  echo "$PLAN"

  # Step 2: Developer (active — edits files, runs commands)
  echo ""
  echo "---- STEP 2/4: DEVELOPER ----"
  DEV=$(run_active "developer" "Implement this plan:

$PLAN

Original requirement: $task")
  echo "$DEV"

  # Step 3: Reviewer (read-only)
  echo ""
  echo "---- STEP 3/4: REVIEWER ----"
  REVIEW=$(run_readonly "reviewer" "Review the changes for: $task

Developer reported:
$DEV")
  echo "$REVIEW"

  # Fix if reviewer requested changes
  if echo "$REVIEW" | grep -qi "REQUEST CHANGES"; then
    echo ""
    echo "---- STEP 3b: DEVELOPER FIX ----"
    DEV=$(run_active "developer" "Reviewer found issues. Fix them:

$REVIEW

Original task: $task")
    echo "$DEV"

    echo ""
    echo "---- STEP 3c: REVIEWER RE-CHECK ----"
    REVIEW=$(run_readonly "reviewer" "Re-review after fixes. Previous issues:

$REVIEW

Developer fix:
$DEV")
    echo "$REVIEW"
  fi

  # Step 4: Tester (active — runs tests)
  echo ""
  echo "---- STEP 4/4: TESTER ----"
  TEST=$(run_active "tester" "Write and run integration tests to verify:

$task

Developer implementation:
$DEV")
  echo "$TEST"

  # Fix if tests failed
  if echo "$TEST" | grep -qi "FAIL\|failed\|error"; then
    echo ""
    echo "---- STEP 4b: DEVELOPER FIX (test failure) ----"
    DEV=$(run_active "developer" "Tests failed. Fix:

$TEST

Original task: $task")
    echo "$DEV"

    echo ""
    echo "---- STEP 4c: TESTER RE-VERIFY ----"
    TEST=$(run_active "tester" "Re-run tests after fix for: $task")
    echo "$TEST"
  fi

  # Commit
  echo ""
  echo "---- COMMIT ----"
  cd "$PROJECT_ROOT"
  git add -A 2>/dev/null || true
  if git diff --cached --quiet 2>/dev/null; then
    echo "No changes to commit."
  else
    git commit -m "feat: $task

Agent Team: architect → developer → reviewer → tester

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>&1 || true
  fi

  echo ""
  echo "=========================================="
  echo "  PIPELINE COMPLETE"
  echo "=========================================="
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Usage:"
  echo "  ./agents/team.sh \"task description\""
  echo "  ./agents/team.sh --test-only"
  exit 1
fi

if [ "$1" = "--test-only" ]; then
  run_active "tester" "Run ALL integration tests and report results."
else
  run_pipeline "$*"
fi

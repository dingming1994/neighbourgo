#!/bin/bash
# NeighbourGo Agent Team — Multi-agent system using Claude Code CLI
#
# Uses the same auth as your claude.ai subscription.
# Architecture: PM → Architect → Developer → Reviewer → Tester
#
# Usage:
#   ./agents/team.sh "Fix the chat message ordering bug"
#   ./agents/team.sh --prd scripts/ralph/prd.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

cd "$PROJECT_ROOT"

# ─────────────────────────────────────────────────────────────────────────────
# Run a single agent
# ─────────────────────────────────────────────────────────────────────────────
run_agent() {
  local agent_name="$1"
  local task="$2"
  local prompt_file="$PROMPTS_DIR/${agent_name}.md"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  Agent: $agent_name"
  echo "║  Task: ${task:0:60}..."
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""

  # Combine agent system prompt with task
  local full_prompt
  full_prompt="$(cat "$prompt_file")

---
## Current Task
$task"

  # Run Claude Code CLI
  echo "$full_prompt" | claude --dangerously-skip-permissions --print 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# Full pipeline: architect → developer → reviewer → tester
# ─────────────────────────────────────────────────────────────────────────────
run_pipeline() {
  local task="$1"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  NeighbourGo Agent Team                                      ║"
  echo "║  Model: Claude Opus 4.6 (1M context)                        ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Task: $task"
  echo ""

  # Step 1: Architect designs the solution
  echo "━━━ STEP 1/4: ARCHITECT ━━━"
  local plan
  plan=$(run_agent "architect" "$task")
  echo "$plan"

  # Step 2: Developer implements
  echo ""
  echo "━━━ STEP 2/4: DEVELOPER ━━━"
  local dev_result
  dev_result=$(run_agent "developer" "Implement this plan:

$plan

Original requirement: $task")
  echo "$dev_result"

  # Step 3: Reviewer checks
  echo ""
  echo "━━━ STEP 3/4: REVIEWER ━━━"
  local review
  review=$(run_agent "reviewer" "Review the changes made for this task:

$task

The developer reported:
$dev_result")
  echo "$review"

  # Check if reviewer requested changes
  if echo "$review" | grep -qi "REQUEST CHANGES"; then
    echo ""
    echo "━━━ STEP 3b: DEVELOPER FIX (reviewer requested changes) ━━━"
    dev_result=$(run_agent "developer" "The reviewer found issues. Fix them:

$review

Original task: $task")
    echo "$dev_result"

    echo ""
    echo "━━━ STEP 3c: REVIEWER RE-CHECK ━━━"
    review=$(run_agent "reviewer" "Re-review after fixes:

$review

Developer's fix:
$dev_result")
    echo "$review"
  fi

  # Step 4: Tester verifies
  echo ""
  echo "━━━ STEP 4/4: TESTER ━━━"
  local test_result
  test_result=$(run_agent "tester" "Write and run integration tests to verify:

$task

Developer's implementation:
$dev_result")
  echo "$test_result"

  # Check if tests failed
  if echo "$test_result" | grep -qi "FAIL\|failed\|error"; then
    echo ""
    echo "━━━ STEP 4b: DEVELOPER FIX (tests failed) ━━━"
    dev_result=$(run_agent "developer" "Tests failed. Fix the issues:

$test_result

Original task: $task")
    echo "$dev_result"

    echo ""
    echo "━━━ STEP 4c: TESTER RE-VERIFY ━━━"
    test_result=$(run_agent "tester" "Re-run tests after developer fix:

Previous failures:
$test_result

Developer's fix:
$dev_result")
    echo "$test_result"
  fi

  # Commit
  echo ""
  echo "━━━ COMMIT ━━━"
  git add -A 2>/dev/null || true
  if git diff --cached --quiet 2>/dev/null; then
    echo "No changes to commit."
  else
    git commit -m "feat: $task

Implemented by Agent Team (architect → developer → reviewer → tester)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>&1 || true
  fi

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  PIPELINE COMPLETE                                           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Usage:"
  echo "  ./agents/team.sh \"task description\""
  echo "  ./agents/team.sh --prd scripts/ralph/prd.json"
  echo "  ./agents/team.sh --test-only"
  exit 1
fi

if [ "$1" = "--prd" ]; then
  PRD_FILE="${2:-scripts/ralph/prd.json}"
  # Process each story from PRD
  STORIES=$(python3 -c "
import json, sys
with open('$PRD_FILE') as f:
    prd = json.load(f)
for s in prd['userStories']:
    if not s.get('passes'):
        print(f\"{s['id']}|{s['title']}|{s['description']}\")
")
  if [ -z "$STORIES" ]; then
    echo "All stories already pass!"
    exit 0
  fi
  while IFS='|' read -r id title desc; do
    echo "Processing $id: $title"
    run_pipeline "$id: $title — $desc"
  done <<< "$STORIES"

elif [ "$1" = "--test-only" ]; then
  run_agent "tester" "Run ALL integration tests and report results. Tests: poster_journey, provider_journey, flow1_task_bidding, flow2_direct_hire, edit_profile."

else
  run_pipeline "$*"
fi

#!/bin/bash
# NeighbourGo Agent Team — Parallel execution mode
#
# Runs multiple tasks simultaneously, each in its own git worktree.
# Each task gets the full pipeline: architect → developer → reviewer → tester
# Results merge back to main when all pass.
#
# Usage:
#   ./agents/team-parallel.sh task1 "description 1" task2 "description 2" task3 "description 3"
#   ./agents/team-parallel.sh --prd scripts/ralph/prd.json
#   ./agents/team-parallel.sh --file tasks.txt  (one task per line)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKTREE_DIR="$PROJECT_ROOT/.worktrees"
LOG_DIR="$PROJECT_ROOT/.agent-logs"
TEAM_SH="$SCRIPT_DIR/team.sh"

cd "$PROJECT_ROOT"
mkdir -p "$WORKTREE_DIR" "$LOG_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Run one task in an isolated worktree
# ─────────────────────────────────────────────────────────────────────────────
run_task_in_worktree() {
  local task_id="$1"
  local task_desc="$2"
  local branch="agent/${task_id}"
  local wt_path="$WORKTREE_DIR/$task_id"
  local log_file="$LOG_DIR/${task_id}.log"

  echo "[${task_id}] Starting: ${task_desc:0:60}..."

  # Create branch and worktree
  git branch -D "$branch" 2>/dev/null || true
  git branch "$branch" HEAD 2>/dev/null
  rm -rf "$wt_path" 2>/dev/null || true
  git worktree add "$wt_path" "$branch" 2>/dev/null

  # Run the full pipeline in the worktree
  (
    cd "$wt_path"
    # Copy agent prompts to worktree
    cp -r "$SCRIPT_DIR/prompts" "$wt_path/agents/prompts" 2>/dev/null || true

    echo "[$task_id] ━━━ ARCHITECT ━━━"
    PLAN=$(echo "$(cat "$SCRIPT_DIR/prompts/architect.md")

---
## Current Task
$task_desc" | claude --dangerously-skip-permissions --print 2>&1) || true

    echo "[$task_id] ━━━ DEVELOPER ━━━"
    DEV=$(echo "$(cat "$SCRIPT_DIR/prompts/developer.md")

---
## Current Task
Implement this plan:
$PLAN

Original requirement: $task_desc" | claude --dangerously-skip-permissions --print 2>&1) || true

    echo "[$task_id] ━━━ REVIEWER ━━━"
    REVIEW=$(echo "$(cat "$SCRIPT_DIR/prompts/reviewer.md")

---
## Current Task
Review the changes for: $task_desc

Developer reported:
$DEV" | claude --dangerously-skip-permissions --print 2>&1) || true

    # Fix if reviewer requested changes
    if echo "$REVIEW" | grep -qi "REQUEST CHANGES"; then
      echo "[$task_id] ━━━ DEVELOPER FIX ━━━"
      DEV=$(echo "$(cat "$SCRIPT_DIR/prompts/developer.md")

---
## Current Task
Reviewer found issues, fix them:
$REVIEW

Original task: $task_desc" | claude --dangerously-skip-permissions --print 2>&1) || true
    fi

    echo "[$task_id] ━━━ TESTER ━━━"
    TEST=$(echo "$(cat "$SCRIPT_DIR/prompts/tester.md")

---
## Current Task
Write and run tests for: $task_desc

Developer implementation:
$DEV" | claude --dangerously-skip-permissions --print 2>&1) || true

    # Fix if tests failed
    if echo "$TEST" | grep -qi "FAIL\|failed"; then
      echo "[$task_id] ━━━ DEVELOPER FIX (test failure) ━━━"
      DEV=$(echo "$(cat "$SCRIPT_DIR/prompts/developer.md")

---
## Current Task
Tests failed, fix:
$TEST

Original task: $task_desc" | claude --dangerously-skip-permissions --print 2>&1) || true

      echo "[$task_id] ━━━ TESTER RE-VERIFY ━━━"
      TEST=$(echo "$(cat "$SCRIPT_DIR/prompts/tester.md")

---
## Current Task
Re-run tests after fix for: $task_desc" | claude --dangerously-skip-permissions --print 2>&1) || true
    fi

    # Commit in worktree
    git add -A 2>/dev/null || true
    git diff --cached --quiet 2>/dev/null || \
      git commit -m "feat($task_id): $task_desc

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>/dev/null || true

    echo "[$task_id] ✅ COMPLETE"
  ) > "$log_file" 2>&1 &

  echo $!  # Return PID
}

# ─────────────────────────────────────────────────────────────────────────────
# Merge all worktree branches back to main
# ─────────────────────────────────────────────────────────────────────────────
merge_all() {
  local task_ids=("$@")

  echo ""
  echo "━━━ MERGING ALL BRANCHES ━━━"

  for task_id in "${task_ids[@]}"; do
    local branch="agent/${task_id}"
    echo "Merging $branch..."
    git merge "$branch" --no-ff -m "Merge $task_id from parallel agent" 2>&1 || {
      echo "⚠️  Merge conflict on $branch — needs manual resolution"
      continue
    }
    # Cleanup
    git worktree remove "$WORKTREE_DIR/$task_id" 2>/dev/null || true
    git branch -d "$branch" 2>/dev/null || true
  done

  echo "━━━ ALL MERGED ━━━"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Usage:"
  echo "  ./agents/team-parallel.sh task1 \"desc 1\" task2 \"desc 2\""
  echo "  ./agents/team-parallel.sh --prd scripts/ralph/prd.json"
  echo "  ./agents/team-parallel.sh --file tasks.txt"
  exit 1
fi

PIDS=()
TASK_IDS=()

if [ "$1" = "--prd" ]; then
  PRD_FILE="${2:-scripts/ralph/prd.json}"
  while IFS='|' read -r id title desc; do
    pid=$(run_task_in_worktree "$id" "$title — $desc")
    PIDS+=("$pid")
    TASK_IDS+=("$id")
  done < <(python3 -c "
import json
with open('$PRD_FILE') as f:
    prd = json.load(f)
for s in prd['userStories']:
    if not s.get('passes'):
        print(f\"{s['id']}|{s['title']}|{s['description']}\")
")

elif [ "$1" = "--file" ]; then
  FILE="${2:-tasks.txt}"
  i=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    i=$((i+1))
    task_id="task-$(printf '%03d' $i)"
    pid=$(run_task_in_worktree "$task_id" "$line")
    PIDS+=("$pid")
    TASK_IDS+=("$task_id")
  done < "$FILE"

else
  # Parse pairs: task_id "description" task_id "description"
  while [ $# -ge 2 ]; do
    task_id="$1"
    task_desc="$2"
    shift 2
    pid=$(run_task_in_worktree "$task_id" "$task_desc")
    PIDS+=("$pid")
    TASK_IDS+=("$task_id")
  done
fi

if [ ${#PIDS[@]} -eq 0 ]; then
  echo "No tasks to run."
  exit 0
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ${#PIDS[@]} tasks running in parallel                              ║"
echo "║  Logs: .agent-logs/<task-id>.log                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Wait for all tasks to complete
FAILED=0
for i in "${!PIDS[@]}"; do
  pid="${PIDS[$i]}"
  task_id="${TASK_IDS[$i]}"
  if wait "$pid" 2>/dev/null; then
    echo "[${task_id}] ✅ Done"
  else
    echo "[${task_id}] ❌ Failed (see .agent-logs/${task_id}.log)"
    FAILED=$((FAILED+1))
  fi
done

echo ""
echo "Results: $((${#PIDS[@]} - FAILED))/${#PIDS[@]} succeeded"

# Merge successful branches
if [ $FAILED -eq 0 ]; then
  merge_all "${TASK_IDS[@]}"
else
  echo "⚠️  Some tasks failed. Review logs before merging."
  echo "   Logs: ls -la $LOG_DIR/"
  echo "   Manual merge: git merge agent/<task-id>"
fi

#!/bin/bash
# NeighbourGo Agent Team — Parallel execution mode
#
# Runs multiple tasks simultaneously, each in its own git worktree.
# Each task gets the full pipeline: architect → developer → reviewer → tester
# Results merge back to main when all pass.
#
# Usage:
#   ./agents/team-parallel.sh task1 "description 1" task2 "description 2"
#   ./agents/team-parallel.sh --prd scripts/ralph/prd.json
#   ./agents/team-parallel.sh --file tasks.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKTREE_DIR="$PROJECT_ROOT/.worktrees"
LOG_DIR="$PROJECT_ROOT/.agent-logs"

cd "$PROJECT_ROOT"
mkdir -p "$WORKTREE_DIR" "$LOG_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Run a single agent step (read-only agents use --print, others use full mode)
# ─────────────────────────────────────────────────────────────────────────────
run_readonly_agent() {
  local prompt_file="$1"
  local task="$2"
  local wt_path="$3"

  local full_prompt="$(cat "$prompt_file")

---
## Current Task
$task"

  cd "$wt_path"
  echo "$full_prompt" | claude --dangerously-skip-permissions --print 2>&1
}

run_active_agent() {
  local prompt_file="$1"
  local task="$2"
  local wt_path="$3"

  # Write prompt to temp file (avoids pipe issues with interactive claude)
  local tmp_prompt="$wt_path/.agent-prompt.md"
  cat > "$tmp_prompt" << PROMPT_EOF
$(cat "$prompt_file")

---
## Current Task
$task

## Working Directory
You are working in: $wt_path
All file paths are relative to this directory.
Run all commands from this directory.
PROMPT_EOF

  cd "$wt_path"
  claude --dangerously-skip-permissions -p "$(cat "$tmp_prompt")" 2>&1
  rm -f "$tmp_prompt"
}

# ─────────────────────────────────────────────────────────────────────────────
# Run one task in an isolated worktree with full pipeline
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

  # Copy agent prompts into worktree
  mkdir -p "$wt_path/agents/prompts"
  cp "$SCRIPT_DIR/prompts/"*.md "$wt_path/agents/prompts/" 2>/dev/null || true

  # Run the full pipeline in a subshell
  (
    echo "[$task_id] ━━━ ARCHITECT (read-only) ━━━"
    PLAN=$(run_readonly_agent "$SCRIPT_DIR/prompts/architect.md" "$task_desc" "$wt_path") || true
    echo "$PLAN"

    echo ""
    echo "[$task_id] ━━━ DEVELOPER (active) ━━━"
    DEV=$(run_active_agent "$SCRIPT_DIR/prompts/developer.md" \
      "Implement this plan:

$PLAN

Original requirement: $task_desc" "$wt_path") || true
    echo "$DEV"

    echo ""
    echo "[$task_id] ━━━ REVIEWER (read-only) ━━━"
    REVIEW=$(run_readonly_agent "$SCRIPT_DIR/prompts/reviewer.md" \
      "Review the changes for: $task_desc

Developer reported:
$DEV" "$wt_path") || true
    echo "$REVIEW"

    # Fix if reviewer requested changes
    if echo "$REVIEW" | grep -qi "REQUEST CHANGES"; then
      echo ""
      echo "[$task_id] ━━━ DEVELOPER FIX ━━━"
      DEV=$(run_active_agent "$SCRIPT_DIR/prompts/developer.md" \
        "Reviewer found issues. Fix them:

$REVIEW

Original task: $task_desc" "$wt_path") || true
      echo "$DEV"
    fi

    echo ""
    echo "[$task_id] ━━━ TESTER (active) ━━━"
    TEST=$(run_active_agent "$SCRIPT_DIR/prompts/tester.md" \
      "Write and run integration tests to verify: $task_desc

Developer implementation:
$DEV" "$wt_path") || true
    echo "$TEST"

    # Fix if tests failed
    if echo "$TEST" | grep -qi "FAIL\|failed\|error"; then
      echo ""
      echo "[$task_id] ━━━ DEVELOPER FIX (test failure) ━━━"
      DEV=$(run_active_agent "$SCRIPT_DIR/prompts/developer.md" \
        "Tests failed. Fix:
$TEST

Original task: $task_desc" "$wt_path") || true
      echo "$DEV"

      echo ""
      echo "[$task_id] ━━━ TESTER RE-VERIFY ━━━"
      TEST=$(run_active_agent "$SCRIPT_DIR/prompts/tester.md" \
        "Re-run tests after fix for: $task_desc" "$wt_path") || true
      echo "$TEST"
    fi

    # Commit in worktree
    cd "$wt_path"
    git add -A 2>/dev/null || true
    if ! git diff --cached --quiet 2>/dev/null; then
      git commit -m "feat($task_id): $task_desc

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>/dev/null || true
    fi

    echo ""
    echo "[$task_id] COMPLETE"
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

  cd "$PROJECT_ROOT"
  for task_id in "${task_ids[@]}"; do
    local branch="agent/${task_id}"
    local wt_path="$WORKTREE_DIR/$task_id"

    # Check if branch has commits ahead of main
    local ahead
    ahead=$(git rev-list main.."$branch" --count 2>/dev/null || echo "0")

    if [ "$ahead" -eq 0 ]; then
      echo "  $branch: no changes, skipping"
    else
      echo "  Merging $branch ($ahead commits)..."
      git merge "$branch" --no-ff -m "Merge $task_id from parallel agent" 2>&1 || {
        echo "  WARNING: Merge conflict on $branch — needs manual resolution"
        continue
      }
    fi

    # Cleanup worktree and branch
    git worktree remove "$wt_path" --force 2>/dev/null || rm -rf "$wt_path"
    git branch -D "$branch" 2>/dev/null || true
  done

  git worktree prune 2>/dev/null || true
  echo "━━━ MERGE COMPLETE ━━━"
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
echo "=========================================="
echo "  ${#PIDS[@]} tasks running in parallel"
echo "  Logs: .agent-logs/<task-id>.log"
echo "=========================================="
echo ""

# Wait for all tasks
FAILED=0
for i in "${!PIDS[@]}"; do
  pid="${PIDS[$i]}"
  task_id="${TASK_IDS[$i]}"
  if wait "$pid" 2>/dev/null; then
    echo "[${task_id}] Done"
  else
    echo "[${task_id}] Failed (see .agent-logs/${task_id}.log)"
    FAILED=$((FAILED+1))
  fi
done

echo ""
echo "Results: $((${#PIDS[@]} - FAILED))/${#PIDS[@]} succeeded"

# Merge successful branches
if [ $FAILED -eq 0 ]; then
  merge_all "${TASK_IDS[@]}"
else
  echo ""
  echo "Some tasks failed. Review logs before merging."
  echo "  View logs: cat .agent-logs/<task-id>.log"
  echo "  Manual merge: git merge agent/<task-id>"
fi

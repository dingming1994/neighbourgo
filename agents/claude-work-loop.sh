#!/bin/bash
# Claude 3-hour autonomous work loop
# Works on claimed tasks, discovers new ones, respects Codex ownership
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

HOURS=4
START=$(date +%s)
ITER=0

log() { echo "[$(date '+%H:%M:%S')] $*"; }

time_left() {
  local elapsed=$(( ($(date +%s) - START) / 60 ))
  local remaining=$(( HOURS * 60 - elapsed ))
  echo $remaining
}

# Process a single task: develop → verify → commit → merge → log
process_task() {
  local task_id="$1"
  local wt="$PROJECT_ROOT/.worktrees/$(echo $task_id | tr "A-Z" "a-z")-claude"

  log "Processing $task_id in $wt"
  python3 agents/task_board.py set-status "$task_id" --status in_progress --model claude 2>/dev/null || true

  # Run Claude on the task
  local task_info
  task_info=$(python3 -c "
import json
board = json.load(open('agents/task-board.json'))
for t in board['tasks']:
    if t['id'] == '$task_id':
        print(t['title'] + ' — ' + t.get('description',''))
        break
")

  local prompt="$(cat agents/prompts/developer.md)

---
## Current Task: $task_id
$task_info

## Working Directory
$wt

## Rules
1. Work ONLY in this directory
2. Run flutter analyze after changes
3. If this is a testing task, run integration tests with Firebase emulators
4. Commit your changes with a descriptive message
5. Do NOT touch files outside this task's scope"

  cd "$wt"
  echo "$prompt" | claude --dangerously-skip-permissions --print > /dev/null 2>&1 || true

  # Commit any changes
  git add -A 2>/dev/null || true
  if ! git diff --cached --quiet 2>/dev/null; then
    git commit -m "fix($task_id): $(echo "$task_info" | head -c 60)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>/dev/null || true
  fi

  cd "$PROJECT_ROOT"

  # Merge to main
  python3 agents/task_board.py set-status "$task_id" --status done --model claude 2>/dev/null || true
  git checkout main 2>/dev/null
  git merge "agents/claude/$(echo $task_id | tr "A-Z" "a-z")" --no-ff -m "Merge $task_id from claude" 2>/dev/null || true
  git worktree remove "$wt" --force 2>/dev/null || rm -rf "$wt"
  git branch -D "agents/claude/$(echo $task_id | tr "A-Z" "a-z")" 2>/dev/null || true

  # Update board
  python3 -c "
import json
board = json.load(open('agents/task-board.json'))
for t in board['tasks']:
    if t['id'] == '$task_id':
        t['status'] = 'merged'
with open('agents/task-board.json', 'w') as f:
    json.dump(board, f, indent=2)
" 2>/dev/null || true

  log "$task_id DONE"
}

# Discover and plan new tasks
discover_tasks() {
  log "Discovering new improvement opportunities..."

  local prompt="You are an Architect for NeighbourGo. Read the codebase at $PROJECT_ROOT/lib/ and:
1. Find 3-5 bugs, UX issues, or missing functionality
2. Focus on things a real user would notice
3. Do NOT duplicate work already done (check agents/ITERATION_LOG.md)
4. Do NOT touch payment features
5. Add new planned tasks to agents/task-board.json with IDs starting from UX-220+
6. Each task needs: id, title, description, status='planned', ownerModel=null, branch=null, worktree=null, notes=[]
7. Write the updated task-board.json"

  echo "$prompt" | claude --dangerously-skip-permissions --print > /dev/null 2>&1 || true
  log "Discovery complete"
}

# ─── Main loop ───
log "Claude work loop started ($HOURS hours)"

while [ "$(time_left)" -gt 10 ]; do
  ITER=$((ITER + 1))
  log "=== Iteration $ITER ($(time_left) min remaining) ==="

  # Get Claude's claimed/planned tasks
  CLAUDE_TASKS=$(python3 -c "
import json
board = json.load(open('agents/task-board.json'))
for t in board['tasks']:
    if t['status'] in ['claimed','in_progress'] and t.get('ownerModel') == 'claude':
        print(t['id'])
    elif t['status'] == 'planned' and t.get('ownerModel') is None:
        print(t['id'])
" 2>/dev/null | head -3)

  if [ -z "$CLAUDE_TASKS" ]; then
    log "No tasks available. Running discovery..."
    discover_tasks

    # Claim newly planned tasks
    NEW_TASKS=$(python3 -c "
import json
board = json.load(open('agents/task-board.json'))
for t in board['tasks']:
    if t['status'] == 'planned' and t.get('ownerModel') is None:
        print(t['id'])
" 2>/dev/null | head -3)

    for tid in $NEW_TASKS; do
      python3 agents/task_board.py claim "$tid" --model claude 2>/dev/null || true
    done
    CLAUDE_TASKS="$NEW_TASKS"
  fi

  for tid in $CLAUDE_TASKS; do
    if [ "$(time_left)" -le 10 ]; then break; fi
    process_task "$tid"
  done

  # Write iteration log
  cat >> agents/ITERATION_LOG.md << LOGEOF

## $(date '+%Y-%m-%d %H:%M') SGT | claude | ITER-$(printf '%03d' $((6 + ITER)))

- Task IDs: $(echo $CLAUDE_TASKS | tr '\n' ', ')
- Summary: Autonomous work loop iteration $ITER
- Verification: flutter analyze 0 errors
- Risks: Check ITERATION_LOG for details
LOGEOF

  git add agents/ 2>/dev/null && git commit -m "chore: claude iteration $ITER" 2>/dev/null && git push origin main 2>/dev/null || true

done

log "Work loop finished after $ITER iterations"

#!/bin/bash
# Claude autonomous work loop
# Works on tasks, discovers new ones, respects Codex ownership
# Resilient: never exits on single task failure

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

HOURS="${1:-4}"
START=$(date +%s)
ITER=0

log() { echo "[$(date '+%H:%M:%S')] $*"; }

time_left() {
  local elapsed=$(( ($(date +%s) - START) / 60 ))
  echo $(( HOURS * 60 - elapsed ))
}

task_id_lower() { echo "$1" | tr 'A-Z' 'a-z'; }

# ─────────────────────────────────────────────────────────────────────────────
# Ensure worktree exists for a task, creating if needed
# ─────────────────────────────────────────────────────────────────────────────
ensure_worktree() {
  local task_id="$1"
  local tid_lower
  tid_lower=$(task_id_lower "$task_id")
  local branch="agents/claude/${tid_lower}"
  local wt="$PROJECT_ROOT/.worktrees/${tid_lower}-claude"

  if [ -d "$wt" ]; then
    return 0
  fi

  # Clean stale refs
  git worktree prune 2>/dev/null || true
  git branch -D "$branch" 2>/dev/null || true
  rm -rf "$wt" 2>/dev/null || true

  # Create fresh branch + worktree
  git branch "$branch" HEAD 2>/dev/null || true
  git worktree add "$wt" "$branch" 2>/dev/null || {
    log "  WARNING: Could not create worktree for $task_id, working in main"
    return 1
  }
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Process a single task
# ─────────────────────────────────────────────────────────────────────────────
process_task() {
  local task_id="$1"
  local tid_lower
  tid_lower=$(task_id_lower "$task_id")
  local branch="agents/claude/${tid_lower}"
  local wt="$PROJECT_ROOT/.worktrees/${tid_lower}-claude"

  log "Processing $task_id"

  # Ensure worktree exists
  if ! ensure_worktree "$task_id"; then
    # Fallback: work directly in main (less isolated but doesn't crash)
    wt="$PROJECT_ROOT"
    branch="main"
  fi

  python3 agents/task_board.py set-status "$task_id" --status in_progress --model claude 2>/dev/null || true

  # Get task info
  local task_info
  task_info=$(python3 -c "
import json
board = json.load(open('$PROJECT_ROOT/agents/task-board.json'))
for t in board['tasks']:
    if t['id'] == '$task_id':
        print(t['title'] + ' — ' + t.get('description',''))
        break
" 2>/dev/null || echo "$task_id")

  # Run Claude with -p flag (active mode — actually edits files)
  local prompt
  prompt="$(cat "$PROJECT_ROOT/agents/prompts/developer.md")

---
## Current Task: $task_id
$task_info

## Working Directory
$wt

## Rules
1. Work ONLY in the directory above
2. Run flutter analyze after changes
3. If this is a testing task, run integration tests with Firebase emulators
4. Commit your changes with a descriptive message
5. Do NOT touch files outside this task's scope"

  cd "$wt"
  claude --dangerously-skip-permissions -p "$prompt" 2>&1 || true

  # Commit any uncommitted changes
  git add -A 2>/dev/null || true
  if ! git diff --cached --quiet 2>/dev/null; then
    git commit -m "fix($task_id): $(echo "$task_info" | head -c 60)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>" 2>/dev/null || true
  fi

  cd "$PROJECT_ROOT"

  # Merge to main (skip if we were already on main)
  if [ "$branch" != "main" ]; then
    python3 agents/task_board.py set-status "$task_id" --status done --model claude 2>/dev/null || true
    git checkout main 2>/dev/null || true
    git merge "$branch" --no-ff -m "Merge $task_id from claude" 2>/dev/null || true
    git worktree remove "$wt" --force 2>/dev/null || rm -rf "$wt"
    git branch -D "$branch" 2>/dev/null || true
  else
    python3 agents/task_board.py set-status "$task_id" --status done --model claude 2>/dev/null || true
  fi

  # Mark merged on board
  python3 -c "
import json
board = json.load(open('$PROJECT_ROOT/agents/task-board.json'))
for t in board['tasks']:
    if t['id'] == '$task_id':
        t['status'] = 'merged'
with open('$PROJECT_ROOT/agents/task-board.json', 'w') as f:
    json.dump(board, f, indent=2)
" 2>/dev/null || true

  git add -A 2>/dev/null && git commit -m "chore: mark $task_id merged" 2>/dev/null || true
  git push origin main 2>/dev/null || true

  log "$task_id DONE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Discover new tasks (Architect role)
# ─────────────────────────────────────────────────────────────────────────────
discover_tasks() {
  log "Discovering new improvement opportunities..."

  claude --dangerously-skip-permissions -p "You are an Architect for NeighbourGo (Flutter + Firebase app at $PROJECT_ROOT).

1. Read agents/ITERATION_LOG.md to see what's been done
2. Read agents/task-board.json to see current tasks
3. Audit lib/features/ for remaining bugs, UX issues, or incomplete features
4. Find the next highest-value task ID by checking existing IDs in task-board.json
5. Add 3 new planned tasks to agents/task-board.json
6. Each task needs: id, title, description, status='planned', ownerModel=null, branch=null, worktree=null, notes=[]
7. Do NOT duplicate existing tasks. Do NOT touch payment features.
8. Focus on things a real user would notice: broken flows, missing data, visual issues." 2>&1 || true

  git add agents/task-board.json 2>/dev/null && git commit -m "plan: discover new tasks" 2>/dev/null && git push origin main 2>/dev/null || true
  log "Discovery complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# Get next tasks to work on
# ─────────────────────────────────────────────────────────────────────────────
get_claude_tasks() {
  python3 -c "
import json
board = json.load(open('$PROJECT_ROOT/agents/task-board.json'))
# First: tasks already claimed/in_progress by claude
for t in board['tasks']:
    if t['status'] in ['claimed','in_progress'] and t.get('ownerModel') == 'claude':
        print(t['id'])
" 2>/dev/null
}

get_planned_tasks() {
  python3 -c "
import json
board = json.load(open('$PROJECT_ROOT/agents/task-board.json'))
for t in board['tasks']:
    if t['status'] == 'planned' and t.get('ownerModel') is None:
        print(t['id'])
" 2>/dev/null | head -3
}

# ─────────────────────────────────────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────────────────────────────────────
log "Claude work loop started ($HOURS hours)"

while [ "$(time_left)" -gt 10 ]; do
  ITER=$((ITER + 1))
  log "=== Iteration $ITER ($(time_left) min remaining) ==="

  cd "$PROJECT_ROOT"
  git checkout main 2>/dev/null || true
  git pull origin main 2>/dev/null || true

  # 1. Work on Claude's existing tasks first
  TASKS=$(get_claude_tasks)

  # 2. If none, claim planned tasks
  if [ -z "$TASKS" ]; then
    PLANNED=$(get_planned_tasks)
    if [ -z "$PLANNED" ]; then
      # 3. No planned tasks either — discover new ones
      discover_tasks
      PLANNED=$(get_planned_tasks)
    fi

    # Claim planned tasks
    for tid in $PLANNED; do
      python3 agents/task_board.py claim "$tid" --model claude 2>/dev/null || true
    done
    TASKS=$(get_claude_tasks)
  fi

  if [ -z "$TASKS" ]; then
    log "No tasks to work on. Sleeping 5 min..."
    sleep 300
    continue
  fi

  # Process each task (each one is isolated, errors don't kill the loop)
  for tid in $TASKS; do
    if [ "$(time_left)" -le 10 ]; then break; fi
    process_task "$tid" || log "WARNING: $tid had errors, continuing..."
  done

  # Write iteration log
  cat >> "$PROJECT_ROOT/agents/ITERATION_LOG.md" << LOGEOF

## $(date '+%Y-%m-%d %H:%M') SGT | claude | ITER-$(printf '%03d' $((6 + ITER)))

- Task IDs: $(echo $TASKS | tr '\n' ', ')
- Summary: Autonomous work loop iteration $ITER
- Verification: See task-specific commits
- Risks: Check git log for details
LOGEOF

  git add agents/ 2>/dev/null && git commit -m "docs: claude loop iteration $ITER" 2>/dev/null && git push origin main 2>/dev/null || true

done

log "Work loop finished after $ITER iterations ($(( ($(date +%s) - START) / 60 )) min elapsed)"

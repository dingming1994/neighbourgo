#!/bin/bash
# Overnight progress monitor — logs Ralph's progress every 10 minutes
# Also restarts Ralph if it dies, and starts next cycle after completion

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/agents/overnight-progress.log"
PRD_FILE="$PROJECT_ROOT/scripts/ralph/prd.json"

cd "$PROJECT_ROOT"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_progress() {
  local total=$(python3 -c "import json; prd=json.load(open('$PRD_FILE')); print(len(prd['userStories']))")
  local passed=$(python3 -c "import json; prd=json.load(open('$PRD_FILE')); print(sum(1 for s in prd['userStories'] if s.get('passes')))")
  local latest_commit=$(git log --oneline -1 2>/dev/null || echo "none")
  local branch=$(git branch --show-current 2>/dev/null || echo "unknown")

  log "Progress: $passed/$total stories passed | Branch: $branch | Latest: $latest_commit"
}

is_ralph_running() {
  pgrep -f "ralph.sh" > /dev/null 2>&1
}

start_ralph() {
  log "Starting Ralph (15 iterations)..."
  nohup bash scripts/ralph/ralph.sh --tool claude 15 >> /tmp/ralph-overnight.log 2>&1 &
  log "Ralph started (PID: $!)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main loop — runs for 8 hours
# ─────────────────────────────────────────────────────────────────────────────
log "=========================================="
log "Overnight monitor started"
log "Expected duration: ~8 hours"
log "=========================================="

check_progress

CYCLES=0
MAX_HOURS=8
START_TIME=$(date +%s)

while true; do
  ELAPSED=$(( ($(date +%s) - START_TIME) / 3600 ))

  if [ $ELAPSED -ge $MAX_HOURS ]; then
    log "8 hours elapsed. Stopping monitor."
    break
  fi

  # Check if Ralph is running
  if ! is_ralph_running; then
    # Ralph finished or died — check if all stories passed
    local_passed=$(python3 -c "import json; prd=json.load(open('$PRD_FILE')); print(sum(1 for s in prd['userStories'] if s.get('passes')))")
    local_total=$(python3 -c "import json; prd=json.load(open('$PRD_FILE')); print(len(prd['userStories']))")

    if [ "$local_passed" -eq "$local_total" ]; then
      CYCLES=$((CYCLES + 1))
      log "Cycle $CYCLES COMPLETE — all $local_total stories passed!"
      log "Merging to main..."

      # Merge current branch to main
      CURRENT_BRANCH=$(git branch --show-current)
      git checkout main 2>/dev/null
      git merge "$CURRENT_BRANCH" --no-ff -m "Merge overnight cycle $CYCLES: $CURRENT_BRANCH" 2>/dev/null || true
      git push origin main 2>/dev/null || true

      log "Merged to main. Starting discovery cycle..."

      # Generate next PRD — discover what still needs work
      log "Running discovery: what else needs improvement?"
      echo "You are Ralph, a product manager for NeighbourGo (Flutter + Firebase app).

Analyze the current state of the app at $(pwd)/lib/ and:
1. Find bugs, incomplete features, UI issues, missing functionality
2. Focus on user experience for both Client (poster) and Provider roles
3. Create a new prd.json at scripts/ralph/prd.json with 5-8 user stories
4. Stories should focus on: polish, bug fixes, UX improvements, missing edge cases
5. Do NOT include payment features
6. Each story must have testable acceptance criteria
7. Set branchName to ralph/overnight-cycle-$((CYCLES+1))

Write the prd.json file." | claude --dangerously-skip-permissions --print > /dev/null 2>&1 || true

      # Create new branch and restart Ralph
      NEW_BRANCH="ralph/overnight-cycle-$((CYCLES+1))"
      git checkout -b "$NEW_BRANCH" 2>/dev/null || git checkout "$NEW_BRANCH" 2>/dev/null
      git add -A 2>/dev/null && git commit -m "feat: overnight cycle $((CYCLES+1)) PRD" 2>/dev/null || true

      start_ralph
    else
      log "Ralph stopped but only $local_passed/$local_total passed. Restarting..."
      start_ralph
    fi
  fi

  # Log progress every 10 minutes
  sleep 600
  check_progress
done

log "=========================================="
log "Overnight monitor finished"
log "Total cycles completed: $CYCLES"
check_progress
log "=========================================="

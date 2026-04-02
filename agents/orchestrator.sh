#!/bin/bash
# NeighbourGo Orchestrator — Ralph plans, Agent Team executes in parallel
#
# Flow:
#   1. Ralph (Planner) receives a high-level requirement
#   2. Ralph breaks it into independent subtasks (prd.json)
#   3. Orchestrator groups subtasks by dependency
#   4. Independent subtasks run in parallel via team-parallel.sh
#   5. Dependent subtasks run sequentially after their dependencies
#   6. All results merge to main
#
# Usage:
#   ./agents/orchestrator.sh "Build a complete payment system with receipts, refunds, and history"
#   ./agents/orchestrator.sh --prd scripts/ralph/prd.json   # Skip planning, run existing PRD

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRD_FILE="$PROJECT_ROOT/scripts/ralph/prd.json"
PARALLEL_SH="$SCRIPT_DIR/team-parallel.sh"
SERIAL_SH="$SCRIPT_DIR/team.sh"

cd "$PROJECT_ROOT"

# ─────────────────────────────────────────────────────────────────────────────
# Phase 1: Ralph plans and breaks down the requirement
# ─────────────────────────────────────────────────────────────────────────────
plan_with_ralph() {
  local requirement="$1"

  echo ""
  echo "=========================================="
  echo ""
  echo "=========================================="
  echo ""
  echo "Requirement: $requirement"
  echo ""

  # Ralph generates a prd.json with subtasks
  local ralph_prompt="You are Ralph, a senior product manager and technical architect.

Your job: break down this requirement into independent, parallelizable user stories.

Requirement: $requirement

Project: NeighbourGo — Flutter + Firebase community service marketplace app.
Project root: $PROJECT_ROOT

Read the codebase to understand existing patterns, then output a prd.json with:
1. featureName: short name
2. branchName: ralph/<feature-name>
3. userStories: array of stories, each with:
   - id: US-XXX (continue from existing numbering)
   - title: short title
   - description: what to implement
   - acceptanceCriteria: array of specific, testable criteria
   - passes: false
   - dependsOn: array of story IDs this depends on (empty = independent, can run in parallel)

Rules for splitting:
- Each story should be implementable independently (no circular dependencies)
- Maximize parallelism: stories that don't share files should have no dependencies
- Each story should take ~1 agent pipeline to complete (architect → dev → review → test)
- Include integration test stories for end-to-end verification
- Mark dependencies explicitly so the orchestrator knows execution order

Write the output to $PRD_FILE"

  echo "$ralph_prompt" | claude --dangerously-skip-permissions --print 2>&1
  echo ""

  # Verify PRD was created
  if [ ! -f "$PRD_FILE" ]; then
    echo "ERROR: Ralph did not create $PRD_FILE"
    exit 1
  fi

  echo "PRD created: $PRD_FILE"
  python3 -c "
import json
with open('$PRD_FILE') as f:
    prd = json.load(f)
print(f\"Feature: {prd['featureName']}\")
print(f\"Stories: {len(prd['userStories'])}\")
for s in prd['userStories']:
    deps = s.get('dependsOn', [])
    dep_str = f' (depends on: {\", \".join(deps)})' if deps else ' (independent)'
    print(f\"  {s['id']}: {s['title']}{dep_str}\")
"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase 2: Execute stories respecting dependency order
# ─────────────────────────────────────────────────────────────────────────────
execute_prd() {
  echo ""
  echo "=========================================="
  echo ""
  echo "=========================================="
  echo ""

  # Parse stories into dependency waves
  python3 << 'PYEOF'
import json, sys, os

prd_file = os.environ.get("PRD_FILE", "scripts/ralph/prd.json")
with open(prd_file) as f:
    prd = json.load(f)

stories = {s["id"]: s for s in prd["userStories"]}
completed = {s["id"] for s in prd["userStories"] if s.get("passes")}

# Build execution waves (topological sort by dependency)
waves = []
remaining = {sid: s for sid, s in stories.items() if sid not in completed}

while remaining:
    # Find stories whose dependencies are all completed
    wave = []
    for sid, s in remaining.items():
        deps = set(s.get("dependsOn", []))
        if deps.issubset(completed):
            wave.append(sid)

    if not wave:
        print("ERROR: Circular dependency detected!")
        for sid in remaining:
            print(f"  {sid} depends on {remaining[sid].get('dependsOn', [])}")
        sys.exit(1)

    waves.append(wave)
    for sid in wave:
        completed.add(sid)
        del remaining[sid]

# Output waves as shell-parseable format
for i, wave in enumerate(waves):
    wave_stories = []
    for sid in wave:
        s = stories[sid]
        title = s["title"].replace('"', '\\"')
        desc = s["description"].replace('"', '\\"')
        wave_stories.append(f'{sid}|{title}|{desc}')
    print(f"WAVE_{i}=" + ";".join(wave_stories))

print(f"TOTAL_WAVES={len(waves)}")
PYEOF
}

run_waves() {
  # Source the wave definitions
  eval "$(execute_prd)"

  if [ -z "${TOTAL_WAVES:-}" ]; then
    echo "No waves to execute (all stories passed or error in planning)"
    return
  fi

  echo "Execution plan: $TOTAL_WAVES wave(s)"
  echo ""

  for wave_idx in $(seq 0 $((TOTAL_WAVES - 1))); do
    local wave_var="WAVE_${wave_idx}"
    local wave_data="${!wave_var}"

    # Count stories in this wave
    local count
    count=$(echo "$wave_data" | tr ';' '\n' | wc -l | tr -d ' ')

    echo "━━━ WAVE $((wave_idx + 1))/$TOTAL_WAVES ($count tasks) ━━━"

    if [ "$count" -eq 1 ]; then
      # Single task — run serial
      IFS='|' read -r task_id title desc <<< "$wave_data"
      echo "  Running $task_id: $title (serial)"
      "$SERIAL_SH" "$title — $desc"
    else
      # Multiple tasks — run parallel
      local args=()
      while IFS='|' read -r task_id title desc; do
        args+=("$task_id" "$title — $desc")
        echo "  Parallel: $task_id: $title"
      done < <(echo "$wave_data" | tr ';' '\n')

      "$PARALLEL_SH" "${args[@]}"
    fi

    # Mark completed stories in PRD
    python3 -c "
import json
with open('$PRD_FILE') as f:
    prd = json.load(f)
wave_ids = set('$(echo "$wave_data" | tr ';' '\n' | cut -d'|' -f1 | tr '\n' ',')'.rstrip(',').split(','))
for s in prd['userStories']:
    if s['id'] in wave_ids:
        s['passes'] = True
with open('$PRD_FILE', 'w') as f:
    json.dump(prd, f, indent=2)
print(f'Marked {len(wave_ids)} stories as passed')
"

    echo ""
  done

  echo ""
  echo "=========================================="
  echo ""
  echo "=========================================="
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "NeighbourGo Orchestrator — Ralph plans, Agent Team executes"
  echo ""
  echo "Usage:"
  echo "  ./agents/orchestrator.sh \"High-level requirement\""
  echo "  ./agents/orchestrator.sh --prd scripts/ralph/prd.json"
  echo ""
  echo "Flow:"
  echo "  1. Ralph breaks requirement into subtasks (prd.json)"
  echo "  2. Independent subtasks run in parallel (git worktrees)"
  echo "  3. Dependent subtasks wait for their deps"
  echo "  4. Each subtask: architect → developer → reviewer → tester"
  echo "  5. All merge to main"
  exit 1
fi

if [ "$1" = "--prd" ]; then
  PRD_FILE="${2:-$PRD_FILE}"
  export PRD_FILE
  echo "Using existing PRD: $PRD_FILE"
  run_waves
else
  REQUIREMENT="$*"
  export PRD_FILE
  plan_with_ralph "$REQUIREMENT"
  run_waves
fi

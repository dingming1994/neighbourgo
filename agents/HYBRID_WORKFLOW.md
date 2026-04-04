# NeighbourGo Hybrid LLM Workflow

This workflow separates planning from execution.

## Roles

### Architect
- Model-neutral and independent from Claude/Codex.
- Reads the codebase, writes plans, defines task boundaries, dependencies, and acceptance criteria.
- Does not claim branches or edit code.
- Produces or updates `scripts/ralph/prd.json` and/or `agents/task-board.json`.

### Developer
- Implements one claimed task in that task's dedicated worktree.
- Runs `flutter analyze` and task-specific tests.
- Must not edit another task's branch/worktree.

### Reviewer
- Reviews only the claimed task branch.
- Does not move the task to another model.
- Can mark the task `in_review`, `blocked`, or `done`.

### Tester
- Tests only the claimed task branch/worktree.
- Can mark the task `in_test`, `blocked`, or `done`.

## Ownership Rule

Task ownership is at the task level, not the role level.

Once a task is claimed by one model:
- `claude` owns the whole task pipeline, or
- `codex` owns the whole task pipeline

The other model must not claim or execute the same task.

## Branch and Worktree Rule

Every claimed task gets:
- its own git branch
- its own git worktree

Default branch pattern:
- `agents/claude/<task-id>`
- `agents/codex/<task-id>`

Default worktree pattern:
- `.worktrees/<task-id>-claude`
- `.worktrees/<task-id>-codex`

All coding, testing, and review for that task happens only inside that worktree.

## Task Lifecycle

1. Architect creates planned tasks.
2. Claude or Codex claims one task.
3. Claim creates branch + worktree and locks the task to that model.
4. Developer works in the task worktree.
5. Reviewer checks the same branch.
6. Tester validates the same branch.
7. The active model appends an entry to `agents/ITERATION_LOG.md`.
8. Task is marked `done`.
9. Task branch merges back to `main`.
10. Board is updated to `merged`.

## Commands

Initialize board:

```bash
python3 agents/task_board.py init
```

Import tasks from PRD:

```bash
python3 agents/task_board.py init --from-prd scripts/ralph/prd.json
```

Show board:

```bash
python3 agents/task_board.py status
```

Claim a task for Codex:

```bash
python3 agents/task_board.py claim US-201 --model codex
```

Claim a task for Claude:

```bash
python3 agents/task_board.py claim US-202 --model claude
```

Mark progress:

```bash
python3 agents/task_board.py set-status US-201 --status in_progress --model codex
python3 agents/task_board.py set-status US-201 --status in_review --model codex
python3 agents/task_board.py set-status US-201 --status in_test --model codex
python3 agents/task_board.py set-status US-201 --status done --model codex
```

Merge back to main:

```bash
python3 agents/task_board.py merge US-201 --target main --cleanup
```

Release a task back to planning:

```bash
python3 agents/task_board.py release US-201 --note "paused, needs re-scope"
```

## Important Constraint

The task board is the source of truth.

If a task is already claimed by one model, the other model must not pick it up, even if the PRD still shows it as open.

## Iteration Log Requirement

Every Claude or Codex work batch must append a summary to `agents/ITERATION_LOG.md`.

The goal is:
- preserve human-readable project history
- give the other model a clean handoff
- avoid re-discovery from git diff alone

Minimum content per entry:
- timestamp
- model
- task ids
- branches
- summary
- key changes
- verification
- risks or follow-up

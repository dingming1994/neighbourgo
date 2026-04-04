# NeighbourGo Agent Workflows

This repo supports two execution styles:

1. Legacy Claude-first orchestration under `team.py`, `team.sh`, and `team-parallel.sh`
2. A hybrid Claude/Codex workflow with model-neutral planning and task-level ownership

## Hybrid Workflow

The hybrid workflow is the recommended path going forward.

Key rules:
- Architect planning is independent from Claude/Codex execution.
- Each task is claimed by exactly one model: `claude` or `codex`.
- Claiming creates an isolated branch and worktree for that task.
- The other model must not pick a claimed task.
- Developer, reviewer, and tester for a task operate inside the same task worktree.
- Finished tasks merge back to `main` individually.
- Every work batch must append a handoff summary to `agents/ITERATION_LOG.md`.

See the full guide in `agents/HYBRID_WORKFLOW.md`.

### Task board commands

Initialize the board:

```bash
python3 agents/task_board.py init
```

Import planned tasks from PRD:

```bash
python3 agents/task_board.py init --from-prd scripts/ralph/prd.json
```

Show status:

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

Mark status:

```bash
python3 agents/task_board.py set-status US-201 --status in_progress --model codex
python3 agents/task_board.py set-status US-201 --status done --model codex
```

Merge back to `main`:

```bash
python3 agents/task_board.py merge US-201 --target main --cleanup
```

## Legacy Claude-only Workflow

The existing Claude Agent SDK pipeline is still present:

```text
PM (Orchestrator)
├── Architect Agent
├── Developer Agent
├── Reviewer Agent
└── Tester Agent
```

Main entry points:
- `python team.py "task"`
- `./agents/team.sh "task"`
- `./agents/team-parallel.sh ...`
- `./agents/orchestrator.sh "high-level requirement"`

Those scripts remain available, but they are still Claude-centric and do not enforce cross-model task locking.

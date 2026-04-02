# NeighbourGo Agent Team

Multi-agent development system using Claude Agent SDK.

## Architecture

```
PM (Orchestrator)
├── Architect Agent — designs solutions (read-only)
├── Developer Agent — writes code, runs flutter analyze
├── Tester Agent — writes + runs integration tests on simulator
└── Reviewer Agent — code review, finds bugs (read-only)
```

## Setup

```bash
cd agents
python3 -m venv .venv
source .venv/bin/activate
pip install claude-agent-sdk
export ANTHROPIC_API_KEY=your-key
```

## Usage

### Single task
```bash
python team.py "Fix the chat message ordering bug"
```

### From PRD (processes all user stories)
```bash
python team.py --prd ../scripts/ralph/prd.json
```

### Test only (run all integration tests)
```bash
python team.py --test-only
```

## Workflow

For each task, the PM orchestrates:
1. **Architect** analyzes and plans (read-only)
2. **Developer** implements the plan
3. **Reviewer** reviews for bugs and pattern violations (read-only)
4. **Developer** fixes any review issues
5. **Tester** writes and runs integration tests
6. **Developer** fixes any test failures
7. Commit when all pass

## Cost Control

- Default budget: $15 per task, $30 per PRD
- Override: `python team.py --prd prd.json 50.0`
- Agents use sonnet by default, opus for architect/reviewer

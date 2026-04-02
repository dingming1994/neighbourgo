#!/usr/bin/env python3
"""
NeighbourGo Agent Team — Multi-agent development system using Claude Agent SDK.

Architecture:
  PM (Orchestrator) → Architect → Developer → Tester → Reviewer

Usage:
  source .venv/bin/activate
  python team.py "Add search functionality to task list"
  python team.py --prd path/to/prd.json
  python team.py --test-only  # Just run tester on current code
"""

import asyncio
import json
import sys
import os
from pathlib import Path

from claude_agent_sdk import query, ClaudeAgentOptions, AgentDefinition, ResultMessage

# Project root
PROJECT_ROOT = str(Path(__file__).parent.parent)

# ─────────────────────────────────────────────────────────────────────────────
# Agent Definitions
# ─────────────────────────────────────────────────────────────────────────────

AGENTS = {
    "architect": AgentDefinition(
        description="System architect. Use for designing solutions, analyzing requirements, and planning implementation before coding. Returns a detailed implementation plan.",
        prompt=f"""You are a senior software architect for a Flutter + Firebase app called NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Analyze requirements and design the solution
- Identify which files need to be created or modified
- Define data models, API contracts, and screen flows
- Identify potential pitfalls (GoRouter wildcard routes, Freezed serialization, Firebase security rules)
- Output a clear, step-by-step implementation plan

Key project conventions:
- State management: Riverpod (StreamProvider, StateNotifierProvider)
- Routing: GoRouter with ShellRoute — static routes BEFORE wildcard routes
- Models: Freezed with json_serializable — toJson() doesn't deep-serialize nested Freezed objects
- Firebase: Firestore + Auth + Storage + Cloud Functions
- Bundle ID: sg.neighbourgo.app
- Theme: minimumSize uses Size(0, 52) NOT Size(double.infinity, 52)

You are READ-ONLY. Do NOT modify any files. Only analyze and plan.""",
        tools=["Read", "Glob", "Grep"],
        model="opus",
    ),

    "developer": AgentDefinition(
        description="Implementation specialist. Use to write code, create files, and implement features according to a plan. Can run flutter analyze to verify.",
        prompt=f"""You are a senior Flutter developer for NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Implement features according to the architect's plan
- Write clean, minimal code following existing patterns
- Run `flutter analyze` after every change to catch errors immediately
- When fixing a bug, use `grep -rn` to find ALL occurrences of the same pattern and fix them all

Critical rules:
- GoRouter: static routes (/profile/edit) MUST be defined BEFORE wildcard routes (/profile/:userId)
- Freezed: nested objects need manual .toJson() before Firestore writes
- AppButton/ElevatedButton: never use Size(double.infinity, ...) in unconstrained layouts
- Always add imports for new dependencies
- Run `cd {PROJECT_ROOT} && flutter analyze` after making changes

Do NOT run tests. The tester agent handles that.""",
        tools=["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
        model="sonnet",
    ),

    "tester": AgentDefinition(
        description="QA engineer. Use to write integration tests, run them on iOS simulator with Firebase emulators, and report all failures with details.",
        prompt=f"""You are a QA engineer for NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Write integration tests in {PROJECT_ROOT}/integration_test/
- Run tests on iOS simulator (device ID: A2E05228-F264-4F8E-842B-D2A0E261F690) with Firebase emulators
- Report every failure with: step that failed, expected vs actual, error message
- Verify fixes by re-running tests — never say "fixed" without a passing test

Test infrastructure:
- Firebase emulators: Java 21+ required, `export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"`
- Start emulators: `firebase emulators:start --project neighbourgo-sg`
- Emulator ports: Auth=9099, Firestore=8080, Storage=9199
- Test helpers: {PROJECT_ROOT}/integration_test/test_helpers.dart
- Test data: {PROJECT_ROOT}/integration_test/test_data.dart
- Run test: `flutter test integration_test/<test>.dart -d A2E05228-F264-4F8E-842B-D2A0E261F690`

Always kill emulators after testing: `pkill -f firebase`""",
        tools=["Bash", "Read", "Edit", "Write", "Glob", "Grep"],
        model="sonnet",
    ),

    "reviewer": AgentDefinition(
        description="Code reviewer. Use to review code changes for bugs, security issues, and pattern violations. READ-ONLY — does not modify files.",
        prompt=f"""You are a senior code reviewer for NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Review code changes for bugs, security issues, and pattern violations
- Check for common NeighbourGo pitfalls:
  * GoRouter wildcard routes catching static routes
  * Freezed toJson() not deep-serializing nested objects
  * Size(double.infinity, ...) in button themes/styles
  * Missing null checks on Firestore data
  * Firebase Timestamp not converted to ISO-8601 in fromFirestore()
  * Missing mounted checks after async operations
  * Routes not excluded from auth redirect
- Search for ALL occurrences of a bug pattern, not just the reported one
- Rate issues as CRITICAL / MAJOR / MINOR
- Output a structured review report

You are READ-ONLY. Do NOT modify any files.""",
        tools=["Read", "Glob", "Grep"],
        model="opus",
    ),
}


# ─────────────────────────────────────────────────────────────────────────────
# PM Orchestrator
# ─────────────────────────────────────────────────────────────────────────────

PM_SYSTEM_PROMPT = f"""You are the PM (Project Manager) orchestrating a team of agents to deliver features for NeighbourGo, a Flutter + Firebase community service app.

Project root: {PROJECT_ROOT}

Your team:
1. **architect** — Designs solutions, analyzes code, creates implementation plans (READ-ONLY)
2. **developer** — Writes code, implements features, runs flutter analyze
3. **tester** — Writes and runs integration tests on iOS simulator with Firebase emulators
4. **reviewer** — Reviews code for bugs and pattern violations (READ-ONLY)

Your workflow for each task:
1. Use **architect** to analyze the requirement and create an implementation plan
2. Use **developer** to implement the plan
3. Use **reviewer** to review the developer's changes
4. If reviewer finds issues, use **developer** to fix them
5. Use **tester** to write and run integration tests
6. If tests fail, use **developer** to fix, then **tester** to re-verify
7. Only report success when tests pass AND reviewer approves

Rules:
- NEVER skip the tester step. Every change must be verified.
- NEVER skip the reviewer step. Every change must be reviewed.
- If a step fails, fix and re-verify — don't just report the failure.
- Keep track of what was done and report a final summary.
- Use `git add` and `git commit` after all steps pass.
"""


async def run_team(task: str, max_budget: float = 15.0):
    """Run the agent team on a task."""
    print(f"\n{'='*60}")
    print(f"  NeighbourGo Agent Team")
    print(f"  Task: {task[:80]}...")
    print(f"  Budget: ${max_budget:.2f}")
    print(f"{'='*60}\n")

    result_text = ""
    total_cost = 0.0

    async for message in query(
        prompt=task,
        options=ClaudeAgentOptions(
            system_prompt=PM_SYSTEM_PROMPT,
            allowed_tools=["Agent", "Read", "Edit", "Write", "Bash", "Glob", "Grep"],
            agents=AGENTS,
            max_turns=100,
            max_budget_usd=max_budget,
            cwd=PROJECT_ROOT,
        ),
    ):
        if isinstance(message, ResultMessage):
            result_text = message.result or ""
            total_cost = getattr(message, "total_cost_usd", 0.0)
            status = getattr(message, "subtype", "unknown")
            print(f"\n{'='*60}")
            print(f"  Status: {status}")
            print(f"  Cost: ${total_cost:.4f}")
            print(f"{'='*60}")
            print(f"\n{result_text}")

    return result_text, total_cost


async def run_from_prd(prd_path: str, max_budget: float = 30.0):
    """Run the agent team on each user story from a PRD file."""
    with open(prd_path) as f:
        prd = json.load(f)

    print(f"\n  Feature: {prd['featureName']}")
    print(f"  Stories: {len(prd['userStories'])}")

    total_cost = 0.0
    for story in prd["userStories"]:
        if story.get("passes"):
            print(f"\n  Skipping {story['id']} (already passes)")
            continue

        task = f"""Implement user story {story['id']}: {story['title']}

Description: {story['description']}

Acceptance Criteria:
{chr(10).join(f'- {c}' for c in story['acceptanceCriteria'])}

Follow the full workflow: architect → developer → reviewer → tester.
Commit when all steps pass."""

        _, cost = await run_team(task, max_budget=max_budget)
        total_cost += cost

        # Mark as passed in PRD
        story["passes"] = True
        with open(prd_path, "w") as f:
            json.dump(prd, f, indent=2)

    print(f"\n{'='*60}")
    print(f"  All stories complete. Total cost: ${total_cost:.4f}")
    print(f"{'='*60}")


def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print('  python team.py "task description"')
        print("  python team.py --prd path/to/prd.json")
        print("  python team.py --test-only")
        sys.exit(1)

    # Check API key
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("Error: ANTHROPIC_API_KEY not set")
        print("  export ANTHROPIC_API_KEY=your-key")
        sys.exit(1)

    if sys.argv[1] == "--prd":
        prd_path = sys.argv[2] if len(sys.argv) > 2 else "scripts/ralph/prd.json"
        budget = float(sys.argv[3]) if len(sys.argv) > 3 else 30.0
        asyncio.run(run_from_prd(prd_path, max_budget=budget))

    elif sys.argv[1] == "--test-only":
        task = "Use the tester agent to run ALL integration tests and report results."
        asyncio.run(run_team(task, max_budget=5.0))

    else:
        task = " ".join(sys.argv[1:])
        budget = 15.0
        asyncio.run(run_team(task, max_budget=budget))


if __name__ == "__main__":
    main()

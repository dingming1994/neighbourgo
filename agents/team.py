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
# Shared lessons learned (injected into all agents)
# ─────────────────────────────────────────────────────────────────────────────

LESSONS_LEARNED = """
## Lessons Learned from 9 Sprints of Development (MUST FOLLOW)

1. **GoRouter route order**: Static routes (/profile/edit, /tasks/post) MUST be defined
   BEFORE wildcard routes (/profile/:userId, /tasks/:taskId). GoRouter matches top-to-bottom.
   EVERY TIME you add or modify routes, verify the order.

2. **Freezed toJson() does NOT deep-serialize**: Nested Freezed objects (e.g. ProviderStats
   inside UserModel) are written as Dart objects, not Maps. Before writing to Firestore,
   manually call .toJson() on nested Freezed objects:
   ```dart
   if (data['stats'] != null && data['stats'] is! Map) {
     data['stats'] = (data['stats'] as dynamic).toJson();
   }
   ```
   Search ALL repositories for the same pattern — don't fix just one.

3. **Never use Size(double.infinity, ...) in button styles**: This causes
   `BoxConstraints forces an infinite width` crash. Use Size(0, 52) instead.
   The global theme in app_theme.dart was the root cause of Edit Profile blank page.

4. **Firestore Timestamp conversion**: fromFirestore() methods must convert
   Timestamp → ISO-8601 string before passing to fromJson(). Check ALL models:
   UserModel, TaskModel, ReviewModel, ChatModel, MessageModel, BidModel.

5. **Same bug, fix everywhere**: When you find a bug, use `grep -rn "pattern" lib/`
   to find ALL occurrences and fix them all at once. Past failures:
   - ProviderStats serialization: fixed in auth_repository but missed profile_repository
   - Route conflicts: fixed /tasks/post but missed /profile/edit, /profile/gallery, /profile/verify

6. **Firebase emulator vs production differences**:
   - Emulators need Java 21+
   - firebase.json storage config: use object format, not array
   - Cloud Functions lib/ must be recompiled after src/ changes
   - Changing bundle ID requires simulator reset (xcrun simctl erase)

7. **Hot reload limitations**: These changes need FULL REBUILD, not hot reload:
   - Bundle ID, Info.plist, AppDelegate.swift (native layer)
   - pubspec.yaml dependency changes
   - Freezed generated code (.freezed.dart, .g.dart)

8. **Mock tests ≠ real tests**: 242 mock tests passed but real device had many bugs.
   Always verify with integration tests on Firebase Emulator + iOS Simulator.

9. **Rendering exceptions are NOT warnings**: `BoxConstraints forces an infinite width`
   caused entire pages to go blank. EVERY rendering exception must be fixed.

10. **currentUserProvider can be loading/null**: When navigating between screens,
    Riverpod stream providers may briefly return loading state. Use .valueOrNull
    with fallback, or direct Firestore fetch, instead of .when(loading: spinner).
"""

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
- Identify potential pitfalls based on lessons learned
- Output a clear, step-by-step implementation plan
- Flag any route ordering, serialization, or layout risks in your plan

Key project conventions:
- State management: Riverpod (StreamProvider, StateNotifierProvider)
- Routing: GoRouter with ShellRoute
- Models: Freezed with json_serializable
- Firebase: Firestore + Auth + Storage + Cloud Functions (region: asia-southeast1)
- Bundle ID: sg.neighbourgo.app
- 10 service categories defined in category_constants.dart

{LESSONS_LEARNED}

You are READ-ONLY. Do NOT modify any files. Only analyze and plan.""",
        tools=["Read", "Glob", "Grep"],
        model="claude-opus-4-6",
    ),

    "developer": AgentDefinition(
        description="Implementation specialist. Use to write code, create files, and implement features according to a plan. Runs flutter analyze to verify.",
        prompt=f"""You are a senior Flutter developer for NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Implement features according to the architect's plan
- Write clean, minimal code following existing patterns
- Run `cd {PROJECT_ROOT} && flutter analyze` after EVERY file change
- When fixing a bug, ALWAYS use `grep -rn "pattern" lib/ --include="*.dart"` to find ALL occurrences

Mandatory checklist before saying "done":
1. [ ] flutter analyze shows 0 errors
2. [ ] All new routes: static routes defined BEFORE wildcard routes in app_router.dart
3. [ ] All Firestore writes: nested Freezed objects manually serialized with .toJson()
4. [ ] No Size(double.infinity, ...) in any button style or theme
5. [ ] All fromFirestore() methods convert Timestamp to ISO-8601 string
6. [ ] All async UI code has `if (!mounted) return` guards
7. [ ] New auth routes excluded from router redirect
8. [ ] Searched for same pattern across ALL files, not just the one being edited

{LESSONS_LEARNED}

Do NOT run integration tests. The tester agent handles that.""",
        tools=["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
        model="claude-opus-4-6",
    ),

    "tester": AgentDefinition(
        description="QA engineer. Use to write integration tests, run them on iOS simulator with Firebase emulators, and report all failures with detailed diagnostics.",
        prompt=f"""You are a QA engineer for NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Write integration tests in {PROJECT_ROOT}/integration_test/
- Run tests on iOS simulator with Firebase emulators
- Report EVERY failure with: step that failed, expected vs actual, full error message
- Verify fixes by re-running tests — NEVER say "fixed" without a green test
- Check for rendering exceptions in test output — they indicate real bugs, not warnings

Test environment setup:
- Java 21+: `export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"`
- Simulator: iPhone 17 Pro Max (A2E05228-F264-4F8E-842B-D2A0E261F690)
- Start emulators: `cd {PROJECT_ROOT} && firebase emulators:start --project neighbourgo-sg &`
- Wait for ready: loop `curl -s http://localhost:9099` until response
- Run test: `cd {PROJECT_ROOT} && flutter test integration_test/<test>.dart -d A2E05228-F264-4F8E-842B-D2A0E261F690`
- Kill emulators after: `pkill -f firebase`
- Test helpers: {PROJECT_ROOT}/integration_test/test_helpers.dart
- Test data factories: {PROJECT_ROOT}/integration_test/test_data.dart

Test patterns that work:
- Suppress rendering exceptions with custom FlutterError.onError handler to isolate real failures
- Use `pumpAndSettle(Duration(milliseconds: 200), EnginePhase.sendSemanticsUpdate, Duration(seconds: 10))`
- For dropdowns: tap the dropdown, pump, then `find.text('Option').last` for overlay item
- For off-screen widgets: `tester.drag(find.byType(SingleChildScrollView), Offset(0, -300))`
- Multi-user tests: create both users in setUpAll, switch with signOut/signIn + re-pump app widget

{LESSONS_LEARNED}

CRITICAL: Rendering exceptions (BoxConstraints, RenderFlex overflow) are REAL BUGS, not ignorable warnings. Report them.""",
        tools=["Bash", "Read", "Edit", "Write", "Glob", "Grep"],
        model="claude-opus-4-6",
    ),

    "reviewer": AgentDefinition(
        description="Code reviewer. Use to review code changes for bugs, security issues, and pattern violations. READ-ONLY — does not modify files.",
        prompt=f"""You are a senior code reviewer for NeighbourGo.
Project root: {PROJECT_ROOT}

Your responsibilities:
- Review code changes for bugs, security issues, and pattern violations
- For EVERY issue found, search the ENTIRE codebase for the same pattern
- Rate issues as CRITICAL / MAJOR / MINOR
- Output a structured review report

Checklist — check EVERY item for EVERY file changed:
1. [ ] GoRouter: any new wildcard routes? Are static routes before them?
2. [ ] Freezed: any .toJson() calls that might miss nested objects?
3. [ ] Button styles: any Size(double.infinity, ...) in themes or inline styles?
4. [ ] Firestore reads: do ALL fromFirestore() methods convert Timestamps?
5. [ ] Async UI: does every async callback check `mounted` before setState/context.go?
6. [ ] Null safety: any force-unwraps (!) on nullable Firestore data?
7. [ ] Auth redirect: are new auth-flow routes excluded from the redirect?
8. [ ] Imports: are all new imports added?
9. [ ] Same bug elsewhere: `grep -rn` for the same pattern in other files?
10. [ ] Rendering: any widgets that could get infinite constraints?

{LESSONS_LEARNED}

You are READ-ONLY. Do NOT modify any files. Output a structured report:

## Review Report
### CRITICAL issues (must fix before merge)
### MAJOR issues (should fix)
### MINOR issues (nice to fix)
### Pattern search results (same bug elsewhere?)
### Verdict: APPROVE / REQUEST CHANGES""",
        tools=["Read", "Glob", "Grep"],
        model="claude-opus-4-6",
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

Your workflow for EVERY task (no exceptions):
1. Use **architect** to analyze the requirement and create an implementation plan
2. Use **developer** to implement the plan
3. Use **reviewer** to review the developer's changes
4. If reviewer says REQUEST CHANGES → use **developer** to fix, then **reviewer** again
5. Use **tester** to write and run integration tests
6. If tests fail → use **developer** to fix, then **tester** to re-verify
7. Only report success when: tests pass AND reviewer APPROVES

ABSOLUTE RULES:
- NEVER skip the tester step. Every change must have a passing test.
- NEVER skip the reviewer step. Every change must be reviewed.
- NEVER say "done" if tests failed or reviewer requested changes.
- If developer-reviewer loop exceeds 3 iterations, escalate to user.
- If tester-developer loop exceeds 3 iterations, escalate to user.
- After all steps pass, run `git add` and `git commit` with descriptive message.
- Report final summary: what was done, files changed, tests passed, issues found and fixed.

{LESSONS_LEARNED}
"""


async def run_team(task: str):
    """Run the agent team on a task."""
    print(f"\n{'='*60}")
    print(f"  NeighbourGo Agent Team")
    print(f"  Task: {task[:80]}...")
    print(f"  Model: Claude Opus 4.6 (1M context)")
    print(f"  Budget: unlimited")
    print(f"{'='*60}\n")

    result_text = ""
    total_cost = 0.0

    async for message in query(
        prompt=task,
        options=ClaudeAgentOptions(
            system_prompt=PM_SYSTEM_PROMPT,
            allowed_tools=["Agent", "Read", "Edit", "Write", "Bash", "Glob", "Grep"],
            agents=AGENTS,
            max_turns=200,
            model="claude-opus-4-6",
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


async def run_from_prd(prd_path: str):
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

        _, cost = await run_team(task)
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
        asyncio.run(run_from_prd(prd_path))

    elif sys.argv[1] == "--test-only":
        task = "Use the tester agent to run ALL integration tests and report results."
        asyncio.run(run_team(task))

    else:
        task = " ".join(sys.argv[1:])
        asyncio.run(run_team(task))


if __name__ == "__main__":
    main()

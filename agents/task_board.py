#!/usr/bin/env python3
"""
Hybrid task board for architect-led planning and task-level Claude/Codex ownership.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = ROOT / "agents"
BOARD_PATH = AGENTS_DIR / "task-board.json"
DEFAULT_WORKTREE_ROOT = ROOT / ".worktrees"
VALID_MODELS = {"claude", "codex"}
VALID_STATUSES = {
    "planned",
    "claimed",
    "in_progress",
    "in_review",
    "in_test",
    "blocked",
    "done",
    "merged",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "task"


def run_git(args: list[str], cwd: Path = ROOT) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def default_board() -> dict[str, Any]:
    return {
        "version": 1,
        "updatedAt": utc_now(),
        "notes": [
            "Architect is model-neutral and plans work without claiming tasks.",
            "Each task can be claimed by only one model: claude or codex.",
            "Claiming a task creates an isolated branch and worktree.",
            "The other model must not pick a claimed task.",
        ],
        "tasks": [],
    }


def load_board() -> dict[str, Any]:
    if not BOARD_PATH.exists():
        return default_board()
    with BOARD_PATH.open() as f:
        return json.load(f)


def save_board(board: dict[str, Any]) -> None:
    board["updatedAt"] = utc_now()
    with BOARD_PATH.open("w") as f:
        json.dump(board, f, indent=2)
        f.write("\n")


def ensure_board() -> dict[str, Any]:
    board = load_board()
    board.setdefault("tasks", [])
    return board


def find_task(board: dict[str, Any], task_id: str) -> dict[str, Any]:
    for task in board["tasks"]:
        if task["id"] == task_id:
            return task
    raise SystemExit(f"Task not found: {task_id}")


def print_task(task: dict[str, Any]) -> None:
    owner = task.get("ownerModel") or "-"
    branch = task.get("branch") or "-"
    print(
        f'{task["id"]:12}  {task["status"]:12}  {owner:7}  '
        f'{branch:30}  {task["title"]}'
    )


def cmd_init(args: argparse.Namespace) -> None:
    board = default_board()
    if args.from_prd:
        with open(args.from_prd) as f:
            prd = json.load(f)
        for story in prd.get("userStories", []):
            board["tasks"].append(
                {
                    "id": story["id"],
                    "title": story["title"],
                    "description": story.get("description", ""),
                    "acceptanceCriteria": story.get("acceptanceCriteria", []),
                    "dependsOn": story.get("dependsOn", []),
                    "source": {"type": "prd", "path": str(args.from_prd)},
                    "status": "merged" if story.get("passes") else "planned",
                    "ownerModel": None,
                    "branch": None,
                    "worktree": None,
                    "claimedAt": None,
                    "mergedAt": utc_now() if story.get("passes") else None,
                    "notes": [],
                }
            )
    save_board(board)
    print(f"Initialized {BOARD_PATH}")


def cmd_add(args: argparse.Namespace) -> None:
    board = ensure_board()
    if any(t["id"] == args.id for t in board["tasks"]):
        raise SystemExit(f"Task already exists: {args.id}")
    board["tasks"].append(
        {
            "id": args.id,
            "title": args.title,
            "description": args.description or "",
            "acceptanceCriteria": args.acceptance or [],
            "dependsOn": args.depends_on or [],
            "source": {"type": "manual"},
            "status": "planned",
            "ownerModel": None,
            "branch": None,
            "worktree": None,
            "claimedAt": None,
            "mergedAt": None,
            "notes": [],
        }
    )
    save_board(board)
    print(f"Added task {args.id}")


def cmd_status(args: argparse.Namespace) -> None:
    board = ensure_board()
    tasks = board["tasks"]
    if args.model:
        tasks = [t for t in tasks if t.get("ownerModel") == args.model]
    if args.status:
        tasks = [t for t in tasks if t.get("status") == args.status]
    print("TASK ID       STATUS        MODEL    BRANCH                          TITLE")
    print("-" * 100)
    for task in tasks:
        print_task(task)


def cmd_claim(args: argparse.Namespace) -> None:
    board = ensure_board()
    task = find_task(board, args.task_id)

    if task["status"] not in {"planned", "blocked"}:
        raise SystemExit(
            f'Task {args.task_id} cannot be claimed from status "{task["status"]}"'
        )
    if task.get("ownerModel") and task["ownerModel"] != args.model:
        raise SystemExit(f'Task {args.task_id} is already locked to {task["ownerModel"]}')

    branch = args.branch or f"agents/{args.model}/{slugify(args.task_id)}"
    worktree_root = Path(args.worktree_root).resolve()
    worktree_root.mkdir(parents=True, exist_ok=True)
    worktree = worktree_root / f"{slugify(args.task_id)}-{args.model}"

    if worktree.exists():
        raise SystemExit(f"Worktree already exists: {worktree}")

    branch_exists = False
    result = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
        cwd=ROOT,
    )
    branch_exists = result.returncode == 0

    if branch_exists:
        run_git(["worktree", "add", str(worktree), branch])
    else:
        run_git(["worktree", "add", "-b", branch, str(worktree), args.base])

    task["status"] = "claimed"
    task["ownerModel"] = args.model
    task["branch"] = branch
    task["worktree"] = str(worktree)
    task["claimedAt"] = utc_now()
    task["notes"].append(
        f"Claimed by {args.model} from base {args.base} at {task['claimedAt']}"
    )
    save_board(board)

    print(f"Claimed {args.task_id}")
    print(f"  model:    {args.model}")
    print(f"  branch:   {branch}")
    print(f"  worktree: {worktree}")


def cmd_set_status(args: argparse.Namespace) -> None:
    board = ensure_board()
    task = find_task(board, args.task_id)
    if args.model and task.get("ownerModel") not in {None, args.model}:
        raise SystemExit(
            f'Task {args.task_id} is owned by {task.get("ownerModel")}, not {args.model}'
        )
    task["status"] = args.status
    if args.note:
        task["notes"].append(f"{utc_now()} {args.note}")
    save_board(board)
    print(f'Set {args.task_id} -> {args.status}')


def cmd_merge(args: argparse.Namespace) -> None:
    board = ensure_board()
    task = find_task(board, args.task_id)
    branch = task.get("branch")
    worktree = task.get("worktree")
    if not branch:
        raise SystemExit(f"Task {args.task_id} has no branch to merge")

    run_git(["checkout", args.target])
    run_git(
        [
            "merge",
            branch,
            "--no-ff",
            "-m",
            f"Merge {task['id']} from {task['ownerModel']} ({branch})",
        ]
    )

    task["status"] = "merged"
    task["mergedAt"] = utc_now()
    task["notes"].append(f"Merged into {args.target} at {task['mergedAt']}")
    save_board(board)

    print(f"Merged {branch} -> {args.target}")

    if args.cleanup:
        if worktree:
            try:
                run_git(["worktree", "remove", "--force", worktree])
            except subprocess.CalledProcessError:
                pass
        try:
            run_git(["branch", "-D", branch])
        except subprocess.CalledProcessError:
            pass
        task["notes"].append("Cleaned up worktree/branch after merge")
        save_board(board)
        print("Cleaned up worktree and branch")


def cmd_release(args: argparse.Namespace) -> None:
    board = ensure_board()
    task = find_task(board, args.task_id)
    if task["status"] == "merged":
        raise SystemExit("Cannot release a merged task")
    task["status"] = "planned"
    task["ownerModel"] = None
    task["branch"] = None
    task["worktree"] = None
    task["claimedAt"] = None
    if args.note:
        task["notes"].append(f"{utc_now()} released: {args.note}")
    save_board(board)
    print(f"Released {args.task_id} back to planned")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Hybrid Claude/Codex task board with task-level ownership"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init", help="Initialize task board")
    p_init.add_argument("--from-prd", type=Path, help="Import tasks from PRD JSON")
    p_init.set_defaults(func=cmd_init)

    p_add = sub.add_parser("add", help="Add a planned task")
    p_add.add_argument("--id", required=True)
    p_add.add_argument("--title", required=True)
    p_add.add_argument("--description")
    p_add.add_argument("--acceptance", action="append")
    p_add.add_argument("--depends-on", action="append")
    p_add.set_defaults(func=cmd_add)

    p_status = sub.add_parser("status", help="Show board status")
    p_status.add_argument("--model", choices=sorted(VALID_MODELS))
    p_status.add_argument("--status", choices=sorted(VALID_STATUSES))
    p_status.set_defaults(func=cmd_status)

    p_claim = sub.add_parser("claim", help="Claim a task for one model")
    p_claim.add_argument("task_id")
    p_claim.add_argument("--model", required=True, choices=sorted(VALID_MODELS))
    p_claim.add_argument("--base", default="main")
    p_claim.add_argument("--branch")
    p_claim.add_argument("--worktree-root", default=str(DEFAULT_WORKTREE_ROOT))
    p_claim.set_defaults(func=cmd_claim)

    p_set = sub.add_parser("set-status", help="Update task status")
    p_set.add_argument("task_id")
    p_set.add_argument("--status", required=True, choices=sorted(VALID_STATUSES))
    p_set.add_argument("--model", choices=sorted(VALID_MODELS))
    p_set.add_argument("--note")
    p_set.set_defaults(func=cmd_set_status)

    p_merge = sub.add_parser("merge", help="Merge a task branch back to target")
    p_merge.add_argument("task_id")
    p_merge.add_argument("--target", default="main")
    p_merge.add_argument("--cleanup", action="store_true")
    p_merge.set_defaults(func=cmd_merge)

    p_release = sub.add_parser("release", help="Release a claimed task")
    p_release.add_argument("task_id")
    p_release.add_argument("--note")
    p_release.set_defaults(func=cmd_release)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

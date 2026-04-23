---
name: pie-cli
description: Use for tasks involving the Python pie CLI, including project scaffolding, web/page/card commands, remote component sync, and login/config troubleshooting.
metadata:
  author: pie-team
  version: 1.0.0
---

# Pie CLI Skill

Use this skill when the user asks to run, debug, or automate the `pie` CLI.

## Scope

- `pie create`
- `pie web ...`, `verify`, `build`
- `pie page add|view`
- `pie card add|list|view|list-events|push|pull|remote list|remote pull`
- `pie login`

## Card types

The `pie card add` command accepts four types:

| Type | Description |
|---|---|
| `simple` | Basic card with a single data prop |
| `complex` | Card with data + children props |
| `container` | Container card with a single content slot |
| `complex-container` | Container with an array content slot (most powerful) |

Use `--io` to add socket IO support, `--ajax` to add AJAX support. Both flags are optional and combinable.

## Defaults

- Prefer running in the target project root.
- Use `uv run pie ...` for local repo usage.
- Keep edits minimal and do not overwrite existing card/page files unless requested.

## Prerequisites Checklist

1. Python `>=3.14`.
2. Dependencies installed with `uv sync`.
3. `.env` loaded when storage or auth is involved.

Required env for remote/storage flows:

- `PIE_USER_ID`
- `PIE_PROJECT` or `PIE_PROJECT_SLUG`
- `PIE_API_KEY`

## Workflow

1. Confirm goal: scaffold, inspect, sync, or auth.
2. Run the narrowest command that answers the request.
3. If command fails, print exact error and check env/config.
4. For remote sync, validate user/project context before mutating.
5. Summarize outputs and next action.

## Safety Rules

- `pie card add-event` is currently not implemented for Python source editing; do not promise automatic implementation.
- For `card push`/`pull`, validate target names and paths before writes.
- For `page add`, ensure `web.py` registration remains valid.

## References

Read command details in:

- `references/command-cheatsheet.md`

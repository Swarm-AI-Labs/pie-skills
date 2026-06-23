---
name: pie-cli
description: Python pie CLI — scaffold projects, manage cards and pages, sync with remote storage.
metadata:
  author: pie-team
  version: 1.0.0
---

# Pie CLI Skill

Use this skill when the user asks to run, debug, or automate the `pie` CLI.

## Scope

- `pie create`, `pie init`, `pie self-upgrade`
- `pie web <module:attr> [verify|build]`
- `pie page add|view|ajax`
- `pie card add|list|view|list-events|add-event|dump-metadata|check-sync`
- `pie card channels|emit` (Centrifuge; backend-only)
- `pie card pull` and `pie card remote list|push|pull|history|public|private|remove`
- `pie card show` — preview one card in the frontend registry harness
- `pie card show-mcp` — headless MCP render server (JSON/HTML/screenshot + ajax)
- `pie db …` — Beanie/MongoDB layer (Documents, indexes, seeds, bridges, migrations) — see `references/db-cheatsheet.md`
- `pie cloudflare init|dev|deploy` — Cloudflare Python Worker
- `pie taskrun local|remote …` — run a generated page task
- `pie login`

**Backend-only — no `pieui` mirror:** `db`, `cloudflare`, `card channels`, `card emit`. Never suggest a `pieui db` / `pieui cloudflare` equivalent.

## Card types

The `pie card add` command accepts four types:

| Type | Description |
|---|---|
| `simple` | Basic card with a single data prop |
| `complex` | Card with data + children props |
| `container` | Container card with a single content slot |
| `complex-container` | Container with an array content slot (most powerful) |

Use `--io` to add socket IO support, `--ajax` to add AJAX support, and `--input` for the typed `stored` (input) variant. Flags are optional and combinable. `--from <ref>` ports a card from frontend piecomponents / a PieMetadata `.json` / a `.py` file / a card name.

**Naming divergence:** pie's `container` type is called `simple-container` in the frontend `pieui` CLI.

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

## Previewing / rendering a card

Render a single card in isolation through the frontend's **registry-dev harness** (a standalone `PiePreviewRoot` Next app under `<frontend>/.pie/registry/`). The backend serves the card envelope at `/api/content/`; the harness fetches and renders it.

- `pie card show EXPR` — serve one card from an ephemeral backend and open it in the harness. `EXPR` is a Python expression evaluating to a `Card`; the eval namespace includes every `Card` subclass in `pages/components/*.py`. Flags: `--frontend-dir`, `--frontend-port` (default `3000`), `--backend-port` (auto), `--route` (default `/`), `--pm`, `--no-open`. Blocks until Ctrl+C.
- `pie card show-mcp` — a FastMCP server that renders cards headlessly for agents. Requires `pip install 'pieui[mcp]'` (adds `mcp` + `playwright`). Flags: `--http PORT` (default stdio), `--frontend-dir`, `--frontend-port` (default `3000`), `--mirror URL`, `--no-frontend`. Tools: `render_card(card?, format=json|html|screenshot)`, `attach(base_url)`, `detach()`, `list_ajax()`, `call_ajax(pathname, data?)`. For `render_card`, prefer a **card expression** over a `{…}` JSON string (the latter is often coerced to a dict and rejected); `format=json` echoes content, `html`/`screenshot` need the harness + linked frontend (`pie init`).

Both depend on `frontendProjectDir` in `.pie/config.json` (or `--frontend-dir`). See the complete guide's section 10 for the full architecture, side-panel recipe, and troubleshooting (e.g. clear `<frontend>/.pie/registry/.next` if a stale CSS/build error persists).

## Safety Rules

- `pie card add-event` is currently not implemented for Python source editing; do not promise automatic implementation.
- For `card push`/`pull`, validate target names and paths before writes.
- For `page add`, ensure `web.py` registration remains valid.
- `card show` / `card show-mcp` spawn a frontend `next dev`; if the user runs their own dev server on that port, confirm before replacing it.
- `pie db model remove|rename`, `pie db migrate|rollback`, and `card remote remove|public|private` mutate code/data/visibility — confirm explicit intent before running.

## References

Read command details in:

- `references/command-cheatsheet.md` — all command groups
- `references/db-cheatsheet.md` — the full `pie db …` (Beanie/MongoDB) surface

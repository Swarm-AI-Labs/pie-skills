---
name: pie-cli
description: Use this skill whenever working with a Pie project — creating cards, pages, and AJAX handlers, porting components from a TypeScript frontend, publishing to remote storage, checking backend/frontend contract sync, or dumping component metadata. Triggers on any mention of "pie", "PieCard", "pie card", "pie page", or requests to scaffold/port/publish/sync a card from the Python side. Use even if the user just asks how to add a component or page in a pie project.
metadata:
  author: pie-team
  version: 2.0.0
---

# Pie CLI Skill

Pie uses a CLI-driven workflow. The CLI enforces structural conventions — files it generates cannot be replicated correctly by hand. **Never create component directories, page files, or event handlers manually.** The only exception is business logic inside method bodies.

## Strict rules

- **New component** → `pie card add [type] <Name>` only. Never create `components/my_card.py` by hand.
- **New page** → `pie page add <path>` only. Never create `pages/my_page.py` by hand.
- **New AJAX handler on a page** → `pie page ajax <path> add <handler>` only.
- Direct edits are allowed only inside generated method bodies.

---

## Commands

### Project setup

**`pie create <AppName>`**
Creates a new Pie project with `pages/`, `components/`, `web.py`.

**`pie init [--out-dir <dir>]`**
Initialises `pages/`, `components/`, `web.py`. Prompts for frontend dirs. Safe to re-run.

**`pie login`** — Signs in, saves credentials to `.pie/config.json`.

**`pie self-upgrade [--pm uv|poetry|pip]`**
Auto-detects package manager (uv tool → pip). `--pm` overrides.

**`pie web`** — Run or lint a web application.

---

### Card management

**`pie card add [type] <Name> [--io] [--ajax] [--from <ref>]`**

Types: `simple` · `complex` · `container` · `complex-container` (default).

| Flag | Effect |
|------|--------|
| `--io` | Adds realtime IO fields |
| `--ajax` | Adds AJAX request fields |
| `--from <ref>` | Port from TypeScript frontend |

`--from` accepts: `.ts`/`.tsx` file path · `piecomponents/` directory · `.json` dump-metadata file · card name (resolves via `frontendComponentsDir`). Auto-resolves if `frontendComponentsDir` is configured and matching component exists.

**`pie card list [filter]`** — Filters: `all` · `complex` · `complex-container` · `container` · `simple`.

**`pie card pull <ref>`**
- `Name` / `project/Name` / `r/user/Name` → PieUI storage
- (same routing as pieui — resolves to storage by name)

**`pie card view <Name>`** — Prints props, ajax fields, IO fields, events.

**`pie card list-events <Name>`** — Lists `get_supported_events()` entries (static parse).

**`pie card add-event <Name> <event>`** — Adds an IO event stub.
> Note: not yet implemented for Python source editing — scaffolds the event stub only.

**`pie card dump-metadata <Name> [--out file.json]`**
Emits `{"python": {...}}` envelope to stdout or file. On existing file, shallow-merges — only replaces `python` key, preserves `typescript` sibling.

**`pie card check-sync <Name>`**
Delegates to `pieui card check-sync` in configured frontend project. Prompts for `frontendProjectDir` if absent, saves to `.pie/config.json`.
Env: `PIE_CHECK_SYNC_NODE`, `PIE_CHECK_SYNC_NODEPATH`.

### Card remote storage

Requires prior `pie login`.

| Command | Action |
|---------|--------|
| `card remote push <Name>` | Upload to storage |
| `card remote pull <Name>[@rev]` | Download from storage |
| `card remote list [--user U] [--project S]` | List remote cards |
| `card remote remove <Name>` | Delete from storage |
| `card remote history <Name> [--page N] [--per-page N]` | Revision history |
| `card remote public <Name>` | Make readable as `r/<user>/<Name>` |
| `card remote private <Name>` | Revoke public access |

### Page management

**`pie page add <path>`** — Creates `pages/<path>.py`.
**`pie page view <path>`** — Prints page source.
**`pie page ajax <path> <add|remove> <handler>`** — Adds/removes AJAX handler method in page class.

---

## Envelope format policy

`dump-metadata` wraps output: `{"python": {...}}`. Python code only reads `python` key — never `typescript`.

Combined file (pie + pieui writing to the same `--out`):
```json
{ "python": {...}, "typescript": {...} }
```
Each side shallow-merges its own key without touching the other.

---

## Environment variables

Required for remote/storage flows:
- `PIE_USER_ID`
- `PIE_PROJECT` or `PIE_PROJECT_SLUG`
- `PIE_API_KEY`

Optional:
- `PIEUI_CHECK_SYNC_PYTHON` — override Python binary used by pieui's check-sync
- `PIE_CHECK_SYNC_NODE` / `PIE_CHECK_SYNC_NODEPATH` — override Node.js used by pie's check-sync

---

## Workflow recipes

### New page with AJAX handler
```bash
pie page add dashboard
pie page ajax dashboard add refresh_data
# Edit business logic in pages/dashboard.py
```

### Input card with events
```bash
pie card add container InputCard --ajax
pie card add-event InputCard submit
pie card add-event InputCard reset
# Add handler logic in components/input_card.py
```

### Port from TypeScript frontend
```bash
pie card add MyCard --from ../pieui/piecomponents/MyCard
# or auto-resolve if frontendComponentsDir is configured:
pie card add MyCard
```

### Verify contract with frontend + publish
```bash
pie card dump-metadata MyCard --out /tmp/meta.json
pieui card dump-metadata MyCard --out /tmp/meta.json   # adds typescript envelope
pie card check-sync MyCard
pie card remote push MyCard
pie card remote public MyCard
```

### Install community card
```bash
pie card pull r/alice/HeroCard
```

---

## Symmetry with pieui CLI

Pie and pieui CLIs are symmetric — same subcommand structure, same positional args, same flags. Key differences:

| Aspect | pie (Python/backend) | pieui (TypeScript/frontend) |
|--------|---------------------|----------------------------|
| Envelope key | `python` | `typescript` |
| Card directory | `components/` | `piecomponents/` |
| `--from` direction | from frontend `.ts`/`.tsx` | from backend `.py` |
| `add-event` impl | stub only (not yet auto-wired) | fully scaffolded |
| `self-upgrade --pm` | `uv` · `poetry` · `pip` | `bun` · `npm` · `pnpm` · `yarn` |

Always run `pie card check-sync <Name>` after porting or updating either side to verify the frontend/backend contract.

---

## IntrospectionError cases

| Situation | Error |
|-----------|-------|
| No matching data class for card | `no data type found` |
| `--out` file is not a JSON object | `Cannot merge` |
| JSON missing `python` key | `missing the "python" envelope (top-level keys: ...)` |

**Naming convention**: data class must be `<Name>Data`, `<Name>Props`, or follow the configured naming pattern.

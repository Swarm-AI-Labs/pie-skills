---
name: pieui-cli
description: Use this skill whenever working with a PieUI project — creating components, pages, and AJAX handlers, porting cards from a Python backend, publishing to remote storage, checking frontend/backend contract sync, or dumping component metadata. Triggers on any mention of "pieui", "PieCard", "piecomponents", "pie card", "pie page", or requests to scaffold/port/publish/sync a card. Use even if the user just asks how to add a component or page in a pieui project.
metadata:
  author: pie-team
  version: 2.0.0
---

# pieui CLI Skill

PieUI uses a CLI-driven workflow. The CLI enforces structural conventions — files it generates cannot be replicated correctly by hand. **Never create component directories, page files, or event handlers manually.** The only exception is business logic inside method bodies and render functions.

## Strict rules

- **New component** → `pieui card add [type] <Name>` only. Never `mkdir piecomponents/Foo && touch index.ts`.
- **New page** → `pieui page add <path>` only. Never `touch app/dashboard/page.tsx`.
- **New AJAX handler on a page** → `pieui page ajax <path> add <handler>` only.
- **New event/method on a card** → `pieui card add-event <Name> <event>` only.
- Direct edits are allowed only inside generated method bodies and the component's render function.

---

## Commands

### Project setup

**`pieui create <AppName>`**
Creates a Next.js app, runs `pieui init`, installs `@swarm.ing/pieui`, wires Storybook.
Env overrides: `PIEUI_CREATE_PACKAGE_SPEC`, `PIEUI_CREATE_NEXT_APP_SPEC`, `PIEUI_CREATE_BUN_BIN`, `PIEUI_CREATE_SKIP_STORYBOOK=1`.

**`pieui init [--out-dir <dir>]`**
Initialises `piecomponents/`, `registry.ts`, Tailwind, `next.config`. Prompts for backend dirs. Safe to re-run.

**`pieui login`** — Signs in, saves credentials to `.pie/config.json`.

**`pieui self-upgrade [--pm bun|npm|pnpm|yarn]`**
Auto-detects package manager (bun → pnpm → yarn → npm).

**`pieui postbuild [--out-dir] [--src-dir] [--append]`**
Scans for `registerPieComponent` calls, writes component manifest. Add to CI after `tsc`.

---

### Card management

**`pieui card add [type] <Name> [--io] [--ajax] [--from <ref>]`**

Types: `simple` · `complex` · `simple-container` · `complex-container` (default).

| Flag | Effect |
|------|--------|
| `--io` | Adds realtime fields to data interface |
| `--ajax` | Adds AJAX request fields |
| `--from <ref>` | Port from Python backend |

`--from` accepts: `.py` file path · `.json` dump-metadata file · card name (resolves via `backendComponentsDir`). Auto-resolves if `backendComponentsDir` is configured and matching `.py` exists.

**`pieui card list [filter]`** — Filters: `all` · `simple` · `complex` · `simple-container` · `complex-container`.

**`pieui card pull <ref>`**
- `Name` / `project/Name` / `r/user/Name` → PieUI storage
- `./file.json` or `/abs/path.json` → local dump-metadata JSON
- `https://...` → HTTP fetch of dump-metadata JSON

**`pieui card view <Name>`** — Prints props, ajax fields, IO fields, events.

**`pieui card remove <Name>`** — Removes dir + deregisters from `registry.ts`.

**`pieui card list-events <Name>`** — Lists method keys registered in `<PieCard methods={...} />`.

**`pieui card add-event <Name> <event>`** — Appends a new handler stub to `<PieCard methods={{...}}>`.

**`pieui card add-story <Name>`** — Generates Storybook `stories.tsx` wired to PieCard methods.

**`pieui card dump-metadata <Name> [--out file.json]`**
Emits `{"typescript": {...}}` envelope to stdout or file. On existing file, shallow-merges — only replaces `typescript` key, preserves `python` sibling.

**`pieui card check-sync <Name>`**
Delegates to `pie card check-sync` in configured backend project. Prompts for `backendProjectDir` if absent, saves to `.pie/config.json`.
Env: `PIEUI_CHECK_SYNC_PYTHON`, `PIEUI_CHECK_SYNC_PYTHONPATH`.

### Card remote storage

Requires prior `pieui login`.

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

**`pieui page add <path>`** — Creates `app/<path>/page.tsx`.
**`pieui page view <path>`** — Prints page source.
**`pieui page ajax <path> <add|remove> <handler>`** — Adds/removes AJAX handler block.

---

## Envelope format policy

`dump-metadata` wraps output: `{"typescript": {...}}`. TS code only reads `typescript` key — never `python`.

Combined file (pie + pieui writing to the same `--out`):
```json
{ "python": {...}, "typescript": {...} }
```
Each side shallow-merges its own key without touching the other.

---

## Workflow recipes

### New page with AJAX handler
```bash
pieui page add dashboard
pieui page ajax dashboard add refresh_data
# Edit business logic in app/dashboard/page.tsx
```

### Input-card with events
```bash
pieui card add simple-container InputCard --ajax
pieui card add-event InputCard submit
pieui card add-event InputCard reset
# Add stored={...} prop in the JSX for persistence
```

### Port from Python backend
```bash
pieui card add MyCard --from ../pie/components/my_card.py
# or auto-resolve if backendComponentsDir is configured:
pieui card add MyCard
```

### Verify contract with backend + publish
```bash
pieui card dump-metadata MyCard --out /tmp/meta.json
pie card dump-metadata MyCard --out /tmp/meta.json   # adds python envelope
pieui card check-sync MyCard
pieui card remote push MyCard
pieui card remote public MyCard
```

### Install community card
```bash
pieui card pull r/alice/HeroCard
pieui card pull https://example.com/HeroCard.json
```

---

## IntrospectionError cases

| Situation | Error |
|-----------|-------|
| No `<Name>Data` / `I<Name>Data` / `<Name>Props` type | `no data type found` |
| `methods={variable}` or `methods={fn()}` | `must be an inline object literal` |
| `<PieCard {...spread}/>` | `spread is not supported` |
| `--out` file is not a JSON object | `Cannot merge` |
| JSON missing `typescript` key | `missing the "typescript" envelope (top-level keys: ...)` |

**Naming convention**: data type must be `<Name>Data`, `I<Name>Data`, or `<Name>Props`.
**Methods must be inline**: `<PieCard methods={{ click: (p) => ... }} />` — external variable references throw.

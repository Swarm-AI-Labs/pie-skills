---
name: pie-pieui-complete
description: Full reference for building projects with the PIE framework using both pie (Python backend) and pieui (TypeScript/Next.js frontend) CLIs. Covers scaffolding, remote sync, envelope policy, workflow recipes, check-sync interpretation, previewing & rendering cards (pie card show, pieui registry harness, pie card show-mcp), and common edge cases.
metadata:
  author: J4h5u5
  version: 1.1.0
---

# PIE + pieUI — Complete Agent Skill Guide

Full reference for AI agents and developers building projects with the PIE framework.
Covers both CLIs, all commands, workflow recipes, envelope policy, and edge cases.

---

## Table of Contents

1. [Architecture](#1-architecture)
2. [Hard Rules — Never Do Manually](#2-hard-rules--never-do-manually)
3. [pieui CLI — All Commands](#3-pieui-cli--all-commands)
4. [pie CLI — All Commands](#4-pie-cli--all-commands)
5. [Envelope Policy](#5-envelope-policy)
6. [Workflow Recipes](#6-workflow-recipes)
7. [Edge Cases](#7-edge-cases)
8. [Project Setup & .gitignore](#8-project-setup--gitignore)
9. [check-sync Findings Guide](#9-check-sync-findings-guide)
10. [Previewing & Rendering Cards](#10-previewing--rendering-cards)

---

## 1. Architecture

PIE is a fullstack framework. Frontend and backend are **strictly separated**, each with its own CLI.

```
┌─────────────────────────────────────────────┐
│              Platform (pieui.swarm.ing)       │
│  username/my-project/MyCard                  │
│   ├── python/  ← pushed by pie CLI           │
│   └── typescript/  ← pushed by pieui CLI     │
└─────────────────────────────────────────────┘
         ↑ push/pull          ↑ push/pull
┌────────────────┐   ┌────────────────────────┐
│  Backend        │   │  Frontend               │
│  Python/FastAPI │   │  TypeScript/Next.js     │
│  pie CLI        │   │  pieui CLI              │
│  pages/         │   │  piecomponents/         │
│  components/    │   │  app/                   │
└────────────────┘   └────────────────────────┘
```

| Layer | Language | CLI | Key directories |
|---|---|---|---|
| Frontend | TypeScript / Next.js | `pieui` | `piecomponents/`, `app/` |
| Backend | Python / FastAPI | `pie` | `pages/`, `pages/components/` |

CLI invocation:
- `node /path/to/pieui/dist/cli.js <cmd>`
- `/path/to/pie/.venv/bin/pie <cmd>`

---

## 2. Hard Rules — Never Do Manually

These actions **must** go through the CLI. Doing them manually breaks the registry or platform metadata.

| ❌ Never manually | ✅ Use instead |
|---|---|
| Create a file in `piecomponents/` | `pieui card add ...` |
| Create `app/<path>/page.tsx` | `pieui page add <path>` |
| Edit `piecomponents/registry.ts` | Updated automatically by any `pieui card add/remove` |
| Create `pages/components/*.py` | `pie card add ...` |
| Create `pages/*.py` | `pie page add ...` |
| Add a methods/event key to `<PieCard methods={...}>` | `pieui add-event <Card> <event>` |
| Add an IO event to a Python card | `pie card add-event <Card> <event>` |
| Delete a piecomponent directory | `pieui remove <ComponentName>` |

**Other hard rules:**

- `"use client"` — required at the top of **every** PIE card TSX file.
- `<button type="button">` — always set; without it the browser submits to `/api/process/`.
- `is_typed=False` — required in every `AsyncPage` subclass that does not override `get_content`.
- Python `snake_case` → camelCase on frontend. `send_label` becomes `sendLabel`. Match in both TS types and component code.
- After editing `web.py` (adding a new route) — **restart the backend process**.
- Never commit `.env`, `.pie/`, `.claude/`, `node_modules/`, `.next/`, `__pycache__/`, `.venv/`.

---

## 3. pieui CLI — All Commands

### 3.1 Auth

```bash
pieui login
```

Opens a browser URL for OAuth. On success writes `{ user_id, api_key, project }` to `.pie/config.json` and appends vars to `.env`.

**When:** Before any `card remote` operation or on first project setup.
**Note:** Run from the project root so config is saved to the correct `.pie/config.json`.

---

### 3.2 Init

```bash
pieui init [--out-dir <dir>]
```

Creates `piecomponents/registry.ts`. Required once per new frontend project.

| Flag | Default | Description |
|---|---|---|
| `--out-dir`, `-o` | `.` | Base directory for piecomponents |

```bash
pieui init
pieui init --out-dir packages/app   # monorepo sub-package
```

---

### 3.3 Create project

```bash
pieui create <AppName>          # scaffold Next.js app + run pieui init
pieui create-pie-app <AppName>  # blank Next.js template only
pieui create-pieui <AppName>    # alias for create-pie-app
```

**When:** Starting a new frontend project from scratch.

---

### 3.4 `page add`

```bash
pieui page add <path>
```

Generates `app/<path>/page.tsx` with the standard PIE Suspense wrapper.

```bash
pieui page add dashboard
pieui page add wallet/send
pieui page add chat/room
```

**When:** Every new route. One command per page. No flags.

---

### 3.5 `card add`

```bash
pieui card add [type] <ComponentName> [--io] [--ajax]
```

Scaffolds `piecomponents/<ComponentName>/` with `index.ts`, `types/index.ts`, `ui/<ComponentName>.tsx`.
Updates `piecomponents/registry.ts` automatically.

**Types:**

| Type | Props signature | Use when |
|---|---|---|
| `simple` | `{ data }` | Card displays data, no children |
| `complex` | `{ data, children }` | Card wraps other components |
| `simple-container` | `{ data, content }` | Card has a single content slot |
| `complex-container` | `{ data, content[] }` | Card has array content slots **(default)** |

**Flags:**

| Flag | What it adds |
|---|---|
| `--ajax` | `pathname`, `depsNames`, `kwargs` fields to the data interface |
| `--io` | Realtime / websocket support fields |

```bash
pieui card add simple ProfileCard
pieui card add complex-container LayoutCard
pieui card add simple LiveTickerCard --io
pieui card add simple ContactFormCard --ajax
pieui card add simple ChatCard --io --ajax
```

---

### 3.6 `card remove`

```bash
pieui remove <ComponentName>
```

Deletes `piecomponents/<ComponentName>/` and removes the entry from `registry.ts`.

**When:** Removing a component. Never delete manually.

---

### 3.7 `list`

```bash
pieui list [filter] [--src-dir <dir>]
```

Prints a table of all registered components: Name, Type, Data Type, Lazy, File.

| Filter | Shows |
|---|---|
| *(none)* | All |
| `simple` | Simple only |
| `complex` | Complex only |
| `simple-container` | Simple containers |
| `complex-container` | Complex containers |

```bash
pieui list
pieui list simple
pieui list complex-container --src-dir app
```

---

### 3.8 `list-events`

```bash
pieui list-events <ComponentName> [--src-dir <dir>]
```

Prints all `methods` keys declared in `<PieCard card="X" methods={...} />` for the component.

**When:** Before adding a new event (to avoid duplicates); auditing a card's event surface.

---

### 3.9 `add-event`

```bash
pieui add-event <ComponentName> <event> [--src-dir <dir>]
```

Adds a new key with a default handler to `<PieCard ... methods={{ <event>: handler }}>` in the TSX.

```bash
pieui add-event ContactFormCard submit
pieui add-event ChatCard message
```

**When:** Adding event handlers to an existing card. Always use this — never edit `methods` manually.

---

### 3.10 `postbuild`

```bash
pieui postbuild [--out-dir <dir>] [--src-dir <dir>] [--append]
```

Scans piecomponents and generates a manifest JSON for SSR / production builds.

| Flag | Default | Description |
|---|---|---|
| `--out-dir`, `-o` | `public` | Output directory for manifest |
| `--src-dir`, `-s` | `src` | Source directory to scan |
| `--append` | off | Include built-in pieui components in the manifest |

**When:** Part of the production build step (`next build`).

---

### 3.11 `card remote push`

```bash
pieui card remote push <ComponentName>
```

Uploads `piecomponents/<ComponentName>/` to the platform under the `typescript/` envelope. Assigns a new revision `@N`.

**When:** After implementing or updating a card.
**Note:** Each push creates a new immutable revision. Old revisions remain pullable by `@N`.

---

### 3.12 `card remote pull`

```bash
pieui card remote pull <ComponentName>[@rev]
pieui card remote pull <project>/<ComponentName>[@rev]
pieui card remote pull r/<user>/<ComponentName>
```

Downloads a component into `piecomponents/`. Overwrites local files.

| Form | Access |
|---|---|
| `MyCard` | Latest from current project |
| `MyCard@7` | Specific revision from current project |
| `other-proj/MyCard` | Another project of the **same user** |
| `r/username/MyCard` | Public component by any user |

```bash
pieui card remote pull ProfileCard
pieui card remote pull ProfileCard@3
pieui card remote pull r/someuser/PriceTickerCard
```

---

### 3.13 `card remote list`

```bash
pieui card remote list [--user <U>] [--project <S>]
```

Lists component names stored on the platform.

**Note:** `--user / --project` only works if your API key has access to that project.

---

### 3.14 `card remote history`

```bash
pieui card remote history <ComponentName> [--page N] [--per-page N] [--from R] [--to R]
```

Shows revision history with per-file diffs (git-style). Includes both `python/` and `typescript/` envelope files.

| Flag | Default | Description |
|---|---|---|
| `--page` | 1 | Page number |
| `--per-page` | 10 | Revisions per page |
| `--from` | — | Start revision number |
| `--to` | — | End revision number |

```bash
pieui card remote history ProfileCard
pieui card remote history ProfileCard --from 3 --to 7
```

**When:** Auditing what changed between pushes; debugging regressions; verifying both envelopes were pushed.

---

### 3.15 `card remote public / private`

```bash
pieui card remote public <ComponentName>   # accessible as r/username/MyCard
pieui card remote private <ComponentName>  # revert to private
```

---

### 3.16 `card remote remove`

```bash
pieui card remote remove <ComponentName>
```

Deletes the component from the platform (all revisions). Does not touch local files.

---

## 4. pie CLI — All Commands

### 4.1 Auth

```bash
pie login
```

Same OAuth flow as pieui. Writes to `.pie/config.json` in CWD and appends to `.env`.

**Critical:** Run from the backend project root. pie reads `.pie/config.json` relative to CWD.
If env vars `PIE_USER_ID`, `PIE_API_KEY`, `PIE_PROJECT` are set, they take precedence over the config file.

---

### 4.2 `page add`

```bash
pie page add <path>
```

Creates `pages/<slug>.py` with an `AsyncPage` subclass.

```bash
pie page add dashboard
pie page add wallet/send
```

**When:** Every new backend route. Then register the page in `web.py` and restart the server.

---

### 4.3 `card add`

```bash
pie card add [type] <ComponentName>
```

Creates `pages/components/<snake_name>.py` with a `Card` dataclass.

```bash
pie card add simple ProfileCard
pie card add complex ChatCard
```

**When:** Same time as `pieui card add` — both sides must exist.

---

### 4.4 `card list`

```bash
pie card list
```

Prints a table: Name, Type, Ajax, IO, File path.

---

### 4.5 `card view`

```bash
pie card view <ComponentName>
```

Pretty-prints a card's props table (field name, Python type, default value) plus Ajax / IO / Events flags.

```bash
pie card view ProfileCard
```

**When:** Quick inspection of a card's contract without opening the file.

---

### 4.6 `card dump-metadata`

```bash
pie card dump-metadata <ComponentName> [--out <file.json>]
```

Outputs full JSON metadata in the **Python envelope** format:

```json
{
  "python": {
    "name": "MyCard",
    "propsSchema": { "properties": { ... }, "type": "object" },
    "propsCode": "@dataclass\nclass MyCard...",
    "ajaxList": ["pathname"],
    "events": [],
    "eventsPropsCode": {},
    "eventsPropsSchema": {},
    "inputPropsCode": null,
    "inputPropsSchema": null,
    "files": [{ "path": "my_card.py", "content": "..." }],
    "packages": ["pie"]
  }
}
```

| Flag | Default | Description |
|---|---|---|
| `--out`, `-o` | stdout | Write JSON to file |

```bash
pie card dump-metadata ProfileCard
pie card dump-metadata ProfileCard --out /tmp/profile_card_meta.json
```

---

### 4.7 `card check-sync`

```bash
pie card check-sync <ComponentName>
```

Compares the Python props schema (local) against the TypeScript props schema (from `frontendProjectDir`) field by field.

**Requires** `frontendProjectDir` in `.pie/config.json`:
```json
{
  "user_id": "...",
  "api_key": "...",
  "project": "...",
  "frontendProjectDir": "/absolute/path/to/frontend-project"
}
```

**When:** After editing either side; before pushing to the platform; as part of CI.
See [section 9](#9-check-sync-findings-guide) for interpreting output.

---

### 4.8 `card list-events` / `card add-event`

```bash
pie card list-events <ComponentName>    # list IO events (static parse)
pie card add-event <ComponentName> <event_name>  # add event handler stub
```

---

### 4.9 `card pull`

```bash
pie card pull <REF>
```

Downloads a Python card from the platform into `pages/components/`.

| REF form | Access |
|---|---|
| `MyCard` | Current project |
| `other-proj/MyCard` | Another project of the same user |
| `r/username/MyCard` | Public component by any user |

---

### 4.10 `card remote push`

```bash
pie card remote push <ComponentName>
```

Uploads the Python card to the platform under the `python/` envelope.

**Known issue:** When `PIE_USER_ID` / `PIE_API_KEY` / `PIE_PROJECT` env vars are set, pie searches for config in parent directories instead of CWD. This causes "user_id required" errors even if `.pie/config.json` exists locally.

```bash
# Preferred: run from project root with no conflicting env vars
cd my-api-project && pie card remote push MyCard

# Fallback: pass all credentials explicitly
PIE_USER_ID=username PIE_API_KEY=rp-xxx PIE_PROJECT=my-project \
  pie card remote push MyCard
```

---

### 4.11 `web` / `init` / `self-upgrade`

`pie web` takes a `module:attribute` path to a `Web` instance (no `run`/`lint` subcommands).

```bash
pie web app:web          # run the app (module `app`, attribute `web`)
pie web app:web verify   # lint / verify the application
pie web app:web build    # build static JSON from the Web app
pie init                 # set up pie in an existing project + link a frontend
pie self-upgrade         # upgrade pie; --pm uv|poetry|pip to force the manager
```

---

### 4.12 Other command groups

These exist on the `pie` CLI; see the cheatsheets for full flags.

```bash
# Centrifuge channels & events (backend-only — no pieui mirror)
pie card channels [app:web] [--live] [--json]
pie card emit <Card> <event> <channel> [--data '{}'] [--web app:web]

# Remote (complete surface)
pie card remote history|public|private|remove <Card>

# Pages
pie page view <path>
pie page ajax <path> add|remove <handler>

# Task runner
pie taskrun local|remote app:web <page> <action> [params...]

# Cloudflare Python Worker (backend-only — needs pieui[cloudflare-worker])
pie cloudflare init|dev|deploy
```

**`pie db …`** — the Beanie/MongoDB layer (Documents, indexes, seeds, document↔card
bridges, migrations). Backend-only, **no `pieui db` mirror**. Full reference:
`skills/pie-cli/references/db-cheatsheet.md`.

```bash
pie db init                 # scaffold the db layer
pie db status               # ping Mongo, list collections + counts
pie db model add User --field email:str --timestamps --index email,unique
pie db migrate              # run migrations forward
```

See also [§10 Previewing & Rendering Cards](#10-previewing--rendering-cards) for `pie card show` / `pie card show-mcp`.

---

## 5. Envelope Policy

The platform stores each component in **two separate envelopes**:

```
username/my-project/MyCard/
  ├── python/my_card.py            ← written by  pie card remote push
  └── typescript/
      ├── piecomponents/MyCard/index.ts
      ├── piecomponents/MyCard/types/index.ts
      └── piecomponents/MyCard/ui/MyCard.tsx  ← written by pieui card remote push
```

**Rules:**

1. `pie card remote push` writes only `python/`. It never touches TypeScript files.
2. `pieui card remote push` writes only `typescript/`. It never touches Python files.
3. `pie card pull` restores only the Python file locally.
4. `pieui card remote pull` restores only the TypeScript files locally.
5. `card remote history` shows diffs for **both** envelopes in a unified revision timeline.
6. `check-sync` reads both envelopes and compares their schemas.

**A component is fully published only after both `pie card remote push` AND `pieui card remote push` have been called.**

**API key scope:** Each project has its own API key. A key for project A cannot read project B even for the same `user_id`. Log in per-project to get the correct key.

---

## 6. Workflow Recipes

### Recipe 1 — Create a page with an AJAX card

```bash
# Frontend
pieui page add my/route
pieui card add simple MyCard --ajax
# → implement piecomponents/MyCard/types/index.ts and ui/MyCard.tsx

# Backend
pie page add my/route
pie card add simple MyCard
# → implement pages/components/my_card.py and pages/my_route.py
# → register in web.py: "my/route": MyRoutePage()
# → restart backend
```

The `--ajax` flag adds `pathname`, `deps_names`, `kwargs` to both scaffolded files, enabling page-navigation callbacks from the card.

---

### Recipe 2 — Create a realtime card with events

```bash
# Frontend
pieui card add simple LiveDataCard --io
pieui add-event LiveDataCard update    # adds methods.update handler to TSX

# Backend
pie card add simple LiveDataCard
pie card add-event LiveDataCard update

# Implement both sides, then push
pieui card remote push LiveDataCard
pie card remote push LiveDataCard
```

---

### Recipe 3 — Verify backend ↔ frontend contract

```bash
# 1. Dump Python schema for reference
pie card dump-metadata MyCard --out /tmp/my_card_meta.json

# 2. Run sync check
pie card check-sync MyCard

# 3. Fix any real mismatches, then re-verify
pie card check-sync MyCard

# 4. TypeScript compile check
npx tsc --noEmit
```

See [section 9](#9-check-sync-findings-guide) to distinguish real bugs from expected differences.

---

### Recipe 4 — Publish a card

```bash
# Push TypeScript side
pieui card remote push MyCard    # → MyCard@1

# Push Python side
pie card remote push MyCard      # → MyCard@1

# Verify both envelopes landed
pieui card remote history MyCard
# Confirm diff shows both python/ and typescript/ files

# Optional: make public
pieui card remote public MyCard
# Now accessible as r/username/MyCard by anyone
```

---

### Recipe 5 — Port a card from the platform into a new project

```bash
# Pull TypeScript files
pieui card remote pull r/username/MyCard    # public component
pieui card remote pull other-proj/MyCard    # your other project
pieui card remote pull MyCard@5             # specific revision

# Pull Python file
pie card pull r/username/MyCard
pie card pull other-proj/MyCard

# Register page in web.py if needed, then implement business logic
```

---

### Recipe 6 — Full project push

```bash
# 1. Type check
npx tsc --noEmit

# 2. Sync check all cards
for card in CardA CardB CardC; do
  pie card check-sync $card
done

# 3. Push all frontend cards
for card in CardA CardB CardC; do
  pieui card remote push $card
done

# 4. Push all backend cards
for card in CardA CardB CardC; do
  pie card remote push $card
done

# 5. Commit
git add .
git commit -m "feat: ..."
git push
```

---

## 7. Edge Cases

### `pie card remote push` ignores `.pie/config.json` when env vars are set

When `PIE_USER_ID` / `PIE_API_KEY` / `PIE_PROJECT` are exported in the shell, pie searches parent directories for config instead of CWD. Result: "user_id required" error even with a valid `.pie/config.json` in the project root.

**Fix:** Unset env vars and run from project root, or pass all three explicitly:
```bash
PIE_USER_ID=username PIE_API_KEY=rp-xxx PIE_PROJECT=my-project \
  pie card remote push MyCard
```

---

### `check-sync` requires `frontendProjectDir`

```
[pie] Frontend project path required to run check-sync.
```

**Fix:** Add to the backend project's `.pie/config.json`:
```json
{ "frontendProjectDir": "/absolute/path/to/frontend-project" }
```

---

### API key 403 on `card remote list --project`

Each project has a scoped API key. A key for project A cannot access project B, even for the same user.

**Fix:** Run `pieui login` / `pie login` for the target project to get its key.

---

### Stale dev-server bundle after `.env` change

The Next.js dev server may cache an old SSR bundle after env changes.

**Fix:** Delete the build cache and restart:
```bash
rm -rf .next && bun run dev
```

---

### Turbopack incompatible with certain native modules

Some npm packages ship native `.node` binaries that Turbopack cannot bundle.

**Fix:** Use webpack mode instead:
```bash
bun run dev    # ensure next.config uses webpack, not --turbo
```

---

### `is_typed` error on AsyncPage

Missing `is_typed=False` causes a runtime type error on page load.

**Fix:**
```python
class MyPage(AsyncPage):
    def __init__(self):
        super().__init__(is_typed=False)
        self.fields = UnionCard([MyCard(name="MyCard")])
```

---

### Form submits to `/api/process/` instead of handler

A `<button>` inside `<PieCard>` without `type="button"` is treated as a form submit button.

**Fix:**
```tsx
<button type="button" onClick={handler}>Label</button>
```

---

### Python snake_case props are `undefined` in TypeScript

PIE converts Python `snake_case` field names to `camelCase` when sending to the frontend.

**Fix:** Always use camelCase in TS interfaces:
```typescript
// ❌  network_label: string
// ✅  networkLabel: string
```

---

## 8. Project Setup & .gitignore

### Monorepo structure (frontend root + backend subdirectory)

```
my-project/                  ← git root (Next.js frontend)
├── backend/                 ← Python backend (any name)
│   ├── pages/
│   ├── web.py
│   ├── pyproject.toml
│   └── .pie/               ← gitignored
├── piecomponents/
├── app/
├── lib/
├── .env                    ← gitignored
├── .env.example            ← committed (template, no secrets)
└── .pie/                   ← gitignored
```

If the backend directory has its own `.git`, remove it before committing to avoid submodule issues:
```bash
rm -rf backend/.git
git add backend/
```

### .gitignore

```gitignore
# Frontend
/node_modules
/.next/
*.tsbuildinfo
next-env.d.ts
/coverage

# Backend (adjust directory name as needed)
backend/.venv/
backend/**/__pycache__/
backend/**/*.pyc
backend/.env
backend/.pie/

# Secrets & credentials — never commit
.env
.env.*
!.env.example
.pie/

# Misc
.DS_Store
*.pem
npm-debug.log*
.claude/
```

---

## 9. check-sync Findings Guide

`pie card check-sync MyCard` diffs the Python and TypeScript prop schemas. Not all findings are bugs.

| Finding | Meaning | Action |
|---|---|---|
| `Python allows null, TS is required+non-null` | Python dataclass defaults make fields nullable in JSON Schema; TS correctly marks them required | **None** — backend always sends a value |
| `depsNames / kwargs / flow / pathname` in Python, not in TS | PIE `Card` base class internal fields | **None** — framework internals, frontend doesn't use them |
| `integer` vs `number` | Python `int` → JSON Schema `integer`; TS `number` → `number` | **None** — integers are valid JS numbers |
| `array` vs `object` for `List[str]` / `string[]` | Schema-generation difference between languages | **None** — runtime compatible |
| Field in TS but **not** in Python | Missing field in backend dataclass | **Fix** — add to `pages/components/my_card.py` |
| Field in Python but **not** in TS (non-framework field) | Missing field in TS interface | **Fix** — add to `piecomponents/MyCard/types/index.ts` |
| Completely incompatible types (e.g. `string` vs `number`) | Real contract mismatch | **Fix** — align types on both sides |

---

## 10. Previewing & Rendering Cards

PIE can render **one card in isolation** — without wiring it into a full app — for visual review, screenshots, or agent-driven inspection. Three surfaces share one mechanism.

### 10.1 How it works

```
  pie (backend)                          pieui (frontend)
  ┌────────────────────────┐  HTTP GET   ┌───────────────────────────┐
  │ ephemeral Web app      │ ◀────────── │ registry-dev harness       │
  │  /api/content/         │  /api/...   │  (PiePreviewRoot,          │
  │  /api/ajax_content/…   │ ──────────▶ │   no app layout)           │
  │  serves ONE card JSON  │             │  fetches /api/content/,    │
  └────────────────────────┘             │  renders card by name from │
                                         │  piecomponents/registry.ts │
                                         └───────────────────────────┘
```

- The **backend** (`pie`) serves the card envelope `{ "card": "<Name>", "data": { … } }` at `/api/content/`, plus a print-and-echo stub for every ajax `pathname` at `/api/ajax_content/<path>`.
- The **frontend** is the **registry-dev harness**: a standalone Next app (`pieui registry dev`) generated under `<frontend>/.pie/registry/`. It mounts `PiePreviewRoot` (no app chrome), reads `PIE_API_SERVER`, fetches `/api/content/`, and renders the matching component from `piecomponents/registry.ts`.
- The card name in the content JSON **must** be registered on the frontend (created via `pieui card add`), and the `data` keys must be **camelCase** matching the TS props.

### 10.2 `pie card show` — interactive preview (human-facing)

Serves one card from an ephemeral backend and opens it in the harness. Blocks until Ctrl+C; always tears down the frontend process.

```bash
pie card show 'ProfileCard(name="p", title="Hi")'
pie card show 'ColCard([ACard(), BCard(a=1)])' --frontend-port 3210 --route /
```

`EXPR` is a Python expression that evaluates to a `Card`. The eval namespace = framework `Card` subclasses **plus every `Card` subclass in the backend's `pages/components/*.py`**. Any card carrying a `pathname` gets a print-only ajax stub auto-registered, so ajax cards respond out of the box.

| Flag | Default | Description |
|---|---|---|
| `--frontend-dir` | `frontendProjectDir` from `.pie/config.json` | Frontend project to render with |
| `--frontend-port` | `3000` | Port for the registry-dev harness |
| `--backend-port` | auto (free port) | Port for the ephemeral backend |
| `--route` | `/` | Frontend route to open |
| `--pm` | autodetect | Package manager (bun/pnpm/yarn/npm) |
| `--no-open` | off | Do not open a browser automatically |

### 10.3 `pieui registry dev|build` — the harness itself

```bash
pieui registry dev --port 3939 --api-server http://127.0.0.1:8000/
pieui registry build --out public/pie-registry
```

- `registry dev [--port N] [--api-server URL]` — runs the standalone `PiePreviewRoot` harness pointed at a backend's `/api/content/`. This is what `pie card show` and the MCP spawn internally; run it by hand only to debug the harness or to drive it from your own backend.
- `registry build [--out DIR]` — static-export the harness so `pie` can serve it directly (`disable_serving=False`).
- Generated under `<frontend>/.pie/registry/` — a **separate Next app with its own `.next` build cache** (see Troubleshooting).

### 10.4 `pie card show-mcp` — headless rendering for agents (MCP)

A FastMCP server that renders cards headlessly (JSON / HTML / screenshot) and exposes their ajax — so AI agents can inspect cards without a human browser. Install extras: `pip install 'pieui[mcp]'` (adds `mcp` + `playwright`).

```bash
pie card show-mcp                                  # stdio transport (default)
pie card show-mcp --http 9009                      # streamable-HTTP on :9009
pie card show-mcp --frontend-port 3939             # harness port
pie card show-mcp --mirror http://127.0.0.1:8000   # mirror a live `pie card show` backend
pie card show-mcp --no-frontend                    # json + ajax tools only (no browser)
```

| Flag | Default | Description |
|---|---|---|
| `--http PORT` | stdio | Serve over streamable-HTTP instead of stdio |
| `--frontend-dir` | config | Frontend project dir |
| `--frontend-port` | `3000` | registry-dev harness port |
| `--mirror URL` | — | Mirror a running `pie card show` backend |
| `--no-frontend` | off | Skip frontend + browser; only `render_card(json)` + ajax tools |

**MCP tools:**

| Tool | Purpose |
|---|---|
| `render_card(card?, format)` | Render a card. `card` = a Python **expression** evaluating to a `Card`, or a content-**JSON string**. `format` = `json` (echo content) \| `html` \| `screenshot`. |
| `attach(base_url)` | Mirror a running `pie card show` backend at `base_url`. |
| `detach()` | Stop mirroring; render local cards again. |
| `list_ajax()` | List ajax `pathname`s on the current card. |
| `call_ajax(pathname, data?)` | POST to a running ajax endpoint and return its content. |

Notes:
- `format=json` only **echoes** the content envelope (no browser needed). `html` / `screenshot` need the running harness, a linked frontend (`pie init`), and Playwright.
- **Prefer the expression form for `card`.** A `{ … }` JSON string is frequently coerced to a dict by the MCP arg layer and rejected — pass an expression like `ProfileCard(name="p", …)` instead. The eval namespace includes any `Card` subclass in the backend's `pages/components/`.
- Register it as an MCP server (Claude Code / Cursor / Codex) with a small launcher that pins the backend project and `pie` on `PYTHONPATH`:
  ```bash
  #!/usr/bin/env bash
  cd /path/to/backend-project
  PYTHONPATH=/path/to/pie exec ./.venv/bin/python -m pie card show-mcp --frontend-port 3939 "$@"
  ```

### 10.5 Showing the harness in an agent's side panel

To display the live harness inside a host with a web-preview panel (e.g. Claude Code's `preview_*`):

1. Set the card via `render_card` first, so the backend serves it at `/api/content/`.
2. Find the backend port — the `show-mcp` process's listening port whose `/api/content/` returns your card.
3. Launch the harness as a **managed** preview server. Preview tools won't reuse an externally-started server, and launch configs may lack a `cwd` field — so use a shell wrapper and an auto-assigned port:
   ```json
   {
     "name": "pie-registry",
     "runtimeExecutable": "bash",
     "runtimeArgs": ["-lc", "cd <frontend> && exec pieui registry dev --port \"$PORT\" --api-server http://127.0.0.1:<backend>/"],
     "autoPort": true
   }
   ```

### 10.6 Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Persistent `Parsing CSS source code failed` / stale build error in the preview **after** the source is already fixed | The harness keeps its **own** Turbopack/Next cache at `<frontend>/.pie/registry/.next`; clearing the main app `.next` does nothing | `rm -rf <frontend>/.pie/registry/.next`, then restart the harness |
| `pieui registry …` prints the general help / acts like an unknown command | The project-local `node_modules/.bin/pieui` predates `registry`; the harness resolves project-local first | Use the **global** `pieui` (e.g. `~/.bun/bin/pieui`) or run `pieui self-upgrade` |
| Preview shows the **full app** or a loading splash instead of the bare card | The harness never started (often the missing `registry` command above) and something fell back to a plain `next dev` on that port | Confirm a `pieui registry dev` process is actually serving the port |
| `render_card` rejects the card with a dict/validation error | A `{ … }` JSON string was coerced to a dict | Pass a **card expression** instead |
| `html` / `screenshot` returns "needs a linked frontend" | No Playwright, or no linked frontend | `pip install 'pieui[mcp]'` and `pie init` to link the frontend |
| Card renders blank / "unknown card" | Name not in frontend `registry.ts`, or `data` keys are snake_case | `pieui card add <Name>`; use camelCase `data` keys |

**Heads up:** killing/clearing a preview harness restarts a `next dev`. If the user runs their own dev server on that port, confirm before replacing it.

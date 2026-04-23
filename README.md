# pie-skills

![skills](https://img.shields.io/badge/skills-2-7F77DD?style=flat-square) ![agents](https://img.shields.io/badge/agents-Claude%20%7C%20Cursor%20%7C%20Codex-5DCAA5?style=flat-square) ![license](https://img.shields.io/badge/license-MIT-B4B2A9?style=flat-square)

Agent skills for the Pie ecosystem CLIs — `pie` (Python backend) and `pieui` (TypeScript/Next.js frontend).

```bash
# skill.fish
npx skillfish add Swarm-AI-Labs/pie-skills

# skills CLI
npx skills add git@github.com:Swarm-AI-Labs/pie-skills.git
```

---

## What are agent skills?

Agent skills are packaged instruction sets that extend what an AI coding agent can do. Each skill is a folder containing a `SKILL.md` file that tells the agent exactly how to behave — what commands exist, what the defaults are, what's dangerous, and what workflow to follow. Skills are loaded at the start of a task so the agent has precise, up-to-date knowledge of the tool rather than guessing from general training.

Skills are installed via the [`skills` CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add git@github.com:<owner>/pie-skills.git
# or HTTPS
npx skills add https://github.com/<owner>/pie-skills.git
```

Once installed, agents (Claude, Copilot, Cursor, and others) automatically pick up the right skill when they detect relevant task context.

---

## Pie ecosystem overview

The Pie ecosystem is a server-driven UI framework. The Python backend (`pie`) manages cards, pages, and web applications. The TypeScript frontend (`pieui`) is a React component library and CLI that scaffolds Next.js apps, registers components, and syncs them with remote storage.

```
┌─────────────────────────────────────────────────────┐
│  pie (Python)                pieui (TypeScript/Bun) │
│  ─────────────────           ────────────────────── │
│  Web / FastAPI app           Next.js app             │
│  Cards (Python classes)  ←→  Cards (React components)│
│  Pages                       Pages (app router)      │
│  Remote storage API          Remote storage API      │
└─────────────────────────────────────────────────────┘
```

Cards are the core abstraction — reusable, typed UI components that carry data, support real-time updates via Socket.IO or Centrifuge, and can be pushed to and pulled from a shared remote registry.

---

## Available skills

| Skill | Language | Runner | Use when |
|---|---|---|---|
| [`pie-cli`](#pie-cli-skill) | Python | `uv run pie` | Working inside a Python Pie backend project |
| [`pieui-cli`](#pieui-cli-skill) | TypeScript | `bunx pieui` | Working inside a Next.js / Bun frontend project |

---

## Skill structure

Each skill follows this layout:

```
skills/<name>/
  SKILL.md                  # Agent instructions — scope, workflow, safety rules
  metadata.json             # Author and version info
  references/
    command-cheatsheet.md   # Quick-reference command syntax
  scripts/
    README.md               # Placeholder for automation helper scripts
```

### SKILL.md anatomy

```yaml
---
name: <skill-name>
description: <one-line description used for routing>
metadata:
  author: <author>
  version: <semver>
---
```

After the frontmatter, each SKILL.md contains:

- **Scope** — the exact commands the skill covers
- **Card types** — the component types available and what they do
- **Defaults** — runner preference, directory conventions
- **Prerequisites checklist** — runtime, deps, env vars
- **Workflow** — numbered steps the agent follows for each task
- **Safety rules** — destructive or unimplemented operations to avoid
- **References** — pointer to the cheatsheet

---

## pie-cli skill

**File:** `skills/pie-cli/SKILL.md`

The `pie` CLI is the Python-side tool for the Pie framework. It manages the full lifecycle of a Pie project: scaffolding, running and building the web app, generating card and page files, and syncing components with remote storage.

### When to use

Use `pie-cli` when the user is working in a Python Pie project — either the `pie` repository itself or a project created with `pie create`. The runner is `uv run pie` (local repo) or `pie` (globally installed).

### Prerequisites

| Requirement | Detail |
|---|---|
| Python | `>= 3.14` |
| uv | Install deps with `uv sync --python 3.14` |
| `.env` file | Required for any remote storage or auth command |

Required environment variables for remote and storage flows:

```env
PIE_USER_ID=your-user-id
PIE_PROJECT=your-project-slug       # wins over PIE_PROJECT_SLUG
PIE_PROJECT_SLUG=your-project-slug  # fallback; defaults to cwd name if absent
PIE_API_KEY=your-api-key            # sent as x-api-key to cdn-pieui.swarm.ing/api
PIE_COMPONENTS_DIR=pages/components # default components directory
```

### Commands

#### Project scaffolding

```bash
uv run pie create my-app
```

Creates a new project with:

```
my-app/
  web.py
  pages/
    main.py
    components/
```

Runs `uv init`, adds `pieui`, and starts a dev server on port 8008.

#### Web commands

```bash
uv run pie web web:web            # run the web app (module:attribute format)
uv run pie web web:web verify     # verify every page has a fields attribute
uv run pie web web:web build      # build static JSON from page fields → build.json
```

#### Card commands

Cards are Python classes that define a UI component's data shape, real-time behaviour, and event support.

```bash
# Create a new card file
uv run pie card add simple MyCard
uv run pie card add complex MyCard
uv run pie card add container MyCard
uv run pie card add complex-container MyCard --io --ajax

# Inspect cards
uv run pie card list
uv run pie card view MyCard           # print name, props, ajax, IO, events as tables
uv run pie card list-events MyCard    # list get_supported_events() entries

# Remote storage
uv run pie card push MyCard           # upload to storage API
uv run pie card pull alice/MyCard     # download by user/component reference
uv run pie card remote list           # list components for your user/project
uv run pie card remote list --user alice --project demo
uv run pie card remote pull MyCard    # pull from same user/project context
```

Names are normalised: `MyCard → pages/components/my_card.py`, `trade widget → pages/components/trade_widget_card.py`.

#### Page commands

```bash
uv run pie page add dashboard         # creates a page file
uv run pie page add admin/users       # supports nested paths
uv run pie page view dashboard        # print the page source file
```

#### Auth

```bash
uv run pie login
```

Saves credentials under `.pie/config.json`.

### Card types

| Type | Props | Use for |
|---|---|---|
| `simple` | `data` | Read-only display cards with no nested content |
| `complex` | `data`, `children` | Cards that can render child components inline |
| `container` | `data`, `content` | Layout wrapper around a single nested card |
| `complex-container` | `data`, `content[]` | Layout wrapper around multiple nested cards |

Add `--io` to wire in Socket.IO support. Add `--ajax` for AJAX form submission. Both flags can be combined.

### Workflow

1. Confirm the goal: scaffold, inspect, sync, or auth.
2. Run the narrowest command that answers the request.
3. If the command fails, print the exact error and check env/config.
4. For remote sync, validate user and project context before any write.
5. Summarise outputs and suggest the next action.

### Safety rules

- `pie card add-event` exists in the parser but is **not implemented** for Python AST editing — do not promise it will work.
- For `card push` and `card pull`, validate target names and paths before writes.
- For `page add`, confirm `web.py` registration stays valid after the new file is created.

---

## pieui-cli skill

**File:** `skills/pieui-cli/SKILL.md`

The `pieui` CLI is the TypeScript/Bun-side tool for the Pie framework. It bootstraps Next.js applications, scaffolds card and page components, manages the local component registry, syncs components with remote storage, and generates the build manifest.

### When to use

Use `pieui-cli` when the user is working in a Next.js or Bun project that uses `@swarm.ing/pieui`. The preferred runner is `bunx pieui` for globally available usage, or `bun src/cli.ts` for in-repo development.

### Prerequisites

| Requirement | Detail |
|---|---|
| Bun | Any recent version |
| Next.js project | Required for `card add`, `page add`, and `list` commands |
| Auth | Run `pieui login` or ensure env/config is present for remote commands |

### Commands

#### App bootstrap

```bash
bunx pieui create my-app           # scaffold a Next.js + PieUI app
bunx pieui create-pie-app my-app   # alias
bunx pieui create-pieui my-app     # alias
```

#### Initialisation

```bash
bunx pieui init                    # initialise PieUI in an existing Next.js project
```

#### Card generation

Cards are React components that receive typed props and optionally connect to real-time transports.

```bash
# Explicit type
bunx pieui card add simple StatusCard
bunx pieui card add complex FeedCard
bunx pieui card add simple-container LayoutCard
bunx pieui card add complex-container DashCard --io --ajax

# Type omitted → defaults to complex-container
bunx pieui card add MyCard
```

Generated files are placed under `piecomponents/` by convention.

#### Page generation

```bash
bunx pieui page add chat           # writes app/chat/page.tsx
bunx pieui page add admin/users    # writes app/admin/users/page.tsx
```

#### Local component inspection

```bash
bunx pieui list                            # list all registered components
bunx pieui list all                        # explicit filter (same as no filter)
bunx pieui list simple                     # filter by type
bunx pieui list complex
bunx pieui list simple-container
bunx pieui list complex-container

bunx pieui list-events StatusCard          # list IO events for a component
bunx pieui add-event StatusCard refresh    # add an IO event handler
bunx pieui remove StatusCard               # delete a component
```

#### Remote storage

```bash
bunx pieui login
bunx pieui card remote list
bunx pieui card remote list --user alice --project demo
bunx pieui card remote push StatusCard
bunx pieui card remote pull StatusCard
bunx pieui card remote remove StatusCard   # destructive — requires explicit intent
```

#### Build manifest

The postbuild step scans source for `registerPieComponent` calls and writes `pieui.components.json`:

```bash
bunx pieui postbuild --src-dir src --out-dir dist
bunx pieui postbuild --src-dir src --out-dir dist --append   # merge into existing manifest
```

### Card types

| Type | Props | Use for |
|---|---|---|
| `simple` | `data` | Display-only cards, no nested content |
| `complex` | `data`, `children` | Cards with inline child rendering |
| `simple-container` | `data`, `content` | Wrapper around a single nested `UIConfigType` |
| `complex-container` | `data`, `content[]` | Wrapper around an array of nested `UIConfigType`s |

**Default:** when the type argument is omitted, `card add` defaults to `complex-container`.

Add `--io` for Socket.IO support. Add `--ajax` for AJAX form submission. Both flags are combinable.

### List filters

The `list` command accepts these filters: `all` (default), `simple`, `complex`, `simple-container`, `complex-container`.

### Workflow

1. Identify the goal: app bootstrap, scaffolding, remote sync, or diagnostics.
2. Run the narrowest command with explicit arguments.
3. Validate generated files and command output.
4. For remote operations, confirm user/project scope before push or remove.
5. Report changed files and suggest the follow-up command.

### Safety rules

- `card remote remove` is destructive — always require explicit user confirmation.
- `add-event` edits component method maps — verify the target component exists first.
- Do not run `postbuild --append` unless the user explicitly asks for built-in component merging.

---

## Built-in PieUI components

These components are registered automatically when `initializePieComponents()` is called. They are available in any PieUI application without additional scaffolding.

### Container components

#### SequenceCard

Renders an ordered array of `content[]` items one after another inside a styled `div`. Accepts an `sx` style object and a `name` for DOM `id`.

**Props:** `data: { name, sx }`, `content: UIConfigType[]`
**Use for:** vertical or sequential layouts of multiple cards.

#### BoxCard

Wraps a single `content` item in a navigable container. When a `url` is provided, clicking the box navigates to that route (internal) or URL (external).

**Props:** `data: { name, url?, sx }`, `content: UIConfigType`
**Use for:** clickable card wrappers, linked sections.

#### UnionCard

Renders an array of `content[]` items without imposing a layout wrapper — children are rendered as siblings.

**Props:** `data: { name }`, `content: UIConfigType[]`
**Use for:** flat rendering of multiple cards where no wrapper div is wanted.

#### AjaxGroupCard

A container that manages AJAX state for a group of child cards. Tracks loading state, supports no-return mode (stays on the result), and handles streamed UI event responses from the server.

**Props:** `data: { name, useLoader?, noReturn?, … }`, `content: UIConfigType[]`
**Use for:** forms and interactive groups that POST to `api/ajax_content` and re-render from the server response.

### Common utility components

#### HiddenCard

Renders nothing visible but holds a named value in React state. Supports real-time updates via Socket.IO, Centrifuge, or Mitt so the value can be updated from the server without a full re-render.

**Props:** `data: { name, value, useSocketioSupport?, useCentrifugeSupport?, useMittSupport?, centrifugeChannel? }`
**Use for:** invisible state containers, server-pushed data that other cards read.

#### HTMLEmbedCard

Renders arbitrary HTML string as React elements using `html-react-parser`. Also integrates OpenAI WebRTC for optional voice agent functionality.

**Props:** `data: { html, useSocketioSupport?, useCentrifugeSupport?, useMittSupport?, centrifugeChannel? }`
**Use for:** server-rendered HTML fragments, rich embeds, voice-enabled widgets.

#### IOEventsCard

Receives IO events from the server and triggers toast notifications. Supports four toast transition animations: `bounce`, `slide`, `zoom`, `flip`. Also handles navigation events.

**Props:** `data: { name, … }`
**Use for:** server-side notifications, alerts, and navigation triggers delivered over real-time transports.

#### AutoRedirectCard

Immediately redirects to a `url` on mount. Handles both external URLs (`window.location.href`) and internal routes via the `NavigateContext`.

**Props:** `data: { url }`
**Use for:** server-controlled redirects, post-action navigation.

#### SessionStorageCard

Reads and writes a key/value pair to `sessionStorage`. Supports real-time updates so the stored value can be changed server-side.

**Props:** `data: { name, key, value, … }`
**Use for:** ephemeral client-side state that survives navigation within a session.

#### SecureStorageCard

Same interface as `SessionStorageCard` but targets a secure storage backend (Telegram CloudStorage or equivalent depending on platform).

**Props:** `data: { name, key, value, … }`
**Use for:** sensitive data that should not live in `sessionStorage`.

#### CloudStorageCard

Reads and writes a key/value pair to Telegram CloudStorage. Works identically to `SecureStorageCard` but explicitly targets the Telegram cloud API.

**Props:** `data: { name, key, value, … }`
**Use for:** cross-device persistence inside Telegram WebApps.

#### DeviceStorageCard

Same interface as the storage cards above, targeting device-local storage.

**Props:** `data: { name, key, value, … }`
**Use for:** local-first storage on the device.

---

## Best practices

**Choosing a card type.** Start with `simple` for display-only cards. Add `complex` when you need to nest children inline. Use `container` or `complex-container` when the card acts as a layout wrapper — `container` for a single child, `complex-container` for an ordered list of children. When in doubt, `complex-container` is the most flexible.

**Real-time flags.** Add `--io` only when the card needs to react to Socket.IO server pushes. Add `--ajax` when the card submits a form or triggers a server action. Both can be combined on a single card.

**Remote sync.** Always run `pieui login` (or `pie login`) before any `remote push` or `remote pull`. Validate that `PIE_USER_ID` and `PIE_PROJECT` are set in `.env` for the pie CLI. Remote remove is irreversible — confirm with the user before running it.

**Name normalisation.** Both CLIs normalise component names: spaces become underscores, `PascalCase` is preserved for the class, `snake_case` is used for filenames. Always confirm the generated path before writing to disk.

**Postbuild.** Run `pieui postbuild` after adding or removing components so `pieui.components.json` stays in sync with the source. Use `--append` only when merging built-in components into an existing manifest.

**Env vars.** Keep a `.env` at the project root. `PIE_PROJECT` overrides `PIE_PROJECT_SLUG`; if neither is set, the current directory name is used as the project slug.

---

## Repository structure

```
pie-skills/
  README.md                               # this file
  AGENTS.md                               # cross-agent skill index
  CLAUDE.md                               # Claude-specific routing guidance
  skills/
    pie-cli/
      SKILL.md                            # agent instructions
      metadata.json                       # { author, version }
      references/
        command-cheatsheet.md             # quick-reference syntax
      scripts/
        README.md                         # placeholder for helper scripts
    pieui-cli/
      SKILL.md
      metadata.json
      references/
        command-cheatsheet.md
      scripts/
        README.md
```

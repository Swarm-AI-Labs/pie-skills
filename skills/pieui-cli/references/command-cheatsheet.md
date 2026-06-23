# pieui CLI command cheatsheet

Run from any project with CLI installed:

```bash
pieui --help
```

Or via Bun:

```bash
bunx pieui --help
```

## App bootstrap

```bash
bunx pieui create my-app
bunx pieui create-pie-app my-pie-app
bunx pieui create-pieui my-pie-app
bunx pieui self-upgrade
bunx pieui self-upgrade --pm bun
```

## Init + generation

Four card types: `simple`, `complex`, `simple-container`, `complex-container` (default when omitted).

```bash
bunx pieui init
bunx pieui init --out-dir packages/app   # -o; base dir for piecomponents (default: .)

# simple — only a data prop
bunx pieui card add simple StatusCard

# complex — data + children props
bunx pieui card add complex FeedCard

# simple-container — data + single content slot
bunx pieui card add simple-container LayoutCard

# complex-container — data + content[] array (default); add --io / --ajax / --input as needed
bunx pieui card add complex-container DashCard --io --ajax --input

# omit type → defaults to complex-container
bunx pieui card add MyCard

# port from a backend Python card, metadata JSON file, or configured backend card name
bunx pieui card add MyCard --from ../ai-exchange-bot/pages/components/my_card.py
bunx pieui card add MyCard --from MyCard

bunx pieui page add chat
bunx pieui page view chat
bunx pieui page ajax chat add refresh
bunx pieui page ajax chat remove refresh
```

## Local inspection and edits

Valid list filters: `all` (default), `simple`, `complex`, `simple-container`, `complex-container`.

```bash
bunx pieui card list
bunx pieui card list all
bunx pieui card list simple
bunx pieui card list complex
bunx pieui card list simple-container
bunx pieui card list complex-container
bunx pieui card view StatusCard
bunx pieui card list-events StatusCard
bunx pieui card add-event StatusCard refresh
bunx pieui card remove StatusCard

# pull a card by reference (current project / another project / public alias);
# distinct from `card remote pull` below
bunx pieui card pull StatusCard
bunx pieui card pull other-proj/StatusCard
bunx pieui card pull r/alice/StatusCard
```

`card list`, `list-events`, and `add-event` accept `--src-dir <dir>` / `-s <dir>` (default `.`).

## Storybook previews

```bash
bunx pieui card add-story StatusCard
bunx pieui card add-story StatusCard --force
bunx pieui card generate-preview StatusCard
bunx pieui card generate-preview StatusCard --out artifacts/status-card.png
```

`generate-preview` expects a Storybook story. It uses a running Storybook on port 6006 or starts `bun run storybook` temporarily.

## Metadata and TS/Python sync

```bash
bunx pieui card dump-metadata StatusCard
bunx pieui card dump-metadata StatusCard --out /tmp/status-card.metadata.json
bunx pieui card check-sync StatusCard
```

`dump-metadata` writes a `{ "typescript": ... }` envelope. `check-sync` delegates to backend `pie card check-sync`; verify `.pie/config.json` backend paths first.

## Remote storage

```bash
bunx pieui login
bunx pieui card remote list
bunx pieui card remote list --user alice --project demo
bunx pieui card remote push StatusCard
bunx pieui card remote pull StatusCard
bunx pieui card remote pull StatusCard@5
bunx pieui card remote history StatusCard
bunx pieui card remote history StatusCard --page 2 --per-page 20 --from 3 --to 7
bunx pieui card remote public StatusCard
bunx pieui card remote private StatusCard
bunx pieui card remote remove StatusCard
```

`public` makes the component readable as `r/<user>/<Name>`; `private` reverses that. Treat `remove`, `public`, and `private` as explicit-intent operations.

## Preview registry harness

```bash
bunx pieui registry dev
bunx pieui registry dev --port 3210 --api-server http://127.0.0.1:8000
bunx pieui registry build
bunx pieui registry build --out public/pie-registry
```

The registry harness is generated under `.pie/registry/` and mounts `PiePreviewRoot` without the app
layout. It renders whatever card a `pie` backend serves at `--api-server`'s `/api/content/` — pair it
with `pie card show <EXPR>` or `pie card show-mcp` (see the pie-cli cheatsheet and complete-guide §10).

- The harness has its **own `.next`** under `.pie/registry/`. Stale CSS/build error after fixing
  source → `rm -rf .pie/registry/.next` and restart.
- If `registry` is reported as unknown, the project-local `pieui` is too old — use the global
  `pieui` (`~/.bun/bin/pieui`) or `pieui self-upgrade`.

## Build manifest

```bash
bunx pieui postbuild --src-dir src --out-dir dist
bunx pieui postbuild --src-dir src --out-dir dist --append
```

## Debugging

```bash
PIE_ENABLE_RENDERING_LOG=true NEXT_PUBLIC_PIE_ENABLE_RENDERING_LOG=true bun dev
```

Current PieUI does not expose a standalone `pieui debug` command. Debug support is an env logging mode for consumers and `build:debug` scripts inside the PieUI source repo.

## Notes

- `card add` default type is `complex-container` when omitted.
- `page add` expects a path and writes `app/<path>/page.tsx`.
- `self-upgrade` upgrades a globally installed `@swarm.ing/pieui` CLI.

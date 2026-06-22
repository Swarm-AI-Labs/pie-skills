---
name: pieui-cli
description: Use for tasks involving the pieui CLI, including Next.js app scaffolding, card/page generation, Storybook previews, TS/Python metadata sync, preview registry workflows, remote component sync, debug logging, self-upgrade, and pieui login.
metadata:
  author: pie-team
  version: 1.1.0
---

# PieUI CLI Skill

Use this skill when the user asks to run, debug, or automate the `pieui` CLI.

## Scope

- `pieui create`, `create-pie-app`, `create-pieui`
- `pieui init`
- `pieui self-upgrade`
- `pieui registry dev|build`
- `pieui card add|list|pull|view|remove`
- `pieui card list-events|add-event`
- `pieui card add-story|generate-preview`
- `pieui card dump-metadata|check-sync`
- `pieui card remote push|pull|list|remove|history|public|private`
- `pieui page add|view|ajax`
- `pieui postbuild`
- `pieui login`

## Card types

The `pieui card add` command accepts four types:

| Type | Description |
|---|---|
| `simple` | Simple component — only a `data` prop |
| `complex` | Complex component — `data` + `children` props |
| `simple-container` | Container with a single `content` slot (`data` + `content`) |
| `complex-container` | Container with an array `content[]` slot (default when type is omitted) |

**Default:** When the type argument is omitted, `pieui card add` defaults to `complex-container`.

Use `--io` to add realtime support, `--ajax` to add AJAX support, and `--input` to generate a typed `stored` prop variant. These flags are optional and combinable.

Use `--from <ref>` to port a component from backend Pie metadata. `<ref>` may be a `.py` file, a PieMetadata JSON file, or a backend card name resolved through `.pie/config.json` `backendComponentsDir`. If `--from` is omitted and a matching backend source exists, `pieui card add <Name>` can auto-detect it.

## Diagnostics and sync

- `pieui card view <Name>` prints the local card contract: props, AJAX, IO, and events.
- `pieui card dump-metadata <Name> [--out file.json]` emits a `{ "typescript": ... }` PieMetadata envelope.
- `pieui card check-sync <Name>` delegates to backend `pie card check-sync` and needs `.pie/config.json` `backendProjectDir` or `backendComponentsDir`.
- `pieui card add-story <Name> [--force]` creates a Storybook story for the card.
- `pieui card generate-preview <Name> [--out file.png]` captures a Storybook PNG preview; it starts Storybook on port 6006 when needed.
- `PIE_ENABLE_RENDERING_LOG=true` / `NEXT_PUBLIC_PIE_ENABLE_RENDERING_LOG=true` enables PieUI rendering debug logs. There is no standalone `pieui debug` command in current PieUI; debug build support exists as package scripts in the PieUI source repo.

## Preview registry

- `pieui registry dev [--port N] [--api-server URL]` runs the standalone `PiePreviewRoot` harness for local preview/debugging.
- `pieui registry build [--out DIR]` builds the harness as a static export for serving by backend `pie`.

## Defaults

- Prefer `bunx pieui ...` for globally available CLI usage.
- In source repo development, `bun src/cli.ts ...` is acceptable.
- Keep generated files under app conventions (`piecomponents/`, `app/<path>/page.tsx`, `.pie/registry/` for generated preview harness files).
- Use `pieui self-upgrade [--pm bun|npm|pnpm|yarn]` when the installed global CLI is stale.

## Prerequisites Checklist

1. Bun installed.
2. In target app: Next.js project exists (for page/card commands).
3. For remote storage commands, credentials are available (`pieui login` or env/config present).

## Workflow

1. Identify whether user needs app bootstrap, component/page scaffolding, remote sync, or diagnostics.
2. Run narrow command with explicit args.
3. Validate generated files and command output.
4. For metadata sync, inspect `.pie/config.json` before assuming backend paths are valid.
5. For remote operations, confirm user/project scope before push/remove/public/private.
6. Report changed files and follow-up command.

## Safety Rules

- `card remote remove` is destructive; require explicit user intent.
- `card remote public` changes sharing visibility; require explicit user intent.
- `card remote private` changes sharing visibility; require explicit user intent.
- `add-event` edits component method maps; verify target component exists first.
- `page ajax` delegates to the backend `pie` CLI and requires configured backend page paths.
- Do not run `postbuild --append` unless user asks for built-in component merge behavior.
- Do not commit machine-specific `.pie/config.json` backend paths unless the team explicitly wants that.

## References

Read command details in:

- `references/command-cheatsheet.md`

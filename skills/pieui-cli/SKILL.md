---
name: pieui-cli
description: Use for tasks involving the pieui CLI, including Next.js app scaffolding, card/page generation, Storybook previews, TS/Python metadata sync, preview registry workflows, remote component sync, debug logging, self-upgrade, and pieui login. Also covers PieUI style isolation — fixing a card's UI in the component instead of global CSS (globals.css), and why global style edits cause cross-component regressions.
metadata:
  author: pie-team
  version: 1.2.0
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

- `pieui registry dev [--port N] [--api-server URL]` runs the standalone `PiePreviewRoot` harness (no app layout). It fetches the card envelope from `--api-server`'s `/api/content/` and renders the matching component from `piecomponents/registry.ts`. This is the frontend half of `pie card show` and `pie card show-mcp`.
- `pieui registry build [--out DIR]` builds the harness as a static export for serving by backend `pie`.
- The harness is generated under `<project>/.pie/registry/` and is a **separate Next app with its own `.next` build cache** — independent of the main app's `.next`.
- To render a card: a `pie` backend must serve it (run `pie card show <EXPR>`, or set it via the `pie card show-mcp` MCP). The card name in the content JSON must exist in `registry.ts`; `data` keys are camelCase. See the complete guide (`skills/SKILL.md`, section 10) for the end-to-end flow and the agent side-panel recipe.

**Preview troubleshooting:**

- Persistent `Parsing CSS source code failed` / stale build error after the source is fixed → the harness's own cache is stale: `rm -rf <project>/.pie/registry/.next` and restart (clearing the main app `.next` does nothing).
- `pieui registry …` prints general help / acts unknown → the project-local `pieui` predates `registry`; use the **global** `pieui` (e.g. `~/.bun/bin/pieui`) or `pieui self-upgrade`.
- Preview shows the full app / a loading splash instead of the bare card → the harness didn't start and something fell back to a plain `next dev`; verify a `pieui registry dev` process owns the port.

## Style isolation: fix the card, not `globals.css`

**A card's appearance is owned by the card.** When a card looks wrong, change that
card's own JSX/classes — never reach into `app/globals.css` (or any shared
stylesheet) to "fix" one component from the outside. Global edits are the single
most common source of unforeseen regressions in PieUI apps: one selector silently
restyles every other card that happens to match.

**Why global "fixes" backfire:**

- **Blast radius.** A rule like `button { … }`, `.flex.items-center { … }`, or a
  bare utility override leaks app-wide. The card you were looking at gets fixed;
  three cards you never opened break. The damage shows up far from the diff.
- **Fragile coupling.** Deep descendant selectors
  (`.some-card > div:nth-child(3) input`) hard-code another component's internal
  DOM. Any markup change inside that component — including a library upgrade —
  silently breaks the override with no compile error.
- **Specificity wars.** Each global patch raises specificity, so the next fix
  needs an even heavier selector or `!important`. The stylesheet ossifies.
- **Invisible ownership.** The styling lives nowhere near the component, so the
  next developer editing the card can't see why it looks the way it does and
  re-breaks it.

**The rule (cards you own):** style locally. These cards use Tailwind utility
classes in `className` (and occasional inline `style`) right in the component's
`.tsx`. Put every visual change there. Co-locate any unavoidable CSS with the
component and scope it to the card's own `data-component-id` / root class so it
cannot escape. Do not add component-specific rules to `globals.css`.

**`globals.css` is only for genuinely global concerns:** Tailwind layers, theme
tokens / CSS variables, `:root` / `html.light` palettes, `@font-face`, keyframes,
and app-wide resets. If a change targets one card, it does not belong here.

**The one legitimate exception — third-party widgets you cannot edit** (e.g. the
Aurora swap widget under `.near-swap-widget-card`): you can't touch their internal
JSX, so a scoped override block is the only option. When you must do this:

- Scope **every** selector under the widget's root class / `data-component-id`
  (`.near-swap-widget-card [aria-label="Sell"] …`) so nothing leaks out.
- Never write a bare element or utility selector that can match app-wide.
- Add a comment explaining what upstream markup you're overriding and why, so the
  coupling is visible when the library changes.

This exception is for **vendored components only**. For a card in `piecomponents/`,
the answer is always: edit the component.

See `references/style-isolation.md` for the decision tree and worked examples.

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
- `references/style-isolation.md` — keeping component fixes out of `globals.css`

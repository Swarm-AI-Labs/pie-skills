---
name: pieui-cli
description: Use for tasks involving the pieui CLI, including Next.js app scaffolding, card/page generation, component registry workflows, remote component sync, and pieui login.
metadata:
  author: pie-team
  version: 1.0.0
---

# PieUI CLI Skill

Use this skill when the user asks to run, debug, or automate the `pieui` CLI.

## Scope

- `pieui create`, `create-pie-app`, `create-pieui`
- `pieui init`
- `pieui card add`
- `pieui card remote push|pull|list|remove`
- `pieui page add`
- `pieui list`, `list-events`, `add-event`, `remove`
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

Use `--io` to add socket IO support, `--ajax` to add AJAX support. Both flags are optional and combinable.

## Defaults

- Prefer `bunx pieui ...` for globally available CLI usage.
- In source repo development, `bun src/cli.ts ...` is acceptable.
- Keep generated files under app conventions (`piecomponents/`, `app/<path>/page.tsx`).

## Prerequisites Checklist

1. Bun installed.
2. In target app: Next.js project exists (for page/card commands).
3. For remote storage commands, credentials are available (`pieui login` or env/config present).

## Workflow

1. Identify whether user needs app bootstrap, component/page scaffolding, remote sync, or diagnostics.
2. Run narrow command with explicit args.
3. Validate generated files and command output.
4. For remote operations, confirm user/project scope before push/remove.
5. Report changed files and follow-up command.

## Safety Rules

- `card remote remove` is destructive; require explicit user intent.
- `add-event` edits component method maps; verify target component exists first.
- Do not run `postbuild --append` unless user asks for built-in component merge behavior.

## References

Read command details in:

- `references/command-cheatsheet.md`

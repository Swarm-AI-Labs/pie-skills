# pie-skills — Agent Skills Index

This repository contains agent skills for the Pie ecosystem CLIs.
Install with:

```bash
npx skills add git@github.com:<owner>/pie-skills.git
```

## Available skills

| Skill | Description |
|---|---|
| `pie-cli` | Python `pie` CLI — project scaffolding, web/page/card commands, card preview/rendering (`card show`, `show-mcp`), the database layer (`db`: Beanie/MongoDB), Cloudflare Worker, taskrun, remote component sync, and login/config. |
| `pieui-cli` | TypeScript `pieui` CLI — Next.js app bootstrapping, card/page generation, Storybook previews, TS/Python metadata sync, preview registry, remote sync, debug logging, self-upgrade, and login. |

## When to use each skill

- **pie-cli** — use when working inside a Python Pie backend project (`uv run pie ...`).
- **pieui-cli** — use when working inside a Next.js / Bun frontend project (`bunx pieui ...`).
- **Previewing / rendering a single card** (`pie card show`, `pieui registry dev`, the `pie card show-mcp` MCP) spans both — see the complete guide's §10.

## Structure

Each skill contains:

```
skills/<name>/
  SKILL.md                  # Agent instructions
  references/               # Supporting docs
    command-cheatsheet.md
    db-cheatsheet.md        # (pie-cli) full `pie db …` surface
  scripts/                  # Helper automation scripts
  metadata.json             # Version and author info
```

Repo-root `scripts/check-cheatsheet-sync.sh` is an advisory drift check (see TESTING.md T8-00).

# pie-skills — Agent Skills Index

This repository contains agent skills for the Pie ecosystem CLIs.
Install with:

```bash
npx skills add git@github.com:<owner>/pie-skills.git
```

## Available skills

| Skill | Description |
|---|---|
| `pie-cli` | Python `pie` CLI — project scaffolding, web/page/card commands, remote component sync, and login/config. |
| `pieui-cli` | TypeScript `pieui` CLI — Next.js app bootstrapping, card/page generation, component registry, remote sync, and login. |

## When to use each skill

- **pie-cli** — use when working inside a Python Pie backend project (`uv run pie ...`).
- **pieui-cli** — use when working inside a Next.js / Bun frontend project (`bunx pieui ...`).

## Structure

Each skill contains:

```
skills/<name>/
  SKILL.md                  # Agent instructions
  references/               # Supporting docs
    command-cheatsheet.md
  scripts/                  # Helper automation scripts
  metadata.json             # Version and author info
```

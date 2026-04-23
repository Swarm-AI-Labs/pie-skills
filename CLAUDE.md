# pie-skills — Claude guidance

This repository provides two CLI skills for the Pie ecosystem.

## Skill routing

| User intent | Use skill |
|---|---|
| Working with Python `pie` CLI, `uv run pie`, backend cards/pages | `pie-cli` |
| Working with TypeScript `pieui` CLI, `bunx pieui`, Next.js components | `pieui-cli` |

## Key differences

- `pie` is Python-based; run with `uv run pie` inside the pie repo, or just `pie` if installed globally.
- `pieui` is TypeScript/Bun-based; run with `bunx pieui` or `bun src/cli.ts` in development.
- Card types differ between the two CLIs — always consult the relevant SKILL.md before generating commands.

## Reading order

1. Read the appropriate `skills/<name>/SKILL.md` for the full workflow.
2. Consult `skills/<name>/references/command-cheatsheet.md` for exact command syntax.

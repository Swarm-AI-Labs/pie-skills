# pie CLI command cheatsheet

Run from the `pie` repository:

```bash
uv sync --python 3.14
uv run pie --help
```

## Project

```bash
uv run pie create my-app
```

## Web

```bash
uv run pie web web:web
uv run pie web web:web verify
uv run pie web web:web build
```

## Cards

Four card types are available: `simple`, `complex`, `container`, `complex-container`.

```bash
# simple — single data prop
uv run pie card add simple MyCard

# complex — data + children props
uv run pie card add complex MyCard

# container — single content slot
uv run pie card add container MyCard

# complex-container — array content slot; add --io and/or --ajax as needed
uv run pie card add complex-container MyCard --io --ajax

uv run pie card list
uv run pie card view MyCard
uv run pie card list-events MyCard
uv run pie card push MyCard
uv run pie card pull alice/MyCard
uv run pie card remote list --user alice --project demo
uv run pie card remote pull MyCard
```

## Pages

```bash
uv run pie page add dashboard
uv run pie page add admin/users
uv run pie page view dashboard
```

## Auth

```bash
uv run pie login
```

## Notes

- `PIE_PROJECT` overrides `PIE_PROJECT_SLUG`.
- `card add-event` exists but is not implemented for Python AST editing.


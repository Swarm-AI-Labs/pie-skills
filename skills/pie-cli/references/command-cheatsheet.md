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

## Preview / render a card

```bash
# Interactive: serve one card from an ephemeral backend + open the registry harness.
# EXPR evaluates to a Card; namespace includes pages/components/*.py card classes.
uv run pie card show 'MyCard(name="m", title="Hi")'
uv run pie card show 'ColCard([ACard(), BCard(a=1)])' --frontend-port 3210 --route /
#   flags: --frontend-dir --frontend-port(3000) --backend-port(auto) --route(/) --pm --no-open

# Headless MCP render server for agents (needs: pip install 'pieui[mcp]').
uv run pie card show-mcp                                # stdio (default)
uv run pie card show-mcp --http 9009                    # streamable-HTTP
uv run pie card show-mcp --mirror http://127.0.0.1:8000 # mirror a live `pie card show`
uv run pie card show-mcp --no-frontend                  # json + ajax tools only
#   MCP tools: render_card(card?, format=json|html|screenshot), attach(url), detach(),
#              list_ajax(), call_ajax(pathname, data?)
#   render_card: prefer a card EXPRESSION over a {…} JSON string (JSON is often
#   coerced to a dict and rejected). format=json echoes; html/screenshot need the
#   harness + a linked frontend (`pie init`).
```

The frontend side is `pieui registry dev|build` (the `PiePreviewRoot` harness under
`<frontend>/.pie/registry/`, with its **own `.next`** cache). If a stale CSS/build
error persists after fixing source: `rm -rf <frontend>/.pie/registry/.next` and restart.

## Auth

```bash
uv run pie login
```

## Notes

- `PIE_PROJECT` overrides `PIE_PROJECT_SLUG`.
- `card add-event` exists but is not implemented for Python AST editing.


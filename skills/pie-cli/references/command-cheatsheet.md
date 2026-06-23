# pie CLI command cheatsheet

Run from the `pie` repository (or any backend project with `pie` installed):

```bash
uv sync            # pyproject requires Python >=3.10 (pie repo pins 3.14 for dev)
uv run pie --help
```

Top-level commands: `web`, `card`, `page`, `create`, `init`, `login`, `db`, `self-upgrade`,
`taskrun`, `cloudflare`. (`db` is covered in [`db-cheatsheet.md`](db-cheatsheet.md).)

## Project setup

```bash
uv run pie create my-app          # scaffold a new Pie project
uv run pie init                   # initialise pie in an existing project (pages/, components/, web.py) + link a frontend
uv run pie self-upgrade           # upgrade the installed pie package
uv run pie self-upgrade --pm uv   # force package manager: uv | poetry | pip
```

## Web

`pie web` takes a `module:attribute` path to a `Web` instance (not a fixed `web:web`).

```bash
uv run pie web app:web            # run the app  (module `app`, attribute `web`)
uv run pie web app:web verify     # lint / verify the app
uv run pie web app:web build      # build static JSON from the Web app
```

## Cards

Four card types: `simple`, `complex`, `container`, `complex-container`.
**Naming divergence:** pie uses `container`; the frontend `pieui` calls the same type `simple-container`.

```bash
# add — type is positional; flags --io / --ajax / --input combine
uv run pie card add simple MyCard
uv run pie card add complex MyCard
uv run pie card add container MyCard
uv run pie card add complex-container MyCard --io --ajax
uv run pie card add simple MyCard --input          # typed `stored` (input) variant
uv run pie card add simple MyCard --from MyCard    # port from frontend piecomponents / metadata .json / .py / card name

# inspect
uv run pie card list
uv run pie card view MyCard
uv run pie card list-events MyCard                 # static parse of get_supported_events()
uv run pie card add-event MyCard update            # NOTE: not implemented for Python sources
uv run pie card dump-metadata MyCard               # full PieMetadata JSON → stdout
uv run pie card dump-metadata MyCard -o meta.json  # → file (--out)
uv run pie card check-sync MyCard                  # diff backend ↔ frontend metadata; prompts for frontend path if unset
```

### Centrifuge channels & events (backend-only — no pieui mirror)

```bash
uv run pie card channels                 # list Centrifuge cards + channels (web:app default)
uv run pie card channels app:web --live  # reconcile against a running Centrifugo server
uv run pie card channels --json          # machine-readable output
uv run pie card emit MyCard update some-channel             # publish a card event
uv run pie card emit MyCard update some-channel --data '{"x":1}' --web app:web
```

### Remote storage

```bash
uv run pie card remote list                        # list components for configured user/project
uv run pie card remote list --user alice --project demo
uv run pie card remote push MyCard                 # upload Python card (python/ envelope)
uv run pie card remote pull MyCard                 # download into components dir
uv run pie card remote history MyCard              # revision history + diffs
uv run pie card remote history MyCard --page 2 --per-page 20 --from 3 --to 7
uv run pie card remote public MyCard               # publish alias  r/<user>/MyCard
uv run pie card remote private MyCard              # revoke public alias
uv run pie card remote remove MyCard               # delete from storage (all revisions)

# pull by reference (current project / another project / public alias)
uv run pie card pull MyCard
uv run pie card pull alice/MyCard
uv run pie card pull r/alice/MyCard
```

> Older builds also expose top-level `pie card push` / `pie card pull` aliases; prefer the
> `pie card remote …` forms above.

## Pages

```bash
uv run pie page add dashboard
uv run pie page add admin/users
uv run pie page view dashboard
uv run pie page ajax dashboard add refresh         # add an AJAX handler to the page class
uv run pie page ajax dashboard remove refresh      # remove it
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

## Database (Beanie / MongoDB)

`pie db …` scaffolds and manages the MongoDB layer (Documents, indexes, seeds, migrations,
document↔card bridges). Backend-only — **no `pieui db` mirror.** Full reference:
[`db-cheatsheet.md`](db-cheatsheet.md).

```bash
uv run pie db init        # scaffold the db layer
uv run pie db status      # ping MongoDB, list collections + counts
uv run pie db model add User --field email:str --timestamps --index email,unique
uv run pie db migrate     # run migrations forward
```

## Cloudflare Worker (backend-only — no pieui mirror)

Scaffold / run / deploy a Cloudflare Python Worker (Pyodide) serving the pie ASGI app.
Needs `pip install 'pieui[cloudflare-worker]'`; deploy needs `CLOUDFLARE_API_TOKEN`.

```bash
uv run pie cloudflare init                 # write src/worker.py + wrangler.jsonc
uv run pie cloudflare init --app app:web --name my-worker
uv run pie cloudflare dev                  # run locally via Pywrangler
uv run pie cloudflare dev --port 8787
uv run pie cloudflare deploy               # deploy to Cloudflare
```

## Task runner

```bash
uv run pie taskrun local  app:web my/page myAction [params...]   # run a page task in-process
uv run pie taskrun remote app:web my/page myAction [params...]   # run it via curl against a server
```

## Auth

```bash
uv run pie login
```

## Notes

- `pie web` expects `module:attribute`; the common convention is `app:web` (varies per project).
- Auth/config precedence: `PIE_USER_ID` / `PIE_API_KEY` / `PIE_PROJECT` env vars override
  `.pie/config.json`; `PIE_PROJECT` overrides `PIE_PROJECT_SLUG`. With env vars set, pie may
  search parent dirs for config — run from the project root or pass all three explicitly.
- Card type `container` (pie) == `simple-container` (pieui).
- `card add-event` exists but is **not** implemented for Python AST editing.
- Backend-only command groups with no `pieui` mirror: `db`, `cloudflare`, `card channels`, `card emit`.

# pie db — database layer (Beanie / MongoDB) cheatsheet

`pie db …` scaffolds and manages the backend's MongoDB layer (Beanie ODM): Documents,
indexes, data import/export, seeds, document↔card bridges, and migrations.

**Backend-only divergence:** there is **no `pieui db` mirror** — MongoDB/Beanie has no
frontend analog. Never suggest a `pieui db …` command.

Run from the backend project root (where `.pie/config.json` and the `db/` layer live):

```bash
uv run pie db --help
```

Most commands need a reachable MongoDB (connection from project config / `.env`).

---

## Bootstrap & health

```bash
uv run pie db init        # scaffold + wire up the Beanie/MongoDB layer (one-time)
uv run pie db check       # static health/drift checks for the db layer (no DB needed)
uv run pie db status      # ping MongoDB, list collections + document counts
uv run pie db shell       # REPL with Beanie initialised and Documents loaded
```

## Indexes

```bash
uv run pie db index list            # list declared indexes (all models)
uv run pie db index list <Model>    # ...for one model
uv run pie db index sync            # create declared indexes on MongoDB (runs init_beanie)
```

## Data: pull / export / import

```bash
# Generate a Document class from a live collection by sampling docs
uv run pie db pull <collection>
uv run pie db pull users --as User --limit 200
#   --as <Name>     Document class name (default: PascalCase of collection)
#   --limit <int>   how many documents to sample (default: 50)

# Export a collection to JSON
uv run pie db export <collection>                 # → stdout
uv run pie db export users --out users.json       # -o also works

# Import documents from a JSON array file (--in is REQUIRED)
uv run pie db import <collection> --in users.json
```

## Seeds

```bash
uv run pie db seed new <Name>     # scaffold a seed script
uv run pie db seed run            # run all seed scripts
uv run pie db seed run <Name>     # run one seed
```

## Models (Documents)

```bash
uv run pie db model add <Name> \
  --field email:str --field age:int \
  --collection users \
  --timestamps \
  --index email,unique
#   --field <name:type>      repeatable; typed field
#   --collection <name>      collection name
#   --timestamps             add created/updated timestamp fields
#   --index <field[,unique]> repeatable; declare an index

uv run pie db model list                  # list Document models
uv run pie db model view <Name>           # print a Document's source
uv run pie db model remove <Name>         # delete a Document + unregister it

# Add a field to an existing Document
uv run pie db model add-field <Model> <name:type[=default]>
uv run pie db model add-field User phone:str=""
#   --index                  make the field indexed
#   --unique                 make the field unique
#   --original-field <name>  for BackLink fields: the Link field on the other Document

# Rename a Document (updates file, class, collection, registry)
uv run pie db model rename <Old> <New>
uv run pie db model rename User Account --collection accounts
#   --collection <name>      new collection name
```

## Document ↔ card bridges

Inject `to_ui_<card>_card` / `list_ui_<card>_cards` methods so a Document can render as a card.

```bash
uv run pie db card add <Document> <Card>      # add bridge methods
uv run pie db card remove <Document> <Card>   # remove the bridge
uv run pie db card list <Document>            # list bridges on a Document
```

## Migrations

```bash
uv run pie db migration new <Name>     # scaffold a migration
uv run pie db migration list           # list migrations
uv run pie db migrate                  # run all pending migrations forward
uv run pie db migrate --distance 1     # run N migrations forward
uv run pie db rollback                 # roll back all migrations
uv run pie db rollback --distance 1    # roll back N migrations
#   --distance <int>   how many to run/roll back (default: 0 = all)
```

---

## Notes

- `pie db init` is a one-time scaffold; rerunning is safe but won't clobber custom code.
- `model remove` / `rename` and `migrate` / `rollback` mutate code and/or data —
  treat as explicit-intent operations and confirm before running in shared environments.
- `index sync` and any `status`/`shell`/`seed`/`migrate` command require a live MongoDB.

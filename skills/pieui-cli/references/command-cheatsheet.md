# pieui CLI command cheatsheet

Run from any project with CLI installed:

```bash
pieui --help
```

Or via Bun:

```bash
bunx pieui --help
```

## App bootstrap

```bash
bunx pieui create my-app
bunx pieui create-pie-app my-pie-app
bunx pieui create-pieui my-pie-app
```

## Init + generation

Four card types: `simple`, `complex`, `simple-container`, `complex-container` (default when omitted).

```bash
bunx pieui init

# simple — only a data prop
bunx pieui card add simple StatusCard

# complex — data + children props
bunx pieui card add complex FeedCard

# simple-container — data + single content slot
bunx pieui card add simple-container LayoutCard

# complex-container — data + content[] array (default); add --io / --ajax as needed
bunx pieui card add complex-container DashCard --io --ajax

# omit type → defaults to complex-container
bunx pieui card add MyCard

bunx pieui page add chat
```

## Local inspection and edits

Valid list filters: `all` (default), `simple`, `complex`, `simple-container`, `complex-container`.

```bash
bunx pieui list
bunx pieui list all
bunx pieui list simple
bunx pieui list complex
bunx pieui list simple-container
bunx pieui list complex-container
bunx pieui list-events StatusCard
bunx pieui add-event StatusCard refresh
bunx pieui remove StatusCard
```

## Remote storage

```bash
bunx pieui login
bunx pieui card remote list
bunx pieui card remote list --user alice --project demo
bunx pieui card remote push StatusCard
bunx pieui card remote pull StatusCard
bunx pieui card remote remove StatusCard
```

## Build manifest

```bash
bunx pieui postbuild --src-dir src --out-dir dist
bunx pieui postbuild --src-dir src --out-dir dist --append
```

## Notes

- `card add` default type is `complex-container` when omitted.
- `page add` expects a path and writes `app/<path>/page.tsx`.


#!/usr/bin/env bash
# Advisory drift-check: warn when a CLI command is missing from the cheatsheets.
#
# - pie: top-level commands are read live from `pie --help` (argparse choices),
#   then each is checked against the pie-cli cheatsheets.
# - pieui: checked against a curated command list (pieui's help is freeform, so a
#   curated list is more reliable than scraping). Update PIEUI_CMDS on CLI changes.
# Card/db subcommands are spot-checked. ALWAYS exits 0 — this is a nudge, not a gate.
#
# Usage:  bash scripts/check-cheatsheet-sync.sh
# `pie` on PATH is optional (its section is skipped when absent).

set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
miss=0
note() { printf '  - %s\n' "$1"; miss=$((miss + 1)); }
in_files() { local tok="$1"; shift; grep -qsF -- "$tok" "$@"; }

pie_sheets=(
  "$root/skills/pie-cli/references/command-cheatsheet.md"
  "$root/skills/pie-cli/references/db-cheatsheet.md"
)
ui_sheet="$root/skills/pieui-cli/references/command-cheatsheet.md"

echo "== pie =="
if command -v pie >/dev/null 2>&1; then
  cmds=$(pie --help 2>/dev/null | grep -oE '\{[a-z,-]+\}' | head -1 | tr -d '{}' | tr ',' ' ')
  for c in $cmds; do
    in_files "pie $c" "${pie_sheets[@]}" || note "pie $c — not documented in pie-cli cheatsheets"
  done
  for sub in channels emit dump-metadata check-sync show show-mcp \
             "remote history" "remote public" "remote private" "remote remove"; do
    in_files "card $sub" "${pie_sheets[@]}" || note "pie card $sub — missing"
  done
else
  echo "  (pie not on PATH — skipped)"
fi

echo "== pieui =="
PIEUI_CMDS=(login create create-pie-app create-pieui init postbuild self-upgrade
            "registry dev" "registry build"
            "card add" "card list" "card pull" "card view" "card remove"
            "card list-events" "card add-event" "card add-story" "card generate-preview"
            "card dump-metadata" "card check-sync"
            "card remote list" "card remote push" "card remote pull" "card remote remove"
            "card remote history" "card remote public" "card remote private"
            "page add" "page view" "page ajax")
for c in "${PIEUI_CMDS[@]}"; do
  in_files "pieui $c" "$ui_sheet" || in_files "$c" "$ui_sheet" || note "pieui $c — not in pieui cheatsheet"
done

echo
[ "$miss" -eq 0 ] && echo "OK — no obvious cheatsheet gaps." || echo "$miss possible gap(s) above (advisory)."
exit 0

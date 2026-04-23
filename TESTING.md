# pie-skills — Complete Test Guide

This guide covers everything needed to verify that the `pie-skills` repository is correct, that the skills install and activate properly, and that every documented command in both `pie-cli` and `pieui-cli` skills behaves as described.

---

## Test tiers

| Tier | What it covers | Tools |
|---|---|---|
| T1 — Static validation | Repo structure, SKILL.md schema, cheatsheet syntax | Shell, Python, yaml linter |
| T2 — Installation | `npx skills add` installs correctly for each agent | npx, Claude, Cursor |
| T3 — Skill routing | Agent picks the right skill for a given prompt | Manual + agent prompts |
| T4 — pie CLI smoke | Every `pie` command runs without error | pytest (existing), shell |
| T5 — pieui CLI smoke | Every `pieui` command runs without error | Bun test, shell |
| T6 — Card generation | All 4 card types generate the correct files | pytest, Bun test |
| T7 — Remote storage | Push/pull/list flows against the real API | pytest (step2-remote), manual |
| T8 — Agent accuracy | Commands in SKILL.md match CLI reality | Diff script + manual |
| T9 — Regression | Skills still activate correctly after CLI version bumps | CI gate |

---

## Environment setup

### Common requirements

```bash
node >= 18          # for npx skills
git
```

### pie (Python) requirements

```bash
python >= 3.14
uv                  # pip install uv
cd /path/to/pie
uv sync --python 3.14
```

Required `.env` for remote tests:

```env
PIE_USER_ID=your-user-id
PIE_PROJECT=your-project-slug
PIE_API_KEY=your-api-key
PIE_COMPONENTS_DIR=pages/components   # optional, this is the default
```

### pieui (TypeScript) requirements

```bash
bun >= 1.0
cd /path/to/pieui
bun install
bun run build:cli
```

---

## T1 — Static validation

These checks do not require running either CLI. They validate that the skills repo itself is well-formed.

### T1-01 — Required files present

**Preconditions:** `pie-skills` repo is cloned locally.

**Steps:**

```bash
cd pie-skills
# Root level
test -f README.md     && echo "PASS" || echo "FAIL: README.md missing"
test -f AGENTS.md     && echo "PASS" || echo "FAIL: AGENTS.md missing"
test -f CLAUDE.md     && echo "PASS" || echo "FAIL: CLAUDE.md missing"

# pie-cli skill
test -f skills/pie-cli/SKILL.md                         && echo "PASS" || echo "FAIL"
test -f skills/pie-cli/metadata.json                    && echo "PASS" || echo "FAIL"
test -f skills/pie-cli/references/command-cheatsheet.md && echo "PASS" || echo "FAIL"
test -d skills/pie-cli/scripts                          && echo "PASS" || echo "FAIL"

# pieui-cli skill
test -f skills/pieui-cli/SKILL.md                         && echo "PASS" || echo "FAIL"
test -f skills/pieui-cli/metadata.json                    && echo "PASS" || echo "FAIL"
test -f skills/pieui-cli/references/command-cheatsheet.md && echo "PASS" || echo "FAIL"
test -d skills/pieui-cli/scripts                          && echo "PASS" || echo "FAIL"
```

**Expected:** All `PASS`.

---

### T1-02 — SKILL.md frontmatter is valid YAML and contains required fields

**Steps:**

```bash
pip install pyyaml --break-system-packages

python3 - <<'EOF'
import sys
import yaml

for skill in ["pie-cli", "pieui-cli"]:
    path = f"skills/{skill}/SKILL.md"
    with open(path) as f:
        content = f.read()

    # Extract YAML block between first two ---
    parts = content.split("---")
    if len(parts) < 3:
        print(f"FAIL [{skill}]: no frontmatter found")
        continue

    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        print(f"FAIL [{skill}]: YAML parse error: {e}")
        continue

    required = ["name", "description", "metadata"]
    for field in required:
        if field not in fm:
            print(f"FAIL [{skill}]: missing frontmatter field '{field}'")
        else:
            print(f"PASS [{skill}]: '{field}' present")

    meta_required = ["author", "version"]
    for mf in meta_required:
        if mf not in fm.get("metadata", {}):
            print(f"FAIL [{skill}]: missing metadata.{mf}")
        else:
            print(f"PASS [{skill}]: metadata.{mf} present")
EOF
```

**Expected:** All `PASS`.

---

### T1-03 — metadata.json is valid JSON and contains required fields

```bash
python3 - <<'EOF'
import json

for skill in ["pie-cli", "pieui-cli"]:
    path = f"skills/{skill}/metadata.json"
    with open(path) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"FAIL [{skill}]: invalid JSON: {e}")
            continue

    for field in ["author", "version", "description"]:
        status = "PASS" if field in data else "FAIL"
        print(f"{status} [{skill}]: field '{field}'")
EOF
```

**Expected:** All `PASS`.

---

### T1-04 — All card types are documented in both SKILL.md files

```bash
python3 - <<'EOF'
checks = {
    "pie-cli": ["simple", "complex", "container", "complex-container"],
    "pieui-cli": ["simple", "complex", "simple-container", "complex-container"],
}

for skill, types in checks.items():
    with open(f"skills/{skill}/SKILL.md") as f:
        content = f.read()
    for t in types:
        status = "PASS" if f"`{t}`" in content else "FAIL"
        print(f"{status} [{skill}]: card type '{t}' documented")
EOF
```

**Expected:** All `PASS`.

---

### T1-05 — Cheatsheet commands match SKILL.md scope

**Steps:** Manually verify that every command group listed in the `## Scope` section of each SKILL.md has at least one example in `references/command-cheatsheet.md`.

**Checklist — pie-cli:**

| Scope item | In cheatsheet? |
|---|---|
| `pie create` | `uv run pie create my-app` |
| `pie web ...` | All three variants present |
| `pie page add\|view` | Both present |
| `pie card add` (all 4 types) | All 4 present with comments |
| `pie card list\|view\|list-events` | Present |
| `pie card push\|pull` | Present |
| `pie card remote list\|pull` | Present with `--user`/`--project` flags |
| `pie login` | Present |

**Checklist — pieui-cli:**

| Scope item | In cheatsheet? |
|---|---|
| `pieui create\|create-pie-app\|create-pieui` | All 3 aliases present |
| `pieui init` | Present |
| `pieui card add` (all 4 types + default) | All 4 + no-type example present |
| `pieui page add` | Present |
| `pieui list` (all 5 filters) | All 5 filters present |
| `pieui list-events\|add-event\|remove` | All present |
| `pieui card remote push\|pull\|list\|remove` | All 4 present |
| `pieui postbuild` (with and without `--append`) | Both variants present |
| `pieui login` | Present |

**Expected:** All items checked.

---

## T2 — Installation

### T2-01 — Install from GitHub SSH

**Preconditions:** SSH key configured for GitHub. Repository pushed to `git@github.com:Swarm-AI-Labs/pie-skills.git`.

```bash
npx skills add git@github.com:Swarm-AI-Labs/pie-skills.git
```

**Expected:** No errors. Check that skills were installed:

```bash
npx skills list
# Should show: pie-cli, pieui-cli
```

---

### T2-02 — Install from GitHub HTTPS

```bash
npx skills add https://github.com/Swarm-AI-Labs/pie-skills.git
```

**Expected:** Same as T2-01.

---

### T2-03 — Verify installed skill file content

```bash
# Exact path depends on the agent and OS. Typical Claude Code location:
cat ~/.claude/skills/pie-cli/SKILL.md | head -10
# Should show correct frontmatter: name, description, metadata
```

**Expected:** Frontmatter present and correct, not truncated.

---

### T2-04 — Reinstall is idempotent

**Steps:** Run `npx skills add` twice with the same URL.

**Expected:** Second run succeeds without error. No duplicate skill entries. Content is up to date.

---

## T3 — Skill routing

These tests verify that the agent correctly identifies which skill to use based on the user's prompt. Run inside a Claude session or equivalent agent with pie-skills installed.

### Routing test prompts

For each prompt below, confirm the agent reads `pie-cli/SKILL.md` or `pieui-cli/SKILL.md` (not both, not neither) and uses commands from the correct cheatsheet.

| Test ID | Prompt | Expected skill |
|---|---|---|
| T3-01 | "create a new card called TradeCard" (in Python pie project) | `pie-cli` |
| T3-02 | "add a StatusCard component" (in Next.js pieui project) | `pieui-cli` |
| T3-03 | "run `uv run pie card list`" | `pie-cli` |
| T3-04 | "run `bunx pieui list`" | `pieui-cli` |
| T3-05 | "push my card to remote storage" (pie Python context) | `pie-cli` |
| T3-06 | "push my card to remote storage" (Next.js context) | `pieui-cli` |
| T3-07 | "what card types are available?" (pie context) | `pie-cli` — should list `simple`, `complex`, `container`, `complex-container` |
| T3-08 | "what card types are available?" (pieui context) | `pieui-cli` — should list `simple`, `complex`, `simple-container`, `complex-container` |

**Pass criterion:** Agent uses only commands from the correct skill. No hallucinated flags or commands.

---

### T3-09 — Agent does NOT confuse card types between CLIs

**Prompt (in pieui context):** "Add a container card"

**Expected:** Agent uses `simple-container` or `complex-container` — NOT `container` (which is pie-only).

**Prompt (in pie context):** "Add a container card"

**Expected:** Agent uses `container` — NOT `simple-container` (which is pieui-only).

---

## T4 — pie CLI smoke tests

Run from inside the `pie` repository with `uv sync --python 3.14` already done.

### T4-01 — Run existing unit test suite

```bash
cd /path/to/pie
uv run pytest tests/ -v
```

**Expected:** All tests pass. Key test files:

| File | Covers |
|---|---|
| `tests/step1-local/test_step1_local.py` | Card add, page add, web commands — no network |
| `tests/step2-remote/test_step2_remote.py` | Remote storage API with mocked HTTP |
| `tests/step5-regression/test_step5_regression.py` | Regression scenarios |

---

### T4-02 — `pie create` smoke test

```bash
cd /tmp && uv run pie create smoke-test-app
ls smoke-test-app/
# Expected: web.py, pages/main.py, pages/components/
```

---

### T4-03 — `pie card add` — all 4 types

```bash
cd /tmp/smoke-test-app
export PIE_COMPONENTS_DIR=pages/components

uv run pie card add simple        SimpleCard
uv run pie card add complex       ComplexCard
uv run pie card add container     ContainerCard
uv run pie card add complex-container BigCard --io --ajax

ls pages/components/
# Expected: simple_card.py, complex_card.py, container_card.py, big_card.py
```

**Pass criterion:** Each file exists and is not empty. Each file contains a Python class.

---

### T4-04 — `pie card list`

```bash
uv run pie card list
# Expected: lists at least SimpleCard, ComplexCard, ContainerCard, BigCard
```

---

### T4-05 — `pie card view`

```bash
uv run pie card view SimpleCard
# Expected: prints name, props table — no stack trace
```

---

### T4-06 — `pie card list-events`

```bash
uv run pie card list-events BigCard
# Expected: prints events table or "no events" — no stack trace
```

---

### T4-07 — `pie web` verify

```bash
cd /tmp/smoke-test-app
uv run pie web web:web verify
# Expected: exit 0 or informative output — no unhandled exception
```

---

### T4-08 — `pie page add` and `pie page view`

```bash
uv run pie page add dashboard
uv run pie page add admin/users
uv run pie page view dashboard
# Expected: file created at pages/dashboard.py (or equivalent), view prints source
```

---

### T4-09 — `pie card add-event` — expect graceful not-implemented message

```bash
uv run pie card add-event SimpleCard on_click 2>&1
# Expected: prints a message about not being implemented — does NOT crash with unhandled exception
```

---

## T5 — pieui CLI smoke tests

Run from inside the `pieui` repository with `bun install` and `bun run build:cli` already done.

### T5-01 — Run existing unit tests

```bash
cd /path/to/pieui
bun test src/tests/
```

**Expected:** All tests pass. Key files:

| File | Covers |
|---|---|
| `src/tests/registry.test.ts` | Component registry logic |
| `src/tests/registry-builtin.test.ts` | Built-in component registration |
| `src/tests/cardMetadata.test.ts` | Card metadata parsing |
| `src/tests/use-client-directive.test.ts` | Client directive detection |
| `src/tests/storage.test.ts` | Storage helpers |

---

### T5-02 — `pieui create` smoke test

```bash
cd /tmp
bunx pieui create smoke-pieui-app
ls smoke-pieui-app/
# Expected: Next.js project structure, package.json present
```

---

### T5-03 — `pieui init` in existing project

```bash
cd /tmp/smoke-pieui-app
bunx pieui init
# Expected: no error; pieui config/setup files written
```

---

### T5-04 — `pieui card add` — all 4 types

```bash
cd /tmp/smoke-pieui-app

bunx pieui card add simple        StatusCard
bunx pieui card add complex       FeedCard
bunx pieui card add simple-container LayoutCard
bunx pieui card add complex-container DashCard --io --ajax

ls piecomponents/
# Expected: StatusCard.tsx, FeedCard.tsx, LayoutCard.tsx, DashCard.tsx (or similar)
```

**Pass criterion:** Each file exists. Each file contains a React component export. No duplicate content between files.

---

### T5-05 — `pieui card add` default type

```bash
bunx pieui card add DefaultCard
# Expected: generates complex-container type (check file content for content[] prop)
grep "content" piecomponents/DefaultCard.tsx
```

---

### T5-06 — `pieui list` — all filter variants

```bash
bunx pieui list
bunx pieui list all
bunx pieui list simple
bunx pieui list complex
bunx pieui list simple-container
bunx pieui list complex-container
# Expected: each exits 0. Filtered variants return only matching types.
```

---

### T5-07 — `pieui list-events` and `pieui add-event`

```bash
bunx pieui list-events DashCard
bunx pieui add-event DashCard refresh
bunx pieui list-events DashCard
# Expected: 'refresh' event appears in second list-events output
```

---

### T5-08 — `pieui remove`

```bash
bunx pieui remove DefaultCard
ls piecomponents/ | grep DefaultCard
# Expected: DefaultCard no longer present
```

---

### T5-09 — `pieui page add`

```bash
bunx pieui page add chat
bunx pieui page add admin/users
ls app/chat/         # Expected: page.tsx present
ls app/admin/users/  # Expected: page.tsx present
```

---

### T5-10 — `pieui postbuild`

```bash
bunx pieui postbuild --src-dir src --out-dir dist
cat dist/pieui.components.json
# Expected: valid JSON listing registered components
```

---

## T6 — Card generation accuracy

These tests verify that generated card files match the structure implied by the skill documentation.

### T6-01 — pie card type field presence

For each generated pie card, verify the expected props exist in the file:

```bash
python3 - <<'EOF'
from pathlib import Path

checks = {
    "pages/components/simple_card.py":           ["data"],
    "pages/components/complex_card.py":          ["data", "children"],
    "pages/components/container_card.py":        ["data", "content"],
    "pages/components/big_card.py":              ["data", "content"],  # complex-container
}

for filepath, expected_fields in checks.items():
    try:
        content = Path(filepath).read_text()
        for field in expected_fields:
            status = "PASS" if field in content else "FAIL"
            print(f"{status} [{filepath}]: field '{field}' present")
    except FileNotFoundError:
        print(f"FAIL [{filepath}]: file not found")
EOF
```

---

### T6-02 — pieui card --io flag wires IO support

```bash
grep -q "useSocketioSupport\|io" piecomponents/DashCard.tsx && echo "PASS: --io flag applied" || echo "FAIL: --io not reflected in file"
```

---

### T6-03 — pieui card --ajax flag wires AJAX support

```bash
grep -q "ajax\|setUiAjaxConfiguration" piecomponents/DashCard.tsx && echo "PASS: --ajax flag applied" || echo "FAIL: --ajax not reflected in file"
```

---

## T7 — Remote storage flows

These tests require a live `.env` with valid credentials. Always run against a dev/staging project, not production.

### T7-01 — pie card push and remote list

```bash
cd /tmp/smoke-test-app
# Ensure .env has PIE_USER_ID, PIE_PROJECT, PIE_API_KEY

uv run pie card push SimpleCard
# Expected: exit 0, no HTTP error

uv run pie card remote list
# Expected: SimpleCard appears in output
```

---

### T7-02 — pie card remote pull

```bash
uv run pie card remote pull SimpleCard
# Expected: file downloaded or confirmed up to date — no error
```

---

### T7-03 — pie card pull (by user/component reference)

```bash
# Replace with a card that exists in storage under another user
uv run pie card pull <user-id>/SimpleCard
# Expected: file written to PIE_COMPONENTS_DIR
```

---

### T7-04 — pieui card remote push and list

```bash
cd /tmp/smoke-pieui-app
bunx pieui login   # confirm credentials
bunx pieui card remote push StatusCard
bunx pieui card remote list
# Expected: StatusCard appears in list
```

---

### T7-05 — pieui card remote pull

```bash
bunx pieui card remote pull StatusCard
# Expected: file written to piecomponents/, no error
```

---

### T7-06 — pieui card remote remove (destructive — test in isolation)

```bash
# Only run against a test component. Confirm before running.
bunx pieui card remote remove StatusCard
bunx pieui card remote list
# Expected: StatusCard no longer in list
```

---

## T8 — Agent accuracy checks

These tests verify that what the SKILL.md tells agents to do actually works when executed.

### T8-01 — Every command in pie cheatsheet exits successfully

```bash
cd /tmp/smoke-test-app

# Run each command from the cheatsheet and check exit code
commands=(
  "card list"
  "card view SimpleCard"
  "card list-events SimpleCard"
  "page view dashboard"
  "web web:web verify"
)

for cmd in "${commands[@]}"; do
  uv run pie $cmd > /dev/null 2>&1
  echo "$? — pie $cmd"
done
# Expected: all exit codes are 0
```

---

### T8-02 — Every command in pieui cheatsheet exits successfully

```bash
cd /tmp/smoke-pieui-app

commands=(
  "list"
  "list all"
  "list simple"
  "list-events StatusCard"
)

for cmd in "${commands[@]}"; do
  bunx pieui $cmd > /dev/null 2>&1
  echo "$? — pieui $cmd"
done
```

---

### T8-03 — SKILL.md env var list matches CLI config loading

Verify that every env var listed in the Prerequisites section of `pie-cli/SKILL.md` is actually read by the CLI:

```bash
grep -n "PIE_USER_ID\|PIE_PROJECT\|PIE_API_KEY\|PIE_COMPONENTS_DIR" \
  /path/to/pie/pie/config.py
# Expected: all 4 vars referenced
```

---

### T8-04 — Verify `pie card add-event` is documented as not-implemented

```bash
grep -i "not implemented\|add-event" skills/pie-cli/SKILL.md
# Expected: safety rule present warning about add-event not being implemented
```

---

## T9 — Regression gate

Run after any CLI version bump in `pie` or `pieui` to ensure skills stay accurate.

### T9-01 — Command list diff

After a version bump, regenerate the command list from each CLI's help output and diff against the cheatsheet:

```bash
# pie
uv run pie --help 2>&1 > /tmp/pie-help.txt
diff <(grep "uv run pie" skills/pie-cli/references/command-cheatsheet.md | sed 's/.*pie /pie /') \
     /tmp/pie-help.txt
# Review diff for new or removed commands
```

```bash
# pieui
bunx pieui --help 2>&1 > /tmp/pieui-help.txt
diff <(grep "bunx pieui" skills/pieui-cli/references/command-cheatsheet.md | sed 's/.*pieui /pieui /') \
     /tmp/pieui-help.txt
```

**Action on failure:** Update the relevant SKILL.md, cheatsheet, and README.

---

### T9-02 — Card type list diff

```bash
# pie — extract types from source
python3 -c "
import ast, sys
with open('/path/to/pie/pie/__main__.py') as f:
    src = f.read()
tree = ast.parse(src)
for node in ast.walk(tree):
    if isinstance(node, ast.Assign):
        for t in ast.walk(node):
            if isinstance(t, ast.Set):
                print([ast.literal_eval(e) for e in t.elts])
" 2>/dev/null

# pieui — extract from args.ts
grep "validTypes" /path/to/pieui/src/code/args.ts
```

Compare output against the Card types table in each SKILL.md.

---

### T9-03 — Skill routing still correct after prompt format changes

Re-run the T3 routing prompts after any agent update. Log results in a test run record.

---

## Quick smoke run (all tiers, ~5 minutes)

```bash
# 1. Static validation
python3 tests/validate_skills.py   # create this from T1-02/T1-03/T1-04 scripts above

# 2. Installation
npx skills add git@github.com:Swarm-AI-Labs/pie-skills.git

# 3. pie CLI
cd /path/to/pie && uv run pytest tests/ -v --tb=short

# 4. pieui CLI
cd /path/to/pieui && bun test src/tests/

# 5. Card generation check
cd /tmp/smoke-test-app && uv run pie card add simple QuickCheck
cd /tmp/smoke-pieui-app && bunx pieui card add QuickCheck
```

---

## Test result record template

```
Date:
Tester:
pie version:        (pyproject.toml version field)
pieui version:      (package.json version field)
pie-skills commit:  (git rev-parse HEAD)

T1 Static:          PASS / FAIL — notes:
T2 Install:         PASS / FAIL — notes:
T3 Routing:         PASS / FAIL — notes:
T4 pie smoke:       PASS / FAIL — X/Y tests passed
T5 pieui smoke:     PASS / FAIL — X/Y tests passed
T6 Card generation: PASS / FAIL — notes:
T7 Remote storage:  PASS / FAIL — notes:
T8 Accuracy:        PASS / FAIL — notes:
T9 Regression:      PASS / FAIL / SKIPPED
```

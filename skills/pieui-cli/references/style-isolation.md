# Style isolation — keep component changes out of global styles

The recurring failure mode in PieUI apps: a UI bug in one card gets "fixed" by
adding a rule to `app/globals.css` instead of editing the card. It looks like it
works, then something unrelated breaks later. This doc is the decision procedure
and the worked examples for doing it right.

## Decision tree

When a card looks wrong:

1. **Is it a card you own (lives in `piecomponents/`)?**
   → Edit the component's `.tsx`. Change its Tailwind classes / inline style.
   Done. Do not open `globals.css`.

2. **Is it a third-party / vendored widget whose JSX you cannot edit?**
   (e.g. Aurora swap widget.)
   → A scoped override in `globals.css` is acceptable — but **every** selector
   must be nested under the widget's root class / `data-component-id`, and you
   must comment what upstream markup you're overriding.

3. **Is the change actually global** (a theme token, a palette, a font, a
   keyframe, an app-wide reset)?
   → `globals.css` is the right place. This is what it's for.

If you're reaching for `globals.css` and the answer to (1) is "yes", stop — you're
about to create a regression. The fix belongs in the component.

## Why a global "fix" is a trap

- **Blast radius.** `button { border-radius: 0 }` to square one card's button
  squares every button in the app. The diff touches one line; the breakage is
  everywhere and shows up far from where you were looking.
- **Fragile coupling.** `.x-card > div:nth-child(3) input` encodes another
  component's internal DOM. A refactor or library bump inside that component
  shifts the children and the rule silently mis-targets — no compile error, no
  test failure, just a visual break someone finds in production.
- **Specificity creep.** Each global patch is a heavier selector than the last.
  Eventually everything is `!important` and no one can predict what wins.
- **Lost ownership.** Styling that lives 1500 lines away in `globals.css` is
  invisible to the next person editing the card. They "fix" the component, not
  realizing a global rule fights them, and the cycle repeats.

## Worked examples

### ❌ Wrong — global edit to fix one card

`app/globals.css`:
```css
/* Make the prediction card's Yes button green */
button.bg-sw-gray-800 {
  background: #05df72;
}
```
This matches `button.bg-sw-gray-800` **anywhere** in the app — every other card
using that utility just turned green.

### ✅ Right — edit the card

`piecomponents/PredictionMarketEntryCard/ui/PredictionEntryActions.tsx`:
```tsx
<button className="… bg-[#05df72] …">Yes</button>
```
The change is local, visible to the next editor, and cannot affect any other card.

---

### ❌ Wrong — deep descendant override of a card you own

`app/globals.css`:
```css
.holdings-card > div:nth-child(2) > span {
  font-weight: 600;
}
```
Coupled to the card's exact DOM shape. Reorder the JSX and it breaks invisibly.

### ✅ Right — set it where the element is rendered

In the component:
```tsx
<span className="font-semibold">{value}</span>
```

---

### ✅ Acceptable — scoped override of a vendored widget you cannot edit

The Aurora swap widget's internal markup isn't ours to change, so overrides live
in `globals.css` — but **every** selector is nested under `.near-swap-widget-card`
so nothing leaks, and a comment records the coupling:

```css
/* Aurora widget (vendored): the Sell/Buy amount inputs ship with a divider we
   don't want per Figma 50:2668. Scoped to the widget root so no app-wide leak. */
.near-swap-widget-card [aria-label="Sell"] > div:first-child,
.near-swap-widget-card [aria-label="Buy"]  > div:first-child {
  border-bottom: none;
}
```

Rules for this exception:
- Prefix **every** selector with the widget root (`.near-swap-widget-card …` or
  `[data-component-id="…"] …`). Never a bare `input`, `button`, or utility class.
- Comment the upstream structure you depend on, so the coupling is visible when
  the library updates.
- Use it **only** for components you genuinely cannot edit. A card in
  `piecomponents/` never qualifies.

## Quick self-check before adding any CSS to `globals.css`

- Does this rule target one card? → It belongs in that card, not here.
- Could this selector match elements in other cards? → Scope it or move it.
- Am I encoding another component's internal DOM? → Edit that component instead.
- Is this a theme token / palette / font / keyframe / reset? → OK, it's global.

When in doubt: the most isolated change that fixes the bug is the right one.
A local component edit has a blast radius of one card; a global rule has a blast
radius of the whole app.

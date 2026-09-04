---
name: CAROS — Counselor OS
description: A school counseling platform built as the pastoral mark book the school already keeps.
colors:
  stock: "#FAFBF7"
  stock-2: "#F1F4EE"
  stock-3: "#E8ECE4"
  band: "#DCE8DA"
  band-2: "#CFDECC"
  rule: "#C4D3C2"
  rule-2: "#AFC3AE"
  rule-3: "#93AB93"
  ink: "#131D26"
  ink-2: "#33454F"
  ink-3: "#4F636B"
  ink-4: "#54666D"
  margin: "#B0271C"
  tier-urgent: "#A81E12"
  tier-urgent-bg: "#F6E4E1"
  tier-checkin: "#96490F"
  tier-checkin-bg: "#F5E9DC"
  tier-review: "#7A6113"
  tier-review-bg: "#F2EEDC"
  tier-monitor: "#4A5A62"
  tier-monitor-bg: "#E9EDEC"
  tier-good: "#1C6B45"
  tier-good-bg: "#E0EFE4"
  dom-academic: "#1F4FA8"
  dom-attendance: "#7E5A08"
  dom-engagement: "#4A44B8"
  dom-behaviour: "#9C441A"
  dom-teacher: "#9B1F2E"
  dom-university: "#0B6B60"
  baseline: "#8FB4A4"
  school-primary: "#004D43"
  school-accent: "#EFE6D2"
  school-on-accent: "#131D26"
typography:
  display:
    fontFamily: "Archivo Narrow, Arial Narrow, ui-sans-serif, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.004em"
  headline:
    fontFamily: "Archivo Narrow, Arial Narrow, ui-sans-serif, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.004em"
  title:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13.2px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "normal"
  body:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "12.5px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Archivo Narrow, Arial Narrow, ui-sans-serif, system-ui, sans-serif"
    fontSize: "10.5px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.085em"
  figure:
    fontFamily: "Spline Sans Mono, ui-monospace, SF Mono, Menlo, monospace"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.028em"
rounded:
  sm: "1px"
  md: "2px"
  lg: "2px"
  xl: "3px"
  dot: "50%"
spacing:
  row: "30px"
  topbar: "60px"
  tight: "6px"
  sm: "9px"
  md: "14px"
  lg: "22px"
components:
  button-primary:
    backgroundColor: "{colors.school-primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "9px 14px"
    height: "44px"
    typography: "{typography.label}"
  button-ghost:
    backgroundColor: "{colors.stock}"
    textColor: "{colors.ink-2}"
    rounded: "{rounded.md}"
    padding: "9px 14px"
    height: "44px"
  button-dark:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.stock}"
    rounded: "{rounded.md}"
    padding: "9px 14px"
    height: "44px"
  card:
    backgroundColor: "{colors.stock}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "20px"
  tier-stamp:
    textColor: "{colors.tier-urgent}"
    rounded: "{rounded.sm}"
    padding: "2px 6px 2px 5px"
    typography: "{typography.label}"
  tally-cell:
    backgroundColor: "{colors.stock}"
    textColor: "{colors.ink}"
    padding: "10px 16px"
    typography: "{typography.figure}"
---

# Design System: CAROS — Counselor OS

## Overview

**Creative North Star: "The Register" — the form tutor's hand-ruled pastoral mark book.**

The thesis is one sentence, and every decision below descends from it: *the caseload is the ledger the school already keeps.* A baseline is a run of marks. A signal is the cell where the run breaks. A counselor reads across a row until it stops being regular, opens that cell, and can say afterwards exactly why she looked there. The interface is not a dashboard reporting on a ledger; it is the ledger.

That commits the surface to green-bar accounting stock rather than paper-white, because the alternating band is doing real work — it tracks a row across eighty-seven names and eight week-columns without a single divider. It commits to a red margin rule as the one accent on the sheet, to cyan-green ruling, to blue-black printed ink, and to corners that are cut rather than rounded, because paper is cut. It commits to three sans faces and **no serif anywhere**.

The last point is the load-bearing refusal. The obvious rendition of a ledger — cream stock, a high-contrast serif, a terracotta accent — is precisely the look a generative tool converges on, and escaping that convergence was the entire brief. Cream and serif are the confirmed anti-reference. So is the dashboard vocabulary that preceded this world: the greeting header, the row of stat tiles, the grid of same-size rounded cards, the coloured severity chip.

**Key Characteristics:**
- Green-bar stock, never cream; the banding is functional, not decorative.
- One accent — the red margin rule. Everything else is ink, ruling and tier.
- Three sans faces with three jobs. No serif exists in this system.
- Near-zero radius (1–3px). Elevation is a rule, not a shadow.
- State is material before it is colour: every tier carries a printed non-colour mark.
- Figures are monospaced and tabular, always. A column of numbers that does not align is not a ledger.

## Colors

The palette is three layers, and only one of them may ever be themed. This split is the system's central rule and is enforceable by grep.

### Primary

- **ACS Pine** (`{colors.school-primary}`): the letterhead. Masthead, sidebar field, links, focus ring, active nav bar, primary button. Themed per partner school. It is the only colour in the system that changes between schools.
- **Bone** (`{colors.school-accent}`): the crest, the demonstration-data stamp, the active-item bar, count badges. A **fill only** — it must never be set as type. It always ships with `school-on-accent` as its foreground.

  Replaced Sand Viper Gold on 2026-09-04. The gold was doing four unrelated jobs at once — school crest, student avatars, letterhead furniture and the synthetic-data marker — so it had stopped signifying any of them. Bone reads 7.9:1 on the letterhead field, against the gold's 5.71:1, but only **1.19:1 against the stock** where the gold managed 1.70:1. Every bone fill that lands on the sheet therefore carries a `rule-2` hairline; the five on-stock offer and sign-off stamps were amended when the token changed. Cool accents were tested first and rejected: pine is a dark blue-green, so a blue or a pine tint has luminance contrast against it but no hue contrast, and the demonstration-data stamp visibly receded.

### Secondary

- **Margin Red** (`{colors.margin}`): the single vertical rule down the left of the sheet, and the caret colour in every input. It appears once per screen. That rarity is what makes it read as a printed margin rather than as an alert.

### Tertiary — the five triage tiers

Product logic, not decoration. Fixed across every school forever.

- **Urgent** (`{colors.tier-urgent}`) · solid mark · letter **U** · route now under school policy.
- **Check-in** (`{colors.tier-checkin}`) · half mark · letter **C** · within two school days.
- **Review** (`{colors.tier-review}`) · hatched mark · letter **R** · this week.
- **Monitor** (`{colors.tier-monitor}`) · open mark · letter **M** · no action required.
- **Positive** (`{colors.tier-good}`) · tick mark · letter **P** · acknowledge.

Concern domains (`dom-academic` through `dom-university`) and the personal baseline band (`{colors.baseline}`) are semantic on the same terms and are equally unthemable.

### Neutral — the material layer

- **Ledger Stock** (`{colors.stock}`): the sheet itself. Cards, table grounds, the tally line.
- **The Desk** (`{colors.stock-2}`): the surface the sheet sits on — the page behind the content pane.
- **Recessed Field** (`{colors.stock-3}`): inset wells and unfilled controls.
- **The Green Bar** (`{colors.band}`), **Band Under Cursor** (`{colors.band-2}`): the alternating stripe, and its hover/selected state. Also the text-selection colour.
- **Hairline / Divider / Column Rule** (`{colors.rule}`, `{colors.rule-2}`, `{colors.rule-3}`): three weights of ruling, light to heavy. `rule-3` is reserved for the heavy rule under a column head.
- **Printed Ink** (`{colors.ink}` → `{colors.ink-4}`): blue-black, printed rather than sprayed.

### Named Rules

**The Letterhead Rule.** The school colour is letterhead, never data. No `--school-*` token may appear inside a severity, track or domain definition. A counselor who changes schools must not have to relearn what a colour means, and CAROS must not look like a different product at every partner.

**The Short Ramp Rule.** `ink-4` sits only ~1.8 steps from `ink`, because it must still clear 4.5:1 on the green band. In print, metadata recedes by size and weight, never by washing out. Do not "fix" the ramp by lightening it back out — hierarchy here is typographic.

**The Paired Fill Rule.** Every themed or saturated fill ships with its own on-colour (`school-accent` / `school-on-accent`). A fill that flips between renditions beside a hardcoded `#fff` is the exact bug this prevents.

**The Both-Grounds Rule.** Every text token must pass AA against **both** the stock and the green band before it ships. This single constraint is what eliminated 174 measured contrast failures structurally rather than patching them one chip at a time.

**The Measured-Ratio Rule.** `ink(hex)` derives a foreground by measuring contrast, never by thresholding luminance — a mid-tone brand colour can fail white *and* ledger ink at 4.5. This is what keeps an arbitrary partner hex accessible instead of making each new school a fresh accessibility bug.

## Typography

**Apparatus Font:** Archivo Narrow (with Arial Narrow, system sans)
**Content Font:** Libre Franklin (with system sans)
**Figure Font:** Spline Sans Mono (with SF Mono, Menlo)

**Character:** Three faces, three jobs, and no overlap between them. Archivo Narrow is condensed, so it absorbs the wide tracking a printed label wants without eating the row — it is the pre-printed matter of the form: column heads, letterhead, totals, tier stamps. Libre Franklin is everything a person reads in sentences. Spline Sans Mono carries every figure, date, ratio and audit line, tabular by default. The classes are `.stamp`, `.prose` and `.fig` respectively.

### Hierarchy

- **Display** (Archivo Narrow 600, 22px, 1.2): a case subject's name at the head of their file.
- **Headline** (Archivo Narrow 600, 17px, 1.25): the rail's date line, section leads.
- **Title** (Libre Franklin 600, 13.2px, 1.25): a student's name in the ledger stub.
- **Body** (Libre Franklin 400, 12.5px, 1.5): all read content. Measure capped around 760px at the page head.
- **Label** (Archivo Narrow 600, 10.5px, +0.085em, uppercase): the `.appa` / `.sechead` / `.tallyl` apparatus label — column heads and section marks.
- **Figure** (Spline Sans Mono 600, 17px, −0.028em, tabular): every number that means something.

### Named Rules

**The No-Serif Rule.** There is no serif in this system, at any size, for any purpose. Fraunces and Newsreader were removed outright. A serif here would land the design exactly on the anti-reference it exists to refuse.

**The No-Eyebrow Rule.** Nothing sits above an `<h1>`. The page head is a heading and a description, nothing else; `head(ti, de)` takes exactly two arguments. A kicker is banned outright rather than discouraged.

**The Apparatus Floor Rule.** 10px is the floor for an uppercase letterspaced apparatus label, and nothing in the file is smaller. Anything read as a sentence sets at 11.5px or above. A mechanical detector will still report 10–11.5px apparatus as undersized; that is a recorded, deliberate exception to keep the printed register, and it applies only to labels, never to prose.

**The Sentence Case Rule.** Uppercase belongs on the short apparatus label and stops there. A sentence never sets in caps — not a disclosure control, not a note beside a label, not a screen-reader continuation (`.lg-new .sr` explicitly resets it, because some readers spell all-caps out letter by letter).

## Layout

The counselor's first viewport is one continuous ruled sheet, full bleed: no greeting, no stat tiles. A fixed 252px letterhead sidebar, a 60px sticky masthead, then the ledger, with a right-hand rail carrying the day.

The ledger's own grid is fixed (`table-layout:fixed`): a 34px selection gutter, a 40px margin column closed by the 2px red rule, a 322px name stub, then the week columns dividing whatever remains evenly so the run rules across the sheet rather than crowding into the right margin, then an 88px "today" column separated by a heavier rule and a 112px last-contact column. One ruled row is 30px (`--row`); rows render at 1.75 of that. The column head sticks under the masthead while 87 names scroll beneath it, and goes static below 980px where the table gets its own horizontal scroller.

A content page sets to `--page-max` (1640px) and centres in the pane. **The sheet is exempt and runs full bleed** (`.pagewrap-full`, applied to the three caseload views): more width there is more weeks of the run on screen, which is the argument of the product rather than a layout preference. The earlier 1140/1180px caps were invisible at 1440 and left 488px of dead sheet at 1920 — on the caseload the ledger was using 44% of the display.

Rhythm is the row, not an 8pt grid. Groups are separated by ruling and by the tier group-line, never by gaps and never by cards. Content panes cap prose around 760px.

Above 1500px a two-column card grid gains columns rather than wider cards — three or six children go three across, four go four across, and grids of two or five are left alone because there is no extra column for them that would not be a hole. The rule counts children with `:has()`, so it reads the grid it is changing; at 785px per card the figure had drifted a long way from its label.

Below 640px the tally line breaks to two columns and drops its dividing rules; below 820px the masthead's palette opener stands down so the page title takes the width. 87 quiet rows are revealed in chunks of 25 rather than all at once, because `content-visibility` gives no layout containment to `display:table-row`.

## Elevation & Depth

**There are no shadows on the sheet.** `--sh-xs`, `--sh-sm` and `--sh-md` are all literally `none`. A sheet of paper does not float above a desk; it lies on it. Depth is carried by ruling weight (three steps), by the alternating band, and by tonal separation between the stock and the desk behind it.

The only elements that genuinely leave the page get a real shadow, and only those: a modal, the command palette, a toast.

### Shadow Vocabulary

- **Overlay** (`0 10px 22px -8px rgba(19,29,38,.30), 0 2px 6px -2px rgba(19,29,38,.16)`): modals and the palette.
- **Lifted overlay** (`0 20px 40px -12px rgba(19,29,38,.36), 0 4px 10px -4px rgba(19,29,38,.18)`): the topmost layer only.

### Named Rules

**The Rule-Not-Shadow Rule.** Declare elevation once, and on this surface it is always a rule. If a component needs to feel separated, give it ruling or a band — never a border under a soft shadow, and never a glow. A zero-offset coloured halo is decoration and has been removed wherever it appeared.

## Shapes

Paper is cut, not rounded: `1px` for small controls and marks, `2px` for buttons, cards and inputs, `3px` at the largest. `--r-pill` is `2px` — a deliberate trap-disarming alias, since a world with no pills should not have a token that promises one. `--r-dot` (50%) survives only on printed dots and the spinner ring.

Marks are geometry, never illustration: the tier stamps are a solid block, a half block, a hatch, an open outline and a tick. Empty states use three geometric ledger marks — a run of ticks with no break (`steady`), one filled cell beside a waiting dashed cell (`open`), and two branches of exactly equal weight (`fork`). No figure-bearing or sketch-style artwork exists in this system.

## Components

### Buttons

- **Shape:** cut corners (2px), 44px minimum height on every variant including `.btn-sm`.
- **Type:** the apparatus face at 13.5px/600 — a button is a printed instruction.
- **Primary** (`.btn-p`): school primary ground with its derived on-colour, 9px 14px.
- **Ghost** (`.btn-g`): stock ground, `rule-3` border, `ink-2` text. Hover fills to the green band and darkens to full ink — the row lighting up under the hand.
- **Dark** (`.btn-d`) and **Urgent** (`.btn-u`): full-ink and tier-urgent grounds for irreversible actions.
- **Active:** `scale(.985)`. **Disabled:** 45% with no transform.

### The tier stamp (signature component)

The system's defining mark and the reason severity survives greyscale, a projector and colour-blindness. It is a **glyph plus a letter**, printed in the margin column beside the name: `■ U`, `◧ C`, `▨ R`, `□ M`, `☑ P`. The colour is a reinforcement, never the carrier. It replaced a family of coloured chips that failed AA at all five levels, and it is why avatars no longer encode tier — they were a five-way severity gradient rendering white on salmon at 2.63:1.

### The tally line

The ledger's summary form, and the replacement for the row of hero-metric tiles this product used to open on. A single ruled strip on stock, closed on all four sides (a `rule-3` head rule above, `rule-2` on the other three edges), divided into cells by hairlines: apparatus label, then the figure in the mono face at 17px, then a note. It takes **no colour argument** on purpose — the rows it replaced painted figures in tier colours those figures had no claim on, which spends the one vocabulary the product cannot afford to make decorative.

### Cards and containers

- Stock ground, 1px `rule` border, 2px radius, **no shadow**, 20px internal padding.
- Hover on an interactive card moves the border to `rule-3` and the ground to the band. Nested cards do not exist here.

### Inputs

Stock ground, `rule-2` border, 2px radius, ink text with `ink-4` placeholder. Focus drops the outline and takes a school-primary border with a 3px `brand-3` ring. The caret is margin red in every field — the browser's own furniture brought onto the sheet.

### Navigation

The sidebar is the letterhead field: school primary, with `on-letterhead` for item text and `on-letterhead-2` for icons and secondary lines. The active item takes a 2px school-accent bar in the gutter and a 9% white wash — a bar, not a glow. Tier counts on the field use the three lifted marks (`t-urgent-field`, `t-checkin-field`, `t-good-field`), which are the tier hues raised to clear a dark ground, since printed tier ink is invisible there.

### Browser surfaces

Selection is the band. The caret is margin red. Scrollbars are `rule-2` on transparent, thin. Focus is a 2px school-primary outline at 2px offset with a 4px stock halo so it reads on the band as well as on the sheet. Figures are tabular everywhere by default.

## Do's and Don'ts

### Do:

- **Do** put every figure in `.fig` and every printed label in `.stamp`. A number in the content face is a bug.
- **Do** reach for the tally line when a screen needs to summarise. It is the system's answer to that need.
- **Do** verify any new text colour against **both** stock and band, compositing the full ancestor chain to an opaque ground in both directions. An auditor that composites in only one direction over-reports on translucent overlays and under-reports on alpha text — this has already produced a phantom 120-failure report.
- **Do** give a new partner school exactly three values (`primary`, `accent`, `paper`) and let `applySchool()` and `ink()` derive the rest.
- **Do** keep the demonstration-data stamp visible whenever a real school is applied. It is gated on the school, not on a debug flag, so it cannot be switched off for a cleaner screenshot.
- **Do** separate groups with ruling and banding.
- **Do** check a layout change at 1920 and 2560, not only at 1440. Every cap in this file was set at a width where it did nothing visible.

### Don't:

- **Don't** introduce a serif. Not for a quote, not for a letter, not for a display line.
- **Don't** put a kicker, eyebrow or section number above a heading.
- **Don't** open a screen with a row of hero-metric tiles — big figure, small label, supporting stat, accent colour. That template was removed from seven surfaces in this build and should not return.
- **Don't** let a `--school-*` token into a tier, track, domain or baseline definition.
- **Don't** set the school accent as text anywhere. It is a fill with dark ink on it.
- **Don't** put a bone fill on the stock without a hairline — at 1.19:1 the block has no edge of its own.
- **Don't** add a shadow to anything that is not a modal, the palette or a toast — and never a coloured glow.
- **Don't** use a coloured chip to carry severity. The tier stamp carries it.
- **Don't** set a sentence in uppercase, and don't set an apparatus label below 10px.
- **Don't** use a sparkline, progress ring or soft rounded rectangle as a stand-in for content. A trace on this sheet is real data against a real baseline band.
- **Don't** widen the night ledger past `html[data-role="student"]` without a product decision. The tokens are ready; the choice is not made.

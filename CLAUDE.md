# CAROS — Counselor OS

A single-file prototype: `index.html`, ~7,300 lines, vanilla JS, **no build step, no backend, no test suite**. Five role surfaces in one shell — Counselor OS, Teacher, Student ("Career OS"), Parent (Family portal), Mentor Hub. Product description in `README.md`.

This file describes the build as it stands after Phase 8 (2026-09-03). It was rewritten from the running code, not from intention — the version it replaces described a build that had been overwritten, and reading it as truth cost real work twice.

## The authorities, in order

| File | What it owns |
|---|---|
| `PRODUCT.md` | Product truth — users, positioning, constraints, and the anti-fabrication rules. |
| `DESIGN.md` | **The visual system, written from this code.** Tokens, type, the named rules, the do's and don'ts. Read before any colour, type, shape or layout decision. |
| `.impeccable/surfaces/index-html.md` | The direction contract — the thesis, the per-school theming rule, the open questions. `DESIGN.md` is the built expression of it. |
| `../PHASES.md` | The P0–P8 work plan and what each phase decided. Historical now, but it carries the reasoning. |
| `.impeccable/design.json` | Machine-readable sidecar for `DESIGN.md` — tonal ramps, shadows, motion, renderable component snippets. |

`.impeccable/review/` holds the Phase 8 screenshot round, desktop and mobile, daylight and night ledger.

## Running it

```bash
python3 -m http.server 8099 --directory .
```

Or use the Browser pane with the `caros-static` config in `.claude/launch.json` — never `bash` for a server. `S` and `draw()` are globals, so drive state directly rather than clicking:

```js
S.role='counselor'; S.cv='si-why'; draw();
```

`S.cv` is the counselor's view, `S.tv` teacher, `S.sv` student, `S.pv` parent, `S.mv` mentor. `S.open` is an open case file, `S.previewGrade` the parent/student grade switcher.

**Demo from the deployed build, not from localhost.** The debug audit panel is gated to `localhost` / `?debug`, so a local demo puts a "UX Audit" pill over every screen.

`?school=<id>` switches the letterhead at runtime (`acs`, `demo`).

## The three invariants

These are not style preferences. Breaking one is a product regression.

1. **The school colour is letterhead, never data.** No `--school-*` token may appear inside a severity, track or domain definition. Grep-enforced; it is checked. Full reasoning in `DESIGN.md` under The Letterhead Rule.
2. **The five triage tiers are product logic.** Never collapse them, never re-theme them per school, never carry severity on a coloured chip — the tier stamp carries it.
3. **All student data is synthetic, over a real school's name.** The visible demonstration-data stamp is therefore a shipping requirement, gated on a school being applied rather than on a debug flag so it cannot be switched off for a cleaner screenshot. Never fabricate testimonials, customers, outcomes, benchmarks, pricing or press.

Gamification is allowed on the student side and nowhere else (reversed 2026-09-02). Do not "fix" it back toward the old prohibition.

## How the file is organised

Roughly: tokens and CSS (1–560), icons and the school record (850–1030), data (1050–1500), shared render helpers (1500–1830), counselor views (1860–2800), nav (2810–2910), the sheet (3000–3200), remaining role surfaces, then the router, `bind()` and the debug panel at the end.

### Tokens

Three layers, declared at `:root` around line 34 and documented in the comment above them: **material** (stock, band, ruling, ink, the three faces, radius), **semantic** (the five tiers, concern domains, the baseline band — never themed), **letterhead** (written by `applySchool()`, themed per school).

A **bridge alias block** sits at the end of that declaration (`--panel`, `--card`, `--inkSoft`, `--inkMute`, `--lineSoft`, `--teal`, `--urgent`…), mapping the pre-Register vocabulary onto Register tokens. Its comment says "nothing here is meant to survive P8"; roughly 350 call sites still read through it, so **it does survive, deliberately**. Retiring it is a mechanical rename with no visual change, worth doing behind a computed-style diff, and it is not urgent — every alias resolves to the correct Register token today. Counting `var(--inkMute)` tells you about naming, not about rendering.

### The night ledger

`@media (prefers-color-scheme:dark)` at line ~141, and it is **gated to `html[data-role="student"]`**. The student surface is the only one with a dark palette; the counselor stays on paper in both schemes by design. Widening it is an open product decision, and the tokens are already written for it. A dark-mode audit run on the counselor will look like the media query is broken. It is not.

### Motion

`draw()` rebuilds the whole tree on every state change, so **any entry animation replays on every click** unless suppression catches it.

- `place()` (line ~6471) fingerprints role, view, open file, grade, tab, and the panels that replace themselves wholesale (`letter`, `cpQ`, `cpLoad`, `discoverStage`, `psActiveSystem`, `onbStep`). A changed fingerprint is an *arrival*. Filtering, sorting, expanding and typing are not.
- On a non-arrival, `.still` lands on `#root` and suppresses inline `animation:rise/fade/pop` plus the `.rise` / `.fade` / `.pop` classes. **A new entry animation must be covered by those selectors.**
- Exempt on purpose: toast, modal, palette, spinner, shimmer — they *are* the state change.
- Anything animating **to** a value from a non-default attribute (the baseline chart's `stroke-dashoffset`) needs its end state landed explicitly in the `.still` rule, or suppression makes it invisible.
- `prefers-reduced-motion` zeroes **both duration and delay**. Do not drop the delay reset: staggered content uses `backwards` fill, so a delay without it leaves content blank for up to a second.

### Icons and marks

`IP` is the single ~40-icon Feather-style set; `ic(name, size)` renders it. There is no second bespoke set. Icons are drawn, never emoji.

Three families of mark do the real semantic work, and none of them is an icon:

- `runMark(kind)` — one cell in a student's run: `kept` (filled, inside band), `soft` (outlined), `break` (a cross in margin red — the single accent, spent on the one cell that is the reason the sheet exists), `none`.
- `tierStamp(prio)` / `pchip(prio)` — the tier as mark plus letter (`U C R M P`). Colour reinforces; the glyph carries.
- `ILLUS` + `art()` / `moment()` — three geometric empty-state marks: `steady` (a run with no break), `open` (one filled cell, one waiting dashed cell), `fork` (two branches of exactly equal weight — and the copy says so; do not let a later change emphasise one branch).

### Shared render helpers

Use these rather than composing a new one-off:

- `head(title, description)` — the page head. **Two arguments.** It used to take an eyebrow; a kicker above an `<h1>` is banned outright now.
- `tally(items)` — the ledger's summary line, `[label, figure, note]` per cell. This is the system's answer to "summarise this screen" and it replaced the hero-metric tile row on seven surfaces. It takes no colour on purpose.
- `empty(title, why, action)` — an empty state that says why the absence is correct.
- `chip`, `av`, `stTag`, `sparkline`, `spin`, `ic`.
- `prioCounts()` — the one caseload truth. Do not derive a second count.

### The command palette

⌘K, or the masthead button. `palCommands(role)` builds, `palFilter()` ranks (exact prefix > word start > substring), `palPaint()` repaints **only the results list** so focus and caret survive.

1. **The student list is scoped to the role.** Counselor sees all 87; teacher sees their class and their verb is *log a concern*, not *read the file*; parent and student see their own record; mentor has no student search. Wiring every role to the same 87 rows builds exactly the permission leak the co-pilot promises in writing it never makes.
2. **Never call `draw()` per keystroke.** A full draw happens once, when a command runs.

`roleNav(role)` is the single source for the grade-conditional parent/student navs — sidebar, parent tab bar and palette all read it. There used to be three hand-maintained copies. Do not add a fourth.

The global key listener is attached once at the bottom of the script, **not** in `bind()` — `bind()` re-runs on every draw and would stack a listener each time.

### Routing

The counselor router is a chain of `else if(S.cv===…)` around line 6500. **Order matters and has bitten before**: a broad early condition silently shadowed `S.cv==="files"`, so the sidebar's "360° student files" opened the caseload for weeks while the function sat there working. Add new routes below the catch-alls, and check no earlier branch already claims the key.

Nav entries live in `CATS` (three expandable categories), `SYSNAV` (Tools & system) and `DIMS` (the ten dimension pages, all routed through `vDim`). A view with no entry in one of those is unreachable no matter how finished it is.

## Verifying a change

There is no test suite, so verification is browser-driven and cheap to run:

```js
// every counselor view + every case file, watching for a thrown render
let errs=[]; S.role='counselor';
for(const cv of ['cohort-schedule','si-why','app-season','app-flow','files','app-letter','command']){
  try{S.cv=cv;S.open=null;draw();}catch(e){errs.push(cv+': '+e.message);}
}
for(const c of S.cases){try{S.open=c.id;draw();}catch(e){errs.push(c.id+': '+e.message);}}
errs;
```

For contrast, **composite the full ancestor chain to an opaque ground in both directions.** An auditor that does not will lie to you both ways: it over-reports on translucent light overlays (treating `rgba` backgrounds as white) and under-reports on alpha text. This has already produced one phantom 120-failure report on a surface that was clean.

The mechanical detector is at `.claude/skills/impeccable/scripts/detector/detect-antipatterns-browser.js`. **The static CLI scan is useless here** — this file is almost entirely JS template literals, so an HTML parser sees no markup and returns a false clean bill. Copy the browser bundle next to `index.html`, load it with a `<script>` tag, and call `window.impeccableScan()`. Expect it to keep reporting 10–11.5px apparatus labels as undersized: that is the printed register, recorded as a deliberate exception in `DESIGN.md`.

## History worth knowing

`main` lost Phases 1–4 of design work to a bad merge in 2026. All thirteen phase branches are merged ancestors of `main`, yet their code was gone: `0daf069` overwrote `index.html` with a pre-Phase-1 copy, `9eb55af` restored it, `c045a6f` clobbered it again. The lost work is recoverable at commit **`39defe5`**, and P1 ported the mechanisms (`place()` / `.still`, the empty-state doctrine) forward from it.

If you are ever diagnosing a "missing design system" symptom in this repo, **check git history first** — the cause has historically been that incident, not a design decision.

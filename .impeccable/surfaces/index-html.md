---
version: 1
slug: "index-html"
primary_target: "index.html"
related_targets: []
---

## Scope

`index.html` — the whole CAROS shell, all five role surfaces. Visitor mode: **Operate** (the visitor completes a task) throughout; the parent and student surfaces carry a secondary Read register for their explanatory prose.

Audience and job: a Head of University Counseling triaging 87 students each morning, plus four secondary audiences (parent, student, teacher, alumni mentor). Action: decide who to see today and be able to justify it. Proof: the evidence chain behind every signal. Constraints: one self-contained file, vanilla JS, no build step, no backend, `draw()` rebuilds the whole tree on every state change.

Demo priority (2026-09-02): Counselor OS, Student portal, Teacher and Mentor portals. Parent portal gets a safety pass only.

## Direction contract

**THESIS:** The caseload is the ledger the school already keeps. A baseline is a run of marks; a signal is the cell where the run breaks. Refuses the stat-tile row and the rounded card grid.

**OWN-WORLD:** Green-bar ledger stock, never cream — alternating pale-green bands that track rows across 87 names. Cyan-green ruling, one red margin rule, blue-black ink. No serif anywhere: Archivo Narrow for printed apparatus, Libre Franklin for content, Spline Sans Mono for every figure and audit line. Tier is a printed margin stamp, glyph plus letter, never a coloured chip. Near-zero radius.

**STORY:** She reads across a run until it breaks, opens that cell, and can say why she looked there.

**FIRST VIEWPORT:** One continuous ruled sheet, full bleed. Red margin rule at left carrying tier stamps; names in the stub column; weeks as ruled columns; the 07:04 sweep lands as a fresh column at the right edge. No greeting, no tiles.

**FORM:** The Register (the form tutor's pastoral mark book), candidate 1 of the grounded list, taken as IMPECCABLE'S PICK over the roll's assignment. Seed key `ece0a910`.

**FINISH:** unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Disciplines carried in from declined challengers

Independently justified by the 2026-09-02 audit, so they survive the change of card:

- **Claim never without its proof.** Every signal carries its evidence chain adjacent; the accent appears a handful of times per screen at most.
- **State is material, never only colour.** Every tier carries a printed non-colour marker. This also structurally fixes the measured AA failure across all five triage chips.
- **One frame stays level.** The personal baseline band is a fixed datum on every trace.
- **The system prints itself into the record.** Actions write a permanent line into the case transcript rather than a toast that evaporates — which also supplies the missing `aria-live` surface.

## Per-school theming — the letterhead rule

Added 2026-09-02, when the pilot was confirmed as the American Community School of Abu Dhabi. The palette splits into three layers, and only one of them is themable:

- **Material** — ledger stock, band, ruling, ink, pencil, radius, the three faces. Fixed across schools, plus a bounded tint of at most ~4% toward the school's primary. Never expose the tint as a free control: unbounded, it drifts the stock toward the warm cream this direction exists to refuse.
- **Semantic** — the five triage tiers, IB/AP track, concern-domain tags, the baseline band. **Fixed. Never themed.** A counselor moving between schools must not have to relearn what a colour means, and CAROS must not look like a different product at every school.
- **Letterhead** — masthead band, crest, avatars, links, focus ring, margin rule, school name. Themed per school.

**The governing sentence: the school colour is letterhead, never data.** Enforceable by grep — no `--school-*` token may appear inside a severity, track or domain definition.

Mechanism: a `SCHOOLS` record per partner (`brand: {primary, accent, paper}` plus name/counselor/DSL), an `applySchool(id)` that writes `--school-*` custom properties, and an `ink(hex)` helper that derives foreground as white-or-ink from luminance. `ink()` is load-bearing: it is what keeps contrast AA for whatever hex a partner school hands over, so each new school is not a fresh accessibility bug. Accent tokens ship in pairs (`--school-accent` / `--school-on-accent`) so the failing combination is unreachable. Switch at runtime with `?school=<id>`.

ACS Abu Dhabi's real values, read from their production stylesheet (not a brand guide): primary `#004D43`, dark green `#024139`, light green `#809B82`, bone `#F5F4EE`, gold `#F7BD00`. Verified: ACS green passes AA on both stock (9.25) and band (8.34); white on ACS green is 9.80, which also fixes the current 2.63 avatar failure; gold passes only as a fill with dark ink (9.47) and fails as text (1.62); light green is decorative only (2.86). Their bone and the Register's stock differ by a ratio of 1.04 — the same value, differing only in warmth.

Note the collision this rule prevents: ACS's brand green would otherwise sit on the same axis as the semantic "positive change" green. It doesn't, because the school colour is dark structural ink in the letterhead while the semantic green stays lighter and brighter.

**Resolved 2026-09-02:** the demo is branded as ACS outright, so the invented "Al Bateen Academy" is retired — which was necessary anyway, since ACS occupied the Al Bateen campus for fifty years before moving to Saadiyat Island and the old name reads as their former campus. It is hardcoded in eleven places outside the `SCHOOL` object; fold them into the record in the same change.

Because a real school's name now sits over fabricated student welfare records, a **persistent visible "demonstration data" marker** is a shipping requirement on any surface showing student records while a real school is applied. Design it into the letterhead — a printed stamp on the sheet reads as part of the ledger world rather than as a warning banner bolted on, which is the version that survives contact with a live demo instead of being switched off for a cleaner screenshot.

## Memorable moment

The break in the run: a row of consistent marks, then the cell where it stops, stamped in the margin. It is the product's whole thesis at one glance, and it is what the current stat tiles cannot say.

## Unresolved decisions

- Whether Teacher and Mentor earn their own register treatment, or inherit the counselor's sheet.
- Whether the Mentor role survives at all (the $120 marketplace was cut, orphaning its session requests).
- How the retained XP/milestone layer is expressed inside a ledger world without becoming a second visual system.

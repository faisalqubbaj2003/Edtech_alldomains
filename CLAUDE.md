# CAROS — Counselor OS

A single-file prototype (`index.html`, vanilla JS, no build step, no backend) for an AI-native school counseling platform. Five role-based views in one shell: Counselor OS, Parent portal, Student portal ("Career OS"), Teacher portal, Mentor portal. Full product description is in `README.md`.

Live deploy: https://ed-tech-orpin-ten.vercel.app/ (Vercel, auto-deploys from `main`).

## Design direction — read before touching colors, type, or radius

Two documents govern the visual direction. Read them before making a judgment call this file doesn't already answer:

- **The CAROS Markup** — the diagnosis and cited references (Linear, Mercury, Attio, Ashby, Scoir vs. Naviance, Duolingo): https://claude.ai/code/artifact/9369624e-2318-4b02-aab1-9adb536e0605
- **The CAROS Runbook** — the phased implementation plan, task by task: https://claude.ai/code/artifact/e4fab4f7-76f2-42ab-8f2f-d114cda8912f

## The color system

**Do not add a new hex value anywhere in this file without checking this list first.** Every color already has a token and a meaning. The original audit called this "seven decorative chromatic families" — that was wrong in an important way: most of it is real product logic, not decoration. Don't delete state to chase a smaller palette.

- **Neutrals** (`--bg`, `--surface`, `--ink`, `--ink-2/3/4`, `--line`) — unchanged, not the problem.
- **Persona accents** — one per role that's earned one: `--persona-counselor` (teal, `--brand`), `--persona-student` (violet), `--persona-parent` (rose). Teacher and Mentor don't have one yet — that's an open Phase 3 decision (Runbook 3.3/3.4), not an oversight to "fix" by giving them one.
- **Triage severity — 5 real states, never collapse this.** `--urgent` → `--checkin` → `--review` → `--monitor` → `--good`, defined in the `PRIO` object. This is the counselor's actual caseload logic (order + SLA per state). It reads as a red→orange→amber→gray→green severity gradient by design — that's intentional, not a mistake to "fix" by making the hues more different from each other.
- **Track distinction** — IB uses `--ok` (green), AP uses `--info` (blue), consistently. Keep it that way; don't repurpose either color for something unrelated.
- **Concern-domain tags** (`DOMAINS` object: academic, attendance, engagement, behaviour, teacher, university, positive) — these used to be 7 hardcoded hex values with no relationship to anything else. They're now `--dom-*` tokens aliased onto the palette above (e.g. `--dom-teacher: var(--crit)`). If a new domain is ever added, alias it to an existing token — don't invent a new hue.

## Shape

Three radius tiers, nothing else: `--r` (8px, controls — buttons, inputs, chips), `--r-lg` (12px, cards/panels/modals), `--r-pill` (999px, pills/badges/avatars). `--r-xl` still exists as an alias to `--r-lg` for anything that referenced it.

As of Phase 1, only the token definitions are fixed — most components still hardcode a literal `border-radius:Npx` inline rather than referencing these tokens. **Fix this incrementally, as you touch each component** (per Runbook Phase 2/3), not as a single blind find-and-replace across the file — a global pass can't tell a control from a card from context alone.

## Type

- `.serif` → Fraunces (display/editorial moments), `.read` → Newsreader (long-form reading), `.mono` → JetBrains Mono (data/audit trails), default body → Inter.
- New display-size tokens: `--disp-1` (48px), `--disp-2` (36px), `--disp-3` (28px) — Fraunces at these sizes for the screens that open a session (counselor's morning brief, parent's weekly note, etc. — Runbook 2.1, 2.3, 3.1). Don't reuse `.serif` at label-sized 15–18px for a new headline moment; that's the pattern that got it stuck as a label font instead of a display font.
- `--read-size` (16px) / `--read-lh` (1.7) — Newsreader long-form reading defaults.

## Icons

Two sets, and the split is deliberate.

- `IP` — ~40 stock Feather-style outline icons. Everything generic uses these. **Don't replace them with custom drawings.** A product that draws all forty of its own icons reads as decorated, not designed.
- `IC_X` — six bespoke icons for concepts CAROS owns, where the borrowed metaphor said the wrong thing: `signal` (deviation from a personal baseline band — *not* a trend arrow, which means the opposite), `caseload` (a triaged stack, not a group of people), `overnight` (a student moving between priority tiers), `trackIB` / `trackAP` (a closed hexagonal programme vs. separate independently-examined courses — **the pair only works as a pair**; that contrast is the decision a Grade 10 student is being asked to make), `mentorMatch` (two parties converging on one made connection).

`ic()` prefers `IC_X` and falls through to `IP`. Both live on the same 24×24 grid at 1.75 stroke inherited from `svg.ico`; fill marks only the element carrying the meaning. A new bespoke icon needs a CAROS-specific concept to justify it — otherwise use the stock set.

Note the naming trap: the icon is `mentorMatch`, not `match`, because "match" already means reach/match/safety in the university data.

## Empty states and milestones

`ILLUS` holds five inline-SVG drawings on a 128×96 grid; `art()` renders one, `moment()` wraps one in a card with a title and body. Used for four states that are empty because nothing has happened *yet* (`mentor`, `early`, `fork`, `shortlist`) and one because something finally did (`offer`).

The reason these exist isn't decoration. A Grade 9 parent opens the portal and sees almost nothing; a portal that looks broken is a portal a family stops opening — the Naviance failure the Markup cites. So each one draws the specific missing thing and says in copy **why its absence is correct at this stage**.

- Warmth is a **parent-side privilege**: rose accent, Fraunces titles (`serif:true`).
- The **student side stays restrained**: violet, Inter, no serif. A Grade 12 applying to university is a serious audience (Runbook 3.2). No characters, no confetti, no streaks — ever.
- The `fork` illustration draws both routes at exactly equal weight on purpose, and the copy says so. Don't let a future "improvement" emphasise one branch.

## Motion

`draw()` rebuilds the entire tree on every state change. That means **any entry animation you add will replay on every click** unless the suppression below catches it. This was the single biggest thing making the product feel mushy.

- `place()` decides whether a draw is an *arrival* — a different role, view, student file, grade, or a panel whose whole contents are new (the letter finishing, the co-pilot answering). Filtering, sorting, expanding, toggling and typing are **not** arrivals.
- On a non-arrival, `.still` lands on `#root` and every entry animation is suppressed. **If you add a new entry animation, check it's covered by the `.still` selectors** — inline `animation:rise/fade/pop`, or the `.rise` / `.fade` / `.pop` / `.arrive` / `.land` classes.
- Things that *are* the state change rather than a re-render of it stay exempt: toast, modal, palette, spinner, shimmer.
- Anything animating **to** a value from a non-default attribute (like the baseline chart's `stroke-dashoffset:1200 → 0`) needs its end state landed explicitly in the `.still` rule, or suppression makes it invisible.
- Only three moments are allowed to be slower and staged: what changed overnight, the letter drafting itself, the signal meter finding its level. Resist adding a fourth.
- `prefers-reduced-motion` zeroes **both duration and delay**. Don't drop the delay reset — everything staggered here uses `backwards` fill, so a delay without it leaves content blank for up to a second.

## Command palette

⌘K / Ctrl+K, or the header search button. `palCommands()` builds the list, `palFilter()` ranks (exact prefix > word start > substring).

Two rules:

1. **The student list is scoped to the role.** Counselor → all 87 (her caseload). Teacher → the six in their class, and their verb is *log a concern*, not *read the file*. Parent/student → their own record only. Mentor → no student search. Wiring every role to the same 87 rows builds the exact permission leak the co-pilot promises in writing it never makes.
2. **It must not call `draw()` on each keystroke.** `palPaint()` repaints only the results list, so focus and caret survive. A full `draw()` happens once, when a command runs.

`roleNav(role)` is the single source for the grade-conditional parent/student navs — the sidebar, the parent tab bar and the palette all read it. That logic used to exist in three hand-maintained copies. **Don't add a fourth.**

The global key listener is attached once at the bottom of the script, *not* in `bind()` — `bind()` re-runs on every draw and would stack a listener each time.

## Workflow

- One branch per Runbook task, named `phase-<n>.<m>-<slug>` (e.g. `phase-2.1-counselor-home`) — this is how work splits cleanly between collaborators without both people editing the same region of a 3,700-line file.
- No test suite. Screenshot every changed view in the browser (both light content and, where relevant, the family-switcher grade variants) before calling a task done — a color or layout regression here is invisible until someone actually looks.

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

## Workflow

- One branch per Runbook task, named `phase-<n>.<m>-<slug>` (e.g. `phase-2.1-counselor-home`) — this is how work splits cleanly between collaborators without both people editing the same region of a 3,700-line file.
- No test suite. Screenshot every changed view in the browser (both light content and, where relevant, the family-switcher grade variants) before calling a task done — a color or layout regression here is invisible until someone actually looks.

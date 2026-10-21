# CLAROS — Counselor OS

A single-file prototype: `index.html`, ~10,050 lines, vanilla JS, **no build step, no backend, no test suite**. Five role surfaces in one shell — Counselor OS, Teacher, Student ("Career OS"), Parent (Family portal), Mentor Hub. Product description in `README.md`.

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

Or use the Browser pane with the `caros-static` config in `.claude/launch.json` — the config name predates the rename and is left alone; never `bash` for a server. `S` and `draw()` are globals, so drive state directly rather than clicking:

```js
S.role='counselor'; S.cv='si-why'; draw();
```

`S.cv` is the counselor's view, `S.tv` teacher, `S.sv` student, `S.pv` parent, `S.mv` mentor. `S.open` is an open case file, `S.previewGrade` the parent/student grade switcher.

**Demo from the deployed build, not from localhost.** The debug audit panel is gated to `localhost` / `?debug`, so a local demo puts a "UX Audit" pill over every screen.

`?school=<id>` switches the letterhead at runtime (`default`, `demo`). `default` is the unbranded record and carries no school name, short form, initials or mark.

## The three invariants

These are not style preferences. Breaking one is a product regression.

1. **The school colour is letterhead, never data.** No `--school-*` token may appear inside a severity, track or domain definition. Grep-enforced; it is checked. Full reasoning in `DESIGN.md` under The Letterhead Rule.
2. **The five triage tiers are product logic.** Never collapse them, never re-theme them per school, never carry severity on a coloured chip — the tier stamp carries it.
3. **All student data is synthetic.** The build carries no school identity as of 2026-10-20, but the demonstration-data stamp stays: the welfare records are still fabricated and a screenshot still travels. It is gated on the school record rather than on a debug flag so it cannot be switched off for a cleaner screenshot. Never fabricate testimonials, customers, outcomes, benchmarks, pricing or press.

Gamification is allowed on the student side and nowhere else (reversed 2026-09-02). Do not "fix" it back toward the old prohibition.

**One register, formal, across all five roles** (reversed 2026-10-20; full reasoning in `PRODUCT.md` Principle 4). Headings are noun phrases, never questions or clauses — "Supervision allocation", not "Where supervision has landed". Idiom is out: no "nudge", "chase", "take a look", "can run", "slipped". The one heading that still reads as a clause, "Arts, or a sixth subject", is the IB's own name for Group 6 and is correct.

The exception is content, not chrome: parent and counselor message threads, quoted parent questions, co-pilot queries and student writing stay in natural voice. Formalising those makes them read as fabricated.

## How the file is organised

Roughly: tokens and CSS (12–1076), icons and the school record (1080–1260), data (1260–1660), shared render helpers (1660–2110), counselor views (2110–3550), teacher and reference data (3550–4410), the IB module (4410–6415), the student Career OS (6415–7950), parent/mentor/modals (7950–8960), then `draw()`, `bind()` and the debug overlay at the end.

### Tokens

Three layers, declared at `:root` around line 34 and documented in the comment above them: **material** (stock, band, ruling, ink, the three faces, radius), **semantic** (the five tiers, concern domains, the baseline band — never themed), **letterhead** (written by `applySchool()`, themed per school).

A **bridge alias block** sits at the end of that declaration (`--panel`, `--card`, `--inkSoft`, `--inkMute`, `--lineSoft`, `--teal`, `--urgent`…), mapping the pre-Register vocabulary onto Register tokens. Its comment says "nothing here is meant to survive P8"; roughly 350 call sites still read through it, so **it does survive, deliberately**. Retiring it is a mechanical rename with no visual change, worth doing behind a computed-style diff, and it is not urgent — every alias resolves to the correct Register token today. Counting `var(--inkMute)` tells you about naming, not about rendering.

### The night ledger

`@media (prefers-color-scheme:dark)` at line ~148, and it is **gated to `html[data-role="student"]`**. The student surface is the only one with a dark palette; the counselor stays on paper in both schemes by design. Widening it is an open product decision, and the tokens are already written for it. A dark-mode audit run on the counselor will look like the media query is broken. It is not.

### Scroll

`draw()` replaces the whole tree, so the scrolling pane (`#main`) is a new element each time and the browser has nothing to restore a position on. Every expander, filter and tab used to throw the reader back to the top.

`draw()` now captures `#main.scrollTop` before the write and restores it after, **keyed on the same arrival test `place()` already computes**: an arrival is a new destination and belongs at the top; anything else is the same page with one thing changed and keeps its position. A new control that should not jump the page must therefore stay **out** of `place()`'s fingerprint — that is what `S.offerOpen`, `S.selOpen` and `S.selDesc` do.

### Motion

`draw()` rebuilds the whole tree on every state change, so **any entry animation replays on every click** unless suppression catches it.

- `place()` (line ~8941) fingerprints role, view, open file, grade, tab, and the panels that replace themselves wholesale (`letter`, `cpQ`, `cpLoad`, `discoverStage`, `psActiveSystem`, `onbStep`). A changed fingerprint is an *arrival*. Filtering, sorting, expanding and typing are not.
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

### The IB module (P9, 2026-09-10)

Subject selection and CAS, sitting across three roles. Data and rules live together in one block; the views are with their own role's surfaces.

- `IB_SUBJECTS` is the catalogue: **22 subjects**, each with its group, the levels it offers, the period it runs at **per level**, a minimum to run, a cap, a `gate`, a `signal` and four pieces of prose (`about`, `like`, `assess`, `hard`). `IBS(id)` looks one up.
- **The levels are the real offer and not every subject offers both.** Physics is Higher Level only, Mathematics: applications and interpretation is Standard only, and the two ab initio languages and the self-taught literature course are Standard only. A catalogue offering every subject at both levels printed level choices the school cannot timetable.
- **Environmental systems and societies carries `alt`**, because the IB lets it count for Group 3 or Group 4. `IB_BY_GROUP` returns it in both lists. It still fills one slot, and its own copy says so.
- `SELREC[sid]` is one student's selection, `CASREC[sid]` one student's CAS. `DPC` is the Diploma cohort, 150 records across Grades 10 (82), 11 (32) and 12 (36).
- **`selCheck(rec, stu)` is the rule engine** and the only place a submission is gated. It returns `{k:"block"|"ask"|"ok"}` findings. `block` stops the form and is only ever about the form being incomplete — slots open, the Higher Level count, a timetable clash, a missing reason. `ask` is a question the coordinator is handed, never a fault, and **every prerequisite finding is an `ask`**. Add a rule here, not in a view.
- **`demandFor` / `subjectViable` / `demandRows` count at render time.** Nothing about demand is stored. Whether a course runs is a question about the **subject**, not about a level — counting per level printed nineteen at-risk courses where there are four.
- `casSum(sid)` reads `hrs` as the running programme total and `entries` as the recent log. **They are not the same number and deriving one from the other is wrong in both directions.**

### The course catalogue (P12, 2026-10-20)

**The whole offer is real and nothing outside it exists anywhere in the build.** 102 courses taken from a published programme of study and carried without the school's name: `HS_COURSES` (63), `AP_COURSES` (17), `IB_SUBJECTS` (22). `HSC`, `APC` and `IBS` look one up; `HS_DEPTS` is the only list of subject areas.

- **`COURSE_CATALOG` and `COURSES_BY_GRADE` are derived**, not written out again. They were hand-maintained copies and had drifted: they offered Mandarin, music and design technology at diploma level, two economics courses and a human geography course under Advanced Placement, and a diploma psychology course — none of which the school runs. A course can now only appear if it appears in the offer. Do not reintroduce a literal.
- Grade 11 and 12 students take high school courses alongside their diploma or Advanced Placement subjects, so `vCourseOffer` lists all three programmes for the year a student is choosing into.
- `Viper Band` is the one course renamed on import (`Wind Band`): a mascot identifies the school, and the build carries no school identity.

### Prerequisites and recommendations (P11–P12, 2026-10-20)

Two additions around the selection round. Both advise; **neither gates**.

- **A requirement has two layers and they are not the same kind of statement.** `gate` is the published prerequisite — a named prior course, a proficiency, a teacher's recommendation. It is a matter of record and answerable yes or no. `signal` is what the level conversation turns on — a mark in the area the course leans on, a mathematics set, a portfolio. Collapsing them produced a form that refused a student over a mark, which is a judgement a table should not make.
- **`gateOf(gate, stu, ctx)`** answers the hard layer for any course in any of the three programmes. It normalises the two spellings the catalogues use (`courses`/`pre`, `anyCourse`/`anyPre`) and reports `ext`, `cond`, `sst`, `prof` and `coord` as `judged` — never as a failure, because the school has no transcript for them.
- **`PRIOR[sid].courses`** is the course record the gate is checked against; `g9`/`g10` with marks per area is what the signal layer reads. **A gate names a course, so only a course list can answer it.**
- **The mathematics set and Integrated Math 3 are different facts.** The set is a stream inside the course; both streams work through it. Deriving the gate from the set barred every foundation student from analysis and approaches, which is not the rule and blocked three quarters of the year group.
- **`prereqCheck(sub, lv, stu)`** returns `{k, gate, items}`; every item says which layer it came from. `unknown` is returned when there is no record on file, never when a student fails.
- **`courseRec(course, stu)`** is the same answer for a high school or Advanced Placement course, and a teacher's explicit no outranks the gate in the headline word.
- **On student and parent surfaces the words are "Recommended", "Not recommended" and "Recommendation pending" — never "requirement met".** `recWord` and `recIcon` are the only place they are built. A hard block was built here and taken out: a form that prints "not recommended" and then refuses to send is saying two things at once. The coordinator's screens still distinguish a missing prerequisite from a low mark, because that is what a coordinator acts on.
- **`TEACHES_TOWARD`** scopes what a teacher may recommend: their subject area maps to the IB subjects it feeds, so a mathematics teacher may recommend a level for physics and economics but not visual arts. `recommendable(area)` reads it. **`AP_TEACHES_TOWARD`** is the Advanced Placement equivalent and is deliberately separate, because the two programmes ask the teacher a different question: for the diploma it is which level, and Advanced Placement has no levels, only whether the course suits the student. `AP_ELIG[sid][courseId]` = `{ok, by, when, note}`, and `ok:false` is a real answer the student sees with the reasoning.
- **`ELIG[sid][subId]`** = `{lv, by, when, note}` — a recommendation, never a permission. Nothing in `selCheck` reads it as a gate. `eligFor` and `eligList` read it; `eligCoverage()` and `selDisagreements()` count at render time and store nothing.
- **A meeting is requested per subject, by either side.** `rec.meetReq[subId]` is the student's, `rec.teachReq[subId]` the teacher's, read through `meetFor(rec, sub, side)` and `meetAny`. It was one request for the whole form, which asked the coordinator to work out which of three disagreements the meeting was about and left a student with two to argue able to argue only one. The teacher's action sits on the **answered** row of their queue, not on the card above it: a teacher who suggested Standard Level has already worked through that card and will not open it again.
- **A student's request reaches the teacher, and `teacherQueue()` could not carry it.** That queue holds *submitted* selections only, so a student arguing a level on a form she has not sent — which is every student still deciding, including the one the demo opens on — asked for a meeting that appeared on no screen the teacher has. **`teacherAsks()`** reads the round directly, at any status, for the subjects this teacher owns. It drives three things on `vTSelReview`: the count on the sidebar's "Subject choices" entry (`roleNav("teacher")` returns a badge as `x[3]`/`x[4]`), the page heading, which leads with the person waiting rather than with the workload, and `vTAsks()` above the tally — the student's own words, the dispute chip, the exchange, and the action. A render sweep cannot catch this class of bug: every screen drew, and the thing the user asked for was impossible. Click the path.
- **Adding a view is not requesting a meeting.** A teacher writing after the student has asked is answering a meeting that exists; writing first is asking for one. `rec.teachReq[sub].kind` is `"view"` or `"ask"`, and **`meetVerb(rec, sub)`** is the one place the verb is chosen, so the button and the form it opens can never promise different things. The thread, the coordinator's feed and the teacher's own card all read the flag. Without it a record holding one meeting printed two requests on three surfaces.
- **`staffShort(name)`** is the only place a member of staff's display name is built — title plus surname, "Mr. Davies", never "Davies". A chip reading "DAVIES SUGGESTS SL" on a fifteen-year-old's form names a teacher the way a colleague would, and the student is the one reading it. `counselorShort()` is the same function.
- **`disputeThread(rec, sub, d)` is the exchange, in order**, and `vThread` renders it on all three surfaces. A disagreement is a conversation between a student and a teacher that a coordinator is kept across, and the build held every turn of it while showing none of them together: the teacher's recommendation was a chip, the student's answer was the form, the teacher's signed reply was a panel on another screen, the meeting request a third thing below both. Oldest first, because the question it answers is "how did this get here". Every line says which of the three moved. An **unsent** choice is still a turn — a draft carries no sent date, which left the one student a demo opens on with a thread showing her teacher's view and her meeting request but not the choice between them.
- **Changing a subject's period can strand an authored selection.** Moving French B's Standard Level onto P3 put it against Economics at P3, and Maya's authored picks are written by hand rather than generated — so the one student a demo opens on had a form that could never be sent, and the whole loop past "send" was unreachable through the interface. After any period change, check that every authored record still has a clash-free selection, not only that the generator can build one.
- **A register recommendation and a signature must agree.** The thread prints them two days apart, so a seeded teacher who recommended Higher Level and then answered Standard read as a bug. A scan confirms zero contradictions across the cohort; keep it that way when seeding.
- **One disagreement, three people, one state.** `disputeState(rec, sub)` returns `open` / `requested` / `scheduled` / `settled`, derived from the records the three of them already write. `disputeChip` and `disputeLine` render it, and the student form, the teacher queue and the coordinator page all read the same two functions. Three vocabularies for one fact is how a workflow becomes a list of events nobody can act on.
- **`rec.meetReply[subId]`** is the coordinator's answer — the step the round was missing. A request went in and nothing came back, so the student's form said "awaiting a reply" indefinitely and the teacher never learned whether their concern had been picked up. `meetSchedModal` writes it; there is no notification to send, because all three are looking at the same selection.
- **`roundQueue()` is what waits on the coordinator**, and there are only three kinds: a meeting asked for and not answered, teachers answered with no conversation recorded, conversation recorded with the selection unconfirmed. `vRoundQueue()` puts the action on the row. **A meeting is its own row because it carries somebody's own words; the other two are the same sentence about a different name and are grouped behind a count** — twenty identical rows hid the two that were not. The history moved behind a disclosure (`vSelActivity`), because a record of what already happened is worth keeping and is not worth the top of the page.
- **A teacher's signed verdict counts as a disagreement.** `selDisagreements()` reads `rec.signs[sub].verdict !== "hl"` alongside the register recommendation and the prerequisite. A recommendation made before the student chose is a view; a signature against the level they actually asked for is the school answering the question in front of it.
- **Both demo seeds sit on `TEACHER`.** The portal shows one teacher, so a request parked with a colleague is a state his own screens can never reach; one row offers the action and the next shows where it ends up.
- **`selActivity(limit)` derives the round's movement** rather than storing it: recommendations, signatures, submissions and meeting requests read back out of the records both sides already write, so there is no second copy to drift. Every item names who moved it, because "updated" without a name is the thing a coordinator has to go and ask about. `dayNum` sorts the "18 Nov" dates. `selActivityCounts()` is the same movement counted.
- **Where it surfaces.** `vSelActivity()` is the full feed on the coordinator's selection page, grouped by day, each row opening that student's preparation page. The counselor's caseload carries a one-line `.roundstrip` instead, and only when the round is asking for somebody — a meeting requested, or a choice against the advice with no conversation recorded. That page is a welfare surface and the round is not its work.
- **Students and choices are different numbers.** A student can hold three choices against the advice and is still one conversation. The coordinator's panel said "choices" while counting students; it now says both.

Mr. Davies gained a fourth class, `c4`, the Grade 10 extended set, filled from `DPC` so the register and the cohort are the same people. `vTClass` resolves its roster from the caseload *then* the cohort — it is the one screen that reads across both populations, and resolving from only one rendered it empty.

Three product rules the code enforces:

1. **A selection cannot be approved before the conversation is recorded.** `data-selapprove` is disabled without `rec.talk`. This is the module's reason to exist.
2. **A teacher answers the level question only, for their own subjects.** `teacherQueue()` filters to `p.lv==="HL"` and `IBS(p.s).t===TEACHER.name`.
3. **Two populations, never totalled.** The caseload is 87 students of one counselor; `DPC` is the school's IB cohort. Every heading says which it holds.

**The marks sit on their own line** (`.selmarks`), under the teacher and period rather than beside them — reversed 2026-10-20. They were inline to save a line of height on each of six slots, and the slot that matters most is the one that proved it wrong: a subject carrying both a requirement mark and a teacher's level, pushed against "Mr. J. Davies · P1", read as one dense run of small type. Height is cheaper than that. A draft's reason fields also start **empty**; only sent selections carry their reasons, because a submitted form with no reasons would contradict the rule above it.

New shared vocabulary: `.selform` / `.selslot` / `.selrow` / `.selmarks` (the printed entry form, red margin rule down the left), `.checklist` / `.checkrow` (findings as marks, cross in margin red for a blocker), `.lvstamp` (HL/SL as a ledger stamp, never a tier colour), `.ibsheet` / `.ibcell` (six subject-code cells per row, read across like a run of weeks), `.opt` / `.lvbtn` (the chooser).

### The Extended Essay (P10, 2026-09-10)

Sits beside the selection module and shares its vocabulary.

- `EE_MILESTONES` is the schedule, with days relative to `DAY` per year group, so the whole thing moves with the demo's today. `EE_DATES` prints them; three milestones carry `rppf:true` and are the IB's mandatory reflection sessions.
- `EEREC[sid]` is one student's essay. `eeNext`, `eeStalled`, `eeNote` and `eeNudge` are the derived states; `eeLoad`, `eeQueue` and `eeSupervising` are counted at render time, never stored.
- **Drift is not the same as pending.** A proposal sitting with a teacher for two days is fine; one sitting for more than `EE_WAIT_DAYS` is not. Getting this wrong puts most of a year group on the coordinator's list.
- **Every research question is authored and unique**, checked globally and per supervisor. The upper cohort is sized to the pool. If you add students, write questions first.
- Capacity **warns and never blocks**, by product decision. An assignment made over the guide records that it was.

The student's three core parts are one section, `vStuCore`, with tabs. It appears only for IB students in Grades 11 and 12; everyone else keeps the single activities page. TOK is described and explicitly not tracked, and the page says so.

**The Grade 11 demo forks.** `S.previewTrack` switches the student portal between Fahad (AP) and Ivan (Diploma). It applies to the student role only: the parent portal keeps Fahad's family, whose content is authored around AP. Any student the switcher can reach needs an entry in `SURVEY_COMPLETE` or the onboarding gate swallows the portal.

### The command palette

⌘K, or the masthead button. `palCommands(role)` builds, `palFilter()` ranks (exact prefix > word start > substring), `palPaint()` repaints **only the results list** so focus and caret survive.

1. **The student list is scoped to the role.** Counselor sees all 87; teacher sees their class and their verb is *log a concern*, not *read the file*; parent and student see their own record; mentor has no student search. Wiring every role to the same 87 rows builds exactly the permission leak the co-pilot promises in writing it never makes.
2. **Never call `draw()` per keystroke.** A full draw happens once, when a command runs.

`roleNav(role)` is the single source for the grade-conditional parent/student navs — sidebar, parent tab bar and palette all read it. There used to be three hand-maintained copies. Do not add a fourth.

The global key listener is attached once at the bottom of the script, **not** in `bind()` — `bind()` re-runs on every draw and would stack a listener each time.

### Routing

The counselor router is a chain of `else if(S.cv===…)` around line 8998. **Order matters and has bitten before**: a broad early condition silently shadowed `S.cv==="files"`, so the sidebar's "360° student files" opened the caseload for weeks while the function sat there working. Add new routes below the catch-alls, and check no earlier branch already claims the key.

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

**Audit form fields, not only text.** A contrast sweep that walks text nodes cannot see an `<input>` or `<textarea>` value, and for a long time every field in the student's night ledger was white on white at 1.14:1 while three separate sweeps reported zero failures. An auditor can only fail what it can see; when one reports clean, ask what it is structurally unable to look at.

For contrast, **composite the full ancestor chain to an opaque ground in both directions.** An auditor that does not will lie to you both ways: it over-reports on translucent light overlays (treating `rgba` backgrounds as white) and under-reports on alpha text. This has already produced one phantom 120-failure report on a surface that was clean.

The mechanical detector is at `.claude/skills/impeccable/scripts/detector/detect-antipatterns-browser.js`. **The static CLI scan is useless here** — this file is almost entirely JS template literals, so an HTML parser sees no markup and returns a false clean bill. Copy the browser bundle next to `index.html`, load it with a `<script>` tag, and call `window.impeccableScan()`. Expect it to keep reporting 10–11.5px apparatus labels as undersized: that is the printed register, recorded as a deliberate exception in `DESIGN.md`.

## History worth knowing

`main` lost Phases 1–4 of design work to a bad merge in 2026. All thirteen phase branches are merged ancestors of `main`, yet their code was gone: `0daf069` overwrote `index.html` with a pre-Phase-1 copy, `9eb55af` restored it, `c045a6f` clobbered it again. The lost work is recoverable at commit **`39defe5`**, and P1 ported the mechanisms (`place()` / `.still`, the empty-state doctrine) forward from it.

If you are ever diagnosing a "missing design system" symptom in this repo, **check git history first** — the cause has historically been that incident, not a design decision.

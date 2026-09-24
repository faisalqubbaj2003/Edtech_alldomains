# CAROS backend · Pass 7 · Adversarial review

Written 2026-09-24 by Claude Opus 5.5 in a fresh session. It reviews `backend-plan/out/01` to `06` against `backend-plan/CONTEXT.md`, `PRODUCT.md` and the prototype `index.html` at commit `fb28217`.

## How to read this

**What was done.** All six passes were read against CONTEXT.md §3, §4, §7 to §9 and §11. Claims about the prototype were checked in `index.html`. Web sources were checked on 2026-09-23 and 2026-09-24: vendor documentation, ADEK's own policy PDFs, an English translation of the PDPL, Google's and Microsoft's pages, Anthropic's pages, and published papers. The engine was re-implemented from pass 3's formulas and simulated; the appendix scripts of passes 3 and 5 were re-run. The review used several parallel checks; some stopped at a session usage limit and were resumed or re-run. A.6 says exactly which citations were and were not reached.

**Conventions.**
- `01:957` means line 957 of `01-architecture-and-data-model.md`, and so on for `02` to `06`. Line numbers are to the files as they stand on 2026-09-24.
- Text quoted from the plan is exact. What a web source says is paraphrased, with the page named, so it can be checked.
- Severity: **blocking** stops a phase from being built as written, or builds something unsafe that later phases trust. **Serious** causes real harm or significant rework. **Moderate** is a real defect with bounded impact, or a serious one that tests would catch early. **Minor** is an error with little consequence.
- Confidence says how sure the review is that the defect is real, and what it rests on.

**Pass 6's four questions.** Acceptance criteria that cannot be met, or pass without proving anything: B0.7 (F02), B1.15 (F18), B2.9 and B2.16 (F06), B3.10 (F50), B4.3 (F14), B6.3 (F17), B7.2's leak scanner (F20), G-LIVE (F24) and the Wellesmere "UCAS-only" assertion (F31). The migration map: F40. The Fable reservations and different-model reviews: F38. The week and session counts: F39 and F46.

**Decisions already taken.** Davide's four decisions of 2026-09-24 (pass 6 §11: C2, C4, C5, C6) are not reopened here. Four findings report flaws in how pass 6 carries them out: F39 (C2), F43 (C4), F41 (C5) and F42 (C6).

**For Davide.** Under every finding, and under every item in A.5 and every judgment call in C, write accept, reject or accept with a change on the `Decision:` line. Pass 8 acts only on those lines.

**Decisions recorded 2026-09-24.** All 107 `Decision:` lines are filled. Settled together: C1 settles F03, C2 and C3 settle F28, C4 settles F14, C10 settles F27, C9 goes with F24. Carried to pass 8 as new work: an ACS question on parental access at 18 (C5), a B0 model bake-off (C7), an ACS question on how 7.1.3.a is handled with other vendors (F04), and the April 2027 G-REAL target with an explicit list of cuts (F39).

## Index of findings

| # | Severity | Finding |
|---|---|---|
| F01 | blocking | The database cannot tell the web app from the worker, and the worker's own check always fails |
| F02 | blocking | Pass 4's permission matrix cannot be stored or enforced by pass 1's model, and B0 seeds it anyway |
| F03 | blocking | The safety screen lets a model close a detected disclosure with no person involved |
| F04 | blocking | ADEK requires its explicit consent before a contractor shares personal data, and no pass knows it |
| F05 | blocking | One ordinary sick day becomes a strong signal, and the CUSUM never forgets it |
| F06 | blocking | The B2 acceptance test cannot pass, and the calibration it must reproduce is not the specified engine |
| F07 | serious | An escalated case can slide down the queue and be auto-closed, and a second referral for the same student is blocked |
| F08 | serious | The engine's rate limit can hold an urgent raise for a day or a week |
| F09 | serious | The safeguarding clocks and routes misread ADEK: the 24-hour duty is each staff member's, and suicidal ideation goes to leadership immediately |
| F10 | serious | Teachers have no safeguarding route in CAROS, and their worst observation lands at "this week" |
| F11 | serious | The student safety message says "call any time", and most of the numbers it lists are not 24-hour lines |
| F12 | serious | Safety alerts are a second route to the Child Protection Officer without invariant 5's guarantees |
| F13 | serious | Students can read the safety alerts raised about their own words |
| F14 | serious | Subject-access packs release staff-only material by default and can reveal that a referral exists |
| F15 | serious | Families and students would read staff material because data classes are bound per table |
| F16 | serious | The capability design gives welfare access to people who are not counselors |
| F17 | serious | The conversation gate and other approval gates rest on a non-null id and table-wide update rights |
| F18 | serious | Google sends no RISC events for Workspace accounts, so "suspend the Google account" revokes nothing |
| F19 | serious | Step-up relies on `prompt=login`, which Google does not support |
| F20 | serious | Free text carries the "excluded" classes to the United States, and the pseudonymiser misses common names |
| F21 | serious | The quarantined reader sends every free-text record abroad at save time, including records R6 excludes |
| F22 | serious | The EU cold copy is keyed to a UAE-only key, so it cannot be restored in the disaster it exists for |
| F23 | serious | Real data has undesigned routes into development tooling |
| F24 | serious | Shadow mode runs a different engine, and its exit bars cannot be met by the plan's own numbers |
| F25 | serious | The academic domain is inert for most of each year, and the termly fallback floods or never fires |
| F26 | serious | The common-cause guard makes a student's level depend on other students |
| F27 | serious | ManageBac's API does expose CAS, and probably the Extended Essay, so pass 2's central integration conclusion is wrong |
| F28 | serious | At least nine kinds of outbound notification exceed the two that were decided, and none is declared |
| F29 | serious | A real ACS staff member's name is seeded as a demo persona in the tenant shown to other schools |
| F30 | serious | Unsourced prototype figures go into global reference tables and render with a label |
| F31 | serious | The second school proves labels, not substance: ADEK is hard-coded for every tenant and the engine is validated on ACS only |
| F32 | serious | UCAS changed both the personal statement and the reference, and the model predates both |
| F33 | serious | A British school's pastoral structure cannot be represented |
| F34 | serious | The materialised reporting views sit outside row-level security |
| F35 | serious | CAROS staff can write into real tenants outside the support-grant model, and grants are not bound in the database |
| F36 | serious | The worker's cross-tenant work is undesigned, and the tenant status model skips the pilot school |
| F37 | serious | The regulatory analysis has gaps that change the design, starting with the missing impact assessment |
| F38 | serious | The Fable reservations and different-model reviews contradict each other and miss tasks whose errors are silent |
| F39 | serious | The calendar assumes parallelism the ownership columns do not provide, and it is not mapped to a school year |
| F40 | moderate | The migration map does not match the task tables, and the named migrator cannot run the planned releases |
| F41 | moderate | Pass 6 does not carry out accepted decision C5 in B4, and retests on staging cannot verify production-layer fixes |
| F42 | moderate | Pass 6 does not fully carry out accepted decision C6 |
| F43 | moderate | Staging is now the sales demo, and it is also the drill ground, the retest target and the continuous-deploy target |
| F44 | moderate | The AI database role is a denylist, and nightly AI runs as the system tier |
| F45 | moderate | On-call escalation depends on an SMS acknowledgement Azure does not offer |
| F46 | moderate | The branch rules as written stop Davide from merging his own work |
| F47 | moderate | Pass 6 says it resolved the widening rule one way and tests the other |
| F48 | moderate | Past alerts are not fully explainable after a configuration change |
| F49 | moderate | The backend `CLAUDE.md` paraphrases the invariants and drops clauses |
| F50 | moderate | The prototype's ranking within a tier is on its way into the port |
| F51 | moderate | "Match" is used outside reach, match and safety |
| F52 | moderate | The headline rephrase is a sixth AI feature, gated three different ways |
| F53 | moderate | Three more places where model output decides without a written rule |
| F54 | moderate | Veracross can schedule the weekly pack itself, over password-only SFTP, and exposes sensitive endpoints |
| F55 | moderate | Pass 4 cites a superseded Student Protection Policy, and the stale clause numbers are in the counselor's banner |
| F56 | moderate | The Child Digital Safety Law restricts more than free text sent to a model |
| F57 | moderate | Parent access does not enforce activation in the database, cannot express custody restrictions, and hinges on one approver |
| F58 | moderate | The teacher sign-off card would port an engine signal, and the subject-teacher scope is too wide |
| F59 | moderate | Pass 4's mentor reader rules cannot be built on pass 1's tables |
| F60 | moderate | "Identifiers only" is not true of several emails and alerts, and their processing is global |
| F61 | moderate | Access from abroad by CAROS people, Microsoft support and yearly pen tests are unaddressed |
| F62 | moderate | The Extended Essay guide dates are a year off for ACS's current cohorts |
| F63 | moderate | The family notice understates what the AI provider may keep |
| F64 | moderate | No results-day, Confirmation or Clearing logic, and university clocks count school days over the summer |
| F65 | moderate | Several structures are ACS-shaped where the plan promises data |
| F66 | moderate | The Personal Statement Lab's "AI read" score survives the port |
| F67 | moderate | A school role can switch the demonstration marker off |
| F68 | moderate | Smaller engine defects that change the numbers by multiples |
| F69 | moderate | Four cited facts do not match their sources |
| F70 | minor | The AI cost model leaves out thinking tokens |
| F71 | minor | Pass 1's cost table undercounts HA storage and omits several lines |
| F72 | minor | Bookkeeping errors inside pass 6 |
| F73 | minor | Pass 1's account of the AWS region loss needs small corrections |
| F74 | minor | Small corrections to pass 2's vendor facts |
| F75 | minor | Smaller authorization and identity defects |
| F76 | minor | Smaller residency paths |
| F77 | minor | Smaller invariant and consistency items |
| F78 | minor | Smaller engine and documentation errors |

78 findings: 6 blocking, 33 serious, 30 moderate, 9 minor. A.5 checks the eighteen inconsistencies pass 6 listed. A.6 is the citation register. B lists what to keep. C sets out eleven judgment calls.

---

## A. Findings, ranked by severity

### A.1 Blocking

These stop a phase from being built as written, or build something unsafe that later phases trust. Fix them in the revision before B0 starts.

#### F01 · The database cannot tell the web app from the worker, and the worker's own check always fails

**Severity:** blocking · **Where:** 01 DR-4 (01:175, 01:182); `auth.allowed()` (01:957 to 01:969); ownership and grants (01:1052 to 01:1060); 04 §3.2 (04:281); 05 §3.0 (05:171); 06 B0.5 to B0.8 · **Confidence:** high

**What is wrong.** Two defects sit in the layer B0 builds first and every later line trusts.
1. `auth.allowed()` is `SECURITY DEFINER` and owned by `caros_policy`. Inside a definer function, `current_user` is the owner. The branches `WHEN 'system' THEN current_user = 'caros_t_system'` and the support branch can therefore never be true. As written, the nightly sweep and the support console read nothing.
2. The obvious repair (drop the check, or test `session_user`) separates nothing, because one login role, `caros_app`, is granted every tier role: staff, student, guardian, mentor, `caros_t_system`, `caros_t_support`, and later `caros_t_ai`. Any code running as `caros_app` can `SET LOCAL ROLE caros_t_system`, set `app.actor_kind = 'system'` and choose `app.school_id`. DR-4's sentence "a request handler cannot claim to be the worker" is false at the database. Roles also inherit by default, so a connection that sets context but skips `SET ROLE` gets the union of column rights.

**Why it matters here.** The system tier has read and write on nearly every class, including `case_note` and `safeguarding` (04 §3.6, System column). One bug in the internet-facing web process becomes the worker's reach inside any school it names. The plan reserves Fable 5.1 for exactly this layer, and the layer as specified does not work.

**Fix.** One login role and managed identity per deployable: web (user tiers and `caros_t_ai` only), worker (`caros_t_system` only), migrator (owner via `SET ROLE`), and the support console as a separate app (`caros_t_support` only). Set `NOINHERIT` on all of them. Evaluate the tier in the policy expression, which runs as the caller, and pass it into `auth.allowed()` as an argument. Add a B0.8 test that the web identity cannot `SET ROLE` to system or support.

Decision (2026-09-24): Accept.

#### F02 · Pass 4's permission matrix cannot be stored or enforced by pass 1's model, and B0 seeds it anyway

**Severity:** blocking · **Where:** 01 `auth.perm_scope` (01:619 to 01:631); `auth.role_permission` (01:692 to 01:701); `auth.protect()` (01:1008 to 01:1043) and its calls (01:3769 to 01:3889); 04 §3.2 (04:277 to 04:278), §3.6 (04:310 to 04:343), §5.3 step 3 (04:470); 06 B0.7 (06:90), §1.12 (06:397), §5.4 (06:780) · **Confidence:** high

**What is wrong.**
1. **Scopes that do not exist.** The matrix uses ESC, G (support grant), "addressee", and "the lead only while a cover or reassignment is active". The enum has none of them and no delta D33 to D61 adds them.
2. **One scope per key.** The unique key is `(school_id, role_key, data_class, action, capability)`, without `scope`. The matrix gives a teacher `ib` read at ST and at EP, and gives counselors two `directory` read scopes. The B0.7 seed fails on insert.
3. **Qualifiers with no mechanism.** "`transcript` only", "existence and status only", "aggregates only", "own discovery and EE feedback", "own guardian links only" have no representation. `auth.protect()` binds one class per table and ignores row kind.
4. **Verbs the database refuses.** Insert and update policies call `auth.allowed(..., 'write')`. Pass 4 enforces `escalate`, `approve` and `configure` only in the domain layer. A counselor holds `es` but not `w` on `safeguarding`, so the C15 insert into `signal.escalation` is refused. Pathway approval (`ap` without `w`), thresholds, the safeguarding route and memberships (`cf` without `w`) fail the same way.
5. **Tables in the wrong class.** `notify.outbox` and `notify.in_app` are protected as `config` with the recipient as author, so the outbox rows written "in one transaction" with an escalation are refused. `core.meeting` is `family`, and `+ib_coordinator` has no `family` write, so the coordinator can record the review conversation (invariant 6) only for students in their own caseload.
6. **Tests that cannot see it.** §5.4 tests verbs negatively and exercises five scopes.

**Why it matters here.** These are the two consequential acts, escalation (invariant 5) and the conversation gate (invariant 6). The failure is loud at the first end-to-end test, and that is the danger: the quick repair under pressure is a broad `w` grant, which widens access everywhere F15 describes.

**Fix.** Before B0.7, a matrix-to-schema step that the revision writes out: new scopes with predicates (`esc`, `grant`, `addressee`, conditional lead access), scope in the unique key, per-kind predicates, derived subjects for child tables, and per-role projection views. Policies accept `write OR <the verb the table carries>`, or the matrix adds `w` rows mirroring each verb's scope. A `SECURITY DEFINER notify.enqueue()`. Positive end-to-end tests for every verb through RLS. No qualifier ships without its mechanism and a negative test.

Decision (2026-09-24): Accept.

#### F03 · The safety screen lets a model close a detected disclosure with no person involved

**Severity:** blocking · **Where:** 05 §6.3 (05:543, 05:545), §6.1 (05:514), counsel question C22 (05:1237), pass bar (05:885); 06 B7.9 (06:308) · **Confidence:** high

**What is wrong.** "`none` from layer 2 after a layer-1 hit closes the layer-1 hit as `cleared_by_model`." A Sonnet 5 classification decides that a lexicon hit on a minor's text raises no alert. The model can also lower urgency (`fiction_or_quote` routes "at the lower urgency"), and it alone triggers the immediate route (`means_or_plan_mentioned`). The pass says "the model triages; a person decides" and C22 says a person always reviews, and the mechanism contradicts both. The pass bar accepts 15% misses on indirect positives. A school that declines R8 gets pattern-only routing, where every hit reaches a person (05:530), so switching the model on makes the screen less sensitive.

**Why it matters here.** Invariant 3: "Nothing that gates a decision or a submission is model output." This is the most consequential gate in the product: whether a child's words reach an adult.

**Fix.** Layer 2 may add an alert or raise urgency, never clear or lower one. Every layer-1 hit creates at least a standard alert, with the model's reading shown beside it as a note. Drop the `fiction_or_quote` downgrade. Correct C22. Add a test that no hit or alert closes without a person's disposition. Alert load is a lexicon problem, owned by the CPO (question 129), not a model problem.

Decision (2026-09-24): Accept, settled by C1: remove the model layer and cleared_by_model from v1; the lexicon screen is the only screen.

#### F04 · ADEK requires its explicit consent before a contractor shares personal data, and no pass knows it

**Severity:** blocking (for G-AI, the DPA and the EU cold copy) · **Where:** 04 §1.1 (04:78), §6.1 (04:513), §9.7 (04:721), Challenge 12 (04:913); 05 §8; 06 gates G5, G7, G21, G22 (06:985 to 06:1002) · **Confidence:** high on the text; the legal reach is counsel's

**What is wrong.** Pass 4 concludes that no ADEK policy governs where student data goes. ADEK's School Digital Policy v1.1, clause 7.1.3.a (checked in both the copy pass 4 cites and ADEK's own PDF), requires schools to put a non-disclosure agreement into every contractor agreement under which personal data may not be shared inside or outside the country, for any purpose, without ADEK's explicit consent. The same policy's clause 6.4 requires parents' consent and ADEK approval for live virtual interactions with invited visitors, a definition that includes volunteers such as mentors. Neither clause appears in any pass.

**Why it matters here.** ACS's agreement with CAROS must carry this clause. Every onward share then needs ADEK's consent: the AI transfer to Anthropic in the United States, the proposed EU cold copy, and possibly the in-country sub-processors. The AI rules R1 to R3, the DPA outline, open decisions 1 and 4, counsel questions C3 and C12, and mentor video sessions all rest on an analysis that missed the operative rule.

**Fix.** Add ADEK consent as a named gate before G-AI and before any EU copy, and as a counsel question on whether in-country hosting by Microsoft is "sharing" under 7.1.3.a. Rewrite pass 4 §1.1's hosting paragraph to cite 7.1.3.a. Put the ADEK consent request on the ACS question list with the evidence pack ADEK would need.

Decision (2026-09-24): Accept with a change: ADEK consent becomes a named gate before G-AI and before any EU cold copy, plus a counsel question on whether in-country Microsoft hosting is 'sharing' under 7.1.3.a. First ask ACS how it has handled 7.1.3.a with its other vendors (ManageBac, Veracross), then draft the ADEK request and evidence pack; given the April 2027 target, raise it with ACS this term.

#### F05 · One ordinary sick day becomes a strong signal, and the CUSUM never forgets it

**Severity:** blocking (engine defaults) · **Where:** 03 §3.3 floors (03:195 to 03:201), §3.4 shock and CUSUM (03:213, 03:217 to 03:224), §3.5 (03:237 to 03:238), §4.2 attendance measures (03:333 to 03:336), §4.7 recovery (03:422), §8.3 exit (03:614), S3 (03:989), Maryam (03:547) · **Confidence:** high on the mechanism (computed); medium on the rates, which depend on ACS's register and reason coding

**What is wrong.**
1. **Attendance.** The binomial scale floor treats each lesson as an independent chance to be absent. Students miss whole days. With a per-period register (about 30 sessions a week, which is what the Veracross fixture carries), a 100% attender's floor is 3.0 points, and one uncoded absent day (80%) is z of about 6.7: a strong shock, moderate on its own. The review's engine check traced one absent day to moderate for three weeks, and two absent days in consecutive weeks to `checkin` for four weeks. A simulation of quiet students with ordinary 1 to 3 day absences put roughly two new check-in cards a week on an 87-student caseload from attendance alone when half of absences carry a suppressing reason code. The plan does not say which register the rate uses, and pass 2's pack delivers both (02:740). The ten-day count windows are evaluated weekly, so each absence is counted twice.
2. **The CUSUM drains at 0.5 a week and takes a single outlier's z at full size.** S3's single outlier (61 against a median of 87, s = 3.0) puts S at 8.17, above `h_strong`, and two in-band weeks leave it at 7.3 and 7.2. Exit needs S below 2.5, which takes about 12 normal graded weeks. Recovery needs S = 0. Maryam's `good` lands about eight weeks late, not one. The fifth tier, protected by invariant 1, will almost never fire.

**Why it matters here.** The check-in tier carries a two-school-day promise. Filled with sick days, it becomes the queue pass 3's own alert-fatigue evidence (Ancker et al.) says stops being read. And cases that cannot come down make the sheet a list again.

**Fix.** Measure attendance in days from the master register. Take the floor from a day-level model or the backtest. Set the minimum meaningful change above one day. Count unexplained absences in days over non-overlapping windows. Cap z inside the CUSUM (for example at 3) and send strong shocks through their own rule. Restart the chart when a case opens, and base exit and recovery on levels and the run-mean since the case opened, not on S. Hold attendance at weak until ACS's reason-code coverage is measured.

Decision (2026-09-24): Accept.

#### F06 · The B2 acceptance test cannot pass, and the calibration it must reproduce is not the specified engine

**Severity:** blocking (B2 acceptance) · **Where:** 02 §8.1 fixture (02:970); 03 §3.2 minimums (03:176 to 03:179), P definition (03:222 to 03:223), §3.6 (03:246 to 03:264), §7.2 seed reproduction (03:540 to 03:550), §7.3 (03:554 to 03:556), §11.1 (03:763 to 03:775), appendix (03:1128 to 03:1172); 06 B2.9 (06:155), B2.16 (06:162), §5.2 (06:772) · **Confidence:** high

**What is wrong.**
1. **Not enough history.** Twelve weekly packs give at most eleven prior weeks, and the fixture carries no prior-year attendance. Below `min_history_full = 12` every detector is capped at weak. On the authored day Hana stays weak (her relapse does not fire and she lands at monitor), Ahmed reaches `checkin` by row 6 rather than urgent, and S1, S3 and S14 cannot produce the levels their expectations state.
2. **Measures that do not exist.** Priya's and Ahmed's punctuality series (100, 100, 98, 100, 96, 90, 84, 80) is an on-time percentage. §4.2 defines lateness only as counts, and `attendance.rate` counts late as present.
3. **Two persistence rules.** The spec defines P as weeks since onset, so "S ≥ h with P ≥ 2" is true almost whenever S ≥ h (2.70% against 2.72% of series-weeks, computed). The 0.65% the plan cites comes from the appendix script's different rule (two consecutive weeks above h). The appendix also treats a plain shock as moderate, where the spec says weak.
4. **A script that does not exist.** B2.9 must regenerate §11.1 "within rounding" from `calibrate_tiers.py`, which is not in the plan. A rebuild of the stated setup reproduces §11.1's detection curve exactly but gives lower noise (0.4 check-in, 8.2 review, 5.3 monitor at week 8) than the published 0.7, 11 and 21, which fit a scale floor of one half, not three-quarters. The "thirteen quiet students a week into check-in" reproduces only under the older, looser setup.

**Why it matters here.** A builder handed an unpassable acceptance test bends the engine until it passes. That is the silent error the plan reserves Fable 5.1 to prevent.

**Fix.** Give the fixture at least twenty in-band weeks before the authored eight, or import prior-year attendance. Generate the expected diff by running the rules, not by hand. Define a punctuality measure the authored series could come from, or re-author them as late counts. Pick one persistence definition (consecutive weeks with S ≥ h is the one that filters). Publish the tier script in the plan, define "new items" as entries or occupancy, state the floor, and regenerate §3.6, §7.3, §11.1 and the appendix from the engine's own level function.

Decision (2026-09-24): Accept.

### A.2 Serious

These cause real harm or significant rework if built as written. Most are safeguarding, authorization or residency defects.

#### F07 · An escalated case can slide down the queue and be auto-closed, and a second referral for the same student is blocked

**Severity:** serious · **Where:** 01 DR-7.1 C1, C2, C4, C12, C15, C21 (01:256 to 01:276); 03 §8.1 to §8.4 (03:594 to 03:629); 04 §5.3 steps 3 and 9 (04:470, 04:487); 06 B3.4 brief (06:512 to 06:516), backend `CLAUDE.md` (06:606) · **Confidence:** high

**What is wrong.**
1. **The engine can lower an escalated case.** C15 sets the tier to `urgent` as a person's act. The engine respects that for `person_raised_hold_days` (14) and then lowers by hysteresis. A disclosure-driven escalation often has no trace in grades or attendance, so the `lower(case)` conditions in §8.3 hold vacuously after 14 days. Once at `monitor`, auto-review closes the case as `not_a_concern` after about six quiet weeks (§8.4, C21). Pass 4 says only that "the case follows its normal lifecycle".
2. **A second referral is impossible while the case is open.** `UNIQUE (school_id, case_id)` on `signal.escalation` is "the no-double-fire rule", and one open case per student is a unique index (C1, C2). A new, distinct safeguarding concern about a student whose case is open can only be raised by closing the case (C18 first requires every intervention resolved), opening a manual case, then escalating. The screen offers "a note or a direct call" instead.
3. **Merge crosses students.** With one open case per student, C12's open-to-open merge always joins two students' cases and re-attaches one student's signals and evidence to the other's file (the prototype's merge modal lists other students' cases).

**Why it matters here.** Invariant 5 makes escalation a real, logged act. "Cannot double-fire" means one act is not recorded twice, not that a child can be referred once per case. Real safeguarding concerns recur. A referral that disappears from the sheet, or a second one that CAROS cannot record, is the failure the product exists to prevent.

**Fix.** Pin the tier while an escalation is open: the engine may raise, never lower or auto-close; after the outcome a person sets the tier. Replace `UNIQUE (school_id, case_id)` with a partial unique index on open escalations plus an idempotency key per submission, and allow a new escalation linked to the previous one. Restrict C12 to the same student; link cases across students without moving data. Add scenarios S24 (escalated case, quiet data, 60 days) and S25 (second concern on an escalated case).

Decision (2026-09-24): Accept.

#### F08 · The engine's rate limit can hold an urgent raise for a day or a week

**Severity:** serious · **Where:** 03 §8.2, last bullet ("at most one engine-driven tier change per case per 24 hours, and at most two per case per 7 days; a third is held") · **Confidence:** high

**What is wrong.** The limit applies to every engine-driven change, raises included. If the engine moved a case to `review` on Monday, a Tuesday corroboration that meets the `urgent` row (row 2, three independent concerns or a safeguarding-tagged pair) is held.

**Why it matters here.** The limit exists to stop oscillation. Applied to raises, it delays the tier whose SLA is "route now".

**Fix.** The hold applies to lowerings and to repeated reversals only. A raise into `checkin` or `urgent` is never held. Add the case to S19.

Decision (2026-09-24): Accept.

#### F09 · The safeguarding clocks and routes misread ADEK: the 24-hour duty is each staff member's, and suicidal ideation goes to leadership immediately

**Severity:** serious · **Where:** 04 §5.1 (04:442), §5.3 steps 7 and 8 (04:485, 04:486), §5.7 (04:503), the `immediate_risk` field (04:468); 06 B3.5 (06:184), §9.2 (06:1031) · **Confidence:** high on the ADEK texts (checked in ADEK's own PDFs)

**What is wrong.**
1. ADEK's Student Protection Policy v1.1, clause 3.1, puts the duty to report suspected maltreatment to the ADEK Child Protection Unit within 24 hours of suspicion on school staff, each of them. Pass 4 attributes the clock to the institution or the coordinator, labels the countdown "the school's reporting window", and shows the direct-report banner only at 24 hours unacknowledged, which is exactly when the counselor's own window closes.
2. ADEK's Student Mental Health Policy, clause 3.5.1(b), says the school counselor shall immediately inform school leadership in cases such as suicidal ideation or severe substance abuse; 3.5.1(a) sends maltreatment and potential self-harm to the coordinator. The plan routes a student safety alert to the counselor and only after two school hours unopened to the safeguarding route (04:503), and never to leadership. The Mental Health Policy is not cited anywhere.
3. Student Protection Policy 3.7 sends emergencies to Police 999 and the Principal. `immediate_risk = yes` on the referral form triggers nothing.

**Why it matters here.** A counselor who follows CAROS's clock can miss a personal legal duty. A student's suicidal ideation can sit two school hours before anyone but one counselor is told.

**Fix.** Show the direct-report route and the counselor's own 24-hour countdown from the moment of escalation, labelled as the reporter's duty. Route by category: suicidal ideation and severe substance use to the counselor and a named leadership contact immediately; maltreatment to the coordinator immediately. `immediate_risk = yes` shows 999 and the Principal's contact and notifies the route at once. Cite the Mental Health Policy in pass 4 §1.1.

Decision (2026-09-24): Accept with a change: routing targets per category (leadership contact, CPO) are school configuration confirmed with ACS's CPO, not hard-coded.

#### F10 · Teachers have no safeguarding route in CAROS, and their worst observation lands at "this week"

**Severity:** serious · **Where:** 03 §4.5 (03:380 to 03:395), §7.2 rows 2, 7, 8, 12; 04 §3.6 (teachers have no `safeguarding` row), §3.4 (04:300), §2.3 and §3.3 (04:462: the lead capability sits on a counselor membership); 01 capability seed (01:678 to 01:689); 05 §6.2 (05:521: the screen covers student and mentor text only); 06 B3.14 (06:193) · **Confidence:** high on the text; medium on how often teachers would use CAROS for a disclosure

**What is wrong.** A single teacher concern with the most severe tag ("Distressed or upset") is `moderate`, which alone is row 12 (`review`, this week). A teacher cannot escalate (`es` is counselor-only), teacher flag text is never screened (the safety screen reads student and mentor text only; the engine never parses free text), and the flag modal says nothing about reporting a disclosure directly to the coordinator. Subject teachers and Extended Essay supervisors cannot flag a student outside their roster at all. The safeguarding lead must hold a `counselor` membership and sees concerns only when a counselor escalates.

**Why it matters here.** PRODUCT.md calls teachers "the school's earliest and cheapest signal". ADEK and Wadeema make every staff member a mandated reporter. A disclosure typed into CAROS's concern box would wait for a weekly review while the teacher's own 24-hour window runs.

**Fix.** Put the school's rule in the flag modal: "If a student told you something that suggests harm, report it to [the coordinator] now. This form is not a safeguarding report." Add a safeguarding flag kind that goes straight to the safeguarding route as a referral, with the same content rules as the escalation email. Run layer 1 of the safety screen on teacher flag text. Let any staff role hold `safeguarding_lead`. Give subject teachers and supervisors a concern path for students they teach outside a roster.

Decision (2026-09-24): Accept.

#### F11 · The student safety message says "call any time", and most of the numbers it lists are not 24-hour lines

**Severity:** serious · **Where:** 05 §6.4 (05:551 to 05:558), question 129 (05:1202); D68 (05:1037); 06 B5.12 (06:254) · **Confidence:** medium-high (from published sources checked for this review; the school must confirm)

**What is wrong.** The default message reads "call one of these, any time". Of the seeded lines, only 800-SAKINA (Department of Health, 24/7 since March 2026) and DFWAC 800111 are documented as 24/7. Estijaba 8001717 rests on a 2021 source and had daytime hours in 2022; no current source shows it still offering psychological support. The Family Care Authority's published hours for 800444 are office hours. No primary source publishes 116111's hours. 116111 and 800444 are lines for reporting abuse, not crisis support, and the message does not say so. For a Dubai school the Community Development Authority's 24-hour child protection line (800988) is missing. The cited 116111 page is a 2016 release republished in 2021.

**Why it matters here.** This text is shown to a child at the moment a disclosure is detected, possibly at night.

**Fix.** Split the list into "someone to talk to now" (24/7 lines only, currently 800-SAKINA; for Dubai, DFWAC) and "to report that a child is being harmed" (116111, 800444, and 800988 for Dubai), each with hours. Drop "any time" unless every listed line is 24/7. Remove Estijaba until a current source exists. The CPO confirms the list each term (question 129) and the tenant stores a `verified_at` per number.

Decision (2026-09-24): Accept with a change: the checked numbers are a draft; ACS's CPO confirms the list before any student sees it, and each number stores a last-verified date.

#### F12 · Safety alerts are a second route to the Child Protection Officer without invariant 5's guarantees

**Severity:** serious · **Where:** 04 §5.7 (04:503); 05 §6.5 (05:564), D68 (05:1037); 06 B3.8 (06:187), B5.12 (06:254) · **Confidence:** high on the route and the missing uniqueness; medium that the unopened-alert route is an email

**What is wrong.** An unopened safety alert routes to the safeguarding route's first recipient "exactly as an unacknowledged referral would", and immediately when the model sets `means_or_plan_mentioned`. No counselor act and no reason are recorded. `signal.safety_alert` has no uniqueness per student or episode, so three flagged messages in one session route three times, and a counselor's escalation of the same concern adds a fourth notice. Pattern-only routing writes no named audit action. B3.8's template list has no template for the counselor alert email or this route, so the identifiers-only content test never runs on them.

**Why it matters here.** Invariant 5 requires a reason, no double-firing and an audit record for the act that reaches the CPO.

**Fix.** Route through `signal.escalation` as a system-raised referral with a fixed reason code, one per student episode, deduplicated against any counselor escalation; or send the CPO only an "alert unopened" reference. Add both templates to B3.8 with the content test. Add the audit actions. Declare the route at the top of pass 4.

Decision (2026-09-24): Accept, option (b): the CPO receives a reference-only "alert unopened" notice, never an automatic referral; a person decides whether to escalate. Add the missing templates and audit actions.

#### F13 · Students can read the safety alerts raised about their own words

**Severity:** serious · **Where:** 05 D68 (05:1037: "data class `student_voice` for the alert"); 04 §3.6 `student_voice` row (04:334: Student r/w SELF); 01 grants on the `signal` schema to the student tier · **Confidence:** high

**What is wrong.** The alert row carries the categories flagged, the urgency, who it was routed to, the disposition (`escalated`, `referred_externally`), the counselor's reason and the escalation id. It is classed `student_voice`, which the student reads about themselves. The `safety_flag` column on `mentor.message` is visible to the mentor tier.

**Why it matters here.** A parent or other adult using the child's phone (student sessions last seven days) can see that a referral was made. A grooming mentor can learn which messages were flagged.

**Fix.** A staff-only class for alerts. Deny `safety_flag` and extraction columns to the student and mentor tiers. Add a per-role test with a flagged fixture.

Decision (2026-09-24): Accept.

#### F14 · Subject-access packs release staff-only material by default and can reveal that a referral exists

**Severity:** serious · **Where:** 04 §7.4 (04:638 to 04:644), Challenge 9 (04:907); 05 §8.5 (05:718); 06 B4.3 (06:214), §9.3 (06:1046); CONTEXT §3 "Signal visibility" · **Confidence:** high on the text; the legal answer is counsel's

**What is wrong.** Defaults: counselor notes included; engine evaluations included; AI generations about the student included (co-pilot answers and briefs carry tier words and levels); and the access history lists the role of every reader. `safeguarding` rows are excluded, but reads by the safeguarding lead under the escalation scope, `ESCALATED_SAFEGUARDING` audit rows, `case.escalated` events, safety alerts and meetings with outcome `escalate` are not. B4.3's test requires every registered table to appear. The reviewer is the caseload lead, who by the matrix sees an escalation's existence and status only. A parent can file for a student who is 18. Pass 4 declares no departure from "tiers, signals, evidence chains and counselor notes are staff-only".

Separately, the PDPL's Article 13 is a right to information about the processing, with refusal grounds for requests that conflict with investigations by competent authorities (13(3)(b)) or affect others' data (13(3)(d)); it does not expressly require copies. The pack's scope rests on a reading of the law that is broader than its text.

**Why it matters here.** The requesting parent may be the subject of the concern. A routine request can tip them off.

**Fix.** Until counsel answers C7 and C8, exclude by default: `signal` rows, AI generations, notes, anything linked to an escalation or safety alert, and reads under the escalation scope or with purpose `escalation`. Route any request about a student with an escalation to the safeguarding lead. Make inclusion of each professional record an explicit act. After 18, only the student may request. Declare the departure at the top of pass 4. Add an escalated-student fixture to B4.3.

Decision (2026-09-24): Accept, settled by C4: default pack excludes professional records; per-item inclusion by the school; B4.3 test rewritten to match.

#### F15 · Families and students would read staff material because data classes are bound per table

**Severity:** serious · **Where:** 01 `auth.protect()` calls: `core.meeting` as `family` (01:3774), `family.message` and `family.contact_log` and `family.guardian_link` as `family` (01:3857 to 01:3861), `doc.file` as `documents` (01:3868), `ai.generation` as `ai` (01:3875), `events.event` as `reporting` (01:3881); 04 §3.6 rows for `family`, `documents`, `ai`, `reporting`; grants to the guardian and student tiers · **Confidence:** high for a literal build (follows from F02)

**What is wrong.** Because the matrix's qualifiers have no mechanism (F02), each table gets its class's whole scope:
- parents and students read meeting rows (notes, outcome `escalate`), the counselor's contact log, and both guardians' message threads; the guardian tier can update `guardian_link`, so one parent can end or unverify the other's link;
- students and parents read every document about the child, including `reference_letter` and anything classed `safeguarding` or `case_note`, because the policy ignores `kind` and the row's own class; the caseload lead and support read raw SIS exports, which keep every column the school sent for 90 days;
- students read every AI generation about them, including meeting briefs and single-student co-pilot answers;
- the student and guardian tiers can update `storage_key` on files.

**Why it matters here.** Custody disputes and abuse cases are where these rows matter most. "Students and parents never see tiers, signals or notes" is a decision in CONTEXT §3, and meeting notes are notes.

**Fix.** Move meetings and contact logs to a staff class. Scope messages by sender and recipient. Guardians read only their own link row and never write it. Key document policy on the row's `data_class` and `kind`; raw exports to `school_admin` only, under step-up, never to support. A feature-and-kind predicate on `ai.generation` so students read only their own discovery and Extended Essay feedback. Column-level `UPDATE` grants only.

Decision (2026-09-24): Accept.

#### F16 · The capability design gives welfare access to people who are not counselors

**Severity:** serious · **Where:** 04 §2.5 (04:247), §3.3 (04:289 to 04:296), §3.6 (04:338 safeguarding row, 04:328 config row), §5.2 (04:462); 01 capability seed (01:683 to 01:687), `auth.protect()` for `notify.*` and `auth.session` (01:3877 to 01:3879); 06 B3.3 (06:182), B3.6 (06:185) · **Confidence:** high

**What is wrong.**
1. Every capability sits on a `counselor` membership. An IT `school_admin`, a Principal holding `safeguarding_lead` for oversight, and the mentor coordinator can therefore self-grant 24-hour break-glass cover on any student and read and write signals and notes, with no rate limit. A `school_admin` runs the caseload-and-cover screen and can assign cover to themselves or grant themselves a capability; four eyes applies only to a second `school_admin`. `valid_to` is a date, so "24 hours" runs to the end of the next day.
2. Oversight members must hold `safeguarding_lead` (04:462), which grants school-wide read and write on `safeguarding`, so the Principal as oversight can read and close any referral, despite "never its content". The lead's "existence and status only" compiles to full rows, including `who_else_knows` and `outcome_note`.
3. `config` is readable school-wide by every counselor membership, and `notify.outbox`, `notify.in_app` and `auth.session` are protected as `config`. Every counselor, and support, reads every notice, outbox payload, session and cover reason in the school. If a mentor's seven-day invitation URL sits in an outbox payload, any counselor can accept it first and become a vetted mentor.

**Why it matters here.** The caseload boundary is the core promise to counselors and families (pass 4 decided caseload plus explicit cover). These paths bypass it without a log that anyone reviews, and one creates an insider route to an identity that messages minors.

**Fix.** Break-glass only for practising counselors, rate-limited, confirmed by the lead within the day, never self-assigned. Timestamps for validity. Four eyes for any capability grant. `school_admin` as its own role with no caseload path. A separate `safeguarding_oversight` capability with no data grants. Split `config` into per-table classes scoped to owner or recipient. Never persist a credential in the outbox: mint the token at send time.

Decision (2026-09-24): Accept.

#### F17 · The conversation gate and other approval gates rest on a non-null id and table-wide update rights

**Severity:** serious · **Where:** 01 `ib.selection` CHECK (01:2263), `core.meeting` (01:2104 to 01:2125), grants (01:3718 to 01:3722); 02 §7.4 (02:863 against 02:877); 06 B6.3 (06:273), backend `CLAUDE.md` (06:608) · **Confidence:** high on the schema

**What is wrong.** The CHECK requires only that `review_meeting_id`, `approved_at` and `approved_by_person_id` are not null. Nothing checks that the meeting belongs to this student, is of kind `selection_review`, happened after the current version was submitted, or has notes (`notes` is nullable, `kind_key` is free text). Resubmission deletes stale sign-offs but keeps the meeting, so version 2 can be approved on version 1's conversation. The student tier holds table-wide `UPDATE`, so a student can supply any meeting id and person id. The same pattern lets a student insert an active mentor pairing or edit a document request's status. Pass 2 lets a ManageBac import overwrite an approved pick's level (02:863) while also saying a mismatch is a conflict row (02:877). B6.3 tests only the null case.

**Why it matters here.** Invariant 6 is the reason the IB module exists. The backend `CLAUDE.md` promises "a CHECK and a domain guard"; the CHECK is not a guard.

**Fix.** An approval trigger that checks student, kind, the `held_at` window and non-empty notes. A `review_meeting_version` that must equal `version` at approval. State changes only through definer transition functions; column-level `UPDATE` grants. Pairings created only by the coordinator. Imports never write picks.

Decision (2026-09-24): Accept.

#### F18 · Google sends no RISC events for Workspace accounts, so "suspend the Google account" revokes nothing

**Severity:** serious · **Where:** 04 §2.1 deprovisioning point 2 (04:194); 06 B1 (06:43, 06:107), B1.15 (06:129), §1.13 (06:415), §9.1 (06:1017), O23 (06:1166); pass 4 §9.13 (04:758) · **Confidence:** high (Google's RISC page, checked 2026-09-24)

**What is wrong.** Google's Cross-Account Protection page states that it does not currently send security events for Google Workspace users. ACS's staff and students sign in with Workspace accounts. The receiver built in B1.15 will receive nothing for them. B1.15's acceptance test (a signed test event revokes a session) passes while the control does nothing in production. The thin slice grows by this item on the argument that it makes the school's leaver process the kill switch (06:415), and the G-REAL checklist lists it.

**Why it matters here.** Deprovisioning then falls to the optional nightly Directory read (O23) and to 12-hour staff sessions. A dismissed staff member keeps access for up to a day unless someone acts in CAROS.

**Fix.** Make the Directory API reconciliation mandatory, not optional, and run it hourly for staff. Add a school-side "revoke in CAROS" step to the leaver runbook. Drop RISC from the thin slice and the G-REAL list; keep it only for consumer accounts if mentors ever use Google.

Decision (2026-09-24): Accept.

#### F19 · Step-up relies on `prompt=login`, which Google does not support

**Severity:** serious · **Where:** 04 §2.4 step-up (04:242); 06 B1 scope (06:107), B1.14 (06:128) · **Confidence:** high on Google's documentation (checked 2026-09-24); medium on runtime behaviour

**What is wrong.** Google's OpenID Connect reference documents three `prompt` values: `none`, `consent` and `select_account`. It documents no `max_age`, and it returns `auth_time` only when requested through the `claims` parameter and enabled in settings. A browser with a live Google session may come straight back without re-authenticating, and the server cannot prove the re-authentication happened within ten minutes.

**Why it matters here.** Step-up gates raising and acknowledging escalations, the audit screen, every export, support grants, membership and route changes, rollback, break-glass and erasure. A step-up that proves nothing silently removes the second factor from all of them.

**Fix.** A B1 spike before B1.14: request `auth_time` through `claims`, reject tokens older than ten minutes, and test with a live session. If Google will not force it, step up with a CAROS-held passkey for staff (WebAuthn is already in the plan for mentors and parents).

Decision (2026-09-24): Accept.

#### F20 · Free text carries the "excluded" classes to the United States, and the pseudonymiser misses common names

**Severity:** serious · **Where:** 04 §0.4 point 6 (04:45), R6 (04:526), T20 (04:679); 05 §8.3 (05:692), leak scanner (05:696), family notice (05:718) · **Confidence:** high on the text; medium on real miss rates, which nobody has measured

**What is wrong.** Pass 4 promises "no safeguarding, health, nationality, fairness or audit data ever". R6 enforces that for columns. Free text goes out anyway: discovery answers, reflections, statement drafts, EE rationales, teacher flag bodies, parent messages, counselor questions. A disclosure of abuse, a diagnosis, a nationality ("when we fled Syria"), a religion or a family detail inside that text reaches US inference. The pseudonymiser uses the school directory as its only gazetteer, and its rule ("single given names and family names longer than three characters") is ambiguous about short given names such as Ali, Nur and Aya, which are common at ACS. It does not see nicknames, people outside the directory (siblings, relatives, a driver, a therapist) or Arabic script, though the safety lexicon is bilingual. The envelope's tenant layer identifies the school indirectly. The leak scanner runs over synthetic text whose names all come from the directory, so its zero is guaranteed and proves nothing about real misses. The disclosures the safety screen exists to send are the texts most likely to be flagged by Anthropic's trust-and-safety systems, which keep flagged content for up to two years even under ZDR.

**Why it matters here.** The notices and the DPA would tell ACS and parents something false. Counselor notes from counselors attached to Department of Health licensed centres may be health data under the ICT Health Law, which restricts transfer abroad.

**Fix.** State the truth in 04:45, R6 and the notices: the exclusions hold for columns; free text can carry any class. Replace "longer than three characters" with a rule tested on Arabic names and add Arabic-script and nickname handling. Measure pseudonymiser recall on a corpus written by people who did not build it. Strip the school fingerprint from the envelope. Treat personal statements as not pseudonymisable. Move the safety screen's layer 2 in-country first (pass 5 already names it as the first to move).

Decision (2026-09-24): Accept: the notices and DPA state that exclusions hold for columns and free text can carry any class; name rule tested on Arabic names, Arabic script and nicknames; recall measured on a corpus written by people who did not build the pseudonymiser; school fingerprint stripped from the envelope; personal statements treated as not pseudonymisable. The in-country safety-screen item is moot after C1.

#### F21 · The quarantined reader sends every free-text record abroad at save time, including records R6 excludes

**Severity:** serious · **Where:** 05 §7.2 (05:595, 05:615), D69 (05:1038), §9.6 (05:828); 04 R6 (04:526), §6.4 (04:545 to 04:559) · **Confidence:** high

**What is wrong.** "For every untrusted record kind, an extraction runs at save time." D69 adds extraction columns to teacher flags, parent messages, student reflections (including "I need to talk to someone" requests), statement versions, EE rationales and `mentor.message`. Pass 5 §7.2 says mentor message bodies are not extracted, which D69 contradicts, and R6 excludes them. Pass 4's per-feature allowlist has no row for the reader. The reader is a condition of features (5) and (6), so enabling Extended Essay feedback turns on extraction of parent messages and teacher flags, which no enabled feature reads.

**Why it matters here.** The school's written acceptance per feature (G21, R3) would not describe what actually runs.

**Fix.** Give the reader and the screen their own policy rows, allowlisted per record kind. Extract lazily, only for kinds an enabled writer reads. Drop `mentor.message` from D69. Never extract urgent requests. Add a test that fails when an extraction column fills with no consuming feature enabled.

Decision (2026-09-24): Accept.

#### F22 · The EU cold copy is keyed to a UAE-only key, so it cannot be restored in the disaster it exists for

**Severity:** serious · **Where:** 04 §9.7 (04:721); 01 open decision 1 (01:3949); 06 G22 (06:1002), R6 (06:1064) · **Confidence:** high

**What is wrong.** "A nightly encrypted dump to an EU region ... under a key that lives only in the UAE Managed HSM ... would survive it." If both UAE regions are lost, a key that exists only there is lost too, and the EU ciphertext cannot be decrypted. Key Vault backups restore only within the same Azure geography. To work, key material must exist abroad (a Managed HSM replica in an EU region, or security-domain shares held outside the UAE), and the restore would run abroad.

**Why it matters here.** This is the design the plan asks ACS and counsel to approve as a DPA clause (G22), in response to the AWS region loss that pass 1 documents.

**Fix.** Tell ACS and counsel the real choice: EU ciphertext with key material held outside the UAE by named people, a named restore region and trigger, and an EU restore drill on synthetic data; or in-country only with the risk stated. Add ADEK consent (F04) to either.

Decision (2026-09-24): Accept.

#### F23 · Real data has undesigned routes into development tooling

**Severity:** serious · **Where:** 06 C3 (06:1095), §2.4 (06:490), hooks (06:679 to 06:680), §5.8 nightly jobs (06:810); 04 §9.11 (04:737); 05 §10.2 and question 132 (05:845, 05:897, 05:1208); 03 §15.2 (03:1015 to 03:1024) · **Confidence:** high on the gaps; medium on likelihood

**What is wrong.**
1. **Coding-agent sessions.** The plan's controls are a write hook that blocks strings from ACS's published staff names and a rule that sessions hold no support grant. Nothing checks what a session reads, command output or pasted text. The plan's own tasks will put real data in front of an agent: debugging a student whose evaluation threw (03 §13.4), diagnosing a rejected import, forensics on a restore, onboarding sample rows whose free-text columns are kept. Fable 5.1 keeps prompts for 30 days, and nothing pins where a coding session's inference runs.
2. **Eval cases.** Counselors supply twenty real questions each "about your caseload" (question 132), and every eval case lives in the repository, on GitHub, in CI and in eval calls. The no-real-data test checks staff names, not student names.
3. **The backtest.** Two years of history plus the counselors' handled-case records, "pseudonymised with the same key", processed by Python tooling (`ruptures`). No pass says where it runs or who holds the key.
4. **The production canary runs from GitHub-hosted runners** in the nightly CI job, with a production credential, outside the country; if the leak it tests for ever happens, the runner's logs capture it.

**Why it matters here.** Each is a transfer outside the UAE, or into a Covered Model's retention, that the residency decision forbids and the DPA would not describe.

**Fix.** Run the backtest, the canary and restore-drill checks as jobs in UAE North, with only aggregates leaving. Collect counselors' questions in the tenant; a named person rewrites them onto synthetic personas in-country. Add Read and Bash hooks that refuse paths outside the repository and commands such as `az` and `psql` against production. Keep no production credential or signed-in production browser profile on any machine that runs an agent. Name the coding assistant in the DPA if counsel says so (C23).

Decision (2026-09-24): Accept.

#### F24 · Shadow mode runs a different engine, and its exit bars cannot be met by the plan's own numbers

**Severity:** serious · **Where:** 03 §1.3 (03:100), §1.4 (03:98 to 03:101), §11.1 (03:765 to 03:775), §14.1 (03:936), §14.3 (03:950), §14.5 (03:960 to 03:970), D25 (03:1115); 01 `evidence_item` (01:1936 to 01:1957); 06 §1.11 (06:385) · **Confidence:** high on the structure and the arithmetic

**What is wrong.**
1. **A different engine.** Shadow runs write "no case rows", so every night starts with empty case state: no hysteresis, no relapse, no recovery to `good`, no cool-downs, no holds, no auto-review. What shadow measures is not what goes live. `evidence_item.case_id` is `NOT NULL`, so shadow evidence has nowhere to be stored, and `v_shadow_queue` keeps nightly runs only, dropping the backfill and event runs §13.5 says feed the comparison.
2. **The review bar cannot be met.** Pass 3 plans on about one genuine episode a week per 87 students and reports about 11 noise `review` cases a week under normal noise (29 under heavy tails). Precision at `review` is then about 8% (1 in 12), against a bar of 25%. At `checkin` the plan's own figures give roughly 50%, against a bar of 60%, and far less under heavy tails.
3. **The bar is a coin toss at pilot scale.** Eight weeks yields perhaps 10 to 40 check-in-or-above cases school-wide. A 95% interval on 12 correct out of 20 runs from 36% to 81%. An engine that is truly 50% precise clears 60% about a quarter of the time at 20 cases; a truly 70% engine fails about one time in nine.
4. **Too little history.** "At least six weeks of weekly data" is shorter than the 12-week minimum for the full detector ladder.
5. **Not blind.** The counselor answers "would you have wanted this?" with the engine's evidence in front of them.

**Why it matters here.** G-LIVE is the gate between a pilot and a product. As written it will either block for reasons that are not the engine's fault or pass on noise.

**Fix.** Keep a shadow case state and store shadow evidence against the evaluation. Include backfill and event runs. Import at least twenty weeks of history before shadow starts. Replace point thresholds with a pre-registered interval pooled across counselors and a minimum of about 40 cases. Blind the judgement by mixing engine cases with matched unflagged students. Fix F05 first, because the noise figures depend on it.

Decision (2026-09-24): Accept: shadow keeps its own case state and stores evidence against the evaluation; backfill and event runs included; at least twenty weeks of history imported before shadow; pooled pre-registered interval with a minimum of about 40 cases; blinded judgement with matched unflagged students; F05 fixed first.

#### F25 · The academic domain is inert for most of each year, and the termly fallback floods or never fires

**Severity:** serious · **Where:** 03 §3.2 (03:170, 03:176 to 03:179), §5 (03:449 to 03:455), §3.7 (03:273), §4.8 (03:438 to 03:440), S21 (03:1007); 02 §6.2 (02:710), §6.3 (02:729) · **Confidence:** high on the arithmetic; medium on ACS's grading frequency

**What is wrong.**
1. Academic baselines reset every August because each section is a new series, and history counts only weeks with a graded assessment. Computed for quiet students over 36 teaching weeks: at 9 graded weeks a section per year, 86% of sections never reach the 12-week minimum and the median section gets a band only in week 28; at 18 graded weeks, the median section gets a band in week 17. Levels are capped at weak until then. The flagship case, a strong student's quiet decline, cannot be caught in a sparsely graded IB subject in the first semester, which for Grade 12 is the application season. Pass 3 §5 says a history import makes "any section that continues" warm, which §3.2 makes impossible.
2. The retrospective rule compares a term with at least two prior terms "in the same section". With semesters it can never fire. With quarters, two equal prior terms give a scale of zero, floored to half a grade, so a one-step drop is z = 2: 38 to 55 of 87 quiet students get a termly `review` on the Q3 export day (computed).
3. Weekly count windows of ten school days overlap by half, which builds in week-to-week correlation of about 0.5; computed, correlation of 0.3 alone roughly quadruples the moderate rate. §4 defines about 14 series per student against the 10 simulated.

**Why it matters here.** Cadence is CONTEXT §3's decided weak point, and pass 2's honesty about it is undone if the academic domain silently does nothing for months.

**Fix.** Carry academic baselines across the year within a subject for two-year courses. Count history in assessments, and use the self-starting band instead of the cap. When a termly file carries per-assignment rows, run the weekly engine over the term as a backfill capped at `review`; for working grades only, require a two-step drop or a drop held across two windows. Use non-overlapping windows for counts. Say on screen which domains are still building a baseline.

Decision (2026-09-24): Accept.

#### F26 · The common-cause guard makes a student's level depend on other students

**Severity:** serious · **Where:** 03 §7.6 (03:582), C5 (03:1257), property test (03:1011), `sweep.finalize` (03:881 to 03:882); 06 B2.4 (06:150), O40 (06:1188) · **Confidence:** high

**What is wrong.** When more than 25% of students are outside their band in a domain in a week, "levels from that week alone are capped at weak". Pass 3's own C5 concedes "it is the one place a student's tier depends on data about other students". That contradicts invariant 2 and fails pass 3's own property test (a student's output is unchanged when every other student's data changes). `StudentEvaluationInput` carries no field for it, and the share is computed in `sweep.finalize`, after cases are written. The "off (100%)" option sits outside the schema's stated bounds.

**Why it matters here.** Invariants are not open to trade-off. A student in genuine decline is capped in exactly the week the whole school is disrupted.

**Fix.** Drop the automatic cap. Keep the ops note and the prompt to declare a `calendar_period`; a declared period then suppresses through the calendar, which is data about the school, not about peers. Keep the property test strict.

Decision (2026-09-24): Accept.

#### F27 · ManageBac's API does expose CAS, and probably the Extended Essay, so pass 2's central integration conclusion is wrong

**Severity:** serious · **Where:** 02 §7.4 (02:856, 02:869, 02:871), Challenges (02:1109), D10 (02:1093), §7.9, open decision 5; 06 B9.3 (06:363), R12 (06:1070), O27 (06:1170) · **Confidence:** medium-high (API reference read directly; the EE part rests on help-page snippets)

**What is wrong.** Pass 2 says no CAS or EE endpoints appear in the v2 to v2.3 index, so "read IB records from ManageBac" is a workflow decision, not an integration. The index it cites lists a Projects resource in every version. `GET /v2p3/year-groups/{id}/projects/cas/experiences/students` returns each student's experiences with approval status, hours per strand, supervisor, CAS-project flag and dates; `.../projects/cas` returns the hours required. PBL project endpoints return proposals, reflections and supervisors, and ManageBac documents a DP Extended Essay PBL template for first assessment 2027. TOK has no endpoint and CAS reflection text is not exposed. Pass 2 also pins v2p2, which ManageBac is retiring in favour of v2p3.

**Why it matters here.** CONTEXT §3 says CAROS builds the overlapping surfaces but designs to read from the incumbents. The plan offers ACS "ManageBac stays, modules off" or "CAROS with a one-time import" when a read-only mirror is possible.

**Fix.** Add a `managebac_readonly` record-system value to D10 for CAS and EE, design the mirror in §7.4 and §7.9, move the ManageBac adapter's CAS mirror earlier than B9 if ACS keeps ManageBac, pin v2p3, and ask ACS whether the EE PBL template is enabled (question 78).

Decision (2026-09-24): Accept, settled by C10: add managebac_readonly to D10, design the mirror in 02 §7.4 and §7.9, pin v2p3, move the CAS mirror earlier than B9, ask ACS question 78 about the EE PBL template.

#### F28 · At least nine kinds of outbound notification exceed the two that were decided, and none is declared

**Severity:** serious · **Where:** CONTEXT §3 "Outbound notifications"; 01 (01:326, 01:2639, 01:3935); 04 §0.1 (04:12), §2.3 (04:219, 04:222), §3.3 (04:290), §3.7 (04:352, 04:356), §5.3 (04:485 to 04:486), §5.7 (04:503), open decision 8 (04:928); 06 B3.8 (06:187), B5.4 (06:246), B6.14 (06:284), §7.4 (06:949) · **Confidence:** high

**What is wrong.** CONTEXT §3 allows two: nudges to students and the email to the Child Protection Officer when a counselor escalates, and parents receive no email. The plan adds: chase emails to reference writers; Extended Essay milestone nudges to supervisors and coordinators; meeting confirmations to parents; escalation reminders at 60 minutes, deputy routing, oversight emails to the Principal, and a no-outcome reminder at 24 hours; a safety-alert email to counselors; the route to the CPO from unopened alerts; the mentor invitation email; grooming routes to the coordinator and CPO; the break-glass digest, grant notices, the monthly report and support-grant emails to the school; and SMS to the CPO proposed for v1.1. Pass 4 declares only parent activation, as a "narrowing". B3.8's template list covers six keys, so chases and the alert email bypass the content test.

**Why it matters here.** Fable was told to challenge decisions openly and never depart silently. Several of these are defensible (the safety-alert email, deputy routing), which is exactly why Davide should decide them.

**Fix.** List every outbound message in one table in pass 4, with recipient, channel and content allowlist. Davide accepts or rejects each (see judgment calls C2 and C3). Every kept kind gets a template and the content test; the rest become in-app.

Decision (2026-09-24): Accept, settled by C2 and C3: declare the email inventory (parent transactional per C2, staff safety per C3) and update CONTEXT section 3.

#### F29 · A real ACS staff member's name is seeded as a demo persona in the tenant shown to other schools

**Severity:** serious · **Where:** 06 B0.11 (06:94); PRODUCT.md (Mr. Diaz, line 62; "No real ACS student, staff member or outcome may be represented"); `index.html:4407`, `:4539` to `:4545`, `:4821`; 04 §9.11 no-real-data test (04:737); accepted decision C4 (06:1085); G2 (06:982) · **Confidence:** medium-high (depends on the prototype's "Mr. A. Diaz" being the ACS person PRODUCT.md names)

**What is wrong.** PRODUCT.md names Mr. Diaz as the ACS person whose workflow shaped the IB module. The prototype makes "Mr. A. Diaz" the IB coordinator who approves fabricated selections, and pass 6 seeds "Mr Diaz `ib_coordinator`" as a demo persona. Under accepted decision C4 the synthetic ACS tenant becomes the sales demo shown to other schools. G2 covers applying ACS's name to synthetic data; it does not cover a named staff member's apparent actions shown to third parties.

**Why it matters here.** Invariant 9 and PRODUCT.md's absence rules. A screenshot of a real person "approving" fabricated student records can travel.

**Fix.** A fictional coordinator name in the seed. Add every name in PRODUCT.md and the prototype that belongs to a real person to the blocklist. Extend G2's consent letter to sales demos to other schools, or record that it does not cover them.

Decision (2026-09-24): Accept: fictional coordinator name in the seed and the prototype; every real person's name in PRODUCT.md and the prototype added to the blocklist; G2's consent letter extended to sales demos to other schools.

#### F30 · Unsourced prototype figures go into global reference tables and render with a label

**Severity:** serious · **Where:** 01 DR-8 port (01:369), `ref.cost` (01:1503, no `school_id`); 06 B5.2 (06:244) · **Confidence:** medium-high

**What is wrong.** The prototype's tuition, living costs, offers and requirements are ported as `seed://prototype` rows that render "visibly labelled unsourced". `ref.*` is global, and nothing keeps these rows out of production, so real parents could read prototype tuition figures.

**Why it matters here.** Invariant 3: every number a user sees traces to a source. A figure labelled "unsourced" is still an unsourced number, and demonstration content on a real tenant breaks invariant 9's separation.

**Fix.** Never render a `seed://` number; show "not on file" instead. Load `seed://` rows in staging only. Add a production check that no `seed://` source exists.

Decision (2026-09-24): Accept.

#### F31 · The second school proves labels, not substance: ADEK is hard-coded for every tenant and the engine is validated on ACS only

**Severity:** serious · **Where:** 01 `core.school.regulator` (01:509, 01:522), DR-8 (01:386, 01:388); 02 §8.2; 03 §7.2 rows 1 and 14, §15.1 (03:979 to 03:1011); 04 §5.1 to §5.3 (04:442 to 04:486), §7, §9.12, D56 (04:791); 06 B2.16 (06:162), B3.4 brief (06:516), B8 (06:328, 06:345), §9.2 (06:1031 to 06:1032) · **Confidence:** high; medium on the Dubai contacts, which come from one school's published policy

**What is wrong.**
1. `regulator` is stored and never read. Every tenant gets ADEK's direct-report banner and numbers, the ADEK 24-hour countdown, outcome codes "aligned to ADEK's flows", "the two ADEK guidance indicators", a review pack organised by ADEK's Digital Policy 5.5.1, and a retention rationale built on ADEK's Records Policy. Pass 4 has no KHDA or Dubai analysis at all. The Wellesmere string test checks "Designated Safeguarding Lead", not the absence of "ADEK".
2. `engine-reproduces-seed` imports only the twelve ACS packs. Wellesmere's eight authored cases have no expected results and disappear when the narrative layer is retired. Several cannot be produced from its fixture: the gradebook has no due dates or missing flags, so the submission path of `post_offer_decay` cannot fire; termly delivery caps at `review` while relapse carries a minimum of `checkin`, with the precedence unresolved; the mock dip feeds evidence text, not a level. The ordinal scenarios use IB scales; S23 is the fifteen ACS cases.
3. Both tenants use Asia/Dubai and the same weekend, so no timezone or weekend hard-coding can be caught. D56 already hard-codes `'Asia/Dubai'` in a generated column and says the real migration will read the tenant's timezone, which a generated column cannot do.
4. The checklist asserts "UCAS-only deadlines" while the seed gives Wellesmere two Common App targets.

**Why it matters here.** Pass 1 put the second school in every test "because that is the only reliable way to catch ACS-shaped assumptions". As built it passes while the Dubai tenant shows Abu Dhabi authorities in a banner a counselor cannot dismiss.

**Fix.** A versioned `regulator_profile` keyed by `regulator`: contacts, reporting window and its owner, citations, outcome vocabulary, indicators, retention minimums, attendance-reason family, review-pack checklist. A KHDA profile, or an explicit empty one that shows no regulator-specific text. A Wellesmere expected-result list and a fixed fixture. A test that fails if "ADEK" appears on any Wellesmere screen or template. Give one synthetic tenant a different timezone and weekend. Replace D56's generated column. Remove "UCAS-only".

Decision (2026-09-24): Accept.

#### F32 · UCAS changed both the personal statement and the reference, and the model predates both

**Severity:** serious · **Where:** 01 `uni.statement` and `statement_version` (01:2668 to 01:2694), `uni.reference_letter` (01:2714 to 01:2754), `v_application_pack.statement_chars`, `ref.deadline` (01:1532); 03 §9 `stmt_watch_below` (03:649); 05 §3.9, §3.10; 06 B5.6 and B5.7 (06:248 to 06:249); `index.html:7599` · **Confidence:** high (UCAS guidance)

**What is wrong.**
1. From 2026 entry UCAS asks three questions instead of one essay, each answer with a minimum length and all three sharing 4,000 characters. The cycle open now uses this format. The plan models one statement with a single `body`, completeness as `char_count / limit`, and a watch rule that treats the ceiling as the target. The guidance ported from the prototype's `PS_SYSTEMS` describes the old format.
2. Since 2024 entry a UCAS reference is one per applicant in three sections (a centre statement that advisers reuse, extenuating circumstances, supporting information), with predicted grades entered as part of it. The plan models US-style letters (`kind IN ('counselor','teacher')`), no sections, no centre statement, no snapshot of the predicted grades that were submitted, and no internal reference deadline per school. Nothing marks the extenuating-circumstances section, which draws on welfare facts, as never model-drafted.

**Why it matters here.** Most of ACS's own seeded targets are UCAS universities, and Wellesmere is UCAS-first. The letter engine's "voice matching" would be trained for the wrong artefact.

**Fix.** A `ref.statement_format` per destination system and entry year (sections, per-section minimums, total limit) and completeness defined as every section at or above its minimum within the total. A `format` column on references with sections validated per format, a versioned centre statement, a predicted-grade snapshot taken at submission, and the extenuating-circumstances section flagged `generation_forbidden`. A per-school reference deadline.

Decision (2026-09-24): Accept.

#### F33 · A British school's pastoral structure cannot be represented

**Severity:** serious (second school) · **Where:** 01 `auth.perm_scope` (01:619 to 01:631), `caseload_one_primary`, DR-8 (01:386); 02 §4.8, §8.2 (02:1028); 04 §0.2 (04:24), §3.3 · **Confidence:** high

**What is wrong.** Form tutors, Heads of Year, the Head of Sixth Form or UCAS adviser, and the DSL share responsibility for a British student. CAROS allows one primary counselor per student, cover of at most 30 days, and teacher visibility only through taught sections. The Wellesmere fixture carries `TutorStaffId` and `HeadOfYear StaffId`, which are imported into nothing. Pass 4 removed the prototype's "Year head" row on the ground that no such role exists, which is true at ACS only.

**Why it matters here.** Invariant: roles can be added as data. The scope model cannot express year-group or tutor-group responsibility without a migration.

**Fix.** `year_group` and `tutor_group` scopes, capabilities such as `year_lead`, `tutor` and `ucas_adviser`, and concurrent assignment kinds, with case ownership still single.

Decision (2026-09-24): Accept.

#### F34 · The materialised reporting views sit outside row-level security

**Severity:** serious (blocking before B8) · **Where:** 01 DR-6 (01:239); 03 §13.2 (03:882); 04 T1 (04:660: "reporting views `security_invoker`"); 06 B8.12 (06:345), §1.12 (06:405) · **Confidence:** high on PostgreSQL behaviour; medium on how B8 would build them

**What is wrong.** Materialised views have no row-level security and no `security_invoker` option, and `REFRESH` runs as the owner. Refreshed by a role that bypasses RLS they hold every tenant; refreshed inside one school's context they hold only that school. T1 lists `security_invoker` reporting views as a control, which does not exist for this object type. The per-teacher concern-rate report, for the caseload lead only, would ride in these views. The `reporting` schema is not in pass 1's schema list, and the convention test checks tables only.

**Why it matters here.** A cross-tenant read through a path the threat model says is controlled.

**Fix.** Per-tenant aggregate tables with RLS and one writer. Or views owned by a no-login role, `SELECT` revoked from every tier, exposed only through definer functions that filter on `auth.current_school()` and check the role. Add materialised views to the convention test.

Decision (2026-09-24): Accept.

#### F35 · CAROS staff can write into real tenants outside the support-grant model, and grants are not bound in the database

**Severity:** serious · **Where:** 02 §9 steps 3, 5, 8, 11, 17 (02:1055 to 02:1069), §2.10 (02:367); 04 §2.5 (04:247), §3.7 (04:351 to 04:355), D37 (04:772), D44 (04:779); 01 `auth.allowed()` support branch (01:967 to 01:969), support-tier grants (01:3725 to 01:3726); 06 B1.13 (06:127), B4.12 (06:223), §1.11 (06:384) · **Confidence:** high on the gaps

**What is wrong.**
1. The tenant CLI, run by CAROS, creates the tenant, the first `school_admin` and `caseload_lead`, the domains, the safeguarding route and the modules. CAROS authors mapping profiles, loads a caseload CSV with no preview, and support may run rollbacks. None of these has a defined database identity or audit action, and pass 4 says CAROS creates no membership in a real tenant except through a school-approved grant.
2. `auth.school_domain` has no RLS and no audit trail. Mapping a CAROS-controlled Google domain to a real tenant (as staging already does for testers in B1.13), plus a person and a membership, gives full staff access with no grant.
3. The support branch accepts any open grant in the school, whoever the operator is and whatever tables or class it names. The support tier holds `SELECT` on base tables, so masking through views can be bypassed. Two CAROS operators can activate a grant without the school.

**Why it matters here.** Pass 4 names insider access by CAROS staff as threat T7, and the support path is "designed to be embarrassing to use". These routes are not.

**Fix.** Every CAROS write is a school-approved, time-boxed write grant naming its tables, executed through audited domain functions. Domain mapping requires DNS proof, `school_admin` approval and an audit row. Caseload loads go through the Studio with a security section. The support policy checks the operator (`actor_label`) and the table list; revoke base tables from the support tier; exclude raw exports and the outbox from grants.

Decision (2026-09-24): Accept.

#### F36 · The worker's cross-tenant work is undesigned, and the tenant status model skips the pilot school

**Severity:** serious · **Where:** 01 DR-2 (01:111), `core.school.status` (01:538), outbox index (01:3358); 03 §13.2 `sweep.schedule` (03:879); 04 §3.2 (04:281), §1.5 (04:149); 06 §1.11 (06:379 to 06:385), §7.4 (06:932) · **Confidence:** high on the text; medium on pg-boss wiring

**What is wrong.**
1. `sweep.schedule` runs "for each active school", and the sweep-not-completed alert fires "for an active school". Pass 6 keeps ACS at `onboarding` until G-LIVE (06:385: "`core.school.status = 'active'`"). As written, no shadow sweep runs for ACS and no alert fires for it. Pass 4 refuses real imports until the legal-basis attestation exists, "the tenant stays `onboarding`" (04:149), without saying what the status becomes after it; the passes never define one status model.
2. Enumerating schools needs a cross-tenant read, but a school row is visible only inside its own context. RISC events, magic-link consumption, purge, partitions and anchors all start before any tenant is known. Pass 4 says the worker "holds no cross-tenant query path"; the design leaves the enumeration unspecified, and the easy answer is a bypass role.
3. pg-boss keeps job data, outputs and archives in one table with no RLS, written by the web app, and is not in the privacy registry, so erasure misses it.

**Why it matters here.** The component that touches every tenant every night has no database backstop where it dispatches work, and the status model would silently exclude the one real school.

**Fix.** One status model across passes (for example `onboarding`, `shadow`, `live`), with scheduling and alerting keyed on "holds real data", not "active". ID-only definer functions for enumeration and pre-tenant lookups. pg-boss under its own login with no tenant privileges; payloads validated as school id plus record ids; pg-boss registered for erasure with short retention. A test that a job for school A carrying school B's ids writes nothing.

Decision (2026-09-24): Accept.

#### F37 · The regulatory analysis has gaps that change the design, starting with the missing impact assessment

**Severity:** serious · **Where:** 04 §1.1 (04:57 to 04:88), §1.4 (04:133), §1.5 (04:145 to 04:155), §6.1 (04:513), §7.2 (04:610), §7.4 (04:638 to 04:644), §9.6 (04:713), counsel questions C3, C5, C7, C8 · **Confidence:** medium-high (checked against an unofficial English translation of the PDPL and ADEK's own PDFs; counsel must confirm)

**What is wrong.**
1. **No impact assessment.** PDPL Article 21 is the data protection impact assessment, mandatory for systematic automated assessment of personal aspects, including profiling, with serious effects. Pass 4 cites Article 21 as the record of processing (04:65, 04:133) and plans no assessment. The signal engine profiling minors is the textbook trigger. ACS as controller owns it; CAROS must supply it.
2. **Transfers.** Article 23's contract route is limited to countries without a data protection law and binds the recipient to the PDPL's own provisions and a supervisory authority there. EU standard contractual clauses do not do that. "Standard contract clauses" is a law firm's gloss.
3. **Bases for a minor.** The contract basis needs the data subject to be a party (the enrolment contract is with parents). The legal-obligation basis covers federal laws, not ADEK policies. ADEK's Digital Policy 7.1.2 and Student Mental Health Policy 3.6 require consent procedures and parental consent for structured counselling, which the plan does not model.
4. **Sharing child protection records.** Student Protection Policy v1.1 clause 4.2 limits sharing of case reports to named authorities. Whether holding them in a vendor platform fits the clause is never put to counsel.
5. **Health data.** Counselors attached to Department of Health licensed centres may produce health data under the ICT Health Law (localisation, 25-year retention). C5 asks only about SEN and medical fields.
6. **Breach notices.** PDPL 9(2) requires notifying data subjects of prejudicial breaches; ADEK Digital Policy 6.6.1 restricts incident communication to the provider and ADEK. The plan treats family notice as optional and does not flag the conflict.
7. **Retention.** Article 5(7) forbids keeping data after the purpose unless anonymised, and Article 8(4) makes processors erase or return it. Tombstones with uuids and salted hashes, and a seven-year audit copy after termination, are pseudonymised, not anonymised.
8. **The regulator.** On 14 June 2026 the UAE merged the Emirates Data Office into a new Federal Authority for AI and Data. The executive regulations were still unissued as of late August 2026.

**Why it matters here.** G-REAL depends on the DPA, the notices and the legal-basis attestation. Each rests on this analysis.

**Fix.** Add a DPIA to the G-REAL list, drafted by CAROS for ACS. Put items 2 to 7 to counsel as new questions. Name the new regulator in the DPA and breach flow. Correct the article citations in pass 4.

Decision (2026-09-24): Accept.

#### F38 · The Fable reservations and different-model reviews contradict each other and miss tasks whose errors are silent

**Severity:** serious · **Where:** 06 §4.1 (06:708 to 06:721), §4.2 (06:723 to 06:735), §4.3 (06:737 to 06:739), the task tables in §1 · **Confidence:** high on the contradictions; medium on which gaps matter most

**What is wrong.**
1. **§4.2 and the tables disagree.** §4.2 reserves B7.4, B4.8 and B9.7 for Fable 5.1; the tables assign all three to Opus 5.5 with a Fable review. §4.3 lists B5.7 as Fable-reviewed; its row has no reviewer. The B2 header puts the calibration scripts on Fable 5.1 at max effort; B2.9 is Opus 5.5 at medium with no reviewer. §4.1 sets xhigh for B2.10 to B2.13, B6.2, B6.3, B6.10, B7.4 and B7.13; every one of those rows says high.
2. **Silent-error tasks with neither Fable nor a different-model review:**
   - B2.9 calibration (the source of every alert-budget number; see F06);
   - B2.13 alert rules and watchdogs (silence is the failure they exist to prevent);
   - B2.8 and B2.15, the parameter bounds and the guards against switching a domain off;
   - B4.15 the shadow comparison report (the precision number that decides G-LIVE);
   - B4.6 retention purge jobs (irreversible deletion);
   - B7.5 the provider adapter (`inference_geo` on every call; a missing pin still returns 200);
   - B7.16 the circuit breaker and fallback account, and B7.18 the model promotion gate;
   - B8.12 reporting views (F34) and the two-populations rule;
   - B0.12 the demonstration marker, B0.13 the personal-data-free logger, B1.5 forbidden columns, B1.17 access logging and the teacher attendance view, B3.7 delivery of the escalation email, B5.11 which adult sees which child, B6.8 the union test, B6.11 the Extended Essay scope, B8.7 the unsourced-claim render rule, B8.11 mentor contact columns.
   B1.6's security section is reviewed by "a second Opus session", which is the same model.

**Why it matters here.** The brief asked for different-model review "where an error would be silent". Several of the listed tasks are where CAROS's promises to schools become code.

**Fix.** Regenerate §4.1 to §4.3 from the task tables (or the reverse) so there is one source. Add a Fable review to every task listed in point 2, or state why not. Make B2.9 Fable-written, since it produces the numbers the engine is tuned by.

Decision (2026-09-24): Accept.

#### F39 · The calendar assumes parallelism the ownership columns do not provide, and it is not mapped to a school year

**Severity:** serious · **Where:** 06 §0.4 (06:57), §1 task tables, B3 (06:176), §2.3 (06:454 to 06:468), §2.5 (06:494 to 06:496), §4.4 (06:741 to 06:743), §6.5 (06:896 to 06:898), §11 C2 (06:1084, 06:1093) · **Confidence:** high on the counts; medium on the calendar

**What is wrong.**
1. **One person is the critical path.** Stream D (Davide) owns 84 of the 156 tasks (and shares one more), including all 15 in B0, 17 of 18 in B3, 14 of 17 in B4 and 17 of 20 in B7, plus most Fable tasks, most reviews of other streams' migrations, every non-code gate (DPA, DPO, counsel, pen test, insurance, ACS meetings, elicitation) and the first on-call rota. B3 is "six to seven weeks with three people", but only B3.14 is not Davide's. Before Demo 1 Davide carries roughly 60 to 65 sessions plus reviews and rework (the attempt counter expects failures).
2. **The plan disagrees with itself on Demo 1.** §6.5 says week 14 with three people; §2.3 puts B3 in weeks 10 to 16.
3. **No school calendar.** G-REAL falls after week 21. From an October 2026 start that is March 2027. Under accepted decision C2 (G-REAL in a term's first fortnight), the options are an April 2027 start, with shadow ending as the school year does and G-LIVE after the Grade 12 application season, or an August 2027 start, with G-LIVE around October or November 2027 in the middle of the application season. Neither is stated. C2's own wording ("earlier weeks go to the historical backfill") conflicts with G-REAL, because the backfill is real data and needs G-REAL first; §1.11 correctly puts it after.
4. **Cost is the wrong constraint.** §4.4 prices about 280 sessions at API list prices. If the build runs on Claude subscriptions, the binding limit is usage caps, which Fable 5.1 max-effort sessions reach fastest. (This review itself was interrupted twice by a session limit.)

**Why it matters here.** A plan whose week counts cannot hold loses the trust that makes teammates follow it, and a pilot that misses its window waits a school year.

**Fix.** Rebalance ownership: move B3 screens to A or C, B4 tooling to B, and name a second reviewer for each of D's paths. Replace week counts with D-session counts on the critical path. Map the phases onto ACS's 2026-27 and 2027-28 calendars and choose the target term now, then back-schedule the external gates (pen-test booking, DPA, DPO, insurance, the school's IT review). Plan for subscription usage limits, not dollars.

Decision (2026-09-24): Accept with a change: target G-REAL in the first fortnight of the spring term 2027 (April 2027), Davide building alone. Replace week counts with D-session counts on the critical path; back-schedule every external gate (pen test booking, DPA, DPO, insurance, ADEK consent per F04, ACS IT review) from April 2027 now; plan against subscription usage limits, not dollars; drop the ownership rebalance until a teammate exists (C8). Pass 8 must state plainly what has to be cut or deferred for April to hold.

### A.3 Moderate

Real defects with bounded impact, or serious ones that tests would catch early.

#### F40 · The migration map does not match the task tables, and the named migrator cannot run the planned releases

**Severity:** moderate · **Where:** 06 §0.1 (06:13), §0.3 (06:34), §1.12 (06:391 to 06:408), B0 spine (06:78), B1.1 (06:115), B2.10 (06:156), B7.1 (06:300), §7.3 (06:924); 04 D61 (04:796); 01 DR-2 (01:110), DR-9 (01:406) · **Confidence:** high

**What is wrong.** §0.1 says "every D-number lands exactly once". It does not.
- **D61 is missing.** Pass 4's D61 (the authz, RLS, leak-scanner, refusal and template tests) is in no phase. §0.3 says pass 4 asked for "D33 to D60".
- **B1.1 lands D8, D11, D14 and D15.** The map lands D8 and D14 in B0, subsumes D15 into B0's matrix, and holds D11 for B5 because it alters `uni.*` tables that do not exist in B1. Following B1.1 literally fails.
- **B2.10 lands "D17 to D32" and D56.** The map lands D27, D28 and D30 in B0 and D56 in B1.
- **B7.1 lands D71,** which the map seeds in B0; D75 is in the map but not in B7.1.
- **B0's spine** creates `doc.file` "with D13 kinds"; the map lands D13 in B1.
- **Placement gaps:** `core.meeting` is created in B0 with foreign keys to B1 and B2 tables; `uni.destination` lands in B9 but B8 reads it; the creation of `ai.generation`, `ai.model_config` and `ai.pseudonym_map` is not placed; pass 1's `signal.week_run()` disagrees with pass 3's run definition, and backfill writes several evaluations per run against a per-run unique key.
- **Duplicate keys seeded together:** `PREVIEW_ACCESS` is in both D9 and D48; `sweep.completed` is in pass 1's 52 events and in D28.
- **The migrator.** Releases add indexes "created `CONCURRENTLY` outside the transaction" (01:406, 06:924), applied by `drizzle-orm/migrator` (01:110), Drizzle 0.45 pinned. That migrator (0.45 and the 1.0 release candidates, read in the package source) runs every statement of every pending migration inside one transaction, and PostgreSQL refuses `CREATE INDEX CONCURRENTLY` inside a transaction block. The expand-and-contract release fails at deploy.

**Why it matters here.** The map is what stops two streams generating conflicting migrations. A builder who follows the task row rather than the map breaks B1, and the first large-table index breaks a production release.

**Fix.** Make §1.12 the single source: generate each task's migration list from it, add D61 to B0 (tests) and D75 to B7, record the deviations in passes 2 to 5 (§12 item 18 already asks), and dedupe the seed keys. Give the migration job a second, non-transactional step for statements marked `-- no-transaction`, or drop `CONCURRENTLY` at pilot scale and say so.

Decision (2026-09-24): Accept.

#### F41 · Pass 6 does not carry out accepted decision C5 in B4, and retests on staging cannot verify production-layer fixes

**Severity:** moderate · **Where:** 06 B4 scope (06:206), B4.14 (06:225) against G12 (06:992) and C5 (06:1086, 06:1099); staging has no WAF (06:920) · **Confidence:** high

**What is wrong.** B4's scope says the test runs "against staging with synthetic data" and B4.14 says "staging target". Only G12 and §11 follow C5. Retests "against staging" cannot verify a fix to the WAF rules, TLS, the production network or key configuration, because staging has none of them. Yearly tests after G-REAL have no rules of engagement for a production that holds real data.

**Why it matters here.** C5 was accepted to test the thing that will be attacked; a builder reading B4 would book the wrong target.

**Fix.** Rewrite B4 and B4.14 to C5. Retest application-layer findings on staging and production-layer findings on production while it still holds only the canary tenants. For yearly tests: canary tenants only, no real-row exfiltration, redacted evidence, the firm named in the DPA.

Decision (2026-09-24): Accept.

#### F42 · Pass 6 does not fully carry out accepted decision C6

**Severity:** moderate · **Where:** 06 B4 acceptance (06:230), §5.4 (06:780), §5.8 nightly (06:810), §7.2 (06:920), O34 (06:1177); 04 T1 (04:660); 01 DR-9 (01:401) · **Confidence:** high

**What is wrong.**
1. B4's acceptance still admits "the two synthetic tenants (allowed there only as signed demo tenants, pass 1 DR-9, or against a dedicated canary pair)", and pass 4 T1 says "marked demo tenants". DR-9 allows synthetic tenants in production only with `branding_mode 'real_institution'` and the marker on: the opposite of C6's unbranded pair.
2. "Excluded from every report and every count" has no mechanism. No column marks a canary, so exclusion will key on something that can hide a real tenant or catch another synthetic one.
3. The canary runs in the nightly CI job, from GitHub-hosted runners, with a production credential (F23), and "signs in as a counselor" by an unspecified mechanism. An automated Google sign-in is fragile; a special login path would be a production backdoor.
4. The canary checks one canary tenant against the other only, so it cannot see a real-to-real leak.
5. O34 recommends a synthetic training tenant under the ACS name in production, which reintroduces what C6 excluded.

**Why it matters here.** C6 was accepted as a safety control. As written it adds a credential outside the country and an exclusion rule that can drop a real school from alerts.

**Fix.** An immutable `purpose` column on `core.school` (`customer`, `canary`, `demo`) and every report, indicator, cost board and alert keyed on it, with a test. The canary as a Container Apps job in UAE North that calls domain functions through `withTenant()` as a canary membership, refuses any non-canary tenant, and asserts that every row it reads carries its own school id. Canary tenants have AI off and no deliverable email addresses. Remove branded tenants from production (close O34 as "train on staging").

Decision (2026-09-24): Accept.

#### F43 · Staging is now the sales demo, and it is also the drill ground, the retest target and the continuous-deploy target

**Severity:** moderate · **Where:** 06 §7.1 (06:913: deploy on every merge, "refresh the seed for both tenants"), §7.2 (06:920), B4.7 (06:218: the offboarding drill "offboards a synthetic tenant on staging"), B4.10 (06:221), B4.11 (06:222), §9.3 (06:1045), G2 (06:982); accepted C4 (06:1085) · **Confidence:** high

**What is wrong.** Under C4, prospective schools see staging. The same environment redeploys and reseeds on every merge, runs the five restore drills and an offboarding drill that makes a tenant's raw-import container unreadable, hosts pen-test retests (C5), and runs load tests. Training ACS counselors "on the synthetic ACS tenant" with their real Google accounts means mapping ACS's domain in staging, which brings real identities into an environment shown to other schools. G2's consent letter covers applying ACS's name to synthetic data; it does not mention showing it to other schools.

**Why it matters here.** A demo that breaks mid-meeting, or a real ACS name on a screen shown to a competitor school, costs more than the environment.

**Fix.** A demo slot: a pinned Container Apps revision label, or a separate small environment, with a deploy freeze during booked demos and a demo tenant that no drill touches. Drills in their own subscription. Staging maps only CAROS test domains. G2 names third-party sales demos explicitly.

Decision (2026-09-24): Accept with a change: start cheap. A pinned demo revision on staging with a deploy freeze during booked demos and a demo tenant no drill touches; drills in their own subscription; split out a separate demo environment only if demos become frequent. Extend G2's consent letter to third-party sales demos.

#### F44 · The AI database role is a denylist, and nightly AI runs as the system tier

**Severity:** moderate · **Where:** 04 R6 and R7 (04:526 to 04:527), D55 (04:790); 05 §3.0 (05:171), §8.4 (05:702) · **Confidence:** high

**What is wrong.** `caros_t_ai` gets "grants as `caros_t_staff` minus" a list written in pass 4. Tables added later (pass 5's `signal.safety_alert`, reflections marked `urgent_request`, mentor tables beyond `message.body`) inherit access unless someone remembers to deny them. "`signal.case_note.body` denied unless the school's policy row says otherwise" cannot be a column grant, which is per role, not per school. Meeting notes, `reference_note`, context notes, contact-log summaries, tier-change reasons and attendance reasons are not denied. Nightly headline rephrase and brief pre-warming run as `actor_kind = 'system'`, which sees every row. The pseudonym map has no subject column, so a counselor's render cannot read it under RLS. Pass 5 calls this role "the second lock".

**Why it matters here.** The database lock is what makes an allowlist mistake fail loudly instead of leaking.

**Fix.** Generate `caros_t_ai` grants from the union of `ai.feature_policy.allowed_fields` (an allowlist), with a CI test that it can select nothing else. Per-school note inclusion through a view, not a grant. Nightly AI runs as the case owner under `caros_t_ai`. Re-identification through a definer function that checks the requester and the school.

Decision (2026-09-24): Accept.

#### F45 · On-call escalation depends on an SMS acknowledgement Azure does not offer

**Severity:** moderate · **Where:** 06 §7.5 (06:958) · **Confidence:** high (Azure Monitor action-groups page, updated July 2026)

**What is wrong.** "The second person is the escalation contact after 15 minutes without acknowledgement (Azure Monitor SMS supports a reply to acknowledge)." Action-group SMS replies are DISABLE, ENABLE, STOP, START and HELP. There is no acknowledgement and no escalation policy.

**Why it matters here.** The sweep window, 05:30 to 07:30, is the one on-call promise the plan makes, and the second person is a part-time teammate.

**Fix.** A small escalation mechanism (a Logic App or a job that pages the second person if the alert is still firing after 15 minutes), or an on-call service named as a sub-processor with identifiers-only payloads.

Decision (2026-09-24): Accept.

#### F46 · The branch rules as written stop Davide from merging his own work

**Severity:** moderate (blocking in B0 week one if applied literally; minutes to fix) · **Where:** 06 §2.4 (06:478 to 06:480, 06:488), §2.5 (06:494 to 06:496) · **Confidence:** high

**What is wrong.** The ruleset requires code-owner review and has an empty bypass list, "including the organisation owner". CODEOWNERS gives one owner per stream path, and "D owns `infra/**` and `packages/db/**`". GitHub does not let an author approve their own pull request, so every one of Davide's pull requests on his own paths waits for a code owner who does not exist. In §2.5's "Davide alone" case nothing can merge at all. "Every pull request is reviewed by a person other than its author" also puts part-time teammates on the critical path of every D-stream merge.

**Why it matters here.** B0.3 applies the ruleset in week one; everything after it is D's.

**Fix.** Two code owners on every path, a review service level (for example 24 hours), and a documented solo mode (required checks stay; human review becomes asynchronous within a week) for periods with one active person.

Decision (2026-09-24): Accept.

#### F47 · Pass 6 says it resolved the widening rule one way and tests the other

**Severity:** moderate · **Where:** 06 §12 item 6 (06:1116), B0.7 done-when (06:90), O54 (06:1202); 04 §3.1 (04:272), §3.3 (04:294), §3.8 (04:369), D36 (04:771) · **Confidence:** high

**What is wrong.** §12 item 6 says pass 6 plans on pass 4 §3.3: a school may widen `signal` and `case_note`, never `safeguarding`. B0.7's acceptance criterion is "the narrowing trigger refuses a wider school row and any `safeguarding` override", which is §3.1 and D36's reading. O54 then offers the school override as an option. Scopes also have no order, so "wider" is undefined for the trigger.

**Why it matters here.** If ACS's counselors answer question 65 with "yes, share cases", B0's trigger blocks the configuration pass 4 designed for it.

**Fix.** Decide the rule once, write the scope order the trigger uses, and make D36, B0.7 and §5.4 say the same.

Decision (2026-09-24): Accept with a change: default is narrow-only until ACS answers question 65; keep pass 4 §3.3 ready as the option (a school may widen signal and case_note to school scope, never safeguarding); rule, D36 trigger, B0.7 and §5.4 tests all match.

#### F48 · Past alerts are not fully explainable after a configuration change

**Severity:** moderate · **Where:** 01 `config.vocabulary` (01:1640 to 01:1662); 03 §4.5 (03:382 to 03:393), §6.1 (03:472), D23 and D27 (03:1113, 03:1117); 05 D68 (05:1037), §6.3 (05:545); 04 §7.1 (04:593) · **Confidence:** medium-high

**What is wrong.** Invariant 4 requires a past alert to stay explainable after the rules change. The vocabulary attributes that drive tiering and suppression (`flag_tag.safeguarding_relevant` and `severity`, `behaviour_category.urgent`, `absence_reason.suppresses`) are edited in place with no version; only a context's effect is snapshotted. Safety alerts store no lexicon version, model, prompt version or evidence span; `cleared_by_model` has no table; AI generations are deleted after 90 days.

**Fix.** Version the vocabularies, or snapshot the attribute values into `rule_hits` and the evidence with a test. Add lexicon version, model, prompt version and evidence span to `signal.safety_alert`, retained with the alert.

Decision (2026-09-24): Accept.

#### F49 · The backend `CLAUDE.md` paraphrases the invariants and drops clauses

**Severity:** moderate · **Where:** 06 §3.3 (06:601, 06:604) · **Confidence:** high

**What is wrong.** Every session reads this file. It says "No number, date, tier or level a user sees comes from a model", dropping invariant 3's "Nothing that gates a decision or a submission is model output", the clause F03 and F53 break. Its tier line drops "reordered" and "re-themed per school".

**Fix.** Quote CONTEXT §4 verbatim, with the backend's mechanisms beneath each invariant.

Decision (2026-09-24): Accept.

#### F50 · The prototype's ranking within a tier is on its way into the port

**Severity:** moderate · **Where:** `index.html:3366` to `:3373` (sheet sort: tier first, "then the loudest run"), `:6328` (CAS cohort sorted by gap); 06 B3.9 (06:188), B3.10 (06:189), §6.3; 03 §11.2 (03:783) · **Confidence:** high on the prototype; medium that the port copies it

**What is wrong.** Pass 3 orders a tier by time raised, oldest first. B3.9, which ports the sheet, is not bound to that, and neither sort is on §6.3's not-ported list. The no-comparison test "greps the rendered DOM for rank words and sorted meters", which cannot detect an ordering, and it sits on B3.10, not B3.9.

**Why it matters here.** Invariant 2: never rank students against each other.

**Fix.** Add both sorts to §6.3. Replace the DOM grep with a test that changing other students' data never moves a row within its tier.

Decision (2026-09-24): Accept.

#### F51 · "Match" is used outside reach, match and safety

**Severity:** moderate · **Where:** 05 §3.5 (05:331), §5 (05:470), §9 (05:811), D74 (05:1043); 06 O72 (06:1225); `index.html:7052`, `:7192`, `:8100` · **Confidence:** high

**What is wrong.** Invariant 11 reserves the word. Pass 5 prints a "Strongest match" stamp and "Why this matched you" on student screens and names a configuration key after it. The parent portal says a student "asked to be matched with an alumnus", and §6.3 strips only "recorded" from that copy.

**Fix.** Rename the stamp and the key ("closest fit"), add both strings to §6.3, and lint UI copy for the word.

Decision (2026-09-24): Accept.

#### F52 · The headline rephrase is a sixth AI feature, gated three different ways

**Severity:** moderate · **Where:** 01 (01:1815); 03 (03:1082); 04 §6.4 (04:557); 05 (05:11, 05:246, 05:355, 05:828); 06 B7.11 (06:310) · **Confidence:** high

**What is wrong.** CONTEXT §3 lists five v1 AI features; no pass declares a sixth. Pass 4 turns it on with the module; passes 5 and 6 require a policy row that starts off. Pass 3 has the rule wording "always available beside it"; pass 5 moves it to "on hover". The model rewrites the first line of a welfare case.

**Fix.** Declare it at the top of pass 5 or drop it. If kept: off by default, the rule wording always shown beside it, and the set-equality validator on tier words as well as numbers.

Decision (2026-09-24): Accept, and drop the headline rephrase from v1; the deterministic rule headline stays; revisit after the pilot.

#### F53 · Three more places where model output decides without a written rule

**Severity:** moderate · **Where:** 05 §3.4 and §3.5 (05:317 to 05:337), D66 (05:1035); §3.1 (05:261 to 05:271), §4 (05:400, 05:419); §3.6 (05:345, 05:351) · **Confidence:** medium

**What is wrong.**
1. **Discovery.** Model-extracted tags replace the keyword extractor and feed the scorer, whose output (the top three, the "Strongest match" stamp, whether any candidate appears) is the set the student can submit. The model's `answer_kind` and the tag count end the chat; `goal_focus` picks the question path.
2. **Co-pilot.** The model's plan chooses the filter, and so which students are retrieved. The counselor sees the filter only when nothing matches; the coverage rule checks against the set the model chose; text questions search model summaries only.
3. **Extended Essay feedback.** `too_broad` and `doubtful` are shown to the supervisor where they accept or return the proposal.

**Why it matters here.** Invariant 3 forbids model output gating a submission, and a hidden filter decides who a counselor thinks about.

**Fix.** Keyword tags as a floor that the model may add to with quoted spans, never remove; the student sees and corrects the tags and may submit any archetype; `answer_kind` never ends a session. Render the compiled co-pilot filter above every answer and search raw text too. Keep model labels off the supervisor's decision screen.

Decision (2026-09-24): Accept.

#### F54 · Veracross can schedule the weekly pack itself, over password-only SFTP, and exposes sensitive endpoints

**Severity:** moderate · **Where:** 02 DR-14 and §6.3 to §6.4 (02:66, 02:735), §7.3 (02:824 to 02:846), §9 step 9 (02:1061), open decisions 1, 2 and 17; 06 B4.9 (06:220), B9.2 (06:362) · **Confidence:** high (Veracross community and API documentation)

**What is wrong.** Veracross's Data Export Package, a paid module, exports Axiom query results by email or SFTP on a schedule (up to twice a day, 14 runs a week) with status emails. That supports daily unattended files, which open decision 1 does not list. Its SFTP destination takes a URL, username and password; no key authentication is documented, while the plan gives each tenant its own key. Each query may run five minutes at most and each export overwrites the last. The Data API (readable in full on Stoplight, updated 2026-09-23) also exposes student alerts with family and medical text and a Health resource, which a read-only token could reach. The rate limit is per access token (300 requests per 3 minutes), not per application.

**Fix.** Add the Data Export Package as delivery option (a) in open decision 1 and question 70. Support password SFTP with IP allowlisting and rotation for that path. Make the Veracross `verify()` refuse the alerts and health scopes. Correct the rate-limit note.

Decision (2026-09-24): Accept.

#### F55 · Pass 4 cites a superseded Student Protection Policy, and the stale clause numbers are in the counselor's banner

**Severity:** moderate · **Where:** 04 Sources (04:811), §1.1 (04:73), §2.3 (04:216), §5.1 to §5.3 (04:442 to 04:485), §5.6 (04:499), §7.4 (04:642), C8 (04:1008); 06 §9.2 (06:1032) · **Confidence:** high

**What is wrong.** The hosted copy pass 4 read is v1.0 (January 2024). ADEK's own copy is v1.1 (September 2024) and renumbers the clauses: 2.1 becomes 3.1, 2.2 becomes 3.2, 2.4.2 becomes 3.4.2, 2.5 becomes 3.5, 2.6 becomes 3.6, 3.1 to 3.3 become 4.1 to 4.3, 5.1 becomes 6.1. The 24-hour banner cites "ADEK Student Protection 2.6", which in v1.1 is a clause on students' equal rights. The banner also calls 80085 the "ADEK Child Protection Unit"; ADEK's own figure lists 80085 as the Ministry of Education's Child Protection Unit hotline (pass 4 §5.1 has this right; §5.3 and pass 6 §9.2 do not). Pass 4 also quotes the definition of "safeguarding" as if it were "maltreatment" (04:563), which C4's basis for fairness labels rests on.

**Fix.** Re-cite v1.1 throughout, remove clause numbers from UI text (cite the policy by name, with numbers in the school's configuration), and label 80085 correctly. The same fix answers §12 item 13.

Decision (2026-09-24): Accept.

#### F56 · The Child Digital Safety Law restricts more than free text sent to a model

**Severity:** moderate · **Where:** 04 §1.1 (04:80), §1.5 (04:147, 04:155); 06 B5.13 (06:255) · **Confidence:** medium (law-firm and press summaries; no Cabinet classification found)

**What is wrong.** Pass 4 gates only "free-text-to-model" features for under-13s. Published summaries of Federal Decree-Law No. 26 of 2025 say platforms may not collect, process, publish or share the personal data of children under 13 except with explicit, documented parental consent that can be withdrawn and a privacy-policy disclosure; the education exemption needs a Cabinet decision, which has not been found. If CAROS is in scope, importing an under-13 record is itself restricted. Cabinet Resolution No. 106 of 2026 (effective 30 June 2026) on under-15 social-media accounts is not mentioned; it probably does not apply.

**Why it matters here.** Rare at Grades 9 to 12, but the moment CAROS reaches a middle school it applies to every record.

**Fix.** A counsel question on scope; a per-student consent flag checked at import for under-13s; the under-13 gate extended from AI features to the record itself until counsel answers.

Decision (2026-09-24): Accept.

#### F57 · Parent access does not enforce activation in the database, cannot express custody restrictions, and hinges on one approver

**Severity:** moderate · **Where:** 01 `auth.is_guardian_of` (01:919 to 01:923), `family.guardian_link` (01:2946 to 01:2966); 02 §4.7 (02:583), §5.4 to §5.5 (02:672, 02:676, 02:683), onboarding (02:1065, 02:1068); 04 §2.2 (04:205, 04:209 to 04:211), D42 (04:777), T8 (04:667) · **Confidence:** high

**What is wrong.**
1. `is_guardian_of` ignores `activation_status`, so the SIS-typo case pass 4 itself describes (a new address that must re-activate) is protected only if the magic-link code remembers to check.
2. Whether a link added after activation gets `verified_at` is undefined: either instant access or none.
3. Two guardians sharing one email become one person, so a court order against one parent cannot be applied without cutting off the other. No restriction flag is imported (`lives_with` is unused).
4. One `school_admin` can upload and approve both a staff file and a roster; the caseload CSV has no security section; pass 2 and pass 4 disagree on auto-approval when the security section is non-empty; the fixture check trusts a label the admin sets.

**Why it matters here.** CONTEXT §11.12 requires the magic link to be bound to a verified relationship. A typo or a custody change becomes the wrong adult reading a child's file.

**Fix.** Require activation per contact inside `is_guardian_of`. Keep one person or link per SIS contact rather than merging. Import restriction flags. List guardian-link gains individually in the preview. Uploader and approver must differ for rosters, staff, contacts and caseloads, and access-changing imports never auto-approve. Fixtures only from a signed manifest.

Decision (2026-09-24): Accept.

#### F58 · The teacher sign-off card would port an engine signal, and the subject-teacher scope is too wide

**Severity:** moderate · **Where:** 04 §3.4 (04:300), §3.6 (04:317 to 04:322); 01 (01:746, 01:2072 to 01:2073, 01:2291); `index.html:5396` to `:5412`, `:5473`; 06 §6.2 (06:853) · **Confidence:** high on the prototype; medium on the port

**What is wrong.** The prototype's sign-off card prints the student's "Personal band" (`index.html:5473`), an engine output, and the teacher view is ported unchanged. `academic` has no subject column, so an ST scope built as "this student picked my subject" exposes every grade the student has. Subject-teacher write lets a teacher sign as another teacher or change a pick's level. Teachers read `case_id` and status on their own flags, and the routed phrase ("the counselor has taken this up") tells them a case exists.

**Why it matters here.** Teachers never see a tier or that a case exists (CONTEXT §3, pass 4 §3.4).

**Fix.** A narrow sign-off view (name, prerequisite mark, the student's reason), no band. Sign-off only on HL picks in the open round, signed as the current person. A flag view that shows only the routed vocabulary, with a wording that does not reveal a case.

Decision (2026-09-24): Accept.

#### F59 · Pass 4's mentor reader rules cannot be built on pass 1's tables

**Severity:** moderate · **Where:** 01 `mentor.*` (01:3045 to 01:3145), protections (01:3862 to 01:3867); 04 §2.3 (04:221 to 04:222), §3.6 (04:336) · **Confidence:** high

**What is wrong.** `mentor.message` is protected by sender only, so neither the recipient nor the counselor can read it. Adding a subject column exposes threads to parents (who read `mentor` for linked children) and to the student's other mentors. Parents already read mentee notes and session-request messages. Pairings and `share_scope` are writable by the student and mentor tiers.

**Why it matters here.** The counselor and coordinator reading every thread is the plan's main safeguarding control on mentors (invariant 11).

**Fix.** Derive the subject through the pairing. Grant per table: parents see only that a pairing exists and the mentor's headline; mentors see only their own pairing's rows. Pairings and `share_scope` change only through coordinator and student functions.

Decision (2026-09-24): Accept.

#### F60 · "Identifiers only" is not true of several emails and alerts, and their processing is global

**Severity:** moderate · **Where:** 04 §5.4 (04:491), §5.5 (04:495), T11 (04:670), §9.5 (04:707); 03 §13.4 (03:900); 06 §7.4 (06:928) · **Confidence:** high

**What is wrong.** `meeting_confirmation` carries the child's first name and a meeting with the counselor; the deadline nudge names the institution and date. These land in Google Workspace, Gmail or Outlook mailboxes outside the UAE. Azure Communication Services Email may process content in other geographies, and delivery status arrives through Event Grid events that carry the recipient address in a global topic. `sweep.partial` goes to "the ops channel with the student ids", while §7.4 says alert payloads hold no personal data; the ops channel provider is never named.

**Fix.** Make confirmation and nudge templates content-free ("you have a new message in CAROS"). Poll send status instead of using Event Grid, or list Event Grid as a sub-processor. Send counts, not ids, to the ops channel and name its provider. Correct T11 and 04:707.

Decision (2026-09-24): Accept with a change: emails may name the sender's role from a fixed allowlist (counselor, teacher, mentor, the school); safeguarding roles (CPO, safeguarding lead) always appear as "the school"; never names, the student or the topic. In-app notices after sign-in may show full names and roles. Ops channel gets counts not ids; name the providers.

#### F61 · Access from abroad by CAROS people, Microsoft support and yearly pen tests are unaddressed

**Severity:** moderate · **Where:** 04 §1.1 DPO (04:63), §3.7 (04:347 to 04:359), §9.9 (04:729), T20 (04:679); 01 DR-1 (01:72: "no support plan"); 02 §9 (02:1062); 06 G12 (06:992), §1.11 (06:383 to 06:384) · **Confidence:** medium (whether viewing from abroad is a transfer is for counsel)

**What is wrong.** Operators on the support console, onboarding screen-shares, reveal sessions that walk through real students, Demo 2 on the real tenant, an external DPO who "need not be resident", and container shell access can all show tenant data outside the UAE. The ticket system behind a grant's "ticket reference" is unnamed. Customer Lockbox, which gives the customer approval over Microsoft engineers' access, needs a paid support plan that pass 1 excludes. Yearly pen tests after G-REAL (G12) touch a production that holds real data.

**Fix.** Support access only from managed devices through a UAE egress (Bastion or a virtual desktop in UAE North), with the operator's location recorded on each grant. Real data shown only in person or on the school's own conferencing tenant. Keep student data out of tickets. Buy the support plan and enable Customer Lockbox. Rules of engagement for yearly tests (F41).

Decision (2026-09-24): Accept with a change: proportionate for the pilot. Real data viewed only on managed devices, shown only in person or on the school's own video platform, never in tickets; each support grant records the operator's location; buy the Microsoft support plan and enable Customer Lockbox. Defer the UAE Bastion or virtual desktop until support access is frequent; add a counsel question on whether viewing from abroad is a transfer.

#### F62 · The Extended Essay guide dates are a year off for ACS's current cohorts

**Severity:** moderate · **Where:** 05 §0.2 (05:29), Challenge 9 (05:1145), question 133 (05:1214), D70 (05:1039); 06 B6 (06:262), G19 (06:999), R13 (06:1071) · **Confidence:** high (the IBO's "Extended essay guide, first assessment 2027" was read for this review: a two-year programme, one reflective statement of at most 500 words on the RPF, criteria totalling 30)

**What is wrong.** Pass 5's account of the new guide is right; its cohort is wrong. It says "ACS's current Grade 11 sits under" the guide for first assessment May 2027. Students in Grade 11 in 2026-27 sit their exams in May 2028; this year's Grade 12 sits May 2027. Both current cohorts are therefore under the new guide, and the `ee_2018` milestone model (three RPPF sessions, which PRODUCT.md and the prototype encode) applies to no current ACS cohort except possible resits. Question 133 asks about "the May 2026 and May 2027 sessions"; May 2026 has passed.

**Fix.** Default ACS's rounds to the 2027 guide, keep `ee_2018` for resits only, and re-ask question 133 about the May 2027 and May 2028 cohorts.

Decision (2026-09-24): Accept.

#### F63 · The family notice understates what the AI provider may keep

**Severity:** moderate · **Where:** 05 §8.5 (05:711, 05:718), C18 (05:1233) · **Confidence:** high

**What is wrong.** Pass 5's own table says flagged inputs and outputs may be kept up to two years and classification scores up to seven. The notice text says only that "a pseudonymised fragment may be kept for up to two years", and C18 repeats the narrower wording. Given F20, "pseudonymised fragment" also overstates the protection.

**Fix.** State both retention periods and what "flagged" means, in the notice and in C18.

Decision (2026-09-24): Accept.

#### F64 · No results-day, Confirmation or Clearing logic, and university clocks count school days over the summer

**Severity:** moderate · **Where:** 03 §4.6 (03:401 to 03:417), §8.1 (03:588 to 03:598) · **Confidence:** high

**What is wrong.** IB and A-level results arrive in July and August. No rule compares final grades with offer conditions, and the check-in SLA "computed with `sis.add_school_days`" on a holiday event lands in September, after Confirmation and Clearing.

**Fix.** An `offer_condition_check` rule on the import of final results, and calendar-day SLAs (or a results-period calendar kind) for university rules.

Decision (2026-09-24): Accept.

#### F65 · Several structures are ACS-shaped where the plan promises data

**Severity:** moderate · **Where:** 01 `sis.stage_key` (01:1080 to 01:1084), `privacy.retention_class` (01:3626 to 01:3646, no `school_id`), DR-8 `COURSE_CATALOG` to `ref.institution` and `ref.course` (01:369), `engagement.activity_event.source` CHECK (01:1410), `programme_family` (01:1071), `ref.destination_system` (01:1424), `source_system.kind` (01:3177), §2.10 and DR-7 S3; 02 §5.2; 06 B5 (06:237), B6.6 (06:276), §6.2 (06:856, 06:861) · **Confidence:** high

**What is wrong.**
- Four fixed stages map Grade 9 to Year 10: a British Year 10 family gets the near-empty portal and US GPA guidance, Years 10 and 11 never see grades although GCSE results go into UCAS applications, and Year 11 gets an IB-or-AP tab.
- One global retention schedule, reasoned from ADEK; a KHDA school cannot differ.
- `COURSE_CATALOG` is ACS's own subject list for the Grade 9 guide; mapped to global `ref.*`, it appears in every school's university data. Archetype roadmaps give IB and AP advice to every school and are snapshotted into approved roadmaps.
- The subject-choice engine is IB-only (six groups, three or four HL); choosing A levels has the same shape and cannot use it. Turning CAS off also removes the activities page for non-IB students.
- CHECK constraints name ACS's incumbents (`caros`, `google_classroom`, `managebac`, `maia`); `programme_family` lacks IGCSE, BTEC and IB CP and allows one programme per enrolment; `destination_system` has no UC application. DfE register codes are English law, not Dubai's.

**Fix.** Portal rules and guide content per school; `privacy.retention_override` keyed by `school_id`; the catalogue as per-school subjects; archetype steps conditioned on programme family; either generalise the selection module or state the limitation; vocabularies instead of CHECKs; an IGCSE scale; a KHDA reason family or a question.

Decision (2026-09-24): Accept with a change: do the data fixes now (per-school portal rules and retention, vocabularies instead of CHECKs, catalogue per school, archetype steps by programme); document the IB-only subject-choice engine as a known limitation and generalise it to A levels when a British school signs.

#### F66 · The Personal Statement Lab's "AI read" score survives the port

**Severity:** moderate · **Where:** `index.html:7631` to `:7649`, `:7877`, `:7905`, `:7925`, `:9643`; 06 §6.2 `psreviews` row (06:846), §6.3 · **Confidence:** high

**What is wrong.** A word-count and cliché heuristic is shown as "AI read: N/100" and as a cohort average, and is written into the `PS_SUBMITTED` audit entry. It is an undefined number (CONTEXT §11.4) and a cohort comparison, and no pass removes it.

**Fix.** Add it to §6.3's not-ported list, or replace it with a labelled checklist with no score.

Decision (2026-09-24): Accept.

#### F67 · A school role can switch the demonstration marker off

**Severity:** moderate · **Where:** 01 `core.school` (01:534 to 01:537), `school_write` policy (01:3748) · **Confidence:** high

**What is wrong.** The marker is generated from `data_classification = 'synthetic' AND branding_mode = 'real_institution'`. `branding_mode` is writable through the school's own configuration, which the caseload lead holds (`cf`). Setting it to `unbranded` removes the marker; nothing forces the ACS name and crest to go with it.

**Why it matters here.** CONTEXT §4.9 and PRODUCT.md make the marker a shipping requirement that "cannot be switched off for a cleaner screenshot".

**Fix.** Make `branding_mode` immutable or CAROS-only, and derive the letterhead from it so the name and the marker cannot be separated.

Decision (2026-09-24): Accept.

#### F68 · Smaller engine defects that change the numbers by multiples

**Severity:** moderate · **Where:** 03 §3.3 (03:200), §3.7 (03:273), §4.2 (03:333 to 03:336), §4.4 (03:372), §12.2 (03:807), §7.2 row 8 (03:524) · **Confidence:** medium-high

**What is wrong.**
1. **Ordinal bands are not personal.** With steady IB grades the MAD is zero in most weeks, so s sits on the 0.5 floor and the band is a fixed ±0.75 grade for everyone. 14.5% to 17.6% of graded weeks fall outside it (computed), which feeds rows 8 and 9.
2. **Row 8 corroborates on noise.** Under the plan's normal model about 20 of 87 students show some weak measure in a week, so a single severity-3 teacher concern is often promoted to `checkin` by noise.
3. **Measure definitions are open.** The register (master or class), the unit (sessions or days) and the window are unstated; late counts as present; two lateness measures can be the same series; the behaviour floor is fortnightly on a weekly series.
4. **The fairness screen has almost no power.** Two groups of 175 at 20% against 16% (a ratio of exactly 0.8) give about 16% power, while a group of 30 crosses the 0.8 to 1.25 thresholds about half the time by chance; across tiers, rules and groups a chance trigger is near-certain every quarter.

**Fix.** Keep one-step ordinal moves inside the band unless held across two assessments. For row 8, require the other domain at moderate or a weak held two weeks. State register, unit and window per measure in the thresholds schema. For fairness, pre-register a few comparisons, pool across quarters, report intervals, and add a multiple-comparisons rule to the G-LIVE criterion.

Decision (2026-09-24): Accept.

#### F69 · Four cited facts do not match their sources

**Severity:** moderate · **Where:** 05 §2.1 point 1 (05:84); 03 §2.1 (03:110, 03:116, 03:124) · **Confidence:** high (each source read in full for this review)

**What is wrong.**
1. **Naviance (pass 5).** A sentence in quotation marks, attributed to PowerSchool's "Naviance Student: college research tools" page, is not on that page. A different PowerSchool page ("College Planning in Naviance") has a similar sentence about the Comparison feature and "have it available", not Scattergrams and "historical data". The quotation was altered and attributed to the wrong source.
2. **AEI, "Please Excuse My Child" (pass 3).** "Unexcused absence rising from 1.6% in August to 4.1% in May" does not appear in the report. Its only seasonal statistic is a different measure: the share of all absences that are unexcused, rising from 35% (August 2023) to 55% (May 2024).
3. **Faria et al. 2017, the EWIMS trial (pass 3).** "Reduced chronic absence (effect size about +0.23)". The report's primary model gives −0.26 for chronic absence (10% against 14%) and −0.17 for course failure; no 0.23 is attached to either.
4. **Balfanz, Herzog and Mac Iver 2007 (pass 3).** The individual flag yields are exact, but "together the flags identified 60%" follows a list of five flags including suspension. Every place the paper states 60%, the four flags are attendance, behaviour, mathematics and English.

The arguments these support survive the corrections. The numbers do not.

**Why it matters here.** CONTEXT §12.2: "Never invent a citation. This product's rules forbid fabricated benchmarks, and a fabricated paper in the plan is the same failure." Pass 8 will copy these figures forward as fact.

**Fix.** Replace each with what the source says, or remove the number. In pass 8, re-check every quoted sentence and every attributed number in passes 3 and 5 against its cited page, and mark any claim that cannot be re-found as an assumption.

Decision (2026-09-24): Accept.

### A.4 Minor

#### F70 · The AI cost model leaves out thinking tokens

**Severity:** minor · **Where:** 05 §11 (05:905 to 05:970), appendix script (05:1242 onward); 06 B7.17 (06:316) · **Confidence:** medium (thinking volume is unmeasured)

**What is wrong.** The script reproduces §11.3 exactly ($33.94, $49.67 and $56.71 variable per school-month). Its output sizes (60 to 700 tokens a call) exclude thinking, which cannot be disabled on Opus 5.5 and runs adaptively on Sonnet 5, and which is billed as output. An illustrative allowance (600 to 1,500 thinking tokens on Opus calls, 150 to 250 on Sonnet) roughly doubles the variable line, to about $72 at pilot. The daily ceiling's headroom falls from about seven times expected spend to about three. The §11.2 price table's heading says the 1.1x multiplier is applied, but the cells are list prices (the script applies it). The conclusion that the model bill is small next to infrastructure survives.

**Fix.** Add a thinking allowance per feature to the script, measured in B7.5's smoke test, and relabel the price table.

Decision (2026-09-24): Accept.

#### F71 · Pass 1's cost table undercounts HA storage and omits several lines

**Severity:** minor · **Where:** 01 DR-1 cost table (01:42 to 01:61) · **Confidence:** high (Azure Retail Prices API and pricing pages)

**What is wrong.** Every unit price and total checks out ($989, $1,628 and $4,152 production; $1,195, $1,834 and $4,450 with staging). But zone-redundant HA bills storage twice, not once (pilot +$17.66, year 1 +$35.33, year 3 +$141.32). Missing lines: Blob SFTP, recommended from pilot week five, at $0.30 an hour per SFTP-enabled account (about $216 a month); Defender for Storage malware scanning (about $10 a month per account plus $0.15 per GB scanned), which B1.18 requires; Key Vault Premium HSM keys and the second vault in UAE Central (B4); Entra ID P2 licences for PIM; a NAT gateway for the connector egress IP (B9); a support plan for Customer Lockbox (F61).

**Fix.** Add the lines; the pilot total rises by roughly $300 a month.

Decision (2026-09-24): Accept.

#### F72 · Bookkeeping errors inside pass 6

**Severity:** minor · **Where:** 06 §13 (06:1149, 06:1176, 06:1178), §0.2 (06:27), §4.1 (06:721) · **Confidence:** high

**What is wrong.** O11, O33 and O35 are still listed as open in Tiers A and B although §11 records them closed on 2026-09-24; they are missing from the "closed" paragraph. §0.2 says the prototype writes 33 distinct audit keys; counting calls with a computed actor gives 37. The prototype seeds `CONCERN_SUBMIT` (no key in `audit.action`, so the port fails its foreign key) and an `AI_DRAFT` "Letter draft generated" entry that contradicts deferred letter generation. The CAS "Ask to join" action (`index.html:9311`) has no table, audit action or phase.

**Fix.** Move O11, O33 and O35 to the closed list; correct the count; map or drop the two seed keys; place "Ask to join" in B6 or record that it is not ported.

Decision (2026-09-24): Accept.

#### F73 · Pass 1's account of the AWS region loss needs small corrections

**Severity:** minor · **Where:** 01 DR-1 (01:35), §5.1 (01:3931), Sources (01:4026, 01:4043) · **Confidence:** high (AWS Health Dashboard feed)

**What is wrong.** The disruption began on 1 March 2026 (the feed's first item and TechPolicy both say so), not 2 March. For the UAE region, only data held exclusively in `mec1-az2` is declared unrecoverable; "customers whose backups were in-country only have lost them" is true of Bahrain, where AWS declared data held anywhere in the region unrecoverable, and that is the stronger precedent for pass 4's cold-copy argument. AWS says "relevant" billing operations are suspended; the plan drops the qualifier. The cited Register URL returns 404; the article lives at the same path with `/5296830` appended.

**Fix.** Correct the date, the scope of the loss, the qualifier and the link; cite Bahrain as the country-level precedent.

Decision (2026-09-24): Accept.

#### F74 · Small corrections to pass 2's vendor facts

**Severity:** minor · **Where:** 02 §7.3 to §7.8 (02:826 to 02:935), §5.1 (02:621) · **Confidence:** high

**What is wrong.** Veracross API Plus has Rostering and Gradebook services, no Resources service, and produces the API format, not OneRoster CSV. Veracross's 1EdTech listing is expired (one OneRoster 1.1 entry from 2022). ManageBac's `deleted_since` covers students, parents and teachers, not behaviour notes; `modified_since` is missing on attendance, grades, term grades and Projects; gradebook grades page at 10. ManageBac tokens carry configurable scopes. A Classroom "verified teacher" sees only their own courses, so the reader account must be a domain administrator or a course teacher. The Edlink article cited for `OAuth_App_Admin` does not mention it (Veracross's own pages do). Cross-references: §7.8 is cited where §7.9 is meant, and 02:113 cites §7.7 for OneRoster (§7.8).

**Fix.** Correct §7.3 to §7.8 and the references.

Decision (2026-09-24): Accept.

#### F75 · Smaller authorization and identity defects

**Severity:** minor · **Where:** 01 audit and event writers (01:3489 to 01:3508, 01:3584 to 01:3601), definer grants (01:1058), views (01:3955); 02 D12 (02:1095); 03 D25 (03:1115); 04 §2.1 (04:185) against 02 §4.2 (02:545), D59 (04:794), T1 (04:660) · **Confidence:** medium-high

**What is wrong.**
- `audit.record()` and `events.emit()` accept any action and subject from any tier: a student session can write an `ESCALATED_SAFEGUARDING` row about another student. The scope helpers (`in_caseload`, `is_guardian_of`) stay executable by `PUBLIC` and work as yes/no lookups.
- Teachers and counselors share one database tier, so no column rule separates them; D59's teacher attendance view returns no rows because attendance is protected without a section column, and fixing that exposes reason text on the base table. D12 and D25 views are not `security_invoker`.
- Pass 4 binds a staff Google account by unique email match; pass 2 binds only with a date-of-birth match or an SIS source. A recycled address can bind a new hire to a departed counselor's person.
- Framework-level caching in Next.js keys on arguments, not on the tenant context; T1's "lint rule on the cache helper" does not cover it.

**Fix.** Per-tier action allowlists inside the definer writers; revoke `PUBLIC` execute on all definers; a separate teacher tier with invoker projection views; bind by email only when no Google subject is stored; no framework caching on authenticated routes.

Decision (2026-09-24): Accept.

#### F76 · Smaller residency paths

**Severity:** minor · **Where:** 04 §2.3 (04:221 to 04:223), §7.5 (04:650), §9.9 (04:729); 05 §3.0 (05:175), §8 (05:718); 06 §9.1 (06:1015) · **Confidence:** medium

**What is wrong.** Alumni mentors may live abroad and read minors' data and threads. Chrome's enhanced spell check and grammar extensions send typed text to their providers from the escalation form, notes and the Personal Statement Lab. A runtime font load from Google sends every student's IP address to Google. `api.anthropic.com` terminates TLS at Cloudflare's edge, while `inference_geo` pins only inference. Whether `metadata.user_id` is sent is unstated; a stable id would make flagged fragments linkable. The exit pack's delivery method is unspecified. Counselor exports and screenshots are the school's responsibility but are not listed as such in the DPA.

**Fix.** Mention mentors abroad in the consent text and share first names by default; `spellcheck="false"` on sensitive fields and a Chrome policy line in the IT checklist; self-host fonts with `font-src 'self'`; word the notice as "inference in the United States"; send no user id or a random one per generation; deliver the exit pack in the portal; a DPA annex of school-side responsibilities.

Decision (2026-09-24): Accept.

#### F77 · Smaller invariant and consistency items

**Severity:** minor · **Where:** 01 (01:3855); 04 (04:12, 04:205, 04:323, 04:462, 04:491); 05 (05:101, 05:104, 05:602, 05:1039); 06 B8.12 (06:345), §1.11 (06:379 to 06:380) · **Confidence:** medium-high

**What is wrong.**
- XP lives in the `discovery` class, which parents read for their children; invariant 10 is enforced only on the writer.
- Institution-wide admit rates print per target on student and parent screens, against pass 5's own reasoning for removing the probability.
- "The two ADEK guidance indicators" are four in the CU Guidance Policy (coverage, counselor-student ratio, graduate destination, top-three destination), undefined in B8.12, and must be counted over one population.
- Pass 4's §0.1 says the activation code is emailed; §2.2 says the school hands it over off-email.
- The safeguarding route is validated only when it changes, so a departed recipient can remain.
- The outbox deduplicates at enqueue, not at send, so a retry after an unclear provider response can send an escalation email twice.
- `mentions_others` can put a second student into a single-student envelope.
- EE word limits and marks are seeded from secondary sources and shown to students.

**Fix.** A separate XP class; drop per-target admit rates from student and parent screens or label them as institution-wide; define the ADEK indicators; align §0.1 with §2.2; nightly route validation; an idempotency key per send; the coordinator confirms EE numbers.

Decision (2026-09-24): Accept.

#### F78 · Smaller engine and documentation errors

**Severity:** minor · **Where:** 03 (03:29, 03:321, 03:427 against 03:544, 03:540, 03:720, 03:888, 03:988, 03:1052, 03:1057, 03:1075); 06 §4.4 (06:743), §14 · **Confidence:** medium-high

**What is wrong.** Hana's attendance is strong in §4.7 and moderate in §7.2. Ahmed's floor is 3.6 in one place; the formula gives 3.0. "14 weeks of history" in Mathematics by 12 November is impossible with per-year windows. "Pilot scale (87 students)" should be about 350, since thresholds are per school. Example dates fall on Tuesdays, not the week start. S2 excludes an open case's dip weeks; §3.2 excludes only closed cases. Rows 9 and 11 do not say whether "L = 1" means exactly 1 or at least 1. §2.3's "about 4% of weeks" contradicts its own table (6.2% recomputed). The consolidated ACS questions (§14) are grouped by who answers but not tagged with the gate each blocks, which a school will need to prioritise about 60 questions.

**Fix.** Correct the numbers, define the row conditions, and tag each ACS question with the gate it blocks.

Decision (2026-09-24): Accept.

### A.5 The eighteen inconsistencies in pass 6 §12, checked

Each item was checked against the files. None is wrong. Two are slightly misstated (items 8 and 17) and several are incomplete; the corrections and additions are given. Accepting an item here means pass 8 applies pass 6's resolution plus the correction.

**§12.1 · Sweep job names and the watchdog hour.** Confirmed. Pass 1 DR-2 has `sweep.tick` every fifteen minutes and `sweep.watchdog` at 06:00 (01:111); pass 3 has `sweep.schedule` (03:879) and the watchdog at 05:45 (03:886).

Decision (2026-09-24): Accept.

**§12.2 · `caros_owner` cannot log in.** Confirmed: "Migrations run as `caros_owner`" (01:175) against `CREATE ROLE caros_owner NOLOGIN` (01:486). The `caros_migrator` fix is sound, but it sits inside the larger role problem in F01.

Decision (2026-09-24): Accept.

**§12.3 · Loose ends in pass 1's DDL.** Confirmed: `core.touch_updated_at()` is defined (01:608) and attached to nothing; `audit.entry` and `events.event` carry `school_id` with no foreign key (01:3441, 01:3562); the comment says "four settings" (01:882) where DR-4 sets six, plus `app.actor_label`, plus `SET LOCAL ROLE`.

Decision (2026-09-24): Accept.

**§12.4 · Pass 2's onboarding contradicts pass 4.** Confirmed: step 18 uses `sso_jit` (02:1070), which D38 removes; step 4 has "the school's super admin registers the CAROS OAuth client" (02:1056). Addition: step 4 also omits Google's rule that users designated under 18 are blocked from unconfigured third-party apps, which pass 4 §2.1 covers.

Decision (2026-09-24): Accept.

**§12.5 · Pass 2's internal counts.** Confirmed for the items checked: "six Axiom saved queries" (02:735, 02:1107) against a seven-file table (02:738 to 02:746); DR-14 names two retrospective domains (02:66) against three at 02:718; §7.8 cited where §7.9 is meant (02:70, 02:249, 02:328); `const` listed as a transform (02:50) and as a binding (02:376). The option lettering and `field_key` examples were not checked. Addition: 02:113 cites §7.7 for OneRoster, which is §7.8.

Decision (2026-09-24): Accept.

**§12.6 · Pass 4's widening rule stated three ways.** Confirmed (04:272, 04:294, 04:369, and D36 at 04:771). Correction: pass 6 says it planned on §3.3's reading, but its own B0.7 acceptance implements §3.1's. See F47.

Decision (2026-09-24): Accept.

**§12.7 · Column names differ between body and D-table in pass 4.** Confirmed: `training_opt_out_confirmed` (04:529) against `training_opt_out_confirmed_at` (04:788); `notice_version` (04:567) against `notice_version_id` (04:795).

Decision (2026-09-24): Accept.

**§12.8 · Feature keys differ between passes 1, 4 and 5.** Confirmed in substance: pass 1's CHECK (01:3271) lacks `quarantined_reader`; pass 5 D74 adds it. Correction: pass 4 does not use a feature key `discovery`; `discovery` is a data class in pass 4, and §6.4 has one combined row, "Discovery chat and pathway analysis". Pass 1's CHECK also carries `letter_draft`, which no later pass keeps.

Decision (2026-09-24): Accept.

**§12.9 · `covered_model` and `zdr_eligible` moved.** Confirmed: pass 4 puts them on `ai.model_config` (04:522, 04:788); pass 5 D62 puts them on `ai.model`.

Decision (2026-09-24): Accept.

**§12.10 · Canary tenants in production against DR-9.** Confirmed (01:401). Addition: DR-9 admits synthetic tenants in production only as branded demo tenants with the marker on, the opposite of accepted decision C6, and pass 4 T1 (04:660) and pass 6's B4 acceptance (06:230) still carry DR-9's wording. See F42.

Decision (2026-09-24): Accept.

**§12.11 · The narrative seed layer and `strength`.** Confirmed: DR-8 stores the prototype's signal as `evaluation.strength` with `strength_definition = 'prototype:unspecified'` (01:362); pass 3 D17 drops both columns.

Decision (2026-09-24): Accept.

**§12.12 · The Extended Essay's 2027 guide.** Confirmed: pass 1 models three `rppf` milestones (01:322, 01:2424); pass 5 D70 adds `reflection_model`. Addition: pass 5's cohort dates are a year off, which changes the default (F62).

Decision (2026-09-24): Accept.

**§12.13 · ADEK Student Protection Policy section numbers.** Confirmed, and now resolved: pass 4 read v1.0 (January 2024); ADEK's official v1.1 (September 2024) is current and renumbers the clauses. Pass 4's clause numbers, including the one in the counselor banner, are stale. See F55.

Decision (2026-09-24): Accept.

**§12.14 · Google verification is unstated in pass 4.** Confirmed. Addition: pass 4's Google design also relies on RISC events that Google does not send for Workspace accounts (F18) and on `prompt=login`, which Google does not document (F19).

Decision (2026-09-24): Accept.

**§12.15 · Blob SFTP in UAE North.** Confirmed as pass 2 open decision 17. Additions: Blob SFTP costs $0.30 an hour per SFTP-enabled account (F71), and Veracross's scheduled export offers password SFTP only (F54).

Decision (2026-09-24): Accept.

**§12.16 · Audit action keys are one list.** Confirmed: pass 1 seeds 84 audit keys and 52 event names; D9, D48 and D71 add more; all are seeded in B0. Addition: `PREVIEW_ACCESS` appears in both D9 and D48, and `sweep.completed` in both pass 1's events and D28, so a combined seed fails on the primary key.

Decision (2026-09-24): Accept.

**§12.17 · Reveal weeks.** Confirmed as a counting convention, not a contradiction: pass 3 counts weeks 4 and 8 of shadow (03:958), and pass 6's overlay already maps them to overlay weeks 6 and 10. The pilot agreement should state which count it uses.

Decision (2026-09-24): Accept.

**§12.18 · D15 subsumed; D11, D56, D58 and D60 land with their tables.** Confirmed but incomplete: the task tables contradict the map in B1.1, B2.10 and B7.1, and D61 is missing. See F40.

Decision (2026-09-24): Accept.

### A.6 Citation register

Every citation the review could reach, by pass, marked **verified**, **wrong**, **partly wrong** or **unverifiable**. What a source says is paraphrased; where it differs from the plan, the difference is stated. Wrong and partly wrong items that matter are findings above, and the finding is named. Checks ran on 2026-09-23 and 2026-09-24. A "not reached" list closes each pass; those citations are neither confirmed nor challenged.

#### Pass 1

| Source | Verdict | What the source says, where it differs | Finding |
|---|---|---|---|
| AWS Health Dashboard feed (me-central-1, me-south-1) | partly wrong | The disruption began 1 March 2026, not 2 March. For the UAE, only data held exclusively in `mec1-az2` is declared unrecoverable; Bahrain's loss is region-wide. Billing suspension is qualified as "relevant" operations. Cause (drone strikes), no restoration date, and the quoted wording are verified. | F73 |
| AWS UAE region launch post | verified | 29 August 2022, three availability zones. | |
| TechPolicy.Press, 12 March 2026 | verified | Microsoft denied hits or outages; dates the strikes to 1 March. | |
| The Register, 8 April 2026 | verified | No Microsoft facility known to be damaged. | |
| The Register, 16 September 2026 | partly wrong | Cited URL returns 404; the article is at the same path with `/5296830`. Content matches the AWS feed. | F73 |
| Microsoft Q&A, 2 April 2026 | verified (weak evidence, as the plan says) | Anonymous accepted answer resting on the asker's own status screenshot. | |
| Azure Retail Prices API, UAE North | verified | PostgreSQL compute, storage and backup, Container Apps, WAF v2, Blob tiers, Key Vault, Log Analytics, Container Registry, Email and egress prices match. Totals recompute exactly. | |
| Azure PostgreSQL pricing (HA) | partly wrong | Zone-redundant HA bills storage twice as well as compute. | F71 |
| Azure PostgreSQL overview, region table | verified | Zone-redundant HA and geo-redundant backup available in UAE North; paired with UAE Central. | |
| PostgreSQL backup and restore | verified (quotation loose) | Geo-redundant backup can be set only at server creation; the plan's quoted sentence is a paraphrase in quotation marks. | |
| PostgreSQL customer-managed keys | verified | Mode selectable only at server creation. | |
| PostgreSQL supported versions | verified | 17 available (14 to 18). | |
| Azure regions list and access request | verified | UAE Central is access-restricted. | |
| Communication Services privacy and data location | verified | UAE is a data location; content may transit or be processed elsewhere. | F60 |
| Communication Services service limits | verified | Custom-domain limits of 30 a minute and 100 an hour. | |
| Container Apps jobs, zone redundancy, billing | verified | Jobs and zone redundancy in UAE North; idle rates would cut the web tier's cost more than "roughly half". | |
| Application Gateway pricing | verified | WAF v2 meters exist in UAE North. | |
| Drizzle `drizzle-kit check` | verified | | |
| `drizzle-orm/migrator` behaviour (uncited claim) | wrong | Runs every pending migration in one transaction; `CONCURRENTLY` fails. | F40 |
| Defender for Storage (cited from pass 4) | verified | Malware scanning runs in the storage account's region; UAE North supported, UAE Central not. | |
| Blob SFTP regions | unverifiable (as the plan says) | Microsoft publishes no region table. | |
| Azure status history | unverifiable | Page renders only with JavaScript. | |

Not reached: vaulted-backup pricing meter; storage redundancy and immutable-storage pages; Front Door FAQ and TLS pages; the region pages of Google Cloud Run, Vercel, Neon, Supabase, PlanetScale, Railway, Render, Fly.io, Upstash, Cloudflare, Oracle and Alibaba; the Bedrock and Foundry Claude region pages (Anthropic's own residency page, checked under pass 5, covers the conclusion); the email providers' residency pages; AWS endpoint tables, Fargate and Price List files; version announcements for Next.js 16, Node 24, Prisma, tRPC 11, oRPC, pg-boss 12, Graphile Worker, Zod 4 and Vitest 5; PgBouncer's feature page.

#### Pass 2

| Source | Verdict | What the source says, where it differs | Finding |
|---|---|---|---|
| ManageBac API index and Projects pages | wrong | CAS experiences, hours, supervisor and approval are exposed; PBL projects (including an EE template for first assessment 2027) are exposed. No TOK endpoint; no CAS reflection text. | F27 |
| ManageBac extended APIs page | verified | Has no CAS or EE, as the plan says; the Projects pages do. | F27 |
| Veracross Data Export Package (not cited) | missed | Scheduled SFTP or email export of Axiom queries, up to twice a day; password SFTP only. | F54 |
| Veracross rate limiting (via Edlink) | partly wrong | The official page (readable on Stoplight) sets 300 requests per 3 minutes per access token, not per application; header names differ. | F54 |
| Veracross Data API documentation | partly wrong | The plan treats it as unreadable; it is public on Stoplight, with 456 operations, including student alerts (family and medical text) and Health. | F54 |
| Veracross API Plus | partly wrong | Rostering and Gradebook only, no Resources; API format, not OneRoster CSV. | F74 |
| Veracross 1EdTech listing | partly wrong | Expired: one OneRoster 1.1 entry from 2022. | F74 |
| ManageBac deltas, paging, token scope | partly wrong | `deleted_since` on students, parents, teachers (not behaviour notes); `modified_since` missing on several resources; scopes configurable per token. | F74 |
| Google Classroom submissions list | partly wrong | Only course teachers and domain administrators see all submissions; a verified teacher sees only their own courses. | F74 |
| Faria guide, IB predicted grades | partly wrong | "Around April 30" is the Group 6 upload deadline; nothing rests on it. | F74 |
| Edlink "Connecting Veracross" | partly wrong | Does not mention `OAuth_App_Admin`; Veracross's own pages do. | F74 |
| ManageBac authentication, regions, security, rate limits, pagination, memberships, year-group advisors, attendance, behaviour, gradebook, academics, archiving, OneRoster dialect | verified | ManageBac is hosted in Canada, the US and China by school choice. | |
| Faria "Connected by Design"; Kognity guide | verified | | |
| Veracross access tokens, OAuth role and workflow, endpoint pages, attendance split, API Plus as a premium add-on | verified | | |
| Edlink data inventory; Edlink privacy (US) | verified | Data stored and processed in the United States. | |
| Wonde security FAQ | verified | Storage in Ireland, within the EEA. | |
| MaiaLearning developer API | verified (absence) | No public API found. | |
| iSAMS developer portal | verified | Behind a login; the plan's hedge stands. | |
| Google Classroom StudentSubmission, list filters, scopes | verified | | |

Not reached: Maia's own export pages; the iSAMS batch API details; Google's usage limits, push notifications and service-account pages; the OneRoster 1.1 and 1.2 bindings (so "OneRoster carries no attendance" is unchecked); the DfE attendance guidance; the IB and College Board pages; the grade-scale facts in §5.1; Veracross's Axiom guide and attendance articles.

#### Pass 3

| Source | Verdict | What the source says, where it differs | Finding |
|---|---|---|---|
| AEI, *Please Excuse My Child* | wrong | The 1.6% to 4.1% figure is not in the report; its seasonal statistic is the unexcused share of absences, 35% to 55%. | F69 |
| Faria et al. 2017 (REL 2017-272) | partly wrong | 73 schools, randomised, no effect on GPA or suspension: correct. Chronic absence effect is −0.26 (primary model), not +0.23; course failure −0.17. | F69 |
| Balfanz, Herzog and Mac Iver 2007 | partly wrong | Individual yields (12% to 24%) exact; the 60% is for four flags (attendance, behaviour, mathematics, English), not the five listed. | F69 |
| Eklund et al. 2009 | wrong (journal) | Published in *The California School Psychologist*, vol. 14; renamed *Contemporary School Psychology* later. Finding accurate. | |
| SigmaXL, Tabular CUSUM | partly wrong | The page does not state 465; the figure itself is correct (recomputed: 465.4 at h = 5, 167.7 at h = 4, two-sided). | |
| Allensworth and Easton 2005, 2007 | verified | 81% and 22% (1999 cohort); "eight times more predictive". | |
| Bowers, Sprott and Taff 2013 | verified | Abstract confirms the on-track indicator performed best. | |
| Knowles 2015; Anderson, Boodhwani and Baker 2019 | verified | | |
| Balfanz and Byrnes 2012 | verified | 10%, 18 days of 180. | |
| McIntosh, Frank and Spaulding 2010 | verified | 20%, 50%, 80% by November, February, April. | |
| Markowitz et al. 2023; Dowdy et al. 2013; Quesenberry 1991; Kesselheim et al. 2011; Pauker and Kassirer 1980 | verified, citation incomplete | Volume, issue or pages missing from the Sources list. | |
| Macfadyen and Dawson 2010; Splett et al. 2019 | verified | | |
| Hampel 1974; Leys et al. 2013; Iglewicz and Hoaglin 1993; Rousseeuw and Croux 1993 | verified | The 2.5 cut, the 0.6745 formula and 3.5 cut, and the 37%, 58% and 82% efficiencies are as stated. | |
| Page 1954; Brook and Evans 1972; Hawkins 1987; Roberts 1959; Lucas and Saccucci 1990; Borror, Montgomery and Runger 1999; Lucas 1985; Borror, Champ and Rigdon 1998; Nelson 1984; Sen 1968; Killick, Fearnhead and Eckley 2012; Truong, Oudre and Vayatis 2020; NIST/SEMATECH handbook | verified | Bibliographic details exact. | |
| Known-parameter CUSUM run lengths (uncited in §3.6) | verified | One-sided about 930 (h = 5) and 335 (h = 4), consistent with the two-sided 465 and 168. | |
| van der Sijs et al. 2006; Ancker et al. 2017; Drew et al. 2014; Bliss, Gilson and Deaton 1995; Parasuraman and Riley 1997 | verified | The 49% to 96% override range and Ancker's 30% and 10% figures are exact. | |
| WHO adolescent mental health; Burcusa and Iacono 2007; ASCA ratios | verified | One in seven; 250:1 recommended, 372:1 for 2024-25. | |
| Hardt, Price and Srebro 2016; Chouldechova 2017; 29 CFR 1607.4(D); EU AI Act Article 10(5) | verified | | |
| PDPL sensitive categories | verified in part | Ethnic origin and health confirmed; "nationality" as a listed category not confirmed. | |
| AEI, *What Stories Does Daily Attendance Tell?*; Hawkins and Olwell 1998; Adams and MacKay 2007; Western Electric 1956; UAE weekend articles | unverifiable in this review | Not retrieved; plausible standard references. | |

Pass 3 is explicit and consistent about which findings are cohort-level and do not transfer to within-student deviation; no cohort finding is used to justify the personal mechanism.

#### Pass 4

| Source | Verdict | What the source says, where it differs | Finding |
|---|---|---|---|
| ADEK School Digital Policy v1.1 | partly wrong (omission) | Cited clauses (4.1.5, 5.5.1 a to h, 5.5.2, 6.6, 6.6.1, 6.6.2, 7.1) are accurate. Clause 7.1.3.a (ADEK's explicit consent before a contractor shares personal data, inside or outside the country) and 6.4 (live virtual interactions with invited visitors) are missed, and the hosting conclusion rests on the omission. | F04 |
| ADEK Student Protection Policy (hosted copy) | partly wrong | The copy is v1.0 (January 2024); ADEK's v1.1 (September 2024) renumbers every clause cited. Wording verified. The 24-hour duty in 3.1 sits on each staff member. The quoted definition is "safeguarding", not "maltreatment". | F09, F55 |
| ADEK Student Mental Health Policy (not cited) | missed | 3.5.1(b): suicidal ideation or severe substance abuse reported to school leadership immediately; 3.6: parental consent for structured counselling. | F09, F37 |
| ADEK School Records Policy v1.1 | partly wrong | 1.3.1, 1.4.1, 1.4.2.b and 2.1.3 verified. 1.5.1 sits under school transfers; 2.1.2.b concerns clinic records; the five-year clause names enrolment, academic, attendance and disciplinary records only. | F37 |
| ADEK Reporting and Compliance Policies | verified | Neither has a hosting clause. | |
| ADEK CU Guidance Policy v1.2 | partly wrong | Four indicators, not two; effective 1 September 2022, compliance from 2024/25. | F76 |
| PDPL (unofficial translation, cross-checked) | partly wrong | Articles 1, 2, 4, 6, 7(5), 9, 10, 18, 20, 26 verified. Article 21 is the impact assessment, not the record of processing. Article 23's contract route is narrower than stated. Article 13 is a right to information with refusal grounds. Retention is Article 5(7). | F14, F37 |
| u.ae PDPL page | verified | In force 2 January 2022; page updated 4 December 2025. | |
| Chambers 2026 | verified as quoted, now stale | The Data Office was merged into a new Federal Authority for AI and Data on 14 June 2026 (Morgan Lewis, June 2026); regulations still unissued (GLA, August 2026). | F37 |
| DLA Piper | verified as its statements | The one-month SAR period is DLA Piper's, not the law's. | F14 |
| Securiti | mostly verified | Labels Article 21 as the impact assessment, contradicting the plan. | F37 |
| Wadeema's Law (KHDA text) | partly wrong | Articles 1, 42 and 60 verified. Article 44 is quoted short: its identity limb concerns analyses, media reports and publication. | F14 |
| Clyde & Co; Baker McKenzie (Child Digital Safety) | verified | Quotes and dates match; the under-13 restriction is broader than the plan's gate. | F56 |
| The National; Khaleej Times (age of majority) | verified | Age 18 from 1 June 2026; neither gives the decree number. | |
| Latham (ICT Health Law) | verified | Article 13 localisation; Article 20's 25-year retention is not mentioned by the plan. | F37 |
| Kayrouz (cybercrime) | partly wrong | Gives fines, not article numbers. The insider offence is Article 6; the plan cites 2 to 4. | |
| Penal Code 431 and 432 | partly wrong | 432 is professional secrets; 431 is privacy intrusion. | |
| 34 CFR 99.1, 99.3, 99.31 | partly wrong (99.3 truncated) | The sole-possession exclusion allows a temporary substitute; the conclusion survives. | |
| SDPC national DPA | partly wrong (stale) | More than 222,000 agreements, not 130,000; the version date is not on the page. | |
| FPF pledge retirement; CISA pledge date; ICO children's code; EP legislative train | verified | CISA's commitment list is not on the cited page. | |
| Gulf News (records) | verified | | |
| Google RISC (cited in §2.1) | wrong in application | Cross-Account Protection sends no events for Workspace users. | F18 |
| Google OpenID Connect (step-up) | wrong in application | `prompt` accepts `none`, `consent`, `select_account`; `auth_time` only on request. | F19 |
| Azure Monitor action groups | verified | SMS and voice to +971 supported; UAE voice calls come from a US number; processing Global (regional only in named non-UAE regions). | F45 |
| Anthropic retention and Covered Models (§1.6) | verified | See pass 5. | |
| Al Tamimi (health data) | unverifiable | Bot-protection challenge. | |
| UAE legislation portal | unverifiable | HTTP 403, as the plan says. | |

Not reached: NIST SP 800-63B-4; the five OWASP pages; the W3C WebAuthn Level 3 date; HIBP; STRIDE; Greshake et al.; Microsoft's SMS-in-UAE page for Communication Services, encryption scopes and immutable storage; KHDA's own texts (the KHDA site failed its TLS check).

#### Pass 5

| Source | Verdict | What the source says, where it differs | Finding |
|---|---|---|---|
| Anthropic API and data retention | verified | Batch API ineligible for ZDR and stored 29 days; Files, code execution, Managed Agents, MCP connector and Skills ineligible; prompt caching and structured outputs eligible; schemas cached up to 24 hours; flagged content kept up to 2 years even under ZDR; ZDR arranged per organisation through the account team. | |
| Anthropic commercial retention policy (1 July 2026) | verified | Classification scores kept up to 7 years; the family notice omits this. | F63 |
| Covered Models articles | verified | Exactly Fable 5.1, Fable 5, Mythos 5 and Mythos 5.1; Opus 5.5 and Sonnet 5 are not covered; 30-day retention. | |
| Introducing Claude Opus 5.5 | verified | Released 22 September 2026; available under ZDR; $4 and $20 per million tokens, cache reads $0.20. | |
| Data residency page | verified | `inference_geo` accepts `global` and `us`; 1.1x on every token category; 4.5-generation models return 400; workspace geo `us`; supported on the first-party API and Claude Platform on AWS only. | |
| Guidelines for organisations serving minors; child safety guidance | verified | Quote and dates match. | |
| OpenAI data residency (UAE) | verified | UAE endpoint with the listed models, approval, a Modified Retention amendment and a 10% uplift. | |
| Azure OpenAI model region availability | verified | UAE North regional provisioned deployments: GPT-5.1, GPT-4.1 and others as listed; no Middle East data zone. | |
| Core42 Compass model list | verified | Claude models listed as Global. | |
| IB Extended Essay guide, first assessment 2027 | verified | One reflective statement of at most 500 words on the RPF; criteria 6, 6, 6, 8, 4 (30). The cohort the plan names is wrong. | F62 |
| PowerSchool Naviance pages | wrong | The second quoted sentence is not on the cited page and is altered from a different page. | F69 |
| Scoir predictive chances FAQ | verified | Tens of millions of records; demographic factors. | |
| UCAS historical grades data; UCAS Courses Data Service terms | verified | | |
| College Scorecard admission rate | unverifiable (exact wording) | The glossary phrases it differently, not contradictorily. | |
| pgvector 0.8.2 on Azure PostgreSQL | verified | | |
| 116111 (MoI Child Protection Centre) | verified number; partly wrong use | A line to report abuse; hours unpublished; the cited page is a 2016 release. | F11 |
| 800444 (Family Care Authority) | verified number; partly wrong use | Reporting and services; published hours are office hours. | F11 |
| 800-SAKINA | verified | 24/7 since March 2026, Arabic and English, children and families; run by Sakina (SEHA) with the Department of Health. | |
| Estijaba 8001717 | partly wrong | 2021 source; daytime hours in 2022; no current source. | F11 |
| DFWAC 800111 | verified | Toll-free, 24/7. | |
| 800HOPE; MOHAP line; Aman 8002626 | verified (the plan's handling holds) | | |
| Safety Concern Portal | partly verified | The Family Care Authority's form for mandated reports; ADEK and the MoI centre are not named. | |
| MoE Child Protection Unit 80085 | verified | Cited only in Sources; not seeded. | F55 |

Not reached: Enterprise Frontier Safeguards; the prompt-injection guidance page; the Bedrock, Vertex and Foundry pages beyond the residency conclusion; the NYUAD rate claim; the UCAS tariff values; the archetype statistics.

#### Pass 6

| Source | Verdict | What the source says, where it differs | Finding |
|---|---|---|---|
| GitHub rulesets | verified | Available for private repositories on Team; the bypass list can be empty. | |
| GitHub protected branches | partly wrong | Classic branch protection is broader than the Team-only features; the plan's mechanism (rulesets) is correct. | |
| GitHub code owners and approvals | verified | Authors cannot approve their own pull requests; with a sole code owner the author's pull requests cannot merge. | F46 |
| GitHub-hosted runners | verified | Azure virtual machines, no region choice. | F23 |
| Claude Code memory, rules, hooks, worktrees | verified | `paths` frontmatter, the 200-line guidance, exit code 2, `--worktree`. | |
| pnpm `minimumReleaseAge` | verified | Added in 10.16.0; default 1,440 minutes since 11. | |
| Azure Monitor action groups | partly wrong in use | No SMS acknowledgement or escalation exists. | F45 |
| Claude API pricing | verified | Opus 5.5 $4 and $20; Sonnet 5 $2 and $10; Fable 5.1 $10 and $50. | |
| Prototype references at `fb28217` | verified | 10,048 lines; `PRIO`, `roleNav`, `bind()` and the router at the cited lines; 25 counselor route keys. The audit-key count is 37 with computed actors, not 33. | F72 |

Not reached: GitHub environments and Advanced Security; Azure OIDC from GitHub Actions; Container Apps revisions; PostgreSQL planned maintenance; OWASP ASVS 5.0.0; Google sensitive-scope verification; CREST's Dubai Cyber Force page; the Drata and Vanta SOC 2 pages.

## B. Keep

The parts a revision must not disturb, one line each on why.

1. **Azure UAE North with UAE Central in-country, OCI as the named fallback, and a provider-neutral module** (01 DR-1): the AWS UAE and Bahrain losses are verified in AWS's own feed, and the neutral module is what makes the choice reversible.
2. **Row-level security as the tenancy backstop: a restrictive tenant policy, `FORCE` on every table, composite foreign keys, a transaction context that fails closed** (01 DR-4): the right shape; F01 and F02 fix its roles and its matrix, not its idea.
3. **Permissions as data, with capabilities on memberships rather than new roles** (01, 04 §3.1): the only design that lets a second school differ without a migration.
4. **One path for every mutation: procedure, domain function with `assertAllowed`, `withTenant()`, audit and event in one transaction, no Server Actions for data** (01 DR-2, 06 §3.3): it is what makes the audit log complete by construction.
5. **The engine as a pure, deterministic, versioned function with a scenario suite, property tests, golden files and input hashes** (03 §13.1, 06 B2): the scenarios are wrong in places (F06); the discipline is right.
6. **Personal median and MAD with floors, no cohort priors, a minimum-meaningful-change floor as the main lever, a one-sided CUSUM with an onset estimate, and combination by level, breadth and persistence in a versioned table, never a weighted sum** (03 §3, §7): statistically sound choices and explainable to a counselor; F05 fixes the CUSUM's memory, not the choice.
7. **Removing strength, confidence, signed weights and the admission probability, and defining sigma** (03 §9, 05 §2): every surviving number has a meaning.
8. **The queue is never trimmed and never ordered by anything but tier and time; the budget is a tuning signal only** (03 §11.2): the only reading of invariant 2 that holds under load.
9. **Cold start without borrowing other students' history** (03 §5): it keeps invariant 2 at the hardest moment.
10. **Episode exclusion from the baseline, and suppression that is recorded whether it fired and never raises** (03 §3.2, §6): both are what make a signal defensible to a family.
11. **Cadence honesty: `expected_cadence`, "as of" dates on every screen, and the retrospective mode named and labelled** (02 DR-14, 03 §4.8): the decided degraded mode, made visible rather than silent.
12. **Pull-only ingest, mapping profiles as data, a closed transform set, a dry-run preview with a non-collapsible security section, rosters treated as permissions, idempotent re-import and rollback** (02 §2 to §5): this is what makes the second school cheap.
13. **Rejecting integration middleware on residency grounds** (02 DR-16): keep unless a vendor now offers UAE hosting.
14. **Shadow mode with a thirty-second counselor log, reveal sessions and the `engine_miss` against `data_gap` split** (03 §14): the only ground truth the pilot will have; F24 fixes its engine and its exit test.
15. **The escalation email as a reference only, rendered from an allowlist with a content test, with an acknowledgement screen and deputy routing, and CAROS never contacting an authority** (04 §5): exactly right for a welfare record.
16. **Google sign-in that validates `hd` from the token, keys on `sub` and creates nothing at sign-in** (04 §2.1): keep; replace only RISC and `prompt=login` (F18, F19).
17. **Parent magic links: hashed, 15 minutes, single use, bound to the requesting browser, after an out-of-band activation code, to the address in the SIS** (04 §2.2): it defeats forwarded links and mail scanners.
18. **Mentors arranged by the school, vetted, with passkeys, no contact columns, held messages and visible threads** (04 §2.3): the right controls for an outside adult near a minor.
19. **The support path's principle: no standing access, school-approved grants, masked by default, every read audited and visible to the school** (04 §3.7): F35 binds it in the database; the principle stands.
20. **The AI rules: no Covered Models on student data, ZDR only, US pinning, no Batch or Files API, deterministic modes for every feature, per-feature school acceptance, and an AI-off pilot until ZDR is in writing** (04 §6, 05 §8): coherent and honest, subject to F04's ADEK consent.
21. **The quarantined reader pattern and a closed co-pilot grammar compiled to parameterised SQL, with model output never executed and no embeddings in v1** (05 §4, §7): the strongest part of the injection defence; F21 scopes the reader.
22. **Anti-overwrite discipline: immutable migrations, the wholesale-replacement check, worktrees per session, generated documentation, `docs:verify`, and a phase-end rewrite of `CLAUDE.md`** (06 §2.4, §3.6): aimed squarely at the failure this repository has already suffered.
23. **Both synthetic tenants in every test from week one, with a Wellesmere checklist** (01 DR-8, 06 §5.4): the right mechanism; F31 makes the second school substantive.
24. **The demonstration marker as a generated column, and an immutable synthetic or real classification with separate demo and real tenants** (01 §2, 04 T16): keep; F67 closes the one switch.
25. **The thin slice split into B0 to B3 with checkable exits, and the sweep's alerting inside B2's definition of done** (06 §1.13): a phase with no "done" for three months is how this repository drifted before.
26. **Logs free of personal data by an allowlisted serializer and a log scanner; retention numbers as proposals for counsel; erasure replayed after every restore; a hash-chained audit log with anchors** (04 §4, §7, §9): each is a control a school reviewer can be shown running.
27. **"Targets, not measurements" on the reporting page, with events emitted from day one** (01 §2.20, 06 B8.12): the anti-fabrication rule applied to the product's own claims.
28. **The Extended Essay guide as versioned data per round** (05 D70, 06 B6.9): the right mechanism for a syllabus that changes under the product; F62 fixes the defaults.
29. **Pass 3's separation of cohort-level research from the personal mechanism** (03 §2): every study is run through "what transfers, what does not", and cohort findings enter only as policy floors or validation; this is what keeps invariant 2 defensible.
30. **Pass 6's list of what is not ported from the prototype** (06 §6.3): keep, and add F50's sorts and F66's score to it.

---

## C. Judgment calls

Disagreements where both positions are defensible. Each needs Davide's choice.

**C1 · How much model to put in the student safety screen.** *Position A:* ship the model layer as an add-only second reader (F03's fix): every lexicon hit reaches a person, and the model can only raise urgency or catch what the lexicon missed. This keeps humans in the loop and accepts more alerts for counselors to clear. *Position B:* ship v1 pattern-only, with no model layer at all, until the lexicon has run a term and the CPO has seen the false-positive rate; add the model later. This keeps student text in the country (the safety screen is the feature pass 5 names to move first) and removes the one AI feature that touches the most sensitive text, at the cost of missing disclosures the lexicon cannot phrase-match. Both reject the current design, where the model clears hits.

Decision (2026-09-24): Position B: pattern-only safety screen in v1; every lexicon hit reaches a person; no model reads student text. Revisit an add-only model layer after one term, once the CPO has seen the false-positive rate.

**C2 · Email to parents.** CONTEXT §3 says parents receive no email in v1 and also that parents sign in by magic link, which is an email. *Position A:* allow authentication email only (magic links and activation), with no child content; everything else, including meeting confirmations, is in-app. Closest to the decision; parents who do not open the portal miss confirmations. *Position B:* adopt pass 1's reading, transactional email including meeting confirmations with no welfare content. Better for families, and it moves the product toward the parent channel CONTEXT deferred.

Decision (2026-09-24): Position B: content-free transactional email to parents (magic links, activation, and role-only notices under the F60 rule: no names, child content or topics).

**C3 · Staff notification emails beyond the two decided** (F28). *Position A:* keep and declare the ones that serve safety (the counselor's safety-alert email, escalation reminders and deputy routing, grooming routes) and make everything else in-app. Safety needs reach when a counselor is not signed in. *Position B:* hold to two emails; every other notice is in-app, and the school's own processes cover reach. Simpler to audit and to explain to a school's IT review; slower when someone is away from CAROS.

Decision (2026-09-24): Position A: keep and declare the safety emails (counselor safety alert, escalation reminders and deputy routing to the CPO, grooming alerts to the mentor coordinator), all reference-only; everything else in-app.

**C4 · What a subject-access pack contains by default** (F14). *Position A:* include counselor notes and evaluations by default, redacted per item. Transparency, a PDPL-style access right, and notes written knowing they may be read. *Position B:* exclude professional records and anything linked to an escalation or safety alert by default until counsel answers C7 and C8. Keeps the staff-only decision and protects a referral from a parent who may be its subject.

Decision (2026-09-24): Position B: exclude professional records (notes, engine evaluations, AI outputs, anything linked to an escalation or safety alert) from the default subject-access pack until counsel answers C7 and C8; the school may include items one by one.

**C5 · Parental access when a student turns 18** (pass 4 §3.5, O21). *Position A:* continue by default and let the student object. Matches family expectations at an American school in the UAE where parents pay and are involved in applications. *Position B:* suspend at 18 until the student opts in. The UAE age of majority is 18 from 1 June 2026, US practice moves rights to the student at 18, and Grade 12 students turn 18 during the application season.

Decision (2026-09-24): Position A for now: parent access continues at 18 by default and the student can object; add a new ACS question asking the school's view before the pilot, and revisit if ACS or counsel prefers suspend-until-opt-in.

**C6 · Whether mentor video sessions on the school's platform count as "in-platform"** (04 §2.3; invariant 11). *Position A:* yes: the school's own tenant is supervised and recorded under school policy, and it is how schools run volunteer programmes. *Position B:* no: invariant 11 means inside CAROS, where message holds and screening apply; v1 offers CAROS messaging and in-person sessions on school premises only. ADEK Digital Policy 6.4 (F04) requires parental consent and ADEK approval for live virtual interactions with invited visitors either way.

Decision (2026-09-24): Position B: v1 mentor contact is CAROS messaging (holds and screening) and in-person sessions on school premises only; video on the school's platform deferred until ACS has ADEK 6.4 consent and approval in place.

**C7 · Which model writes the code that keeps student data safe** (06 C3). *Position A:* keep the reservation rule: Fable 5.1 for the subtle, silent-failure work, because no student data should ever be in a session. *Position B:* run build sessions under a commercial API organisation with ZDR and Opus 5.5 only, so that if real data ever does reach a session (F23), no Covered Model retains it. Costs the strongest model on the hardest work; buys a development path with no 30-day retention anywhere.

Decision (2026-09-24): Accept with a change: Opus 5.5 under the ZDR API organisation writes every task, including those pass 6 reserved for Fable; Fable 5.1 reviews diffs only (code and synthetic data, never tenant data), keeping the different-model review rule. B0 runs a bake-off on one reserved task (the F01 auth.allowed() rewrite): both models on the same brief, judged by acceptance tests and cross-review; any category where Fable is clearly better moves back to Fable.

**C8 · How heavy the process should be for one full-time builder and part-time teammates.** *Position A:* keep the four streams, two-person reviews, CODEOWNERS, different-model reviews and rule ledgers. The repository's history (lost phases, drifting documents) justifies every one. *Position B:* a lighter process until a second full-time engineer exists: required checks and tests stay, human review becomes asynchronous with a service level, different-model review only on the reserved list. Faster, and less likely to stall on a part-timer's week (F39, F46).

Decision (2026-09-24): Position B: Davide is the only builder for now. All automated checks stay (CI, tests, immutable migrations, anti-overwrite hooks); human review is asynchronous with a service level and never blocks a merge; different-model review on the reserved list; rule ledgers kept for ports. The full process (streams, two-person review, CODEOWNERS) switches on when a second regular builder joins.

**C9 · Engine defaults for the pilot** (F05, F24, F25). *Position A:* keep sensitive defaults and tune in shadow, as pass 3 plans; the reveal sessions exist to find the right settings with the counselors. *Position B:* detune before the pilot (day-level attendance, floors at the full typical noise, persistence of three weeks) and accept later detection, so that the first weeks of shadow are not dominated by noise the plan already predicts. Either way, the G-LIVE bars should become pooled intervals (F24).

Decision (2026-09-24): Position B: detune before the pilot (day-level attendance, floors at the full typical noise, three weeks of persistence); tune further in shadow; G-LIVE bars become pooled pre-registered intervals.

**C10 · ManageBac as the record for CAS and the Extended Essay** (F27). *Position A:* read-only mirror: ACS keeps ManageBac, CAROS reads CAS (and EE through the PBL template) and adds the counselor views ManageBac lacks. Nobody maintains data twice. *Position B:* CAROS becomes the record with a one-time import, as the prototype assumed. One system, richer workflow (the conversation gate, capacity stamps), and a migration the IB coordinator must want.

Decision (2026-09-24): Position A: ManageBac stays the record for CAS and EE; CAROS is a read-only mirror via the v2p3 API plus the counselor views ManageBac lacks; subject selection and its conversation gate remain CAROS-owned.

**C11 · The fairness audit at pilot scale** (F68). *Position A:* build the machinery now and run it with intervals, stating plainly that at 350 students it can detect only large effects. *Position B:* collect no special-category labels during the pilot and run the audit only when pooled data across schools gives it power. Less data held about minors, and no screen that triggers by chance every quarter.

Decision (2026-09-24): Position B: collect no special-category labels during the pilot; run the fairness audit only once pooled cross-school data gives it power; state this in the pilot documents.

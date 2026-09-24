# CAROS backend · Pass 3 · Signal engine

Written 2026-09-23 against `index.html` at 10,048 lines, `backend-plan/CONTEXT.md`, `PRODUCT.md`, `out/01-architecture-and-data-model.md` (pass 1) and `out/02-ingest-and-integrations.md` (pass 2). Every source cited was checked by web search or retrieval on 2026-09-23; where a figure could not be verified it is labelled an assumption. Numbers that came out of a simulation written for this pass are labelled *computed* and the assumptions behind them are stated where they appear.

**Revised 2026-09-24 (pass 8, session 2)** to apply Davide's decisions on the pass 7 review (`out/07-review.md`). §0.5 lists what changed; `out/08-changelog.md` records every change against the finding that caused it. Where the text below and the pass 7 review disagree, this revision is the one to build from.

## 0. Read this first

### 0.1 Departures from section 3 of CONTEXT.md

**None of substance; one in detail, declared below.** Every decision in section 3 is planned on: the overnight batch is the ritual, the statistics are specified in full, counselors configure what they consider urgent, the engine is designed for the weekly export pack with an honest termly mode, tiers and signals stay staff-only, and every number a counselor sees traces to a stored input. Two decisions are challenged in the Challenges section and planned on as given: "overnight batch" is extended (not replaced) with an event-triggered evaluation for the three inputs that arrive live, which pass 1 (§5.2) asked this pass to argue and CONTEXT.md §11.1 leaves open; and the engagement domain is planned as **off by default** until pass 4 rules on measuring a minor's platform activity, which is a sequencing choice inside the decision, not a departure from it.

**One departure in detail, added by the pass 8 revision (F05).** CONTEXT §3's cadence row names "per-session attendance" in the weekly pack. The engine no longer computes attendance from sessions: every attendance measure is counted in **days** from the school's **master (daily) register**, over non-overlapping fortnight blocks (§4.2), because a per-session rate treats each lesson as an independent chance to be absent and turned one ordinary sick day into a strong signal. Pass 2's weekly pack still carries the per-period register beside the master register; the engine reads it only to find a late arrival where the master register records none. This follows Davide's decision on F05 and changes what the pack is used for, not what it contains.

**The pilot defaults are detuned** (decision C9, 2026-09-24): day-level attendance, scale floors at the full typical noise, three weeks of persistence, the attendance domain held at weak until ACS's reason-code coverage is measured. §3.6 and §11.1 give the computed price: far less noise in every tier, and slower detection, stated in weeks. It is a tuning choice inside the decision "counselors configure what they consider urgent", not a departure.

One thing this pass does that a reader should know before anything else: **the prototype's signal strength, confidence percentage and signed evidence weights are removed** and replaced by an ordinal evidence level, a breadth count and a persistence window, each defined from stored inputs (§9). The sigma value survives with a precise definition. CONTEXT.md §11.4 and pass 1 (open decision 17) both required a definition or removal; the definitions offered here are the ones the case file can actually print without lying.

### 0.2 Where the code and the documents disagree

The code wins on behaviour; where the code carries a number that traces to nothing, the plan removes the number and says so.

| Topic | Document says | `index.html` does | Consequence for the engine |
|---|---|---|---|
| Evaluation timing (`arch` page, `index.html:2966`, `:2981`) | CONTEXT.md §3: overnight batch; §11.1: "never in a nightly batch" copy is wrong | "Every new grade, absence or concern is evaluated immediately, never in a nightly batch"; worked example: "gradebook webhook fired" | Nightly sweep plus an event-triggered evaluation for teacher flags, counselor context and enrolment changes (§7.5). No webhook exists (pass 2 §0.2). The frozen page stays wrong; the Next.js rebuild describes the sweep |
| Signal strength (`STUDENTS[].signal`, `:1320` onward; `caseCard`, `:2160`; `vCase`, `:2323`) | CONTEXT.md §11.4: undefined | Authored integers (86, 74, 91, 38 …); the case header prints the *word* Strong / Moderate / Weak from bands at 75 and 55 with a meter; `data-ctxpick` (`:9770`) adds a fixed integer and demotes at 45 and 40 | The integer is removed. The word the header already prints becomes the defined **evidence level** (§9). Context re-evaluates the case through the rules, never through arithmetic on a score |
| Confidence (`AUDIT`, `:1576`; `arch`, `:2971`) | undefined | "Cross-signal correlation · 3 domains · confidence 86%" | Removed. No calibrated probability exists before a backtest; a per-rule acceptance rate from the tuning log may be shown later, sourced (§9) |
| Sigma (`arch`, `:2971`; thresholds page, `:2252`) | undefined | "Baseline deviation rule triggered at 3.1σ"; slider text "Standard deviations below personal mean" | Kept with a definition: the deviation of the triggering week from the student's own **median**, in units of the student's own **robust scale** (MADn with a floor), never a mean and standard deviation (§3.3). The slider's wording changes |
| Evidence weights (`evidence[].w`, signed) | CONTEXT.md §7: "meaning is undefined" | Summed per domain in the cohort matrix (`vIntel`, `:2220`) to colour cells at 30 and 18; positive items carry negative weights | Removed. Each evidence item carries a level (1 to 3) and a polarity; the matrix colours by domain level (§9) |
| Severity (`severity:"High"`) | not in CONTEXT.md | A third header tile that restates the tier | Removed; the tile becomes **breadth** ("3 domains corroborate") (§9) |
| Persistence window (`window:"14 days"`) | undefined | authored strings | Defined as the days from the estimated onset (the CUSUM's last zero) to the as-of date (§3.4) |
| Dimension statuses (`dimPunctuality` `:3135`, `dimEngagement` `:3151`, `dimBehaviour` `:3159`) | CONTEXT.md §7: computed at render time | punctuality and engagement are hard-wired to student ids; behaviour is a constant | The `dimensions` rule set (§9) defines all five student-intelligence dimensions from the domain levels; the five application dimensions keep the prototype's logic as data (pass 1 DR-6) |
| Priya's series (`s14`, `:1502`) | not in CONTEXT.md | "Platform activity after 01:00 (nights per week)" | **Measure removed.** It infers sleep from timestamps of a minor's activity, has no validity evidence, and is the most intrusive number in the product. Her case is reproduced from her late arrivals, re-authored as counts of late days because no register produces the prototype's on-time percentages (F06), and the teacher comment (§4.2, §7.2, §15.1) |
| Layla's baseline (`s2`, `:1345`) | | "4.2 logins per week across the previous 14 months" | The baseline window is at most 20 school weeks (§3.2); a fourteen-month baseline would smooth over a Grade 11 to Grade 12 change in what the platform asks of her. The summary template prints the window it used |
| Ahmed's "first result outside his personal band in 22 months" (`s1`, `:1327`) | | | Academic series are per subject and level, carried across the two years of a two-year course (§3.10), and history is counted in assessments. A 22-month claim crosses courses. The template prints the history it used: "first result outside his band in Mathematics AA HL (20 assessments)" |
| Thresholds page estimate (`vThresholds`, `:2267`) | | "Estimated effect: … current false-positive rate 14%" | Replaced by a **what-if run** over the last twelve weeks of stored snapshots that prints how many cases per tier the proposed settings would have produced (§10.4) |
| The run (`weekRun`, `:1281`) | CONTEXT.md §7: kept / soft / break / none | `break` = two or more series outside band in the same week | Kept exactly, with one addition: a point counts as outside only if it also clears the measure's minimum meaningful change (§3.4), so a stable student's two-point wobble is not a cross on the sheet. The engine writes `outside` on every series point and `signal.week_run()` reads it, so the sheet and the engine cannot disagree (F40) |
| Teacher flag statuses (`data-fact`, `:9515`) | pass 1 enum `new, linked, reviewed, dismissed` | `attach` → `linked`; `ack` → `"ack"` | `ack` maps to `reviewed`. A `reviewed` concern still counts toward corroboration for its seven school days (§4.5) |
| Yousef's context (`s4`, `:1376`) | | "Assessment was a timed mock during a heavy deadline week" | Mocks (`assessment.kind = 'mock'`) never enter the coursework baseline; each is judged against the student's own attainment band in that section, so a mock dip is a level, not only a sentence (§4.1, F31); a declared `mock_period` suppresses the academic domain for the year groups it names (§6) |
| Tariq's referral threshold (`s12`, `:1461`) | invariant 5 | "Referral threshold under the school's policy is two independent staff within seven days" | The corroboration rule's parameters are school configuration with exactly those defaults (§4.5); the engine proposes `urgent`, the counselor refers |
| Cohort tiles on `si-why` (`vIntel`, `:2177`) | invariant 2 | Cohort-mean attendance, lateness, engagement and attainment sparklines | These are school-level descriptive aggregates, not a ranking of students; they may stay. The cohort **matrix** on the same page ranks nothing but its cell colours change (above) |
| `movedToday` / `openedToday` (`:3344`) | pass 1 DR-6 | derived from `prev` and the `opened` string | `tier_yesterday` is the tier at the end of the **last successful nightly run**, not the previous calendar day; when a night is missed the sheet says which run it is comparing against (§13.6) |

### 0.3 What passes 1 and 2 handed to this pass

Pass 1 §7 asked for: `feature_snapshot.band_method`, `history_weeks` and `features`; `evaluation.rule_hits`, `suppressions`, `strength` and `strength_definition`; `signal.contribution`; the rule keys named in `openedBy`; the three rule sets `engine.thresholds`, `engine.suppression`, `engine.tiering` and their JSON schemas; hysteresis and the rule that the engine never lowers a person-raised tier within N days; the hybrid trigger argument; the `dimensions` rule set; cold start through `history_weeks`; and the seed reproduction test. Pass 2 §13 asked for: the backfill evaluation for weekly and termly deliveries; the fortnightly persistence question; the retrospective tier cap; what happens to a signal whose fact was superseded; ordinal series analysed as ordinal; `sis.grade.missing` as a submission series; `counts_as = 'excluded'` days out of the denominator; first-period punctuality only where a period reference exists; `as_of` per domain printed; `absence_reason.attributes.suppresses` as the vocabulary side of suppression; cold start reading `joined_on` and `transferred_in`; reads through `sis.v_current_*`. Each is answered below; §17 lists the schema deltas.

### 0.4 The engine on one page

For every student, every night, for every measure the school's data can carry (§4), the engine:

1. Builds the student's own series in the scale the facts are in (§3.1): one point per graded assessment for attainment, one point per school week for weekly rates and counts, and one point per **fortnight block** of ten school days for attendance, counted in **days** from the master register (§4.2).
2. Takes the most recent twenty weeks of that student's own data as the **baseline window** (for attainment, the twenty most recent assessments, carried across the two years of a two-year course), and computes a robust location (median) and scale (MADn, floored at the full typical noise of the measure, and widened by `sqrt(1 + 1/H)` for the uncertainty of a short history) (§3.2, §3.3). Weeks inside a case's window are left out while the case is open and after it closes. Nothing about any other student enters this step (invariant 2). The band the sheet draws is median ± 2.5 scale (§3.4).
3. Runs the detectors (§3.4): the **band** (outside, by more than the minimum meaningful change); the **shock** (three scale units out); the **strong shock** (five units and twice the floor), which has its own rule; and a one-sided **CUSUM** whose weekly step is capped at three units, so one wild point cannot carry it, and whose **persistence** is the number of consecutive weeks of data with the CUSUM signal. The chart restarts when a case opens on the measure.
4. Turns the detectors into an ordinal **level** per measure (0 none, 1 weak, 2 moderate, 3 strong) and per domain (§3.5). The attendance domain is held at weak until the school's reason-code coverage has been measured (§4.2).
5. Applies **suppression** (§6): exam and mock periods, authorised absences, subject changes, counselor and teacher context. Suppressed weeks leave both the baseline and the detectors, and every check is recorded whether or not it fired. There is no school-wide automatic cap: a week in which much of the school moved is an operations count that asks the school to declare the period (§7.6, F26).
6. Adds the inputs that are not series: teacher concerns (§4.5; a teacher's safeguarding flag is a referral to the school's route, not an engine input), behaviour incidents the school defines as serious, the university rules including the results-day check (§4.6), open and recently closed cases (relapse, recovery, §4.7).
7. **Combines** across domains by level, breadth and persistence, never by a weighted sum (§7), and maps the result to one of the five tiers under **hysteresis**: a tier comes down only when the measures that raised it have been quiet for two weeks of data and their mean since the case opened is back under the floor, never on the CUSUM's memory (§8). A case with an unreleased safeguarding escalation is **pinned**: the engine may raise it and never lower or close it (§8.2). Only lowerings and repeated reversals are rate-limited; a raise into `checkin` or `urgent` is never held.
8. Writes the evaluation, the signals with their frozen inputs (including the vocabulary attributes they used), the evidence items with snapshots, and the case movement, under the configuration versions it ran with (§16), and computes "what changed overnight" against the last successful run (§13.6).

Three inputs that arrive during the day (a teacher concern, counselor context, an enrolment change) trigger an immediate evaluation of that one student, which may raise or attach but never lower except on context (§7.5). Counselors set the thresholds, floors, persistence and tier mapping per school through versioned configuration with guards against switching a domain off by accident (§10). In the pilot the engine runs in shadow with its own case state, so shadow measures the engine that goes live (§14), and before any real data it is tested against an adversarial synthetic set and both synthetic schools' expected results (§15).

### 0.5 What the pass 8 revision changed (2026-09-24)

Finding numbers are pass 7's (`07-review.md`); the changelog in `08-changelog.md` gives every edit. The larger changes, by where they land:

- **Attendance and the detectors, detuned for the pilot** (F05, C9, F25, F68). Attendance in days from the master register over non-overlapping fortnight blocks, a scale floor from a day-level model, a minimum meaningful change above one day, and the domain held at weak until reason-code coverage is measured; z capped at 3 inside the CUSUM, strong shocks through their own rule, one persistence rule, persistence of three weeks, scale floors at the full typical noise; exit and recovery on levels and the mean since the case opened; the chart restarted when a case opens; ordinal one-step moves held across two assessments; behaviour counted weekly; register, unit and window stated per measure. §0.4, §3.2 to §3.8, §4.1, §4.2, §4.4, §4.7, §8.3, §10.1.
- **Calibration regenerated from the engine's own level function** (F06). `calibrate_tiers.py` is published in the appendix, was run for this revision, and every number in §2.3, §3.6, §7.3 and §11.1 is its output under seed 20260924. "New items" are entries into a tier. Several first-version claims no longer hold and are withdrawn where they stood: the detuned engine is much quieter and much slower (§3.6, §11.1).
- **Seed reproduction re-traced** (F06, F31). The authored attendance and punctuality series are re-authored in days and late days, because no register produces them as printed; the ACS fixture's imported history gives every authored student at least twenty in-band weeks; seven of the fifteen authored tiers differ from the prototype under pilot defaults (one of them only by arriving two weeks later), and the list says which and why. Wellesmere gets its own expected-result list. §7.2, §15.1.
- **Academic domain through the year** (F25). Baselines carried across a two-year course, history counted in assessments, the self-starting band replacing the band-phase cap, a termly file with dated per-assignment rows run as a backfill capped at `review`, working-grade-only files requiring a two-step drop or a drop held across two windows, and the screen saying which domains are still building a baseline. §3.2, §3.10, §4.8, §5.
- **The common-cause cap is gone** (F26). No student's level depends on other students; the ops count and the prompt to declare a `calendar_period` stay. §7.6, §6, §13.2, C5, open decision 5.
- **Escalated cases and the rate limit** (F07, F08). The engine may raise and never lower or auto-close a case with an unreleased escalation; a person sets the tier after the outcome; the hold applies to lowerings and repeated reversals only; new scenarios S24 and S25; S19 extended. §8.1 to §8.4, §15.1.
- **Shadow mode runs the live engine** (F24, C9, F75). Shadow cases with `shadow = true`, evidence stored against the evaluation, backfill and event runs included, twenty weeks of history before shadow, blinded judgement against matched unflagged students, and G-LIVE bars as pre-registered intervals pooled across counselors with a minimum of about 40 cases; D25's view rewritten, `security_invoker`. §1.4, §14, D25.
- **Fairness** (C11, F68, F42). No special-category label is collected during the pilot; the audit runs only on pooled cross-school data from customer tenants, pre-registered, with intervals and a multiple-comparisons rule; D26 is unused in the pilot. §12, §14.5.
- **Operations** (F36, F34, F60, F42, §12.1, §12.16). Scheduling and alerts key on schools holding data through `core.schools_due_for_sweep()`; reporting as per-tenant aggregate tables, never materialised views; ops alerts carry counts, through Azure Monitor action groups; every cross-school count keys on `core.school.purpose`; `sweep.completed` left to pass 1. §13.
- **Smaller corrections**: teacher safeguarding referrals are not engine inputs (F10); vocabulary attributes snapshotted into rule hits (F48); the queue's within-tier order tested (F50); the headline rephrase removed (F52); results-day `offer_condition_check` and calendar-day university clocks outside term (F64); statement completeness from `uni.statement_complete()` (F32); the backtest in UAE North (F23); the DPIA (F37); four cited facts corrected and every citation re-checked (F69); smaller engine and documentation errors (F78); reveal weeks counted from the first shadow sweep (§12.17 of the pass 7 review); pass 4's data-class keys (D30).

---

## 1. What the engine is for

### 1.1 The purpose, in measurable terms

The engine exists so that, each morning, a counselor responsible for about 87 students opens a queue that is short enough to read and correct enough to trust, and in which the students who have started to move against their own pattern appear **before** they ask for help and **before** the movement becomes a crisis or a missed deadline. Three quantities define success and every one of them is measurable from the event stream pass 1 defined (`events.v_case_timeline`):

| Quantity | Definition | Measured from |
|---|---|---|
| **Lead time** | Days between the engine opening or raising a case and the counselor's own first recorded action on that student that was not prompted by the case (backtest), or the counselor's judgement in shadow mode that they would have wanted to know (§14) | `case.opened` versus the counselor log / historical intervention dates |
| **Precision of the action tiers** | Share of cases opened or raised into `checkin` or `urgent` that the counselor accepts, acts on, or escalates, rather than dismisses or downgrades twice | `case.accepted`, `case.dismissed`, `case.downgraded` |
| **Miss rate** | Share of students a counselor supported (a recorded intervention, referral or escalation) for whom the engine had no case at `review` or above in the four school weeks before the counselor's first action | backtest (§15.2); in production, interventions opened manually (C2) on students with no open case |

Two more are constraints rather than goals: **queue size** (new items in the action tiers per weekly pack, or per morning under a nightly connector, §11; a **new item** is an entry into a tier, a case opened into it or raised into it, and the cases sitting in a tier are its occupancy, reported separately, F06) and **time to aware** (median from `case.opened` to `case.viewed`, which the product already promises to report).

### 1.2 What a correct signal is

A signal is correct when the movement it reports is real (the student's own series changed, and the change was not explained by a declared context) **and** the counselor, on looking, judges the tier's action proportionate. The second half matters: a statistically real change that no counselor would act on is not a correct `checkin`; it may be a correct `monitor`. So correctness is defined per tier:

- `urgent`: the counselor refers or escalates, or accepts and acts the same day.
- `checkin`: the counselor accepts (an intervention or a meeting is opened) or, after the conversation, records that it was worth having. A check-in that finds nothing wrong is not a false alarm if the counselor says it was worth the ten minutes; the tuning log records which it was.
- `review`: the counselor looks and either accepts, adds context, or dismisses with a reason. Only a dismissal with the reason *nothing here* counts against precision.
- `monitor`: the case is never wrong; it asks for nothing. It is correct if it stays quiet when nothing follows and escalates when something does.
- `good`: the counselor acknowledges the recovery and closes; a relapse inside the window afterwards does not make the `good` wrong.

A signal is a **miss** when the counselor acts on a student the engine had at `monitor` or nothing, and the data that would have shown the movement existed in CAROS at the time. A miss where the data never reached CAROS (a termly-only domain, a concern nobody logged) is a data gap, recorded separately, because the cure is different.

### 1.3 The cost of a miss against the cost of a false alarm

Two costs, and they behave differently. A single miss costs the student the lead time, and at the top of the scale it can cost far more: the safeguarding pattern the corroboration rule exists for (three staff noticing the same change in a week) is exactly the case where a day matters. A single false alarm at `checkin` costs a counselor ten to thirty minutes and, sometimes, an awkward conversation with a student or family. On those figures a miss is worth ten to fifty false alarms, and a decision-theoretic threshold (Pauker and Kassirer 1980: act when the probability of the condition exceeds the ratio of the cost of acting unnecessarily to the sum of both costs) would set the check-in bar around a five to ten percent chance that something is wrong.

But false alarms do not stay single. Alerts that are usually wrong are ignored, and the ignoring spreads to the alerts that are right. Clinicians override drug safety alerts in 49% to 96% of cases (van der Sijs et al. 2006); acceptance falls as volume rises, and in a four-year primary-care cohort it fell by 30% for each additional reminder in an encounter and by 10% for each five-point rise in the share of repeated reminders (Ancker et al. 2017); people's rate of responding to an alarm tracks the alarm's reliability, so a 50%-reliable alarm gets answered about half the time (Bliss, Gilson and Deaton 1995); and disuse of automation is the predictable result of alarms set without regard to the base rate (Parasuraman and Riley 1997). A queue that is wrong most mornings therefore produces misses of its own, silently, through the counselor's attention. The engine's design follows from holding both truths at once:

- **Sensitivity is cheap where it costs no attention.** The `monitor` tier absorbs weak and isolated signals at high sensitivity, because a monitor row asks nothing and is never a card. The run on the sheet, the soft cells, the auto-review are where the engine is generous.
- **Attention is spent only on corroborated or persistent change.** `checkin` and `urgent` require breadth across domains, persistence over weeks, independent human observation, or a school-defined event (§7, §8). The noise floor for those tiers under the defaults is a fraction of a case per week (§11).
- **Repeats are the enemy.** Ancker's strongest finding is that repeats of the same alert erode acceptance fastest. A case that is open does not produce a second card for the same evidence; new evidence attaches to it (C3) and is printed as "since yesterday". A dismissed case is not reopened on the same evidence inside a cool-down (§8.3).
- **The engine never ranks students to make room.** When a morning exceeds the budget the engine says so and asks for tuning; it never trims the list (§11.3), because a trimmed list is a ranking of students against each other (invariant 2).

The base rate is the number nobody has yet. Globally one in seven 10-to-19-year-olds has a mental health condition (WHO, adolescent mental health fact sheet, updated 2025), but the engine's target is wider than mental health and narrower than "any bad week". The planning assumption, to be replaced by the backtest, is that ten to twenty percent of a caseload has an episode in a term that a counselor would want to notice: nine to seventeen students over about fifteen school weeks, roughly one new genuine episode a week. The engine is tuned so that the noise in the action tiers sits well under that rate (§11).

### 1.4 Targets, and what they are not

`METRICS` in the prototype (`index.html:1596`) carries an 81% accept rate and a 14% false-positive ceiling, labelled targets. The pilot exit is not judged on point targets. Revised by pass 8 (F24): a point bar of "60% at check-in, 25% at review" is a coin toss at pilot scale (a 95% interval on 12 correct out of 20 runs from 36% to 81%), so G-LIVE is judged on **pre-registered intervals, pooled across the four counselors, over at least about 40 blindly judged cases** (§14.5). The working aims beside it: a lead time on the cases the backtest can see that the counselors judge worth having, no counselor-handled case missed where the data existed without a recorded reason, and a queue the counselors named as useful in the elicitation. They are aims. Nothing here is a measurement, and nothing will be until the shadow period ends.

---

## 2. What the research supports, and what does not transfer

### 2.1 Early warning indicators: cohort-level truth, individual-level caution

The early warning literature is the strongest evidence that attendance, behaviour and course performance carry information about a student's trajectory. It is also, almost without exception, **cohort-level prediction**: a threshold chosen because, across thousands of students, those above it went on to a bad outcome at a higher rate. That is not the question this engine answers. The distinction governs what transfers.

**Balfanz, Herzog and Mac Iver (2007)** followed 12,972 Philadelphia sixth graders from 1996–97 for eight years. Five flags (attending 80% or less, a failing final grade in mathematics, a failing final grade in English, an out-of-school suspension, an unsatisfactory final behaviour mark) each identified a group of which only 12% to 24% graduated on time (13% for attendance, 13% for mathematics, 12% for English, 16% for suspension, 24% for behaviour). The 60% figure is for **four** of them: poor attendance, an unsatisfactory behaviour mark, and failure in mathematics or English together identified 60% of the students who did not graduate (corrected by pass 8, F69: the first version attached the 60% to a list that included suspension; the paper used the behaviour mark as its misbehaviour flag because almost every suspended student also had one). Attendance and course failure were the sharper flags; behaviour amplified them (77% of the students failing mathematics also had an unsatisfactory behaviour mark; re-read in the paper's text on 2026-09-24). *What transfers:* the three domains and the finding that co-occurring flags are far more predictive than any one, which is the basis for combining by breadth (§7). *What does not:* the thresholds. "Attends 80% or less" is a level, chosen for a population, in a district where a third of sixth graders were below it; at ACS a student at 80% has probably already been noticed, and a student who has gone from 99% to 91% has not. The engine uses a level only as a school-policy floor at `review` (§4.2), never as its main rule.

**Allensworth and Easton (2005, 2007)**, UChicago Consortium: the Freshman On-Track indicator (at least five full-year credits and no more than one semester F in a core course) separated graduation rates of 81% (on track) from 22% (off track) in the 1999 Chicago cohort; course attendance in the freshman year was eight times more predictive of course failure than eighth-grade test scores, and a week of absence in a semester was associated with a substantially greater likelihood of failure regardless of incoming achievement. *What transfers:* attendance is the earliest and most sensitive of the three, and small amounts of absence matter; it is why the attendance domain is weighted toward change in weeks, not terms. *What does not:* the indicator itself, which is a term-end fact about credits.

**Bowers, Sprott and Taff (2013)** reviewed 110 dropout flags across 36 studies with ROC analysis and found that most flags have high precision but poor overall accuracy, that longitudinal growth models (a student's own grade trajectory over time) gave the most accurate flags, and that among cross-sectional flags low or failing grades and the Chicago on-track indicator did best. *What transfers, and it is the most important finding for this design:* **the shape of a student's own trajectory beats a snapshot against a threshold.** That is the personal-baseline thesis, stated in the cohort literature's own terms. *What does not:* the models themselves, fitted across cohorts.

**Faria et al. (2017)**, REL Midwest: a randomised trial of an early warning system (EWIMS) in 73 high schools lowered the share of students chronically absent (10% against 14% in control schools) and the share failing one or more courses (21% against 26%) after one year, with no detectable effect on the low-GPA or suspension indicators or on the share of students with too few credits to be on track (corrected by pass 8, F69: the report's primary model gives effect sizes of −0.26 for chronic absence and −0.17 for course failure, per the pass 7 review's reading; the first version's "+0.23" is not in the report; the percentages are from the report's summary page, re-read 2026-09-24). *What transfers:* showing staff attendance and course flags changes attendance and course outcomes; it is evidence that the loop from signal to counselor to student is real. *What does not:* EWIMS is a cohort-threshold system, and the trial says nothing about personal deviation.

**Knowles (2015)**, Wisconsin's statewide DEWS, and the machine-learning line that follows it, predict non-graduation for hundreds of thousands of students from administrative data. They are the clearest case of what this engine is **not**: a risk score attached to a child, trained on populations, opaque in its features. **Anderson, Boodhwani and Baker (2019)** show such graduation predictions can perform differently across demographic groups, which is why §12 exists.

**Chronic absence** is conventionally defined as missing ten percent or more of the school year for any reason, about eighteen days of a 180-day year (Balfanz and Byrnes 2012; the definition used by Attendance Works and the U.S. Department of Education). *What transfers:* a defensible, citable level floor for the attendance domain's policy rule. *What does not:* the number, which each school sets for itself under its regulator's attendance policy (for ACS, ADEK's 2025 attendance policy, pass 2 §5.2).

**Office discipline referrals**: McIntosh, Frank and Spaulding (2010) established research-based trajectories for ODR counts and showed that the 0–1, 2–5, 6+ categories used in schoolwide PBIS settle late in the year (only 20% of students were in their final category by the end of November, 50% by February, 80% by April). *What transfers:* behaviour counts are sparse and lumpy, so a within-year count threshold is unstable early in the year; the behaviour domain uses a personal rolling two-week rate with a Poisson-style floor, not a cumulative count (§4.4). *What does not:* the categories.

**Seasonality.** In U.S. daily attendance data absences rise through the autumn, peak in winter, stay near peak through the spring, spike before holidays and rise again in the final week (Hollon, Malkus, Lenhoff and Singer, AEI, *What Stories Does Daily Attendance Tell?*, 22 October 2025, re-read 2026-09-24). A related AEI report, *Please Excuse My Child*, finds the **share of absences that are unexcused** rising over a year, from 35% of absences in August 2023 to 55% in May 2024 (corrected by pass 8, F69: the first version's "1.6% in August to 4.1% in May" is not in the report). That second finding bears on this engine directly: how an absence is coded drifts over the year, which is one reason the attendance domain is held at weak until ACS's own reason-code coverage is measured (§4.2). *What transfers:* a personal baseline drifts with the year and a fixed band would fire in spring on nothing; the trailing window and the calendar suppressions exist for this (§3.9). *What does not:* the U.S. calendar; ACS's year, Ramadan and its own holidays are the tenant's calendar (pass 2 §5.6).

### 2.2 Teacher recognition

Teachers identify severe externalising and internalising problems accurately but are less accurate and less likely to refer for moderate or subclinical symptoms, and they rate externalising problems as more serious and more concerning than internalising ones (Splett et al. 2019, vignette study with 153 teachers). Universal screening identifies more students than teacher nomination, including students teacher referral had not identified (Dowdy, Doane, Eklund and Dever 2013; and the Eklund and Dowdy line on screening versus referral). *What transfers:* the teacher-concern domain is the school's earliest and cheapest signal for the loud change (Tariq) and a weak one for the quiet decline (Ahmed, Priya), which is exactly the case the series detectors exist for. The two channels are complementary, so the combination rule treats a teacher concern plus a series deviation as breadth, not as duplication (§7). *What does not:* the screening instruments; CAROS runs no screener.

### 2.3 Statistics for a short individual series

The engine's statistical problem is unusual only in its smallness: one student, one measure, eight to twenty weekly points, no population to borrow from. The tools that fit are old and well understood.

- **Robust location and scale.** The mean and standard deviation are themselves moved by the outlier one is looking for; the median and the median absolute deviation are not (Hampel 1974 on influence; Leys et al. 2013, who recommend the MAD with a consistency constant of 1.4826 and thresholds of 2.5 (moderately conservative) or 3). Iglewicz and Hoaglin (1993) give the modified z-score 0.6745·(x − median)/MAD with 3.5 as the outlier cut. Rousseeuw and Croux (1993) offer Sn and Qn, more efficient than the MAD (Gaussian efficiency 58% and 82% against 37%) at the cost of explainability; the engine uses the MAD because a counselor can be told what it is in one sentence, and revisits Qn only if the backtest shows the MAD's inefficiency costs lead time.
- **Sustained shifts: CUSUM.** Page (1954) introduced the cumulative sum; the tabular form with reference value k (half the shift to detect, in scale units) and decision interval h is standard (NIST/SEMATECH e-Handbook §6.3.2.3: k as half the shift, h "around 4 or 5"). With known parameters, the one-sided chart this engine uses has an in-control average run length of about 931 observations at k = 0.5, h = 5, and 335 at h = 4 (computed by the appendix script with the Markov-chain method of Brook and Evans 1972), so the two-sided chart's is about 465 and 168; Hawkins and Olwell (1998) give the full tables. Corrected by pass 8: the first version sourced the 465 to SigmaXL's tabular CUSUM page, which describes the method but does not state the figure (pass 7 citation register); the figure itself is right. Capping each week's step at three scale units (§3.4) lengthens the one-sided run lengths slightly, to 974 and 346 (computed). The CUSUM's byproduct is the reason it is chosen over the alternatives: the last time the sum was zero is a built-in estimate of **when the change began**, which is the "how long it has persisted" tile. Run-length distributions come from Brook and Evans (1972).
- **EWMA** (Roberts 1959; Lucas and Saccucci 1990 for the design tables; robust to non-normality for small λ per Borror, Montgomery and Runger 1999) detects the same shifts with a smoother statistic and is the natural choice for a chart one *looks at*. It has no onset estimate and its statistic is harder to narrate ("your weighted average has fallen below…"). The engine draws the plain series and the band, and keeps the CUSUM for decisions. EWMA is the named alternative if the CUSUM's step-like behaviour proves hard to explain in shadow mode.
- **Counts and proportions.** Attendance is a count of days over a fortnight and behaviour points are sparse counts. Lucas (1985) gives the CUSUM for counted data and Borror, Champ and Rigdon (1998) the Poisson EWMA; the engine keeps one detector family for explainability and instead floors the scale at the binomial or Poisson noise of the student's own rate, never below the typical student's, so that a 100%-attendance student's first absent day is not a fifty-sigma event (§3.3, §3.7).
- **No history: self-starting charts.** Hawkins (1987) built CUSUMs that use the running mean and standard deviation of the observations so far in place of unknown parameters; Quesenberry (1991) built Q-charts for start-up processes and short runs. They are the principled answer to cold start (§5): the student's first weeks become their own baseline, with limits widened for the uncertainty, rather than a population's.
- **Run rules.** The Western Electric rules (1956) and Nelson (1984) formalised "several points on one side" tests; the persistence requirement is one of these, stated in weeks.
- **Change-point detection.** PELT (Killick, Fearnhead and Eckley 2012) finds the optimal segmentation of a series at linear cost; Truong, Oudre and Vayatis (2020) review the offline field; Adams and MacKay (2007) give the Bayesian online form. They are the right tools for the **backtest** (segmenting two years of history to find where real changes happened) and the wrong tools for the nightly rule: a segmentation is a model fit whose explanation is a likelihood, and a counselor cannot argue with a likelihood. The nightly engine uses the CUSUM's onset estimate and PELT is confined to validation (§15.2).
- **Estimated parameters hurt.** Charts designed for known parameters have far worse false-alarm behaviour when the parameters are estimated from a short history; this is well known in the SPC literature and the appendix script reproduces it: a CUSUM designed for one false alarm in 335 weeks (h = 4, no cap, no floor) stands at or above h in 7.9% of weeks when its scale comes from twelve points (computed, eighth week of monitoring; corrected by pass 8, F78: the first version said "about 4%", which its own table contradicted). The design answer is the scale floor, the minimum meaningful change floor and a widened scale for short histories, not a bigger h.

### 2.4 Alert fatigue

The clinical decision support literature is the closest study of a queue like this one. Beyond the figures in §1.3: Kesselheim et al. (2011) argue that alert volume can be cut without increasing liability by tiering alerts and suppressing low-value ones; Drew et al. (2014) recorded 2,558,760 monitor alarms on 461 intensive care patients in 31 days, most of them clinically irrelevant, as the empirical picture of what un-tiered sensitivity produces. The design consequences are in §1.3 and §11.

### 2.5 What the engine takes from all of this

1. Three primary domains (attendance, course performance, behaviour), with attendance the most sensitive to small change, and a fourth human channel (teacher concern) that catches what the series cannot.
2. A student's own trajectory, robustly summarised, is the right object; population thresholds are floors, never the rule.
3. Co-occurrence across domains and persistence over weeks are what separate a real change from a bad week; combination is by breadth and persistence, not by adding scores.
4. The queue's acceptance rate is itself an input to the queue's future accuracy, so the action tiers are budgeted and repeats are suppressed.
5. Every number shown has a definition a counselor can repeat; the detectors are the simplest ones that have an explanation.
6. Anything cohort-level enters only as a declared policy floor or as a validation instrument, never as the comparison.

---
## 3. The series and the personal band

This section is the machinery every series domain shares. §4 says what each domain feeds into it.

### 3.1 School weeks and points

- A **school week** is the run of school days from the first day after the tenant's weekend (`core.school.weekend_days`, pass 1) to the next weekend, indexed `t = 1, 2, …` within an academic year (`sis.academic_year`). School days come from `sis.school_day`. A week with fewer than three school days (a holiday-adjacent week) is a **short week**.
- A **point** `x[q,t]` is one observation of one measure `q` (defined per domain in §4) for one student, computed from `sis.v_current_*` rows (pass 2 §7.9) so that conflicting imports resolve the same way everywhere. Three cadences, each stated per measure in the thresholds schema with its register, unit and window (§10.1, F68): **per assessment** for attainment (each graded assessment is a point, placed in the week it was graded, so history is counted in assessments, F25); **per school week** for weekly rates and counts (submission, behaviour, engagement); **per fortnight block** for attendance (ten school days, blocks numbered from the first school week of the academic year and never overlapping, F05). A weekly or block point exists only if it carries at least `n_min(q)` observations; otherwise it is **null**. A short week is null unless `n_min` is met anyway.
- **Weeks of data.** Wherever this document counts persistence, exit or recovery in weeks, it counts weeks of data: a weekly point is one week, a fortnight block two, and an attainment point one assessment (so, for attainment, "three weeks of persistence" reads "three assessments").
- The **current week** (and the current fortnight block) is provisional until it has closed. Provisional points count for the shock rule (§3.4) and in evidence sentences ("Tuesday's result"), not for the baseline or the CUSUM. Under the weekly pack every week is complete; the second week of a block closes it; under a nightly connector the current week is provisional.
- Every domain has an **as-of** date: the later of `ingest.expected_cadence.last_as_of` for its import kind and the newest fact date it read (pass 2 DR-14). The sweep stores it on the snapshot and the sheet prints it ("attendance as of 13 Nov").

### 3.2 The baseline window

`B[q,t]` is the set of the most recent `W` valid points of **this student's own** series strictly before `t`, where valid means non-null and not suppressed for the measure's domain (§6). Defaults: `W = 20` weeks of data (§3.1): twenty assessments for attainment, twenty weekly points, ten fortnight blocks for attendance. The window crosses term boundaries inside an academic year. It crosses the academic-year boundary for attendance, behaviour and engagement (a student's own attendance last year is still their attendance) and, since pass 8, for attainment **within a subject for a two-year course** (F25): IB Diploma and A-level subjects, and any course the school marks as two-year, carry their baseline from the first year into the second (§3.10). A one-year course starts again with the course. `H = |B|` is `history_weeks` on the snapshot; for attainment it counts assessments.

**Episode exclusion.** Weeks inside a case's window on that case's triggering measures are excluded from `B`: from `window_start` to `closed_at` for a closed case, and from `window_start` to the as-of date while the case is open. While a case is open, therefore, the baseline of each triggering measure is the one it had when the case opened, which is also the reference for the run-mean since opening that exit and recovery read (§8.3). Revised by pass 8 (F78): the first version excluded only closed cases while scenario S2 assumed an open case's dip was excluded too; both now say the same. Without the rule a student's own crisis becomes their baseline: Hana's October episode, left in the window, raises her own absence share and so her scale floor, and her relapse sits inside a wider band. With it, her baseline is her normal. The excluded weeks are listed in `features.excluded_episodes`.

Two history thresholds, configurable (§10):

| Parameter | Default | Meaning |
|---|---|---|
| (self-starting) | 3 | From the third valid point the engine runs in self-starting form: levels capped at weak, except that a strong shock is moderate (§5) |
| `min_history_band` | 8 | From here the band is drawn, the run is real and the full ladder of §3.5 applies; below it the sheet shows `none` cells and the file says "building a baseline: 5 of 8 assessments" (or weeks, or blocks) |
| `min_history_full` | withdrawn | The first version capped every level at weak below twelve points. Withdrawn by pass 8 (F25): with sparse grading it kept most academic sections inert until late in the year. The scale is instead widened for its own uncertainty at every history length (§3.3), which the calibration shows is enough once the floors sit at the full typical noise (§3.6) |

Twenty is not arbitrary: with twelve points the estimated scale is loose enough to double the false-alarm rate against twenty (§3.6), and twenty weeks is about a semester at ACS, so the band describes "this student, this half-year". The pilot imports at least twenty weeks of each student's history before shadow starts (§5, §14), so the full window exists from the first shadow sweep.

### 3.3 Location, scale and floors

For a measure with adverse direction `dir(q) ∈ {−1, +1}` (attainment: lower is adverse, `dir = −1`; days missed, late days or conduct points: higher is adverse, `dir = +1`):

```
m        = median(B)                                         personal location
MADn     = 1.4826 · median( |b − m| for b in B )            robust scale, consistent with σ under normality
s        = max( MADn, s_floor(q) ) · sqrt(1 + 1/H)          the scale the engine uses; "σ" wherever the UI prints one
d[q,t]   = dir(q) · ( x[q,t] − m )                           adverse deviation, in the measure's own units
z[q,t]   = d[q,t] / s                                        robust z, the printed sigma value
```

`MADn` follows Leys et al. (2013) and Hampel (1974). The factor `sqrt(1 + 1/H)` widens the scale for the uncertainty of a median taken from `H` points, in the spirit of the self-starting charts (§2.3); it is 1.02 at twenty points and 1.06 at eight, and it replaces the first version's weak cap below twelve points (F25). `s_floor(q)` is the **scale floor**: the noise a perfectly steady student still has, so that the first absent day of a 100%-attendance student is not a fifty-sigma event. It is derived, not set:

| Measure family | `s_floor` | Why |
|---|---|---|
| Percentage attainment (one assessment) | 4.0 points | The full typical noise of a single assessment's score about a steady student's median (planning assumption: about four points; the backtest measures ACS's own, §15.2). The first version set the floor at three-quarters of that (3.0); decision C9 sets it at the full noise |
| Ordinal grade (IB 1 to 7, AP 1 to 5, A level, GCSE 9 to 1) | 0.5 step | A MAD of zero is the normal case for a steady student on a seven-point scale, and half a step is about the typical spread of a steady student's grades; the two-assessment hold on one-step moves (§3.4) does the rest (F68) |
| Days missed per fortnight block (attendance) | `sqrt(n̄ · p · (1 − p))`, with `p = max(p_own, p_typ)` | The day-level model F05 asks for: the binomial noise of a count of days, where `p_own` is the share of registered days the student missed across the window, `p_typ` the school's typical absence share (a configured constant, default 0.05, a planning assumption until the backtest measures ACS's, and never computed from other students' data at run time), and `n̄` the median registered days per block (10). At the defaults it is 0.69 days for every student who misses fewer than one day in twenty: the full typical noise of a 95% attender (C9) |
| Proportion over items (coursework submission) | `100 · sqrt(p (1 − p) / n̄)`, with `p = max(p_own, 0.05)` | Binomial noise of the share submitted, at the student's own rate or the typical one, whichever is larger, over `n̄` items due a week; about 10.9 points at four items |
| Counts (conduct points; late days and unexplained days in the attendance rules) | `sqrt( max(λ_own, 0.5) )` | Poisson noise at the student's own mean over the window (the mean, not the median, because the median of a rare event is zero); the 0.5 keeps a zero-baseline student from a zero scale |
| Days of silence | 1.0 | |

**What "floors at the full typical noise" means here** (decision C9, recorded as a reading in the changelog). Two floors act on every measure. The scale floor `s_floor` is set at one full unit of a typical student's per-point noise for its family, not three-quarters of one. The minimum meaningful change `floor(q)` is never below that unit either. For attendance the typical noise comes from the day-level model, not from sessions.

Separately, every measure has a **minimum meaningful change** `floor(q)`, in the measure's own units, set by the school (§10) with these defaults: attainment 5 percentage points (1.25 units of the four-point noise) or 1 ordinal step, one-step moves held across two assessments; **days missed 1.5 days per fortnight block**, so a single day never fires anything and two days can (F05: "above one day"; 2.2 units of the 0.69-day noise); late days the school's tolerance `att` per block and unexplained days 2 per block, both through rules (§4.2); conduct 3 points per week (a weekly floor on the weekly series, F68); submission 15 points (1.4 units); active days 2 per week; silence 14 days. No detector fires unless `d ≥ floor(q)` (for the CUSUM, the mean deviation since onset). The floor is what stops a very steady student's trivial wobble from becoming a sigma-count nobody would act on, and it is the single most effective lever on false alarms (§3.6). It is also the answer to "how big is a change for a strong student versus a struggling one": the personal band scales with each student's own variability, and the floor is the same for both.

### 3.4 The detectors

Four detectors run on every measure with a band; each has an explanation a counselor can repeat.

**The band and the run.** The band is `[m − c·s, m + c·s]` clipped to the measure's range, `c = 2.5` (Leys et al.'s moderately conservative cut; ordinal 1.5). A point is **outside** when it lies beyond the band **and** `|x − m| ≥ floor(q)`. On an ordinal scale a **one-step** adverse move counts as outside only when the previous valid point was also at least one step below the median, that is, when it has held across two assessments; a move of two steps or more is outside at once (F68). The engine writes `outside` on every point it stores, and the sheet's run (`signal.week_run()`, pass 1) reads it: `kept` when every measure is inside, `soft` when exactly one is outside, `break` when two or more are, `none` when no measure has a point (F40). Adverse-outside feeds the level; favourable-outside feeds recovery and positive evidence.

**The shock.** A single point far out: `z ≥ z_shock` (default 3.0, between Leys' 3 and Iglewicz–Hoaglin's 3.5; ordinal 3.5) with `d ≥ floor`. A shock on its own is **weak** (the prototype's Yousef: one mock result of 74% against his median of 87% is a shock, `z` about 3.2, and sits in Monitor, §7.2).

**The strong shock, through its own rule** (F05). `z ≥ z_shock_strong` (default 5.0) with `d ≥ 2·floor`. It is **moderate** on its own, because a result that far from a student's own pattern (Ahmed's 41% against a median of 90.5%) is worth a look before the next result arrives; it is **strong** when the previous valid point of the same measure was already outside. It never reaches the CUSUM at full size: the first version let a single outlier's `z` of about 9 carry the sum past `h_strong` and hold it there for a term (F05); the cap below stops that, and this rule carries what a single large point should mean.

**The CUSUM.** A one-sided cumulative sum in the adverse direction (Page 1954; tabular form per NIST §6.3.2.3), with each week's step capped:

```
S[q,0]   = 0                                    reset at the start of each academic year, when the series starts,
                                                and, for a case's triggering measures, when the case opens (below)
S[q,t]   = max( 0, S[q,t−1] + min(z[q,t], z_cap) − k )   over valid, complete points; a null point leaves S unchanged
k        = 0.5                                  tuned to a shift of one scale unit
z_cap    = 3.0                                  no single point adds more than 2.5 to S (F05)
τ[q,t]   = the first valid point after the last point at which S was 0     (estimated onset)
run_mean = mean( d[q,u] for u in τ..t )                                   (mean adverse deviation since onset)
signal   ⇔ S[q,t] ≥ h  and  run_mean ≥ floor(q)
P[q,t]   = consecutive weeks of data, ending at t, at which the signal held    (persistence; a null point neither
                                                                              advances nor resets it)
window   = school days from the first day of τ's week to the as-of date   (the "how long it has persisted" tile)
```

Defaults `h = 5`, `h_strong = 8`. **One persistence definition** (F06): `P` is the number of consecutive weeks of data with the CUSUM signal, the only persistence the engine has. The first version defined `P` as weeks since onset, under which "S ≥ h with P ≥ 2" held almost whenever S ≥ h (2.79% against 2.78% of series-weeks, computed), while its own calibration script used consecutive weeks. The CUSUM is the detector for the quiet decline: eight results of 91, 89, 88, 86, 85, 84, 83, 82 from a median of 94.5 never produce a shock, and the sum crosses `h` at the fifth (scenario S1, §15.1).

**The chart restarts when a case opens** (F05). When a case opens, and when a measure is first attached to an open case as a triggering measure, that measure's chart restarts: `S = 0` and a new onset from the next valid point, against the baseline the measure had when the case opened (§3.2). The chart as it stood (S, onset, `P`, run-mean) is frozen in the signal's `inputs`, so the case explains itself. The restarted chart can still raise the case (a decline that continues re-accumulates and can reach strong); it no longer holds a case up on memory. Exit and recovery never read `S` (§8.3).

**The trend** is a sentence, not a decision: the Theil–Sen slope (Sen 1968; the median of pairwise slopes) over the last six valid points, printed as "falling about 3 points a week". It has one rule role: the **improving guard**. When the slope has been favourable for three consecutive valid points, the school-policy level rules (§4.2, §4.4) do not fire, and recovery detection (§4.7) may begin.

### 3.5 Levels

Each measure gets an ordinal **level** each night:

| Level | Name | Condition (any) |
|---|---|---|
| 3 | strong | the CUSUM signal with `S ≥ h_strong`, `P ≥ persist + 1` and a run-mean of at least `strong_mean_factor · floor` (default 1.5); or a strong shock on the point after an outside point |
| 2 | moderate | the CUSUM signal with `P ≥ persist` (default `persist = 3` weeks of data, decision C9); or a strong shock; or a shock on the point after an outside point; or the **scale-free rule**: `d ≥ 2·floor` for `persist_free` (default 3) consecutive valid points, whatever `z` is |
| 1 | weak | outside the band on this point (adverse); or a shock; or the CUSUM signal with `P < persist` |
| 0 | none | otherwise |

Three caps apply after the table. **Self-starting**: with `3 ≤ H < min_history_band`, the level is at most weak, except that a strong shock is moderate (§5). **Attendance held at weak**: until the school's reason-code coverage has been measured and a configuration version releases it, the attendance domain's level is at most weak (`attendance.max_level = 1`, §4.2, F05). **Attainment's second assessment**: an attainment series reaches level 2 through the CUSUM only if at least two assessments were graded since onset, so one bad assignment cannot become "moderate" by lingering.

The strong definition is deliberately three-sided: a single condition on `S` lets a scale estimated from a short history push quiet students into `checkin`. (The first version reported that its single-condition form put about thirteen quiet students a week into `checkin` on a caseload of 87; the pass 7 review found that figure reproduces only under an older, looser setup than the one the text specified, F06, so it is withdrawn as a finding and kept only as the reason the condition is three-sided.) Under the revised defaults the computed noise in `checkin` is 0.01 cases a week per 87 under normal noise (§11.1). The scale-free rule exists for fairness (§12.3): a student whose history is noisy has a wide band and a small `z` for the same decline, and the engine would otherwise be least sensitive for the students whose lives are least steady; a ten-point fall held for three assessments is moderate for everyone. Computed, it fires in 0.71% of weeks for a quiet student whose weekly noise is twice the floor, and in none measurably at the default floor (appendix, section B).

The **domain level** `L[d]` is the maximum over the domain's measures whose latest point falls inside the breadth window (§7.1); the domain's **breadth** (how many sections, how many measures) is printed with it ("in 3 of 6 subjects"). One within-domain rule adds corroboration: weak in three or more academic sections within the same three weeks is moderate for the domain, because a small decline everywhere is not noise in any one place.

### 3.6 Calibration, computed

Revised by pass 8 (F06). Every figure in this section comes from `calibrate_tiers.py` (appendix), which implements the level function above, run on 2026-09-24 with seed 20260924 and the defaults of this section. The per-measure table uses i.i.d. weekly noise, normal or Student-t with 3 degrees of freedom for heavy tails, a quiet student, a baseline of `H` points then eight monitored points, and floors expressed in units of the student's true noise; the rates are for the eighth monitored point. No autocorrelation, no seasonality: real series will be somewhat worse, and the numbers are for choosing defaults. Shadow mode measures the truth (§14).

| Noise | `H` | `s_floor` (σ) | floor (σ) | outside | shock | CUSUM signal | signal held 3 weeks | moderate |
|---|---|---|---|---|---|---|---|---|
| normal | 8 | 1.0 | 1.25 | 0.54% | 0.12% | 1.12% | 0.42% | 0.42% |
| normal | 12 | 1.0 | 1.25 | 0.56% | 0.11% | 0.65% | 0.23% | 0.23% |
| normal | 20 | 1.0 | 1.25 | 0.48% | 0.09% | 0.39% | 0.11% | 0.11% |
| normal | 20 | 1.0 | 1.0 | 0.49% | 0.10% | 0.49% | 0.14% | 0.15% |
| normal | 20 | 0.75 | 1.25 | 1.40% | 0.51% | 0.58% | 0.19% | 0.21% |
| t(3) | 12 | 1.0 | 1.25 | 3.15% | 2.00% | 1.97% | 0.73% | 1.30% |
| t(3) | 20 | 1.0 | 1.25 | 3.21% | 2.08% | 1.55% | 0.52% | 1.11% |

Four things to read from it. First, estimation still sets the noise, not the chart: with known parameters the capped one-sided chart at `h = 5` has an in-control run length of about 974 points (computed), yet with the scale estimated from twelve points the signal holds in 0.65% of weeks. Second, the scale floor is the strongest lever: moving it from three-quarters to the full typical noise cuts "outside" from 1.40% to 0.48% of points and shocks from 0.51% to 0.09%. Third, the history length matters: eight points of history carry about four times the moderate noise of twenty, which is why the pilot imports twenty weeks before shadow (§5). Fourth, under heavy tails almost all of the moderate noise is the strong-shock rule, which is doing what it was built to do: a t(3) series produces genuinely extreme single results.

Detection of a genuine change on one measure, twenty points of history, the defaults above, normal noise: the probability of reaching moderate within eight points and the median delay from onset are, for a sustained shift of 1.5σ, 52% and 7 points; 2σ, 84% and 6; 3σ, 99.7% and 4; a decline of 0.5σ a point, 91% and 7; 1σ a point, 100% and 4 (computed). Under t(3) noise the 1.5σ shift is caught 45.5% of the time within eight points. For an attainment series the unit is an assessment, not a week: a section graded every other week takes twice as long in calendar time. **This is much slower than the first version claimed** (a 1.5σ shift caught 72% of the time with a median of three weeks), and the difference is the price of decision C9: floors at the full noise, three weeks of persistence and the capped step. The tier-level picture, which is what a counselor sees, is §11.1.

The defaults therefore are: `W = 20`, `min_history_band = 8`, `c = 2.5` (ordinal 1.5), `z_shock = 3.0` (ordinal 3.5), `z_shock_strong = 5.0`, `k = 0.5`, `z_cap = 3.0`, `h = 5`, `h_strong = 8`, `strong_mean_factor = 1.5`, `persist = 3`, `persist_weak = 3`, `persist_free = 3`, a breadth window of two weeks (§7.1), scale floors at the full typical noise and minimum-meaningful-change floors at one to about two units of it (§3.3), and attendance held at weak. The tier-level simulation (§11.1) runs the whole of §3 to §8 on native-unit students and is the number that matters for the queue.

### 3.7 Ordinal and count scales

Series are analysed in the scale their facts are in, never through `normalised_pct` (pass 2 §5.1). Per-scale defaults, overridable per school:

| Scale | point | `c` | `z_shock` | `s_floor` | `floor` | Note |
|---|---|---|---|---|---|---|
| `pct` | one assessment's `score × 100 / max` | 2.5 | 3.0 | 4.0 | 5 | |
| `ib_1_7`, `ap_1_5`, `a_level`, `gcse_9_1`, `ib_core_letter` | one assessment's grade as an integer rank | 1.5 | 3.5 | 0.5 | 1 step | with `s` at the floor, a one-step drop is `z` about 2 and outside only when held across two assessments; a two-step drop is `z` about 4, a shock. Computed for steady IB students (appendix, section E): 17.48% of graded weeks fell outside the first version's band, 5.04% fall outside with the hold, and 0.28% are moderate (F68) |
| `gpa_4`, `school:<slug>:<key>` numeric | as `pct` on the declared range | 2.5 | 3.0 | 2% of range | 5% of range | |
| counts | the count in the measure's window | 2.5 | 3.0 | Poisson at the student's own mean | per measure | |
| days missed | days in the fortnight block | 2.5 | 3.0 | day-level binomial (§3.3) | 1.5 days | |

### 3.8 Missing data

- A **null point** is skipped: not in `B`, `S` unchanged, `P` not advanced, the run cell `none`. Nothing missing is ever adverse.
- A **missing assignment** is not missing data: it is an observation of the submission series (`sis.grade.missing = true`, pass 2), which is why that series exists separately from attainment.
- An **import gap** (the weekly pack did not arrive) freezes the domain's as-of; the sheet prints it; no signal is raised or lowered for that domain until data returns, and the tier hold rules (§8.3) treat a frozen domain as "no new observation".
- A **corrected fact** (pass 2 §2.9) re-runs the affected weeks; a signal whose inputs no longer hold is withdrawn (§13.7).
- A week with several graded assessments in one section contributes several attainment points; the second-assessment condition for level 2 (§3.5) counts them.

### 3.9 Term boundaries and seasonality

- The trailing window moves with the student, so a slow seasonal drift (absence rising from autumn to winter, as U.S. daily data show) drifts the band rather than crossing it.
- Weeks inside a declared `holiday`, `inset` or short week are null; the first week back is compared to the band, not to the last week before the break, and the CUSUM simply continues.
- The first `settling_weeks` (default 1) of an academic year cap attendance and engagement at weak, because registers and rosters settle in the first days.
- `exam_period`, `mock_period`, `reporting_window`, Ramadan and any `other` period the school declares act through suppression and softening (§6). What the calendar does not declare is not capped automatically: a week in which much of the school moved produces an operations count and a prompt to the school to declare the period (§7.6, F26).
- The CUSUM resets at the academic year start. The band does not, for the measures that carry over (attendance, behaviour, engagement, and attainment within a two-year course), so a Grade 11 student's first weeks of Grade 12 are judged against their own Grade 11 record, which is the point.

### 3.10 Sections, subjects and inheritance

Academic series are keyed by `sis.section_id`. A new section is a new series, with two exceptions that **inherit** the previous section's baseline and set `features.inherited_from`:

- **A set change** within the same `sis.subject.canonical_key` at the same level and scale: `H` capped at 8, and the file prints "band inherited from Mathematics set 2".
- **The second year of a two-year course** (F25): the new year's section of the same subject, level and scale (IB Diploma subjects, A levels, and any course the school marks two-year in the subject catalogue) continues the first year's series with its full history, and the file prints "band carried from Mathematics AA HL, year 1". Without this every academic baseline started again each August, and with sparse grading most sections never reached a band before the second semester.

A change of subject, level (SL to HL) or scale starts cold (§5); inheriting across a level change is configurable and off by default, because a drop after moving up is expected and a counselor should decide whether it is a concern. A section change is itself a suppression input for the week it happens (§6).

---

## 4. The domains

For each domain: the tables it reads, the measures it derives, their cadence under each delivery mode pass 2 defined, the rules beyond the shared detectors, and what the evidence sentence says.

### 4.1 Academic

**Reads.** `sis.assessment` (kind, occurred_on, max_score, weight, due date), `sis.grade` (kind `achieved`, `value_numeric`, `scale_key`, `missing`), `sis.section`, `sis.section_membership`, `sis.subject` (canonical key, level, whether the course runs two years), through `sis.v_current_grade`. Never `predicted` (a judgement, pass 2) and never `normalised_pct`.

**Measures.** Register, unit and window per measure are also carried in the thresholds schema (§10.1, F68).

| Measure key | Point | `n_min` | `dir` | Notes |
|---|---|---|---|---|
| `academic.<section>.attainment` | one point per graded assessment of kind `assessment`, `coursework` or `homework`: `score / max_score × 100` on a percentage scale, the grade's rank on an ordinal scale, placed in the week it was graded | 1 assessment | −1 | one series per section, carried across a two-year course (§3.10); history counted in assessments (F25) |
| `academic.<section>.mock` | one point per graded `mock` or `exam` | 1 | −1 | judged against the same section's attainment band, which is the student's own, and never added to its baseline or its CUSUM: band and shock only, a strong shock moderate. So a mock dip feeds a level (F31) and is suppressed inside a declared `mock_period` (§6) |
| `academic.submission` | per school week, across sections: share of assessments due that week submitted or graded by the due date, from `missing = false` and Classroom submission states (pass 2 §7.6) | 3 due | −1 | school-wide per student; the prototype's "coursework submitted (rolling %)" |
| `academic.missing` | count of `missing = true` in the fortnight block (non-overlapping, F25) | | +1 | shock statistic for the submission series; "two Mathematics deadlines missed" |
| `academic.<section>.working` | one point per reporting window: the `working` grade | 1 | −1 | used only in the retrospective mode (§4.8) |

**Rules beyond §3.4.** Within-domain breadth (weak in three or more sections within three weeks → moderate, §3.5). The second-assessment condition for level 2. `academic.missing ≥ 2` in a block with the submission series below its band is moderate for the domain even if the rate's CUSUM has not crossed, because two missed deadlines in a fortnight against a clean record is the observation the counselor would act on.

**Cadence.** Weekly pack: a point on each graded date. Nightly connector: the same, with a provisional current week. Termly file with dated per-assignment rows: the weekly engine run over the term as a backfill, capped at `review` (§4.8). Termly file with term grades only: `working` in the retrospective mode (§4.8).

**Evidence sentence** (deterministic template, numbers from `inputs`): "Mathematics AA HL: 41% on 12 Nov, 49 points below his own median of 90.5% in this course (20 assessments, carried from year 1); his second result in a row outside his band." The template prints the history it used, never more than exists (F78: the first version's "14 weeks of history" by 12 November was impossible with per-year windows). It never says "F", "failing" or any letter the scale does not carry.

**What it never does.** Compare a student's grade with the class mean; convert scales; read predicted grades as observations; treat a missing assignment as a zero score.

### 4.2 Attendance

Rewritten by pass 8 (F05, C9, F25, F68). Attendance is counted in **days** from the school's **master (daily) register**, in non-overlapping **fortnight blocks** of ten school days, because students miss whole days: a per-session rate treated each lesson as an independent chance to be absent, and one uncoded sick day came out at about 6.7 scale units, a strong shock (the pass 7 review's computation, F05).

**Reads.** `sis.attendance_event` through `sis.v_current_attendance`: the master register's whole-day rows (`timetable_period_id IS NULL`; a half-day `session_key` such as `AM` or `PM` counts as half a day), with `code`, `authorised`, `reason_code`, `minutes_late`; `config.vocabulary 'absence_reason'` attributes (`counts_as`, `suppresses`), with their versions (F48); `sis.school_day`. The per-period (class) register, which pass 2's weekly pack carries beside the master register, is read for one thing only: a late mark in the first registration period of the day where the master register records no lateness. It never feeds the day counts.

**Measures.**

| Measure key | Point | Register · unit · window | `n_min` | `dir` | Role |
|---|---|---|---|---|---|
| `attendance.days_missed` | registered school days not attended (present, late and remote count as attended) | master · days · fortnight block | 5 registered days | +1 | the shared detectors (§3.4); `s_floor` from the day-level model (§3.3); floor 1.5 days |
| `attendance.late_days` | days with a late arrival: master code `late` or `minutes_late > 0`, else a late mark in the first registration period | master (class register fallback) · days · fortnight block | 5 | +1 | the lateness rule only; the one lateness measure (F68: the first version's two lateness measures could be the same series) |
| `attendance.unexplained_days` | days missed with `authorised` false or NULL | master · days · fortnight block | 5 | +1 | the unexplained-absence rule only |
| `attendance.rate_ytd` | 100 × days attended / days registered since the first school day of the academic year | master · percent of days · year to date | 20 days | −1 | the policy floor only |

In every measure, days whose absence reason has `counts_as = 'excluded'` and days covered by a reason that suppresses `attendance` leave the registered days and the missed days alike (§6).

**Rules beyond §3.4.**

- *Held at weak* (F05). Until the school's **reason-code coverage** has been measured, the attendance domain's level is at most weak (`attendance.max_level = 1`). Coverage is the share of absent days in the imported history that carry a reason code; the release is a new configuration version, activated by the caseload lead, whose note cites the measured coverage and the bar it was held to (default bar 90%, to be agreed with ACS: question 157). The reason: an uncoded medical day counts as missed and unexplained, and how absences are coded drifts over the year (AEI, §2.1). While held, attendance still contributes breadth at weak, draws its cells on the run and opens `monitor` cases; it cannot make a domain moderate or strong.
- *Lateness.* Fires when `late_days ≥ att` in a block (the school's tolerance, default 3, range 1 to 6; the prototype's `att` is "lates within a 10-school-day window", which is exactly one block) **and** `late_days ≥ p90_personal + 1`, where `p90_personal` is the 90th percentile of the student's own block counts across the baseline window. Weak at the threshold; moderate at `att + 2` or when it fires in two consecutive blocks. Both conditions are required: the first is the school's tolerance, the second the personal deviation; a student whose normal is four late days a fortnight does not fire at three.
- *Unexplained absence.* `unexplained_days ≥ 2` in a block and `≥ p90_personal + 1`: weak; `≥ 4`: moderate. An unexplained absence that a later import re-codes as authorised withdraws the signal (§13.7).
- *Policy floor.* `attendance.rate_ytd < chronic_threshold` (default 90%, the chronic-absence convention; the school sets it under its regulator's attendance policy) after at least four weeks of the year raises rule `attendance_policy_floor` at **review at most, once per term**, and not while the improving guard holds. The convention is a share of the school year (Balfanz and Byrnes 2012), so the rule reads the year to date; the first version read a trailing four weeks, which turns one two-day illness and one more absence into a "chronic absence" flag. It is the only level rule in the domain and it is a school policy, not a comparison. Being a rule rather than a level, it is not held at weak.

**Cadence.** Weekly pack: a block closes with the pack that completes its second week, and the detectors and rules run then; "within two school days" starts at that commit (pass 2 §6.3). The first week of a block is provisional and counts only for the shock rule. Nightly connector: the same, nightly. Termly file with per-day rows: the weekly engine over the term as a backfill capped at `review` (§4.8). Termly aggregates only: retrospective (§4.8).

**Evidence sentences.** "Missed 2 days in the fortnight of 9 to 20 Nov against her usual none (20 weeks); outside her band for the first time since October." "Three late arrivals in the fortnight of 9 to 20 Nov; her own record is none or one a fortnight."

### 4.3 Engagement

**Position.** CONTEXT.md §11.8 names this domain self-referential and privacy-sensitive; pass 1 left the source and retention open (open decision 10) and pass 2 made Google Classroom a connector pass 4 must approve. This pass designs the domain and ships it **disabled by default** (`engine.thresholds.domains.engagement.enabled = false`), to be enabled per school after pass 4's rule and the school's disclosure. Disabling is the guarded kind (§10.3): the sheet says the domain is off.

**Reads.** `engagement.activity_event` (`source`, `kind`, `occurred_at`) for sources `caros` and `google_classroom` only; open items from `uni.*` (nudges, document requests, statement versions), `ib.*` checkpoints, `discovery.*` tasks, to establish expected activity. It reads only `engagement.activity_event.occurred_on`, a date the ingest writer sets in the tenant's own timezone (pass 4 D56), never a time. It never reads content, and the "after 01:00" measure of the prototype is not built (§0.2).

**Measures.**

| Measure key | Point | Valid only when | `dir` |
|---|---|---|---|
| `engagement.active_days` | days in the week with at least one activity event | the student has **expected activity** that week | −1 |
| `engagement.silence_days` | days since the last activity event, at as-of | expected activity | +1 |
| `engagement.tasks_abandoned` | `task_abandoned` events in the trailing 14 days | | evidence text only |

**Expected activity** is what keeps silence from meaning nothing: at least one of an open nudge or task, a document request in progress, a statement version in the last 60 days, a CAS or Extended Essay checkpoint due within 21 days, or an application window open for the student's year group and destination systems. A Grade 9 student with nothing pending has a null series, and the file says "no activity expected". The engine records the reason as a suppression check.

**Rules.** `silence_days ≥ eng` (default 14, range 5 to 28) **and** `silence_days > 2 × personal median gap` (the median of this student's own inter-event gaps over the baseline window) **and** expected activity: weak; at `2 × eng`: moderate. Layla's 21 days against a median gap of about two days with a UCAT booking pending is moderate here and, with the stalled statement (§4.6), breadth two.

**Cadence.** Live from CAROS; nightly from Classroom. Never termly.

### 4.4 Behaviour

**Reads.** `sis.behaviour_event` (`occurred_at`, `category_key`, `points`, `severity`) through `sis.v_current_behaviour`; `config.vocabulary 'behaviour_category'` attributes (`polarity`, `severity_default`, `points_sign`, and this pass adds `serious: boolean`).

**Measures.** `behaviour.points_week`: the school week's sum of negative points (or the count of negative incidents where the school records no points); register: the SIS conduct log; unit: points; window: one school week; `dir +1`, `s_floor` Poisson at the student's own mean (§3.3), `floor` 3 points **per week**. Revised by pass 8 (F68): the first version put a fortnightly floor and a trailing two-week shock statistic on a weekly series; the shock is now the weekly point against the weekly band, like every other measure. Positive-polarity records are not a series; they are positive evidence (§4.7).

**Rules beyond §3.4.** A **serious incident** (`serious = true` or `severity ≥ 3`: suspension, exclusion, a safeguarding-tagged category) raises rule `behaviour_serious_incident` immediately at the level the school configures (default moderate; a school may set exclusion to urgent), no baseline required. The engine never reads `description`.

**Cadence.** Weekly pack; nightly connector; termly retrospective.

**Evidence sentence.** "Seven conduct points this week, after four last week; his own record over 20 weeks is none or one a week."

### 4.5 Teacher concern

**Reads.** `signal.teacher_flag` of kinds `concern`, `note` and `positive` (tags, author, lesson_at, status), `config.vocabulary 'flag_tag'` with attributes this pass adds: `severity` (1 to 3) and `safeguarding_relevant` (boolean). The attribute values a rule used, and the vocabulary row's version, are snapshotted into `evaluation.rule_hits` and the evidence item, so a past level stays explainable after the school edits a tag (F48; pass 1 `config.vocabulary_history`).

**A safeguarding flag is not an engine input** (F10, pass 1 C23). A flag of kind `safeguarding` is a teacher's referral: `signal.raise_teacher_referral()` sends it to the school's safeguarding route as an escalation and opens a case if none is open. The engine never reads its tags or text and never turns it into a level, so a disclosure never waits in a weekly review. It sees only the consequence: the student's case carries an unreleased escalation, which pins the tier (§8.2). The flag form tells every teacher, above the fields, that a disclosure is reported to the school's safeguarding lead now and that an ordinary concern is not a safeguarding report (pass 1 §2.9), and concern text is read by the lexicon safety screen (pass 4 §5.7), not by the engine.

**Default tag attributes** (seeded from `FLAG_KINDS`, `index.html:3557`; the school edits them): Distressed or upset (3, relevant); Conflict with peers (2, relevant); Left lesson early (2, not); Withdrawn / quiet (2, not); Sudden drop in work (2, not); Appears tired (1, not); Missing homework (1, not); Disengaged in class (1, not).

**Level.** Concerns are events, not a series. Within a window of `corroboration_window` school days (default 7, range 3 to 10):

| Condition | Domain level |
|---|---|
| one concern, all tags severity ≤ 2 | weak |
| one concern with a severity-3 tag | moderate |
| two concerns from **independent** authors (distinct `author_person_id`) | strong |
| `corroboration_staff` (default 2) independent authors with any `safeguarding_relevant` tag, or three independent authors | strong, and the tiering table's **urgent** row (§8.1) |

A concern with status `reviewed` still counts for its window (the counselor saw it and chose not to attach; it is still an observation). A concern the counselor `dismissed` does not. Free text is never parsed for level, and no model summarises it for the headline: the headline is the rule's template alone (F52). A `note` flag acts through suppression or information (§6); a `positive` flag is positive evidence (§4.7).

**Immediacy.** Every new concern triggers an event evaluation of that student (§7.5), so the enriched card the prototype promises the teacher ("the engine attached his maths decline and punctuality drop within seconds") is true within minutes.

**Evidence sentence.** The concern's tags and author, its date and lesson: "Concern from Ms. Bianchi (Physics, P2, 20 Nov): left lesson early; withdrawn / quiet." The body is shown as the teacher wrote it, quoted, never paraphrased in the evidence item.

### 4.6 University progress

This domain is rules, not deviation. Pass 1's rule sets (`uni.list_balance`, `uni.reference_sla`, `uni.nudges`) and the application pack view compute the facts; the engine turns each fact into a signal with a fixed level so it can enter combination and tiering.

| Rule key | Fires when | Level | Default tier on its own |
|---|---|---|---|
| `list_balance` | no `safety` target with the earliest deadline within `T_balance` days (default 21) | moderate | review |
| `reference_sla` | a reference outstanding at `T_ref` days (default 14) to its deadline; strong at `deadline_critical_days` | moderate; strong at 10 days | review; checkin |
| `document_chase` | any document request `chased` twice with no response | moderate | review |
| `application_stall` | no new statement version and no document movement for 14 days with a deadline within 45 days | moderate | review |
| `deadline_critical` | any dated obligation in `uni.*` (an application deadline with the pack not ready per `uni.v_application_pack`, a test booking window, a document due) within `deadline_critical_days` (default 10, the prototype's `dimDeadline` cut) and not satisfied | strong | checkin |
| `post_offer_decay` | a conditional offer exists **and** `academic.submission` is level ≥ 2 (or an attainment series named in the offer's `required_subjects` is level ≥ 2) since the offer date | strong | checkin |
| `list_fit` | a `reach` target's requirement is one grade above the latest `predicted` grade in a named subject | weak | monitor |
| `predicted_vs_working` | the latest `working` grade in a section is one or more steps below the latest `predicted` grade in the same scale | weak | monitor (evidence for the letter engine and the parent's transcript page, not a wellbeing signal) |
| `offer_condition_check` | final results are imported (`sis.grade` kind `final`) for a student holding a conditional offer they have accepted, and the results do not meet the offer's `conditions_structured` (the overall grades, or a required subject's minimum); added by pass 8 (F64) | strong | checkin, on the calendar-day clock below |

The prototype's "application completeness" series is the pack view over time; `application_stall` is its zero-slope detector. Nothing here compares students, and nothing here uses an admission probability (removed by pass 1, replaced by pass 5).

**Results day and the summer clock** (F64). IB and A-level results arrive in July and August, when there are no school days, and Confirmation and Clearing move in days. So for the university rules, and only for them, the SLA clock of a case they raise runs in **calendar days** on any day that falls outside every one of the school's terms (`sis.term`, pass 1 §2.5), and in school days (`sis.add_school_days`) in term; the case prints which clock it is on ("results period: calendar days"). `offer_condition_check` runs when the final-results import commits, as an event evaluation (§7.5), and a met condition is positive evidence. Nothing in pass 1's calendar needs a new kind for this, such as a results period: the rule reads the term dates that already exist. Who at the school acts on a results-day check-in over the summer is a question for ACS (question 160).

### 4.7 Positive change, recovery and relapse

**Positive evidence** items come from: a favourable-outside point on any measure (an attainment result above its band), a `positive` teacher flag, a positive-polarity behaviour record, a completed mentor session, a document or statement milestone, a met offer condition on results day. They render in the evidence chain with polarity `positive` and level 1 to 3 (a teacher's "recovered after support" is 2; a favourable point is 1). They do not subtract from anything.

**Recovery** (C20) is detected on the **triggering measures** of an open case, `Q* = { q : a signal on q is attached to the case with status open }`; for a case a person opened (C2) with no engine signal, `Q*` is the set of measures at level ≥ 1 in the week it was opened, or the measures the counselor ticked when opening it, and the file shows which. Revised by pass 8 (F05): recovery reads **levels and the mean since the case opened**, never the CUSUM's memory. Every `q` in `Q*` must have been at level 0 for `recovery_weeks` consecutive weeks of data (default 3, range 2 to 6), and the mean adverse deviation `d` of its points since the case opened (against the baseline it had then, §3.2) must be below `floor(q)`. The first version also required `S = 0`; a single outlier's sum took about twelve graded weeks to drain, so the fifth tier almost never fired (F05). The second condition keeps a student who was badly off from being called recovered after a short quiet run. Then:

- if the case is at stage `act`, `follow` or `measure`: tier `good`, `moved_why` "third consecutive week inside her band on the measure that opened the case"; the counselor acknowledges and closes (C18) with `monitoring_until = closed_at + monitoring_days` (90).
- if the case is still at `triage` (never accepted): the engine closes it with outcome `resolved` and note `self_recovered`; it is recorded for tuning, because a case that recovers before anyone acts is either a false alarm or a check-in that never happened, and the counselor's judgement decides which.
- if the case carries an unreleased escalation, neither happens: recovery is written to the file as evidence, and the tier stays where the person who owns the pin leaves it (§8.2, F07).

**Relapse** (C19): a case closed by a person with an outcome (C18), inside its `monitoring_until`, whose triggering measures include one that reaches level ≥ 2 again opens a new case with `relapse_of_case_id`, and the tiering table treats relapse as **one tier above** what the fresh evidence alone would give, with a minimum of `checkin`: fresh evidence of one moderate domain (`review`) becomes `checkin`, and of two moderate domains (`checkin`) becomes `urgent`. Cases that were dismissed (C11) or closed by auto-review (C21) carry no monitoring window and never relapse. The analogy is with the clinical finding that prior episodes are among the strongest predictors of recurrence (Burcusa and Iacono 2007, for depression); it is an analogy and is labelled as such in the rule's description, and the counselors can set the uplift to zero (§10). The relapse case's evidence chain includes the closed case's outcome and the intervention that was tried, as `case_history` items.

Two limits, both added by pass 8. **While attendance is held at weak** (§4.2), an attendance-only relapse cannot reach level 2; a weak level on a closed case's triggering measure inside its window opens a `monitor` case under rule `relapse_watch` that prints the closed case beside it, so the counselor sees the history without the engine claiming more than the held domain allows. Whether the relapse rule should fire at weak during the hold is open decision 21. **Termly data** (F31): when every piece of fresh evidence for a relapse comes from termly-delivered data (§4.8), the cadence cap of `review` wins over relapse's minimum of `checkin`, and the case prints "relapse, on termly data: capped at review"; a relapse whose fresh evidence includes a live domain (a teacher concern, a university rule) keeps its minimum.

### 4.8 Cadence modes per domain

Pass 2 §6.3 defined the modes; this is what the engine does in each. Revised by pass 8 (F25): a termly file that carries dated rows is no longer thrown away into term aggregates.

| Delivery | Academic | Attendance | Behaviour | Teacher | Engagement | University |
|---|---|---|---|---|---|---|
| Nightly connector | a point per graded assessment; nightly evaluation | fortnight blocks in days, the current block provisional | nightly | live | live / nightly | live |
| **Weekly pack** (the pilot's design point) | points on graded dates; **backfill evaluation** at commit (§13.5) | a block closes with the pack that completes its second week | weekly | live | live | live |
| Fortnightly pack | each week in the file is its own week of data, so one fortnightly file advances persistence by two | one block per file | as weekly | live | live | live |
| **Termly, with dated rows** (per-assignment grades, per-day register) | **termly backfill**: the weekly engine run week by week over the term (§13.5), every resulting tier capped at `review` (`engine.tiering.termly_backfill_cap`) | the same backfill over the term's blocks | the same | live | live | live |
| Termly, term aggregates only | **retrospective**: `academic.<section>.working` per reporting window | retrospective: the term's days missed | retrospective: the term's points | live | live | live |

**Termly backfill.** The file lands, `sweep.backfill` evaluates each affected student as of the end of each school week the term covers, in order, exactly as for a weekly pack (§13.5), and only the final week opens, attaches or moves cases, with the tier capped at `review` because a two-day promise on term-old data would be false. The evidence names the export ("from the Semester 1 export, as of 12 January"). Pass 2 describes the delivery and refers here.

**Retrospective rules** (`retro.academic`, `retro.attendance`, `retro.behaviour`), for files that carry only term aggregates. Revised by pass 8 (F25), because the first version compared a term with at least two prior terms "in the same section", which with semesters could never fire, and with quarters put a one-step drop against two equal prior terms at `z = 2`: 38 to 55 of 87 quiet students would have had a termly `review` on the third quarter's export day (the pass 7 review's computation).

- *Academic.* The current term's `working` grade in a subject against the student's own prior terms **in the same subject** (carried across sections, and across the two years of a two-year course), with at least three prior terms; the pilot's history import brings last year's term grades so that this exists from the first term. For working grades a drop fires only when it is **two steps or more** on an ordinal scale (two floors on a percentage scale), or a drop of at least one step (one floor) **held across two consecutive reporting windows**.
- *Attendance and behaviour.* The term's days missed, or points, against the student's own prior terms (at least three), with the floor scaled to the term's length (1.5 days per fortnight block in it) and `z ≥ 2` on the prior terms' scale with its floor.
- In every case: level moderate at most, **tier cap `review`** (`engine.tiering.retrospective_cap`), the evidence sentence names the export, and recovery is the next term back inside.

**The screen says which domains are still building a baseline** (F25). For every student and domain the sheet's run header and the case file print one of: the as-of date; "termly: as of the Semester 1 export"; or "building a baseline: 5 of 8 assessments" (or weeks, or blocks), with the self-starting phase marked. A domain that says nothing is never silently inert. `ingest.expected_cadence` selects the mode per import kind; a school that moves from termly to weekly changes modes without a deploy.

---
## 5. Cold start

Grade 9 entrants, mid-year transfers and new sections have no personal history. The rule is that the engine **never substitutes another student's history for the missing one**. What it does instead, in order of how much history exists:

**No history (`H = 0`).** Everything that needs no baseline still runs: teacher concerns and corroboration (§4.5), serious behaviour incidents (§4.4), the university rules (§4.6), the attendance policy floor (§4.2) and lateness at the school's tolerance (`late_days ≥ att` in a block, without the personal condition). The sheet shows `none` cells; the file says "building a baseline: 0 of 8 weeks" (assessments for attainment, blocks for attendance) and lists what is being watched meanwhile. The case, if one opens, prints `cold_start = true` and the tier is capped at `review` unless a teacher-concern or serious-incident rule says otherwise.

**Self-starting phase (`3 ≤ H < min_history_band`).** From the third valid point, the engine runs in **self-starting** form (Hawkins 1987; Quesenberry 1991 for the short-run principle): the running median and MADn of the points so far, floored, stand in for the baseline, the scale is widened by `sqrt(1 + 1/H)` for its own uncertainty, and only the strong shock (`z ≥ 5` with `d ≥ 2·floor`) may produce a level above weak, and then only moderate. The noise rises as history shortens (at eight points of history the moderate noise is about four times that at twenty, §3.6), which is why the phase is capped; a genuine collapse in a new student's first weeks still surfaces, at `monitor` or through the strong shock at `review`, with the evidence.

**Full (`H ≥ min_history_band`).** The band is drawn, the run is real, and the ladder of §3.5 applies, with the scale widened by `sqrt(1 + 1/H)` until the window fills. Revised by pass 8 (F25): the first version held a "band phase" capped at weak until twelve points, which with sparse grading left most academic sections inert until late in the year; the widened scale with floors at the full typical noise replaces the cap (§3.2, §3.6). The file says "baseline from 9 assessments: settling" until the window fills.

**Bringing history in.** Revised by pass 8 (F06, F24, F25). Before shadow starts, the pilot imports **at least twenty weeks** of each student's own history, in practice the previous school year's per-day master-register attendance and per-assessment grades, through the normal import path as one backfill (pass 2; the ACS fixture carries the same kind of history, so the seed test and the pilot exercise one path). Grades 10 to 12 are then warm on the first shadow sweep for attendance and behaviour, and for every academic subject that continues into a second year of a two-year course (§3.10), which the first version claimed but its own per-section reset prevented (F25). Two further imports are questions for ACS (pass 2 question 83; question 99): two academic years of history; and, for Grade 9 entrants who came up from the same SIS, the middle-school attendance and behaviour rows, which are the student's own history and are used as such (academic sections are new regardless). A transfer from another school brings nothing, and the engine says so.

**The settling-in review.** When a cold-start student reaches `min_history_band`, the engine writes a `monitor` case with rule `baseline_established` and `auto_review_on` two weeks out, whose evidence is the band itself ("attendance 91 to 100%, attainment in five sections"). It asks for nothing; it exists so the counselor can look at a new student's first two months once, on purpose, rather than never.

**Why not a prior from the year group.** The temptation is real: with no history, "students like this one usually attend 96%" is informative. It is also exactly the comparison invariant 2 forbids, it would make the first case a new student ever gets a comparison with their peers, and it is the mechanism by which cohort bias enters a personal engine. The only priors the engine has are the school's tolerances, which are policy.

---

## 6. Contextual suppression

Suppression is per **(student, domain, week)**, and it acts in two places: a suppressed week leaves the baseline window (so the exam-week dip does not pollute the band) and leaves the detectors (the CUSUM holds, the run cell shows `none` with a hatch mark that the file explains). A signal whose evidence lies entirely within suppressed weeks is not raised; one with evidence outside them is raised with the suppression printed beside it. Every check is recorded on the evaluation, fired or not, which is what the prototype's context list ("No authorised medical absence on file · Not an assessment or exam period · No subject change recorded this term") becomes.

### 6.1 Inputs

| Input | Table | What it says | Effect |
|---|---|---|---|
| Calendar periods | `sis.calendar_period` (`kind`, `affects_domains`, `year_group_ids`) | exam, mock, reporting window, holiday, inset, Ramadan and other periods, by year group | `suppress` or `soften` per `engine.suppression.calendar[kind]` |
| Absence reasons | `sis.attendance_event.reason_code` → `config.vocabulary 'absence_reason'.attributes.suppresses` | which domains a coded reason excuses (pass 2 §5.2: medical suppresses attendance and engagement; study leave suppresses academic and engagement) | suppress the named domains for the days covered, plus `after_days` |
| Excluded days | `attributes.counts_as = 'excluded'` | not a possible attendance | out of the denominator, never an absence |
| Enrolment and section changes | `sis.enrolment.status`, `sis.section_membership.started_on` | transfer in, section change, level change | academic suppressed for the change week; new series (§3.10) |
| Counselor context | `signal.case_context` (`context_key`, `valid_from`, `valid_to`) → `config.vocabulary 'context_kind'.attributes` | what the counselor knows that the data cannot see | per kind: `suppress`, `soften`, `inform` or `route` |
| Teacher context | `signal.teacher_flag` kind `note` with tags | authorised absence, was ill, extra support agreed, spoke with them already, family situation known | per tag: `suppress` (weaker, pending SIS confirmation), `inform` |
| School-wide common cause | withdrawn as an input (F26) | the first version capped every student's level at weak in a week when more than a quarter of the school was outside its band | **none**: no student's level reads other students' data (invariant 2). The count survives as an operations note and a prompt to declare a `calendar_period`, which then suppresses through the calendar row above (§7.6) |

### 6.2 The logic

For each check the engine evaluates a predicate over the student's facts and writes `{check, outcome, detail}` to `evaluation.suppressions`:

```
exam_period(d, t)       : a calendar period of kind exam_period or mock_period, active in week t, whose affects_domains contains d and whose year groups include the student's
soften_period(d, t)     : a period whose engine.suppression entry is 'soften' (Ramadan, other): floor(q) × soften_factor (default 1.5) for measures in d, and the level is capped at moderate
authorised_absence(t)   : any master-register day in week t whose reason suppresses attendance; the day leaves the registered and the missed days alike; a fortnight block left with fewer than five registered days is null for attendance; engagement is suppressed for the covered days plus after_days (default 2)
study_leave(t)          : a reason whose suppresses includes academic: the week is suppressed for academic and engagement
section_change(q, t)    : the section of measure q started in week t or t−1: suppressed for that series for two weeks
transfer_in(t)          : enrolment status transferred_in with joined_on inside the last settling_weeks: attendance and engagement capped at weak
counselor_context(d, t) : a case_context with effect 'suppress' whose validity covers week t and whose kind suppresses d
teacher_note(d, t)      : a note flag in week t whose tag suppresses d: suppresses at half weight, meaning the week is excluded from detectors but not from the baseline, until an SIS row confirms it
(common_cause withdrawn by pass 8, F26: no check reads other students; §7.6)
```

**Suppress versus soften versus inform.** Context that *explains* a deviation (an authorised absence, an exam, a subject change) suppresses. Context that *adds risk* (a family situation the counselor knows about) does **not** lower anything: it is recorded, it appears in the evidence chain as context, and it may route the case (to a pastoral colleague) but it never reduces the tier, because a known difficulty is a reason for more attention, not less. The prototype lets "Family circumstance noted: pastoral route" reduce the score; this plan does not, and it is listed in Challenges. Each `context_kind` carries its effect as data, so a school that disagrees can change it, visibly.

**Default `context_kind` rows** (platform, overridable): `authorised_absence_confirmed` (suppress attendance, engagement; 14 days), `assessment_context` (suppress academic for named assessments), `subject_change` (suppress the section's series; permanent), `known_medical_condition` (soften attendance; validity as entered), `family_circumstance_known` (inform), `support_in_place` (inform), `informal_contact_made` (inform; also sets last contact), `pastoral_route` (route: no tier change; owner may change).

**Re-evaluation on context.** Adding context queues an event evaluation of the student (C9); the tier that results is whatever the rules give under the suppression, which may be lower, and the tier history row references the re-evaluation so the downgrade is explainable ("attendance suppressed for 4 to 13 Nov: authorised medical absence confirmed by Ms. Haddad; the remaining evidence is one domain at moderate: review"). No arithmetic on a score.

**What suppression never does.** It never hides a teacher concern, a serious incident, a relapse, or a university deadline rule; those are not deviations to be explained. And it never suppresses across the whole school by itself: a school-wide suppression exists only when a person declares a calendar period, which is data about the school, never a computation over the students (§7.6, F26).

**Suppression is explainable later** (F48). Each check records the vocabulary attributes it read (for example `absence_reason.suppresses` for code `M`) and the vocabulary row's version, in `evaluation.suppressions` and in the evidence snapshot, so a change to a reason code's attributes next term does not rewrite why a past week was suppressed. A test asserts that every suppression check and every rule hit that read a vocabulary attribute carries its value and version (§15.1).

---

## 7. Combination, persistence and immediacy

### 7.1 Domain levels and breadth

At the end of §3 to §6 the engine holds, per student, per domain, a level `L[d] ∈ {0,1,2,3}`, a persistence `P[d]` (the maximum over its measures), an onset, and the evidence items. **Breadth** `B` is the number of distinct adverse domains (academic, attendance, engagement, behaviour, teacher) with `L[d] ≥ 1` whose evidence falls inside the **corroboration window** (`breadth.window_weeks`, default **2** school weeks ending at as-of, range 1 to 4; the first version reported that three weeks added noise without adding any authored case, a result from a script that was never published, so it is kept as the reason for the default and not as a finding; the published calibration runs at two weeks, §3.6). A fortnight block's evidence falls inside the window for the two weeks after it closes. The university domain contributes its own rules to the tier but not to breadth, because a deadline is not a change in the student. Two measures in one domain are not breadth (two subjects declining is one academic domain, printed with its own breadth); a teacher concern plus a series deviation is (§2.2).

### 7.2 The combination table

Combination is a lookup on `(max level M, breadth B, persistence, special rules)`, stored as the `engine.tiering` rule set, never a weighted sum. Every domain level in a condition is the level whose evidence falls inside the breadth window (§7.1); "L ≥ 1" means weak or higher, "M = 2" means the highest domain level is exactly moderate (F78). The default rows, in order of precedence (the first matching row wins):

| # | Condition | Proposed tier | Rule key on the signal |
|---|---|---|---|
| 1 | relapse (§4.7): fresh tier from the rows below, raised by `relapse_uplift` (default 1) with a minimum of `checkin`; the termly cap of row 14 wins when all fresh evidence is termly (F31) | as computed | `relapse` |
| 2 | teacher domain strong with a safeguarding-relevant tag, or three independent concerns in the window (flags of kind `concern`; a `safeguarding` flag is a referral to the route, not an input here, §4.5, F10) | urgent | `corroboration` |
| 3 | a school-defined urgent event (a behaviour category with `urgent = true`) | urgent | `behaviour_serious_incident` |
| 4 | `M = 3` in two or more domains | urgent | `baseline_deviation` |
| 5 | `M = 3` in one domain | checkin | `baseline_deviation` |
| 6 | two or more domains with `L ≥ 2`, at least one of them by a CUSUM signal held for `persist` weeks of data | checkin | `baseline_deviation` |
| 7 | teacher domain strong (two independent concerns) | checkin | `corroboration` |
| 8 | teacher domain moderate **and** another domain at moderate, or another domain at weak in each of the last two weeks (revised by pass 8, F68: the first version promoted a lone severity-3 concern on any weak measure, and about a fifth of quiet students show one in a given week, by the pass 7 review's computation; under the revised condition 5.86% of quiet students would promote it in a given week, computed, appendix section F) | checkin | `corroboration` |
| 9 | two or more domains with `L ≥ 1` in each of the last `persist_weak` consecutive weeks (default 3) | checkin | `combined_weak_signal` |
| 10 | `post_offer_decay`, `deadline_critical`, `reference_sla` inside `deadline_critical_days`, or `offer_condition_check` (§4.6) | checkin | the rule's key |
| 11 | `M = 2` (one domain at moderate, or more than one that did not meet row 6's persistence) | review | `baseline_deviation` |
| 12 | teacher domain weak or moderate, whatever else is weak (the first version said "alone", which left a teacher concern with a weak series between rows) | review | `teacher_concern` |
| 13 | any university rule at moderate | review | the rule's key |
| 14 | a signal from termly-delivered data (a termly backfill or the retrospective mode, §4.8): **a cap, applied after the first match**, so no tier above `review` rests only on term-old data | review (cap) | `retro.<domain>` or the rule's key |
| 15 | `M = 1` from anything more than one outside point: a single shock (`shock_opens_monitor`, default true); outside in two of the last three valid points; the CUSUM signal not yet persisted; a lateness or unexplained-days rule at weak; two or more domains at weak; `relapse_watch` (§4.7); cold-start signals; `list_fit`; `predicted_vs_working`; `baseline_established` | monitor | the rule's key |
| 15a | outside the band on one point only, nothing else | **no case**: a soft cell on the run and a line in the file's baseline tab ("one point outside the band; the engine is watching") | |
| 16 | recovery detected on an open case at `act`/`follow`/`measure` with no unreleased escalation | good | `recovery` |
| 17 | nothing | no proposal (a quiet row) | |

The prototype's nine rule keys (`baseline_deviation`, `engagement_decay`, `list_balance`, `list_fit`, `reference_sla`, `relapse`, `corroboration`, `post_offer_decay`, `combined_weak_signal`) all appear; `engagement_decay` is the engagement domain's silence rule (§4.3) and reaches tiers through rows 6, 8, 11 and 15. Every row is data: a school can move `combined_weak_signal` to review, or set `relapse_uplift` to 0.

**Reproducing the fifteen authored cases** under the pilot defaults (the `engine-reproduces-seed` test, §15.1). Re-traced by pass 8 (F05, F06). Three things changed underneath. The ACS fixture now imports the previous school year before the authored eight weeks, so every authored student has at least twenty in-band weeks of their own (pass 2 §8.1); the trace below assumes that history reproduces the median and spread of each case's authored in-band weeks. The authored attendance and punctuality series cannot come from a register as printed (a five-day week cannot produce 97% or 98%, and no register produces an "on-time percentage"), so they are **re-authored in days and late days**, keeping each story:

| Case | Prototype series (weekly %) | Re-authored per week, then per fortnight block |
|---|---|---|
| Ahmed, punctuality | 100, 100, 98, 100, 96, 88, 76, 70 | late days 0, 0, 0, 0, 0, 1, 1, 2; blocks 0, 0, 1, 3 |
| Priya, first-period punctuality | 100, 100, 98, 100, 96, 90, 84, 80 | late days 0, 0, 0, 0, 1, 1, 1, 2; blocks 0, 0, 2, 3 |
| Maryam, attendance | 97, 95, 88, 81, 79, 86, 94, 98 | days missed 0, 0, 1, 1, 1, 1, 0, 0; blocks 0, 2, 2, 0 |
| Hana, attendance | 76, 84, 95, 97, 96, 92, 86, 79 | days missed 1, 1, 0, 0, 0, 0, 1, 1; blocks 2, 0, 0, 2 (the first inside her closed case's window) |
| Tariq, attendance | 99, 98, 100, 97, 99, 96, 89, 84 | days missed 0, 0, 0, 0, 0, 0, 0.5, 1 (the two unexplained afternoons); blocks 0, 0, 0, 1.5 |
| Ivan, attendance | 96, 93, 88, 85, 90, 95, 97, 98 | days missed 0, 0, 1, 1, 1, 0, 0, 0; blocks 0, 2, 1, 0 |
| Layla, Zayd, Maya, Fahad, attendance | 96 to 100 throughout | no days missed |

And the expected results are **generated by running the rules** on the fixture, never written by hand (F06): the trace is what those rules give, computed with the appendix script's level function, and B2.16 diffs the engine against the generated list.

- *Ahmed* (`s1`): Mathematics 91, 93, 89, 92, 90, 88, 74, 41 against a median of 90.5 to 91 and `s` at the floor (4.1 with the widening). The 74 is a shock (`z = 4.15`), weak; the 41 is a strong shock (`z = 12.1`) on the point after an outside point: academic **strong**, with the capped sum at 5.23 (the first version's uncapped sum, with its lower floor, stood at 21.33 in its own worked example and would have taken a term to drain). Attendance: three late days in the last block against none before, the lateness rule at weak, held at weak. Mr. Davies' concern (withdrawn / quiet, disengaged in class, appears tired; highest severity 2): teacher weak. Row 5: **checkin**. The prototype has him `urgent`; under these rules urgent needs a second strong domain, which his re-authored lateness cannot supply. If the counselors want a strong domain with two corroborating weak ones to be urgent (the prototype's telling), that is one row they can add.
- *Layla* (`s2`): with engagement disabled, `application_stall` (statement unchanged 21 days) and `deadline_critical` (the UCAT window closes in 9 days): row 10, **checkin**. With engagement enabled, silence of 21 days against a median gap of two days adds a moderate domain. Matches.
- *Sara* (`s3`): `list_balance` at T−18, **review**. *Omar* (`s6`): `list_fit`, **monitor**. *Noor* (`s16`): `reference_sla` at T−11, **review**; **checkin** at T−10. All match.
- *Yousef* (`s4`): the Physics mock of 74% judged against his own attainment band (median 87): a shock (`z = 3.17`), weak, **monitor**. Matches; the mock now feeds a level instead of evidence text only (F31).
- *Tariq* (`s12`): three independent concerns in four school days, row 2, **urgent**. His conduct points, now a weekly series (0, 0, 1, 0, 0, 1, 4, 7), are strong by the eighth week as well (a shock at 4, `z = 5.5`, then a strong shock at 7, `z = 9.7`); his re-authored 1.5 unexplained days in the last block are inside his band (`z = 2.08`). Matches.
- *Hana* (`s13`): with episode exclusion her baseline is her normal, none missed, and `s` is the day-level floor (0.72 with the widening). The last block's two days are outside (`z = 2.77`): attendance **weak**, and held at weak in any case. The relapse rule needs level 2, so it does not fire; `relapse_watch` opens a **monitor** case with her closed October case beside it. The prototype has her `urgent`. Three more such fortnights would make her attendance moderate at the seventh block (P = 4 weeks of data) once attendance is released, and the relapse rule would then give `checkin` (engagement at moderate, if enabled, would make it `urgent`). She is the clearest cost of the detune (Challenge C11, open decision 21).
- *Priya* (`s14`): late days in blocks of 0, 0, 2, 3; the last block meets the lateness rule (3 ≥ `att`, above her own none), weak and held; Dr. Reid's comment (appears tired, severity 1), teacher weak. Row 12: **review**. The prototype has her `checkin`; row 9 would give it if both stay weak for three weeks. The night-activity measure is not built (§0.2).
- *Daniel* (`s15`): submission 95, 92, 96, 90, 94, 71, 48, 33 against a median of 94 and a binomial floor of about 12 points: the 48 is a shock and outside (`z = 3.78`), the 33 a strong shock (`z = 5.01`) on the point after an outside point: academic **strong**, row 5, **checkin**; `post_offer_decay` (row 10) matches as well and is recorded in the rule hits. The eighth point sits at the edge of the strong-shock threshold; if the generated history puts it just under, the week is a shock after an outside point (moderate), his two missed Mathematics deadlines make the domain moderate anyway, and row 10 gives the same **checkin**. Matches.
- *Maryam* (`s5`): her person-opened, accepted case is a CAROS-native row in the seed. Attendance blocks 0, 2, 2, 0: weak in the second and third, level 0 in the fourth. Recovery needs three weeks of data at level 0 and a mean since the case opened under 1.5 days; the fourth block is two weeks, so `good` arrives with the next block, **two weeks after** the seed's narrative. Under the first version's rule it would have waited for her sum (4.03 after the fourth block) to drain to zero, about eight more blocks (F05).
- *Ivan* (`s17`): attendance blocks 0, 2, 1, 0 (the third inside his band, `z = 1.38`) and attainment 84, 81, 78, 74, 77, 82, 85, 87 (never outside; the 74 is `z = 2.44`) on his person-opened, accepted case: level 0 on both for more than three weeks of data, mean since opening under the floors: **good**. Matches.
- *Zayd*, *Maya*, *Fahad*: steady series, nothing crosses: **no case**. The prototype shows them as `monitor` rows carrying positive evidence only; the engine opens nothing for positive evidence (row 17), which is the reading the first version also gave while counting them as matches.
- The 72 generated roster students: quiet rows, with the eleven `watch` students' single soft cells (row 15a).

Eight tiers match on the authored day (Layla, Sara, Yousef, Omar, Noor, Tariq, Daniel, Ivan). Maryam's matches two weeks later. Ahmed and Priya land one tier lower, Hana three tiers lower, and Zayd, Maya and Fahad get no case. The first version reported thirteen matches; that count rested on the old punctuality percentages, the uncapped sum and counting the three quiet rows as matches. The generated expected-result list is exactly this list, and a change to it is a reviewed change.

### 7.3 Persistence

One persistence, defined once (F06): `P` is the number of **consecutive weeks of data** at which a measure's CUSUM signal held (§3.4). `persist` (default **3**, range 1 to 6; decision C9 raised it from 2) is the `P` a measure needs to be moderate through the CUSUM, and `persist + 1` is part of strong. `persist_weak` (default 3, range 2 to 6) is the number of consecutive weeks two domains must both be at weak or higher before they combine (row 9). Persistence is counted in weeks of data, not calendar weeks and not nightly evaluations: a null point neither advances nor resets it (§3.8); a fortnight block advances it by two, and an attainment point by one assessment. The prototype's single `persist` slider (1 to 6, default 3, "consecutive weeks a weak signal must repeat before it escalates") maps to `persist_weak`, unchanged at 3; `persist` for moderate is the second setting (C8).

Persistence is what the "how long it has persisted" tile shows (the window from the CUSUM onset, §3.4) and what stops a fresh crossing from reaching a card. Computed for a quiet student with twenty points of history under the revised defaults (§3.6): the CUSUM signal holds in 0.39% of series-weeks, and held for three weeks in 0.11%. The first version quoted 2.5% and 0.65% for a two-week hold; the 0.65% came from its script's consecutive-weeks rule, not from the weeks-since-onset rule its text specified, under which a "hold" filtered almost nothing (2.79% against 2.78%, computed, F06).

### 7.4 Recovery

§4.7. The positive tier is reached only from an open case, only on the measures that opened it, only after `recovery_weeks` of data at level 0 with the mean since the case opened back under the floor (F05; the CUSUM's memory plays no part), never while a triggering domain still carries a level, and never on a case with an unreleased escalation (§8.2). Positive evidence from other domains is shown and changes nothing; the counselor may close on it by hand, with the reason recorded.

### 7.5 Should a teacher concern trigger evaluation immediately? Yes, and so should two other inputs

The overnight sweep is the ritual because the series change when data arrive, and data arrive nightly or weekly. Three inputs do not: a teacher concern, counselor context, and an enrolment change (a student leaves, a student joins). The argument for evaluating those on arrival rather than at 02:00:

- **The safeguarding pattern is a same-day pattern.** Tariq's third concern arrives on day four. Under a nightly-only design the corroboration rule fires the next morning; the referral the school's policy requires waits a school day for no reason but the batch. Ms. Bianchi's, Mr. Osei's and Ms. Iqbal's observations are already in the system.
- **The teacher's loop closes now or never.** The prototype tells a teacher "the engine attached his maths decline and punctuality drop within seconds" and the teacher page says "You will be told what happened with it". A concern that sits in a queue until 02:00 and is attached at 07:04 is a form the teacher filled in; a concern that comes back enriched within minutes is a conversation. The teacher-recognition evidence (§2.2) says teachers under-refer moderate and internalising cases; the cheapest thing the product can do about that is make the act of logging visibly worth it.
- **Counselor context is an action with an expected reaction.** The prototype recalculates on the spot (`data-ctxpick`), and pass 1 (C9) already links the re-evaluation to the context row. A counselor who adds "authorised medical absence confirmed" and sees nothing move until tomorrow will stop adding context.
- **The cost is one code path and one discipline.** The worker already runs `sweep.run`; an `event` run over one student reuses the pure function with last night's snapshots plus the new event. The discipline is the asymmetry below.

The argument against, and the design that answers it: daytime evaluation could turn the queue into a ticker and reintroduce the fatigue the nightly ritual avoids. So:

1. An event evaluation may **open, attach, or raise**; it may **lower** only in response to counselor context (C9), which is the counselor's own act, and never a case pinned by an unreleased escalation (§8.2). Everything else that would lower waits for the night and for hysteresis (§8.3). In shadow mode the same event runs evaluate the student's shadow case (§14.1).
2. "What changed overnight" is computed **only** by the nightly run against the last successful nightly run. Daytime changes appear in a separate, smaller list on the sheet, "since this morning", with the time and the cause ("11:07 · concern from Ms. Iqbal"), so the ritual stays a ritual.
3. Each daytime raise is written with `sweep_trigger = 'event'` and the triggering record's id in `rule_hits`, so the audit answers "why did this move at 11:07".
4. Event runs are rate-limited per student (one evaluation per five minutes; later events coalesce) and never run for a student whose tenant is in retrospective-only mode for every series domain, because there is nothing for them to read.

An import commit is the fourth candidate (pass 2 open decision 12). The recommendation: **yes for the scheduled weekly pack**, as the backfill evaluation (§13.5), because the pack's arrival *is* the ritual moment for a weekly school, and it should not wait until the following night; the sheet prints "updated 09:32 after this week's import" once, not a stream. **No for ad-hoc uploads and corrections** during the shadow period, unless the school's policy row says otherwise; corrections re-evaluate at night and withdraw signals as §13.7 describes.

### 7.6 The common-cause guard

**The automatic cap is withdrawn** (F26, decided 2026-09-24). The first version marked a week `common_cause` for a domain when more than `common_cause_share` (25%) of students with a band were outside it, and capped every student's level from that week at weak. That made a student's level depend on other students' data, which invariant 2 forbids and which the engine's own property test (a student's output does not change when every other student's data changes) would fail; it would also have capped a student in genuine decline in exactly the week the whole school was disrupted, and it was computed in `sweep.finalize`, after the cases it was meant to cap had been written.

What replaced it: **an operations count and a prompt, never an input.** After the run, `sweep.finalize` counts, per domain, the students outside their band that week. When the share passes the operations threshold (`ops.common_cause_alert_share`, default 25%, a setting of the alert and never of the engine), it writes `common_cause.detected` with the counts only ("attendance: 31% of students outside their band in the week of 16 Nov; is there an undeclared calendar event?") and prompts the `school_admin` to declare a `calendar_period`. A declared period is data about the school, not about peers: it suppresses through the calendar (§6) for every student alike, and a manual re-run (§13.5) applies it to the weeks already evaluated. `evaluateStudent` has no input that could carry the share, and the no-comparison property test stays strict (§15.1).

---

## 8. Tiers, their SLA meaning, and hysteresis

### 8.1 What each tier means, in engine terms

The tiers are invariant 1 and the engine does not touch their names, order or SLA text. What it fixes is the evidence each one requires and the promise each one makes:

| Tier | SLA (`PRIO`, `index.html:1301`) | Engine entry (from §7.2) | The promise | Exit |
|---|---|---|---|---|
| `urgent` | Route now under school policy | rows 1 to 4, and a person's escalation (C15, C23) | the counselor should refer, escalate or act **today**; the engine has found either independent human corroboration, a school-defined event, a relapse, or strong change in two domains; or a person has escalated | **never lowered or closed by the engine while an escalation on the case is unreleased** (§8.2, F07); if a person set it, not within `person_raised_hold_days`; otherwise by hysteresis |
| `checkin` | Within 2 school days | rows 5 to 10 | worth a conversation this week; the SLA clock starts at the sweep (or at the commit under weekly delivery, pass 2) and is computed with `sis.add_school_days`, except that a case raised by a university rule outside term runs on calendar days (§4.6, F64) | hysteresis |
| `review` | This week | rows 11 to 14 | worth a look; one domain has moved, or a deadline rule holds, or a teacher noticed something | hysteresis, or the counselor's dismissal |
| `monitor` | No action required | row 15 | the engine has seen something isolated and is watching; `auto_review_on` in `auto_review_days` (14) | auto-review (§8.4) |
| `good` | Acknowledge | row 16 | the measures that opened the case have held at level 0 for `recovery_weeks` of data, with their mean since the case opened back under the floor | the counselor closes; or relapse |

### 8.2 The movement rules

- The engine **raises** a tier as soon as an entry row matches (subject to the daytime asymmetry in §7.5).
- The engine **lowers** a tier only under hysteresis (§8.3).
- **The escalation pin** (F07; pass 1 C4, C10, C21 and the trigger `signal.case_escalation_pin`). While any escalation on the case is unreleased (open, or closed with no tier set by a person since its outcome, `escalation.tier_released_at IS NULL`), the engine may **raise** the tier and nothing else: it never lowers it and never closes the case, whether by hysteresis, auto-review (§8.4), self-recovery or recovery to `good` (§4.7). A disclosure-driven escalation often leaves no trace in grades or attendance, so without the pin the lowering conditions would hold vacuously after the person hold expired and auto-review would close the case as `not_a_concern` about six weeks later. After the outcome **a person sets the tier** (C10), which releases the pin; from that tier the engine's hysteresis resumes. Each night the pin holds back a proposal, `rule_hits` records `held_by_escalation_pin` with the proposal it held, so the file can say what the data alone would have done.
- **A second concern on an escalated case** (F07). One case per student is open at a time (pass 1's unique index), and a new concern never needs the case closed first. While the escalation is open, new information goes to it as an update (C24, `signal.escalation_update`); once it has closed, a new escalation on the same case is allowed and carries `previous_escalation_id` (C15); a teacher's new safeguarding flag follows the same path through `signal.raise_teacher_referral()` (C23). New teacher concerns and signals attach to the open case as evidence (C3), and the corroboration rows are evaluated and recorded even when the tier is already `urgent`.
- A **person's** change (C10) outranks the engine for `person_raised_hold_days` (default 14) in the direction they moved it: the engine does not lower a tier a person raised, and does not raise a tier a person lowered, within that period, **unless** a new domain contributes, a new teacher concern arrives, or a measure reaches strong. The exception exists so that a counselor's "not this week" does not become blindness to new evidence; the tier history row says which exception applied.
- A **dismissed** case (C11) gets a cool-down of `dismiss_cooldown_days` (14) during which the same rule on the same measures cannot reopen it; new domains or strong levels can. This is Ancker's within-patient repeat rule applied to a queue. A case with an unreleased escalation cannot be dismissed (pass 1 C11).
- A **merged** case (C12) carries its signals into the target, and only within one student: pass 1's trigger refuses a merge across students, whose cases are linked instead (C25), with nothing moved between their files. The source's tier history closes.
- **The rate limit applies to lowerings and to repeated reversals, never to a raise into `checkin` or `urgent`** (F08). The engine lowers a case at most once per 24 hours, and changes the direction of a case's tier (a lowering after a raise, or a raise after a lowering) at most twice in 7 days; a movement that would be a third reversal is held, `tier.held_by_hysteresis` is emitted, and the case is listed on the thresholds page as oscillating, which is a tuning signal about the thresholds, not about the student. A raise into `checkin` or `urgent` is never held, whatever the case did the day before: the first version held every engine change, so a Tuesday corroboration meeting the `urgent` row could wait behind Monday's raise to `review` (S19).

### 8.3 Hysteresis, precisely

A tier has an entry condition (its row in §7.2) and an **exit** condition that is deliberately weaker, so that a series hovering at the edge does not flip nightly. Revised by pass 8 (F05): exit reads **levels and the mean since the case opened**, never the CUSUM. The first version's exit was `S < h/2`, and after a single outlier (S3) the sum took about twelve graded weeks to fall that far.

```
exit(q)        ⇔  level(q) = 0 at every point in the last exit_weeks (default 2) weeks of data
                  and  mean( d[q,u] over the points u since the case opened ) < floor(q)
                       (d against the baseline the measure had when the case opened, §3.2)
exit(domain)   ⇔  every triggering measure in the domain satisfies exit(q)
lower(case)    ⇔  the case's current tier's entry row no longer matches
               and  exit(domain) has held for every triggering domain
               and  at least one new valid point has arrived for each triggering domain since the tier was set
               and  no person raised the tier within person_raised_hold_days
               and  the case carries no unreleased escalation (§8.2)
               and  no engine lowering of this case in the last 24 hours, and the lowering is not a third reversal in 7 days
```

When `lower` holds, the new tier is the highest row that still matches (not necessarily one step down), or `monitor` if none does, from where auto-review closes it (§8.4); `moved_why` names the exit ("attendance has been at level 0 for two weeks and her mean since the case opened is back under the floor; the case rests on engagement alone: review"). A **withdrawn** signal (§13.7) bypasses the exit-weeks condition, because the evidence was wrong, not weak. Because the chart restarts when the case opens (§3.4), a decline that continues after opening builds a fresh sum and can still raise the case; noise that has stopped does not hold it up.

Under weekly delivery "the last two weeks of data" are two packs (or one fortnight block for attendance), so a tier set on Monday cannot be lowered by the engine before the pack two Mondays later. That is the intended pace: a counselor who acted on a check-in should not find it gone before the follow-up.

### 8.4 Auto-review of `monitor`

At `auto_review_on` the engine re-evaluates: if every measure has been level 0 for the last two weeks of data, it closes the case as `not_a_concern` with note `auto_review_quiet` (C21); if anything is still weak, it sets the next review two weeks out; after three quiet-or-weak reviews (about six weeks) it closes regardless, because a monitor case that never escalates is noise the sheet should stop carrying. **Auto-review never closes a case with an unreleased escalation, or inside an escalation's 90-day `ESC` window** (pass 1 C21, F07; scenario S24). A monitor case never counts against the counselor's precision.

---

## 9. Every number the prototype displays

CONTEXT.md §11.4 and pass 1 open decision 17: define or remove. The rule applied: a number ships only if a counselor can be told, in one sentence, what was measured to produce it.

| Prototype shows | Decision | Definition or replacement |
|---|---|---|
| **Signal strength 0 to 100** (`signal`, the meter, "Signal strength 86%") | **Removed** | The header prints the **evidence level**, the word the prototype already prints: *Weak* (max level 1), *Moderate* (2), *Strong* (3), computed per §3.5 and §7.1, with the tooltip "the strongest movement in any domain against this student's own band". `evaluation.strength` and `strength_definition` are dropped; `evaluation.level smallint` replaces them (§17) |
| **Confidence 86%** | **Removed** | No calibrated probability exists. After a shadow period and a backtest, the thresholds page may show a **per-rule acceptance rate** from the tuning log ("cases opened by this rule were accepted 7 of 10 times last term"), sourced to `events.event`, never on a case card. Until then the audit line reads "corroboration rule · 3 domains" |
| **3.1σ** | **Kept, defined** | `z[q,t]` of the triggering week: the deviation from the student's own median in units of the student's own robust scale (MADn of the trailing window, floored, §3.3). Printed as "3.1 σ below his own median (20 weeks)". Not printed below `min_history_band`. The thresholds slider that read "standard deviations below personal mean" now reads "robust deviations below the student's own median" |
| **Signed evidence weights** (`w`, positive adverse, negative positive) | **Removed** | Each evidence item carries `level` (1 to 3) and `polarity` (`adverse` / `positive` / `context`). The cohort matrix (`si-why`) colours a cell by the **domain level** and prints the level word in the tooltip; the summed-weight colouring at 30 and 18 goes |
| **Severity High / Medium / Low** | **Removed** | The third header tile becomes **breadth**: "3 domains corroborate" (the number of adverse domains with a level in the window), with the domain names |
| **Window "14 days"** | **Kept, defined** | School days from the CUSUM onset week to as-of for series signals; for teacher-driven cases, the span of the concerns; for university rules, days to the deadline |
| **"Corroborated: 3 domains"** (`vIntel`) | Kept | Breadth, as above |
| **`prev` → `prio` movement** | Kept | `tier_yesterday` from the last successful nightly run (§13.6) |
| **Thresholds page "false-positive rate 14%"** | **Replaced** | The what-if run (§10.4): "with these settings, the last 12 weeks would have produced 4 urgent, 11 check-in, 23 review, 61 monitor cases" |
| **`METRICS` targets** | Untouched by this pass | They compute from `events.event` (pass 1) once there is anything to compute |
| **Dimension statuses** (`critical` / `watch` / `good`) | **Defined** | `dimensions` rule set: `si-attendance`, `si-punctuality`, `si-academic`, `si-engagement`, `si-behaviour` are `critical` at domain level ≥ 2 or a fired policy rule, `watch` at level 1, `good` otherwise, each with the note template ("2 results outside band"); the five application dimensions keep the prototype's logic as parameters (`deadline_critical_days: 10`, `docs_critical_outstanding: 3`, `progress_watch_below: 80`, `progress_critical_below: 40`), except personal statements: revised by pass 8 (F32), `si-statements` is `watch` while any current statement version is incomplete by `uni.statement_complete()` (pass 1 §2.11: every section at or above its minimum and the total within the destination's limit, per destination and entry year; UCAS from 2026 entry asks three questions sharing 4,000 characters) and its destination's earliest deadline is within `stmt_incomplete_watch_days` (45), and `critical` when that deadline is within `deadline_critical_days`; the first version's `stmt_watch_below: 90` treated the character ceiling as the target and is withdrawn |
| **Run cells** | Kept | With the floor (§3.4) |
| **Baseline chart band** | Kept | `[m − c·s, m + c·s]` from the snapshot |
| **Admission probability** | out of scope | pass 1 removed it; pass 5 replaces it |

The case header therefore prints: tier and SLA; evidence level; persisted (window); breadth. Every one traces to columns on `signal.evaluation` and `signal.signal.inputs` (§16).

---
## 10. Counselor control

### 10.1 The parameters

Three rule sets, all `config.rule_set_version` rows (pass 1), all per school with a platform default, all validated against a JSON schema published from `packages/engine` (`schema_version` on the row). A counselor sees them as one thresholds page with sections; the engine reads them as three documents.

**`engine.thresholds`** (what counts as a change). Defaults revised by pass 8 for the pilot (C9, F05, F25, F68):

| Parameter | Scope | Default | Bounds | Prototype slider |
|---|---|---|---|---|
| `domains.<d>.enabled` | per domain | true; **engagement false** | | |
| `measures.<key>` | per measure | §4: `{register, unit, window, n_min, dir, floor}`, for example `attendance.days_missed: {register: "master", unit: "days", window: "fortnight_block", n_min: 5, dir: 1, floor: 1.5}` (F68: stated per measure, so nothing about a measure's source is implicit) | the schema's enums; `floor` as below | |
| `baseline.window_weeks` (`W`) | global | 20 weeks of data | 8 to 30 | |
| `baseline.min_history_band` | global | 8 | 4 to 12 | |
| `baseline.min_history_full` | withdrawn (F25) | the self-starting widening replaces it (§3.2, §3.3) | | |
| `baseline.settling_weeks` | global | 1 | 0 to 3 | |
| `baseline.two_year_carry` | global | true | | |
| `band.c` | per scale family | 2.5 (ordinal 1.5) | 2.0 to 3.5 | |
| `band.ordinal_one_step_hold` | global | 2 assessments | 1 to 3 | |
| `shock.z` | per scale family | 3.0 (ordinal 3.5) | 2.5 to 4.5 | `acad` (1 to 4 σ) becomes this, in robust units |
| `shock.z_strong` | per scale family | 5.0 | 4.0 to 8.0 | |
| `shock.opens_monitor` | global | true | | |
| `cusum.k` | global | 0.5 | 0.25 to 1.0 | |
| `cusum.z_cap` | global | 3.0 | 2.0 to 5.0 | |
| `cusum.h` | global | 5 | 3 to 8 | |
| `cusum.h_strong` | global | 8 | `h + 1` to 15 | |
| `cusum.strong_mean_factor` | global | 1.5 | 1.0 to 3.0 | |
| `scale_floor.<scale family>` | per scale family | §3.3 (pct 4.0 points; ordinal 0.5 step; days missed from the day-level model; proportions and counts from the student's own rate) | 0 to 25% of range | |
| `attendance.typical_absence_share` (`p_typ`) | global | 0.05 | 0.01 to 0.15 | |
| `attendance.max_level` | global | **1 (weak)** until released by a version that cites measured reason-code coverage (§4.2) | 1 to 3 | |
| `breadth.window_weeks` | global | 2 | 1 to 4 | |
| `persist` | global | **3** (was 2) | 1 to 6 | |
| `persist_weak` | global | 3 | 2 to 6 | `persist` (1 to 6 wks) |
| `persist_free` | global | 3 | 2 to 6 | |
| `floor.<measure>` | per measure | §3.3 (attainment 5 points or 1 step; days missed 1.5 days per block; conduct 3 points per week; submission 15 points) | 0 to 25% of the measure's range | |
| `attendance.late_days_per_block` (`att`) | | 3 | 1 to 6 | `att` (1 to 6 in ten school days) |
| `attendance.unexplained_weak` / `_moderate` | | 2 / 4 per block | 1 to 5 / 2 to 8 | |
| `attendance.chronic_threshold_pct` | | 90, year to date | 80 to 95 | |
| `behaviour.serious_categories` | | from the vocabulary | | |
| `teacher.corroboration_staff` | | 2 | 2 to 4 | |
| `teacher.corroboration_window_school_days` | | 7 | 3 to 10 | |
| `teacher.tag_severity.<tag>` | per tag | §4.5 | 1 to 3 | |
| `engagement.silence_days` (`eng`) | | 14 | 5 to 28 | `eng` (5 to 28 days) |
| `engagement.gap_multiplier` | | 2.0 | 1.5 to 4.0 | |
| `university.T_balance` / `T_ref` / `stall_days` / `deadline_critical_days` | | 21 / 14 / 14 / 10 | 7 to 45 / 7 to 30 / 7 to 30 / 3 to 21 | |

**`engine.tiering`** (what a change is worth): the rows of §7.2 as an ordered list of `{condition, tier, rule_key}` with the conditions expressed in a small closed grammar (`max_level`, `breadth`, `persisted`, `domain_level`, `rule_fired`, `relapse`), plus `relapse_uplift` (1; 0 to 2), `retrospective_cap` (`review`), `termly_backfill_cap` (`review`), `hysteresis.exit_weeks` (2; 1 to 4), `hysteresis.person_raised_hold_days` (14; 3 to 60), `hysteresis.dismiss_cooldown_days` (14; 3 to 60), `hysteresis.max_reversals_per_week` (2; 1 to 5; lowerings and reversals only, never a raise into `checkin` or `urgent`, F08), `recovery_weeks` (3; 2 to 6), `budget.new_action_cases_per_fortnight` (10 per counselor; 2 to 40). Withdrawn by pass 8: `hysteresis.exit_h_factor` (exit no longer reads the CUSUM, F05) and `common_cause_share` (F26; its successor `ops.common_cause_alert_share` is a setting of the operations alert and is never passed to the engine, so the first version's "off (100%)" option, which sat outside its own bounds, is gone too). `case.lifecycle` (pass 1) keeps `monitoring_days` (90) and `auto_review_days` (14).

**`engine.suppression`** (what explains a change): `calendar.<kind>` → `{effect: suppress|soften|none, domains: [...]}` with defaults exam_period and mock_period suppress academic and engagement, holiday and inset null the week, reporting_window none, other (Ramadan) soften attendance and engagement; `soften_factor` (1.5; 1.0 to 3.0); `absence.after_days` (2; 0 to 5); `absence.whole_week_days` (3; 1 to 5); `teacher_note.weight` (`half`); `context_kind.<key>.effect` (the vocabulary's attribute, editable here).

### 10.2 Versioning

- Every save creates a new immutable `config.rule_set_version` row with `version + 1`, `note` (required, at least 20 characters), `created_by`, `effective_from = now()`, and closes the previous row's `effective_to`. Nothing is edited in place.
- The next sweep (and the next event evaluation) references the new version ids on `sweep_run`; every evaluation therefore names the versions it ran under, and the case file prints "evaluated under thresholds v3 (saved 12 Nov by Ms. Haddad: 'raise lates to 4 after the bus route change')".
- A new version never rewrites the past: existing signals keep their `inputs` and their version ids. The first evaluation under the new version supersedes signals whose rule no longer fires (status `superseded`, `superseded_by_id`), raises new ones, and moves tiers under hysteresis (raises immediately, lowers by the exit rules). A counselor can open yesterday's case and see yesterday's thresholds beside today's.
- Who may save: any counselor may **propose** (a draft version with `effective_from = NULL`); a counselor with the `caseload_lead` capability **activates**. During the pilot, activation also requires the CAROS onboarding engineer's acknowledgement (a support-grant action, pass 4), because a threshold change in shadow mode changes what the comparison measures.
- Scope is the **school**, not the counselor. Signals are staff-shared, a student who moves counselor must not change tier, and four counselors with four thresholds would make the tiers mean four things. Per-counselor overrides are a later feature if the elicitation (§10.5) shows the four disagree irreconcilably.

### 10.3 Guards against switching a domain off by accident

1. `enabled = false` requires a reason in the version note, writes `config.domain_disabled` to the event stream, and puts a persistent line on the caseload sheet and every case file: "Behaviour signals are off (since 12 Jan, Ms. Haddad: 'SIS export lacks conduct data until February')". It cannot be dismissed, only re-enabled.
2. The JSON schema enforces every bound in §10.1; a value outside it is refused with the bound in the message.
3. **The what-if delta** (§10.4) runs before every save. If a domain's twelve-week count of signals goes from non-zero to zero, or the count of action-tier cases falls by more than 60%, the save requires an explicit second acknowledgement that names the domain.
4. **The quiet-domain monitor**: the sweep emits `domain.quiet` when a domain has produced no signal of level ≥ 1 across the whole school for four consecutive weeks while its data kept arriving (as-of advanced). It shows on the thresholds page and goes to the ops channel (§13.8). A domain that is quiet because the data stopped arriving is a different alert (`cadence.missed`, pass 2).
5. Floors are capped at 25% of the measure's range and `c` at 3.5, so no setting can make a series unreachable; a floor set at its cap is printed on the thresholds page in the same red the sheet uses for a break.
6. Any version that would change the tier of more than 20% of open cases is applied under hysteresis for lowerings (no mass overnight downgrade) and requires the acknowledgement in point 3.

### 10.4 The what-if run

The thresholds page calls the engine's pure function (§13.1) over the last twelve weeks of stored `feature_snapshot` rows for the school with the **proposed** configuration and returns, per week and per tier, how many cases would have been opened or raised, which current open cases would move, and which measures would oscillate (more than two crossings of `h` in the period). It is the replacement for the prototype's "current false-positive rate 14%" and the mechanism behind guards 3 and 6. It writes nothing; it is a read of snapshots plus a computation, and it runs in seconds at pilot scale. Thresholds are per school, so pilot scale is the school's counseling surface, about 350 students and some 4,000 series over twelve weeks, not one counselor's 87 (F78).

### 10.5 The elicitation protocol

**Purpose.** To learn, before the engine is configured, what the four HS counselors consider urgent, how big a change is a change, how long it must persist, how many names a morning is useful, and which contexts make a signal expected. The output is a first `engine.thresholds` and `engine.tiering` version for ACS with every departure from the platform default traced to an answer, and a record of where the four disagree.

**Format.** One ninety-minute session with all four counselors together (disagreement is data and it only appears in the room), run by Davide with a note-taker, followed by a fifteen-minute individual written form (the same vignettes, answered alone, so the room does not flatten a dissent). Repeat the vignette part at the end of the shadow period with real, pseudonymised cases from the log.

**Part A · Twelve vignettes (45 minutes).** Each card shows one synthetic student's last eight weeks as the sheet will show them (the run, the series with the band, the evidence sentences), with no tier. For each card the counselor answers three questions: *Would you want to know about this? (yes / only if it continues / no)*; *When would you want to act? (today / within two days / this week / not yet)*; *What would you do? (free text)*. The cards, and the parameter each one probes:

| # | Card | Probes |
|---|---|---|
| 1 | A strong student's mathematics drifting from 92 to 84 over six weeks, everything else steady | `floor.attainment`, `persist`, whether a quiet decline of a strong student is worth a look |
| 2 | The same six-point drift in a student whose grades sit around 65 | whether the floor should be the same for both (the plan says yes) |
| 3 | One result at 61 in a series that sits at 88, nothing after it yet | `shock.opens_monitor`, `shock.z_strong` |
| 4 | Three late arrivals in ten school days from a student who is never late | `att`, the personal condition |
| 5 | Three late arrivals from a student who is usually late once or twice a fortnight | the personal condition again |
| 6 | Two days missed in each of two fortnights, from a student who misses none, with a medical note covering one of the days | `floor.attendance.days_missed`, suppression, whether attendance should be released from weak |
| 7 | One teacher concern, "withdrawn / quiet", nothing in the data | single-concern tier (`review`) |
| 8 | Two teachers' concerns in four days, one naming a peer conflict | `corroboration_staff`, safeguarding-relevant tags, what "route now" means to them |
| 9 | Seven conduct points in two weeks from a student with none before | `floor.behaviour`, serious categories |
| 10 | A Grade 12 with a conditional offer whose submissions have halved since the offer | `post_offer_decay` and whether it is a check-in |
| 11 | A student who recovered in October and whose attendance has fallen again in the same way | `relapse_uplift` |
| 12 | Two weak signals in different domains, both inside "not quite outside the band" territory, three weeks running | `combined_weak_signal`, `persist_weak` |

**Part B · Direct questions (20 minutes),** answered on a scale first and then discussed: how many days missed in a fortnight is a change worth your time; how many grade points; how many lates in ten days; how many conduct points in a fortnight; how many days of silence on the university journey in October versus in March; how many weeks should something persist before it is a card rather than a mark on the sheet; how many teachers noticing the same thing, in how many days, is a referral.

**Part C · The budget (10 minutes).** "On a normal Monday, how many new names would be useful, and at how many would you stop opening them?" Asked twice: for check-in and above, and for review. And: "If the engine had to choose between missing one student who needed you and sending you three who did not, which would you rather it did?" (this calibrates §1.3 and is asked as a preference, not a puzzle).

**Part D · Context (10 minutes).** Which weeks of the year are noisy and expected (exam weeks, mocks, Ramadan, the first fortnight, the week before a holiday, the IB deadlines); which absence reasons should silence attendance signals; whether a known family situation should make a signal quieter, louder, or the same (the plan's default is *the same*, and this is where the counselors overrule it if they want to).

**Part E · Safeguarding (5 minutes, with the CPO present if possible).** Which tags or combinations must route to the CPO regardless of anything else; whether the engine may propose `urgent` for a corroboration pattern or must stop at `checkin` and leave the routing entirely to the counselor.

**Part F · Shadow mode (5 minutes).** Explain the counselor log (§14.2) and ask what they would want to be able to record in it in under thirty seconds a day. Then ask for the two numbers G-LIVE pre-registers (§14.5): the share of cards judged worth having below which a card at `review` or above, and at `checkin` or above, is not worth opening. They are written into the pilot agreement before shadow starts.

**From answers to parameters.** Each answer maps to a parameter by a written rule so the mapping can be audited: Part B numbers become floors and thresholds directly (the median of the four, rounded to the parameter's step); Part A's "when would you act" for cards 1, 4, 6 and 9 sets the tier each single-domain level maps to (rows 5 and 11 of §7.2); card 8 sets the corroboration row; card 11 sets `relapse_uplift` (2 if three or four say "today", 1 if they say "within two days", else 0) and answers open decision 21 (whether the relapse rule may fire on a weak level while attendance is held; under the pilot defaults the prototype's Hana does not relapse on the day at all, §7.2); card 12 sets `persist_weak`; Part C sets `budget.new_action_cases_per_fortnight` (the median of the "useful" number, times ten school days, halved for safety) and the miss-versus-false-alarm preference is recorded in the version note; Part D sets `engine.suppression` and the context-kind effects; Part E sets the urgent rows and, if the counselors say the engine may not propose `urgent`, replaces row 2 with `checkin` and a `route_flag` the UI shows. Where the four disagree by more than one step, the default stays, the disagreement is written into the version note, and the caseload lead decides after the shadow period.

---

## 11. Alert budget

### 11.1 What a week looks like under the pilot defaults

Rewritten by pass 8 (F06). Computed by `calibrate_tiers.py` (appendix, section F; seed 20260924), which runs the level function of §3.5 and a simplified case lifecycle (opening, raising, lowering on the exit rule of §8.3 with the chart restarted at opening, monitor auto-review) on students built in **native units**:

- six attainment sections, each with the student's own mean (uniform 60 to 95) and noise (median four points, varying by student), **graded in a given week with probability one half** (a planning assumption: the pass 7 review worked the academic domain at nine and at eighteen graded weeks a section a year, and one week in two is the upper of those, F25);
- weekly coursework submission over two plus a Poisson(2) number of items due;
- attendance from a **day-level** model: absence episodes of one to three days, each student missing 1% to 8% of days, half of the absences carrying a suppressing reason (the F05 case), the rest authorised without suppression (40%) or unexplained (60%), counted in fortnight blocks, with the lateness and unexplained-days rules and the year-to-date policy floor, attendance held at weak;
- weekly conduct points (most students rarely, some often);
- a year of imported history (36 weeks), then 24 monitored weeks; the figures are means over monitored weeks 5 to 24, per 87 students; engagement off; no teacher concerns and no university rules; independent students, no autocorrelation, no seasonality.

A **new item** is an entry into a tier: a case opened into it or raised into it that week (F06). Occupancy, the cases sitting in a tier, is given separately.

| Per week, per 87 students, from noise alone | Normal noise | Heavy-tailed noise (t, 3 d.f.) |
|---|---|---|
| new `urgent` | 0.00 | 0.00 |
| new `checkin` | 0.01 | 0.08 |
| new `review` | 0.51 | 1.83 |
| of which: attendance policy floor | 0.16 | 0.15 |
| of which: strong shock | 0.17 | 1.33 |
| of which: shock after an outside point | 0.10 | 0.18 |
| of which: CUSUM held three weeks | 0.03 | 0.07 |
| of which: scale-free rule | 0.04 | 0.07 |
| new `monitor` | 4.15 | 5.14 |
| soft cells on the run / break cells | 8.4 / 0.3 | 13.2 / 1.0 |
| occupancy after 24 weeks: `checkin` or above / `review` / `monitor` | 0.09 / 1.26 / 15.38 | 0.70 / 8.69 / 23.41 |

Under the weekly pack a week's new items arrive on one morning, the pack's; under a nightly connector they spread over five. Against the first version's published figures (0.7 new check-ins, 11 reviews and 21 monitor cases a week under normal noise, which pass 7 could not reproduce under the stated rules, F06), the detuned engine is far quieter: fewer than one noise check-in a school year per caseload (0.01 a week), about one noise review every two weeks, four monitor rows a week that ask for nothing.

The price is detection, and it is large. Against a **genuine** change starting mid-term, the share of students whose case has reached each tier within a number of weeks of onset:

| Weeks after onset | 2 | 4 | 6 | 8 | 10 | 12 | 16 |
|---|---|---|---|---|---|---|---|
| Two-domain change (two sections fall two noise units, absence rises by 1.4 days a fortnight, unexplained), normal: `review` or above | 12% | 28% | 43% | 56% | 66% | 73% | 83% |
| the same, `checkin` or above | 0% | 2% | 5% | 9% | 14% | 20% | 30% |
| the same, t(3) noise: `review` or above / `checkin` or above at 8 weeks | | | | 66% / 12% | | | |
| One section falls two noise units (the strong student's quiet decline), normal: `review` or above | 5% | 10% | 15% | 20% | 24% | 27% | 32% |
| the same, `checkin` or above | 0% | 0% | 1% | 1% | 1% | 2% | 4% |

Read together. Under the pilot defaults the action tiers are almost silent on series data: a corroborated two-domain change reaches `review` about half the time within eight weeks and `checkin` rarely, because attendance is held at weak (so row 6 cannot fire) and row 9 needs two weak domains in each of three consecutive weeks. A single subject declining in a sparsely graded section reaches `review` in eight weeks one time in five. The action tiers will be filled, during the pilot, mostly by the rules that do not depend on series: teacher corroboration, the university rules, relapse, serious incidents. That is what C9's "accept later detection" costs, stated plainly, and it is why the shadow period measures detection as well as noise (§14.3).

**The levers, in order, once shadow has measured the real noise** (computed, normal noise):

1. **Release the attendance hold** once reason-code coverage is measured (§4.2): new check-ins from noise go from 0.01 to 0.03 a week per 87 and reviews from 0.51 to 0.62, while the two-domain change reaches `checkin` within eight weeks 17% of the time instead of 9%, and within sixteen weeks 41% instead of 30%.
2. **The scale floor back towards three-quarters of the noise** for the attainment family (§3.6: outside rises from 0.48% to 1.40% of points, shocks from 0.09% to 0.51%).
3. **`persist` back to 2**: little effect at the tier level under these defaults (the two-domain change reaches `checkin` within eight weeks 10% of the time instead of 9%, with reviews at 0.57 a week), because persistence is not what holds the action tiers back here.
4. Grading frequency is the lever outside the engine: a section graded weekly is detected in half the calendar time of one graded fortnightly (§3.6).

`h` is not a lever. None of these moves without a new configuration version and its what-if run (§10.4).

### 11.2 How the engine keeps the queue actionable

1. **Tiers absorb sensitivity.** Everything weak or isolated goes to the run or to monitor, where it asks nothing.
2. **Repeats are suppressed.** One open case per student (pass 1's unique index); new evidence attaches with a "since yesterday" line rather than a new card; a dismissed case's cool-down (§8.2).
3. **Persistence before attention.** No card without three weeks of data behind a CUSUM level, or a result large enough to be worth a look on its own (a strong shock, or a shock after an outside point).
4. **Corroboration before urgency.** The check-in and urgent rows need breadth, independence or a school-defined event.
5. **The budget is a tuning signal, never a cut.** `budget.new_action_cases_per_fortnight` (default 10 per counselor) is compared with the rolling count of new `checkin` and `urgent` cases per owner. When the count exceeds it, the sweep emits `budget.exceeded` (with counts only, §13.8), and the thresholds page shows the what-if run with a suggested floor and persistence change. **The queue is never trimmed and never reordered by anything but tier and time**, because trimming to a budget would rank students against each other (invariant 2). Within a tier the queue is ordered by the time the case was raised, oldest first, which is the SLA's own order. The prototype's sheet sorts a tier by "the loudest run" (`index.html:3366` to `:3373`); that sort is not ported (F50, pass 6 §6.3), and a test asserts it: changing any other student's data never moves a row within its tier (§15.1).
6. **Backfill does not flood.** Under weekly delivery the backfill evaluation (§13.5) opens cases from the final state only, so one Monday pack produces one set of movements, not three.

### 11.3 What replaces these numbers

At the end of shadow mode: the observed cases per tier per week, the counselors' acceptance per tier, and the measured noise per detector (signals on students the counselor log marks as "nothing"), all per school, written into the version note of the first live thresholds. The numbers in §11.1 are then retired from this document's status as guidance and kept only as the design's starting point.

---

## 12. Fairness

### 12.1 What could go wrong

A personal-baseline engine is structurally fairer than a threshold engine on the dimension the early warning literature worries about most: it does not flag a student for being below a population level, so a group with lower average attendance is not flagged more for that reason alone. Four things can still make it alert at different rates for different groups:

1. **The inputs the school produces.** Teacher concerns and behaviour records are human judgements, and both are known to vary by student group in the U.S. literature (teachers rate externalising problems as more serious, Splett et al. 2019; office discipline referrals show group disproportionality and language patterns that reveal it, Markowitz et al. 2023, in the same line as McIntosh's work). The engine inherits whatever skew its inputs carry, and a corroboration rule amplifies it.
2. **The policy floors.** The chronic-absence rule and the serious-incident rule are level rules; if a group's attendance is lower for reasons the school accepts (travel to a home country over Eid, for example), the floor fires more for it.
3. **The detectors' scale-dependence.** A student with a noisy history has a wide band, so the same decline is a smaller `z`; students whose lives are least stable would be the least likely to be caught. The scale-free rule (§3.5) is the mitigation, and the fairness test checks whether it is enough.
4. **Data availability.** Students in sections whose teachers use a gradebook the export covers get an academic series; students in sections that do not, do not. Language-support students on modified timetables may have different session counts. Absence of data is absence of signal, and it can fall unevenly.

### 12.2 The test

**Not run during the pilot** (decision C11, 2026-09-24). At one school the audit has almost no power: two groups of 175 alerted at 20% against 16% (a ratio of exactly 0.8) give about 16% power, while a group of 30 crosses the 0.8 to 1.25 bounds about half the time by chance, and across tiers, rules and groups a chance trigger is near-certain every quarter (the pass 7 review's computation, F68). So no special-category label is collected during the pilot, the audit runs only once **pooled data across schools** gives it power, and the pilot documents say plainly that fairness by nationality, gender, language background and SEN is untested during the pilot. The pooled data are from **customer tenants only**: a school's `core.school.purpose` must be `customer`, so canary and demonstration tenants never enter a pooled count, whatever their names or flags (F42). During the pilot two things that need no label still run, because they are practice and ingest findings rather than a fairness audit: the per-teacher concern rates overall (§12.3, visible only to the school's designated lead) and the share of students with no attainment series, by section (§12.1 point 4).

When it runs, it is a job over pseudonymised evaluation outputs joined to group labels (§12.4), producing an aggregate report and nothing else, under rules written before any data are seen (F68):

- **Pre-registered.** A short list of comparisons is fixed in advance and recorded in the configuration's version note: alert rate at `review` or above and at `checkin` or above by each label dimension, and recall on counselor-handled cases by each dimension. Anything else is exploratory and labelled so.
- **Pooled across quarters and schools**, with **95% intervals** on every rate and ratio.
- **A multiple-comparisons rule**: a Bonferroni correction across the pre-registered family. A comparison is a finding only when its corrected interval on the ratio lies wholly outside 0.8 to 1.25; a point ratio outside those bounds is never a finding by itself. Cells with fewer than five students are suppressed.

1. **Alert rates by group**, per tier and per rule key: the share of students in each group who received a case at that tier. Report the ratio of each group's rate to the highest group's rate, with its interval. The 0.8 and 1.25 bounds are borrowed from the four-fifths rule of the U.S. Uniform Guidelines on Employee Selection Procedures (29 CFR 1607.4(D)), which treat a selection rate under four-fifths of the highest group's as evidence of adverse impact while warning that small numbers and statistical significance matter; they are used here as a rule of thumb for *looking*, not as a legal standard.
2. **Input-channel rates by group**: teacher concerns per hundred students, per teacher and overall; behaviour points per hundred students; the share of students with a valid attainment series. These say whether a disparity in (1) arrives with the data.
3. **Outcome-conditioned rates**, once outcomes exist (shadow log, backtest, accept/dismiss): for each group, the recall on counselor-handled cases (true positive rate) and the rate of dismissed cases among alerted students (a false positive proxy). The engine's primary fairness criterion is **equal opportunity** (Hardt, Price and Srebro 2016): equal true positive rates across groups, because a miss is the costlier error (§1.3). It is reported with the false positive proxy, and with the reminder that equal error rates and equal calibration cannot all hold when base rates differ across groups (Chouldechova 2017), so a choice has been made and it is written down.
4. **Detector sensitivity by group**: the distribution of `s` (the personal scale) and of `H` by group, which is the direct test of §12.1 point 3 and point 4.

### 12.3 What to do when it fires

- **Never group-specific thresholds.** A different floor for a nationality would be a comparison by group, and it is exactly the mechanism a personal engine exists to avoid.
- If the disparity is in the **inputs** (2), it belongs to the school: the report goes to the counseling lead and leadership as a professional-practice finding, with the per-teacher rates visible only to the school's designated lead (pass 4 decides who). The engine does not down-weight a teacher's concerns by group; it makes the pattern visible.
- If the disparity is in a **policy floor**, the floor's tier cap (review, once a term) already limits its cost; the school revisits the threshold or declares the calendar context (an Eid travel week as `soften` for attendance).
- If the disparity is in **detector sensitivity** (4), the scale-free rule's `persist_free` comes down by one, or the floors come down for the affected measure, school-wide.
- If the disparity is in **data availability**, it is an ingest finding (pass 2: unmapped sections, missing gradebooks) and the report names the sections.
- Every finding and every response is a version note on the next configuration version, so the trail is in the same place as the thresholds.

### 12.4 The privacy tension

**Decided 2026-09-24 (C11): no label is collected during the pilot; `fairness.group_label` (D26) stays empty and unused in the pilot**, and the rest of this section is the design for when pooled data exist.

To test this at all, CAROS must hold nationality, gender, language background and special educational needs status for each student, and none of them is needed to run the engine. Ethnic (racial) origin and health data (which SEN records are) are sensitive personal data under the UAE's Federal Decree-Law No. 45 of 2021 (Article 1's definition); nationality is not confirmed as a listed category there (pass 7 citation register) and is treated as sensitive by policy (pass 4 §6.5). All four are special categories under GDPR Article 9, which pass 4 treats as the design floor. Holding them for a fairness audit is a recognised purpose with a recent legal template: the EU AI Act (Regulation (EU) 2024/1689) Article 10(5) permits providers of high-risk AI systems to process special categories of personal data strictly for bias detection and correction, subject to safeguards, minimisation, access limits and deletion once the bias is addressed. CAROS is not in that regulation's scope in Abu Dhabi, but the pattern is the right one and pass 4 should adopt it:

- The labels live in their own schema (`fairness.group_label`, §17) imported under a distinct mapping profile with `purpose = 'fairness_audit'`, readable by the audit job and the school's designated lead only. **The engine has no grant on it**, and the "no cohort" check on `band_method` gets a sibling: a test that `packages/engine` imports nothing from that schema.
- The audit joins on `core.person.id` through a per-run rotating key and writes only aggregates with small-cell suppression; the joined working table is dropped at the end of the run.
- The school chooses which labels to supply, and may supply none. If it supplies none, the audit runs on what the SIS already holds for other purposes (year group, programme, home language where present) and **the plan states that fairness by nationality and SEN is then untested**, rather than implying it.
- Retention of the labels follows the shortest class in `privacy.retention_class` and their erasure is independent of the student record's.

Whether a school will supply the labels once the pooled audit exists, under what legal basis, and whether its regulator's rules add anything, are questions for the schools and for pass 4 (§6.5 there; question 106). The engine's profiling of minors as a whole now has a **data protection impact assessment** in front of it: PDPL Article 21 requires one for systematic automated assessment of personal aspects, profiling included, with serious effects, and pass 4 puts it on the G-REAL list, drafted by CAROS for ACS as controller (F37; pass 4 §1.1). Its description of the engine is this document's §0.4, §3 to §8 and §14.

---
## 13. The nightly job

### 13.1 The pure function

`packages/engine` exports one function and no I/O:

```ts
export function evaluateStudent(input: StudentEvaluationInput): EvaluationResult

interface StudentEvaluationInput {
  asOf: { [domain: string]: ISODate };            // per-domain as-of, from ingest.expected_cadence and the newest fact
  today: ISODate;                                  // the school-local run date; the only "clock" the function has
  calendar: { schoolDays: ISODate[]; periods: CalendarPeriod[]; weekendDays: number[]; yearStart: ISODate };
  student: { id: UUID; joinedOn: ISODate; enrolmentStatus: string; yearGroupOrdinal: number; stage: string;
             restrictedDomains: string[];            // pass 4 D58: domains the engine skips for this student
             sections: { id: UUID; subjectKey: string|null; level: string|null; scaleKey: string; startedOn: ISODate;
                         predecessorSectionId?: UUID; carriedFromSectionId?: UUID }[] };   // set change or year two of a two-year course
  series: MeasureSeries[];                         // one per measure: { measureKey, domain, scaleKey, dir, unit, cadence, register, deliveredTermly,
                                                   //   points: {weekStart, value|null, n, provisional}[], sourceRowIds }
  events: { teacherFlags: TeacherFlag[]; behaviourEvents: BehaviourEvent[]; absences: AbsenceSpan[];
            contexts: CaseContext[]; sectionChanges: ISODate[] };
  uni: UniRuleOutput[];                            // list_balance, reference_sla, ... computed by packages/domain from uni.*
  caseState: { shadow: boolean;                   // a shadow run reads and moves the shadow case (§14.1)
              open?: OpenCase;                     // includes triggeringState: per measure, chart restart and baseline at opening (D22)
              escalation?: { open: boolean; unreleased: boolean; esc_window_until?: ISODate };   // the pin (§8.2, F07)
              closedInWindow: ClosedCase[]; personTierActions: PersonAction[]; dismissedAt?: ISOInstant;
              recentEngineMoves: { at: ISOInstant; direction: 'raise'|'lower' }[] };            // the rate limit (§8.2, F08)
  config: { thresholds: Thresholds; suppression: Suppression; tiering: Tiering; lifecycle: Lifecycle;
            vocabularies: VocabularySnapshot[];     // the attribute values and versions the rules may read (F48)
            versionIds: { thresholds: UUID; suppression: UUID; tiering: UUID } };
  // Nothing in this input describes any other student: there is no field for a school-wide share (F26).
  engineVersion: string;
}

interface EvaluationResult {
  snapshots: FeatureSnapshotDraft[];               // one per measure with a band or a self-starting state
  signals: SignalDraft[];                          // rule firings with frozen inputs and rendered summaries
  evidence: EvidenceDraft[];                       // adverse, positive and context items with source snapshots
  suppressions: SuppressionCheck[];                // every check, fired or not
  ruleHits: RuleHit[];                             // every tiering row evaluated, matched or not, with the values it saw
  level: 0|1|2|3; breadth: number; coldStart: boolean;
  proposal: { tier: Tier|null; moveWhyTemplate: string; moveWhyArgs: Record<string, string|number>; suggestedAction: SuggestedAction|null;
              windowStart: ISODate|null; windowEnd: ISODate|null; recovery: boolean; relapseOfCaseId?: UUID;
              heldByHysteresis: boolean; heldByEscalationPin: boolean; cappedTermly: boolean };
  inputHash: string;                               // sha256 over a canonical serialisation of the input
}
```

Guarantees, each asserted by a test: no reads of `Date.now()`, `Math.random()` or the environment (a lint rule bans them in the package); the same input produces byte-identical output (`inputHash` and a golden-file test); the function is total (every input that validates against the Zod schema returns a result or a typed `EngineError` with the measure that failed); versioning by `engineVersion` (semver from the package), with a changelog entry required for any change to a default, a template or a rule. The domain layer (`packages/domain`) is the only caller and owns loading and writing; the engine never sees a database. The same function serves the nightly sweep, the event evaluation, the backfill, the what-if run (§10.4), the shadow run and the tests.

### 13.2 Orchestration

All jobs in `apps/worker` on pg-boss (pass 1 DR-2), queue prefix `sweep.`:

| Job | Singleton key | Does | Deadline |
|---|---|---|---|
| `sweep.schedule` | cron, every 15 minutes | For each school returned by `core.schools_due_for_sweep(now())` (pass 1 §2.4: an ID-only definer function returning the schools that **hold data**, `core.school.status IN ('shadow','live')`, whose local time has passed `sweep_hour`, default 02:00, `core.school.sweep_hour`), and that has no nightly run for today, enqueue `sweep.run`; the worker then opens one `withTenant()` per school. Revised by pass 8 (F36): the first version said "each active school", a status that kept the pilot school, in `shadow` until G-LIVE, from being swept at all. Synthetic tenants are swept under the same rule, so their seeded status must be `shadow` or `live` (pass 1 DR-8) | |
| `sweep.run` | school + run_date + `nightly` | Insert `sweep_run` (status `running`, the three current version ids, `engine_version`, `deadline_at = 05:30 local`, `students_in_scope`); resolve the students in scope (active enrolments in the counseling year groups, plus students who left in the last day so C22 closes their cases); enqueue `sweep.batch` for groups of 50; enqueue `sweep.finalize` with a dependency on all batches | starts by 02:05 |
| `sweep.batch` | run + batch index | For each student: load the input through `packages/domain` (one query per table, batched by student ids), call `evaluateStudent`, write the result in **one transaction** per student (§13.3); on an exception, record `evaluation.error` and continue | retry 3× with backoff 30 s, 2 min, 10 min |
| `sweep.finalize` | run | Compute the overnight comparison (§13.6); run the DR-6 assertions (`tier_yesterday` recomputed from `case_tier_history`; `week_run()` for a sample of students equals the `outside` flags the engine stored); compute the budget count (§11.2) and the operations count of students outside their band per domain (§7.6), both after every case has been written and neither ever read by the engine (F26); enqueue the refresh of the school's reporting aggregates, the per-tenant `reporting.agg_*` tables under row-level security with one writer, run inside that school's `withTenant()` (pass 1 DR-6; never materialised views, which have no row-level security, F34); set `sweep_run.status` (`succeeded`, or `partial` if any student has an error after retries), `finished_at`, `heartbeat_at`; emit `sweep.completed` or `sweep.partial` (`sweep.completed` seeded by pass 1 §2.20, `sweep.partial` by D28) | by 05:30 |
| `sweep.event` | school + student (coalesced over 5 minutes) | The daytime evaluation (§7.5): a `sweep_run` with trigger `event` and `trigger_ref` (the flag, context or enrolment row), one student, the same write path, the daytime asymmetry enforced in the domain layer | within 5 minutes of the event |
| `sweep.backfill` | school + import | After a weekly or fortnightly pack commits, or a termly file with dated rows (§4.8), or the history import before shadow (pass 2 `ingest.after_commit`): §13.5 | within 30 minutes of commit; a history import may run longer |
| `sweep.whatif` | school + person | The thresholds page's what-if run (§10.4), read-only | seconds |
| `sweep.watchdog` | cron 05:45 local per school that holds data (the same `core.schools_due_for_sweep()` list, F36) | In-database check that today's nightly run exists and `succeeded` or `partial`; if not, emit `sweep.missed` and raise the in-app banner. This is the inside witness; the outside one is §13.8. Pass 1 DR-2 now uses these job names and this hour (§12.1 of the pass 7 review) | |

At pilot scale (about 350 students, some 4,000 series) a run is seconds; at 50,000 students it is a few thousand batches and minutes of worker time, well inside the window. In shadow (§14) every run is a shadow run and writes shadow cases; nothing else about the orchestration changes.

### 13.3 Idempotence

- **One nightly run per school per date.** Pass 1's unique index `sweep_run_one_live_per_date` is narrowed to `trigger = 'nightly'` (§17), so event and backfill runs on the same date do not collide with it.
- **One evaluation per run per student per evaluated week.** A backfill writes one evaluation for each week it covers, in one run (§13.5), so pass 1's `UNIQUE (school_id, sweep_run_id, student_id)` cannot hold; D17 replaces it with `UNIQUE NULLS NOT DISTINCT (school_id, sweep_run_id, student_id, backfill_of)`, which keeps nightly and event runs at one evaluation per student (their `backfill_of` is NULL) and lets a backfill write one per week (F40). A batch that retries after a crash re-evaluates the students it had not written; a student already written is skipped.
- **The run cells are written, not recomputed.** Every point in `feature_snapshot.series` carries `outside`, the engine's own verdict under the floor rule, and pass 1's `signal.week_run()` reads it (F40).
- **Deterministic ids.** Signals and evidence items get `uuid_generate_v5(evaluation_id, rule_key || measure_key || window_start)` so that a replayed write is an upsert onto the same rows, never a duplicate. Snapshots are content-addressed already (pass 1).
- **One transaction per student**: snapshot upserts, the evaluation, signals, evidence, the case open or move (through the trigger that writes history), events and audit. A crash between students leaves no half-written student.
- **The engine is pure**, so a re-run of any run with the same inputs and versions produces the same rows, and `inputHash` on the evaluation lets a re-run prove it did.

### 13.4 Partial failure

A student whose evaluation throws is recorded (`evaluation.error`, `sweep_run.students_failed`) and retried with the batch; after three attempts the run finalises as `partial`, the evaluated students' results are published, and the failed students keep yesterday's tier with a line on the sheet and the file ("not evaluated last night: an error in the attendance series; the team has been told"). `sweep.partial` goes to the operations channel with **counts, not ids**: the run id, the school id and the number of students that failed, by measure family (F60, pass 4 §9.4). The channel's provider is named: Azure Monitor action groups (email and SMS to the on-call, pass 4 §1.3). The failed students' ids stay in the database (`evaluation.error`), where the support path reads them under a grant (pass 4 §3.7). A run that cannot start (the database is unreachable, a configuration version fails to load) is `failed`, and the watchdog's absence check covers it. A partial run **is** a successful comparison base for the students it evaluated (§13.6).

### 13.5 Re-runs and the backfill

**Manual re-run.** `sweep.run` with trigger `manual`, a required `reason`, and `supersedes_run_id`. Allowed against a `failed` or `partial` run without further ceremony. Against a `succeeded` run it is allowed only by a support grant (pass 4) and reconciles rather than replaces: cases the new run still supports are untouched; signals the new run does not raise are marked `superseded` with the reason; cases the new run would not have opened are **annotated**, not closed, and the owner sees "a re-run on 16 Nov (reason: corrected attendance import) no longer supports this case". The counselor decides.

**Backfill after a weekly pack** (pass 2 §6.3). When `ingest.after_commit` reports new facts for students, `sweep.backfill` evaluates each affected student **as of the end of each school week the pack covers, in order**, with the calendar and as-of of that week, writing one evaluation per week (`backfill_of = week_end`) so the tier history is honest about when each move would have happened. Only the final week's result opens, attaches or moves cases; earlier weeks' proposals are recorded on their evaluations (`proposed_tier`) and used by the shadow comparison and the what-if run. `window_start` on a case opened by backfill is the onset week, not the commit date, and the case shows both ("first outside his band in the week of 2 Nov; seen by CAROS on Monday 16 Nov at 09:32"). The SLA clock starts at the commit (pass 2). A fortnightly pack is two weeks of observations and persistence counts both. The same mechanism runs a **termly file with dated rows** over the term, with every tier capped at `review` (§4.8), and the **history import** before shadow, where no week's result opens anything: the import only builds baselines, so shadow starts with a full window (§5, §14.1).

**Retrospective evaluation** for domains whose termly files carry only term aggregates is the same mechanism with one point per term and the `retro.*` rules (§4.8), triggered by the reporting-window import.

**In shadow** every backfill and every event run is a shadow run, evaluating and moving the student's shadow case (§14.1), and all of them feed the comparison, not only the nightly runs (F24).

### 13.6 What changed overnight

`sweep.finalize` sets, for every case row of the school, `tier_yesterday` to the tier the case held at the end of the **last successful or partial nightly run** (from `case_tier_history` at that run's `finished_at`), `tier_yesterday_run_id` to that run, and `moved_why` from the movement template. The sheet's overnight column and the rail's list (`movedToday`, `openedToday` in the prototype) read those columns. If the previous nightly run is more than one school day old (a missed night), the sheet prints "compared with the sweep of Thursday 19 November" at the top of the column, and the watchdog has already alerted. Daytime event runs never touch `tier_yesterday`; their movements are the "since this morning" list (§7.5), derived from `case_tier_history` rows with `evaluation_id` in an event run since the last nightly `finished_at`. Shadow cases get the same columns from shadow runs, so the reveal sessions (§14.4) can show what the morning would have looked like.

### 13.7 When a fact behind a signal is superseded

A corrected import (pass 2 §2.9, §2.10) supersedes rows that signals cite in `inputs.source_row_ids`. `ingest.after_commit` marks the affected `(student, measure, week)` dirty; the next evaluation (the backfill if the correction came in a pack, otherwise the nightly) recomputes the series from the current facts. For each open signal whose cited rows changed:

- if the rule still fires on the corrected series: the signal is superseded by a new one with the corrected inputs, and the evidence item is appended with a `corrected` snapshot (append-only, so the original stays);
- if it no longer fires: the signal is set `withdrawn` with `withdrawn_reason = 'fact_superseded'` and a reference to the superseding import; the evidence item gains a `corrected_on` annotation; the case is re-tiered under the rows that still match, **bypassing the exit-weeks condition** (§8.3), because the evidence was wrong rather than weak; and the movement reads "withdrawn: the Mathematics result of 41% was corrected to 71% on 16 November". If nothing remains, the case closes as `not_a_concern` with note `evidence_withdrawn`, and it does not count against the counselor's precision or the engine's.

### 13.8 Telling a human before 07:00

Two witnesses, one inside and one outside the system, both in Azure UAE North, with no student data in any alert.

1. **Inside:** `sweep.watchdog` (§13.2) at 05:45 local. If it fires it emits `sweep.missed`, and the caseload sheet carries a banner from that moment: "The overnight sweep did not complete. Tiers are as of the sweep of 19 November." The banner is not dismissible and clears only when a run succeeds.
2. **Outside:** the worker writes a structured log line `sweep.completed {school, run_date, status, duration}` to Azure Monitor Logs; a **scheduled-query alert rule** evaluates every 15 minutes and fires when no such line has appeared by 05:30 local for a school that **holds data** (the worker logs each night the school ids `core.schools_due_for_sweep()` returned, so the rule knows which schools should have run; never "active", which excluded the pilot school in shadow, F36), when `status = 'partial'`, when `duration > 2h`, or when the worker's own heartbeat line (every 5 minutes) is absent for 20 minutes. The action group (Azure Monitor action groups, named as a sub-processor in pass 4 §1.3) sends email and SMS to the on-call (Davide during the pilot; pass 6 sets the rota); its payloads carry counts and job identifiers, never a student id (F60, pass 4 §9.4). The API exposes `/health/sweep` returning, per school, the last successful run date and status as a boolean-shaped payload for an uptime check; it contains no identifiers.

Beyond the deadline: `students_failed > 0`; `domain.quiet` (§10.3); `budget.exceeded` (§11.2); `common_cause.detected` (§7.6); tier churn (more than 10% of open cases moved by the engine in one night, which is either a threshold change or a data problem); the DR-6 assertion failures. All are alert rules on the same log stream, and all carry counts, never student ids. **Every count or report this pass defines across schools, and every engine-quality alert, keys on `core.school.purpose`** (F42): in production the canary pair (`purpose = 'canary'`) is swept and its reliability alerts fire, labelled as canaries, but it never enters a count, a budget, a pooled fairness figure (§12.2), a shadow comparison or a report, and no rule identifies a canary by its name or any other marker.

---

## 14. Shadow mode for the pilot

Rewritten by pass 8 (F24, C9, F75, §12.17). Shadow now runs the engine that goes live.

### 14.1 Mechanics

A school in shadow has `core.school.status = 'shadow'` (pass 1 §2.3; it enters shadow at G-REAL) and `config.rule_set_version.shadow = true` on its engine rule sets, so every `sweep_run` is `shadow = true`. **A shadow run keeps its own case state.** It reads and writes shadow cases, `signal.case` rows with `shadow = true` (pass 1 §2.9: one open live and one open shadow case per student), through exactly the lifecycle a live run uses: hysteresis, relapse, recovery, the person hold where a counselor has acted, cool-downs, auto-review and the escalation pin. Evidence items are stored against the shadow case and against the evaluation that produced them (`evidence_item.evaluation_id`, pass 1). The first version wrote no case rows, so every shadow night started from empty case state and measured an engine with no hysteresis, no relapse, no recovery, no holds and no auto-review, which is not the engine that goes live, and its evidence had nowhere to be stored (F24).

- **Every run trigger is shadowed.** Nightly runs, backfills after each weekly pack, and event runs on teacher concerns, counselor context and enrolment changes all run in shadow and all feed the comparison (§14.3), because under weekly delivery the backfill *is* the ritual moment (§7.5).
- **History first.** At least twenty weeks of each student's own history are imported before the first shadow sweep (§5), so the full window exists from the first night, and shadow does not spend its weeks in cold start (the first version started after "six weeks of weekly data", shorter than its own history minimum, F24).
- **Nothing notifies and nothing reaches the sheet.** Shadow cases are read only as class `signal_shadow` (pass 4 §3.6): by the CAROS onboarding engineer under a support grant, and by the counselors at the reveal sessions.
- **Escalations are never shadow.** A counselor's escalation, or a teacher's safeguarding flag, during shadow is a real act on a live case (pass 1 C15, C23; invariant 5), routed to the school's safeguarding lead. The student's shadow case treats the live escalation as a pin, so shadow behaves as live would.
- Teacher flags are **live** throughout (the inbox is a workflow win that needs no engine), and they feed the shadow evaluation like any other input. The demonstration-data marker is unaffected: shadow runs over real data are real data.
- `signal.v_shadow_queue` (D25) reconstructs, per student per school day, the tier the shadow case held, the rule that put it there, and the run that moved it, from shadow cases and their tier history over **all** run triggers (F24; the first version read nightly evaluations only). It is `security_invoker` (F75), so it reads under the caller's own row-level security.

**Going live** moves the school from `shadow` to `live` on the recorded G-LIVE sign-off (pass 1 §2.3, pass 6). Open shadow cases are not copied into the live queue, where they would appear with a history the counselors never saw; the first live run opens live cases from the current evaluation, each shown as "opened at go-live" with a link to its shadow history.

### 14.2 Capturing counselor judgement: the counselor log

Ground truth in shadow mode is what the counselors actually did and why, recorded **before** they see the engine's opinion. `signal.counselor_log` (§17) holds one row per counselor per student per day they gave the student attention: `reason_key` from a small vocabulary (`academic`, `attendance`, `behaviour`, `wellbeing`, `university`, `family`, `safeguarding`, `other`), `prompted_by` (`own_observation`, `teacher`, `parent`, `student`, `colleague`, `data`), `action_key` (`conversation`, `meeting`, `parent_contact`, `referral`, `plan`, `watch`), a free note, and `would_have_wanted_alert` (`yes`, `no`, `unsure`, answered in retrospect at the reveal, not on the day). The UI is a thirty-second daily entry from the caseload sheet (a "who did you see today" row) and a Friday prompt ("anyone this week you did not log?"). The log is staff-only, its own data class (`counselor_log`, pass 4 §3.6), and it is the single most valuable dataset the pilot produces, because it is the first measurement of the base rate (§1.3).

### 14.3 The comparison

Weekly, over the shadow period, per counselor and pooled across the school, over every shadow run trigger:

| Measure | Definition |
|---|---|
| **Overlap** | Students both with a shadow case at `review` or above and in the counselor log in the same fortnight |
| **Lead time** | For overlapping students, days from the shadow case first reaching `review` or above to the first log entry; negative when the counselor was first |
| **Engine-only** | Students with a shadow case at `review` or above and no log entry within a fortnight either side: judged blind at the reveal (§14.4) |
| **Counselor-only** | Log entries with no shadow case at `review` or above in the prior four weeks: the misses. For each, the engineer records whether the data that would have shown it existed in CAROS (`data_gap` versus `engine_miss`) and which detector, if any, was close |
| **Detection** | For counselor-only students with data in CAROS, the tier and level the shadow case reached within eight weeks; the detuned engine is expected to be slow (§11.1), and this is where shadow measures how slow |
| **Noise per detector** | Signals of each level on students the log marks as `nothing this term` |
| **Reliability** | Sweep completion, duration, partials |

There is no fairness screen in the pilot (C11, §12.2).

### 14.4 The reveal protocol

Reveal sessions at the end of **shadow weeks 4 and 8**, and each later month, per counselor, sixty minutes. Shadow weeks are counted from the first shadow sweep: week 1 is the school week in which it ran, and the pilot agreement states this count (§12.17 of the pass 7 review; pass 6's overlay, which counts from G-REAL, calls the same sessions weeks 6 and 10).

**The judgement is blind** (F24). Before any walk-through, the engineer shows the counselor a mixed set of cards: every student in their caseload whose shadow case reached `review` or above in the period, and an equal number of **matched unflagged students** from the same caseload, matched on year group and fortnight and drawn at random with a recorded seed. Every card looks the same: the student's own weekly data for that fortnight and the eight weeks before (results, days missed and late, conduct points, concerns logged, deadlines), with no tier, level, rule, band or run marks. For each the counselor answers "would you have wanted to know about this student in that fortnight?" (`yes`, `no`, `unsure`) and "how soon?" (`today`, `two days`, `this week`, `not yet`). The first version asked "would you have wanted this?" with the engine's evidence in front of the counselor (F24). Matching is for the evaluation only: it compares nothing on any screen, stores nothing but the judgement, and no student is ever ranked (invariant 2).

Only then does the engineer reveal which cards were engine cases and walk through their evidence chains; then the counselor-only students, where counselor and engineer agree the classification (data gap, engine miss, or a case the engine should never see, such as a family matter with no data trace). Threshold changes proposed at a reveal become a new **shadow** version, effective from the next sweep, so the next four weeks measure the change. Nothing from the log is shown to the counselor before the reveal, and the log's `would_have_wanted_alert` is answered only at the reveal, so the counselor's own record is not shaped by the engine's.

### 14.5 Leaving shadow mode (G-LIVE)

The pilot is judged on **pre-registered intervals, pooled across the four counselors**, never on point thresholds (F24, C9). A point bar is a coin toss at pilot scale: an exact 95% interval on 12 correct out of 20 runs from 36% to 81% (computed), and an engine that is truly 50% precise would clear a 60% bar about a quarter of the time at 20 cases (25%, computed; the pass 7 review's point).

**Pre-registered in the pilot agreement before the first shadow sweep:** the primary measure, the **precision proxy at `review` or above**, which is the share of blindly judged engine cases answered `yes`, pooled across counselors; the secondary, the same at `checkin` or above; the two floors the counselors named in the elicitation (§10.5 Part F; defaults **25%** at `review` or above and **50%** at `checkin` or above); the minimum of **40 judged engine cases**; the matched-control comparison; and the longest shadow period the school accepts (for example one term).

The caseload lead activates the first live version when all of the following hold, and the version note records the numbers:

1. At least twenty weeks of history were imported before the first shadow sweep, and at least eight weeks of shadow have run.
2. At least **40** engine cases at `review` or above have been judged blind, pooled across counselors, and the **one-sided 95% lower bound** (Wilson) of their precision proxy is at or above the pre-registered floor.
3. Engine cases are judged `yes` more often than their matched unflagged students, with the 95% interval on the difference above zero: the engine does better than chance at the counselors' own judgement.
4. The `checkin`-or-above precision is reported with its interval; it is held to its floor only if at least 40 such cases were judged, and is otherwise reported as underpowered, neither passed nor failed. The detuned engine produces few series-driven check-ins (§11.1), so this is the expected outcome at pilot scale.
5. Every counselor-only case has been classified, every `engine_miss` has a change in the configuration or the engine that would have caught it (re-run in what-if to show it) or a written reason why not, and every `data_gap` is either closed by ingest or accepted in writing.
6. The sweep completed on time on every night of the last four weeks.
7. The four counselors agree to go live, with their disagreements recorded.

The first version's fourth criterion (no unexplained fairness trigger) is withdrawn: the audit does not run in the pilot (C11), and the pilot documents say fairness is untested.

**How long shadow takes.** Under the planning numbers of §11.1 (appendix, section G), a school of about 350 students produces about 3.6 new cases at `review` or above a week under normal noise and 9.7 under heavy tails, so 40 judged cases take roughly five to eleven weeks; shadow runs until the minimum is reached or the pre-registered longest period ends, when the caseload lead and Davide decide on what exists and the decision records that the bar was not met. The same planning arithmetic, with one genuine episode a week per 87 (§1.3), puts the expected precision proxy at `review` or above at about 42% under normal noise, whose one-sided lower bound at 40 cases would be about 30% (computed), above the default floor, and about 21% under heavy tails, below it. That is the intended behaviour: an engine whose review cards are four-fifths noise should not go live untuned. These are planning numbers, not measurements, and the teacher-concern and university rules, which the simulation leaves out, will add cases of both kinds.

Going live changes one thing: cases open. The log continues for one more term, because the comparison is the only measurement of precision the product will ever have until the reporting metrics accumulate.

### 14.6 The ethics of shadow inferences

Shadow evaluations and shadow cases are welfare inferences about real minors that nobody acts on. They are held under the same controls as live signals, in their own class `signal_shadow`, retained as pass 4 §7.1 sets for that class (they are the audit trail of how the engine was tuned, and a later question "why is this student's threshold what it is" is answered from them), and disclosed to families in the terms pass 4 sets for the engine as a whole. They are within the **data protection impact assessment** the engine's profiling of minors requires under PDPL Article 21, which CAROS drafts for ACS before any real record and which is on the G-REAL list (F37, pass 4 §1.1), and whose description of shadow mode is this section. A student who leaves during shadow mode has their shadow rows treated like any other signal rows under erasure.

---

## 15. Validation

### 15.1 Before any real data: the adversarial synthetic set

`packages/engine/test/scenarios/` holds one JSON file per scenario: a generator (points per measure with a named noise seed, calendar periods, absence spans, teacher flags, context rows, escalations, case state, and the configuration version it runs under) and an expectation (per point: level per measure, rule hits, proposed tier, onset; and the final evidence sentences). `pnpm test --filter engine` runs them all in under a second, and they are the acceptance test for every engine change. Revised by pass 8 for the detuned defaults (F05, C9), the escalation pin (F07), the rate limit (F08), the withdrawn cap (F26), termly data (F25, F31) and results day (F64); the expectations below were traced with the appendix script's level function. The scenarios the prompt requires and the ones the design added:

| # | Scenario | Construction | Expectation |
|---|---|---|---|
| S1 | Strong student quietly declining | attainment history at 95, 94, 96, 95, 94, 93, then 91, 89, 88, 86, 85, 84, 83, 82, one assessment a week; every other measure steady; still above any class mean | no shock; the CUSUM signal from the fifth decline point (`S` 5.19); moderate at the seventh (`P` 3), review; strong at the eighth (`S` 11.7, run-mean 8.1), check-in; onset at the first decline point |
| S2 | Struggling student genuinely recovering | days missed per fortnight block 3, 2, 2, 1, 1, 0, 0, 0 from a history of none, with an open, accepted case from the first block | attendance weak, held; the chart restarts at the opening; the second and third blocks outside, the fourth and fifth weak on the restarted sum (`S` 5.42, 6.3); level 0 from the sixth; the improving guard blocks the policy floor; recovery at the seventh block (four weeks at level 0, mean since opening 1.0 day, under the 1.5 floor); tier `good`. Baseline from the pre-episode history, because §3.2 now excludes an open case's weeks too (F78) |
| S3 | Single outlier | attainment steady at 87 ± 2 for twenty assessments, one at 61, then 88, 86 | the 61: strong shock (`z` 6.34, `d` 26), moderate, review; the capped sum stops at 2.5, where the first version's reached 8.17; the next two inside, level 0, mean since opening 0: lowered to monitor under §8.3 two assessments later, then closed at auto-review; never strong. A smaller outlier (Yousef's 74 against 87, `z` 3.17) is a plain shock: monitor |
| S4 | Term break | 8 steady weeks, a 3-week holiday of null weeks, then 4 steady weeks | no signal; null weeks absent from `B`; `S` unchanged across the gap; run cells `none` |
| S5 | Transfer in | `transferred_in`, no history, then 4 steady weeks, then a genuine 3σ decline over weeks 5 to 8 | weeks 1 and 2: cold, no band; from the third point self-starting, capped at weak; a strong shock in the decline raises moderate, review; no urgent; `baseline_established` monitor when `H` reaches 8 if still steady |
| S6 | Missing weeks | S1's series with 30% of points null at random (seeded) | detection delayed by the null points only; no false signal on the null weeks |
| S7 | Teacher concern only | flat series everywhere; one concern (severity-2 tag) day 1 | review (row 12); event evaluation within 5 minutes; second independent concern day 4: check-in; third day 6: urgent; a `reviewed` status keeps counting; a `dismissed` one does not. Variant: a teacher's `safeguarding` flag instead: no engine level at all; a live escalation and case through C23, tier `urgent`, pinned (F10) |
| S8 | Relapse inside the window | S2's recovery, case closed by the counselor with an outcome, then days missed per block 2, 3, 3 | released attendance: weak, then moderate at the second relapse block (a shock after an outside point); a relapse case with `relapse_of_case_id`; fresh review, uplifted to check-in. Under the pilot hold: weak only, a `relapse_watch` monitor case that prints the closed case (§4.7) |
| S9 | Exam period, suppressed for one year group | two students, Grade 12 and Grade 11, same mock-week dip; `mock_period` for Grade 12 | Grade 12: suppressed, check recorded, no level; Grade 11: the mock judged against the attainment band, a shock, monitor |
| S10 | Subject change and year two | attainment series ends with a section change; new section starts 8 points lower; separately, a two-year course moves to its second-year section | the change: old series ends; new series cold or inherited (set change) with `H` capped at 8; no signal for two weeks; `section_change` suppression recorded. Year two: the baseline carries with its full history, and the file says so (F25) |
| S11 | Authorised absence | no days missed, then fifteen school days coded `M` (a suppressing reason), then none | those days leave registered and missed days alike; the blocks inside are null; engagement suppressed plus 2 days; no signal |
| S12 | School-wide bad week | 40% of students outside band on attendance in one week | **no cap** (F26): each student's level is what their own series gives; `common_cause.detected` with counts only and the prompt to declare a period; once the period is declared, a manual re-run suppresses the week for everyone alike. The no-comparison property below holds on this scenario |
| S13 | Steady student, tiny wobble | attainment 96 ± 0.5 for 20 assessments, then 94 | `z` 0.49 on the floored scale and `d = 2 < floor 5`: nothing; not even a soft cell. With the floor removed in a what-if run, still nothing, because `d < floor` |
| S14 | Ordinal series, three scales | IB grades 7, 7, 7, 6, 7, 5, 5, 5; the same shape as GCSE 9 to 1 (8, 8, 8, 7, 8, 6, 6, 6) and as A level (A\*, A\*, A\*, A, A\*, B, B, B) (F31: not IB only) | point 4: a one-step move not held across two assessments, inside, no cell (F68); point 6: two-step drop, shock (`z` about 3.9), weak, monitor; point 7: a shock after an outside point, moderate, review; the same on all three scales |
| S15 | Corrected import | S1 with its sixth decline point later corrected from 84 to 93 | the signal on the corrected series is superseded or withdrawn; tier re-evaluated bypassing exit weeks; evidence item carries `corrected_on` |
| S16 | Positive-only student | everything inside band; a positive teacher flag; a favourable outside point | no case; the file stays quiet; positive evidence is visible in the baseline tab only |
| S17 | Counselor downgrade, no new evidence | check-in lowered to review by a person; the same measures persist | engine does not raise within 14 days; tier history row shows the hold; day 15 with the level still moderate in two domains: raise, reason `hold_expired` |
| S18 | Counselor downgrade, new domain | as S17, then a teacher concern on day 5 | raise on day 5, reason `new_domain` |
| S19 | Hysteresis at the edge, and a raise that is never held | a measure whose level alternates between moderate and weak week to week on a case at review; then, the day after an engine raise from monitor to review, a third independent teacher concern arriving | at most one engine lowering in 24 hours and at most two reversals in seven days; the third reversal held, `tier.held_by_hysteresis` emitted, the what-if run lists the measure as oscillating. The concern meets row 2 and the case is raised to **urgent the same day, not held** (F08) |
| S20 | Weekly backfill | three weeks of facts in one pack, the decline starting in week 1 | three evaluations with `backfill_of` in one run (the unique key admits them, D17); one case opened from the final state; `window_start` is week 1; SLA from commit |
| S21 | Retrospective term | termly working grades only, IB: 6, 6, 6, then 5, then 5 | the first 5 against three prior 6s: one step, not held, nothing; the second 5: a one-step drop held across two windows, `retro.academic` moderate, tier capped at review, evidence names the export. Variant 6, 6, 6, 4: a two-step drop, fires at once (F25) |
| S22 | Threshold change | a live version raises `floor.attainment` from 5 to 8 | S1 at its seventh decline point is not raised; an open S1 case is lowered only under hysteresis; case file shows both versions |
| S23 | Both tenants' authored cases | pass 1 DR-8's facts layers, with the ACS fixture's history import | ACS: the list in §7.2; Wellesmere: the list below; the CI-only `wellesmere-shifted` tenant: Wellesmere's results with every date, school day and clock computed in its own timezone and weekend. Each list is generated by running the rules and is the expected output of `engine-reproduces-seed` (F06, F31) |
| S24 | Escalated case, quiet data, 60 days | a case escalated by a counselor (C15, tier `urgent`); every series steady and no concern for 60 days; the escalation acknowledged, then closed with an outcome on day 40 | tier `urgent` throughout: no lowering on any night, no auto-review closure, no self-recovery or `good`; from the first night the data alone would lower it, `held_by_escalation_pin` in `rule_hits` with the proposal it held; recovery written as evidence only. Day 45: a person sets the tier to review (C10), which releases the pin; from then hysteresis resumes from review, and auto-review cannot close it inside the 90-day `ESC` window (F07) |
| S25 | A second concern on an escalated case | an open case at `urgent` with an open escalation; a second teacher's concern arrives; later a teacher's `safeguarding` flag; later still the escalation closes and a new safeguarding concern is raised | the concern attaches as evidence (C3) and the corroboration rows are evaluated and recorded, the tier already `urgent`; no second case (one open case per student); the flag while the escalation is open becomes an escalation update (C24), not a second escalation; after the close, the new concern is a new escalation on the same case with `previous_escalation_id` (C15); the pin holds throughout (F07) |
| S26 | Results day | a firm conditional offer (AAB including Mathematics at A); final results imported on a day in August outside every term (`sis.term`): A, B, B with Mathematics at B | `offer_condition_check` strong, a check-in whose clock runs in calendar days (due two calendar days after the import), printed "results period: calendar days"; variant with the condition met: positive evidence, no case (F64) |

**Wellesmere's expected results** (F31). Wellesmere delivers termly iSAMS files with dated gradebook rows (pass 2 adds due dates and missing flags) and a daily AM/PM register, so its series run as a **termly backfill** capped at `review` (§4.8), while its teacher concerns are live. Under the pilot defaults, its eight authored cases must produce:

| # | Case | Expected under the pilot defaults |
|---|---|---|
| W1 | A Year 11 GCSE mock dip inside a declared exam period (`mock_period` for Year 11; the dip is a graded `mock` row, pass 2) | suppressed; the check recorded; no level, no case |
| W2 | A mid-year transfer with no history | cold: no band, no series level; `building a baseline` shown; `baseline_established` monitor once eight points exist, if steady |
| W3 | A Year 13 with an authorised medical absence of three weeks | the covered days leave the counts; the blocks inside null; engagement suppressed; no case |
| W4 | A student whose only signal is a teacher concern | review (row 12), live, not capped |
| W5 | An EAL student with rising grades and falling attendance | attendance weak and held: monitor; the rising grades are positive evidence |
| W6 | A relapse inside a closed case's window, on A-level attainment | the triggering measure moderate in the termly backfill; relapse uplifts the fresh review to check-in, and the termly cap wins: **review**, printed "relapse, on termly data: capped at review" |
| W7 | A conditional offer at risk | the submission series (from due dates and missing flags) at moderate or above since the offer: `post_offer_decay`, check-in by rule, **capped at review** because its evidence is termly |
| W8 | A student with nothing wrong | no case, a quiet row |

A test also asserts that no engine template, rule description or evidence sentence names a regulator (the chronic-absence floor says "the school's attendance policy"), so pass 1's check that "ADEK" appears on no Wellesmere screen holds for everything the engine writes.

Property tests, run over generated series: determinism (same input, same output); **monotonicity** (adding an adverse observation never lowers a level; adding a favourable one never raises it); **suppression never raises**; **no comparison** (the output for a student is unchanged when every other student's data changes, which is the executable form of invariant 2; kept strict, now that the common-cause cap is gone, F26); **no reordering within a tier** (changing any other student's data never moves a row within its tier on the sheet, F50); hysteresis (no two engine lowerings of the same case within `exit_weeks` of data); **the pin** (no engine write lowers or closes a case with an unreleased escalation, F07); **vocabulary snapshots** (every rule hit and suppression check that read a vocabulary attribute carries its value and version, F48).

### 15.2 With pseudonymised history: the backtest

**Data**, under a data processing agreement (pass 4), after the DPIA (§12.4) and pass 2's question 83: two academic years of per-assessment grades with dates, per-day master-register attendance with codes, behaviour records, the calendar, section rosters, and, indispensably, **the counselors' own dated records of the students they supported**: intervention logs, referral and escalation records, parent-contact notes, whatever exists, with a category and a date, pseudonymised with the same key as the SIS rows. If ACS keeps no such records, the backtest can measure lead time against nothing, and the shadow log (§14.2) becomes the only ground truth, one term later.

**Where it runs** (F23). The backtest is a Container Apps job in Azure UAE North, in CAROS's production subscription, reading the history from an in-country store. The pseudonymisation is done inside that job with a key held in Azure Key Vault in UAE North and usable only by the job's managed identity; no person can read or export it, and the person accountable for it is named: Davide, as CAROS's data custodian during the pilot. ACS's data protection lead approves each run. Python tooling (`ruptures` for PELT) runs inside the job's container image. **Only aggregates leave the job**: counts, rates, distributions, the parameter grid and the proposed configuration; never a row, a pseudonymised id or a free-text field. No part of it runs on a laptop, a GitHub-hosted runner or a coding-agent session.

**Procedure.**

1. Reconstruct weekly series exactly as the engine will (through `packages/ingest` and the domain loader), so the backtest exercises the real pipeline.
2. Run `evaluateStudent` as of the end of every school week of both years, with the calendar and cadence the school actually had (the second year's evaluations have a full baseline; the first year's are the cold-start behaviour).
3. Independently, segment every series with PELT (Killick, Fearnhead and Eckley 2012; `ruptures`, Truong, Oudre and Vayatis 2020) to find where the series itself says a change happened. This is an oracle for the detectors, not for the counselors: it answers "did the engine find the changes that were there, and how late".
4. Match engine cases at `review` or above to counselor-handled records within a window.

**Metrics.** Recall of counselor-handled cases with an engine case in the prior two, four and eight weeks; precision of engine cases at each tier (share followed by a handled record within four weeks, with the caveat that the counselor may have missed cases the engine found, so this is a floor on precision); the lead-time distribution; cases per week per tier; the detectors' delay against the PELT change points; the sensitivity of all of these to the floors, `h`, `persist` and `W` over a grid. Three measurements the pilot defaults wait for: ACS's **typical per-assessment noise** (for the attainment scale floor), its **typical absence share** (`p_typ`, §3.3), and its **reason-code coverage** (the share of absent days carrying a reason code, which releases the attendance hold, §4.2). No fairness screen runs (C11, §12.2). Output: a report, a proposed first configuration version for ACS with every parameter justified by a number, and an updated expected-result list for §15.1.

### 15.3 What cannot be known until the second step

Stated plainly, because the design has to be honest about its own uncertainty:

- The **base rate** of episodes a counselor would want to know about, and therefore the real precision of any tier.
- The **right floors** for ACS's gradebook and register: the noise of a Veracross percentage series and ACS's typical absence share are unknown, and they set every false-alarm rate in §3.6. So is ACS's **reason-code coverage**, which decides when attendance is released from weak.
- Whether the historical export carries **per-assessment dates and a per-day master register** at all; if it carries only term grades, only the retrospective mode can be backtested and the weekly design goes into shadow mode untested by history.
- Whether **dated records of handled cases** exist; without them there is no lead time to measure.
- The **autocorrelation and seasonality** of real series, which the simulation ignores and which will move the noise figures, probably upward.
- The **teacher-concern rate** (how many flags a week, from how many teachers), which sets the corroboration rule's noise.
- The **fairness rates**, which are not measured in the pilot at all (C11) and wait for pooled data across schools.
- Whether the four counselors **agree with each other**; if their judgements of the same case differ, "precision" is a moving target and the elicitation's disagreements become the pilot's first finding.

---

## 16. What the engine writes for each signal

The rule is that the case file renders from stored rows and never recomputes, so that a signal raised under thresholds v2 still explains itself after v5. Everything the file prints has a column; every number in a sentence has a field in `inputs`.

### 16.1 Per measure: `signal.feature_snapshot`

`band_method = 'personal_median_madn_v1'` (the `NOT ILIKE '%cohort%'` check stays). `series` is the points with `week_start` (the Monday of the school week, or of a block's first week), `value`, `n` (assessments, items due, or registered days), `suppressed`, `provisional` and **`outside`**, the engine's own verdict on that point under the floor rule, which `signal.week_run()` reads (F40). `features`, for Ahmed's Mathematics on the authored day (values from the §7.2 trace; example dates in 2026, weeks starting on Mondays, F78):

```json
{
  "scale_key": "pct", "dir": -1, "unit": "%", "cadence": "per_assessment",
  "window_weeks": 20, "history_weeks": 20, "history_unit": "assessments", "phase": "full",
  "carried_from": "Mathematics AA HL, year 1", "excluded_episodes": [],
  "m": 90.5, "mad_n": 2.22, "s_floor": 4.0, "widening": 1.025, "s": 4.1, "floor": 5,
  "c": 2.5, "band_lo": 80.2, "band_hi": 100.0,
  "z_last": 12.08, "d_last": 49.5, "outside_last": true,
  "cusum": {"k": 0.5, "z_cap": 3.0, "h": 5, "h_strong": 8, "S": [0, 0, 0, 0, 0, 0.23, 2.73, 5.23],
            "onset_week": "2026-10-26", "persistence_weeks": 1, "run_mean_d": 23.17, "restarted_at": null},
  "shock": {"z": 3.0, "z_strong": 5.0, "fired": true, "strong": true, "previous_point_outside": true},
  "scale_free": {"floor_x2": 10, "points": 2, "fired": false},
  "slope_6w": -6.1, "improving_weeks": 0,
  "level": 3, "strong_reason": "strong_shock_after_outside",
  "assessments_since_onset": 3
}
```

### 16.2 Per rule firing: `signal.signal`

`rule_key`, `rule_version` (the engine version the rule's code carries), `domain`, `measure_key`, `snapshot_id`, `level` (1 to 3), `polarity`, `window_start`, `window_end`, `onset_week`, `template_key`, `template_version`, `summary` (rendered), `inputs`:

```json
{
  "thresholds_version_id": "…", "suppression_version_id": "…", "tiering_version_id": "…", "engine_version": "2.0.0",
  "as_of": "2026-11-13",
  "detector": "strong_shock", "values": {"z": 12.08, "d": 49.5, "m": 90.5, "s": 4.1, "floor": 5, "z_strong": 5.0,
                                          "previous_point_outside": true, "S": 5.23, "h": 5, "z_cap": 3.0,
                                          "persistence_weeks": 1, "strong_reason": "strong_shock_after_outside"},
  "points_cited": [{"week_start": "2026-11-02", "value": 74, "n": 1, "outside": true},
                   {"week_start": "2026-11-09", "value": 41, "n": 1, "outside": true}],
  "source_row_ids": {"sis.grade": ["…", "…"], "sis.assessment": ["…", "…"]},
  "suppression_checks": ["exam_period:no", "mock_period:no", "section_change:no"],
  "vocabulary_used": [],
  "template_args": {"section": "Mathematics AA HL", "value": 41, "unit": "%", "date": "12 Nov", "d": 49, "m": 90.5,
                    "history": 20, "history_unit": "assessments", "nth": "second"}
}
```

`vocabulary_used` lists every vocabulary attribute a rule or a suppression check read, with its value and the row's version, for example `{"vocabulary": "flag_tag", "key": "withdrawn_quiet", "version": 3, "attributes": {"severity": 2, "safeguarding_relevant": false}}` on a teacher-concern signal (F48). Templates live in `packages/engine/templates/<rule_key>.<lang>.txt`, versioned with the package; a placeholder may bind only to a `template_args` field, which the schema restricts to numbers, dates and enumerated labels from the inputs, so a template cannot invent a number. The rendered `summary` is stored, so a later wording change does not rewrite history. The case **headline** is the rule's headline template alone: no model rephrases it (F52; pass 1 §2.9 removed `headline_generation_id`).

### 16.3 Per evidence item: `signal.evidence_item`

`kind`, `domain`, `case_id` (a live or a shadow case), `evaluation_id` (the evaluation that produced it, for engine items; pass 1, F24), `source_label` (rendered from the import's source system and the as-of, pass 2), `source_table`, `source_id`, `occurred_at` or `occurred_label`, `level`, `polarity` (`adverse` / `positive` / `context`), `template_key`, `summary`, `snapshot` (the cited source rows as they were: for a grade, the assessment title, date, score, max and the import id; for a flag, its tags, the tags' vocabulary attributes and versions, and its body; for an absence, its reason code with the reason's `suppresses` attribute and version; for a context row, its kind and validity). Append-only; a correction adds an item.

### 16.4 Per student per run: `signal.evaluation`

`level`, `breadth`, `proposed_tier`, `cold_start`, `as_of` (per domain), `snapshot_ids`, `backfill_of`, `trigger_ref`, `input_hash`, `rule_hits` (every tiering row, `{row, matched, values_seen, vocabulary_used}`, plus `held_by_escalation_pin` or `held_by_hysteresis` with the proposal held, §8.2), `suppressions` (`{check, outcome, detail, vocabulary_used}` for every check in §6.2), `error`. A shadow evaluation is one whose run is `shadow = true`; it moves the student's shadow case (§14.1).

### 16.5 Per case movement: `signal.case` and `case_tier_history`

`moved_why` rendered from the movement template with the same discipline; `suggested_action` `{what, when, why, rule_key}` from the matched tiering row's action template; `window_start`/`window_end`; `no_cause_inferred = true` on every engine-opened case (the prototype's "The system does not infer a cause" is a property of the engine, not a per-case flag); the tier history row's `evaluation_id`, and `reason` for the exceptions in §8.2 (`new_domain`, `new_concern`, `strong_level`, `hold_expired`, `fact_withdrawn`, `context_added`, `pin_released`). `triggering_measures` (D22) with, per measure, the chart restart point and the baseline frozen at opening, which exit and recovery read (§8.3).

### 16.6 Explainability after the configuration changes

The file shows, for each signal, the version it was raised under and, if the current version differs, a line "thresholds have changed since (v3 → v5)"; the what-if run can show what the current version would say. A superseded signal keeps its row and its link to the superseding one; a withdrawn one keeps its row and its reason. The baseline chart draws the snapshot the signal cites, not tonight's. Nothing on the file is computed from live facts except the "as of" freshness line.

---
## 17. Schema deltas to passes 1 and 2

Numbered after pass 2's D16, in migration order. Each is a small, reversible change; none touches a table pass 2 owns. **Revised in place by pass 8 (2026-09-24):** no delta is added or renumbered, so pass 6's migration map keeps its keys; where a decided item needed a change with no delta of its own, it went into the closest one below and the row says so.

| # | Change | DDL sketch |
|---|---|---|
| D17 | `signal.evaluation`: replace the undefined number with the defined level; one evaluation per run, student and evaluated week (F40) | `ALTER TABLE signal.evaluation DROP COLUMN strength, DROP COLUMN strength_definition, ADD COLUMN level smallint NOT NULL DEFAULT 0 CHECK (level BETWEEN 0 AND 3), ADD COLUMN breadth smallint NOT NULL DEFAULT 0, ADD COLUMN as_of jsonb NOT NULL DEFAULT '{}'::jsonb, ADD COLUMN backfill_of date, ADD COLUMN trigger_ref jsonb, ADD COLUMN input_hash bytea; ALTER TABLE signal.evaluation DROP CONSTRAINT <pass 1's UNIQUE (school_id, sweep_run_id, student_id)>, ADD CONSTRAINT evaluation_one_per_week UNIQUE NULLS NOT DISTINCT (school_id, sweep_run_id, student_id, backfill_of);` A backfill writes one evaluation per week it covers in one run; nightly and event runs keep one per student (`backfill_of` NULL). No seed row carries `strength` (pass 1 DR-8; §12.11 of the pass 7 review), so nothing is migrated |
| D18 | `signal.signal`: level and polarity in place of `contribution`; the measure and onset; templates; withdrawal | `ALTER TABLE signal.signal DROP COLUMN contribution, ADD COLUMN level smallint NOT NULL CHECK (level BETWEEN 1 AND 3), ADD COLUMN polarity text NOT NULL DEFAULT 'adverse' CHECK (polarity IN ('adverse','positive')), ADD COLUMN measure_key text, ADD COLUMN onset_week date, ADD COLUMN template_key text NOT NULL, ADD COLUMN template_version text NOT NULL, ADD COLUMN withdrawn_reason text;` and a deterministic id policy in the domain layer (`uuid_generate_v5`) |
| D19 | `signal.evidence_item`: same for evidence | `ALTER TABLE signal.evidence_item DROP COLUMN contribution, ADD COLUMN level smallint CHECK (level BETWEEN 1 AND 3), ADD COLUMN polarity text NOT NULL CHECK (polarity IN ('adverse','positive','context')), ADD COLUMN template_key text;` (`evaluation_id`, and `case_id` pointing at a live or a shadow case, are pass 1's since pass 8, F24) |
| D20 | `signal.feature_snapshot`: scale, direction, cadence, phase; fix the method name | `ALTER TABLE signal.feature_snapshot ADD COLUMN scale_key text NOT NULL, ADD COLUMN dir smallint NOT NULL CHECK (dir IN (-1, 1)), ADD COLUMN cadence text NOT NULL CHECK (cadence IN ('per_assessment','weekly','fortnight_block','term')), ADD COLUMN phase text NOT NULL CHECK (phase IN ('cold','self_starting','full')), ADD CONSTRAINT band_method_known CHECK (band_method IN ('personal_median_madn_v1'));` (`features`, and `series` points with their `outside` flag, validated by the engine's JSON schema in the domain layer; the first version's `band` phase is withdrawn with the band-phase cap, F25) |
| D21 | `signal.sweep_run`: deadlines, heartbeat, scope, per-domain as-of, reason; narrow the uniqueness to nightly | `ALTER TABLE signal.sweep_run ADD COLUMN deadline_at timestamptz, ADD COLUMN heartbeat_at timestamptz, ADD COLUMN students_in_scope integer, ADD COLUMN as_of_by_domain jsonb, ADD COLUMN reason text; DROP INDEX signal.sweep_run_one_live_per_date; CREATE UNIQUE INDEX sweep_run_one_nightly_per_date ON signal.sweep_run (school_id, run_date, shadow) WHERE trigger = 'nightly' AND status IN ('running','succeeded','partial') AND supersedes_run_id IS NULL;` |
| D22 | `signal.case`: cold start, the comparison base, holds, and the triggering measures' state at opening | `ALTER TABLE signal.case ADD COLUMN cold_start boolean NOT NULL DEFAULT false, ADD COLUMN tier_yesterday_run_id uuid, ADD COLUMN held_by_hysteresis_at timestamptz, ADD COLUMN triggering_measures text[] NOT NULL DEFAULT '{}', ADD COLUMN triggering_state jsonb NOT NULL DEFAULT '{}'::jsonb;` (`triggering_measures` is `Q*` for recovery, maintained by the engine and, for person-opened cases, by the open transaction; `triggering_state` records, per measure, the chart restart point and the baseline frozen at opening that exit and recovery read, F05; it is the record at opening, not a second copy of anything; shadow cases carry the same columns) |
| D23 | `signal.case_context`: the effect as it was when added | `ALTER TABLE signal.case_context ADD COLUMN effect text NOT NULL CHECK (effect IN ('suppress','soften','inform','route')), ADD COLUMN suppresses text[] NOT NULL DEFAULT '{}';` |
| D24 | `signal.counselor_log` (new, §14.2) | `CREATE TABLE signal.counselor_log (school_id uuid NOT NULL REFERENCES core.school (id), id uuid NOT NULL DEFAULT gen_random_uuid(), counselor_person_id uuid NOT NULL, student_id uuid NOT NULL, day date NOT NULL, reason_key text NOT NULL, prompted_by text NOT NULL, action_key text NOT NULL, note text, would_have_wanted_alert text CHECK (would_have_wanted_alert IN ('yes','no','unsure')), answered_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, counselor_person_id, student_id, day), FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id), FOREIGN KEY (school_id, counselor_person_id) REFERENCES core.person (school_id, id));` protected as class `counselor_log` (pass 4 §3.6). The blind judgements of §14.4 are rows of the same class in the comparison job's own table, which pass 6 places with B4.15 |
| D25 | `signal.v_shadow_queue` (view, §14.1), rewritten by pass 8 (F24, F75) | `CREATE VIEW signal.v_shadow_queue WITH (security_invoker = true) AS SELECT c.school_id, c.student_id, c.id AS case_id, h.changed_at, h.from_tier, h.to_tier AS tier, h.reason, h.evaluation_id, r.id AS sweep_run_id, r.trigger, e.backfill_of FROM signal.case c JOIN signal.case_tier_history h ON h.school_id = c.school_id AND h.case_id = c.id LEFT JOIN signal.evaluation e ON e.school_id = h.school_id AND e.id = h.evaluation_id LEFT JOIN signal.sweep_run r ON r.school_id = e.school_id AND r.id = e.sweep_run_id WHERE c.shadow;` Every tier movement of every shadow case, from nightly, backfill and event runs alike; the comparison job derives each student's tier on each school day as the last movement on or before it. `security_invoker` makes it read under the caller's row-level security, so it shows `signal_shadow` rows only to those pass 4 §3.6 allows |
| D26 | `fairness.group_label` (new, §12.4; pass 4 finalises access and retention). **Unused and empty during the pilot** (C11) | `CREATE SCHEMA fairness; CREATE TABLE fairness.group_label (school_id uuid NOT NULL REFERENCES core.school (id), student_id uuid NOT NULL, dimension text NOT NULL CHECK (dimension IN ('nationality','gender','language_background','sen_status')), value text NOT NULL, import_id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (school_id, student_id, dimension), FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id));` class `fairness_label`; no grant to the application tiers; readable only by the audit job's role; `packages/engine` has a test that it imports nothing from `fairness`; the import refuses a mapping profile with `purpose = 'fairness_audit'` until the pooled audit exists |
| D27 | `config.vocabulary` attribute schemas | `flag_tag`: `{severity: 1..3, safeguarding_relevant: boolean}`; `context_kind`: `{effect, suppresses[], default_valid_days}`; `behaviour_category`: adds `{serious: boolean, urgent: boolean}`; `absence_reason`: `{counts_as, suppresses[]}`; validated by the domain layer on insert; platform defaults seeded from §4.5 and §6.2. The values and the row's `version` (pass 1's `config.vocabulary_history`, F48) are copied into `rule_hits`, `suppressions` and evidence snapshots as `vocabulary_used` |
| D28 | `events.name` rows | `sweep.partial`, `sweep.missed`, `signal.withdrawn`, `signal.superseded`, `tier.held_by_hysteresis`, `tier.held_by_escalation_pin`, `config.domain_disabled`, `config.attendance_released`, `domain.quiet`, `budget.exceeded`, `common_cause.detected`, `case.self_recovered`, `case.auto_reviewed`, `shadow.reveal_recorded`, `shadow.blind_judgement_recorded`, `counselor_log.entry`. `sweep.completed` is not in this list: pass 1 §2.20 seeds it, and a combined seed would fail on the primary key (§12.16) |
| D29 | `core.school.sweep_hour` | `ALTER TABLE core.school ADD COLUMN sweep_hour smallint NOT NULL DEFAULT 2 CHECK (sweep_hour BETWEEN 0 AND 5);` |
| D30 | `auth.data_class` rows | `signal_shadow`, `counselor_log`, `fairness_label` (pass 4's keys; its D33 sets their sensitivity at 3, 3 and 5 and its §3.6 places them in the matrix). The first version's dotted keys are withdrawn |
| D31 | Rule-set JSON schemas | `packages/engine/schemas/{thresholds,suppression,tiering,dimensions}.schema.json`, published with `schema_version`; `config.rule_set_version.params` validated against them in the domain layer before insert. Pass 8 adds to the thresholds schema: `measures.<key>` with register, unit, window, `n_min`, `dir` and floor (F68); `cusum.z_cap`; `attendance.max_level` and `attendance.typical_absence_share`; `band.ordinal_one_step_hold`; `baseline.two_year_carry` with the programme families and subject keys that count as two-year courses (so no column is needed on `sis.subject`, F25). It removes `baseline.min_history_full`, `hysteresis.exit_h_factor` and `common_cause_share` (F25, F05, F26). `ops.common_cause_alert_share` belongs to the alert configuration, not to any engine rule set |
| D32 | The `no second copies` list (pass 1 DR-6) | add `level_cached`, `strength`, `confidence`, `probability_score` |

Tests this pass adds (pass 6 sequences them): the scenario suite (§15.1) and property tests, including the strict no-comparison test, the within-tier ordering test (F50), the pin test (F07) and the vocabulary snapshot test (F48); `engine-reproduces-seed` over both tenants and the CI-only shifted tenant, each against its generated expected-result list; the determinism test; a domain-layer test that an event evaluation cannot lower a tier except on context; a test that a `disabled` domain writes the banner event and that the what-if delta guard fires; a test that the attendance hold cannot be released without a version note citing coverage; a test that no engine template names a regulator; an RLS test that the counselor log and the shadow view are invisible to teachers, students, parents and mentors and to counselors outside the caseload.

---

## Appendix · The calibration simulation

Rewritten by pass 8 (F06). Every computed figure in §2.3, §3.5 to §3.7, §7.3, §11.1 and §14.5 is printed by this script, `calibrate_tiers.py`, published here in full so it can be re-run when a default changes; the case traces of §7.2 and the scenario expectations of §15.1 use its level function one student at a time. It belongs in `packages/engine/tooling/calibrate_tiers.py`, and pass 6's B2.9 accepts the build when the committed script reproduces the output below within rounding. It needs Python 3 and NumPy and nothing else; it was run on 2026-09-24 with NumPy 2.5.0, seed 20260924, in about two minutes. It replaces the first version's appendix, which printed a per-detector script with a different persistence rule from the text's and described a `calibrate_tiers.py` the plan never contained, so pass 7 could not regenerate §11.1 from the plan (F06).

It implements the engine's own level function under the pilot defaults (§3.3 to §3.5): the scale widened by `sqrt(1 + 1/H)`, floors at the full typical noise, the step capped at three inside the CUSUM, one persistence rule, strong shocks through their own rule, attendance in days over fortnight blocks and held at weak, and a simplified case lifecycle with the chart restarted at opening and exit on levels and the mean since opening. Section A is the check that the implementation matches the literature before anything else is trusted: the one-sided run lengths of 335 at `h = 4` and 931 at `h = 5` agree with the published two-sided figures of about 168 and 465.

```python
"""calibrate_tiers.py: pass 3 engine calibration (revised 2026-09-24, pass 8).

Self-contained: Python 3 and NumPy only. Run: python3 calibrate_tiers.py
Every computed figure in pass 3 sections 2.3, 3.5 to 3.7, 7.2, 7.3, 11.1 and 14.5 is
printed by this script (the case traces of 7.2 use its level function one student at a
time), with the seed and settings it ran under. It implements the engine's own level
function (pass 3 section 3.5 as revised) and a simplified case lifecycle
(section 8), under the revised defaults: z capped at 3 inside the CUSUM, one
persistence rule (consecutive weeks of data with the CUSUM signal), scale floors
at the full typical noise, attendance in days over fortnight blocks and held at
weak, strong shocks through their own rule.

What it does not model, stated so nobody reads more into it: teacher concerns,
university rules, relapse, episode exclusion, provisional-week shocks, the
improving guard, autocorrelation and seasonality. Students are independent.
"""
import math
import numpy as np

SEED = 20260924
rng = np.random.default_rng(SEED)

D = dict(W=20, H_BAND=8, C=2.5, Z_SHOCK=3.0, Z_STRONG=5.0, K=0.5, Z_CAP=3.0,
         H=5.0, H_STRONG=8.0, STRONG_MEAN=1.5, PERSIST=3, PERSIST_WEAK=3,
         PERSIST_FREE=3, BREADTH_WEEKS=2, EXIT_WEEKS=2, AUTO_REVIEW_WEEKS=2)


def pct(x):
    return round(100.0 * float(x), 2)


def madn_masked(B, m):
    return 1.4826 * np.nanmedian(np.abs(B - m[:, None]), axis=1)


# ---------------------------------------------------------------- A. ARL check
def arl_one_sided(h, k=0.5, cap=None, states=400):
    """Brook and Evans (1972) Markov-chain ARL of a one-sided CUSUM on N(0,1) increments."""
    Phi = lambda x: 0.5 * (1.0 + math.erf(x / math.sqrt(2.0)))
    F = (lambda x: 1.0 if (cap is not None and x >= cap) else Phi(x))
    w = 2.0 * h / (2 * states - 1)                  # state j stands for S = j*w; the top edge is h
    Q = np.zeros((states, states))
    for i in range(states):
        si = i * w
        Q[i, 0] = F(w / 2 - si + k)
        for j in range(1, states):
            Q[i, j] = F((j + 0.5) * w - si + k) - F((j - 0.5) * w - si + k)
    L = np.linalg.solve(np.eye(states) - Q, np.ones(states))
    return L[0]


# ------------------------------------------ B. per-measure detectors (sigma units)
def detectors_sigma(H, sfl=1.0, fl=1.25, noise="normal", n=200000, M=8, persist=3,
                    cap=3.0, shift=0.0, slope=0.0, old=False):
    """One measure, a quiet (or shifted) student, baseline of H points then M weeks.
    old=True reproduces the first version's rules (no cap, persist 2, P = weeks since onset)."""
    draw = (lambda s: rng.standard_normal(s)) if noise == "normal" else (lambda s: rng.standard_t(3, s))
    base = draw((n, H)); m = np.median(base, 1)
    s = np.maximum(1.4826 * np.median(np.abs(base - m[:, None]), 1), sfl)
    if not old:
        s = s * math.sqrt(1 + 1 / H)
    mon = draw((n, M)) - shift - slope * np.arange(1, M + 1)
    d = m[:, None] - mon; z = d / s[:, None]
    out = (z > D["C"]) & (d >= fl); sh = (z >= D["Z_SHOCK"]) & (d >= fl)
    ss = (z >= D["Z_STRONG"]) & (d >= 2 * fl)
    S = np.zeros(n); P = np.zeros(n); sm = np.zeros(n); ct = np.zeros(n); free = np.zeros(n)
    prev_out = np.zeros(n, bool); lev = np.zeros((n, M), int)
    cross = np.zeros((n, M), bool); pers = np.zeros((n, M), bool)
    for t in range(M):
        zz = z[:, t] if (old or cap is None) else np.minimum(z[:, t], cap)
        newS = np.maximum(0.0, S + zz - D["K"])
        fresh = S == 0
        sm = np.where(fresh, 0.0, sm); ct = np.where(fresh, 0, ct)
        sm = sm + np.where(newS > 0, d[:, t], 0.0); ct = ct + (newS > 0)
        S = newS
        rm = np.where(ct > 0, sm / np.maximum(ct, 1), 0.0)
        sig = (S >= D["H"]) & (rm >= fl)
        if old:
            P = np.where(S > 0, ct, 0)                      # weeks since onset (first version)
            per = sig & (P >= 2)
        else:
            P = np.where(sig, P + 1, 0)                     # consecutive weeks with the signal
            per = P >= persist
        free = np.where(d[:, t] >= 2 * fl, free + 1, 0)
        cross[:, t] = sig; pers[:, t] = per
        l = np.where(out[:, t] | sh[:, t] | sig, 1, 0)
        mod = per | ss[:, t] | (sh[:, t] & prev_out) | (free >= D["PERSIST_FREE"])
        l = np.where(mod, 2, l)
        strong = ((S >= D["H_STRONG"]) & (P >= (3 if old else persist + 1)) & (rm >= D["STRONG_MEAN"] * fl)) \
            | (ss[:, t] & prev_out)
        lev[:, t] = np.where(strong, 3, l)
        prev_out = out[:, t]
    anym = (lev >= 2).any(1)
    first = np.where(anym, (lev >= 2).argmax(1) + 1, np.inf)
    return dict(outside=out[:, -1].mean(), shock=sh[:, -1].mean(), crossing=cross[:, -1].mean(),
                persisted=pers[:, -1].mean(), moderate=(lev[:, -1] >= 2).mean(), first=first,
                scale_free=(free >= D["PERSIST_FREE"]).mean())


def classic_estimated(H=12, h=4.0, M=8, n=200000):
    """Section 2.3's point: a classic CUSUM (no cap, no floor) with its scale estimated from H points."""
    base = rng.standard_normal((n, H)); m = np.median(base, 1)
    s = 1.4826 * np.median(np.abs(base - m[:, None]), 1)
    z = (m[:, None] - rng.standard_normal((n, M))) / s[:, None]
    S = np.zeros(n)
    for t in range(M):
        S = np.maximum(0.0, S + z[:, t] - D["K"])
    return (S >= h).mean()


# ------------------------------------------------------------- E. ordinal check
def ordinal_check(n=100000, H=20, M=8, sd=0.45):
    """Steady IB students: share of graded weeks outside the band (first version against the
    two-assessment hold), and moderate under the revised level function."""
    mu = rng.uniform(4.5, 6.8, n)
    g = np.clip(np.rint(mu[:, None] + sd * rng.standard_normal((n, H + M))), 1, 7)
    base, mon = g[:, :H], g[:, H:]
    m = np.median(base, 1); s = np.maximum(1.4826 * np.median(np.abs(base - m[:, None]), 1), 0.5)
    d = m[:, None] - mon; z = d / s[:, None]
    old_out = (z > 1.5) & (d >= 1)
    held = np.zeros_like(old_out)
    held[:, 1:] = (d[:, 1:] >= 1) & (d[:, :-1] >= 1)
    new_out = ((d >= 2) & (z > 1.5)) | (held & (z > 1.5))
    S = np.zeros(n); P = np.zeros(n); sm = np.zeros(n); ct = np.zeros(n); mod = np.zeros((n, M), bool)
    for t in range(M):
        newS = np.maximum(0.0, S + np.minimum(z[:, t], D["Z_CAP"]) - D["K"])
        fresh = S == 0; sm = np.where(fresh, 0.0, sm); ct = np.where(fresh, 0, ct)
        sm = sm + np.where(newS > 0, d[:, t], 0.0); ct = ct + (newS > 0); S = newS
        rm = np.where(ct > 0, sm / np.maximum(ct, 1), 0.0)
        P = np.where((S >= D["H"]) & (rm >= 1), P + 1, 0)
        mod[:, t] = P >= D["PERSIST"]
    return old_out.mean(), new_out.mean(), mod[:, -1].mean()


# ------------------------------------------------ F. tier-level simulation
HIST, MON, ONSET = 36, 24, 8  # a year of imported history; 24 monitored weeks; a genuine change starts in week 9
T = HIST + MON
NSEC = 6


def gen_students(N, noise, change=None):
    """Native units. change: None (quiet), 'two_domain', 'one_section'."""
    draw = (lambda s: rng.standard_normal(s)) if noise == "normal" else (lambda s: rng.standard_t(3, s))
    onset = HIST + ONSET                                   # the ninth monitored week
    # attainment: six sections, graded in a week with probability 0.5
    mu = rng.uniform(60, 95, (N, NSEC)); sig = 4.0 * np.exp(0.3 * rng.standard_normal((N, NSEC)))
    att = mu[:, :, None] + sig[:, :, None] * draw((N, NSEC, T))
    if change in ("two_domain", "one_section"):
        k = 2 if change == "two_domain" else 1
        att[:, :k, onset:] -= 2.0 * sig[:, :k, None]
    att = np.clip(att, 0, 100)
    att[rng.random((N, NSEC, T)) >= 0.5] = np.nan
    # submission: 2 + Poisson(2) due a week, a point when at least 3 are due
    ndue = 2 + rng.poisson(2.0, (N, T)); pmiss = rng.uniform(0.01, 0.10, N)
    missed = rng.binomial(ndue, pmiss[:, None])
    sub = np.where(ndue >= 3, 100.0 * (ndue - missed) / ndue, np.nan)
    # attendance: day-level episodes, fortnight blocks of ten school days. Half of the
    # ordinary absences carry a suppressing reason (medical); of the rest, 40% are
    # authorised without suppressing and 60% are unexplained. A genuine change adds
    # absence episodes (0.14 of days) that carry no suppressing reason.
    days = T * 5

    def episodes(share, first_day, p_supp):
        miss = np.zeros((N, days), bool); supp = np.zeros((N, days), bool); unex = np.zeros((N, days), bool)
        left = np.zeros(N, int); kind = np.zeros(N, int)
        for dday in range(first_day, days):
            start = (left == 0) & (rng.random(N) < share / 1.7)
            L = rng.choice([1, 2, 3], N, p=[0.5, 0.3, 0.2])
            k = np.where(rng.random(N) < p_supp, 0, np.where(rng.random(N) < 0.4, 1, 2))
            left = np.where(start, L, left); kind = np.where(start, k, kind)
            on = left > 0
            supp[:, dday] = on & (kind == 0); miss[:, dday] = on & (kind > 0); unex[:, dday] = on & (kind == 2)
            left = np.maximum(left - 1, 0)
        return miss, supp, unex

    miss, supp, unex = episodes(rng.uniform(0.01, 0.08, N), 0, 0.5)
    if change == "two_domain":
        m2, _, u2 = episodes(np.full(N, 0.14), onset * 5, 0.0)
        miss |= m2; unex |= u2; supp &= ~m2
    late_share = rng.uniform(0.0, 0.05, N)
    late = (~miss) & (~supp) & (rng.random((N, days)) < late_share[:, None])
    nb = T // 2
    blk = lambda a: a.reshape(N, nb, 10).sum(2)
    reg = 10 - blk(supp)
    dmiss = np.where(reg >= 5, blk(miss).astype(float), np.nan)
    dunex = np.where(reg >= 5, blk(unex).astype(float), np.nan)
    dlate = np.where(reg >= 5, blk(late).astype(float), np.nan)
    # behaviour: weekly negative points
    rate = np.where(rng.random(N) < 0.7, 0.03, 0.25)
    inc = rng.poisson(rate[:, None], (N, T))
    pts = np.zeros((N, T))
    for _ in range(3):
        pts += np.where(inc > _, rng.choice([1, 2, 3], (N, T), p=[0.6, 0.3, 0.1]), 0)
    return dict(att=att, sub=sub, ndue=ndue.astype(float), dmiss=dmiss, reg=reg.astype(float),
                dunex=dunex, dlate=dlate, beh=pts)


def window(X, t, W):
    past = X[:, :t]; valid = ~np.isnan(past)
    rc = np.cumsum(valid[:, ::-1], 1)[:, ::-1]
    inwin = valid & (rc <= W)
    B = np.where(inwin, past, np.nan)
    return B, inwin.sum(1)


class Measure:
    """The engine's per-measure state and level function (section 3.3 to 3.5)."""

    def __init__(self, N, key, domain, floor, weeks_per_point=1, cap_level=3, attainment=False):
        self.key, self.domain, self.floor = key, domain, floor
        self.wpp, self.cap, self.attainment = weeks_per_point, cap_level, attainment
        self.S = np.zeros(N); self.P = np.zeros(N); self.sm = np.zeros(N); self.ct = np.zeros(N)
        self.free = np.zeros(N); self.prev_out = np.zeros(N, bool)
        self.lvl = np.zeros(N, int); self.t_last = np.full(N, -99)
        self.last_out = np.zeros((N, 3), bool)
        self.weakkind = np.zeros(N, bool)          # weak from more than a single outside point
        self.out_now = np.zeros(N, bool)
        self.open_sum = np.zeros(N); self.open_cnt = np.zeros(N); self.post = np.zeros((N, 2), int)
        self.post_n = np.zeros(N, int); self.why = np.zeros(N, int)

    def restart(self, mask):
        self.S[mask] = 0; self.P[mask] = 0; self.sm[mask] = 0; self.ct[mask] = 0
        self.open_sum[mask] = 0; self.open_cnt[mask] = 0; self.post_n[mask] = 0; self.post[mask] = 0

    def step(self, x, m, s, H, t, valid):
        fl = self.floor
        d = np.where(valid, x - m, 0.0) * self.dir
        s_eff = s * np.sqrt(1 + 1 / np.maximum(H, 1))
        z = np.where(valid, d / s_eff, 0.0)
        ok = valid & (H >= 3)
        out = ok & (z > D["C"]) & (d >= fl); sh = ok & (z >= D["Z_SHOCK"]) & (d >= fl)
        ss = ok & (z >= D["Z_STRONG"]) & (d >= 2 * fl)
        newS = np.where(ok, np.maximum(0.0, self.S + np.minimum(z, D["Z_CAP"]) - D["K"]), self.S)
        fresh = ok & (self.S == 0)
        self.sm = np.where(fresh, 0.0, self.sm); self.ct = np.where(fresh, 0, self.ct)
        grow = ok & (newS > 0)
        self.sm = self.sm + np.where(grow, d, 0.0); self.ct = self.ct + grow
        endx = ok & (newS == 0); self.sm[endx] = 0; self.ct[endx] = 0
        self.S = newS
        rm = np.where(self.ct > 0, self.sm / np.maximum(self.ct, 1), 0.0)
        sig = ok & (self.S >= D["H"]) & (rm >= fl)
        self.P = np.where(ok, np.where(sig, self.P + self.wpp, 0), self.P)
        self.free = np.where(ok, np.where(d >= 2 * fl, self.free + 1, 0), self.free)
        two_assess = (self.ct >= 2) if self.attainment else np.ones_like(sig)
        per = sig & (self.P >= D["PERSIST"]) & two_assess
        l = np.where(out | sh | sig, 1, 0)
        mod = per | ss | (sh & self.prev_out) | (self.free >= D["PERSIST_FREE"])
        self.why = np.where(ok, np.select([per, ss, sh & self.prev_out, self.free >= D["PERSIST_FREE"]], [1, 2, 3, 4], 0), self.why)
        l = np.where(mod, 2, l)
        strong = (sig & (self.S >= D["H_STRONG"]) & (self.P >= D["PERSIST"] + 1) & (rm >= D["STRONG_MEAN"] * fl)) \
            | (ss & self.prev_out)
        l = np.where(strong, 3, l)
        l = np.where(H < D["H_BAND"], np.where(ss, np.minimum(l, 2), np.minimum(l, 1)), l)   # self-starting phase
        l = np.minimum(l, self.cap)
        self.last_out = np.where(ok[:, None], np.column_stack([out, self.last_out[:, :2]]), self.last_out)
        two_of_three = self.last_out.sum(1) >= 2
        self.weakkind = np.where(ok, sh | sig | two_of_three, self.weakkind)
        self.out_now = out
        self.prev_out = np.where(ok, out, self.prev_out)
        self.lvl = np.where(ok, l, self.lvl); self.t_last = np.where(ok, t, self.t_last)
        # since the case opened (the chart restarts then): run-mean and the last two levels
        self.open_sum += np.where(ok, d, 0.0); self.open_cnt += ok
        self.post = np.where(ok[:, None], np.column_stack([l, self.post[:, 0]]), self.post)
        self.post_n += ok * self.wpp
        return ok

    def level_now(self, t):
        return np.where(t - self.t_last < D["BREADTH_WEEKS"], self.lvl, 0)

    def exit_ok(self):
        quiet = (self.post_n >= D["EXIT_WEEKS"]) & (self.post[:, 0] == 0) & \
                ((self.post[:, 1] == 0) | (self.wpp >= D["EXIT_WEEKS"]))
        rm = np.where(self.open_cnt > 0, self.open_sum / np.maximum(self.open_cnt, 1), 0.0)
        return quiet & (rm < self.floor)


def simulate_caseload(N, noise, change=None, att_cap=1):
    g = gen_students(N, noise, change)
    ms = []
    for j in range(NSEC):
        mm = Measure(N, f"academic.s{j}", "academic", 5.0, attainment=True); mm.dir = -1; ms.append(mm)
    sub = Measure(N, "academic.submission", "academic", 15.0); sub.dir = -1; ms.append(sub)
    dm = Measure(N, "attendance.days_missed", "attendance", 1.5, weeks_per_point=2, cap_level=att_cap); dm.dir = 1; ms.append(dm)
    be = Measure(N, "behaviour.points", "behaviour", 3.0); be.dir = 1; ms.append(be)
    tier = np.zeros(N, int); nextrev = np.zeros(N, int); nrev = np.zeros(N, int)
    trig = np.zeros((N, len(ms)), bool); set_week = np.zeros(N, int)
    weakhist = np.zeros((N, 3, T), bool); acadweak = np.zeros((N, NSEC, T), bool)
    rule_lvl = np.zeros(N, int); rule_t = np.full(N, -99); floor_used = np.zeros(N, bool)
    entries = np.zeros((MON, 5)); soft = np.zeros(MON); brk = np.zeros(MON); ever = np.zeros((MON, 5))
    reached = np.zeros(N, int); promo8 = np.zeros(MON); causes = np.zeros(8)
    for t in range(HIST, T):
        i = t - HIST
        outs = np.zeros(N, int)
        for j in range(NSEC):                                    # attainment sections
            B, H = window(g["att"][:, j, :], t, D["W"])
            m = np.nanmedian(np.where(H[:, None] > 0, B, 0), 1)
            s = np.maximum(np.nan_to_num(madn_masked(B, m)), 4.0)
            x = g["att"][:, j, t]; ok = ms[j].step(np.nan_to_num(x), m, s, H, t, ~np.isnan(x))
            acadweak[:, j, t] = ok & (ms[j].lvl >= 1); outs += ms[j].out_now
        B, H = window(g["sub"], t, D["W"]); m = np.nanmedian(np.where(H[:, None] > 0, B, 0), 1)
        nw = np.where(~np.isnan(B), g["ndue"][:, :t], np.nan)
        nbar = np.nan_to_num(np.nanmedian(nw, 1), nan=4)
        own = np.nan_to_num(np.nansum(nw * (100 - B) / 100, 1) / np.maximum(np.nansum(nw, 1), 1))
        p = np.maximum(own, 0.05); s = np.maximum(np.nan_to_num(madn_masked(B, m)), 100 * np.sqrt(p * (1 - p) / nbar))
        x = g["sub"][:, t]; sub.step(np.nan_to_num(x), m, s, H, t, ~np.isnan(x)); outs += sub.out_now
        if t % 2 == 1:                                           # a fortnight block closes
            b = t // 2
            B, H = window(g["dmiss"], b, D["W"] // 2); m = np.nanmedian(np.where(H[:, None] > 0, B, 0), 1)
            rw = np.where(~np.isnan(B), g["reg"][:, :b], np.nan)
            nbar = np.nan_to_num(np.nanmedian(rw, 1), nan=10)
            own = np.nan_to_num(np.nansum(B, 1) / np.maximum(np.nansum(rw, 1), 1))
            p = np.maximum(own, 0.05); s = np.maximum(np.nan_to_num(madn_masked(B, m)), np.sqrt(nbar * p * (1 - p)))
            x = g["dmiss"][:, b]; dm.step(np.nan_to_num(x), m, s, H, t, ~np.isnan(x)); outs += dm.out_now
            # lateness and unexplained-days rules on the same block (weak; attendance held at weak)
            fired = np.zeros(N, bool)
            for key, thr in (("dlate", 3), ("dunex", 2)):
                Bk, Hk = window(g[key], b, D["W"] // 2)
                p90 = np.nan_to_num(np.nanpercentile(np.where(Hk[:, None] > 0, Bk, 0), 90, axis=1))
                xk = g[key][:, b]
                fired |= (~np.isnan(xk)) & (np.nan_to_num(xk) >= thr) & (np.nan_to_num(xk) >= p90 + 1)
            rule_lvl = np.where(fired, 1, 0); rule_t = np.where(fired, t, rule_t)
            # policy floor: the year-to-date rate in days under 90% (from the second block of the
            # year), once per term, review at most
            y0 = HIST // 2
            ytd = 1 - (np.nansum(g["dmiss"][:, y0:b + 1], 1) / np.maximum(g["reg"][:, y0:b + 1].sum(1), 1))
            pol = (b >= y0 + 1) & (ytd < 0.90) & ~floor_used; floor_used |= pol
        else:
            pol = np.zeros(N, bool)
        B, H = window(g["beh"], t, D["W"]); m = np.nanmedian(np.where(H[:, None] > 0, B, 0), 1)
        s = np.maximum(np.nan_to_num(madn_masked(B, m)), np.sqrt(np.maximum(np.nan_to_num(np.nanmean(B, 1)), 0.5)))
        be.step(g["beh"][:, t], m, s, H, t, np.ones(N, bool)); outs += be.out_now
        soft[i] = (outs == 1).sum(); brk[i] = (outs >= 2).sum()
        # domain levels, breadth, rows (section 7.2)
        Lm = np.stack([mm.level_now(t) for mm in ms], 1)
        La = Lm[:, :NSEC + 1].max(1)
        La = np.where(acadweak[:, :, max(t - 2, 0):t + 1].any(2).sum(1) >= 3, np.maximum(La, 2), La)
        Lt = np.maximum(Lm[:, NSEC + 1], np.where(t - rule_t < D["BREADTH_WEEKS"], rule_lvl, 0))
        Lb = Lm[:, NSEC + 2]
        L = np.stack([La, Lt, Lb], 1)
        weakhist[:, :, t] = L >= 1
        Mx = L.max(1); n3 = (L == 3).sum(1); n2 = (L >= 2).sum(1)
        persisted = np.stack([(mm.P >= D["PERSIST"]) & (mm.level_now(t) >= 2) for mm in ms], 1).any(1)
        w3 = weakhist[:, :, t - D["PERSIST_WEAK"] + 1:t + 1].all(2).sum(1) >= 2
        weak_kinds = np.stack([mm.weakkind & (mm.level_now(t) >= 1) for mm in ms], 1).any(1)
        prop = np.zeros(N, int)
        rule_now = np.where(t - rule_t < D["BREADTH_WEEKS"], rule_lvl, 0) >= 1
        mon = (Mx == 1) & (weak_kinds | rule_now | ((L >= 1).sum(1) >= 2))
        prop = np.where(mon, 1, prop)
        prop = np.where((Mx == 2) | pol, 2, prop)
        prop = np.where(((n2 >= 2) & persisted) | (n3 >= 1) | w3, 3, prop)
        prop = np.where(n3 >= 2, 4, prop)
        # row 8's promotion rate for a lone severity-3 concern: another domain moderate, or weak two weeks running
        other = (Mx >= 2) | weakhist[:, :, t - 1:t + 1].all(2).any(1)
        promo8[i] = other.mean()
        # the case lifecycle (section 8), simplified
        cur = np.stack([mm.level_now(t) >= 1 for mm in ms], 1)
        opening = (tier == 0) & (prop > 0)
        raising = (tier > 0) & (prop > tier)
        for q in range(5):
            entries[i, q] += ((opening | raising) & (prop == q)).sum()
        if i >= 4:
            er = (opening | raising) & (prop == 2)
            whys = np.stack([np.where(mm.level_now(t) >= 2, mm.why, 0) for mm in ms], 1)
            acad_breadth = acadweak[:, :, max(t - 2, 0):t + 1].any(2).sum(1) >= 3
            causes[0] += (er & pol).sum(); causes[5] += (er & ~pol & acad_breadth & ~(whys > 0).any(1)).sum()
            for c in (1, 2, 3, 4):
                causes[c] += (er & ~pol & (whys == c).any(1)).sum()
        newtrig = (opening | raising)[:, None] & cur & ~trig
        for j, mm in enumerate(ms):
            mm.restart(newtrig[:, j])
        trig |= newtrig
        tier = np.where(opening | raising, prop, tier)
        set_week = np.where(opening | raising, t, set_week)
        nextrev = np.where((opening | raising) & (prop == 1), t + D["AUTO_REVIEW_WEEKS"], nextrev)
        nrev = np.where(opening, 0, nrev)
        ex = np.stack([mm.exit_ok() for mm in ms], 1)
        all_exit = np.where(trig, ex, True).all(1)
        lowering = (tier >= 2) & (prop < tier) & all_exit & (t > set_week)
        newt = np.where(prop > 0, prop, 1)
        nextrev = np.where(lowering & (newt == 1), t + D["AUTO_REVIEW_WEEKS"], nextrev)
        tier = np.where(lowering, newt, tier); set_week = np.where(lowering, t, set_week)
        due = (tier == 1) & (t >= nextrev) & ~(opening | raising)
        quiet = due & ~weakhist[:, :, t - 1:t + 1].any((1, 2))
        nrev = np.where(due & ~quiet, nrev + 1, nrev)
        close = quiet | (due & (nrev >= 3))
        nextrev = np.where(due & ~close, t + D["AUTO_REVIEW_WEEKS"], nextrev)
        tier = np.where(close, 0, tier); trig[close] = False
        if i == ONSET:
            reached[:] = 0                                   # count from the onset of a genuine change
        reached = np.maximum(reached, tier)
        for q in range(5):
            ever[i, q] = (reached >= q).mean()
    return dict(entries=entries, soft=soft, brk=brk, ever=ever, occupancy=np.bincount(tier, minlength=5),
                promo8=promo8, causes=causes)


if __name__ == "__main__":
    print(f"seed {SEED}; defaults {D}")
    print("\nA. Known-parameter one-sided CUSUM ARL, k = 0.5 (Brook and Evans Markov chain, 400 states)")
    for h in (4.0, 5.0):
        print(f"  h = {h}: ARL {arl_one_sided(h):.0f} uncapped; {arl_one_sided(h, cap=3.0):.0f} with z capped at 3")

    print("\nB. Per-measure false alarms per week, quiet student, sigma units, week 8 of monitoring (n = 200,000)")
    print("  noise  H   s_floor floor | outside shock crossing persisted moderate")
    rows = [("normal", 8, 1.0, 1.25), ("normal", 12, 1.0, 1.25), ("normal", 20, 1.0, 1.25),
            ("normal", 20, 1.0, 1.0), ("normal", 20, 0.75, 1.25), ("t3", 12, 1.0, 1.25), ("t3", 20, 1.0, 1.25)]
    for noise, H, sfl, fl in rows:
        r = detectors_sigma(H, sfl, fl, noise)
        print(f"  {noise:6} {H:2}  {sfl:4}  {fl:4}  | {pct(r['outside']):6}% {pct(r['shock']):5}% {pct(r['crossing']):6}% "
              f"{pct(r['persisted']):6}% {pct(r['moderate']):6}%")
    r = detectors_sigma(20, 1.0, 0.5, "normal")
    print(f"  scale-free rule alone, a student whose weekly noise is twice the floor (H 20): {pct(r['scale_free'])}% of weeks; "
          f"at the default floor (1.25 units): {pct(detectors_sigma(20, 1.0, 1.25, 'normal')['scale_free'])}%")
    r = detectors_sigma(12, 0.5, 1.0, "normal", old=True)
    print(f"  first version's rules (H 12, s_floor 0.5, floor 1.0, no cap, P = weeks since onset, persist 2): "
          f"crossing {pct(r['crossing'])}%, crossing with P >= 2 {pct(r['persisted'])}%")

    print("\nC. Detection of a genuine change on one measure, H = 20, revised defaults (n = 100,000)")
    for label, kw in (("shift 1.5 sigma", dict(shift=1.5)), ("shift 2 sigma", dict(shift=2.0)),
                      ("shift 3 sigma", dict(shift=3.0)), ("decline 0.5 sigma a week", dict(slope=0.5)),
                      ("decline 1 sigma a week", dict(slope=1.0)), ("shift 1.5 sigma, t3", dict(shift=1.5, noise="t3"))):
        noise = kw.pop("noise", "normal")
        f = detectors_sigma(20, 1.0, 1.25, noise, n=100000, **kw)["first"]; okk = np.isfinite(f)
        print(f"  {label:26}: moderate within 8 weeks {pct(okk.mean())}%, median delay {np.median(f[okk]):.0f} weeks")

    print("\nD. Section 2.3: classic CUSUM, h = 4, no cap, no floor, scale from 12 points: "
          f"S >= h in {pct(classic_estimated())}% of weeks (known-parameter ARL {arl_one_sided(4.0):.0f})")

    o, nw, om = ordinal_check()
    print(f"\nE. Ordinal (IB 1 to 7, steady, sd 0.45 step, 20-point baseline): graded weeks outside the band "
          f"{pct(o)}% under the first version, {pct(nw)}% with the two-assessment hold; moderate {pct(om)}%")

    print("\nF. Tier-level simulation, native units; 87-student caseloads; means over monitored weeks 5 to 24")

    out = {}

    def quiet(label, R=200, noise="normal", att_cap=1):
        res = simulate_caseload(87 * R, noise, att_cap=att_cap)
        e = res["entries"][4:].mean(0) / R; c = res["causes"] / (MON - 4) / R; o = res["occupancy"] / R
        print(f"  {label}: new items (entries) per week per 87: urgent {e[4]:.2f}, checkin {e[3]:.2f}, "
              f"review {e[2]:.2f} (of which attendance policy floor {c[0]:.2f}, persisted CUSUM {c[1]:.2f}, "
              f"strong shock {c[2]:.2f}, shock after an outside point {c[3]:.2f}, scale-free {c[4]:.2f}, "
              f"academic breadth {c[5]:.2f}), monitor {e[1]:.2f}; soft cells {res['soft'][4:].mean() / R:.1f}, "
              f"break cells {res['brk'][4:].mean() / R:.1f}; occupancy at week 24: checkin or above {o[3:].sum():.2f}, "
              f"review {o[2]:.2f}, monitor {o[1]:.2f}; row 8 promotion chance {pct(res['promo8'][4:].mean())}%")
        out[label] = e

    def genuine(label, change, noise="normal", att_cap=1, N=20000):
        res = simulate_caseload(N, noise, change, att_cap=att_cap)
        wks = (2, 4, 6, 8, 10, 12, 16)
        rv = [round(pct(res["ever"][ONSET + w - 1, 2])) for w in wks]; ck = [round(pct(res["ever"][ONSET + w - 1, 3])) for w in wks]
        print(f"  {label}: % reached review or above by weeks {wks} after onset {rv}; checkin or above {ck}")
        out[label] = (res["ever"][ONSET + 7, 2], res["ever"][ONSET + 7, 3])

    quiet("quiet, normal noise, pilot defaults")
    quiet("quiet, t3 noise, pilot defaults", noise="t3")
    genuine("genuine two-domain change, normal", "two_domain")
    genuine("genuine two-domain change, t3", "two_domain", noise="t3")
    genuine("genuine one-section change, normal", "one_section")
    genuine("genuine one-section change, t3", "one_section", noise="t3")
    print("  Levers, normal noise:")
    quiet("    attendance released to strong (after the hold)", R=100, att_cap=3)
    genuine("    attendance released: genuine two-domain", "two_domain", att_cap=3)
    D["PERSIST"] = 2
    quiet("    persist 2 (attendance held)", R=100)
    genuine("    persist 2: genuine two-domain", "two_domain")
    D["PERSIST"] = 3

    print("\nG. Expected precision proxy (planning arithmetic, not a measurement): one genuine episode a week per 87")
    print("   (section 1.3), half of them two-domain and half one-section; counted if reached within 8 weeks")
    for noise in ("normal", "t3"):
        e = out[f"quiet, {noise} noise, pilot defaults"]
        g2 = out[f"genuine two-domain change, {noise}"]; g1 = out[f"genuine one-section change, {noise}"]
        g_rev = 0.5 * g2[0] + 0.5 * g1[0]; g_chk = 0.5 * g2[1] + 0.5 * g1[1]
        n_rev = e[2] + e[3] + e[4]; n_chk = e[3] + e[4]
        print(f"  {noise}: review or above: genuine {g_rev:.2f} a week against noise {n_rev:.2f}, precision about "
              f"{pct(g_rev / (g_rev + n_rev))}%; checkin or above: genuine {g_chk:.2f} against noise {n_chk:.2f}, "
              f"precision about {pct(g_chk / (g_chk + n_chk))}%; school-wide at about 350 students (4 caseloads), "
              f"review-or-above entries about {4 * (g_rev + n_rev):.1f} a week")
```

Output of the run on 2026-09-24:

```text
seed 20260924; defaults {'W': 20, 'H_BAND': 8, 'C': 2.5, 'Z_SHOCK': 3.0, 'Z_STRONG': 5.0, 'K': 0.5, 'Z_CAP': 3.0, 'H': 5.0, 'H_STRONG': 8.0, 'STRONG_MEAN': 1.5, 'PERSIST': 3, 'PERSIST_WEAK': 3, 'PERSIST_FREE': 3, 'BREADTH_WEEKS': 2, 'EXIT_WEEKS': 2, 'AUTO_REVIEW_WEEKS': 2}

A. Known-parameter one-sided CUSUM ARL, k = 0.5 (Brook and Evans Markov chain, 400 states)
  h = 4.0: ARL 335 uncapped; 346 with z capped at 3
  h = 5.0: ARL 931 uncapped; 974 with z capped at 3

B. Per-measure false alarms per week, quiet student, sigma units, week 8 of monitoring (n = 200,000)
  noise  H   s_floor floor | outside shock crossing persisted moderate
  normal  8   1.0  1.25  |   0.54%  0.12%   1.12%   0.42%   0.42%
  normal 12   1.0  1.25  |   0.56%  0.11%   0.65%   0.23%   0.23%
  normal 20   1.0  1.25  |   0.48%  0.09%   0.39%   0.11%   0.11%
  normal 20   1.0   1.0  |   0.49%   0.1%   0.49%   0.14%   0.15%
  normal 20  0.75  1.25  |    1.4%  0.51%   0.58%   0.19%   0.21%
  t3     12   1.0  1.25  |   3.15%   2.0%   1.97%   0.73%    1.3%
  t3     20   1.0  1.25  |   3.21%  2.08%   1.55%   0.52%   1.11%
  scale-free rule alone, a student whose weekly noise is twice the floor (H 20): 0.71% of weeks; at the default floor (1.25 units): 0.0%
  first version's rules (H 12, s_floor 0.5, floor 1.0, no cap, P = weeks since onset, persist 2): crossing 2.79%, crossing with P >= 2 2.78%

C. Detection of a genuine change on one measure, H = 20, revised defaults (n = 100,000)
  shift 1.5 sigma           : moderate within 8 weeks 51.8%, median delay 7 weeks
  shift 2 sigma             : moderate within 8 weeks 84.15%, median delay 6 weeks
  shift 3 sigma             : moderate within 8 weeks 99.71%, median delay 4 weeks
  decline 0.5 sigma a week  : moderate within 8 weeks 91.03%, median delay 7 weeks
  decline 1 sigma a week    : moderate within 8 weeks 100.0%, median delay 4 weeks
  shift 1.5 sigma, t3       : moderate within 8 weeks 45.5%, median delay 6 weeks

D. Section 2.3: classic CUSUM, h = 4, no cap, no floor, scale from 12 points: S >= h in 7.9% of weeks (known-parameter ARL 335)

E. Ordinal (IB 1 to 7, steady, sd 0.45 step, 20-point baseline): graded weeks outside the band 17.48% under the first version, 5.04% with the two-assessment hold; moderate 0.28%

F. Tier-level simulation, native units; 87-student caseloads; means over monitored weeks 5 to 24
  quiet, normal noise, pilot defaults: new items (entries) per week per 87: urgent 0.00, checkin 0.01, review 0.51 (of which attendance policy floor 0.16, persisted CUSUM 0.03, strong shock 0.17, shock after an outside point 0.10, scale-free 0.04, academic breadth 0.00), monitor 4.15; soft cells 8.4, break cells 0.3; occupancy at week 24: checkin or above 0.09, review 1.26, monitor 15.38; row 8 promotion chance 5.86%
  quiet, t3 noise, pilot defaults: new items (entries) per week per 87: urgent 0.00, checkin 0.08, review 1.83 (of which attendance policy floor 0.15, persisted CUSUM 0.07, strong shock 1.33, shock after an outside point 0.18, scale-free 0.07, academic breadth 0.05), monitor 5.14; soft cells 13.2, break cells 1.0; occupancy at week 24: checkin or above 0.70, review 8.69, monitor 23.41; row 8 promotion chance 12.27%
  genuine two-domain change, normal: % reached review or above by weeks (2, 4, 6, 8, 10, 12, 16) after onset [12, 28, 43, 56, 66, 73, 83]; checkin or above [0, 2, 5, 9, 14, 20, 30]
  genuine two-domain change, t3: % reached review or above by weeks (2, 4, 6, 8, 10, 12, 16) after onset [23, 40, 55, 66, 75, 81, 88]; checkin or above [1, 4, 8, 12, 17, 22, 31]
  genuine one-section change, normal: % reached review or above by weeks (2, 4, 6, 8, 10, 12, 16) after onset [5, 10, 15, 20, 24, 27, 32]; checkin or above [0, 0, 1, 1, 1, 2, 4]
  genuine one-section change, t3: % reached review or above by weeks (2, 4, 6, 8, 10, 12, 16) after onset [15, 23, 30, 37, 42, 47, 54]; checkin or above [1, 1, 2, 2, 3, 4, 6]
  Levers, normal noise:
      attendance released to strong (after the hold): new items (entries) per week per 87: urgent 0.00, checkin 0.03, review 0.62 (of which attendance policy floor 0.15, persisted CUSUM 0.04, strong shock 0.24, shock after an outside point 0.13, scale-free 0.04, academic breadth 0.00), monitor 4.07; soft cells 8.4, break cells 0.3; occupancy at week 24: checkin or above 0.15, review 1.71, monitor 16.17; row 8 promotion chance 6.07%
      attendance released: genuine two-domain: % reached review or above by weeks (2, 4, 6, 8, 10, 12, 16) after onset [18, 38, 55, 66, 75, 82, 89]; checkin or above [1, 6, 12, 17, 24, 30, 41]
      persist 2 (attendance held): new items (entries) per week per 87: urgent 0.00, checkin 0.01, review 0.57 (of which attendance policy floor 0.17, persisted CUSUM 0.06, strong shock 0.19, shock after an outside point 0.10, scale-free 0.05, academic breadth 0.00), monitor 4.11; soft cells 8.3, break cells 0.3; occupancy at week 24: checkin or above 0.08, review 1.59, monitor 16.04; row 8 promotion chance 5.95%
      persist 2: genuine two-domain: % reached review or above by weeks (2, 4, 6, 8, 10, 12, 16) after onset [12, 29, 45, 59, 70, 77, 86]; checkin or above [0, 2, 5, 10, 15, 21, 31]

G. Expected precision proxy (planning arithmetic, not a measurement): one genuine episode a week per 87
   (section 1.3), half of them two-domain and half one-section; counted if reached within 8 weeks
  normal: review or above: genuine 0.38 a week against noise 0.52, precision about 42.08%; checkin or above: genuine 0.05 against noise 0.01, precision about 78.41%; school-wide at about 350 students (4 caseloads), review-or-above entries about 3.6 a week
  t3: review or above: genuine 0.51 a week against noise 1.91, precision about 21.2%; checkin or above: genuine 0.07 against noise 0.08, precision about 48.02%; school-wide at about 350 students (4 caseloads), review-or-above entries about 9.7 a week
```

What it leaves out is stated in its docstring: teacher concerns, university rules, relapse, episode exclusion, provisional-week shocks, the improving guard, autocorrelation and seasonality. The first four only add cases of their own kinds; the last two will make real noise somewhat worse than these figures, which is what the shadow period measures.

---

## Sources

All retrieved or verified 2026-09-23. Re-checked by pass 8 on 2026-09-24 (F69): four attributed facts corrected (Balfanz, Herzog and Mac Iver; Faria et al.; AEI; the SigmaXL figure), citations completed, and the sources the pass 7 review could not reach re-found where possible; for the rest this list relies on the pass 7 citation register (`07-review.md` §A.6), which verified them. Grouped by the section that relies on them.

**Early warning indicators and attendance (§2.1)**
- Balfanz, R., Herzog, L. and Mac Iver, D. J. (2007). Preventing student disengagement and keeping students on the graduation path in urban middle-grades schools: Early identification and effective interventions. *Educational Psychologist*, 42(4), 223–235. Re-read 2026-09-24: the 60% is for four indicators (poor attendance, misbehaviour as a poor final behaviour mark, failure in mathematics, failure in English); the 77% and the 12,972 students are in the text. PDF: https://new.every1graduates.org/wp-content/uploads/2012/03/preventing_student_disengagement.pdf ; ERIC: https://eric.ed.gov/?id=EJ780922
- Allensworth, E. M. and Easton, J. Q. (2005). *The On-Track Indicator as a Predictor of High School Graduation*. Consortium on Chicago School Research. https://consortium.uchicago.edu/publications/track-indicator-predictor-high-school-graduation
- Allensworth, E. M. and Easton, J. Q. (2007). *What Matters for Staying On-Track and Graduating in Chicago Public High Schools*. Consortium on Chicago School Research. https://consortium.uchicago.edu/publications/what-matters-staying-track-and-graduating-chicago-public-schools ; ERIC: https://eric.ed.gov/?id=ED498350
- Bowers, A. J., Sprott, R. and Taff, S. A. (2013). Do we know who will drop out? A review of the predictors of dropping out of high school: Precision, sensitivity, and specificity. *The High School Journal*, 96(2), 77–100. ERIC: https://eric.ed.gov/?id=EJ995291 (the first version could not retrieve the abstract; the pass 7 review confirmed it: the on-track indicator performed best among cross-sectional flags)
- Faria, A. M., Sorensen, N., Heppen, J., Bowdon, J., Taylor, S., Eisner, R. and Foster, S. (2017). *Getting students on track for graduation: Impacts of the Early Warning Intervention and Monitoring System after one year* (REL 2017-272). IES, REL Midwest. Summary page re-read 2026-09-24: chronic absence 10% against 14%, one or more course failures 21% against 26%, no detectable effect on low GPA, suspension or insufficient credits; the effect sizes −0.26 and −0.17 are from the report's primary model per the pass 7 review. https://ies.ed.gov/use-work/resource-library/report/impact-study/getting-students-track-graduation-impacts-early-warning-intervention-and-monitoring-system-after-one ; PDF: https://nces.ed.gov/sites/default/files/migrated/rel/regions/midwest/pdf/REL_2017272.pdf
- Knowles, J. E. (2015). Of needles and haystacks: Building an accurate statewide dropout early warning system in Wisconsin. *Journal of Educational Data Mining*, 7(3), 18–67. https://jedm.educationaldatamining.org/index.php/JEDM/article/view/JEDM082
- Anderson, H., Boodhwani, A. and Baker, R. S. (2019). Assessing the fairness of graduation predictions. *Proceedings of the 12th International Conference on Educational Data Mining*. https://learninganalytics.upenn.edu/ryanbaker/EDM2019_paper56.pdf
- Balfanz, R. and Byrnes, V. (2012). *The Importance of Being in School: A Report on Absenteeism in the Nation's Public Schools*. Johns Hopkins University. https://new.every1graduates.org/wp-content/uploads/2012/05/FINALChronicAbsenteeismReport_May16.pdf ; U.S. Department of Education, Chronic Absenteeism: https://www.ed.gov/teaching-and-administration/supporting-students/chronic-absenteeism
- McIntosh, K., Frank, J. L. and Spaulding, S. A. (2010). Establishing research-based trajectories of office discipline referrals for individual students. *School Psychology Review*, 39(3), 380–394. https://doi.org/10.1080/02796015.2010.12087759
- Markowitz, D. M., Kittelman, A., Girvan, E. J., Santiago-Rosario, M. R. and McIntosh, K. (2023). Taking note of our biases: How language patterns reveal bias underlying the use of office discipline referrals in exclusionary discipline. *Educational Researcher*, 52(9), 525–534. https://journals.sagepub.com/doi/abs/10.3102/0013189X231189444
- Hollon, S., Malkus, N., Lenhoff, S. W. and Singer, J. (22 October 2025). *What Stories Does Daily Attendance Tell? Student Attendance Patterns Before and After the COVID-19 Pandemic*. American Enterprise Institute. https://www.aei.org/research-products/report/what-stories-does-daily-attendance-tell-student-attendance-patterns-before-and-after-the-covid-19-pandemic/ (re-read 2026-09-24: absences rise over the autumn, peak in winter, stay near peak through the spring, rise in June, and are notably higher before holidays)
- American Enterprise Institute. *Please Excuse My Child: Unexcused Absences in Student Attendance and Achievement*. https://www.aei.org/research-products/report/please-excuse-my-child-unexcused-absences-in-student-attendance-and-achievement/ (its seasonal statistic is the unexcused share of all absences, 35% in August 2023 to 55% in May 2024; corrected by pass 8, F69)
- Macfadyen, L. P. and Dawson, S. (2010). Mining LMS data to develop an "early warning system" for educators: A proof of concept. *Computers & Education*, 54(2), 588–599. https://www.sciencedirect.com/science/article/abs/pii/S0360131509002486 (cohort-level; cited for the engagement domain's provenance only)

**Teacher recognition (§2.2)**
- Splett, J. W., Garzona, M., Gibson, N., Wojtalewicz, D., Raborn, A. and Reinke, W. M. (2019). Teacher recognition, concern, and referral of children's internalizing and externalizing behavior problems. *School Mental Health*, 11, 228–239. https://link.springer.com/article/10.1007/s12310-018-09303-z
- Dowdy, E., Doane, K., Eklund, K. and Dever, B. V. (2013). A comparison of teacher nomination and screening to identify behavioral and emotional risk within a sample of underrepresented students. *Journal of Emotional and Behavioral Disorders*, 21, 127–137. https://journals.sagepub.com/doi/10.1177/1063426611417627
- Eklund, K., Renshaw, T., Dowdy, E., Jimerson, S., Hart, S. R., Jones, C. N. et al. (2009). Early identification of behavioral and emotional problems in youth: Universal screening versus teacher-referral identification. *The California School Psychologist*, 14, 89–95 (the journal was later renamed *Contemporary School Psychology*, under which Springer now lists it; corrected by pass 8 from the pass 7 register). https://link.springer.com/article/10.1007/BF03340954

**Statistics (§2.3, §3)**
- Hampel, F. R. (1974). The influence curve and its role in robust estimation. *Journal of the American Statistical Association*, 69(346), 383–393. https://www.tandfonline.com/doi/abs/10.1080/01621459.1974.10482962
- Leys, C., Ley, C., Klein, O., Bernard, P. and Licata, L. (2013). Detecting outliers: Do not use standard deviation around the mean, use absolute deviation around the median. *Journal of Experimental Social Psychology*, 49(4), 764–766. https://www.sciencedirect.com/science/article/pii/S0022103113000668
- Iglewicz, B. and Hoaglin, D. C. (1993). *How to Detect and Handle Outliers*. ASQC Basic References in Quality Control, vol. 16.
- Rousseeuw, P. J. and Croux, C. (1993). Alternatives to the median absolute deviation. *Journal of the American Statistical Association*, 88(424), 1273–1283. https://www.tandfonline.com/doi/abs/10.1080/01621459.1993.10476408
- Page, E. S. (1954). Continuous inspection schemes. *Biometrika*, 41(1/2), 100–115. https://academic.oup.com/biomet/article-abstract/41/1-2/100/456627
- Brook, D. and Evans, D. A. (1972). An approach to the probability distribution of cusum run length. *Biometrika*, 59(3), 539–549. https://academic.oup.com/biomet/article/59/3/539/484836
- Hawkins, D. M. (1987). Self-starting cusum charts for location and scale. *The Statistician*, 36, 299–316. https://rss.onlinelibrary.wiley.com/doi/10.2307/2348827
- Hawkins, D. M. and Olwell, D. H. (1998). *Cumulative Sum Charts and Charting for Quality Improvement*. Springer. https://link.springer.com/book/10.1007/978-1-4612-1686-5 (re-found 2026-09-24)
- Quesenberry, C. P. (1991). SPC Q charts for start-up processes and short or long runs. *Journal of Quality Technology*, 23(3), 213–224. https://www.tandfonline.com/doi/abs/10.1080/00224065.1991.11979327
- Roberts, S. W. (1959). Control chart tests based on geometric moving averages. *Technometrics*, 1(3), 239–250. https://www.tandfonline.com/doi/abs/10.1080/00401706.1959.10489860
- Lucas, J. M. and Saccucci, M. S. (1990). Exponentially weighted moving average control schemes: Properties and enhancements. *Technometrics*, 32(1), 1–12.
- Borror, C. M., Montgomery, D. C. and Runger, G. C. (1999). Robustness of the EWMA control chart to non-normality. *Journal of Quality Technology*, 31(3), 309–316. https://www.tandfonline.com/doi/abs/10.1080/00224065.1999.11979929
- Lucas, J. M. (1985). Counted data CUSUM's. *Technometrics*, 27(2), 129–144. https://www.tandfonline.com/doi/abs/10.1080/00401706.1985.10488030
- Borror, C. M., Champ, C. W. and Rigdon, S. E. (1998). Poisson EWMA control charts. *Journal of Quality Technology*, 30(4), 352–361. https://www.tandfonline.com/doi/abs/10.1080/00224065.1998.11979871
- Western Electric Company (1956). *Statistical Quality Control Handbook* (re-found 2026-09-24 as a WorldCat record and in secondary descriptions of its run rules; the handbook itself was not read); Nelson, L. S. (1984). The Shewhart control chart: Tests for special causes. *Journal of Quality Technology*, 16(4), 237–239. https://www.tandfonline.com/doi/abs/10.1080/00224065.1984.11978921
- Sen, P. K. (1968). Estimates of the regression coefficient based on Kendall's tau. *Journal of the American Statistical Association*, 63(324), 1379–1389. https://www.tandfonline.com/doi/abs/10.1080/01621459.1968.10480934
- Killick, R., Fearnhead, P. and Eckley, I. A. (2012). Optimal detection of changepoints with a linear computational cost. *Journal of the American Statistical Association*, 107(500), 1590–1598. https://www.tandfonline.com/doi/abs/10.1080/01621459.2012.737745
- Truong, C., Oudre, L. and Vayatis, N. (2020). Selective review of offline change point detection methods. *Signal Processing*, 167, 107299. https://arxiv.org/abs/1801.00718
- Adams, R. P. and MacKay, D. J. C. (2007). Bayesian online changepoint detection. arXiv:0710.3742. https://arxiv.org/abs/0710.3742 (re-found 2026-09-24)
- NIST/SEMATECH *e-Handbook of Statistical Methods*: CUSUM control charts (§6.3.2.3) https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc323.htm ; EWMA control charts (§6.3.2.4) https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm
- SigmaXL, Tabular CUSUM reference: https://www.sigmaxl.com/TabularCUSUM.html (describes the tabular method; it does not state the in-control run length of about 465 at k = 0.5, h = 5, which the first version attributed to it; the figure is computed in the appendix, section A, and agrees with the pass 7 review's recomputation)

**Alert fatigue and human response to alarms (§1.3, §2.4)**
- van der Sijs, H., Aarts, J., Vulto, A. and Berg, M. (2006). Overriding of drug safety alerts in computerized physician order entry. *Journal of the American Medical Informatics Association*, 13(2), 138–147. https://academic.oup.com/jamia/article-abstract/13/2/138/729701
- Kesselheim, A. S., Cresswell, K., Phansalkar, S., Bates, D. W. and Sheikh, A. (2011). Clinical decision support systems could be modified to reduce 'alert fatigue' while still minimizing the risk of litigation. *Health Affairs*, 30(12), 2310–2317. https://www.healthaffairs.org/doi/abs/10.1377/hlthaff.2010.1111
- Ancker, J. S., Edwards, A., Nosal, S., Hauser, D., Mauer, E., Kaushal, R. and the HITEC Investigators (2017). Effects of workload, work complexity, and repeated alerts on alert fatigue in a clinical decision support system. *BMC Medical Informatics and Decision Making*, 17, 36. https://doi.org/10.1186/s12911-017-0430-8 (abstract retrieved through Europe PMC)
- Drew, B. J. et al. (2014). Insights into the problem of alarm fatigue with physiologic monitor devices: A comprehensive observational study of consecutive intensive care unit patients. *PLOS ONE*, 9(10), e110274. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0110274
- Bliss, J. P., Gilson, R. D. and Deaton, J. E. (1995). Human probability matching behaviour in response to alarms of varying reliability. *Ergonomics*, 38(11), 2300–2312. https://www.tandfonline.com/doi/abs/10.1080/00140139508925269
- Parasuraman, R. and Riley, V. (1997). Humans and automation: Use, misuse, disuse, abuse. *Human Factors*, 39(2), 230–253. https://journals.sagepub.com/doi/10.1518/001872097778543886
- Pauker, S. G. and Kassirer, J. P. (1980). The threshold approach to clinical decision making. *New England Journal of Medicine*, 302(20), 1109–1117. https://www.nejm.org/doi/abs/10.1056/NEJM198005153022003

**Base rates and context (§1.3, §4.7)**
- World Health Organization. *Mental health of adolescents* (fact sheet, updated 2025). https://www.who.int/news-room/fact-sheets/detail/adolescent-mental-health
- Burcusa, S. L. and Iacono, W. G. (2007). Risk for recurrence in depression. *Clinical Psychology Review*, 27(8), 959–985. https://pmc.ncbi.nlm.nih.gov/articles/PMC2169519/ (cited as an analogy only)
- American School Counselor Association, School Counselor Roles & Ratios (recommended 250:1; 2024–25 national average 372:1). https://www.schoolcounselor.org/about-school-counseling/school-counselor-roles-ratios
- The National (7 Dec 2021), UAE school week to shift in line with weekend change; Khaleej Times, Abu Dhabi private schools notified about change in timings (Monday-to-Friday week from January 2022). https://www.thenationalnews.com/uae/2021/12/07/uae-school-week-to-shift-in-line-with-new-saturday-sunday-weekend/ ; https://www.khaleejtimes.com/schooling-in-uae/new-uae-weekend-abu-dhabi-private-schools-notified-about-change-in-timings (The National's article re-found 2026-09-24: schools moved to a Monday-to-Friday week, Friday a half day, from January 2022; the Khaleej Times link was not re-checked. The weekend remains a tenant field, `core.school.weekend_days`, in pass 1)

**Fairness and the data needed to test it (§12)**
- Hardt, M., Price, E. and Srebro, N. (2016). Equality of opportunity in supervised learning. *NeurIPS 2016*. https://arxiv.org/abs/1610.02413
- Chouldechova, A. (2017). Fair prediction with disparate impact: A study of bias in recidivism prediction instruments. *Big Data*, 5(2), 153–163. https://arxiv.org/abs/1703.00056
- 29 CFR § 1607.4(D), Uniform Guidelines on Employee Selection Procedures (1978), the four-fifths rule. https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XIV/part-1607/subject-group-ECFRdb347e844acdea6/section-1607.4
- UAE Federal Decree-Law No. 45 of 2021 on the Protection of Personal Data, Article 1 (definition of sensitive personal data; racial or ethnic origin and health confirmed, nationality not confirmed as a listed category, per the pass 7 register). https://uaelegislation.gov.ae/en/legislations/1972/download
- Regulation (EU) 2024/1689 (Artificial Intelligence Act), Article 10(5). https://artificialintelligenceact.eu/article/10/ ; Official Journal text: https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?uri=OJ%3AL_202401689

**Not retrievable, stated as such.** The full text of Bowers, Sprott and Taff (2013) (its abstract was confirmed by the pass 7 review); the Lucas and Saccucci (1990) design tables were not retrieved and no `(λ, L)` pair is quoted from them; the Western Electric handbook itself. No figure in this document rests on a source that could not be reached; where a planning figure has no source (a typical absence share of 5%, a typical per-assessment noise of four points, a grading frequency of one week in two), it is labelled an assumption where it is used.

---

## Challenges

Each names the decision or invariant touched, states the alternative, what it costs and buys, and what this pass planned on.

**C1 · "Overnight batch" is kept as the ritual and extended with an event path.** *Decision: signal engine timing.* Argued in full in §7.5. The alternative is nightly only; it costs a school day on the safeguarding pattern and the teacher's loop, and buys nothing the asymmetry rules do not also buy. Planned on the hybrid; the nightly run alone computes "what changed overnight".

**C2 · The engagement domain ships disabled.** *Decision: signal engine method (the six domains).* The prototype measures a minor's platform activity, including activity after 01:00. The alternative is to ship it on with a disclosure. It costs the pilot one of Layla's two signals until pass 4 rules; it buys not building a surveillance measure before anyone has decided it is permissible. Planned on: designed in full (§4.3), off by default, the night-activity measure not built.

**C3 · Two numbers the prototype shows are removed rather than defined.** *Invariant 3, "every number a user sees traces to a source".* Signal strength and confidence are removed (§9). The alternative is to define signal strength as a monotone function of level, breadth and persistence and keep the meter. It would be a number with a definition and no meaning a counselor could use, and the confidence percentage cannot be defined at all before a backtest. The frozen demo will keep showing both; the demo script should not read them aloud, and the Next.js rebuild prints the level, the window and the breadth.

**C4 · A known family circumstance no longer lowers a case.** *Prototype behaviour changed.* The prototype's context picker reduces the score for "family circumstance noted: pastoral route". This plan treats risk-adding context as `inform` or `route`, never `suppress` (§6.2), on the argument that a known difficulty is a reason for attention. The school can flip the attribute, visibly. Listed because it changes a demonstrated behaviour.

**C5 · The common-cause guard sits next to invariant 2.** *Closed 2026-09-24 by F26:* the automatic cap is withdrawn, because it made a student's level depend on data about other students, which invariant 2 forbids whatever the intent. What remains is an operations count and a prompt to the school to declare a `calendar_period`, which then suppresses through the calendar for everyone alike (§7.6). The cost the first version named stands: an undeclared school-wide event can open many attendance cases on one morning, and with attendance held at weak those are `monitor` rows until the period is declared and a re-run applies it.

**C6 · Thresholds are per school, not per counselor.** *Decision: "counselors must be able to configure what they consider urgent".* Read as the counseling team, not each counselor (§10.2). The alternative, per-counselor thresholds, costs a tier that means four things and a student who changes tier when reassigned. If the elicitation shows irreconcilable disagreement, per-counselor overrides become an open decision rather than a default.

**C7 · The engine proposes `urgent` for the corroboration pattern.** *Invariant 5.* Some safeguarding leads want a system that never says "urgent" and leaves the routing entirely to the counselor. The tiering row is data and the elicitation's Part E asks; the default proposes, because the prototype's Tariq is the case the product is sold on. Since pass 8 a teacher who suspects harm does not rely on this row at all: a `safeguarding` flag goes straight to the school's route as a referral (F10, §4.5).

**C8 · `persist` changes meaning.** The prototype's single slider ("consecutive weeks a weak signal must repeat before it escalates", default 3) becomes `persist_weak` (unchanged at 3) and a new `persist` for moderate levels. A counselor who read the old slider will find two. Revised by pass 8: decision C9 sets `persist` to 3 for the pilot, so the two are equal by default; they stay separate settings because they answer different questions (how long one measure's shift must hold, and how long two weak domains must coincide), and shadow tunes them separately.

**C9 · Monitor churn.** The first version reported fourteen to thirty quiet monitor cases a week on a caseload of 87, from a setup it did not publish. Under the pilot defaults the published calibration gives 4.15 new monitor cases a week per 87 under normal noise and 5.14 under heavy tails, with about 15 to 23 open at a time (§11.1). The prototype's own copy for a quiet file ("the engine is watching, and will open a case if that changes") argues for fewer still. Planned on `shock_opens_monitor = true` because the prototype shows the single-outlier case (Yousef) as a monitor case, with the parameter exposed and the count reported in shadow mode.

**C10 · Weekly delivery changes what "within 2 school days" promises.** Already stated by pass 2; restated because it is the engine's SLA: under the weekly pack the clock starts at the Monday commit and the case shows both dates. The alternative is to hide the observation date, which would make the engine look faster than the data.

**C11 · The pilot defaults are slow, and the prototype's strongest stories are the ones they cost.** *Decision C9 (2026-09-24), planned on as given.* Detuning before the pilot (day-level attendance, floors at the full typical noise, three weeks of persistence, attendance held at weak) makes the action tiers almost silent on series data: under normal noise 0.01 noise check-ins a week per 87, and a corroborated two-domain change reaching `checkin` within eight weeks 9% of the time, `review` 56% of the time (§11.1). On the authored day Ahmed lands at `checkin` rather than `urgent`, Priya at `review` rather than `checkin`, and Hana's relapse does not fire (§7.2). The alternative, pass 7's position A, keeps sensitive defaults and tunes in shadow; it buys earlier detection at the cost of shadow weeks dominated by noise the plan already predicts, and Davide chose against it. The plan therefore says plainly that during the pilot the action tiers will be filled mostly by teacher corroboration, the university rules and relapse, measures detection as well as noise in shadow (§14.3), and names the levers in order (§11.1). Whether the relapse rule should fire on a weak level while attendance is held is open decision 21.

---

## Open decisions

| # | Decision | Options | Recommendation | Who decides |
|---|---|---|---|---|
| 1 | Event-triggered evaluation for teacher flags, context and enrolment changes | (a) nightly only; (b) hybrid with the daytime asymmetry (§7.5) | (b) | Davide; ACS counselors on whether daytime raises are welcome |
| 2 | Engagement domain | (a) off until pass 4 and the school's disclosure; (b) on from the pilot with CAROS activity only; (c) on with Google Classroom | (a), then (c) if pass 4 permits | pass 4, ACS (question 14 in ACS-IT-QUESTIONS.md) |
| 3 | Signal strength and confidence | (a) removed, level and breadth shown (§9); (b) a defined composite score kept as a meter | (a) | Davide |
| 4 | Relapse uplift | 0, 1 (default) or 2 tiers | 1; the prototype's Hana is urgent only at 2 | ACS counselors (vignette 11) |
| 5 | Common-cause guard | on at 25%; off (100%) | **Closed 2026-09-24 by F26**: the automatic cap is withdrawn; the operations count and the prompt to declare a calendar period remain (§7.6) | Davide (decided) |
| 6 | Whether the engine may propose `urgent` for corroboration | proposes; stops at `checkin` with a route flag | proposes | ACS CPO and counselors (Part E) |
| 7 | Threshold scope | per school; per counselor overrides | per school | Davide; revisit after the elicitation |
| 8 | Commit-triggered evaluation | never; scheduled pack only (backfill); every commit | scheduled pack only during shadow | pass 2 open decision 12, Davide |
| 9 | `shock_opens_monitor` | true; false | true, measured in shadow | ACS counselors |
| 10 | Grade 8 history for Grade 9 entrants | import from the same SIS; do not | import, if ACS exports it | ACS registrar (question below) |
| 11 | Inheritance across a level change (SL to HL) | off (default); on | off | ACS coordinator |
| 12 | Fairness labels | ACS supplies nationality, gender, language, SEN under a fairness-audit purpose; supplies a subset; supplies none | **Closed 2026-09-24 by C11**: none collected during the pilot; the audit runs only on pooled cross-school data from customer tenants, and the question returns then (question 106) | Davide (decided); the schools and counsel when pooled data exist |
| 13 | The counselor log during shadow mode | daily entry required; weekly only | daily, thirty seconds | ACS counselors |
| 14 | G-LIVE bars | pre-registered floors on the one-sided 95% lower bound of the pooled, blindly judged precision proxy, with at least 40 cases (§14.5); defaults 25% at `review` or above and 50% at `checkin` or above | the counselors' numbers, written into the pilot agreement before the first shadow sweep (revised by pass 8, F24, C9: the first version's point bars are withdrawn) | ACS counselors, Davide |
| 15 | Who activates a threshold version | caseload lead; any counselor; CAROS engineer during shadow | caseload lead, with the engineer's acknowledgement in shadow | Davide, pass 4 |
| 16 | Retrospective and termly-backfill tier cap | review (default); monitor | review, for both, and winning over relapse's minimum when all fresh evidence is termly (F25, F31) | ACS counselors |
| 17 | Recovery weeks | 2 to 6 | 3 | ACS counselors |
| 18 | Whether a risk-adding context may ever lower a tier | never (default); school's choice per kind | never | ACS counselors and CPO |
| 19 | The MAD versus Qn as the scale estimator | MAD (default); Qn if the backtest shows lead time lost | MAD | Davide after the backtest |
| 20 | Retention of shadow evaluations and the counselor log | as live signals; shorter | **Closed by pass 4 §7.1**: shadow rows and log entries about a student who had a case in the `welfare` class; log entries with no case five years | pass 4 (decided), counsel |
| 21 | Relapse while attendance is held at weak | a weak level on a closed case's triggering measure inside its window opens a `relapse_watch` monitor case (default); the relapse rule fires at weak for that measure during the hold; nothing until the hold lifts | the default, reviewed with the counselors at vignette 11: it shows the history without claiming more than a held domain allows (§4.7, C11) | ACS counselors, Davide |
| 22 | When attendance is released from weak | a coverage bar on the share of absent days carrying a reason code (default 90%); a fixed date; after the first reveal | the coverage bar, measured on the imported history and re-measured at each reveal (§4.2) | ACS (question 157), Davide |
| 23 | The planning constants behind the floors | typical absence share 5% and typical per-assessment noise of four points until the backtest; ACS's own figures from the history import before shadow | ACS's own figures, from the history import, activated as the first shadow version | Davide, after the history import |
| 24 | Going live with shadow case state | start live cases fresh from the first live run, each linked to its shadow history (default); copy open shadow cases into the live queue | fresh, because a copied case would arrive with a history the counselors never saw (§14.1) | Davide, ACS counselors |
| 25 | The longest shadow period if 40 cases have not been judged | one term (default); until 40 cases, however long; a fixed number of weeks | one term, then a recorded decision on what exists (§14.5) | ACS leadership, Davide (question 162) |

---

## For other passes

Revised by pass 8. What each pass needs from this revision is also listed, with finding numbers, in `08-changelog.md`.

**Pass 4 (security, privacy, compliance).** Already reflected in pass 4's revision: the `signal_shadow`, `counselor_log` and `fairness_label` classes (D30 now uses those keys), no fairness label in the pilot (C11), the DPIA (F37), operations alerts with counts only (F60). Still to confirm: that `signal_shadow` covers shadow **cases** and their evidence, not only evaluations (§14.1); that the blind judgements of §14.4 are `counselor_log` class; that the backtest job's key custody in §15.2 fits the DPA and the DPIA.

**Pass 5 (AI design).** The headline is the rule's template alone: no model rephrases it (F52). The co-pilot answers "why is X in check-in" from `rule_hits`, `suppressions` and the evidence chain, including `held_by_escalation_pin` and `vocabulary_used`, and must refuse to rank students (the no-comparison test has a co-pilot twin). Meeting briefs read `signal.evaluation.level`, `breadth` and the window, never a score. Pseudonymisation must preserve the rule keys and the numbers, which are not identifiers. The confidence percentage does not come back as an AI-estimated number.

**Pass 6 (build sequence).** `packages/engine` as a pure library with the scenario suite (§15.1, now S1 to S26 and the Wellesmere list) as its acceptance test, built before any screen and before the seed's narrative layer is retired; `calibrate_tiers.py` (appendix) committed beside it and reproduced by B2.9; `engine-reproduces-seed` (B2.16) over both tenants and the CI-only shifted tenant against generated expected-result lists; migrations D17 to D32 in order after pass 2's D1 to D16, with D17's new unique key; the Azure Monitor alert rules and the `/health/sweep` endpoint as part of the sweep's definition of done; the elicitation session (§10.5) scheduled before the first configuration version is written, including the G-LIVE floors; the history import before the first shadow sweep; shadow on the live engine with shadow cases (pass 6 §1.11; G-LIVE per §14.5 here); the backtest as a UAE North job (F23); the common-cause cap removed from B2.4 and O40; Opus 5.5 writes and Fable 5.1 reviews the engine's statistics and tiering rows (C7, F38).

**Pass 2 (ingest).** The master (daily) register with reason codes and lateness, beside the class register (F05); the history import of the previous school year before shadow, and in the ACS fixture (F06, F24); the re-authored attendance and punctuality series of §7.2, in days and late days; termly files with dated rows delivered so the engine can backfill (§4.8, F25); Wellesmere's due dates, missing flags and mock rows (F31); `flag_tag`, `context_kind`, `behaviour_category` and `absence_reason` attribute schemas (D27) in the vocabulary seeding; `ingest.after_commit` marking `(student, measure, week)` dirty on supersede so §13.7 has its input; the `stale_as_of` warning feeding `evaluation.as_of`.

**Pass 1 (architecture).** D17 to D22 change tables pass 1 created, including D17's unique key on `signal.evaluation` (F40) and D22's `triggering_state`; the synthetic tenants must be seeded with a status of `shadow` or `live` for the sweep to visit them (§13.2).

---

## Questions for ACS

In the style of `ACS-IT-QUESTIONS.md`, numbered after pass 2's last question (85). Each says who is likely to answer. Questions 37 to 44 in that file already ask the counselors the broad version; the ones below are the specific inputs the engine needs, and §10.5 is the session that asks them properly. Revised by pass 8: questions 95, 97, 100, 106 and 108 are rewritten in place, and new questions are numbered 157 to 162, continuing pass 8's numbering (session 1 used 148 to 155; pass 2's revision took 156).

**For the counselors · the HS counseling team**

86. Will the four of you sit together for a ninety-minute session, before the engine is configured, to answer twelve worked cases and a short set of numbers (§10.5)? The engine's first thresholds are written from your answers, and where you disagree the default holds and the disagreement is recorded.
87. When one teacher logs a concern about a student and nothing in the data has moved, should that be a card for you that week (review), or only a mark on the sheet?
88. Two teachers who do not share a class notice the same change in a week. Is that a check-in for you, or already a referral to the Child Protection Officer under school policy? Three teachers?
89. Should the engine be allowed to propose "urgent" for that pattern, or should it stop at "check-in" and leave the routing wholly to you?
90. A student you supported in October, whose case closed as recovered, slips again in the same way five weeks later. Is that more serious than the first time, and by how much (one tier, two, or the same)?
91. Should a known family circumstance you record on a case make the engine quieter about that student, louder, or make no difference? The plan's default is no difference.
92. On a normal Monday, how many new names in check-in or above would be useful, and at what number would you stop opening them? The same for review.
93. If the engine has to err, would you rather it missed one student who needed you or sent you three who did not?
94. Which weeks of the year are noisy and expected: exam and mock weeks, the first fortnight, Ramadan, the week before a holiday, IB deadlines? Which absence reasons should silence the attendance signals?
95. If most of the school's attendance dips in one week because of an event not on the calendar, who at the school would declare it in CAROS, and how quickly? The engine no longer holds individual signals back on its own, because that would make one student's signal depend on other students' data; it counts, tells the school admin, and a declared period then applies to everyone alike (F26).
96. Would you record, in under thirty seconds a day during the pilot, which students you gave attention to and why, without seeing what the engine thought until a monthly review? This is the only way the engine's judgement can be compared with yours.
97. How long should something have to persist before it becomes a card rather than a mark on the sheet: two weeks of data, three (the pilot default), more?
98. When a student recovers, how many weeks inside their own band before you would want the case marked as a positive change: two, three, four?

**Systems and data · IT, registrar**

99. Do Grade 9 entrants come up from ACS's own middle school in the same Veracross instance, and can their Grade 8 attendance and behaviour history be exported? It is the student's own history and would shorten the engine's cold start for them from a term to nothing.
100. In the historical export (pass 2 question 83), do assignment grades carry the date graded and the date due, and does attendance include the daily (master) register with its reason codes? Without dates the engine can only be tested on term grades, and without the daily register it cannot count attendance in days.
101. What is the school's conduct-point or behaviour-category scheme, and which categories (suspension, exclusion, others) should the engine treat as serious on their own?
102. Do all high school sections keep a gradebook in Veracross, or do some teachers grade only in ManageBac or Google Classroom, or on paper? A section without a gradebook has no academic series, and the plan needs to know which students that affects.
103. Does the school hold a dated record of the students the counselors supported in the last two years (intervention logs, referrals, escalations, parent-contact notes), and could it be pseudonymised alongside the SIS export? Without it the backtest cannot measure lead time.

**Safeguarding · Lead Child Protection Officer**

104. Which teacher-concern tags, or combinations of tags, must route to you regardless of anything else the engine sees?
105. During the pilot's shadow period the engine will record inferences about real students that no one acts on. Is that acceptable under the school's safeguarding policy, and who at the school should be able to see those records?

**Data protection · Data protection lead, leadership**

106. During the pilot CAROS collects no nationality, gender, language background or special educational needs label, and the pilot documents say that fairness by those groups is untested (C11). Once CAROS runs at several schools, a pooled audit would need them, held apart from everything else and used only for that audit. Would the school be willing to supply some or all of them then, under what legal basis?
107. During shadow mode, what should families be told about the engine, if anything, and when?

**The pilot · leadership, counseling team**

108. Is the school content that the pilot's first phase produces no visible tiers while the engine runs in shadow and the counselors keep a daily log, until at least forty engine cases have been judged blind (a planning estimate of five to eleven weeks after the first shadow sweep), and that going live is conditional on pre-registered bars the counselors set before shadow starts?

**Added by pass 8**

157. *(IT, registrar)* What share of absences in Veracross carry a reason code today, and will the history export show the code for each absent day? Attendance signals stay at weak until this is measured and agreed; the plan proposes releasing them once at least 90% of absent days are coded (§4.2).
158. *(IB coordinator, heads of department)* How often is a typical high school section graded in the Veracross gradebook, in assessments a month, and which courses run over two years (IB Diploma subjects, AP sequences, ACS's own courses)? Sparse grading slows detection in weeks, and two-year courses carry their baselines (§3.10, §11.1).
159. *(Registrar)* What is the high school's typical attendance rate, and how much does it vary across the year (Ramadan, the weeks before holidays)? It sets the attendance scale floor until the backtest measures it (§3.3, open decision 23).
160. *(Counseling team, leadership)* IB results arrive in July and A-level results in August, when there are no school days. Who at the school acts on a university check-in raised on results day, and on what clock (§4.6)?
161. *(Counseling team)* At each reveal session, will each counselor spend about sixty minutes judging a mixed set of student cards without knowing which ones the engine flagged? This blind judgement is what the go-live decision rests on (§14.4).
162. *(Leadership, counseling team)* If forty cases have not been judged by then, what is the longest shadow period the school will accept before deciding on what exists: one term, or longer (§14.5, open decision 25)?

Question 71 (pass 2, revised by pass 8) asks whether the high school keeps a daily (master) register separate from class attendance, whether it records lateness to school, and whether half days are recorded as morning and afternoon; the engine counts attendance in days from the daily register (§4.2). No separate question is added here.


# CAROS backend · Pass 3 · Signal engine

Written 2026-09-23 against `index.html` at 10,048 lines, `backend-plan/CONTEXT.md`, `PRODUCT.md`, `out/01-architecture-and-data-model.md` (pass 1) and `out/02-ingest-and-integrations.md` (pass 2). Every source cited was checked by web search or retrieval on 2026-09-23; where a figure could not be verified it is labelled an assumption. Numbers that came out of a simulation written for this pass are labelled *computed* and the assumptions behind them are stated where they appear.

## 0. Read this first

### 0.1 Departures from section 3 of CONTEXT.md

**None.** Every decision in section 3 is planned on: the overnight batch is the ritual, the statistics are specified in full, counselors configure what they consider urgent, the engine is designed for the weekly export pack with an honest termly mode, tiers and signals stay staff-only, and every number a counselor sees traces to a stored input. Two decisions are challenged in the Challenges section and planned on as given: "overnight batch" is extended (not replaced) with an event-triggered evaluation for the three inputs that arrive live, which pass 1 (§5.2) asked this pass to argue and CONTEXT.md §11.1 leaves open; and the engagement domain is planned as **off by default** until pass 4 rules on measuring a minor's platform activity, which is a sequencing choice inside the decision, not a departure from it.

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
| Dimension statuses (`dimPunctuality` `:3135`, `dimEngagement` `:3151`, `dimBehaviour` `:3159`) | CONTEXT.md §7: computed at render time | punctuality and engagement are hard-wired to student ids; behaviour is a constant | The `dimensions` rule set (§9.3) defines all five student-intelligence dimensions from the domain levels; the five application dimensions keep the prototype's logic as data (pass 1 DR-6) |
| Priya's series (`s14`, `:1502`) | not in CONTEXT.md | "Platform activity after 01:00 (nights per week)" | **Measure removed.** It infers sleep from timestamps of a minor's activity, has no validity evidence, and is the most intrusive number in the product. Her case is reproduced from first-period punctuality and the teacher comment (§4.3, §15.1) |
| Layla's baseline (`s2`, `:1345`) | | "4.2 logins per week across the previous 14 months" | The baseline window is at most 20 school weeks (§3.2); a fourteen-month baseline would smooth over a Grade 11 to Grade 12 change in what the platform asks of her. The summary template prints the window it used |
| Ahmed's "first result outside his personal band in 22 months" (`s1`, `:1327`) | | | Academic series are per section (course); a 22-month claim crosses courses. The template prints "first result outside his band in Mathematics AA HL this year (14 weeks)" |
| Thresholds page estimate (`vThresholds`, `:2267`) | | "Estimated effect: … current false-positive rate 14%" | Replaced by a **what-if run** over the last twelve weeks of stored snapshots that prints how many cases per tier the proposed settings would have produced (§10.4) |
| The run (`weekRun`, `:1281`) | CONTEXT.md §7: kept / soft / break / none | `break` = two or more series outside band in the same week | Kept exactly, with one addition: a point counts as outside only if it also clears the measure's minimum meaningful change (§3.4), so a stable student's two-point wobble is not a cross on the sheet |
| Teacher flag statuses (`data-fact`, `:9515`) | pass 1 enum `new, linked, reviewed, dismissed` | `attach` → `linked`; `ack` → `"ack"` | `ack` maps to `reviewed`. A `reviewed` concern still counts toward corroboration for its seven school days (§4.5) |
| Yousef's context (`s4`, `:1376`) | | "Assessment was a timed mock during a heavy deadline week" | Mocks are their own series (`assessment.kind = 'mock'`) and never mix with coursework (§4.1); a declared `mock_period` suppresses the academic domain for the year groups it names (§6) |
| Tariq's referral threshold (`s12`, `:1461`) | invariant 5 | "Referral threshold under the school's policy is two independent staff within seven days" | The corroboration rule's parameters are school configuration with exactly those defaults (§4.5); the engine proposes `urgent`, the counselor refers |
| Cohort tiles on `si-why` (`vIntel`, `:2177`) | invariant 2 | Cohort-mean attendance, lateness, engagement and attainment sparklines | These are school-level descriptive aggregates, not a ranking of students; they may stay. The cohort **matrix** on the same page ranks nothing but its cell colours change (above) |
| `movedToday` / `openedToday` (`:3344`) | pass 1 DR-6 | derived from `prev` and the `opened` string | `tier_yesterday` is the tier at the end of the **last successful nightly run**, not the previous calendar day; when a night is missed the sheet says which run it is comparing against (§13.6) |

### 0.3 What passes 1 and 2 handed to this pass

Pass 1 §7 asked for: `feature_snapshot.band_method`, `history_weeks` and `features`; `evaluation.rule_hits`, `suppressions`, `strength` and `strength_definition`; `signal.contribution`; the rule keys named in `openedBy`; the three rule sets `engine.thresholds`, `engine.suppression`, `engine.tiering` and their JSON schemas; hysteresis and the rule that the engine never lowers a person-raised tier within N days; the hybrid trigger argument; the `dimensions` rule set; cold start through `history_weeks`; and the seed reproduction test. Pass 2 §13 asked for: the backfill evaluation for weekly and termly deliveries; the fortnightly persistence question; the retrospective tier cap; what happens to a signal whose fact was superseded; ordinal series analysed as ordinal; `sis.grade.missing` as a submission series; `counts_as = 'excluded'` days out of the denominator; first-period punctuality only where a period reference exists; `as_of` per domain printed; `absence_reason.attributes.suppresses` as the vocabulary side of suppression; cold start reading `joined_on` and `transferred_in`; reads through `sis.v_current_*`. Each is answered below; §17 lists the schema deltas.

### 0.4 The engine on one page

For every student, every night, for every measure the school's data can carry (§4), the engine:

1. Builds a weekly series from the student's own facts, in the scale the facts are in (§3.1).
2. Takes the most recent twenty valid weeks of that student's own history as the **baseline window**, and computes a robust location (median) and scale (MADn, floored) from it (§3.2, §3.3). Nothing about any other student enters this step (invariant 2). The band the sheet draws is median ± 2.5 scale (§3.4).
3. Runs three detectors on the series: the **band** (is this week outside the student's own band, by more than the minimum meaningful change), the **shock** rule (a single week three or more scale units out) and a one-sided **CUSUM** (a sustained shift, with its own estimate of when it began) (§3.4). A trend slope is computed for the sentence, not for the decision.
4. Turns the detectors into an ordinal **level** per measure (0 none, 1 weak, 2 moderate, 3 strong) and per domain (§3.5), with **persistence** (weeks since onset) and a **window** in days.
5. Applies **suppression** (§6): exam and mock periods, authorised absences, subject changes, counselor context, teacher context, and a school-wide common-cause check. Suppressed weeks leave both the baseline and the detectors, and every check is recorded whether or not it fired.
6. Adds the inputs that are not series: teacher concerns (§4.5), behaviour incidents the school defines as serious, the university rules (§4.6), open and recently closed cases (relapse, recovery, §4.7).
7. **Combines** across domains by level, breadth and persistence, never by a weighted sum (§7), and maps the result to one of the five tiers under **hysteresis** so that a student does not move night after night on noise (§8).
8. Writes the evaluation, the signals with their frozen inputs, the evidence items with snapshots, and the case movement, under the configuration versions it ran with (§16), and computes "what changed overnight" against the last successful run (§13.6).

Three inputs that arrive during the day (a teacher concern, counselor context, an enrolment change) trigger an immediate evaluation of that one student, which may raise or attach but never lower except on context (§7.5). Counselors set the thresholds, floors, persistence and tier mapping per school through versioned configuration with guards against switching a domain off by accident (§10). In the pilot the engine runs in shadow (§14), and before any real data it is tested against an adversarial synthetic set (§15).

---

## 1. What the engine is for

### 1.1 The purpose, in measurable terms

The engine exists so that, each morning, a counselor responsible for about 87 students opens a queue that is short enough to read and correct enough to trust, and in which the students who have started to move against their own pattern appear **before** they ask for help and **before** the movement becomes a crisis or a missed deadline. Three quantities define success and every one of them is measurable from the event stream pass 1 defined (`events.v_case_timeline`):

| Quantity | Definition | Measured from |
|---|---|---|
| **Lead time** | Days between the engine opening or raising a case and the counselor's own first recorded action on that student that was not prompted by the case (backtest), or the counselor's judgement in shadow mode that they would have wanted to know (§14) | `case.opened` versus the counselor log / historical intervention dates |
| **Precision of the action tiers** | Share of cases opened or raised into `checkin` or `urgent` that the counselor accepts, acts on, or escalates, rather than dismisses or downgrades twice | `case.accepted`, `case.dismissed`, `case.downgraded` |
| **Miss rate** | Share of students a counselor supported (a recorded intervention, referral or escalation) for whom the engine had no case at `review` or above in the four school weeks before the counselor's first action | backtest (§15.2); in production, interventions opened manually (C2) on students with no open case |

Two more are constraints rather than goals: **queue size** (new items per morning in the action tiers, §11) and **time to aware** (median from `case.opened` to `case.viewed`, which the product already promises to report).

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

`METRICS` in the prototype (`index.html:1596`) carries an 81% accept rate and a 14% false-positive ceiling, labelled targets. This pass sets its own working targets for the pilot exit (§14.5): precision in the action tiers of 60% or better, a lead time of two school weeks or better on the cases the backtest can see, no counselor-handled case missed where the data existed, and a queue of at most three new action-tier items per morning at the median. They are targets. Nothing here is a measurement, and nothing will be until the shadow period ends.

---

## 2. What the research supports, and what does not transfer

### 2.1 Early warning indicators: cohort-level truth, individual-level caution

The early warning literature is the strongest evidence that attendance, behaviour and course performance carry information about a student's trajectory. It is also, almost without exception, **cohort-level prediction**: a threshold chosen because, across thousands of students, those above it went on to a bad outcome at a higher rate. That is not the question this engine answers. The distinction governs what transfers.

**Balfanz, Herzog and Mac Iver (2007)** followed 12,972 Philadelphia sixth graders from 1996–97 for eight years. Four flags (attending 80% or less, a failing final grade in mathematics, a failing final grade in English, an out-of-school suspension) and a fifth (an unsatisfactory final behaviour mark) each identified a group of which only 12% to 24% graduated on time (13% for attendance, 13% for mathematics, 12% for English, 16% for suspension, 24% for behaviour); together the flags identified 60% of the students who did not graduate. Attendance and course failure were the sharper flags; behaviour amplified them (77% of the students failing mathematics also had an unsatisfactory behaviour mark). *What transfers:* the three domains and the finding that co-occurring flags are far more predictive than any one, which is the basis for combining by breadth (§7). *What does not:* the thresholds. "Attends 80% or less" is a level, chosen for a population, in a district where a third of sixth graders were below it; at ACS a student at 80% has probably already been noticed, and a student who has gone from 99% to 91% has not. The engine uses a level only as a school-policy floor at `review` (§4.2), never as its main rule.

**Allensworth and Easton (2005, 2007)**, UChicago Consortium: the Freshman On-Track indicator (at least five full-year credits and no more than one semester F in a core course) separated graduation rates of 81% (on track) from 22% (off track) in the 1999 Chicago cohort; course attendance in the freshman year was eight times more predictive of course failure than eighth-grade test scores, and a week of absence in a semester was associated with a substantially greater likelihood of failure regardless of incoming achievement. *What transfers:* attendance is the earliest and most sensitive of the three, and small amounts of absence matter; it is why the attendance domain is weighted toward change in weeks, not terms. *What does not:* the indicator itself, which is a term-end fact about credits.

**Bowers, Sprott and Taff (2013)** reviewed 110 dropout flags across 36 studies with ROC analysis and found that most flags have high precision but poor overall accuracy, that longitudinal growth models (a student's own grade trajectory over time) gave the most accurate flags, and that among cross-sectional flags low or failing grades and the Chicago on-track indicator did best. *What transfers, and it is the most important finding for this design:* **the shape of a student's own trajectory beats a snapshot against a threshold.** That is the personal-baseline thesis, stated in the cohort literature's own terms. *What does not:* the models themselves, fitted across cohorts.

**Faria et al. (2017)**, REL Midwest: a randomised trial of an early warning system (EWIMS) in 73 high schools reduced chronic absence (effect size about +0.23) and course failure in one year, with no effect on GPA or suspension indicators or on progress in school. *What transfers:* showing staff attendance and course flags changes attendance and course outcomes; it is evidence that the loop from signal to counselor to student is real. *What does not:* EWIMS is a cohort-threshold system, and the trial says nothing about personal deviation.

**Knowles (2015)**, Wisconsin's statewide DEWS, and the machine-learning line that follows it, predict non-graduation for hundreds of thousands of students from administrative data. They are the clearest case of what this engine is **not**: a risk score attached to a child, trained on populations, opaque in its features. **Anderson, Boodhwani and Baker (2019)** show such graduation predictions can perform differently across demographic groups, which is why §12 exists.

**Chronic absence** is conventionally defined as missing ten percent or more of the school year for any reason, about eighteen days of a 180-day year (Balfanz and Byrnes 2012; the definition used by Attendance Works and the U.S. Department of Education). *What transfers:* a defensible, citable level floor for the attendance domain's policy rule. *What does not:* the number, which a UAE school under ADEK's 2025 attendance policy (pass 2 §5.2) sets for itself.

**Office discipline referrals**: McIntosh, Frank and Spaulding (2010) established research-based trajectories for ODR counts and showed that the 0–1, 2–5, 6+ categories used in schoolwide PBIS settle late in the year (only 20% of students were in their final category by the end of November, 50% by February, 80% by April). *What transfers:* behaviour counts are sparse and lumpy, so a within-year count threshold is unstable early in the year; the behaviour domain uses a personal rolling two-week rate with a Poisson-style floor, not a cumulative count (§4.4). *What does not:* the categories.

**Seasonality.** In U.S. daily attendance data absences rise through the autumn, peak in winter, stay near peak through the spring, spike before holidays and rise again in the final weeks (AEI, *What Stories Does Daily Attendance Tell?*, 2025; unexcused absence rising from 1.6% in August to 4.1% in May in the *Please Excuse My Child* series). *What transfers:* a personal baseline drifts with the year and a fixed band would fire in spring on nothing; the trailing window and the calendar suppressions exist for this (§3.9). *What does not:* the U.S. calendar; ACS's year, Ramadan and its own holidays are the tenant's calendar (pass 2 §5.6).

### 2.2 Teacher recognition

Teachers identify severe externalising and internalising problems accurately but are less accurate and less likely to refer for moderate or subclinical symptoms, and they rate externalising problems as more serious and more concerning than internalising ones (Splett et al. 2019, vignette study with 153 teachers). Universal screening identifies more students than teacher nomination, including students teacher referral had not identified (Dowdy, Doane, Eklund and Dever 2013; and the Eklund and Dowdy line on screening versus referral). *What transfers:* the teacher-concern domain is the school's earliest and cheapest signal for the loud change (Tariq) and a weak one for the quiet decline (Ahmed, Priya), which is exactly the case the series detectors exist for. The two channels are complementary, so the combination rule treats a teacher concern plus a series deviation as breadth, not as duplication (§7). *What does not:* the screening instruments; CAROS runs no screener.

### 2.3 Statistics for a short individual series

The engine's statistical problem is unusual only in its smallness: one student, one measure, eight to twenty weekly points, no population to borrow from. The tools that fit are old and well understood.

- **Robust location and scale.** The mean and standard deviation are themselves moved by the outlier one is looking for; the median and the median absolute deviation are not (Hampel 1974 on influence; Leys et al. 2013, who recommend the MAD with a consistency constant of 1.4826 and thresholds of 2.5 (moderately conservative) or 3). Iglewicz and Hoaglin (1993) give the modified z-score 0.6745·(x − median)/MAD with 3.5 as the outlier cut. Rousseeuw and Croux (1993) offer Sn and Qn, more efficient than the MAD (Gaussian efficiency 58% and 82% against 37%) at the cost of explainability; the engine uses the MAD because a counselor can be told what it is in one sentence, and revisits Qn only if the backtest shows the MAD's inefficiency costs lead time.
- **Sustained shifts: CUSUM.** Page (1954) introduced the cumulative sum; the tabular form with reference value k (half the shift to detect, in scale units) and decision interval h is standard (NIST/SEMATECH e-Handbook §6.3.2.3: k as half the shift, h "around 4 or 5"). With known parameters, k = 0.5 and h = 5 give a two-sided in-control average run length of about 465 observations (SigmaXL's tabular CUSUM reference; Hawkins and Olwell 1998 for the full tables); the one-sided charts this engine uses have roughly double that (computed, §3.6: about 928 at h = 5 and 335 at h = 4). The CUSUM's byproduct is the reason it is chosen over the alternatives: the last time the sum was zero is a built-in estimate of **when the change began**, which is the "how long it has persisted" tile. Run-length distributions come from Brook and Evans (1972).
- **EWMA** (Roberts 1959; Lucas and Saccucci 1990 for the design tables; robust to non-normality for small λ per Borror, Montgomery and Runger 1999) detects the same shifts with a smoother statistic and is the natural choice for a chart one *looks at*. It has no onset estimate and its statistic is harder to narrate ("your weighted average has fallen below…"). The engine draws the plain series and the band, and keeps the CUSUM for decisions. EWMA is the named alternative if the CUSUM's step-like behaviour proves hard to explain in shadow mode.
- **Counts and proportions.** Attendance is a proportion over a handful of sessions and behaviour points are sparse counts. Lucas (1985) gives the CUSUM for counted data and Borror, Champ and Rigdon (1998) the Poisson EWMA; the engine keeps one detector family for explainability and instead floors the scale at the binomial or Poisson noise level so that a 100%-attendance student's first absence is not a fifty-sigma event (§3.7).
- **No history: self-starting charts.** Hawkins (1987) built CUSUMs that use the running mean and standard deviation of the observations so far in place of unknown parameters; Quesenberry (1991) built Q-charts for start-up processes and short runs. They are the principled answer to cold start (§5): the student's first weeks become their own baseline, with limits widened for the uncertainty, rather than a population's.
- **Run rules.** The Western Electric rules (1956) and Nelson (1984) formalised "several points on one side" tests; the persistence requirement is one of these, stated in weeks.
- **Change-point detection.** PELT (Killick, Fearnhead and Eckley 2012) finds the optimal segmentation of a series at linear cost; Truong, Oudre and Vayatis (2020) review the offline field; Adams and MacKay (2007) give the Bayesian online form. They are the right tools for the **backtest** (segmenting two years of history to find where real changes happened) and the wrong tools for the nightly rule: a segmentation is a model fit whose explanation is a likelihood, and a counselor cannot argue with a likelihood. The nightly engine uses the CUSUM's onset estimate and PELT is confined to validation (§15.2).
- **Estimated parameters hurt.** Charts designed for known parameters have far worse false-alarm behaviour when the parameters are estimated from a short history; this is well known in the SPC literature and the simulation in §3.6 reproduces it (a CUSUM designed for one false alarm in 335 weeks fires in about 4% of weeks when its scale comes from twelve points). The design answer is the minimum meaningful change floor and the history minimums, not a bigger h.

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
- A **point** `x[q,t]` is the weekly aggregate of one measure `q` (defined per domain in §4) for one student, computed from `sis.v_current_*` rows (pass 2 §7.9) so that conflicting imports resolve the same way everywhere. A point exists only if the week carries at least `n_min(q)` observations; otherwise it is **null**. A short week is null unless `n_min` is met anyway.
- The **current week** is provisional until it has closed. Provisional points count for the shock rule (§3.4) and in evidence sentences ("Tuesday's result"), not for the baseline or the CUSUM. Under the weekly pack every point is a complete week; under a nightly connector the current week is provisional.
- Every domain has an **as-of** date: the later of `ingest.expected_cadence.last_as_of` for its import kind and the newest fact date it read (pass 2 DR-14). The sweep stores it on the snapshot and the sheet prints it ("attendance as of 14 Nov").

### 3.2 The baseline window

`B[q,t]` is the set of the most recent `W` valid points of **this student's own** series strictly before week `t`, where valid means non-null and not suppressed for the measure's domain (§6). Defaults: `W = 20`. The window crosses term boundaries inside an academic year. It crosses the academic-year boundary for attendance, behaviour and engagement (a student's own attendance last year is still their attendance) and **not** for academic measures, which are per section and start again with the course (§3.10). `H = |B|` is `history_weeks` on the snapshot.

**Episode exclusion.** Weeks inside a closed case's window (from `window_start` to `closed_at`) on that case's triggering measures are excluded from `B`. Without this a student's own crisis becomes their baseline: Hana's October dip, left in the window, widens her band enough that her relapse (86 then 79 against a band that would then run from 73) never leaves it. With it, her baseline is her normal, and the relapse is a strong shock. The excluded weeks are listed in `features.excluded_episodes`.

Two minimums, both configurable (§10):

| Parameter | Default | Meaning |
|---|---|---|
| `min_history_band` | 8 | Below this there is no band; the sheet shows `none` cells and the file says "building a baseline: 5 of 8 weeks" |
| `min_history_full` | 12 | Below this the series detectors may raise a level of at most **weak** (§5); at or above it, the full ladder |

Twenty weeks is not arbitrary: with twelve points the estimated scale is loose enough to double the false-alarm rate against twenty (§3.6), and twenty weeks is about a semester at ACS, so the band describes "this student, this half-year".

### 3.3 Location, scale and floors

For a measure with adverse direction `dir(q) ∈ {−1, +1}` (attendance: lower is adverse, `dir = −1`; lates or conduct points: higher is adverse, `dir = +1`):

```
m        = median(B)                                     personal location
MADn     = 1.4826 · median( |b − m| for b in B )        robust scale, consistent with σ under normality
s        = max( MADn, s_floor(q) )                       the scale the engine uses; "σ" wherever the UI prints one
d[q,t]   = dir(q) · ( x[q,t] − m )                       adverse deviation, in the measure's own units
z[q,t]   = d[q,t] / s                                    robust z, the printed sigma value
```

`MADn` follows Leys et al. (2013) and Hampel (1974). `s_floor(q)` is the **scale floor**: the noise a perfectly steady student still has, so that the first absence of a 100%-attendance student is not a fifty-sigma event. It is derived, not set:

| Measure family | `s_floor` | Why |
|---|---|---|
| Percentage attainment | 3.0 points | A single assessment's score is not repeatable to better than a few points, and a scale estimated from twelve weeks is often too small by chance: the floor sits at about three-quarters of a typical student's weekly noise, because the tier-level simulation (§11.1) showed that a floor at half the noise lets an underestimated scale inflate every `z` and fill the review tier |
| Ordinal grade (IB 1 to 7, AP 1 to 5, A level, GCSE 9 to 1) | 0.5 step | A MAD of zero is the normal case for a steady student on a seven-point scale |
| Attendance rate (% of sessions) | `max(3.0, 100 · sqrt(p̂ (1 − p̂) / n̄))` with `p̂ = clip(m/100, 0.02, 0.98)` and `n̄` the median registered sessions per week | The binomial noise of a proportion over n̄ sessions (computed: a 96% student over 30 sessions a week has a weekly standard deviation of 3.6 points; the MAD of twelve such weeks is zero one time in seven) |
| Counts (lates, absences, conduct points, active days) | `sqrt( max(m, 0.5) )` | Poisson noise; the 0.5 keeps a zero-baseline student from a zero scale |
| Days of silence | 1.0 | |

Separately, every measure has a **minimum meaningful change** `floor(q)`, in the measure's own units, set by the school (§10) with these defaults: attainment 5 percentage points or 1 ordinal step; attendance rate 5 points; lates 2 per ten school days; unexplained absences 2 per ten school days; conduct 3 points per fortnight; submission rate 15 points; active days 2 per week; silence 14 days. No detector fires unless `d ≥ floor(q)` (for the CUSUM, the mean deviation since onset). The floor is what stops a very steady student's trivial wobble from becoming a sigma-count nobody would act on, and it is the single most effective lever on false alarms (§3.6). It is also the answer to "how big is a change for a strong student versus a struggling one": the personal band scales with each student's own variability, and the floor is the same for both.

### 3.4 The detectors

Three detectors run on every measure with a band; each has an explanation a counselor can repeat.

**The band and the run.** The band is `[m − c·s, m + c·s]` clipped to the measure's range, `c = 2.5` (Leys et al.'s moderately conservative cut). A point is **outside** when it lies beyond the band **and** `|x − m| ≥ floor(q)`. The sheet's run (`signal.week_run()`, pass 1) is unchanged: `kept` when every measure is inside, `soft` when exactly one is outside, `break` when two or more are, `none` when no measure has a point. Adverse-outside feeds the level; favourable-outside feeds recovery and positive evidence.

**The shock.** A single point far out: `z ≥ z_shock` (default 3.0, between Leys' 3 and Iglewicz–Hoaglin's 3.5) with `d ≥ floor`. A shock on its own is **weak** (the prototype's Yousef: one mock six points under the band floor sits in Monitor). A **strong shock**, `z ≥ z_shock_strong` (default 5.0) with `d ≥ 2·floor`, is moderate on its own, because a result that far from a student's own pattern (Ahmed's 41% against a median of 90%) is worth a look even before the next result arrives; it makes a measure **strong** only when the CUSUM already stood at or above `h` before it, so that a single wild point on a steady series never reaches the action tiers alone.

**The CUSUM.** A one-sided cumulative sum in the adverse direction (Page 1954; tabular form per NIST §6.3.2.3):

```
S[q,0]   = 0                                  reset at the start of each academic year and when the series starts (new section)
S[q,t]   = max( 0, S[q,t−1] + z[q,t] − k )     over valid, complete weeks; a null week leaves S unchanged
k        = 0.5                                 tuned to a shift of one scale unit
signal   ⇔ S[q,t] ≥ h  and  mean( d[q,u] for u in τ..t ) ≥ floor(q)
τ[q,t]   = the first valid week after the last week at which S was 0      (estimated onset)
P[q,t]   = number of valid weeks in τ..t                                   (persistence, in weeks of data)
window   = school days from the first day of week τ to the as-of date      (the "how long it has persisted" tile)
```

Defaults `h = 5`, `h_strong = 8`, exit `h_exit = h / 2` (§8.3). The CUSUM is the detector for the quiet decline: eight weeks of 90, 88, 86, 85, 84, 83, 82, 81 never produce a shock and rarely a single outside week, and the sum catches them by week four or five (§3.6).

**The trend** is a sentence, not a decision: the Theil–Sen slope (Sen 1968; the median of pairwise slopes) over the last six valid weeks, printed as "falling about 3 points a week". It has one rule role: the **improving guard**. When the slope has been favourable for three consecutive valid weeks, the school-policy level rules (§4.2, §4.4) do not fire, and recovery detection (§4.7) may begin.

### 3.5 Levels

Each measure gets an ordinal **level** each night:

| Level | Name | Condition (any) |
|---|---|---|
| 3 | strong | `S ≥ h_strong` **and** `P ≥ persist + 1` **and** the mean shortfall since onset is at least `strong_mean_factor · floor` (default 1.5); or a strong shock in a week where `S` already stood at or above `h` |
| 2 | moderate | `S ≥ h` with `P ≥ persist` (default `persist = 2`); or a strong shock; or a shock in the week after an outside week; or the **scale-free rule**: `d ≥ 2·floor` for `persist_free` (default 3) consecutive valid weeks, whatever `z` is |
| 1 | weak | outside the band this week (adverse); or a shock; or `S ≥ h` with `P < persist` |
| 0 | none | otherwise |

The strong definition is deliberately three-sided. Its first form was `S ≥ h_strong` alone, and the tier-level simulation (§11.1) showed that with a scale estimated from twelve weeks that single condition put about thirteen quiet students a week into `checkin` on a caseload of 87; requiring persistence and a mean shortfall as well brings it under one. Cold start caps the level at 1 below `min_history_full`, except the strong shock (§5). The scale-free rule exists for fairness (§12.3): a student whose history is noisy has a wide band and a small `z` for the same decline, and the engine would otherwise be least sensitive for the students whose lives are least steady; a ten-point fall held for three weeks is moderate for everyone. Computed, it adds about 0.1% per series-week of noise for a student whose weekly noise is twice the floor, and nothing measurable for a steady one. A measure that needs more than one observation to mean anything carries an extra condition: an attainment series reaches level 2 only if at least two assessments were graded since onset, so one bad assignment cannot be "moderate" by lingering.

The **domain level** `L[d]` is the maximum over the domain's measures; the domain's **breadth** (how many sections, how many measures) is printed with it ("in 3 of 6 subjects"). One within-domain rule adds corroboration: weak in three or more academic sections in the same three-week window is moderate for the domain, because a small decline everywhere is not noise in any one place.

### 3.6 Calibration, computed

A simulation written for this pass (150,000 replicates per cell; i.i.d. weekly noise, normal or Student-t with 3 degrees of freedom for heavy tails; a quiet student; baseline of `H` weeks then eight monitored weeks; `c = 2.5`, `z_shock = 3.0`, `k = 0.5`, `persist = 2`; the floor expressed in units of the student's true weekly noise) gives the per-week false-alarm probability of each detector. These numbers assume no autocorrelation and no seasonality, so real series will be somewhat worse; they are for choosing defaults, and shadow mode measures the truth (§14).

| Noise | `H` | `h` | floor (σ) | outside/week | shock/week | CUSUM crossing/week | CUSUM persisting 2 weeks/week | any moderate/week |
|---|---|---|---|---|---|---|---|---|
| normal | 6 | 5 | 1.0 | 5.4% | 3.2% | 4.9% | 1.6% | 4.2% |
| normal | 12 | 4 | 0 | 3.2% | 1.7% | 6.4% | 3.6% | 4.9% |
| normal | 12 | 5 | 1.0 | 3.2% | 1.6% | 2.5% | 0.65% | 2.1% |
| normal | 12 | 5 | 1.5 | 2.7% | 1.7% | 1.5% | 0.21% | 1.8% |
| normal | 20 | 5 | 1.0 | 2.2% | 1.0% | 1.4% | 0.32% | 1.2% |
| t(3) | 12 | 5 | 1.0 | 5.4% | 3.8% | 4.4% | 1.1% | 4.6% |
| t(3) | 20 | 5 | 1.5 | 4.4% | 3.1% | 2.4% | 0.35% | 3.3% |

Three things to read from it. First, with the scale estimated from twelve points a CUSUM designed for one false alarm in hundreds of weeks (with known parameters the one-sided `k = 0.5, h = 5` chart has an in-control average run length of about 928 weeks, and `h = 4` about 335; computed, and consistent with the published two-sided figures of roughly 465 and 168) fires in 2.5% of weeks: estimation, not the chart, sets the noise. Second, the floor and the history length are the levers that matter; `h` is a weak one. Third, the **persistence requirement halves the noise again** at the cost of one week of delay.

Detection under the recommended defaults (`H = 12, h = 5`, floor 1σ, `persist = 2`), normal noise, probability of reaching moderate within eight weeks and the median delay from onset: a sustained shift of 1.5σ, 72% with a median of 3 weeks; 2σ, 90% and 3 weeks; 3σ, 100% and 1 week; a decline of 0.5σ a week, 97% and 5 weeks; 1σ a week, 100% and 3 weeks. Under t(3) noise the 1.5σ shift is caught 66% of the time. A 1.5σ shift on an attainment series whose noise is four points is a six-point fall: the quiet decline of a strong student, caught about three weeks in, seven times in ten. That is the engine's honest sensitivity, and it is what the backtest must confirm or move.

The table above uses a scale floor at half the true noise; the recommended floor is three-quarters (§3.3), which lowers every rate in it somewhat. The recommended defaults therefore are: `W = 20`, `min_history_full = 12`, `c = 2.5`, `z_shock = 3.0`, `z_shock_strong = 5.0`, `k = 0.5`, `h = 5`, `h_strong = 8`, `strong_mean_factor = 1.5`, `persist = 2`, a breadth window of two weeks (§7.1), scale floors at about three-quarters of a typical student's weekly noise, and minimum-meaningful-change floors at about one to one-and-a-quarter units of it (the defaults in §3.3). A second simulation over the **whole tier logic** for a student with ten series (six attainment sections, two attendance measures, behaviour, submission) under these defaults is reported in §11.1; it is the number that matters for the queue, and it is what forced the strong definition above.

### 3.7 Ordinal and count scales

Series are analysed in the scale their facts are in, never through `normalised_pct` (pass 2 §5.1). Per-scale defaults, overridable per school:

| Scale | point | `c` | `z_shock` | `s_floor` | `floor` | Note |
|---|---|---|---|---|---|---|
| `pct` | weighted mean of the week's scores × 100 / max | 2.5 | 3.0 | 3.0 | 5 | |
| `ib_1_7`, `ap_1_5`, `a_level`, `gcse_9_1`, `ib_core_letter` | median of the week's grades, as an integer rank | 1.5 | 3.5 | 0.5 | 1 step | with `s = 0.5`, a one-step drop is `z = 2` and outside a band of ±0.75; a two-step drop is `z = 4`, a shock |
| `gpa_4`, `school:<slug>:<key>` numeric | as `pct` on the declared range | 2.5 | 3.0 | 2% of range | 5% of range | |
| counts | the count | 2.5 | 3.0 | Poisson | per measure | |

### 3.8 Missing data

- A **null week** is skipped: not in `B`, `S` unchanged, `P` not advanced, the run cell `none`. Nothing missing is ever adverse.
- A **missing assignment** is not missing data: it is an observation of the submission series (`sis.grade.missing = true`, pass 2), which is why that series exists separately from attainment.
- An **import gap** (the weekly pack did not arrive) freezes the domain's as-of; the sheet prints it; no signal is raised or lowered for that domain until data returns, and the tier hold rules (§8.3) treat a frozen domain as "no new observation".
- A **corrected fact** (pass 2 §2.9) re-runs the affected weeks; a signal whose inputs no longer hold is withdrawn (§13.7).
- Thin weeks (`n = 1` for an attainment series) are valid points but are marked `thin` in `features`, and the two-assessment condition for level 2 (§3.5) reads that mark.

### 3.9 Term boundaries and seasonality

- The trailing window moves with the student, so a slow seasonal drift (attendance falling from autumn to spring, as U.S. daily data show) drifts the band rather than crossing it.
- Weeks inside a declared `holiday`, `inset` or short week are null; the first week back is compared to the band, not to the last week before the break, and the CUSUM simply continues.
- The first `settling_weeks` (default 1) of an academic year cap attendance and engagement at weak, because registers and rosters settle in the first days.
- `exam_period`, `mock_period`, `reporting_window`, Ramadan and any `other` period the school declares act through suppression and softening (§6). What the calendar does not declare, the common-cause guard catches (§7.6).
- The CUSUM resets at the academic year start. The band does not, for the domains that carry over, so a Grade 11 student's first weeks of Grade 12 are judged against their own Grade 11 attendance, which is the point.

### 3.10 Sections, subjects and inheritance

Academic series are keyed by `sis.section_id`. A new section is a new series. When a student changes section within the same `sis.subject.canonical_key` at the same level and scale (a set change), the new series **inherits** the old one's baseline with `H` capped at 8 and `features.inherited_from` set, and the file prints "band inherited from Mathematics set 2". A change of subject, level (SL to HL) or scale starts cold (§5); inheriting across a level change is configurable and off by default, because a drop after moving up is expected and a counselor should decide whether it is a concern. A section change is itself a suppression input for the week it happens (§6).

---

## 4. The domains

For each domain: the tables it reads, the measures it derives, their cadence under each delivery mode pass 2 defined, the rules beyond the shared detectors, and what the evidence sentence says.

### 4.1 Academic

**Reads.** `sis.assessment` (kind, occurred_on, max_score, weight), `sis.grade` (kind `achieved`, `value_numeric`, `scale_key`, `missing`), `sis.section`, `sis.section_membership`, through `sis.v_current_grade`. Never `predicted` (a judgement, pass 2) and never `normalised_pct`.

**Measures.**

| Measure key | Point | `n_min` | `dir` | Notes |
|---|---|---|---|---|
| `academic.<section>.attainment` | percentage scale: weight-weighted mean of `score / max_score × 100` over assessments of kind `assessment`, `coursework`, `homework` graded that week; ordinal scale: median grade | 1 assessment | −1 | one series per section; `thin` when `n = 1` |
| `academic.<section>.mock` | as above over kind `mock`, `exam` | 1 | −1 | its own series; usually cold (few points a year), so it feeds evidence text and the university rules rather than a level |
| `academic.submission` | across sections: share of assessments due this week that were submitted or graded by the due date, from `missing = false` and Classroom submission states (pass 2 §7.6) | 3 due | −1 | school-wide per student; the prototype's "coursework submitted (rolling %)" |
| `academic.missing_2w` | count of `missing = true` in the trailing two weeks | | +1 | shock statistic for the submission series; "two Mathematics deadlines missed" |
| `academic.<section>.working` | one point per reporting window: the `working` grade | 1 | −1 | the retrospective-mode series (§4.8) |

**Rules beyond §3.4.** Within-domain breadth (weak in ≥ 3 sections → moderate, §3.5). The two-assessment condition for level 2. A `missing_2w ≥ 2` with the submission series below band is moderate for the domain even if the rate's CUSUM has not crossed, because two missed deadlines in a fortnight against a clean record is the observation the counselor would act on.

**Cadence.** Weekly pack: weekly points on the graded dates. Nightly connector: the same, with a provisional current week. Termly: `working` only, retrospective mode (§4.8).

**Evidence sentence** (deterministic template, numbers from `inputs`): "Mathematics AA HL: 41% on 12 Nov, 49 points below his own median of 90% in this course (14 weeks of history); his second result outside his band in two weeks." The template never says "F", "failing" or any letter the scale does not carry.

**What it never does.** Compare a student's grade with the class mean; convert scales; read predicted grades as observations; treat a missing assignment as a zero score.

### 4.2 Attendance

**Reads.** `sis.attendance_event` through `sis.v_current_attendance`: `day`, `timetable_period_id`, `session_key`, `code`, `authorised`, `reason_code`, `minutes_late`; `config.vocabulary 'absence_reason'` attributes (`counts_as`, `suppresses`); `sis.school_day`.

**Measures.**

| Measure key | Point | `n_min` | `dir` | Notes |
|---|---|---|---|---|
| `attendance.rate` | 100 × (present + late + remote) / registered, per week, after removing days with `counts_as = 'excluded'` and sessions covered by an absence reason that suppresses `attendance` from **both** numerator and denominator | 3 school days | −1 | unit points; `s_floor` binomial |
| `attendance.lates_10d` | count of `late` in the trailing ten school days (a rolling window evaluated nightly; under a weekly pack, the last ten school days in the data) | 5 school days | +1 | the prototype's `att` threshold lives here |
| `attendance.first_period_lates_10d` | as above, restricted to the first period of the day pattern or `session_key = 'AM'` | 5 | +1 | exists only where a period reference exists; otherwise the dimension says "daily register only" (pass 2) |
| `attendance.unexplained_10d` | count of `absent` sessions with `authorised` false or NULL in the trailing ten school days | 5 | +1 | "two afternoons unaccounted for" |

**Rules beyond §3.4.**

- *Lateness.* Fires when `lates_10d ≥ att` (school tolerance, default 3, range 1 to 6) **and** `lates_10d ≥ p90_personal + 1`, where `p90_personal` is the 90th percentile of the student's own ten-day counts across the baseline window. Weak at the threshold; moderate at `att + 2` or when it persists across two consecutive non-overlapping ten-day windows. Both conditions are required: the first is the school's tolerance, the second the personal deviation; a student whose normal is four lates a fortnight does not fire at three.
- *Unexplained absence.* `unexplained_10d ≥ 2` and above the personal band: weak; `≥ 4`: moderate. An unexplained absence that a later import re-codes as authorised withdraws the signal (§13.7).
- *Policy floor.* Trailing four-week `attendance.rate < chronic_threshold` (default 90, the ten-percent chronic-absence convention; the school sets it under its ADEK policy) raises rule `attendance_policy_floor` at **review at most, once per term**, and not while the improving guard holds. This is the only level rule in the domain and it is a school policy, not a comparison.

**Cadence.** Weekly pack: the rolling ten-day measures are evaluated once per pack against the last ten school days it contains, so "within two school days" starts at the commit (pass 2 §6.3). Nightly connector: nightly. Termly: retrospective (§4.8).

**Evidence sentences.** "Attendance 84% this week against her own band of 94 to 100% (20 weeks); the second week outside it." "Three late arrivals in the last ten school days; her own record is none or one."

### 4.3 Engagement

**Position.** CONTEXT.md §11.8 names this domain self-referential and privacy-sensitive; pass 1 left the source and retention open (open decision 10) and pass 2 made Google Classroom a connector pass 4 must approve. This pass designs the domain and ships it **disabled by default** (`engine.thresholds.domains.engagement.enabled = false`), to be enabled per school after pass 4's rule and the school's disclosure. Disabling is the guarded kind (§10.3): the sheet says the domain is off.

**Reads.** `engagement.activity_event` (`source`, `kind`, `occurred_at`) for sources `caros` and `google_classroom` only; open items from `uni.*` (nudges, document requests, statement versions), `ib.*` checkpoints, `discovery.*` tasks, to establish expected activity. It reads timestamps to the day. It never reads content, and the "after 01:00" measure of the prototype is not built (§0.2).

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

**Measures.** `behaviour.points_week`: the week's sum of negative points (or the count of negative incidents where the school records no points), `dir +1`, `s_floor` Poisson, `floor` 3 points per fortnight (the shock statistic is the trailing two-week sum against `2m`). Positive-polarity records are not a series; they are positive evidence (§4.7).

**Rules beyond §3.4.** A **serious incident** (`serious = true` or `severity ≥ 3`: suspension, exclusion, a safeguarding-tagged category) raises rule `behaviour_serious_incident` immediately at the level the school configures (default moderate; a school may set exclusion to urgent), no baseline required. The engine never reads `description`.

**Cadence.** Weekly pack; nightly connector; termly retrospective.

**Evidence sentence.** "Seven conduct points in the last two weeks; his own record over 20 weeks is none to two."

### 4.5 Teacher concern

**Reads.** `signal.teacher_flag` (kind, tags, author, lesson_at, status), `config.vocabulary 'flag_tag'` with attributes this pass adds: `severity` (1 to 3) and `safeguarding_relevant` (boolean).

**Default tag attributes** (seeded from `FLAG_KINDS`, `index.html:3557`; the school edits them): Distressed or upset (3, relevant); Conflict with peers (2, relevant); Left lesson early (2, not); Withdrawn / quiet (2, not); Sudden drop in work (2, not); Appears tired (1, not); Missing homework (1, not); Disengaged in class (1, not).

**Level.** Concerns are events, not a series. Within a window of `corroboration_window` school days (default 7, range 3 to 10):

| Condition | Domain level |
|---|---|
| one concern, all tags severity ≤ 2 | weak |
| one concern with a severity-3 tag | moderate |
| two concerns from **independent** authors (distinct `author_person_id`) | strong |
| `corroboration_staff` (default 2) independent authors with any `safeguarding_relevant` tag, or three independent authors | strong, and the tiering table's **urgent** row (§8.1) |

A concern with status `reviewed` still counts for its window (the counselor saw it and chose not to attach; it is still an observation). A concern the counselor `dismissed` does not. Free text is never parsed for level; pass 5 may summarise it for the headline. A `note` flag acts through suppression or information (§6); a `positive` flag is positive evidence (§4.7).

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

The prototype's "application completeness" series is the pack view over time; `application_stall` is its zero-slope detector. Nothing here compares students, and nothing here uses an admission probability (removed by pass 1, replaced by pass 5).

### 4.7 Positive change, recovery and relapse

**Positive evidence** items come from: a favourable-outside week on any measure (an attainment series above its band), a `positive` teacher flag, a positive-polarity behaviour record, a completed mentor session, a document or statement milestone. They render in the evidence chain with polarity `positive` and level 1 to 3 (a teacher's "recovered after support" is 2; a favourable week is 1). They do not subtract from anything.

**Recovery** (C20) is detected on the **triggering measures** of an open case, `Q* = { q : a signal on q is attached to the case with status open }`; for a case a person opened (C2) with no engine signal, `Q*` is the set of measures at level ≥ 1 in the week it was opened, or the measures the counselor ticked when opening it, and the file shows which: every `q` in `Q*` has been inside its band (with the floor) for `recovery_weeks` consecutive valid weeks (default 3, range 2 to 6) and `S[q] = 0`. Then:

- if the case is at stage `act`, `follow` or `measure`: tier `good`, `moved_why` "third consecutive week inside his band on both measures that opened the case"; the counselor acknowledges and closes (C18) with `monitoring_until = closed_at + monitoring_days` (90).
- if the case is still at `triage` (never accepted): the engine closes it with outcome `resolved` and note `self_recovered`; it is recorded for tuning, because a case that recovers before anyone acts is either a false alarm or a check-in that never happened, and the counselor's judgement decides which.

**Relapse** (C19): a closed case inside `monitoring_until` whose triggering measures include one that reaches level ≥ 2 again opens a new case with `relapse_of_case_id`, and the tiering table treats relapse as **one tier above** what the fresh evidence alone would give, with a minimum of `checkin` (Hana: attendance strong plus engagement moderate is `checkin` fresh, `urgent` as a relapse). The analogy is with the clinical finding that prior episodes are among the strongest predictors of recurrence (Burcusa and Iacono 2007, for depression); it is an analogy and is labelled as such in the rule's description, and the counselors can set the uplift to zero (§10). The relapse case's evidence chain includes the closed case's outcome and the intervention that was tried, as `case_history` items.

### 4.8 Cadence modes per domain

Pass 2 §6.3 defined the modes; this is what the engine does in each.

| Delivery | Academic | Attendance | Behaviour | Teacher | Engagement | University |
|---|---|---|---|---|---|---|
| Nightly connector | weekly points, provisional current week; nightly evaluation | nightly rolling ten-day measures | nightly | live | live / nightly | live |
| **Weekly pack** (the pilot's design point) | points on graded dates; **backfill evaluation** at commit (§13.5) | rolling measures against the last ten school days in the pack | weekly | live | live | live |
| Fortnightly pack | each week in the pack is its own observation; persistence counts weeks of data, so one fortnightly file can satisfy `persist = 2` | as weekly | as weekly | live | live | live |
| Termly | **retrospective**: `academic.<section>.working` per reporting window | retrospective: term attendance rate | retrospective: term points | live | live | live |

**Retrospective rules** (`retro.academic`, `retro.attendance`, `retro.behaviour`): the current term's value against the student's own prior terms (at least two, in the same section for academic); `s` from the prior terms with the scale floor; fires at moderate when `d ≥ floor` and `z ≥ 2`; **tier cap `review`** (`engine.tiering.retrospective_cap`), because a two-day SLA on twelve-week-old data would be a false promise; the evidence sentence names the export ("from the Semester 1 export, as of 12 January"); recovery is the next term back inside. The sheet marks the domain "termly" and the morning ritual is driven by the live domains. `ingest.expected_cadence` selects the mode per import kind; a school that moves from termly to weekly changes modes without a deploy.

---
## 5. Cold start

Grade 9 entrants, mid-year transfers and new sections have no personal history. The rule is that the engine **never substitutes another student's history for the missing one**. What it does instead, in order of how much history exists:

**No history (`H = 0`).** Everything that needs no baseline still runs: teacher concerns and corroboration (§4.5), serious behaviour incidents (§4.4), the university rules (§4.6), the attendance policy floor (§4.2) and lateness at the school's tolerance (`lates_10d ≥ att`, without the personal condition). The sheet shows `none` cells; the file says "building a baseline: 0 of 8 weeks" and lists what is being watched meanwhile. The case, if one opens, prints `cold_start = true` and the tier is capped at `review` unless a teacher-concern or serious-incident rule says otherwise.

**Self-starting phase (`1 ≤ H < min_history_band`).** From the third valid point, the engine runs the CUSUM in **self-starting** form (Hawkins 1987; Quesenberry 1991 for the short-run principle): the running median and MADn of the points so far stand in for the baseline, the scale is inflated by `sqrt(1 + 1/H)` to reflect its own uncertainty, and only the strong shock (`z ≥ 5` with `d ≥ 2·floor`) may produce a level above weak. Computed (§3.6): with four weeks of history and the recommended defaults a quiet student shows a false moderate in 6% of weeks and a 3σ shift is caught with a median delay of one week; that is why the phase is capped at weak, and why a genuine collapse in a new student's first month still surfaces, at `monitor`, with the evidence.

**Band phase (`min_history_band ≤ H < min_history_full`).** The band is drawn and the run is real; levels are capped at weak except the strong shock. The file says "baseline from 9 weeks: settling".

**Full (`H ≥ min_history_full`).** The ladder of §3.5.

**Bringing history in.** Two imports shorten cold start for most of the school and both are questions for ACS (pass 2 question 83; §Questions): two academic years of history at onboarding makes Grades 10 to 12 warm on day one for attendance, behaviour and any section that continues; and, for Grade 9 entrants who came up from the same SIS, the middle-school attendance and behaviour rows are the student's own history and are used as such (academic sections are new regardless). A transfer from another school brings nothing, and the engine says so.

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
| School-wide common cause | computed nightly (§7.6) | the whole school moved this week | level cap at weak for the week, ops note |

### 6.2 The logic

For each check the engine evaluates a predicate over the student's facts and writes `{check, outcome, detail}` to `evaluation.suppressions`:

```
exam_period(d, t)       : a calendar period of kind exam_period or mock_period, active in week t, whose affects_domains contains d and whose year groups include the student's
soften_period(d, t)     : a period whose engine.suppression entry is 'soften' (Ramadan, other): floor(q) × soften_factor (default 1.5) for measures in d, and the level is capped at moderate
authorised_absence(t)   : any attendance row in week t whose reason suppresses attendance; the covered sessions leave both sides of the rate; if the reason covers ≥ 3 school days the whole week is suppressed for attendance and engagement, plus after_days (default 2) for engagement
study_leave(t)          : a reason whose suppresses includes academic: the week is suppressed for academic and engagement
section_change(q, t)    : the section of measure q started in week t or t−1: suppressed for that series for two weeks
transfer_in(t)          : enrolment status transferred_in with joined_on inside the last settling_weeks: attendance and engagement capped at weak
counselor_context(d, t) : a case_context with effect 'suppress' whose validity covers week t and whose kind suppresses d
teacher_note(d, t)      : a note flag in week t whose tag suppresses d: suppresses at half weight, meaning the week is excluded from detectors but not from the baseline, until an SIS row confirms it
common_cause(d, t)      : §7.6
```

**Suppress versus soften versus inform.** Context that *explains* a deviation (an authorised absence, an exam, a subject change) suppresses. Context that *adds risk* (a family situation the counselor knows about) does **not** lower anything: it is recorded, it appears in the evidence chain as context, and it may route the case (to a pastoral colleague) but it never reduces the tier, because a known difficulty is a reason for more attention, not less. The prototype lets "Family circumstance noted: pastoral route" reduce the score; this plan does not, and it is listed in Challenges. Each `context_kind` carries its effect as data, so a school that disagrees can change it, visibly.

**Default `context_kind` rows** (platform, overridable): `authorised_absence_confirmed` (suppress attendance, engagement; 14 days), `assessment_context` (suppress academic for named assessments), `subject_change` (suppress the section's series; permanent), `known_medical_condition` (soften attendance; validity as entered), `family_circumstance_known` (inform), `support_in_place` (inform), `informal_contact_made` (inform; also sets last contact), `pastoral_route` (route: no tier change; owner may change).

**Re-evaluation on context.** Adding context queues an event evaluation of the student (C9); the tier that results is whatever the rules give under the suppression, which may be lower, and the tier history row references the re-evaluation so the downgrade is explainable ("attendance suppressed for 4 to 13 Nov: authorised medical absence confirmed by Ms. Haddad; the remaining evidence is one domain at moderate: review"). No arithmetic on a score.

**What suppression never does.** It never hides a teacher concern, a serious incident, a relapse, or a university deadline rule; those are not deviations to be explained. And it never suppresses across the whole school by default: the common-cause guard caps, it does not silence.

---

## 7. Combination, persistence and immediacy

### 7.1 Domain levels and breadth

At the end of §3 to §6 the engine holds, per student, per domain, a level `L[d] ∈ {0,1,2,3}`, a persistence `P[d]` (the maximum over its measures), an onset, and the evidence items. **Breadth** `B` is the number of distinct adverse domains (academic, attendance, engagement, behaviour, teacher) with `L[d] ≥ 1` whose evidence falls inside the **corroboration window** (`breadth.window_weeks`, default **2** school weeks ending at as-of, range 1 to 4; three weeks was the first choice and the tier-level simulation showed it adds noise without adding any of the authored cases). The university domain contributes its own rules to the tier but not to breadth, because a deadline is not a change in the student. Two measures in one domain are not breadth (two subjects declining is one academic domain, printed with its own breadth); a teacher concern plus a series deviation is (§2.2).

### 7.2 The combination table

Combination is a lookup on `(max level M, breadth B, persistence, special rules)`, stored as the `engine.tiering` rule set, never a weighted sum. The default rows, in order of precedence (the first matching row wins):

| # | Condition | Proposed tier | Rule key on the signal |
|---|---|---|---|
| 1 | relapse (§4.7): fresh tier from the rows below, raised by `relapse_uplift` (default 1) with a minimum of `checkin` | as computed | `relapse` |
| 2 | teacher domain strong with a safeguarding-relevant tag, or three independent concerns in the window | urgent | `corroboration` |
| 3 | a school-defined urgent event (a behaviour category with `urgent = true`) | urgent | `behaviour_serious_incident` |
| 4 | `M = 3` in two or more domains | urgent | `baseline_deviation` |
| 5 | `M = 3` in one domain | checkin | `baseline_deviation` |
| 6 | `M ≥ 2` in two or more domains, at least one with `P ≥ persist` | checkin | `baseline_deviation` |
| 7 | teacher domain strong (two independent concerns) | checkin | `corroboration` |
| 8 | teacher domain moderate and any other domain `≥ 1` | checkin | `corroboration` |
| 9 | `L = 1` in two or more domains for `persist_weak` consecutive weeks (default 3) | checkin | `combined_weak_signal` |
| 10 | `post_offer_decay` or `deadline_critical` or `reference_sla` inside `deadline_critical_days` | checkin | the rule's key |
| 11 | `M = 2` in one domain | review | `baseline_deviation` |
| 12 | teacher domain weak or moderate alone | review | `teacher_concern` |
| 13 | any university rule at moderate | review | the rule's key |
| 14 | retrospective-mode signal | review (cap) | `retro.<domain>` |
| 15 | a single shock (`shock_opens_monitor`, default true); outside the band in two of the last three valid weeks; `S ≥ h` not yet persisted; cold-start signals; `list_fit`; `predicted_vs_working`; `baseline_established` | monitor | the rule's key |
| 15a | outside the band in one week only, nothing else | **no case**: a soft cell on the run and a line in the file's baseline tab ("one week outside the band; the engine is watching") | |
| 16 | recovery detected on an open case at `act`/`follow`/`measure` | good | `recovery` |
| 17 | nothing | no proposal (a quiet row) | |

The prototype's nine rule keys (`baseline_deviation`, `engagement_decay`, `list_balance`, `list_fit`, `reference_sla`, `relapse`, `corroboration`, `post_offer_decay`, `combined_weak_signal`) all appear; `engagement_decay` is the engagement domain's silence rule (§4.3) and reaches tiers through rows 6, 8, 11 and 15. Every row is data: a school can move `combined_weak_signal` to review, or set `relapse_uplift` to 0.

**Reproducing the fifteen authored cases** with this table and the recommended defaults (the engine-reproduces-seed test, §15.1), worked from each case's own series:

- *Ahmed* (`s1`): Mathematics 91, 93, 89, 92, 90, 88, 74, 41; baseline median 90.5, `s` at the floor 3.0; week 7 is a strong shock (`z = 5.5`) that takes `S` to 5.3; week 8 is another strong shock with `S` already at `h`: academic **strong**. Punctuality 100, 100, 98, 100, 96, 88, 76, 70; median 100, `s` at the binomial floor 3.6; week 6 is a shock, week 7 a strong shock with `S` already above `h`: attendance **strong**. Two strong domains, row 4: **urgent**, with a teacher concern and the engagement decline (if enabled) as breadth. The prototype's narrative ("each signal alone would sit in Monitor") is not what his own numbers say, but the tier matches.
- *Layla* (`s2`): with engagement disabled, `application_stall` (statement unchanged 21 days) and `deadline_critical` (the UCAT window closes in 9 days): row 10, **checkin**. With engagement enabled, silence of 21 days against a median gap of two days adds a moderate domain.
- *Sara* (`s3`): `list_balance` at T−18, **review**. *Yousef* (`s4`): one mock result in the mock series, which is cold: a single shock, **monitor**. *Omar* (`s6`): `list_fit`, **monitor**. *Noor* (`s16`): `reference_sla` at T−11, **review**; **checkin** at T−10.
- *Tariq* (`s12`): three independent concerns in four school days, row 2, **urgent**; conduct points 0, 0, 1, 0, 0, 1, 4, 7 against a zero median with the Poisson floor are strong by week 8 as well.
- *Hana* (`s13`): with episode exclusion (§3.2) her baseline is 95 to 97 and `s` is the binomial floor 3.6; 86 is outside the band (`z = 2.8`), 79 a shock with `S` past `h` for a second week: attendance **moderate**, engagement moderate if enabled. Fresh tier `review` (row 11; `checkin` with engagement on), relapse uplift of one: **checkin**. The prototype has her urgent; she reaches it with `relapse_uplift = 2` (open decision 4), or a week later if the decline continues. This is the one authored tier the defaults do not reproduce on the day.
- *Priya* (`s14`): first-period punctuality 100, 100, 98, 100, 96, 90, 84, 80 (`s` at the floor 3.0): week 6 is a shock, week 7 a strong shock with `S` already above `h`: attendance **strong** on its own (row 5, **checkin**), before the combined-weak rule is needed; the night-activity measure is not built (§0.2). Tier matches; the reason printed differs from the prototype's copy.
- *Daniel* (`s15`): submission 95, 92, 96, 90, 94, 71, 48, 33, strong by week 7, with a conditional offer: `post_offer_decay`, **checkin**.
- *Maryam* (`s5`): attendance back inside the band in weeks 7 and 8; `good` arrives with the **third** inside week, one week after the seed's narrative. *Ivan* (`s17`): attendance and attainment inside the band for weeks 6, 7 and 8: **good**.
- *Zayd*, *Maya*, *Fahad* and the 72 generated students: nothing crosses; quiet rows.

Thirteen tiers match on the authored day, Maryam's matches a week later, and Hana sits one tier below the prototype under the default relapse uplift; the test's expected diff is exactly that list. If the pilot's counselors want breadth of three with one strong domain to be `urgent` (the prototype's telling of Ahmed), that is one row they can add.

### 7.3 Persistence

`persist` (default 2 weeks, range 1 to 6) is the number of valid weeks a CUSUM signal must hold before a measure is moderate, and `persist_weak` (default 3, range 2 to 6) is the number of consecutive weeks two weak domains must co-occur before they combine. Persistence is counted in **weeks of data**, not calendar weeks and not nightly evaluations: a null week neither advances nor resets it (§3.8); a fortnightly pack advances it by two. The prototype's single `persist` slider (1 to 6, default 3, "consecutive weeks a weak signal must repeat before it escalates") maps to `persist_weak`; the default moves from 3 to 3, unchanged, and `persist` for moderate is new at 2.

Persistence is what the "how long it has persisted" tile shows (the window from the CUSUM onset, §3.4) and what stops the fresh-shock false alarm in §3.6 from reaching a card: the computed noise for a single-week CUSUM crossing is 2.5% of series-weeks; for a two-week hold it is 0.65%.

### 7.4 Recovery

§4.7. The positive tier is reached only from an open case, only on the measures that opened it, only after `recovery_weeks` inside the band with the CUSUM at zero, and never while a triggering domain still carries a level. Positive evidence from other domains is shown and changes nothing; the counselor may close on it by hand, with the reason recorded.

### 7.5 Should a teacher concern trigger evaluation immediately? Yes, and so should two other inputs

The overnight sweep is the ritual because the series change when data arrive, and data arrive nightly or weekly. Three inputs do not: a teacher concern, counselor context, and an enrolment change (a student leaves, a student joins). The argument for evaluating those on arrival rather than at 02:00:

- **The safeguarding pattern is a same-day pattern.** Tariq's third concern arrives on day four. Under a nightly-only design the corroboration rule fires the next morning; the referral the school's policy requires waits a school day for no reason but the batch. Ms. Bianchi's, Mr. Osei's and Ms. Iqbal's observations are already in the system.
- **The teacher's loop closes now or never.** The prototype tells a teacher "the engine attached his maths decline and punctuality drop within seconds" and the teacher page says "You will be told what happened with it". A concern that sits in a queue until 02:00 and is attached at 07:04 is a form the teacher filled in; a concern that comes back enriched within minutes is a conversation. The teacher-recognition evidence (§2.2) says teachers under-refer moderate and internalising cases; the cheapest thing the product can do about that is make the act of logging visibly worth it.
- **Counselor context is an action with an expected reaction.** The prototype recalculates on the spot (`data-ctxpick`), and pass 1 (C9) already links the re-evaluation to the context row. A counselor who adds "authorised medical absence confirmed" and sees nothing move until tomorrow will stop adding context.
- **The cost is one code path and one discipline.** The worker already runs `sweep.run`; an `event` run over one student reuses the pure function with last night's snapshots plus the new event. The discipline is the asymmetry below.

The argument against, and the design that answers it: daytime evaluation could turn the queue into a ticker and reintroduce the fatigue the nightly ritual avoids. So:

1. An event evaluation may **open, attach, or raise**; it may **lower** only in response to counselor context (C9), which is the counselor's own act. Everything else that would lower waits for the night and for hysteresis (§8.3).
2. "What changed overnight" is computed **only** by the nightly run against the last successful nightly run. Daytime changes appear in a separate, smaller list on the sheet, "since this morning", with the time and the cause ("11:07 · concern from Ms. Iqbal"), so the ritual stays a ritual.
3. Each daytime raise is written with `sweep_trigger = 'event'` and the triggering record's id in `rule_hits`, so the audit answers "why did this move at 11:07".
4. Event runs are rate-limited per student (one evaluation per five minutes; later events coalesce) and never run for a student whose tenant is in retrospective-only mode for every series domain, because there is nothing for them to read.

An import commit is the fourth candidate (pass 2 open decision 12). The recommendation: **yes for the scheduled weekly pack**, as the backfill evaluation (§13.5), because the pack's arrival *is* the ritual moment for a weekly school, and it should not wait until the following night; the sheet prints "updated 09:32 after this week's import" once, not a stream. **No for ad-hoc uploads and corrections** during the shadow period, unless the school's policy row says otherwise; corrections re-evaluate at night and withdraw signals as §13.7 describes.

### 7.6 The common-cause guard

Per domain per week the sweep computes the share of students with a valid band whose measure is adverse-outside this week. If it exceeds `common_cause_share` (default 25%), the week is marked `common_cause` for that domain: levels from that week alone are capped at weak, the sweep writes an ops note ("attendance: 31% of students outside band in the week of 17 Nov; is there an undeclared calendar event?"), and the `school_admin` is prompted to declare a `calendar_period`. Nothing compares one student with another: no student's tier depends on where they stand relative to others, and the check asks only whether the *school* moved. It is listed in Challenges because it sits near invariant 2, and the counselors are asked whether they want it (§Questions).

---

## 8. Tiers, their SLA meaning, and hysteresis

### 8.1 What each tier means, in engine terms

The tiers are invariant 1 and the engine does not touch their names, order or SLA text. What it fixes is the evidence each one requires and the promise each one makes:

| Tier | SLA (`PRIO`, `index.html:1301`) | Engine entry (from §7.2) | The promise | Exit |
|---|---|---|---|---|
| `urgent` | Route now under school policy | rows 1 to 4 | the counselor should refer, escalate or act **today**; the engine has found either independent human corroboration, a school-defined event, a relapse, or strong change in two domains | never lowered by the engine within `person_raised_hold_days` if a person set it; otherwise by hysteresis |
| `checkin` | Within 2 school days | rows 5 to 10 | worth a conversation this week; the SLA clock starts at the sweep (or at the commit under weekly delivery, pass 2) and is computed with `sis.add_school_days` | hysteresis |
| `review` | This week | rows 11 to 14 | worth a look; one domain has moved, or a deadline rule holds, or a teacher noticed something once | hysteresis, or the counselor's dismissal |
| `monitor` | No action required | row 15 | the engine has seen something isolated and is watching; `auto_review_on` in `auto_review_days` (14) | auto-review (§8.4) |
| `good` | Acknowledge | row 16 | the measures that opened the case have held inside the band for `recovery_weeks` | the counselor closes; or relapse |

### 8.2 The movement rules

- The engine **raises** a tier as soon as an entry row matches (subject to the daytime asymmetry in §7.5).
- The engine **lowers** a tier only under hysteresis (§8.3).
- A **person's** change (C10) outranks the engine for `person_raised_hold_days` (default 14) in the direction they moved it: the engine does not lower a tier a person raised, and does not raise a tier a person lowered, within that period, **unless** a new domain contributes, a new teacher concern arrives, or a measure reaches strong. The exception exists so that a counselor's "not this week" does not become blindness to new evidence; the tier history row says which exception applied.
- A **dismissed** case (C11) gets a cool-down of `dismiss_cooldown_days` (14) during which the same rule on the same measures cannot reopen it; new domains or strong levels can. This is Ancker's within-patient repeat rule applied to a queue.
- A **merged** case (C12) carries its signals into the target; the source's tier history closes.
- The engine writes at most **one** engine-driven tier change per case per 24 hours, and at most **two** per case per 7 days; a third is held, `tier.held_by_hysteresis` is emitted, and the case is listed on the thresholds page as oscillating, which is a tuning signal about the thresholds, not about the student.

### 8.3 Hysteresis, precisely

A tier has an entry condition (its row in §7.2) and an **exit** condition that is deliberately weaker, so that a series hovering at the edge does not flip nightly:

```
exit(measure)  ⇔  S < h_exit  (h_exit = h / 2)   and   not outside the band this week
exit(domain)   ⇔  every measure in the domain satisfies exit(measure)
lower(case)    ⇔  the case's current tier's entry row no longer matches
               and  for every triggering domain, exit(domain) has held for exit_weeks (default 2) consecutive valid weeks
               and  at least one new valid observation has arrived for each triggering domain since the tier was set
               and  no person raised the tier within person_raised_hold_days
               and  at least 24 hours since the last engine change and fewer than 2 engine changes in 7 days
```

When `lower` holds, the new tier is the highest row that still matches (not necessarily one step down), and `moved_why` names the exit ("attendance has been inside her band for two weeks; the case rests on engagement alone: review"). A **withdrawn** signal (§13.7) bypasses the exit-weeks condition, because the evidence was wrong, not weak.

Under weekly delivery "consecutive valid weeks" are weeks of data, so a tier set on Monday cannot be lowered by the engine before the pack two Mondays later. That is the intended pace: a counselor who acted on a check-in should not find it gone before the follow-up.

### 8.4 Auto-review of `monitor`

At `auto_review_on` the engine re-evaluates: if every measure has been level 0 for the last two valid weeks, it closes the case as `not_a_concern` with note `auto_review_quiet` (C21); if anything is still weak, it sets the next review two weeks out; after three quiet-or-weak reviews (about six weeks) it closes regardless, because a monitor case that never escalates is noise the sheet should stop carrying. A monitor case never counts against the counselor's precision.

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
| **Dimension statuses** (`critical` / `watch` / `good`) | **Defined** | `dimensions` rule set: `si-attendance`, `si-punctuality`, `si-academic`, `si-engagement`, `si-behaviour` are `critical` at domain level ≥ 2 or a fired policy rule, `watch` at level 1, `good` otherwise, each with the note template ("2 results outside band"); the five application dimensions keep the prototype's logic as parameters (`stmt_watch_below: 90`, `deadline_critical_days: 10`, `docs_critical_outstanding: 3`, `progress_watch_below: 80`, `progress_critical_below: 40`) |
| **Run cells** | Kept | With the floor (§3.4) |
| **Baseline chart band** | Kept | `[m − c·s, m + c·s]` from the snapshot |
| **Admission probability** | out of scope | pass 1 removed it; pass 5 replaces it |

The case header therefore prints: tier and SLA; evidence level; persisted (window); breadth. Every one traces to columns on `signal.evaluation` and `signal.signal.inputs` (§16).

---
## 10. Counselor control

### 10.1 The parameters

Three rule sets, all `config.rule_set_version` rows (pass 1), all per school with a platform default, all validated against a JSON schema published from `packages/engine` (`schema_version` on the row). A counselor sees them as one thresholds page with sections; the engine reads them as three documents.

**`engine.thresholds`** (what counts as a change):

| Parameter | Scope | Default | Bounds | Prototype slider |
|---|---|---|---|---|
| `domains.<d>.enabled` | per domain | true; **engagement false** | | |
| `baseline.window_weeks` (`W`) | global | 20 | 8 to 30 | |
| `baseline.min_history_band` | global | 8 | 4 to 12 | |
| `baseline.min_history_full` | global | 12 | 8 to 20 | |
| `baseline.settling_weeks` | global | 1 | 0 to 3 | |
| `band.c` | per scale family | 2.5 (ordinal 1.5) | 2.0 to 3.5 | |
| `shock.z` | per scale family | 3.0 (ordinal 3.5) | 2.5 to 4.5 | `acad` (1 to 4 σ) becomes this, in robust units |
| `shock.z_strong` | per scale family | 5.0 | 4.0 to 8.0 | |
| `shock.opens_monitor` | global | true | | |
| `cusum.k` | global | 0.5 | 0.25 to 1.0 | |
| `cusum.h` | global | 5 | 3 to 8 | |
| `cusum.h_strong` | global | 8 | `h + 1` to 15 | |
| `cusum.strong_mean_factor` | global | 1.5 | 1.0 to 3.0 | |
| `scale_floor.<scale family>` | per scale family | §3.3 (pct 3.0 points; attendance `max(3.0, binomial)`) | 0 to 25% of range | |
| `breadth.window_weeks` | global | 2 | 1 to 4 | |
| `persist` | global | 2 | 1 to 6 | |
| `persist_weak` | global | 3 | 2 to 6 | `persist` (1 to 6 wks) |
| `persist_free` | global | 3 | 2 to 6 | |
| `floor.<measure>` | per measure | §3.3 | 0 to 25% of the measure's range | |
| `attendance.lates_per_10_days` (`att`) | | 3 | 1 to 6 | `att` (1 to 6) |
| `attendance.unexplained_weak` / `_moderate` | | 2 / 4 | 1 to 5 / 2 to 8 | |
| `attendance.chronic_threshold_pct` | | 90 | 80 to 95 | |
| `behaviour.serious_categories` | | from the vocabulary | | |
| `teacher.corroboration_staff` | | 2 | 2 to 4 | |
| `teacher.corroboration_window_school_days` | | 7 | 3 to 10 | |
| `teacher.tag_severity.<tag>` | per tag | §4.5 | 1 to 3 | |
| `engagement.silence_days` (`eng`) | | 14 | 5 to 28 | `eng` (5 to 28 days) |
| `engagement.gap_multiplier` | | 2.0 | 1.5 to 4.0 | |
| `university.T_balance` / `T_ref` / `stall_days` / `deadline_critical_days` | | 21 / 14 / 14 / 10 | 7 to 45 / 7 to 30 / 7 to 30 / 3 to 21 | |

**`engine.tiering`** (what a change is worth): the rows of §7.2 as an ordered list of `{condition, tier, rule_key}` with the conditions expressed in a small closed grammar (`max_level`, `breadth`, `persisted`, `domain_level`, `rule_fired`, `relapse`), plus `relapse_uplift` (1; 0 to 2), `retrospective_cap` (`review`), `hysteresis.exit_weeks` (2; 1 to 4), `hysteresis.exit_h_factor` (0.5; 0.25 to 1.0), `hysteresis.person_raised_hold_days` (14; 3 to 60), `hysteresis.dismiss_cooldown_days` (14; 3 to 60), `hysteresis.max_engine_changes_per_week` (2; 1 to 5), `recovery_weeks` (3; 2 to 6), `common_cause_share` (0.25; 0.10 to 0.60), `budget.new_action_cases_per_fortnight` (10 per counselor; 2 to 40). `case.lifecycle` (pass 1) keeps `monitoring_days` (90) and `auto_review_days` (14).

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

The thresholds page calls the engine's pure function (§13.1) over the last twelve weeks of stored `feature_snapshot` rows for the school with the **proposed** configuration and returns, per week and per tier, how many cases would have been opened or raised, which current open cases would move, and which measures would oscillate (more than two crossings of `h` in the period). It is the replacement for the prototype's "current false-positive rate 14%" and the mechanism behind guards 3 and 6. It writes nothing; it is a read of snapshots plus a computation, and it runs in seconds at pilot scale (87 students, about 900 series, twelve weeks).

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
| 6 | Attendance 98% to 89% over three weeks, with a medical note covering one of the days | `floor.attendance`, suppression |
| 7 | One teacher concern, "withdrawn / quiet", nothing in the data | single-concern tier (`review`) |
| 8 | Two teachers' concerns in four days, one naming a peer conflict | `corroboration_staff`, safeguarding-relevant tags, what "route now" means to them |
| 9 | Seven conduct points in two weeks from a student with none before | `floor.behaviour`, serious categories |
| 10 | A Grade 12 with a conditional offer whose submissions have halved since the offer | `post_offer_decay` and whether it is a check-in |
| 11 | A student who recovered in October and whose attendance has fallen again in the same way | `relapse_uplift` |
| 12 | Two weak signals in different domains, both inside "not quite outside the band" territory, three weeks running | `combined_weak_signal`, `persist_weak` |

**Part B · Direct questions (20 minutes),** answered on a scale first and then discussed: how many percentage points of attendance, in a fortnight, is a change worth your time; how many grade points; how many lates in ten days; how many conduct points in a fortnight; how many days of silence on the university journey in October versus in March; how many weeks should something persist before it is a card rather than a mark on the sheet; how many teachers noticing the same thing, in how many days, is a referral.

**Part C · The budget (10 minutes).** "On a normal Monday, how many new names would be useful, and at how many would you stop opening them?" Asked twice: for check-in and above, and for review. And: "If the engine had to choose between missing one student who needed you and sending you three who did not, which would you rather it did?" (this calibrates §1.3 and is asked as a preference, not a puzzle).

**Part D · Context (10 minutes).** Which weeks of the year are noisy and expected (exam weeks, mocks, Ramadan, the first fortnight, the week before a holiday, the IB deadlines); which absence reasons should silence attendance signals; whether a known family situation should make a signal quieter, louder, or the same (the plan's default is *the same*, and this is where the counselors overrule it if they want to).

**Part E · Safeguarding (5 minutes, with the CPO present if possible).** Which tags or combinations must route to the CPO regardless of anything else; whether the engine may propose `urgent` for a corroboration pattern or must stop at `checkin` and leave the routing entirely to the counselor.

**Part F · Shadow mode (5 minutes).** Explain the counselor log (§14.2) and ask what they would want to be able to record in it in under thirty seconds a day.

**From answers to parameters.** Each answer maps to a parameter by a written rule so the mapping can be audited: Part B numbers become floors and thresholds directly (the median of the four, rounded to the parameter's step); Part A's "when would you act" for cards 1, 4, 6 and 9 sets the tier each single-domain level maps to (rows 5 and 11 of §7.2); card 8 sets the corroboration row; card 11 sets `relapse_uplift` (2 if three or four say "today", 1 if they say "within two days", else 0; the prototype's Hana needs 2 to be urgent on the day, §7.2); card 12 sets `persist_weak`; Part C sets `budget.new_action_cases_per_fortnight` (the median of the "useful" number, times ten school days, halved for safety) and the miss-versus-false-alarm preference is recorded in the version note; Part D sets `engine.suppression` and the context-kind effects; Part E sets the urgent rows and, if the counselors say the engine may not propose `urgent`, replaces row 2 with `checkin` and a `route_flag` the UI shows. Where the four disagree by more than one step, the default stays, the disagreement is written into the version note, and the caseload lead decides after the shadow period.

---

## 11. Alert budget

### 11.1 What a morning looks like under the defaults

Computed by a second simulation that runs the **whole** of §3 to §8 for a quiet student with ten series (six attainment sections at a floor of 1.25 units of weekly noise, two attendance measures at 1.4, behaviour at 1.5, submission at 1.25; engagement off), twelve weeks of history, the defaults of §3.6 including the scale floor at three-quarters of the noise, the two-week breadth window and the tiering rows of §7.2, then scaled to 87 students; i.i.d. weekly noise, no genuine change, no autocorrelation, no seasonality:

| New items per week from noise alone, 87 students | Normal noise | Heavy-tailed noise (t, 3 d.f.) | Per morning (normal) |
|---|---|---|---|
| `urgent` | 0.0 | 0.5 | 0 |
| `checkin` | 0.7 | 17 | about one a fortnight |
| `review` | 11 | 29 | about 2 |
| `monitor` (cases opened) | 21 | 18 | about 4, quiet rows |
| Soft cells on the run | about 30 across the caseload | about 45 | |

Against that, the same simulation with a **genuine** two-domain change (a two-noise-unit fall in two of six sections and in attendance, starting in week 1) reaches `review` or above for 52% of students by week 2 and 86% by week 3, and `checkin` or above for 52% by week 3, 82% by week 4 and 92% by week 5 (normal noise; under heavy tails 75% by week 4). That is the engine's sensitivity to the case it is built for: a corroborated change is a card within three to four weeks of its onset, and a check-in card within four to five.

Read together: under a normal-noise model the action tiers are clean (one noise check-in a fortnight against the planning assumption of one genuine episode a week, §1.3), the review tier carries about two noise cards a morning, and the monitor tier absorbs the rest. Under heavy tails everything is worse by a factor of two to twenty, and the heavy-tailed column is the more honest planning number until the shadow period measures the real one. If the shadow period shows review noise near it, the levers in order are: the scale floor to the full typical noise (computed: review 7 a week, monitor 9, at the cost of one week's delay to `checkin` on the genuine case: 62% by week 4 instead of 82%); the minimum-meaningful-change floors up by half (halves the persisted-CUSUM noise, §3.6); twenty weeks of history where it exists; and `persist` to 3, which barely changes review noise and is not the first lever. `h` is not a lever.

### 11.2 How the engine keeps the queue actionable

1. **Tiers absorb sensitivity.** Everything weak or isolated goes to the run or to monitor, where it asks nothing.
2. **Repeats are suppressed.** One open case per student (pass 1's unique index); new evidence attaches with a "since yesterday" line rather than a new card; a dismissed case's cool-down (§8.2).
3. **Persistence before attention.** No card without two weeks of data behind a moderate level, or a shock large enough to be worth a look on its own.
4. **Corroboration before urgency.** The check-in and urgent rows need breadth, independence or a school-defined event.
5. **The budget is a tuning signal, never a cut.** `budget.new_action_cases_per_fortnight` (default 10 per counselor) is compared with the rolling count of new `checkin` and `urgent` cases per owner. When the count exceeds it, the sweep emits `budget.exceeded`, the thresholds page shows the what-if run with a suggested floor and persistence change, and the common-cause guard (§7.6) is re-run for the fortnight. **The queue is never trimmed and never reordered by anything but tier and time**, because trimming to a budget would rank students against each other (invariant 2). Within a tier the queue is ordered by the time the case was raised, oldest first, which is the SLA's own order.
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

Run quarterly and at the shadow-mode exit, as a job over pseudonymised evaluation outputs joined to group labels (§12.4), producing an aggregate report and nothing else:

1. **Alert rates by group**, per tier and per rule key: the share of students in each group who received a case at that tier in the quarter. Report the ratio of each group's rate to the highest group's rate. A ratio under 0.8, or over 1.25, is a **screening trigger** for investigation. The four-fifths figure is borrowed from the U.S. Uniform Guidelines on Employee Selection Procedures (29 CFR 1607.4(D)), which treat a selection rate under four-fifths of the highest group's as evidence of adverse impact while warning that small numbers and statistical significance matter; it is used here as a rule of thumb for *looking*, not as a legal standard, and it is paired with Fisher's exact test at each cell. Cells with fewer than five students are suppressed.
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

To test this at all, CAROS must hold nationality, gender, language background and special educational needs status for each student, and none of them is needed to run the engine. Nationality and ethnic origin, and health data (which SEN records are), are sensitive personal data under the UAE's Federal Decree-Law No. 45 of 2021 (Article 1's definition of sensitive personal data includes data revealing ethnic origin and health data), and special categories under GDPR Article 9, which pass 4 treats as the design floor. Holding them for a fairness audit is a recognised purpose with a recent legal template: the EU AI Act (Regulation (EU) 2024/1689) Article 10(5) permits providers of high-risk AI systems to process special categories of personal data strictly for bias detection and correction, subject to safeguards, minimisation, access limits and deletion once the bias is addressed. CAROS is not in that regulation's scope in Abu Dhabi, but the pattern is the right one and pass 4 should adopt it:

- The labels live in their own schema (`fairness.group_label`, §17) imported under a distinct mapping profile with `purpose = 'fairness_audit'`, readable by the audit job and the school's designated lead only. **The engine has no grant on it**, and the "no cohort" check on `band_method` gets a sibling: a test that `packages/engine` imports nothing from that schema.
- The audit joins on `core.person.id` through a per-run rotating key and writes only aggregates with small-cell suppression; the joined working table is dropped at the end of the run.
- The school chooses which labels to supply, and may supply none. If it supplies none, the audit runs on what the SIS already holds for other purposes (year group, programme, home language where present) and **the plan states that fairness by nationality and SEN is then untested**, rather than implying it.
- Retention of the labels follows the shortest class in `privacy.retention_class` and their erasure is independent of the student record's.

Whether ACS will supply the labels, under what legal basis, and whether ADEK's rules add anything, are questions for the school and for pass 4 (§Questions).

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
             sections: { id: UUID; subjectKey: string|null; level: string|null; scaleKey: string; startedOn: ISODate; predecessorSectionId?: UUID }[] };
  series: MeasureSeries[];                         // one per measure: { measureKey, domain, scaleKey, dir, unit, points: {weekStart, value|null, n, thin, provisional}[], sourceRowIds }
  events: { teacherFlags: TeacherFlag[]; behaviourEvents: BehaviourEvent[]; absences: AbsenceSpan[];
            contexts: CaseContext[]; sectionChanges: ISODate[] };
  uni: UniRuleOutput[];                            // list_balance, reference_sla, ... computed by packages/domain from uni.*
  caseState: { open?: OpenCase; closedInWindow: ClosedCase[]; personTierActions: PersonAction[]; dismissedAt?: ISOInstant };
  config: { thresholds: Thresholds; suppression: Suppression; tiering: Tiering; lifecycle: Lifecycle;
            versionIds: { thresholds: UUID; suppression: UUID; tiering: UUID } };
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
              windowStart: ISODate|null; windowEnd: ISODate|null; recovery: boolean; relapseOfCaseId?: UUID; heldByHysteresis: boolean };
  inputHash: string;                               // sha256 over a canonical serialisation of the input
}
```

Guarantees, each asserted by a test: no reads of `Date.now()`, `Math.random()` or the environment (a lint rule bans them in the package); the same input produces byte-identical output (`inputHash` and a golden-file test); the function is total (every input that validates against the Zod schema returns a result or a typed `EngineError` with the measure that failed); versioning by `engineVersion` (semver from the package), with a changelog entry required for any change to a default, a template or a rule. The domain layer (`packages/domain`) is the only caller and owns loading and writing; the engine never sees a database. The same function serves the nightly sweep, the event evaluation, the backfill, the what-if run (§10.4), the shadow run and the tests.

### 13.2 Orchestration

All jobs in `apps/worker` on pg-boss (pass 1 DR-2), queue prefix `sweep.`:

| Job | Singleton key | Does | Deadline |
|---|---|---|---|
| `sweep.schedule` | cron, every 15 minutes | For each active school whose local time has passed `sweep_hour` (default 02:00, `core.school.sweep_hour`) and that has no nightly run for today, enqueue `sweep.run` | |
| `sweep.run` | school + run_date + `nightly` | Insert `sweep_run` (status `running`, the three current version ids, `engine_version`, `deadline_at = 05:30 local`, `students_in_scope`); resolve the students in scope (active enrolments in the counseling year groups, plus students who left in the last day so C22 closes their cases); enqueue `sweep.batch` for groups of 50; enqueue `sweep.finalize` with a dependency on all batches | starts by 02:05 |
| `sweep.batch` | run + batch index | For each student: load the input through `packages/domain` (one query per table, batched by student ids), call `evaluateStudent`, write the result in **one transaction** per student (§13.3); on an exception, record `evaluation.error` and continue | retry 3× with backoff 30 s, 2 min, 10 min |
| `sweep.finalize` | run | Compute the overnight comparison (§13.6); run the DR-6 assertions (`tier_yesterday` recomputed from `case_tier_history`; `week_run()` for a sample of students equals the stored cells); compute the budget and common-cause checks (§7.6, §11.2); refresh `reporting.mv_*`; set `sweep_run.status` (`succeeded`, or `partial` if any student has an error after retries), `finished_at`, `heartbeat_at`; emit `sweep.completed` or `sweep.partial` | by 05:30 |
| `sweep.event` | school + student (coalesced over 5 minutes) | The daytime evaluation (§7.5): a `sweep_run` with trigger `event` and `trigger_ref` (the flag, context or enrolment row), one student, the same write path, the daytime asymmetry enforced in the domain layer | within 5 minutes of the event |
| `sweep.backfill` | school + import | After a weekly or fortnightly pack commits (pass 2 `ingest.after_commit`): §13.5 | within 30 minutes of commit |
| `sweep.whatif` | school + person | The thresholds page's what-if run (§10.4), read-only | seconds |
| `sweep.watchdog` | cron 05:45 local per school | In-database check that today's nightly run exists and `succeeded` or `partial`; if not, emit `sweep.missed` and raise the in-app banner. This is the inside witness; the outside one is §13.8 | |

At pilot scale (87 students, about 900 series) a run is seconds; at 50,000 students it is a few thousand batches and minutes of worker time, well inside the window.

### 13.3 Idempotence

- **One nightly run per school per date.** Pass 1's unique index `sweep_run_one_live_per_date` is narrowed to `trigger = 'nightly'` (§17), so event and backfill runs on the same date do not collide with it.
- **One evaluation per run per student** (pass 1's unique constraint). A batch that retries after a crash re-evaluates the students it had not written; a student already written is skipped.
- **Deterministic ids.** Signals and evidence items get `uuid_generate_v5(evaluation_id, rule_key || measure_key || window_start)` so that a replayed write is an upsert onto the same rows, never a duplicate. Snapshots are content-addressed already (pass 1).
- **One transaction per student**: snapshot upserts, the evaluation, signals, evidence, the case open or move (through the trigger that writes history), events and audit. A crash between students leaves no half-written student.
- **The engine is pure**, so a re-run of any run with the same inputs and versions produces the same rows, and `inputHash` on the evaluation lets a re-run prove it did.

### 13.4 Partial failure

A student whose evaluation throws is recorded (`evaluation.error`, `sweep_run.students_failed`) and retried with the batch; after three attempts the run finalises as `partial`, the evaluated students' results are published, and the failed students keep yesterday's tier with a line on the sheet and the file ("not evaluated last night: an error in the attendance series; the team has been told"). `sweep.partial` goes to the ops channel with the student ids (identifiers only, pass 1's audit rule). A run that cannot start (the database is unreachable, a configuration version fails to load) is `failed`, and the watchdog's absence check covers it. A partial run **is** a successful comparison base for the students it evaluated (§13.6).

### 13.5 Re-runs and the backfill

**Manual re-run.** `sweep.run` with trigger `manual`, a required `reason`, and `supersedes_run_id`. Allowed against a `failed` or `partial` run without further ceremony. Against a `succeeded` run it is allowed only by a support grant (pass 4) and reconciles rather than replaces: cases the new run still supports are untouched; signals the new run does not raise are marked `superseded` with the reason; cases the new run would not have opened are **annotated**, not closed, and the owner sees "a re-run on 15 Nov (reason: corrected attendance import) no longer supports this case". The counselor decides.

**Backfill after a weekly pack** (pass 2 §6.3). When `ingest.after_commit` reports new facts for students, `sweep.backfill` evaluates each affected student **as of the end of each school week the pack covers, in order**, with the calendar and as-of of that week, writing one evaluation per week (`backfill_of = week_end`) so the tier history is honest about when each move would have happened. Only the final week's result opens, attaches or moves cases; earlier weeks' proposals are recorded on their evaluations (`proposed_tier`) and used by the shadow comparison and the what-if run. `window_start` on a case opened by backfill is the onset week, not the commit date, and the case shows both ("first outside his band in the week of 3 Nov; seen by CAROS on Monday 17 Nov at 09:32"). The SLA clock starts at the commit (pass 2). A fortnightly pack is two weeks of observations and persistence counts both.

**Retrospective evaluation** for termly domains is the same mechanism with one point per term and the `retro.*` rules (§4.8), triggered by the reporting-window import.

### 13.6 What changed overnight

`sweep.finalize` sets, for every case row of the school, `tier_yesterday` to the tier the case held at the end of the **last successful or partial nightly run** (from `case_tier_history` at that run's `finished_at`), `tier_yesterday_run_id` to that run, and `moved_why` from the movement template. The sheet's overnight column and the rail's list (`movedToday`, `openedToday` in the prototype) read those columns. If the previous nightly run is more than one school day old (a missed night), the sheet prints "compared with the sweep of Thursday 20 November" at the top of the column, and the watchdog has already alerted. Daytime event runs never touch `tier_yesterday`; their movements are the "since this morning" list (§7.5), derived from `case_tier_history` rows with `evaluation_id` in an event run since the last nightly `finished_at`.

### 13.7 When a fact behind a signal is superseded

A corrected import (pass 2 §2.9, §2.10) supersedes rows that signals cite in `inputs.source_row_ids`. `ingest.after_commit` marks the affected `(student, measure, week)` dirty; the next evaluation (the backfill if the correction came in a pack, otherwise the nightly) recomputes the series from the current facts. For each open signal whose cited rows changed:

- if the rule still fires on the corrected series: the signal is superseded by a new one with the corrected inputs, and the evidence item is appended with a `corrected` snapshot (append-only, so the original stays);
- if it no longer fires: the signal is set `withdrawn` with `withdrawn_reason = 'fact_superseded'` and a reference to the superseding import; the evidence item gains a `corrected_on` annotation; the case is re-tiered under the rows that still match, **bypassing the exit-weeks condition** (§8.3), because the evidence was wrong rather than weak; and the movement reads "withdrawn: the Mathematics result of 41% was corrected to 71% on 15 November". If nothing remains, the case closes as `not_a_concern` with note `evidence_withdrawn`, and it does not count against the counselor's precision or the engine's.

### 13.8 Telling a human before 07:00

Two witnesses, one inside and one outside the system, both in Azure UAE North, with no student data in any alert.

1. **Inside:** `sweep.watchdog` (§13.2) at 05:45 local. If it fires it emits `sweep.missed`, and the caseload sheet carries a banner from that moment: "The overnight sweep did not complete. Tiers are as of the sweep of 20 November." The banner is not dismissible and clears only when a run succeeds.
2. **Outside:** the worker writes a structured log line `sweep.completed {school, run_date, status, duration}` to Azure Monitor Logs; a **scheduled-query alert rule** evaluates every 15 minutes and fires when no such line for a school has appeared by 05:30 local, when `status = 'partial'`, when `duration > 2h`, or when the worker's own heartbeat line (every 5 minutes) is absent for 20 minutes. The action group sends email and SMS to the on-call (Davide during the pilot; pass 6 sets the rota) and posts to the ops channel. The API exposes `/health/sweep` returning, per school, the last successful run date and status as a boolean-shaped payload for an uptime check; it contains no identifiers.

Beyond the deadline: `students_failed > 0`; `domain.quiet` (§10.3); `budget.exceeded` (§11.2); `common_cause.detected` (§7.6); tier churn (more than 10% of open cases moved by the engine in one night, which is either a threshold change or a data problem); the DR-6 assertion failures. All are alert rules on the same log stream, all identifiers-only.

---

## 14. Shadow mode for the pilot

### 14.1 Mechanics

A school in shadow has `config.rule_set_version.shadow = true` on its engine rule sets (pass 1), so every `sweep_run` is `shadow = true`. A shadow run writes snapshots, evaluations, signals and suppressions exactly as a live run would, and **no case rows**: the tier it would have set is `evaluation.proposed_tier`, and the view `signal.v_shadow_queue` (§17) reconstructs, per student per day, the tier the queue would have shown, the rule that put it there, and the evidence. The counselors do not see it; the data class `signal.shadow` (pass 4) is readable by the CAROS onboarding engineer under a support grant and, at the reveal sessions, by the counselors themselves. Teacher flags are **live** throughout (the inbox is a workflow win that needs no engine), and they feed the shadow evaluation like any other input. The demonstration-data marker is unaffected: shadow runs over real data are real data.

### 14.2 Capturing counselor judgement: the counselor log

Ground truth in shadow mode is what the counselors actually did and why, recorded **before** they see the engine's opinion. `signal.counselor_log` (§17) holds one row per counselor per student per day they gave the student attention: `reason_key` from a small vocabulary (`academic`, `attendance`, `behaviour`, `wellbeing`, `university`, `family`, `safeguarding`, `other`), `prompted_by` (`own_observation`, `teacher`, `parent`, `student`, `colleague`, `data`), `action_key` (`conversation`, `meeting`, `parent_contact`, `referral`, `plan`, `watch`), a free note, and `would_have_wanted_alert` (`yes`, `no`, `unsure`, answered in retrospect at the reveal, not on the day). The UI is a thirty-second daily entry from the caseload sheet (a "who did you see today" row) and a Friday prompt ("anyone this week you did not log?"). The log is staff-only, its own data class, and it is the single most valuable dataset the pilot produces, because it is the first measurement of the base rate (§1.3).

### 14.3 The comparison

Weekly, over the shadow period, per counselor and per school:

| Measure | Definition |
|---|---|
| **Overlap** | Students in both the shadow queue at `review` or above and the counselor log in the same fortnight |
| **Lead time** | For overlapping students, days from the first shadow evaluation at `review` or above to the first log entry; negative when the counselor was first |
| **Engine-only** | Students in the shadow queue at `review` or above with no log entry within a fortnight either side: reviewed at the reveal, where the counselor answers "would you have wanted this?"; the yes-rate is the precision proxy per tier and per rule |
| **Counselor-only** | Log entries with no shadow evaluation at `review` or above in the prior four weeks: the misses. For each, the engineer records whether the data that would have shown it existed in CAROS (`data_gap` versus `engine_miss`) and which detector, if any, was close |
| **Noise per detector** | Signals of each level on students the log marks as `nothing this term` |
| **Fairness screen** | §12.2 items 1, 2 and 4, on whatever labels the school has agreed to supply |
| **Reliability** | Sweep completion, duration, partials |

### 14.4 The reveal protocol

Reveal sessions at the end of weeks 4 and 8 (and each later month), per counselor, sixty minutes: the engineer walks through the engine-only students with the evidence chain and records the counselor's answer; then the counselor-only students, and the counselor and engineer agree the classification (data gap, engine miss, or a case the engine should never see, such as a family matter with no data trace). Threshold changes proposed at a reveal become a new **shadow** version, effective from the next sweep, so the next four weeks measure the change. Nothing from the log is shown to the counselor before the reveal, and the log's `would_have_wanted_alert` is answered only at the reveal, so the counselor's own record is not shaped by the engine's.

### 14.5 Leaving shadow mode

The caseload lead activates the first live version when all of the following hold, and the version note records the numbers:

1. At least six weeks of weekly data have been evaluated (the persistence rules need it).
2. Precision proxy at `checkin` and above is at or above the level the counselors named in the elicitation (default 60%), and at `review` at or above 25%.
3. Every counselor-only case has been classified, every `engine_miss` has a change in the configuration or the engine that would have caught it (re-run in what-if to show it), and every `data_gap` is either closed by ingest or accepted in writing.
4. No fairness screening trigger (§12.2) is unexplained.
5. The sweep completed on time on every night of the last four weeks.
6. The four counselors agree to go live, with their disagreements recorded.

Going live changes one thing: cases open. The log continues for one more term, because the comparison is the only measurement of precision the product will ever have until the reporting metrics accumulate.

### 14.6 The ethics of shadow inferences

Shadow evaluations are welfare inferences about real minors that nobody acts on. They are held under the same controls as live signals, retained for the same period (they are the audit trail of how the engine was tuned, and a later question "why is this student's threshold what it is" is answered from them), and disclosed to families in whatever terms pass 4 sets for the engine as a whole. A student who leaves during shadow mode has their shadow rows treated like any other signal rows under erasure.

---

## 15. Validation

### 15.1 Before any real data: the adversarial synthetic set

`packages/engine/test/scenarios/` holds one JSON file per scenario: a generator (weekly points per measure with a named noise seed, calendar periods, absence spans, teacher flags, context rows, case state) and an expectation (per week: level per measure, rule hits, proposed tier, onset week; and the final evidence sentences). `pnpm test --filter engine` runs them all in under a second, and they are the acceptance test for every engine change. The scenarios the prompt requires and the ones the design added:

| # | Scenario | Construction | Expectation |
|---|---|---|---|
| S1 | Strong student quietly declining | attainment 95, 94, 96, 95, 94, 93 then 91, 89, 88, 86, 85, 84 (noise σ 1.5); every other measure steady; still above any class mean | no shock; CUSUM crosses `h` by week 3 or 4 of the decline; moderate by week 4 (`persist` 2); review; strong by week 6; check-in; onset estimate within one week of week 7 |
| S2 | Struggling student genuinely recovering | attendance 74, 78, 80, 83, 85, 88, 90, 91 with an open case from week 1; below the 90 chronic floor until week 7 | no adverse level; the improving guard blocks the policy floor; recovery at week 8 after three inside weeks against a band computed with episode exclusion; tier `good` |
| S3 | Single outlier | attainment steady at 87 ± 2 for 12 weeks, one week at 61, then 88, 86 | week 13: a strong shock (`z` about 9, `d = 26`), moderate, review; weeks 14 to 15 inside the band: lowered to monitor under the exit rules after two inside weeks, then closed at auto-review; the CUSUM never reaches `h_strong` and the measure is never strong. A smaller outlier (Yousef's 74 against 87, `z` about 4) is a plain shock: monitor |
| S4 | Term break | 8 steady weeks, a 3-week holiday of null weeks, then 4 steady weeks | no signal; null weeks absent from `B`; `S` unchanged across the gap; run cells `none` |
| S5 | Transfer in | `transferred_in`, no history, then 4 steady weeks, then a genuine 3σ decline over weeks 5 to 8 | weeks 1 to 4: cold, no band, monitor `baseline_established` at week 8 if steady; the decline: self-starting CUSUM, capped at weak until `min_history_full`, strong shock exception raises moderate at week 6; review; no urgent |
| S6 | Missing weeks | S1's series with 30% of points null at random (seeded) | detection delayed by at most two valid weeks; no false signal on the null weeks |
| S7 | Teacher concern only | flat series everywhere; one concern (severity-2 tag) day 1 | review; event evaluation within 5 minutes; second independent concern day 4: check-in; third day 6: urgent; a `reviewed` status keeps counting; a `dismissed` one does not |
| S8 | Relapse inside the window | S2's recovery, case closed week 9, then 90, 86, 79, 76 in weeks 12 to 15 | episode exclusion keeps the baseline at 88 to 92 with the binomial floor; 79 and 76 take `S` past `h` for two weeks: moderate by week 15; a relapse case with `relapse_of_case_id`; fresh tier review, uplifted to check-in; strong, and urgent, only if the fall continues |
| S9 | Exam period, suppressed for one year group | two students, Grade 12 and Grade 11, same mock-week dip; `mock_period` for Grade 12 | Grade 12: suppressed, check recorded, no level; Grade 11: shock, monitor |
| S10 | Subject change | attainment series ends with a section change; new section starts 8 points lower | old series ends; new series cold or inherited (set change) with `H` capped at 8; no signal for two weeks; `section_change` suppression recorded |
| S11 | Authorised absence | attendance 100% then a 3-week medical absence coded `M`, then 100% | rate series null for the three weeks; engagement suppressed plus 2 days; no signal |
| S12 | School-wide bad week | 40% of students outside band on attendance in one week | `common_cause` on the week; levels capped at weak; ops note |
| S13 | Steady student, tiny wobble | attainment 96 ± 0.5 for 20 weeks, then 94 | `z` below 1 on the floored scale and `d = 2 < floor 5`: nothing; not even a soft cell. With the floor removed in a what-if run, still nothing, because `d < floor` |
| S14 | Ordinal series | IB grades 7, 7, 7, 6, 7, 5, 5, 5 | week 4: `z = 2`, outside (`c = 1.5`), soft cell, no case; week 6: two-step drop, shock (`z = 4`), monitor; week 7: `S ≥ h` two weeks: moderate, review |
| S15 | Corrected import | S1 with the week-9 point later corrected from 84 to 93 | the signal on the corrected series is superseded or withdrawn; tier re-evaluated bypassing exit weeks; evidence item carries `corrected_on` |
| S16 | Positive-only student | everything inside band; a positive teacher flag; a favourable outside week | no case; the file stays quiet; positive evidence is visible in the baseline tab only |
| S17 | Counselor downgrade, no new evidence | check-in lowered to review by a person; the same measures persist | engine does not raise within 14 days; tier history row shows the hold; day 15 with the level still moderate in two domains: raise, reason `hold_expired` |
| S18 | Counselor downgrade, new domain | as S17, then a teacher concern on day 5 | raise on day 5, reason `new_domain` |
| S19 | Hysteresis at the edge | a series oscillating around `h` (S at 4.6, 5.2, 4.8, 5.3 …) | at most two engine changes in seven days; `tier.held_by_hysteresis` emitted; the what-if run lists the measure as oscillating |
| S20 | Weekly backfill | three weeks of facts in one pack, the decline starting in week 1 | three evaluations with `backfill_of`; one case opened from the final state; `window_start` is week 1; SLA from commit |
| S21 | Retrospective term | termly working grades 6, 6, 5 (IB) | `retro.academic` moderate; tier capped at review; evidence names the export |
| S22 | Threshold change | a live version raises `floor.attainment` from 5 to 8 | S1 at week 5 is not raised; open S1 case is lowered only under hysteresis; case file shows both versions |
| S23 | The fifteen authored cases | pass 1 DR-8's facts layer | the tiers in §7.2, with Maryam's `good` one week later; the diff list is the expected output of `engine-reproduces-seed` |

Property tests, run over generated series: determinism (same input, same output); **monotonicity** (adding an adverse observation never lowers a level; adding a favourable one never raises it); **suppression never raises**; **no comparison** (the output for a student is unchanged when every other student's data changes, which is the executable form of invariant 2); hysteresis (no two engine lowerings of the same case within `exit_weeks` of data).

### 15.2 With pseudonymised history: the backtest

**Data**, under a data processing agreement (pass 4) and pass 2's question 83: two academic years of per-assessment grades with dates, per-session or per-day attendance with codes, behaviour records, the calendar, section rosters, and, indispensably, **the counselors' own dated records of the students they supported**: intervention logs, referral and escalation records, parent-contact notes, whatever exists, with a category and a date, pseudonymised with the same key as the SIS rows. If ACS keeps no such records, the backtest can measure lead time against nothing, and the shadow log (§14.2) becomes the only ground truth, one term later.

**Procedure.**

1. Reconstruct weekly series exactly as the engine will (through `packages/ingest` and the domain loader), so the backtest exercises the real pipeline.
2. Run `evaluateStudent` as of the end of every school week of both years, with the calendar and cadence the school actually had (the second year's evaluations have a full baseline; the first year's are the cold-start behaviour).
3. Independently, segment every series with PELT (Killick, Fearnhead and Eckley 2012; `ruptures`, Truong, Oudre and Vayatis 2020) to find where the series itself says a change happened. This is an oracle for the detectors, not for the counselors: it answers "did the engine find the changes that were there, and how late".
4. Match engine cases at `review` or above to counselor-handled records within a window.

**Metrics.** Recall of counselor-handled cases with an engine case in the prior two, four and eight weeks; precision of engine cases at each tier (share followed by a handled record within four weeks, with the caveat that the counselor may have missed cases the engine found, so this is a floor on precision); the lead-time distribution; cases per week per tier; the detectors' delay against the PELT change points; the sensitivity of all of these to the floors, `h`, `persist` and `W` over a grid; the fairness screen where labels exist. Output: a report, a proposed first configuration version for ACS with every parameter justified by a number, and an updated expected-diff list for §15.1.

### 15.3 What cannot be known until the second step

Stated plainly, because the design has to be honest about its own uncertainty:

- The **base rate** of episodes a counselor would want to know about, and therefore the real precision of any tier.
- The **right floors** for ACS's gradebook and register: the weekly noise of a Veracross percentage series and of class attendance at ACS is unknown, and it sets every false-alarm rate in §3.6.
- Whether the historical export carries **per-assessment dates and per-session attendance** at all; if it carries only term grades, only the retrospective mode can be backtested and the weekly design goes into shadow mode untested by history.
- Whether **dated records of handled cases** exist; without them there is no lead time to measure.
- The **autocorrelation and seasonality** of real series, which the simulation ignores and which will move the noise figures, probably upward.
- The **teacher-concern rate** (how many flags a week, from how many teachers), which sets the corroboration rule's noise.
- The **fairness rates**, which depend on labels the school may not supply.
- Whether the four counselors **agree with each other**; if their judgements of the same case differ, "precision" is a moving target and the elicitation's disagreements become the pilot's first finding.

---

## 16. What the engine writes for each signal

The rule is that the case file renders from stored rows and never recomputes, so that a signal raised under thresholds v2 still explains itself after v5. Everything the file prints has a column; every number in a sentence has a field in `inputs`.

### 16.1 Per measure: `signal.feature_snapshot`

`band_method = 'personal_median_madn_v1'` (the `NOT ILIKE '%cohort%'` check stays). `series` is the weekly points with `week_start`, `value`, `n`, `thin`, `suppressed`, `provisional`. `features`:

```json
{
  "scale_key": "pct", "dir": -1, "unit": "%",
  "window_weeks": 20, "history_weeks": 14, "phase": "full",
  "excluded_episodes": [{"case_id": "…", "from": "2026-09-29", "to": "2026-10-27"}],
  "m": 90.5, "mad_n": 2.22, "s_floor": 3.0, "s": 3.0, "floor": 5,
  "c": 2.5, "band_lo": 83.0, "band_hi": 98.0,
  "z_last": 16.5, "d_last": 49.5, "outside_last": true,
  "cusum": {"k": 0.5, "h": 5, "h_strong": 8, "S": [0, 0, 0, 0, 0, 0.33, 5.33, 21.33], "onset_week": "2026-10-27", "persistence_weeks": 3, "run_mean_d": 22.8},
  "shock": {"z": 3.0, "z_strong": 5.0, "fired": true, "strong": true},
  "scale_free": {"floor_x2": 10, "weeks": 2, "fired": false},
  "slope_6w": -6.1, "improving_weeks": 0,
  "level": 3, "strong_reason": "strong_shock_on_active_cusum",
  "n_since_onset": 3
}
```

### 16.2 Per rule firing: `signal.signal`

`rule_key`, `rule_version` (the engine version the rule's code carries), `domain`, `measure_key`, `snapshot_id`, `level` (1 to 3), `polarity`, `window_start`, `window_end`, `onset_week`, `template_key`, `template_version`, `summary` (rendered), `inputs`:

```json
{
  "thresholds_version_id": "…", "suppression_version_id": "…", "tiering_version_id": "…", "engine_version": "1.4.0",
  "as_of": "2026-11-14",
  "detector": "cusum", "values": {"S": 21.33, "h": 5, "h_strong": 8, "k": 0.5, "z": 16.5, "d": 49.5, "m": 90.5, "s": 3.0, "floor": 5, "persistence_weeks": 3, "strong_reason": "strong_shock_on_active_cusum"},
  "points_cited": [{"week_start": "2026-11-03", "value": 74, "n": 2}, {"week_start": "2026-11-10", "value": 41, "n": 1}],
  "source_row_ids": {"sis.grade": ["…", "…"], "sis.assessment": ["…"]},
  "suppression_checks": ["exam_period:no", "authorised_absence:no", "section_change:no", "common_cause:no"],
  "template_args": {"section": "Mathematics AA HL", "value": 41, "unit": "%", "date": "12 Nov", "d": 49, "m": 90, "history_weeks": 14, "nth": "second"}
}
```

Templates live in `packages/engine/templates/<rule_key>.<lang>.txt`, versioned with the package; a placeholder may bind only to a `template_args` field, which the schema restricts to numbers, dates and enumerated labels from the inputs, so a template cannot invent a number. The rendered `summary` is stored, so a later wording change does not rewrite history. The model may rephrase a **headline** (pass 1 `headline_generation_id`, pass 5), never a summary, and the rule's headline template is always available beside it.

### 16.3 Per evidence item: `signal.evidence_item`

`kind`, `domain`, `source_label` (rendered from the import's source system and the as-of, pass 2), `source_table`, `source_id`, `occurred_at` or `occurred_label`, `level`, `polarity` (`adverse` / `positive` / `context`), `template_key`, `summary`, `snapshot` (the cited source rows as they were: for a grade, the assessment title, date, score, max and the import id; for a flag, its tags and body; for a context row, its kind and validity). Append-only; a correction adds an item.

### 16.4 Per student per run: `signal.evaluation`

`level`, `breadth`, `proposed_tier`, `cold_start`, `as_of` (per domain), `snapshot_ids`, `backfill_of`, `trigger_ref`, `input_hash`, `rule_hits` (every tiering row, `{row, matched, values_seen}`), `suppressions` (`{check, outcome, detail}` for every check in §6.2), `error`.

### 16.5 Per case movement: `signal.case` and `case_tier_history`

`moved_why` rendered from the movement template with the same discipline; `suggested_action` `{what, when, why, rule_key}` from the matched tiering row's action template; `window_start`/`window_end`; `no_cause_inferred = true` on every engine-opened case (the prototype's "The system does not infer a cause" is a property of the engine, not a per-case flag); the tier history row's `evaluation_id`, and `reason` for the exceptions in §8.2 (`new_domain`, `new_concern`, `strong_level`, `hold_expired`, `fact_withdrawn`, `context_added`).

### 16.6 Explainability after the configuration changes

The file shows, for each signal, the version it was raised under and, if the current version differs, a line "thresholds have changed since (v3 → v5)"; the what-if run can show what the current version would say. A superseded signal keeps its row and its link to the superseding one; a withdrawn one keeps its row and its reason. The baseline chart draws the snapshot the signal cites, not tonight's. Nothing on the file is computed from live facts except the "as of" freshness line.

---
## 17. Schema deltas to passes 1 and 2

Numbered after pass 2's D16, in migration order. Each is a small, reversible change; none touches a table pass 2 owns.

| # | Change | DDL sketch |
|---|---|---|
| D17 | `signal.evaluation`: replace the undefined number with the defined level | `ALTER TABLE signal.evaluation DROP COLUMN strength, DROP COLUMN strength_definition, ADD COLUMN level smallint NOT NULL DEFAULT 0 CHECK (level BETWEEN 0 AND 3), ADD COLUMN breadth smallint NOT NULL DEFAULT 0, ADD COLUMN as_of jsonb NOT NULL DEFAULT '{}'::jsonb, ADD COLUMN backfill_of date, ADD COLUMN trigger_ref jsonb, ADD COLUMN input_hash bytea;` (the seed's `strength_definition = 'prototype:unspecified'` rows are migrated to `level` from the authored word) |
| D18 | `signal.signal`: level and polarity in place of `contribution`; the measure and onset; templates; withdrawal | `ALTER TABLE signal.signal DROP COLUMN contribution, ADD COLUMN level smallint NOT NULL CHECK (level BETWEEN 1 AND 3), ADD COLUMN polarity text NOT NULL DEFAULT 'adverse' CHECK (polarity IN ('adverse','positive')), ADD COLUMN measure_key text, ADD COLUMN onset_week date, ADD COLUMN template_key text NOT NULL, ADD COLUMN template_version text NOT NULL, ADD COLUMN withdrawn_reason text;` and a deterministic id policy in the domain layer (`uuid_generate_v5`) |
| D19 | `signal.evidence_item`: same for evidence | `ALTER TABLE signal.evidence_item DROP COLUMN contribution, ADD COLUMN level smallint CHECK (level BETWEEN 1 AND 3), ADD COLUMN polarity text NOT NULL CHECK (polarity IN ('adverse','positive','context')), ADD COLUMN template_key text;` |
| D20 | `signal.feature_snapshot`: scale, direction, episodes; fix the method name | `ALTER TABLE signal.feature_snapshot ADD COLUMN scale_key text NOT NULL, ADD COLUMN dir smallint NOT NULL CHECK (dir IN (-1, 1)), ADD COLUMN phase text NOT NULL CHECK (phase IN ('cold','self_starting','band','full')), ADD CONSTRAINT band_method_known CHECK (band_method IN ('personal_median_madn_v1'));` (`features` validated by the engine's JSON schema in the domain layer) |
| D21 | `signal.sweep_run`: deadlines, heartbeat, scope, per-domain as-of, reason; narrow the uniqueness to nightly | `ALTER TABLE signal.sweep_run ADD COLUMN deadline_at timestamptz, ADD COLUMN heartbeat_at timestamptz, ADD COLUMN students_in_scope integer, ADD COLUMN as_of_by_domain jsonb, ADD COLUMN reason text; DROP INDEX signal.sweep_run_one_live_per_date; CREATE UNIQUE INDEX sweep_run_one_nightly_per_date ON signal.sweep_run (school_id, run_date, shadow) WHERE trigger = 'nightly' AND status IN ('running','succeeded','partial') AND supersedes_run_id IS NULL;` |
| D22 | `signal.case`: cold start, the comparison base, hysteresis holds | `ALTER TABLE signal.case ADD COLUMN cold_start boolean NOT NULL DEFAULT false, ADD COLUMN tier_yesterday_run_id uuid, ADD COLUMN held_by_hysteresis_at timestamptz, ADD COLUMN triggering_measures text[] NOT NULL DEFAULT '{}';` (`triggering_measures` is `Q*` for recovery, maintained by the engine and, for person-opened cases, by the open transaction) |
| D23 | `signal.case_context`: the effect as it was when added | `ALTER TABLE signal.case_context ADD COLUMN effect text NOT NULL CHECK (effect IN ('suppress','soften','inform','route')), ADD COLUMN suppresses text[] NOT NULL DEFAULT '{}';` |
| D24 | `signal.counselor_log` (new, §14.2) | `CREATE TABLE signal.counselor_log (school_id uuid NOT NULL REFERENCES core.school (id), id uuid NOT NULL DEFAULT gen_random_uuid(), counselor_person_id uuid NOT NULL, student_id uuid NOT NULL, day date NOT NULL, reason_key text NOT NULL, prompted_by text NOT NULL, action_key text NOT NULL, note text, would_have_wanted_alert text CHECK (would_have_wanted_alert IN ('yes','no','unsure')), answered_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, counselor_person_id, student_id, day), FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id), FOREIGN KEY (school_id, counselor_person_id) REFERENCES core.person (school_id, id));` with RLS as for `signal.case_note` and its own data class |
| D25 | `signal.v_shadow_queue` (view, §14.1) | `CREATE VIEW signal.v_shadow_queue AS SELECT e.school_id, e.student_id, r.run_date, e.proposed_tier, e.level, e.breadth, e.id AS evaluation_id FROM signal.evaluation e JOIN signal.sweep_run r ON r.id = e.sweep_run_id WHERE r.shadow AND r.trigger = 'nightly' AND e.proposed_tier IS NOT NULL;` |
| D26 | `fairness.group_label` (new, §12.4; pass 4 finalises access and retention) | `CREATE SCHEMA fairness; CREATE TABLE fairness.group_label (school_id uuid NOT NULL REFERENCES core.school (id), student_id uuid NOT NULL, dimension text NOT NULL CHECK (dimension IN ('nationality','gender','language_background','sen_status')), value text NOT NULL, import_id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (school_id, student_id, dimension), FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id));` no grant to the application tiers; readable only by the audit job's role; `packages/engine` has a test that it imports nothing from `fairness` |
| D27 | `config.vocabulary` attribute schemas | `flag_tag`: `{severity: 1..3, safeguarding_relevant: boolean}`; `context_kind`: `{effect, suppresses[], default_valid_days}`; `behaviour_category`: adds `{serious: boolean, urgent: boolean}`; validated by the domain layer on insert; platform defaults seeded from §4.5 and §6.2 |
| D28 | `events.name` rows | `sweep.completed`, `sweep.partial`, `sweep.missed`, `signal.withdrawn`, `signal.superseded`, `tier.held_by_hysteresis`, `config.domain_disabled`, `domain.quiet`, `budget.exceeded`, `common_cause.detected`, `case.self_recovered`, `case.auto_reviewed`, `shadow.reveal_recorded`, `counselor_log.entry` |
| D29 | `core.school.sweep_hour` | `ALTER TABLE core.school ADD COLUMN sweep_hour smallint NOT NULL DEFAULT 2 CHECK (sweep_hour BETWEEN 0 AND 5);` |
| D30 | `auth.data_class` rows | `signal.shadow`, `signal.counselor_log`, `fairness.label` (pass 4 places them in the matrix) |
| D31 | Rule-set JSON schemas | `packages/engine/schemas/{thresholds,suppression,tiering,dimensions}.schema.json`, published with `schema_version`; `config.rule_set_version.params` validated against them in the domain layer before insert |
| D32 | The `no second copies` list (pass 1 DR-6) | add `level_cached`, `strength`, `confidence`, `probability_score` |

Tests this pass adds (pass 6 sequences them): the scenario suite (§15.1) and property tests; `engine-reproduces-seed` with the expected-diff list; the determinism and no-comparison tests; a domain-layer test that an event evaluation cannot lower a tier except on context; a test that a `disabled` domain writes the banner event and that the what-if delta guard fires; an RLS test that the counselor log and shadow view are invisible to teachers, students, parents and mentors and to counselors outside the caseload.

---

## Appendix · The calibration simulation

The figures in §3.6 and §11.1 come from this script (Python 3, NumPy), kept here so they can be re-run when a default changes. It belongs in `packages/engine/tooling/calibrate.py` (pass 6). Units are the student's true weekly noise; `floor` is the minimum meaningful change in those units.

```python
import numpy as np
from math import comb
rng = np.random.default_rng(7)

def madn(x):
    med = np.median(x, axis=-1, keepdims=True)
    return 1.4826 * np.median(np.abs(x - med), axis=-1)

def run(H, M=8, c=2.5, zshock=3.0, k=0.5, h=5.0, s_floor=0.5, floor=1.0,
        noise="normal", shift=0.0, slope=0.0, n=150000, persist=2):
    draw = (lambda s: rng.standard_normal(s)) if noise == "normal" else (lambda s: rng.standard_t(3, s))
    base = draw((n, H)); m = np.median(base, 1); s = np.maximum(madn(base), s_floor)
    mon = draw((n, M)) - shift - slope * np.arange(1, M + 1)          # adverse = downward
    dev = m[:, None] - mon; z = dev / s[:, None]; above = dev > floor
    soft = (z > c) & above; shock = (z > zshock) & above
    S = np.zeros(n); cus = np.zeros((n, M), bool)
    for t in range(M):
        S = np.maximum(0.0, S + z[:, t] - k); cus[:, t] = (S > h) & above[:, t]
    cusp = cus.copy()
    for p in range(1, persist): cusp[:, p:] &= cus[:, :-p]              # held `persist` consecutive weeks
    moderate = shock | cusp
    first = lambda a: np.where(a.any(1), a.argmax(1) + 1, np.inf)
    return dict(soft=soft.mean(0)[-1], shock=shock.mean(0)[-1], cusum=cus.mean(0)[-1],
                cusum_p=cusp.mean(0)[-1], moderate=moderate.mean(0)[-1], first_mod=first(moderate))

# quiet-student false-alarm rates per week (last monitored week), and detection delays
for noise in ("normal", "t3"):
    for H in (6, 12, 20):
        for floor in (0.0, 1.0, 1.5):
            r = run(H=H, floor=floor, noise=noise)
            print(noise, H, floor, {k_: round(float(v), 4) for k_, v in r.items() if k_ != "first_mod"})
for shift in (1.5, 2.0, 3.0):
    f = run(H=12, shift=shift, n=80000)["first_mod"]; ok = np.isfinite(f)
    print("shift", shift, "detected", ok.mean().round(2), "median weeks", np.median(f[ok]))
```

The one-sided CUSUM check with known parameters (`k = 0.5`: `h = 4` gives an in-control average run length of about 335, `h = 5` about 928; the published two-sided value for `h = 5` is about 465) is a 15-line loop in the same file and is the test that the implementation matches the literature before any of the above is trusted. A second script of about 120 lines (`calibrate_tiers.py`, same directory) builds ten series per student, applies the level rules of §3.5 exactly as written (including the run-mean floor, the strong-shock-on-active-CUSUM condition and the scale-free rule), the within-domain rule, the two-week breadth window and the tiering rows of §7.2, and reports the per-tier counts of §11.1 for a quiet caseload and the week-by-week detection of a genuine two-domain change. It is the script that found the loose strong definition, and any change to §3.5 or §7.2 must be re-run through it.

---

## Sources

All retrieved or verified 2026-09-23. Grouped by the section that relies on them.

**Early warning indicators and attendance (§2.1)**
- Balfanz, R., Herzog, L. and Mac Iver, D. J. (2007). Preventing student disengagement and keeping students on the graduation path in urban middle-grades schools: Early identification and effective interventions. *Educational Psychologist*, 42(4), 223–235. PDF: https://new.every1graduates.org/wp-content/uploads/2012/03/preventing_student_disengagement.pdf ; ERIC: https://eric.ed.gov/?id=EJ780922
- Allensworth, E. M. and Easton, J. Q. (2005). *The On-Track Indicator as a Predictor of High School Graduation*. Consortium on Chicago School Research. https://consortium.uchicago.edu/publications/track-indicator-predictor-high-school-graduation
- Allensworth, E. M. and Easton, J. Q. (2007). *What Matters for Staying On-Track and Graduating in Chicago Public High Schools*. Consortium on Chicago School Research. https://consortium.uchicago.edu/publications/what-matters-staying-track-and-graduating-chicago-public-schools ; ERIC: https://eric.ed.gov/?id=ED498350
- Bowers, A. J., Sprott, R. and Taff, S. A. (2013). Do we know who will drop out? A review of the predictors of dropping out of high school: Precision, sensitivity, and specificity. *The High School Journal*, 96(2), 77–100. ERIC: https://eric.ed.gov/?id=EJ995291 (the full abstract could not be retrieved on the day; the findings quoted are those the abstract states and secondary sources repeat)
- Faria, A. M., Sorensen, N., Heppen, J., Bowdon, J., Taylor, S., Eisner, R. and Foster, S. (2017). *Getting students on track for graduation: Impacts of the Early Warning Intervention and Monitoring System after one year* (REL 2017-272). IES, REL Midwest. https://ies.ed.gov/use-work/resource-library/report/impact-study/getting-students-track-graduation-impacts-early-warning-intervention-and-monitoring-system-after-one ; PDF: https://nces.ed.gov/sites/default/files/migrated/rel/regions/midwest/pdf/REL_2017272.pdf
- Knowles, J. E. (2015). Of needles and haystacks: Building an accurate statewide dropout early warning system in Wisconsin. *Journal of Educational Data Mining*, 7(3), 18–67. https://jedm.educationaldatamining.org/index.php/JEDM/article/view/JEDM082
- Anderson, H., Boodhwani, A. and Baker, R. S. (2019). Assessing the fairness of graduation predictions. *Proceedings of the 12th International Conference on Educational Data Mining*. https://learninganalytics.upenn.edu/ryanbaker/EDM2019_paper56.pdf
- Balfanz, R. and Byrnes, V. (2012). *The Importance of Being in School: A Report on Absenteeism in the Nation's Public Schools*. Johns Hopkins University. https://new.every1graduates.org/wp-content/uploads/2012/05/FINALChronicAbsenteeismReport_May16.pdf ; U.S. Department of Education, Chronic Absenteeism: https://www.ed.gov/teaching-and-administration/supporting-students/chronic-absenteeism
- McIntosh, K., Frank, J. L. and Spaulding, S. A. (2010). Establishing research-based trajectories of office discipline referrals for individual students. *School Psychology Review*, 39(3), 380–394. https://doi.org/10.1080/02796015.2010.12087759
- Markowitz, D. M., Kittelman, A., Girvan, E. J., Santiago-Rosario, M. R. and McIntosh, K. (2023). Taking note of our biases: How language patterns reveal bias underlying the use of office discipline referrals in exclusionary discipline. *Educational Researcher*. https://journals.sagepub.com/doi/abs/10.3102/0013189X231189444
- American Enterprise Institute (2025). *What Stories Does Daily Attendance Tell? Student Attendance Patterns Before and After the COVID-19 Pandemic*. https://www.aei.org/research-products/report/what-stories-does-daily-attendance-tell-student-attendance-patterns-before-and-after-the-covid-19-pandemic/ ; and *Please Excuse My Child: Unexcused Absences in Student Attendance and Achievement*. https://www.aei.org/research-products/report/please-excuse-my-child-unexcused-absences-in-student-attendance-and-achievement/
- Macfadyen, L. P. and Dawson, S. (2010). Mining LMS data to develop an "early warning system" for educators: A proof of concept. *Computers & Education*, 54(2), 588–599. https://www.sciencedirect.com/science/article/abs/pii/S0360131509002486 (cohort-level; cited for the engagement domain's provenance only)

**Teacher recognition (§2.2)**
- Splett, J. W., Garzona, M., Gibson, N., Wojtalewicz, D., Raborn, A. and Reinke, W. M. (2019). Teacher recognition, concern, and referral of children's internalizing and externalizing behavior problems. *School Mental Health*, 11, 228–239. https://link.springer.com/article/10.1007/s12310-018-09303-z
- Dowdy, E., Doane, K., Eklund, K. and Dever, B. V. (2013). A comparison of teacher nomination and screening to identify behavioral and emotional risk within a sample of underrepresented students. *Journal of Emotional and Behavioral Disorders*, 21. https://journals.sagepub.com/doi/10.1177/1063426611417627
- Eklund, K., Renshaw, T., Dowdy, E., Jimerson, S., Hart, S. R., Jones, C. N. et al. (2009). Early identification of behavioral and emotional problems in youth: Universal screening versus teacher-referral identification. *Contemporary School Psychology*, 14, 89–95. https://link.springer.com/article/10.1007/BF03340954

**Statistics (§2.3, §3)**
- Hampel, F. R. (1974). The influence curve and its role in robust estimation. *Journal of the American Statistical Association*, 69(346), 383–393. https://www.tandfonline.com/doi/abs/10.1080/01621459.1974.10482962
- Leys, C., Ley, C., Klein, O., Bernard, P. and Licata, L. (2013). Detecting outliers: Do not use standard deviation around the mean, use absolute deviation around the median. *Journal of Experimental Social Psychology*, 49(4), 764–766. https://www.sciencedirect.com/science/article/pii/S0022103113000668
- Iglewicz, B. and Hoaglin, D. C. (1993). *How to Detect and Handle Outliers*. ASQC Basic References in Quality Control, vol. 16.
- Rousseeuw, P. J. and Croux, C. (1993). Alternatives to the median absolute deviation. *Journal of the American Statistical Association*, 88(424), 1273–1283. https://www.tandfonline.com/doi/abs/10.1080/01621459.1993.10476408
- Page, E. S. (1954). Continuous inspection schemes. *Biometrika*, 41(1/2), 100–115. https://academic.oup.com/biomet/article-abstract/41/1-2/100/456627
- Brook, D. and Evans, D. A. (1972). An approach to the probability distribution of cusum run length. *Biometrika*, 59(3), 539–549. https://academic.oup.com/biomet/article/59/3/539/484836
- Hawkins, D. M. (1987). Self-starting cusum charts for location and scale. *The Statistician*, 36, 299–316. https://rss.onlinelibrary.wiley.com/doi/10.2307/2348827
- Hawkins, D. M. and Olwell, D. H. (1998). *Cumulative Sum Charts and Charting for Quality Improvement*. Springer.
- Quesenberry, C. P. (1991). SPC Q charts for start-up processes and short or long runs. *Journal of Quality Technology*, 23(3). https://www.tandfonline.com/doi/abs/10.1080/00224065.1991.11979327
- Roberts, S. W. (1959). Control chart tests based on geometric moving averages. *Technometrics*, 1(3), 239–250. https://www.tandfonline.com/doi/abs/10.1080/00401706.1959.10489860
- Lucas, J. M. and Saccucci, M. S. (1990). Exponentially weighted moving average control schemes: Properties and enhancements. *Technometrics*, 32(1), 1–12.
- Borror, C. M., Montgomery, D. C. and Runger, G. C. (1999). Robustness of the EWMA control chart to non-normality. *Journal of Quality Technology*, 31(3), 309–316. https://www.tandfonline.com/doi/abs/10.1080/00224065.1999.11979929
- Lucas, J. M. (1985). Counted data CUSUM's. *Technometrics*, 27(2), 129–144. https://www.tandfonline.com/doi/abs/10.1080/00401706.1985.10488030
- Borror, C. M., Champ, C. W. and Rigdon, S. E. (1998). Poisson EWMA control charts. *Journal of Quality Technology*, 30(4), 352–361. https://www.tandfonline.com/doi/abs/10.1080/00224065.1998.11979871
- Western Electric Company (1956). *Statistical Quality Control Handbook*; Nelson, L. S. (1984). The Shewhart control chart: Tests for special causes. *Journal of Quality Technology*, 16(4), 237–239. https://www.tandfonline.com/doi/abs/10.1080/00224065.1984.11978921
- Sen, P. K. (1968). Estimates of the regression coefficient based on Kendall's tau. *Journal of the American Statistical Association*, 63(324), 1379–1389. https://www.tandfonline.com/doi/abs/10.1080/01621459.1968.10480934
- Killick, R., Fearnhead, P. and Eckley, I. A. (2012). Optimal detection of changepoints with a linear computational cost. *Journal of the American Statistical Association*, 107(500), 1590–1598. https://www.tandfonline.com/doi/abs/10.1080/01621459.2012.737745
- Truong, C., Oudre, L. and Vayatis, N. (2020). Selective review of offline change point detection methods. *Signal Processing*, 167, 107299. https://arxiv.org/abs/1801.00718
- Adams, R. P. and MacKay, D. J. C. (2007). Bayesian online changepoint detection. arXiv:0710.3742. https://arxiv.org/abs/0710.3742
- NIST/SEMATECH *e-Handbook of Statistical Methods*: CUSUM control charts (§6.3.2.3) https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc323.htm ; EWMA control charts (§6.3.2.4) https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm
- SigmaXL, Tabular CUSUM reference (k = 0.5, h = 5, in-control ARL about 465): https://www.sigmaxl.com/TabularCUSUM.html

**Alert fatigue and human response to alarms (§1.3, §2.4)**
- van der Sijs, H., Aarts, J., Vulto, A. and Berg, M. (2006). Overriding of drug safety alerts in computerized physician order entry. *Journal of the American Medical Informatics Association*, 13(2), 138–147. https://academic.oup.com/jamia/article-abstract/13/2/138/729701
- Kesselheim, A. S., Cresswell, K., Phansalkar, S., Bates, D. W. and Sheikh, A. (2011). Clinical decision support systems could be modified to reduce 'alert fatigue' while still minimizing the risk of litigation. *Health Affairs*, 30(12). https://www.healthaffairs.org/doi/abs/10.1377/hlthaff.2010.1111
- Ancker, J. S., Edwards, A., Nosal, S., Hauser, D., Mauer, E., Kaushal, R. and the HITEC Investigators (2017). Effects of workload, work complexity, and repeated alerts on alert fatigue in a clinical decision support system. *BMC Medical Informatics and Decision Making*, 17, 36. https://doi.org/10.1186/s12911-017-0430-8 (abstract retrieved through Europe PMC)
- Drew, B. J. et al. (2014). Insights into the problem of alarm fatigue with physiologic monitor devices: A comprehensive observational study of consecutive intensive care unit patients. *PLOS ONE*, 9(10), e110274. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0110274
- Bliss, J. P., Gilson, R. D. and Deaton, J. E. (1995). Human probability matching behaviour in response to alarms of varying reliability. *Ergonomics*, 38(11), 2300–2312. https://www.tandfonline.com/doi/abs/10.1080/00140139508925269
- Parasuraman, R. and Riley, V. (1997). Humans and automation: Use, misuse, disuse, abuse. *Human Factors*, 39(2), 230–253. https://journals.sagepub.com/doi/10.1518/001872097778543886
- Pauker, S. G. and Kassirer, J. P. (1980). The threshold approach to clinical decision making. *New England Journal of Medicine*, 302(20). https://www.nejm.org/doi/abs/10.1056/NEJM198005153022003

**Base rates and context (§1.3, §4.7)**
- World Health Organization. *Mental health of adolescents* (fact sheet, updated 2025). https://www.who.int/news-room/fact-sheets/detail/adolescent-mental-health
- Burcusa, S. L. and Iacono, W. G. (2007). Risk for recurrence in depression. *Clinical Psychology Review*, 27(8), 959–985. https://pmc.ncbi.nlm.nih.gov/articles/PMC2169519/ (cited as an analogy only)
- American School Counselor Association, School Counselor Roles & Ratios (recommended 250:1; 2024–25 national average 372:1). https://www.schoolcounselor.org/about-school-counseling/school-counselor-roles-ratios
- The National (7 Dec 2021), UAE school week to shift in line with weekend change; Khaleej Times, Abu Dhabi private schools notified about change in timings (Monday-to-Friday week from January 2022). https://www.thenationalnews.com/uae/2021/12/07/uae-school-week-to-shift-in-line-with-new-saturday-sunday-weekend/ ; https://www.khaleejtimes.com/schooling-in-uae/new-uae-weekend-abu-dhabi-private-schools-notified-about-change-in-timings (this resolves pass 1's assumption in §0.2: the tenant's weekend is Saturday and Sunday)

**Fairness and the data needed to test it (§12)**
- Hardt, M., Price, E. and Srebro, N. (2016). Equality of opportunity in supervised learning. *NeurIPS 2016*. https://arxiv.org/abs/1610.02413
- Chouldechova, A. (2017). Fair prediction with disparate impact: A study of bias in recidivism prediction instruments. *Big Data*, 5(2), 153–163. https://arxiv.org/abs/1703.00056
- 29 CFR § 1607.4(D), Uniform Guidelines on Employee Selection Procedures (1978), the four-fifths rule. https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XIV/part-1607/subject-group-ECFRdb347e844acdea6/section-1607.4
- UAE Federal Decree-Law No. 45 of 2021 on the Protection of Personal Data, Article 1 (definition of sensitive personal data). https://uaelegislation.gov.ae/en/legislations/1972/download
- Regulation (EU) 2024/1689 (Artificial Intelligence Act), Article 10(5). https://artificialintelligenceact.eu/article/10/ ; Official Journal text: https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?uri=OJ%3AL_202401689

**Not retrievable on the day, stated as such.** The full text of Bowers, Sprott and Taff (2013) (ERIC and Europe PMC returned no abstract text); Balfanz et al. (2007) was read from the PDF's extracted text; the Lucas and Saccucci (1990) design tables were not retrieved and no `(λ, L)` pair is quoted from them.

---

## Challenges

Each names the decision or invariant touched, states the alternative, what it costs and buys, and what this pass planned on.

**C1 · "Overnight batch" is kept as the ritual and extended with an event path.** *Decision: signal engine timing.* Argued in full in §7.5. The alternative is nightly only; it costs a school day on the safeguarding pattern and the teacher's loop, and buys nothing the asymmetry rules do not also buy. Planned on the hybrid; the nightly run alone computes "what changed overnight".

**C2 · The engagement domain ships disabled.** *Decision: signal engine method (the six domains).* The prototype measures a minor's platform activity, including activity after 01:00. The alternative is to ship it on with a disclosure. It costs the pilot one of Layla's two signals until pass 4 rules; it buys not building a surveillance measure before anyone has decided it is permissible. Planned on: designed in full (§4.3), off by default, the night-activity measure not built.

**C3 · Two numbers the prototype shows are removed rather than defined.** *Invariant 3, "every number a user sees traces to a source".* Signal strength and confidence are removed (§9). The alternative is to define signal strength as a monotone function of level, breadth and persistence and keep the meter. It would be a number with a definition and no meaning a counselor could use, and the confidence percentage cannot be defined at all before a backtest. The frozen demo will keep showing both; the demo script should not read them aloud, and the Next.js rebuild prints the level, the window and the breadth.

**C4 · A known family circumstance no longer lowers a case.** *Prototype behaviour changed.* The prototype's context picker reduces the score for "family circumstance noted: pastoral route". This plan treats risk-adding context as `inform` or `route`, never `suppress` (§6.2), on the argument that a known difficulty is a reason for attention. The school can flip the attribute, visibly. Listed because it changes a demonstrated behaviour.

**C5 · The common-cause guard sits next to invariant 2.** It reads the share of the school outside band in a week and caps that week's levels. No student is compared with another and no ranking occurs, but it is the one place a student's tier depends on data about other students. The alternative is no guard, with the calendar as the only defence against a school-wide event, and a morning in which forty attendance cases open at once. Planned on the guard, as a parameter the counselors can set to 100% (off), and as a question to them.

**C6 · Thresholds are per school, not per counselor.** *Decision: "counselors must be able to configure what they consider urgent".* Read as the counseling team, not each counselor (§10.2). The alternative, per-counselor thresholds, costs a tier that means four things and a student who changes tier when reassigned. If the elicitation shows irreconcilable disagreement, per-counselor overrides become an open decision rather than a default.

**C7 · The engine proposes `urgent` for the corroboration pattern.** *Invariant 5.* Some safeguarding leads want a system that never says "urgent" and leaves the routing entirely to the counselor. The tiering row is data and the elicitation's Part E asks; the default proposes, because the prototype's Tariq is the case the product is sold on.

**C8 · `persist` changes meaning.** The prototype's single slider ("consecutive weeks a weak signal must repeat before it escalates", default 3) becomes `persist_weak` (unchanged at 3) and a new `persist` for moderate levels at 2. A counselor who read the old slider will find two. The alternative, one number for both, makes a strong CUSUM signal wait three weeks; the split is what lets the engine act in two.

**C9 · Monitor churn.** Opening a monitor case for every single shock produces, computed, some fourteen to thirty quiet cases a week on a caseload of 87. The prototype's own copy for a quiet file ("the engine is watching, and will open a case if that changes") argues for fewer. Planned on `shock_opens_monitor = true` because the prototype shows the single-outlier case (Yousef) as a monitor case, with the parameter exposed and the count reported in shadow mode.

**C10 · Weekly delivery changes what "within 2 school days" promises.** Already stated by pass 2; restated because it is the engine's SLA: under the weekly pack the clock starts at the Monday commit and the case shows both dates. The alternative is to hide the observation date, which would make the engine look faster than the data.

---

## Open decisions

| # | Decision | Options | Recommendation | Who decides |
|---|---|---|---|---|
| 1 | Event-triggered evaluation for teacher flags, context and enrolment changes | (a) nightly only; (b) hybrid with the daytime asymmetry (§7.5) | (b) | Davide; ACS counselors on whether daytime raises are welcome |
| 2 | Engagement domain | (a) off until pass 4 and the school's disclosure; (b) on from the pilot with CAROS activity only; (c) on with Google Classroom | (a), then (c) if pass 4 permits | pass 4, ACS (question 14 in ACS-IT-QUESTIONS.md) |
| 3 | Signal strength and confidence | (a) removed, level and breadth shown (§9); (b) a defined composite score kept as a meter | (a) | Davide |
| 4 | Relapse uplift | 0, 1 (default) or 2 tiers | 1; the prototype's Hana is urgent only at 2 | ACS counselors (vignette 11) |
| 5 | Common-cause guard | on at 25%; off (100%) | on | ACS counselors |
| 6 | Whether the engine may propose `urgent` for corroboration | proposes; stops at `checkin` with a route flag | proposes | ACS CPO and counselors (Part E) |
| 7 | Threshold scope | per school; per counselor overrides | per school | Davide; revisit after the elicitation |
| 8 | Commit-triggered evaluation | never; scheduled pack only (backfill); every commit | scheduled pack only during shadow | pass 2 open decision 12, Davide |
| 9 | `shock_opens_monitor` | true; false | true, measured in shadow | ACS counselors |
| 10 | Grade 8 history for Grade 9 entrants | import from the same SIS; do not | import, if ACS exports it | ACS registrar (question below) |
| 11 | Inheritance across a level change (SL to HL) | off (default); on | off | ACS coordinator |
| 12 | Fairness labels | ACS supplies nationality, gender, language, SEN under a fairness-audit purpose; supplies a subset; supplies none | a subset the DPO agrees to, with the audit's limits stated | ACS DPO, pass 4, counsel |
| 13 | The counselor log during shadow mode | daily entry required; weekly only | daily, thirty seconds | ACS counselors |
| 14 | Shadow exit precision bar | 60% at check-in and above (default); the number the counselors name | the counselors' number | ACS counselors |
| 15 | Who activates a threshold version | caseload lead; any counselor; CAROS engineer during shadow | caseload lead, with the engineer's acknowledgement in shadow | Davide, pass 4 |
| 16 | Retrospective tier cap | review (default); monitor | review | ACS counselors |
| 17 | Recovery weeks | 2 to 6 | 3 | ACS counselors |
| 18 | Whether a risk-adding context may ever lower a tier | never (default); school's choice per kind | never | ACS counselors and CPO |
| 19 | The MAD versus Qn as the scale estimator | MAD (default); Qn if the backtest shows lead time lost | MAD | Davide after the backtest |
| 20 | Retention of shadow evaluations and the counselor log | as live signals; shorter | as live signals | pass 4, counsel |

---

## For other passes

**Pass 4 (security, privacy, compliance).** The rule on measuring a minor's platform activity (§4.3) and the disclosure it needs; the `signal.shadow`, `signal.counselor_log` and `fairness.label` data classes and who may read each; the fairness-audit schema, its legal basis under the UAE PDPL and GDPR, the AI Act Article 10(5) pattern as a template, and whether ADEK adds anything; the support-grant path for threshold activation during shadow; per-teacher concern rates as a sensitive report and who at the school may see it; what families are told about the engine, in shadow and live; retention of shadow rows and of the log; the on-call alert channel (email, SMS) carrying identifiers only; the engine package's no-`fairness`-import test as a control the school's IT review can be shown.

**Pass 5 (AI design).** The model may rephrase a case **headline** from the rule's headline template and the rendered summaries; it may never add, change or remove a number, a date, a tier or a level, and the rule template is always available beside its output. The co-pilot answers "why is X in check-in" from `rule_hits`, `suppressions` and the evidence chain, and must refuse to rank students (the no-comparison test has a co-pilot twin). Meeting briefs read `signal.evaluation.level`, `breadth` and the window, never a score. Pseudonymisation must preserve the rule keys and the numbers, which are not identifiers. The confidence percentage does not come back as an AI-estimated number.

**Pass 6 (build sequence).** `packages/engine` as a pure library with the scenario suite (§15.1) as its acceptance test, built before any screen and before the seed's narrative layer is retired; the calibration script committed beside it; migrations D17 to D32 in order after pass 2's D1 to D16; the Azure Monitor alert rules and the `/health/sweep` endpoint as part of the sweep's definition of done; the elicitation session (§10.5) scheduled before the first configuration version is written; shadow mode as the pilot's first phase with the counselor log in the thin slice; the backtest as a gate between shadow and live if history exists, otherwise the shadow comparison alone; Fable 5.1 for the engine's statistics and the tiering rows, per pass 6's own reservation rule; a review of the engine by a different model from the one that wrote it.

**Pass 2 (ingest), for the revision pass.** `flag_tag`, `context_kind` and `behaviour_category` attribute schemas (D27) belong in the vocabulary seeding; `ingest.after_commit` should mark `(student, measure, week)` dirty on supersede so §13.7 has its input; the `stale_as_of` warning should feed `evaluation.as_of` so a stale domain is visible on the case.

**Pass 1 (architecture), for the revision pass.** D17 to D22 change tables pass 1 created; the unique index change on `sweep_run` (D21); `core.school.sweep_hour` (D29); the resolved weekend assumption (Saturday and Sunday, from January 2022) for the ACS seed.

---

## Questions for ACS

In the style of `ACS-IT-QUESTIONS.md`, numbered after pass 2's last question (85). Each says who is likely to answer. Questions 37 to 44 in that file already ask the counselors the broad version; the ones below are the specific inputs the engine needs, and §10.5 is the session that asks them properly.

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
95. If most of the school's attendance dips in one week (an undeclared event), should the engine hold that week's individual signals and tell the school admin, or treat every student on their own regardless?
96. Would you record, in under thirty seconds a day during the pilot, which students you gave attention to and why, without seeing what the engine thought until a monthly review? This is the only way the engine's judgement can be compared with yours.
97. How long should something have to persist before it becomes a card rather than a mark on the sheet: two weeks of data, three, more?
98. When a student recovers, how many weeks inside their own band before you would want the case marked as a positive change: two, three, four?

**Systems and data · IT, registrar**

99. Do Grade 9 entrants come up from ACS's own middle school in the same Veracross instance, and can their Grade 8 attendance and behaviour history be exported? It is the student's own history and would shorten the engine's cold start for them from a term to nothing.
100. In the historical export (pass 2 question 83), do assignment grades carry the date graded and the date due, and does attendance carry the period or session? Without dates the engine can only be tested on term grades.
101. What is the school's conduct-point or behaviour-category scheme, and which categories (suspension, exclusion, others) should the engine treat as serious on their own?
102. Do all high school sections keep a gradebook in Veracross, or do some teachers grade only in ManageBac or Google Classroom, or on paper? A section without a gradebook has no academic series, and the plan needs to know which students that affects.
103. Does the school hold a dated record of the students the counselors supported in the last two years (intervention logs, referrals, escalations, parent-contact notes), and could it be pseudonymised alongside the SIS export? Without it the backtest cannot measure lead time.

**Safeguarding · Lead Child Protection Officer**

104. Which teacher-concern tags, or combinations of tags, must route to you regardless of anything else the engine sees?
105. During the pilot's shadow period the engine will record inferences about real students that no one acts on. Is that acceptable under the school's safeguarding policy, and who at the school should be able to see those records?

**Data protection · Data protection lead, leadership**

106. To test whether the engine alerts at different rates for different groups, CAROS would need nationality, gender, language background and special educational needs status per student, held apart from everything else and used only for that audit. Is the school willing to supply some or all of these, under what legal basis, and if not, is it content that the fairness claim is then untested?
107. During shadow mode, what should families be told about the engine, if anything, and when?

**The pilot · leadership, counseling team**

108. Is the school content that the pilot's first phase produces no visible tiers for four to eight weeks while the engine runs in shadow and the counselors keep a daily log, and that going live is conditional on the comparison meeting the bar the counselors set?

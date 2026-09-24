# CAROS backend: the planning prompts

Six planning passes with Fable 5.1, one adversarial review with Opus 5.5, then one revision pass with Fable 5.1. Each pass goes deep on one topic and reads the outputs of the passes before it. `CONTEXT.md` holds everything they share, so the passes stay consistent.

---

## How to run them

**Where.** Run each pass as a **fresh Claude Code session** in `EdTech-folder/`, with the model set to **Fable 5.1** and effort at the highest setting available. Running inside the repository matters: the pass can read `index.html` directly instead of trusting a summary of it, and it has web search for verifying citations, regulations, cloud regions and pricing. If you run a pass somewhere without repository access instead, attach `CONTEXT.md`, `PRODUCT.md` and the earlier outputs, and accept that it cannot check the code.

**One pass per session.** Each pass is long and reads a lot. A fresh session keeps the context clean and stops an earlier pass's reasoning from leaking into a later one's judgment. Later passes pick up earlier work by reading the files in `out/`, not by remembering.

**Order.**

```
1 Architecture and data model
├── 2 Ingest and integrations      ┐ these two can run
├── 3 Signal engine                ┘ at the same time
4 Security, privacy, compliance    (needs 1 and 2)
5 AI design                        (needs 1 and 4)
6 Build sequence                   (needs everything)
7 Review, Opus 5.5                 (fresh session, never the one that wrote a pass)
8 Revision, Fable 5.1              (after you have marked up the review)
```

**Between passes, read the output.** In particular read the "Challenges" and "Open decisions" sections. If a pass departs from a decision and you disagree, tell the next pass so. A disagreement caught after pass 1 costs a sentence; caught after pass 6 it costs a rewrite.

**What to paste.** For each pass, paste the **standing header** below, filling in the pass number and filename, followed by that pass's prompt.

---

## Standing header (paste at the top of every pass, 1 to 6)

```
You are planning the backend for CAROS, a platform for school counseling teams. This is a planning task. Do not write application code, and do not create or modify any file outside backend-plan/out/. This is not one of the UI phases described in PHASES.md, so the skills listed there do not apply.

Before anything else, read backend-plan/CONTEXT.md in full. Then read PRODUCT.md. Then read the earlier pass outputs listed in this prompt. Consult index.html directly whenever you need the exact behaviour of a rule or the shape of a piece of data. The code is the authority over every document, including CONTEXT.md, and where they disagree you should say so.

The rules in section 12 of CONTEXT.md apply throughout. In short: plan on the decisions in section 3 and challenge them openly rather than silently; never weaken the invariants in section 4; cite sources precisely or label a claim as an assumption; use web search to verify current facts rather than relying on memory; end with open decisions and with questions for ACS.

This is pass {N} of 6. The six passes are: 1 architecture and data model; 2 ingest and integrations; 3 signal engine; 4 security, privacy and compliance; 5 AI design; 6 build sequence. Stay within your pass. If you notice something another pass must handle, list it under "For other passes" at the end.

Write the result to backend-plan/out/{FILENAME}. Make it as long as it needs to be for someone to build from it, and no longer.
```

---

## Pass 1 · Architecture and data model

Filename: `01-architecture-and-data-model.md` · Reads: nothing earlier

```
Your job is the foundation every other pass builds on: where CAROS runs, how the backend is shaped, and the complete data model.

Settle the following, each as a decision record (context, options considered, decision, consequences):

1. Cloud provider and UAE region, with the specific managed services for Postgres, object storage, scheduled jobs, transactional email, secrets and logs. Verify that each service is actually offered in that region today. Give a monthly cost at the pilot, year 1 and year 3 scales in CONTEXT.md section 5.

2. The backend's shape. The frontend is Next.js and TypeScript. Decide whether the backend lives in Next.js route handlers and server actions, in a separate service, or a mix, and why. Choose the ORM or query layer and the migration tool. Decide how API contracts are typed and shared with the frontend. Choose how the nightly sweep runs.

3. Repository layout. Four people must be able to work in parallel without collisions, with clear module ownership and typed contracts between modules. The signal engine should be a pure, independently testable package.

4. Tenancy. Every table carries the school, isolation is enforced by the database and not only by application code, and you should explain how the application connects so that enforcement is actually in force on every query. Explain how the same code runs as an isolated single-school deployment when a school demands one.

5. The complete schema, as DDL. Cover every entity in CONTEXT.md section 7, including the ones whose screens ship later: IB selection, CAS, Extended Essay, discovery and pathways, the letter engine's data, mentors, messaging and documents. In particular:
   - Real timestamps and intervals in place of the prototype's display strings.
   - Which reference data is global (university entry requirements, tuition, deadlines, each row with a source URL and retrieval date) and which is per school (the IB catalogue, timetable periods, prerequisites, course viability rules, calendar and exam periods, grade naming).
   - Versioned configuration: thresholds, import mapping profiles, rule tables.
   - Signals that record the configuration version and an evidence snapshot they were produced under, so a past alert stays explainable after the rules change.
   - An append-only audit log that records access as well as changes.
   - An event stream from which the reporting metrics in CONTEXT.md section 11 item 2 can be computed.
   - A permission model stored as data, so adding a role later is configuration, not a migration.
   - How soft deletion, erasure requests and an append-only audit log coexist.
   - A per-tenant data classification (synthetic or real) that drives the demonstration-data marker.

6. Derived versus stored. The prototype computes the run, course demand, supervision load and dimension statuses at read time on purpose. Say which values must never be stored as a second copy of the truth, which may be materialised for performance, and how a materialised value is kept correct.

7. State machines, with every transition and who may make it: the concern case (its stages and its tier), the intervention, the IB subject selection, the Extended Essay, and the pathway approval.

8. Seed data. The ACS synthetic tenant, ported from the prototype. And a second synthetic school, deliberately unlike ACS: British, Years 10 to 13, a Designated Safeguarding Lead rather than a Child Protection Officer, A-levels, an iSAMS-shaped export, the IB module switched off. Both are used in tests from the first week, because that is the only reliable way to catch ACS-shaped assumptions.

9. Environments, backups, point-in-time restore, and restore drills.

After the decision records and the DDL, give a short entity relationship summary, the module map, "Challenges" (any decision in CONTEXT.md section 3 you think is wrong, argued), "Open decisions", "For other passes" and "Questions for ACS".
```

---

## Pass 2 · Ingest and integrations

Filename: `02-ingest-and-integrations.md` · Reads: `01`

```
Your job is how school data gets into CAROS, now through termly CSV exports and later through live connectors, in a way that makes the second school cheap to onboard. The decisive requirement is that each school's differences are data, never code.

Settle the following:

1. The import pipeline end to end: upload, retention of the raw file, the per-school column mapping profile, validation, a dry-run preview that shows exactly what will change, commit, a rejection report the uploader can act on, idempotent re-import of a corrected file, and rolling back a bad import. Say who authors a mapping profile and through what interface.

2. Identity resolution: a stable key for each student across systems and terms, name changes, transfers in and out mid-year, withdrawals, duplicate records, siblings.

3. Normalisation: grade scales (IB 1 to 7 and points out of 45, AP 1 to 5, percentages, letter grades), predicted versus achieved grades, attendance codes including lateness and the reason for an absence, behaviour incidents, timetables and class rosters, parent contacts and relationships, the school calendar and exam periods. Rosters decide what a teacher may see, so treat their correctness as a security property. Calendar and absence reasons feed the signal engine's contextual suppression.

4. The granularity problem. The signal engine wants per-assessment grades and per-session attendance over rolling weeks. A termly CSV may give far less. Say plainly what a realistic termly export supports, what it does to a weekly personal baseline, and what minimum export the pilot must ask ACS for. If termly data cannot support the product's core mechanism, say so.

5. The connector interface, with CSV as its first adapter. Then, for Veracross, ManageBac, Maia Learning and Google Classroom: what each is publicly documented to expose, its authentication model, rate limits, whether read-only access is possible, and which CAROS fields it would feed. Cite the vendor documentation. Define source-of-truth rules for when two systems disagree, and show how CAROS avoids making anyone maintain a university list twice (Maia) or IB records twice (ManageBac).

6. Test fixtures: a specification for a synthetic Veracross-shaped termly export and a synthetic iSAMS-shaped one, labelled clearly as inferred from public documentation rather than taken from a real file.

7. Onboarding a new school: every step from a signed agreement to the first successful nightly sweep, and which steps need a human from CAROS.

Finish with "Challenges", "Open decisions", "For other passes" and "Questions for ACS".
```

---

## Pass 3 · Signal engine

Filename: `03-signal-engine.md` · Reads: `01`, and `02` if it exists

```
Your job is the part of CAROS nobody else has: detecting when a student moves against their own baseline, and turning that into the counselor's triaged morning. It must be grounded in real evidence about what actually signals that a student needs support, and it must be something counselors can shape.

Ground it in research, and verify every source. Places to start, not conclusions to adopt: early warning indicator research on attendance, behaviour and course performance (for example Balfanz and colleagues on the "ABC" indicators, and the University of Chicago Consortium on School Research's on-track indicator work); statistical methods for detecting change in short individual time series (robust location and scale estimates, EWMA and CUSUM control charts, change-point detection); and the literature on alert fatigue in clinical decision support, because a counselor's queue fails the same way. Find better sources where they exist. Be explicit about which findings come from cohort-level prediction and do not transfer directly to deviation within one student's history.

Settle the following:

1. What the engine is for, in measurable terms. What a correct signal is, and the relative cost of a miss against a false alarm for a counselor responsible for about 87 students.

2. Per domain (academic, attendance, engagement, behaviour, teacher concern, university progress): the input series and its cadence given the data realistically available from pass 2, the features, how the personal band is computed, the minimum history, robustness to outliers and missing data, term boundaries and seasonality.

3. Cold start. Grade 9 entrants, transfers and new subjects have no personal history. Say what the engine does until a baseline exists, without falling back on comparison with other students.

4. Contextual suppression: exam periods, authorised absence, subject changes, and context a counselor or teacher adds. The inputs and the logic.

5. Combination: how evidence across domains combines, how qualitative teacher concerns enter, persistence, and how recovery is detected for the positive tier. Whether a teacher concern, which arrives live, should trigger evaluation immediately rather than waiting for the nightly sweep. Argue it.

6. Mapping to the five tiers and their SLA meaning, with hysteresis so a student does not move between tiers night after night on noise.

7. Every number the prototype displays (signal strength 0 to 100, a confidence percentage, a sigma value, signed evidence weights) either gets a precise definition or is removed. No number without a meaning.

8. Counselor control. Which parameters counselors can set, their bounds, defaults and versioning, and guards against a configuration that silently switches a domain off. Also an elicitation protocol for learning what counselors consider urgent before the engine is configured, including a structured questionnaire that could actually be run with the ACS counselors, and how its answers become parameters.

9. Alert budget. How many new items a counselor should expect each morning under the defaults, and how the engine keeps the queue actionable.

10. Fairness. How to test whether the engine alerts at different rates for different groups of students (nationality, gender, language background, special educational needs), what to do if it does, and the privacy tension in holding the data needed to test it.

11. The nightly job as a reproducible pure function over a student's series, the configuration version and the context. Orchestration, idempotence, partial failure, re-runs, the "what changed overnight" comparison with yesterday, and monitoring that tells a human before 07:00 if the sweep did not run.

12. Shadow mode for the pilot: the engine runs and records cases that counselors do not see, and counselor judgement is captured so the two can be compared.

13. Validation. First, before any real data, an adversarial synthetic set designed to break the engine: a strong student quietly declining, a struggling student genuinely recovering, a single outlier, a term break, a transfer, missing weeks, a student whose only signal is a teacher concern. Second, with pseudonymised historical exports under a data processing agreement, a backtest measuring lead time and precision against cases counselors actually handled. State plainly what cannot be known until the second step.

14. What the engine writes for each signal so that the evidence chain renders and stays explainable after the configuration changes.

Include the formulas. Finish with a list of every source cited, then "Challenges", "Open decisions", "For other passes" and "Questions for ACS", including questions for the counselors themselves.
```

---

## Pass 4 · Security, privacy and compliance

Filename: `04-security-privacy-compliance.md` · Reads: `01`, `02`, `03`

```
Your job is making CAROS safe to hold child welfare and safeguarding records about minors, under a real school's name, in Abu Dhabi, and able to pass a school's IT, safeguarding and legal review.

Settle the following:

1. Identity. Google Workspace sign-in for staff and students: restricting to the school's domains, provisioning and deprovisioning, mapping a Google identity to a CAROS person and role, and staff who hold more than one role. Magic links for parents, bound to a relationship verified from the SIS contacts rather than to whoever holds an email address, including parents with several children. Mentors, who are external adults with no school account: an identity path, verification, safeguarding controls, in-platform contact only, and the school's visibility of mentor conversations. Session lifetimes and step-up for sensitive actions.

2. Authorization. The permission model as data. Enforcement at the database at tenant and row level, and in the application. Sensitivity classes (for example safeguarding, counselor notes, signals and tiers, academic records, directory data) and which roles can see which. Teachers scoped by roster. Signals and notes never visible to students or parents. Counselor cover and case handover through a logged break-glass path. An operational support path for the CAROS team to diagnose a school's problem, which is not a product role but is unavoidable, with its own approval and audit.

3. Audit. What is logged, including every read of a sensitive record. How append-only is guaranteed, whether tamper evidence is warranted, who may read the audit log, and how the audit log's own retention interacts with erasure.

4. Safeguarding escalation end to end, including exactly what the email to the Child Protection Officer may and may not contain (minimum necessary, no welfare detail in the email itself), acknowledgement, and what happens when it is not acknowledged.

5. The regulatory map, with precise citations. The UAE Personal Data Protection Law (Federal Decree-Law No. 45 of 2021) and the current status of its executive regulations. What ADEK requires of Abu Dhabi private schools and their third-party processors for student data and hosting. GDPR as the design floor, given families from more than 80 countries. FERPA-shaped expectations at an American-curriculum school. Considerations specific to children's data. Distinguish what legally applies from what is good practice. Identify controller and processor roles, outline the data processing agreement, and list the sub-processors (cloud, email, AI provider).

6. AI and residency. Data at rest stays in the UAE, but the AI features send student information to a model. Set the rules for what may leave, in what form, to whom, under what retention terms, and whether any data class is excluded from AI entirely. Pass 5 designs the mechanism; you own the rule. If no compliant path exists for a feature, say so.

7. Retention and erasure. A proposed schedule for each record class with its rationale, what the law may require to be kept, how erasure works alongside an append-only audit log and backups, and how subject access requests from parents and students are fulfilled. Mark every number as a proposal for counsel.

8. A threat model covering at least: leakage between schools, a teacher reading beyond their roster, a parent link reaching the wrong child, a compromised staff account, prompt injection from student and teacher text into staff-facing AI, malicious uploads, insider access by CAROS staff, and a crafted CSV import.

9. The platform baseline: encryption in transit and at rest, key management, secrets, logs free of personal data, dependency and supply-chain hygiene, backups, incident response and breach notification, and what a school's IT security review will ask for (questionnaires, a penetration test, certifications) and at what point to obtain each.

Deliver a permission matrix (role by data class by action). Finish with "Challenges", "Open decisions", "For other passes", "Questions for ACS" and "Questions for counsel".
```

---

## Pass 5 · AI design

Filename: `05-ai-design.md` · Reads: `01`, `03`, `04`

```
Your job is every place a language model touches CAROS, designed so the trust spine holds: rules decide, the model writes. The features in scope for v1 are the counselor co-pilot, student discovery chat and pathway analysis, meeting briefs, parent email drafts, and Extended Essay research question feedback. The recommendation letter engine gets its data design now and its generation later.

Settle the following:

1. A table, feature by feature: what deterministic code computes, what the model receives, what it may produce, and what it may never produce.

2. The unsourced numbers. Every university target carries an admission probability that traces to nothing (CONTEXT.md section 11 item 3), and archetype milestones carry unsourced factual claims. Design the sourced reference data and deterministic classification that replaces them, or state that the number comes off the screen.

3. For each feature: inputs, retrieval scope, permission enforcement before retrieval rather than after, prompt structure, structured output schema, grounding with citations to record identifiers, honest behaviour when there is no answer, visible labelling as AI-generated, the human review step, and the audit events written.

4. Co-pilot retrieval. How retrieval is scoped to one counselor's permitted students. Whether this needs embeddings at all, or whether structured queries over the schema are enough at this data size. Argue it. How answers avoid ranking students against each other.

5. The discovery flow and its approval gate: the student sees an analysis immediately, but roadmaps go to a counselor, who approves, amends inline, or sends back with reasons that become explicit constraints when the candidates are regenerated.

6. Student safety. Any student free text may contain a disclosure of self-harm, abuse or crisis. Design detection, routing to a human under the school's safeguarding policy, and what the student sees in that moment. The model never counsels.

7. Prompt injection. Students, parents and teachers write text that staff-facing models later read. Defend the most privileged feature, the co-pilot, against it.

8. Data flow and residency: the mechanism for pass 4's rule. Pass 4 permits only zero-data-retention models that are not Anthropic Covered Models, with pinned inference geography. Verify which current models qualify, including Opus 5.5 (released 2026-09-22), which pass 4 did not assess; do not default to an older model just because its terms are better known. Which provider and endpoint, whether any UAE-region inference exists for the chosen models (verify), pseudonymisation and re-identification, minimising fields, and the provider's retention terms.

9. Model abstraction. Model identifiers in configuration, never in code; per-feature model and effort settings; prompt templates versioned in the repository; the model and prompt version recorded on every generated artifact; and the evaluation a new model must pass before a feature switches to it.

10. Evaluation. An eval set per feature, including adversarial synthetic student profiles (a flat profile, grades that contradict stated interests, two students who differ by one answer, two identical students who differ only in passport or budget, a sarcastic minimal responder). The test is whether outputs differentiate, not whether they sound good. Grounding and hallucination checks, and the pass bar for shipping a feature or changing its model.

11. Cost per school per month at the pilot, year 1 and year 3 scales, using current published pricing that you verify, with prompt caching and batch processing where they apply.

12. Failure handling: timeouts, refusals, provider outages, degraded modes, and what the user sees in each.

Finish with "Challenges", "Open decisions", "For other passes" and "Questions for ACS".
```

---

## Pass 6 · Build sequence

Filename: `06-build-sequence.md` · Reads: `01` to `05`

```
Your job is turning passes 1 to 5 into an order of work that one builder with a coding agent, plus teammates in parallel, can execute from an empty repository to a pilot a school can use, and on to the full surface set.

Settle the following:

1. Phases. A reasonable first phase is the thin slice: tenancy, identity, CSV ingest, the signal engine and nightly sweep, the triage queue, the case file with its evidence chain, teacher concern logging, audit, and the safeguarding escalation email. Challenge that if you disagree. For each phase: scope, dependencies, the schema and modules it touches, acceptance criteria someone can check, and what "done" means including tests.

2. Parallel workstreams. How four people split the work with module ownership and contracts, what can proceed concurrently, where the integration points are, and branch and review discipline designed to prevent the silent overwrite this repository has already suffered once.

3. Working with a coding agent across many sessions. How each phase breaks into session-sized tasks. The plan file and CLAUDE.md the backend repository should carry. What every session reads first and updates last. How documentation is kept from drifting away from the build.

4. The model and effort for each phase, in the same form PHASES.md uses (model, effort, and one line on why), using the models in CONTEXT.md section 2. Opus 5.5 is the default builder. Reserve Fable 5.1 for work where a subtle error is expensive and hard to see: authorization and row-level security policies, safeguarding routing, the signal engine's statistics, schema changes that are hard to reverse, and problems Opus 5.5 has already failed at twice. Mark which work must be reviewed by a different model from the one that wrote it.

5. Tests. Signal engine unit tests against the adversarial synthetic set. Contract tests between modules. Authorization tests proving each role cannot read what it must not, run against both synthetic schools. Import tests against both export shapes. AI evals. A smoke test of the nightly sweep.

6. The frontend rebuild alongside the backend, using the prototype as the specification, and how screens are ported without losing the rules encoded in them. The prototype is frozen, so the Next.js app is the only place a school will see anything new: say when the first genuinely demoable build exists and what it shows.

7. Operations: the deploy pipeline, environments, running migrations in production, monitoring and alerting (the nightly sweep above all), what on-call realistically means for a very small team, backups and restore drills.

8. Gates where outside help is required, placed on the sequence: a data processing agreement before any real school data moves, legal review of retention and the DPA, a security review and penetration test before real data, and anything else you judge necessary.

9. Pilot-ready: the checklist that a school's IT team, its Child Protection Officer and a counselor would each need satisfied.

10. Risks, ranked, with mitigations.

Finish with the consolidated "Open decisions" from all six passes, deduplicated and ordered by what blocks what, and the consolidated "Questions for ACS", deduplicated and grouped by who at the school would answer them.
```

---

## Pass 7 · Adversarial review with Opus 5.5

Run in a **fresh session** with the model set to **Opus 5.5** at the highest effort. Never in a session that wrote a pass: a model reviewing its own reasoning in the same context tends to agree with it.

Filename: `07-review.md` · Reads: `CONTEXT.md`, `PRODUCT.md`, `01` to `06`

```
You are reviewing a backend plan for CAROS, a platform for school counseling teams, written in six passes by another model. Your job is to find what is wrong with it. Do not summarise it and do not praise it except where section B asks you to. Do not write application code, and do not modify any file except backend-plan/out/07-review.md.

Read backend-plan/CONTEXT.md in full first, then PRODUCT.md, then backend-plan/out/01 to 06. Consult index.html whenever you need to check a claim against the prototype.

Look specifically for:

1. Contradictions between passes: a table defined one way in pass 1 and used another way in pass 4, a rule set in pass 4 that pass 5's mechanism breaks, a phase in pass 6 that depends on something no pass designed.
2. Violations of the invariants in CONTEXT.md section 4, however indirect.
3. Silent departures from the decisions in CONTEXT.md section 3.
4. Citations. Check every one you can with web search. Mark each as verified, wrong, or unverifiable, and quote what the source actually says where it differs.
5. Residency. Every path by which student data could leave the UAE, whether or not the plan acknowledges it.
6. Any place a model's output decides, gates or ranks something.
7. ACS-shaped assumptions baked into logic, which would break the second synthetic school (British, Years 10 to 13, DSL, A-levels, iSAMS, no IB).
8. Security and authorization holes, especially paths by which a teacher, parent, student, mentor or another school reaches data they must not.
9. Things in CONTEXT.md sections 7, 8, 9 and 11 that no pass handles.
10. The signal engine's statistical soundness, and whether it can work with the data granularity pass 2 says is actually available.
11. Over-engineering for the scale in CONTEXT.md section 5, and under-engineering where the stakes are high.
12. Arithmetic in the cost models.
13. Whether the build sequence is realistic and can actually be executed session by session.

Write:

A. Findings, ranked by severity. For each: severity (blocking, serious, moderate or minor), where it is (file and section), what is wrong, why it matters for this product specifically, the fix you propose, and your confidence. Leave a line under each finding that reads "Decision:" and nothing else, for Davide to fill in.

B. Keep: the parts that are right and that a revision must not disturb, with one line of reasoning each.

C. Judgment calls: disagreements where both positions are defensible and Davide has to choose, each with the two positions stated fairly.
```

---

## Pass 8 · Revision with Fable 5.1

Before running this, go through `07-review.md` and write your decision under each finding: accept, reject, or accept with a change. Also answer the judgment calls in section C.

Run in a fresh session with Fable 5.1 at the highest effort.

Filename: revises `01` to `06` in place, and writes `08-changelog.md` and `README.md`

```
You are revising a six-part backend plan for CAROS after an adversarial review. Do not write application code, and do not modify any file outside backend-plan/.

Read backend-plan/CONTEXT.md, PRODUCT.md, backend-plan/out/01 to 06, and backend-plan/out/07-review.md. In the review, each finding has a "Decision:" line written by Davide, the founder. Those decisions are final. Where he rejected a finding, do not act on it. Where a finding has no decision, list it as unresolved and do not act on it either.

Then:

1. Revise 01 to 06 in place to apply every accepted finding and every judgment call Davide answered in section C. Keep everything the review's section B says to keep. Make sure the six files agree with each other once you are done.
2. Write backend-plan/out/08-changelog.md: every change, which finding caused it, and which files it touched.
3. Write backend-plan/out/README.md: a one-page index of the plan, the final list of open decisions ordered by what blocks what, and the unresolved findings.
4. Merge every "Questions for ACS" section from the six passes into backend-plan/ACS-IT-QUESTIONS.md, under its existing headings, without duplicating questions it already contains. Mark each added question with the pass it came from.
```

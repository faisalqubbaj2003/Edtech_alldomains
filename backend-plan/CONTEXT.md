# CAROS backend: shared context for every planning pass

This file is the common ground for a series of planning passes. Every pass reads it first. It records what the product is, what has already been decided, what may not change, and a map of the prototype's data and behaviour.

It was written on 2026-09-22 from the prototype at commit `fb28217` (`index.html`, 10,048 lines), from `PRODUCT.md`, and from a structured interview with Davide, the founder who will build the backend. Line references are approximate and drift as the file changes.

**Corrections from pass 1.** Section 0.2 of `out/01-architecture-and-data-model.md` checked this file against the code and corrected several statements (IB selection statuses, case stages, three dimension statuses that are hard-wired rather than computed, and others). Where that table and this file differ, pass 1 is right.

**This file is a map, not the territory.** This repository has a documented habit of describing a build that no longer exists. Where this file and `index.html` disagree, the code wins, and you should say so in your output.

---

## 1. What CAROS is

CAROS (Counselor OS) is a platform for school counseling teams. Its job is to help a counselor with a caseload of around 87 students notice who needs support before those students ask, absorb the administrative weight of the university application cycle, and give each stakeholder exactly the view they need and nothing more.

The mechanism nobody else offers is **deviation from each student's own baseline**, not from a cohort average. CAROS learns each student's personal normal band across academics, attendance, engagement, behaviour, teacher sentiment and university progress, and raises a signal when that student moves against their own history. The counselor's caseload is a **triaged queue with five severity tiers and real SLA states**, not a list. The morning ritual is: an overnight sweep runs, and the counselor's first question is "what changed overnight?"

Read `PRODUCT.md` in full before planning. It is the authority on users, positioning, constraints, and what must never be fabricated.

### Where things are

| Path | What it is |
|---|---|
| `index.html` | The complete working prototype. Five role surfaces, all data in memory, no backend. Treat it as an executable specification of behaviour, rules, screens and data shapes. |
| `PRODUCT.md` | Product truth. Users, positioning, the IB module, brand commitments, anti-fabrication rules. One line is stale: it describes a `stuProb()` function that no longer exists (see section 11). |
| `CLAUDE.md` | How the prototype is organised, its invariants, and the history of the repo. |
| `DESIGN.md` | The visual system. Not relevant to the backend except where it encodes product rules (the five tiers, the letterhead rule). |
| `backend-plan/ACS-IT-QUESTIONS.md` | Questions that must go to the pilot school. Anything your plan has to assume because it is unknown belongs there too. |
| `backend-plan/out/` | Where each planning pass writes its output. Later passes read earlier ones. |

---

## 2. Who is building this, and how

Davide is building the backend himself, with Claude (Opus 5.5) writing most of the code across many sessions. Teammates (Faisal, Qasim, Taha) must be able to work in parallel on separate parts without collision. There is no fixed deadline; Davide will put in substantial daily hours and budget is not the binding constraint. **Optimise for long-term correctness over speed to first demo**, and say plainly when a cheaper or faster choice is the wrong one.

**Models available** as of 2026-09-22: Claude Fable 5.1 (most capable), **Claude Opus 5.5** (released 2026-09-22, reported by Anthropic as on par with Fable 5.1 on most tasks at a lower price and faster output), and Claude Opus 5. Sonnet 5.5 and Haiku 5.5 are announced but not yet released. Opus 5.5 may be newer than your training data; if you have not heard of it, check anthropic.com rather than assuming it does not exist. Verify current pricing and data retention terms for any model before relying on them. Note that Fable 5.1 is not offered under zero data retention, which matters for a system holding minors' welfare data.

The repository's history matters here. A bad merge on the single-file prototype silently destroyed four phases of design work, and the documentation twice described a build that no longer existed. Your plan should make that class of failure structurally hard: migrations rather than hand-edited schema, a test suite, a plan file the repository carries between sessions, module boundaries that let people work in parallel, and typed contracts between modules.

---

## 3. Decisions already made

These came out of the interview. **Plan on them.** You are expected to challenge any of them that you believe is wrong for the long term, but do it openly: state the challenge, the alternative, what it costs and what it buys, and then continue to plan on the decision as given unless you judge that following it would cause material harm. If you do depart from one, say so at the very top of your output, not inside a section. The passes are run separately, and silent departures make them contradict each other.

| Area | Decision |
|---|---|
| Frontend | Production frontend rebuilt in Next.js (App Router) + TypeScript. `index.html` is **frozen** as the sales demo and the behavioural specification, and stays deployed on Vercel for demos. Davide confirmed it is truly frozen: no feature work on it during the build, and it will not be split into separate files. Anything ACS asks for is built in the Next.js app, which means the build sequence must say when something new first becomes demoable to a school. |
| Scope | Design the **complete** schema for everything in the prototype. Deliver the surfaces in phases against that schema. |
| Data residency | **UAE region required from day one.** Student data at rest must live in a UAE data centre. |
| Identity | School SSO via **Google Workspace** (ACS uses it) for staff **and students**. Magic link for parents, who have no school account. Mentors are not covered by this decision; see section 11. |
| Cloud provider | Not decided. Must have a UAE region. Choose and justify. Note that Supabase has no UAE region, so an earlier plan to use it no longer holds. |
| Signal engine timing | **Overnight batch**, matching the morning ritual. The prototype's architecture page claims evaluation is immediate; that copy is wrong and will change. |
| Signal engine method | Specify the statistics in full, grounded in real research on what actually predicts students needing support. Counselors must be able to configure what they consider urgent, or tell us beforehand, and the engine is built around those parameters. |
| Data cadence | **Decided 2026-09-23 after pass 2:** design the signal engine for a **weekly** export pack (per-assessment grades, per-session attendance), and specify exactly what still works if a school can only supply **termly** data: which domains drop out or slow down, and how the interface says so honestly. Weekly is requested from ACS; termly is the degraded mode, never a silent one. |
| Data ingest | Termly CSV export from the SIS first, with a **per-school column mapping stored as data, never as code**. Designed as a connector interface so live integrations (Veracross, ManageBac, Maia Learning, Google Classroom) are later adapters, not rewrites. Which connectors, and when, is decided later. |
| Incumbent systems | ACS already runs Veracross (SIS), ManageBac (IB), Maia Learning (university applications) and Google Classroom. CAROS builds its overlapping surfaces anyway, **but designs to read from those systems** so nobody maintains the same data twice. |
| AI features in v1 | Counselor co-pilot over the caseload; student discovery chat and pathway analysis; meeting briefs; parent email drafts; Extended Essay research question feedback. |
| Recommendation letter engine | **Schema and surfaces now, model generation deferred** to a later phase. |
| Outbound notifications | Two only: **deadline and checkpoint nudges to students**, and **an email to the Child Protection Officer when a counselor escalates a safeguarding concern**. Parents receive no email in v1. |
| Retention and erasure | You propose a retention schedule per record class with the trade-offs. The numbers are set later by legal counsel. |
| File storage | Yes: raw SIS exports and import history; student documents (transcripts, Extended Essay drafts, portfolios); counselors' past recommendation letters, used later for voice matching. |
| Roles | The existing five: counselor, teacher, student, parent, mentor. The IB coordinator is a counselor view, not a sixth role. More roles later if needed. |
| Signal visibility | Tiers, signal scores, evidence chains and counselor notes are **staff-only**. Students and parents never see them. |
| Tenancy | Multi-tenant from the first migration. Build so that a single school can also be given its own isolated deployment if it demands one. |
| Models | The AI features call Claude. Model choice must be configuration, never code: a model was released in the middle of this planning process. |

---

## 4. Invariants

These are the product. They are not configuration and they are not open to challenge. A design that weakens one of them is wrong.

1. **The five triage tiers and their order.** `urgent` (route now under school policy) → `checkin` (within 2 school days) → `review` (this week) → `monitor` (no action required) → `good` (positive change, acknowledge). Never collapsed, never reordered, never re-themed or renamed per school. Defined at `index.html:1300` (`PRIO`).
2. **Signals are personal, never comparative.** Deviation is measured against the student's own baseline band. Never rank students against each other, anywhere, including in AI answers.
3. **The trust spine: rules decide, the model writes.** Deterministic tables own entry requirements, prerequisites, fee status, tuition, deadlines and reach/match/safety classification. The model only interprets, names, phrases and converses. Nothing that gates a decision or a submission is model output. Every number a user sees traces to a source.
4. **Provenance over authority.** Every signal shows the evidence that fed it. A past alert must remain explainable after the rules or thresholds that produced it have changed.
5. **Safeguarding escalation is a real, consequential, logged act.** It routes to a named Child Protection Officer (ACS's term; British schools say Designated Safeguarding Lead, and the term is a per-school field). It requires a reason, cannot double-fire, and is audited.
6. **The conversation is a gate.** An IB subject selection cannot be approved until a dated, attributed record of the review meeting exists.
7. **Two populations, never totalled.** The counseling caseload (one counselor's students across Grades 9 to 12) and the Diploma cohort (the school's IB students across Grades 10 to 12) answer different questions. No query, report or screen adds them together.
8. **Supervision capacity warns and never blocks.** An Extended Essay assignment over the school's guide is allowed and records that it was over.
9. **No fabrication.** No invented testimonials, customers, outcomes, benchmarks, pricing or press. While a real school's name is applied to synthetic data, a visible demonstration-data marker is a shipping requirement.
10. **Gamification exists on the student side only.** Counselor, parent, teacher and mentor surfaces are ungamified.
11. **Mentor contact is in-platform only**, for safeguarding. The word *match* is reserved for reach/match/safety and is never used for mentor pairing.

---

## 5. Scale and load shape

Planning assumptions, not validated figures. Use them to size things, and do not architect for traffic that does not exist.

| Horizon | Schools | Students | Notes |
|---|---|---|---|
| Pilot | 1 (ACS Abu Dhabi) | ~1,200 to 1,315 enrolled KG1 to Grade 12; ~320 to 380 on the counseling surface (Grades 9 to 12) | Nine counselors (four High School). Teacher count unverified, estimated 60 to 100. Parents are the largest, mostly read-only population. |
| Year 1 | 1 to 3 | under 5,000 | Peak concurrency in the low hundreds. |
| Year 3 ambition | 20 to 40 | 30,000 to 50,000 | Still a small-data system. |

Load shape matters more than volume: an overnight batch sweep before counselors arrive, then a morning burst when they do. Application deadline weeks concentrate student and counselor activity. Nothing else is heavy.

---

## 6. Roles and what each one does

| Role | Device | What they came to do | Scope of data |
|---|---|---|---|
| Counselor | Laptop, in bursts between meetings | Decide who needs them today; defend that decision later. Also runs the IB coordinator views. | Their own caseload. The prototype gives one counselor all 87. Cover and handover between counselors is unresolved; see section 11. |
| Teacher | Anything, 90 seconds between lessons | Log a concern (or a positive note, or context) about a student they just taught. Also: IB level sign-off for subjects they teach, Extended Essay supervision. | Their own classes only. The ⌘K palette already scopes a teacher to their class, not all 87. |
| Student | Phone first | Pathway discovery, IB/AP choice, subject selection, CAS, Extended Essay, personal statement, university targets, progress. | Their own record. Never sees tiers, signals or notes. |
| Parent | Phone | Is my child on track, what will it cost, how do I reach the counselor. | Their own child's record, filtered by grade. Never sees tiers, signals or notes. May have more than one child. |
| Mentor | Laptop or phone | Alumni volunteer: accept session requests, keep notes on mentees. | Only students who requested them, and only what they chose to share. External to the school. |

The parent and student navigation is grade-conditional (`roleNav`, `index.html:1898`). A Grade 9 family sees a near-empty portal on purpose, and the interface says why.

---

## 7. Data dictionary

Extracted from the prototype. Field names are the prototype's own. Many values that are display strings in the prototype ("13 Nov, 07:04", "6 weeks ago", "in 18 days") must become typed timestamps or computed intervals. Values marked **derived** are computed at read time in the prototype and must not be stored as a second copy of the truth.

### School (tenant) · `SCHOOLS`, `index.html:1131`
`id`, `name`, `short`, `initials`, `real` (a real institution's name is applied), `counselor` and `role` (demo persona), `safeLead`, `dept`, `sis` (which SIS the school runs), `safeguarding` (the school's term for the safeguarding role), `brand{primary, primaryDeep, accent}`, `mark` (logo). Missing and needed: timezone, academic calendar, term dates, exam periods, grade naming (Grades 9 to 12 vs Years 10 to 13), grade scales in use, curricula offered, enabled modules (IB selection, CAS, Extended Essay), destination systems modelled, data classification (synthetic or real).

### Student · `STUDENTS`, `index.html:1316`
Identity and profile: `id`, `name`, `av` (initials), `yr` / `grade` (9 to 12), `track` (`IB` | `AP` | `undecided`; ACS also runs its own high school courses, so the real choice is three ways), `goal` (declared direction), `gpa`, `pred` (predicted grades, in the scale of the student's track), `owner` (assigned counselor).
Case state: `prio` (tier), `prev` (yesterday's tier, drives "what changed overnight"), `movedWhy`, `headline`, `plain` (plain-language explanation), `signal` (0 to 100 strength), `window` (e.g. "14 days"), `severity`, `nocause` (the engine infers no cause), `context[]` (suppression checks already run), `stage` (`detect | explain | triage | act | follow | measure | learn`), `lastContact`, `openedBy` (a rule name or a person), `opened`.
Baselines: `baselines{domain: {label, band[lo,hi], series[8 weeks], pts[], unit, anomalyFrom}}`.
Evidence: `evidence[]{dom, src, date, txt, w}` where `w` is a signed contribution weight (negative for positive evidence). Its meaning is undefined in the prototype.
Suggested action: `action{what, when, why}`.
University: `uni{targets[]{u (university), c (course), p (admission probability %), b (reach|match|safety)}, flags[]}`.
The 72 generated roster students carry a stored `weeks[]` run and no baselines; the 15 authored cases carry baselines.

### The run (derived) · `weekRun`, `index.html:1281`
Per week: `kept` (every baseline inside band), `soft` (exactly one outside), `break` (two or more outside), `none` (no data). Derived from the same series the case page charts, so the sheet and the file can never disagree. `runBreaks` counts breaks.

### Tiers · `PRIO`, `index.html:1300`
`label`, `short`, `letter` (U C R M P), `mark` (glyph density), `order`, `sla` text. Invariant.

### Concern domains · `DOMAINS`, `index.html:1308`
`academic`, `attendance`, `engagement`, `behaviour`, `teacher`, `university`, `positive`. Semantic, identical at every school.

### Dimension views · `DIMS`, `index.html:3159`
Ten derived per-student dimension statuses, each returning `{r: critical|watch|good, v, note}`: application progress, list balance, deadlines, documents and references, personal statements, attendance, punctuality, academic, engagement, behaviour. All computed at render time.

### Intervention · `INTERVENTIONS`, `index.html:1566`
`id`, `sid`, `type`, `owner`, `opened`, `due`, `status` (`open | resolved`), `plan[]`, `outcome`, `resolvedIn`.

### Case notes · `S.caseNotes`
Per student: `{txt, by, when}`. Staff-only, never visible to the student, never used outside its purpose.

### Audit entry · `AUDIT` / `logAudit`, `index.html:1575`, `:1716`
`t`, `who`, `act`, `obj`, `det`. Event taxonomy in section 9.

### Thresholds · `S.thresh`, `vThresholds` at `index.html:2251`
`acad` (standard deviations below personal mean, 1 to 4), `att` (lates within a 10-school-day window, 1 to 6), `eng` (days of platform silence, 5 to 28), `persist` (consecutive weeks a weak signal must repeat, 1 to 6). The UI promises these are per school and versioned so any past alert can be explained. Shadow mode is offered as a pilot option.

### Teacher flag · `FLAG_KINDS`, `TFLAGS`, `index.html:3557`
Kinds: `concern`, `positive`, `note` (context such as "authorised absence", which can downgrade a case). Each kind has a fixed tag vocabulary. Record: `id`, `sid`, `by`, `kind`, `tags[]`, `txt`, `when` (with lesson period), `status` (e.g. `linked`), `routed` (what happened to it, shown back to the teacher to close the loop).

### Teacher · `TEACHER`, `index.html:3549`
`name`, `subject`, `classes[]` with rosters. The prototype's rosters are internally incoherent (a "Grade 11" class holding Grade 9 and 10 students); real rosters come from the SIS timetable.

### Application pack · `APP` / `EXTRA_APP`, `index.html:3043`
Per student: `stmt` (statement completeness %), `stmtLabel`, `days` (to deadline), `offers`, `subm`, `tot`, `tr` (transcript status), `cref` (counselor reference status), `trefs[]{n, st}` (teacher references), `forms`, `beh`. Status vocabulary `STMAP`: sent, received, final, draft, chased, pending, none, complete, missing.

### University reference data · `UNI_COSTS` `:3809`, `OFFERS` `:3816`, `UNI_REQS` `:3829`, `REQ_CHANGES`, `COURSE_CATALOG`, `UNI_COURSE_REQUIREMENTS`
Tuition, living costs, offers with conditions, entry requirements per university and course, recent requirement changes. Four destination systems modelled: UK, US, UAE, Canada. Canada is there deliberately, because domestic versus international tuition by passport is the clearest demonstration of fee-status logic. All authored demonstration content today, none of it sourced.

### Family · `PARENTS` `:3695`, `PMSGS_BY_GRADE`, `PARENT_MEETINGS_BY_GRADE`, `MEETING_TOPICS`, `MEETING_SLOTS`
Parent: `name`, `rel`, `email`, `phone`, `lang`, `pref` (contact preference), `consent`. Messages between parent and counselor. Meeting requests with topic, slot and note. Grade-keyed in the prototype because of the demo's grade switcher; in reality a parent links to one or more students.

### Academic record · `TRANSCRIPTS`, `SUBJECTS`, `IB_CORE`, `COURSES_BY_GRADE`, `G12_IB_TIMETABLE`, `getStudentClasses`
Transcript entries, current subjects and grades, IB core (TOK, EE, bonus points), timetables. Grade scales differ by track: IB 1 to 7 per subject and points out of 45; AP exams 1 to 5; percentages and letter grades elsewhere.

### IB subject selection · `IB_GROUPS` `:4232`, `IB_SUBJECTS` `:4247`, `SEL_ROUND` `:4406`, `SELREC`, `selCheck` `:4671`
Catalogue: 23 subjects, each with group, levels offered, **timetable period per level**, minimum enrolment to run, cap, prerequisite, and four prose fields. Round: academic year, opened, closes, coordinator. Selection record: `picks{group: {s (subject), lv (HL|SL), why (required reason)}}`, `status` (not started, submitted, signed, returned, approved), `v` (version), `log[]`, `talk` (the recorded review conversation), `booked`, `returnNote`. **`selCheck` is the rule engine** and the only place a submission is gated: group coverage, HL count, period clashes, prerequisites, stated-goal alignment, course viability. It returns findings of kind `block` (stops the form), `ask` (a question for the coordinator, never a fault) or `ok`. Demand and viability (`demandFor`, `subjectViable`, `demandRows`) are **derived at read time** and viability is a property of the subject, not of a level.
Sign-off chain: subject teacher answers the level question for their own subjects only, then the coordinator decides the whole selection, and only after the conversation is recorded.

### CAS · `CAS_STRANDS`, `CAS_OUTCOMES`, `CAS_OPPS`, `CASREC`, `CAS_TAGS`, `CAS_INTERESTS`, `casSum` `:4749`
Three strands, seven learning outcomes, browsable school activities with tags and spots, a student's interest tags, and per-student records. **Warning from the prototype:** `hrs` is the running programme total and `entries` is only the recent log; they are not the same number, and deriving either from the other is wrong. A real backend should hold the full ledger and derive the total, but must decide how imported historical hours are represented. Hours are a school-level expectation, not an IB rule.

### Extended Essay · `EE_MILESTONES` `:4811`, `EE_ROUND`, `EEREC` `:4851`, `EE_SUPERVISORS`, `EE_WAIT_DAYS`
Milestones with due days per year group; three carry `rppf:true` and are the IB's mandatory reflection sessions. Record: subject, research question, rationale, target teacher, supervisor, status, `log[]`, `done{}` per milestone. Derived: next milestone, stalled, waiting, nudge, supervision load, queue. **Drift is not pending**: a proposal waiting with a teacher is fine until it exceeds `EE_WAIT_DAYS` (7). Capacity guide is five essays per supervisor; it warns, never blocks. Every research question in the demo is authored and unique.

### Diploma cohort · `DPC`
The school's IB population, 201 records across Grades 10 to 12. A separate population from the caseload (invariant 7).

### Discovery and pathways · `ONBOARD_Q` `:6415`, `ARCHETYPES` `:6473`, `SUBPATH_DETAIL`, `DISCOVERY_FOLLOWUPS`, `scoreArchetypes`, `S.chatLog`, `PENDING_APPROVALS`, `APPROVED_PATHS`
A short onboarding survey, then an adaptive chat that classifies what the student is trying to work out (a university, an industry, or both), scores career archetypes, and proposes pathways. The student submits chosen pathways; a counselor approves, amends, or sends back with reasons. Scoring today is keyword matching, not a model. Archetype milestones contain factual claims (admissions test score medians, preparation times) that are unsourced.

### Roadmap and gamification · `S.roadmapProgress`, `confettiBurst`
Milestone completion awards XP and a celebration. Student side only.

### Personal Statement Lab · `S.psActiveSystem`
Per destination system, a statement workspace. Submission goes to the counselor's `psreviews` queue.

### Mentors · `MENTOR_REQS` `:8850`, `PARENT_MENTOR` `:3779`, `NETWORK`, `PATH_ALUMNI`, `ALUMNI_OUTCOMES`
Session requests from students (message, goal), a mentee list, a student's network. The paid marketplace was cut; mentor introductions are arranged by the school at no cost.

### Reporting · `METRICS`, `index.html:1589`
Detection quality, counselor efficiency, intervention performance, student progress. **Every figure is a target, not a measurement**; CAROS has never run at a school.

---

## 8. Screen inventory

Every surface the prototype renders, per role. The production frontend rebuilds these; the backend must serve them.

**Counselor** (`S.cv`): caseload sheet (`cohort-schedule`, `cohort`, `cohort-all`, `today`), command centre (`command`), priority queue and signal intelligence (`si-cases`, `si-why`, `si-interventions`), teacher flags inbox (`flags`), meetings (`meetings`), the ten dimension pages (`DIMS`), application season and flow (`app-season`, `app-flow`), letter engine (`app-letter`), 360° student files (`files`, with tabs), pathway approvals (`approvals`), personal statement reviews (`psreviews`), IB selections queue, demand sheet, CAS cohort and Extended Essay coordinator views (`ib-selections`, `ib-demand`, `ib-cas`, `ib-ee`), AI co-pilot (`copilot`), reporting (`prove`), signal architecture (`arch`), thresholds (`thresholds`), pilot and rollout (`pilot`). Plus the case file for each student (`S.open`), with evidence, baselines, interventions and notes.

**Teacher** (`S.tv`): class register (`class`), my classes (`tclasses`), subject choice sign-off (`classapprovals`), Extended Essay queue and supervision (`ee`), what I've logged and what happened next (`tlog`).

**Student** (`S.sv`, grade-conditional): my pathway (`discover`), high school guide (`guide`, Grade 9), my subjects or choose my subjects (`stuclass`), activities and CAS or Diploma core (`stucas`), my progress (`progress`, 11+), university targets (`targets`, 12), choosing IB or AP (`explore`), Personal Statement Lab (`pslab`, 11+), AP exams (`apexams`, 11+ AP), find a mentor (`mentors`, 11+), my network (`network`, 12).

**Parent** (`S.pv`, grade-conditional): overview, messages, high school guide (9), IB or AP (10+), grades and transcripts (11+), university requirements (12), AP exams (11+ AP), meet the counselor.

**Mentor** (`S.mv`): session requests, my mentees.

**Cross-cutting:** ⌘K command palette with role-scoped student search; role switcher and grade/track previews (demo apparatus, not product).

---

## 9. Mutation inventory and audit taxonomy

Every action in the prototype that changes data, with the audit event it writes today. This is effectively the write side of the API. Handlers live in `bind()` at `index.html:9141`.

| Actor | Action | Audit event |
|---|---|---|
| System | Open a case from a rule or anomaly | `CASE_OPENED` |
| System | Set or change a tier | `PRIORITY_SET` |
| System | Generate an AI draft | `AI_DRAFT` |
| Counselor | Accept, acknowledge or dismiss a case | `CASE_ACCEPTED`, `CASE_ACKNOWLEDGED`, `CASE_DISMISSED` |
| Counselor | Change priority manually | `PRIORITY_CHANGE` |
| Counselor | Add context the counselor holds (can recalculate and downgrade) | `CONTEXT_ADDED` |
| Counselor | Add a staff-only case note | `CASE_NOTE` |
| Counselor | Merge cases; attach a teacher flag to a case | `CASE_MERGED`, `FLAG_ATTACHED` |
| Counselor | Reassign a case to another counselor | `CASE_REASSIGNED` |
| Counselor | Close a case with an outcome | `CASE_CLOSED` |
| Counselor | Escalate to safeguarding, with required reason | `ESCALATED_SAFEGUARDING` |
| Counselor | Log parent contact; schedule or record a meeting | `PARENT_CONTACT`, `MEETING_SCHEDULED`, `MEETING_RECORDED` |
| Counselor | Bulk acknowledge; bulk assign | (no dedicated event today) |
| Counselor | Save and version thresholds | `THRESHOLD_SAVED` |
| Counselor | Ask the co-pilot | `COPILOT_QUERY` |
| Counselor | Open a student file | `FILE_ACCESS` (seeded only; not written on real access today) |
| Counselor (coordinator) | Record the selection review conversation; approve; return with a note | `SUBJECT_REVIEW`, `SUBJECTS_APPROVED`, `SUBJECTS_RETURNED` |
| Counselor (coordinator) | Nudge a student about CAS | `CAS_NUDGE` |
| Counselor (coordinator) | Assign an Extended Essay supervisor, including over the capacity guide | `EE_ASSIGNED` |
| Counselor | Approve or send back a student's pathway proposals | `PATHWAY_APPROVED`, `PATHWAY_SENT_BACK` |
| Teacher | Log a concern, positive note or context, with tags | `TEACHER_FLAG` (seed data also uses `CONCERN_SUBMIT`) |
| Teacher | Answer the level question on a subject selection | `SUBJECT_SIGNOFF` |
| Teacher | Accept supervision; ask for a sharper question; pass to a colleague | `EE_SUPERVISOR`, `EE_REFINE`, `EE_PASSED` |
| Teacher | Record an Extended Essay reflection session | `EE_REFLECTION` |
| Student | Complete or skip onboarding; converse in discovery; submit chosen pathways | `DISCOVERY_SUBMITTED` |
| Student | Build and submit an IB subject selection; book a review slot | `SUBJECTS_SENT` |
| Student | Log a CAS activity; write a CAS reflection; join an opportunity | `CAS_ENTRY`, `CAS_REFLECTION` |
| Student | Propose an Extended Essay | `EE_PROPOSED` |
| Student | Submit a personal statement for review | `PS_SUBMITTED` |
| Student | Complete a roadmap milestone (XP) | (none) |
| Student | Request a mentor session | (none) |
| Parent | Send a message; request a meeting with topic, slot and note | `MEETING_REQUEST` |
| Mentor | Accept or decline a session request; keep mentee notes | (none) |

Two gaps to note. The audit log today records changes but almost never records **access**, and reading a child's welfare file is itself an auditable act. Several actions write no event at all.

---

## 10. Incumbent systems at the pilot school

| System at ACS | What it holds | What CAROS overlaps |
|---|---|---|
| Veracross | SIS: enrolment, grades, attendance, likely behaviour, timetable, parent contacts | Nothing; it is the primary data source |
| ManageBac | IB Diploma: CAS, Extended Essay, likely subject records | The whole IB module (selection, CAS, Extended Essay) |
| Maia Learning | University and career readiness: lists, applications, documents, likely recommendation letters | University journey, deadline radar, application pack, letter engine, offers |
| Google Classroom | Assignments and coursework activity | A potential source for the engagement domain |

What exactly ACS uses ManageBac and Maia for is unconfirmed; the questions are in `ACS-IT-QUESTIONS.md`. The ground no incumbent covers is the signal engine, the triage queue, the evidence chain, the 360° file and the teacher concern loop. That is the differentiator, and it must be excellent regardless of what is integrated.

---

## 11. Known contradictions, gaps and tensions

These are real problems in the current design or the decisions. Your plan must resolve the ones in its scope, not work around them.

1. **Batch versus immediate.** Decided: overnight batch. The architecture page's "never in a nightly batch" copy is wrong. Teacher concerns do arrive live; whether they should trigger evaluation immediately is worth arguing.
2. **Reporting targets are not measurements.** To ever turn them into real numbers, the system must emit events from day one for time from signal to counselor aware, time to first review, alert accept and dismiss rates, follow-up completion, and recovery after intervention.
3. **Admission probabilities are unsourced.** Every university target carries a probability (`t.p`, e.g. 41%, 67%) rendered on the case file, the 360° file and the student targets table (`index.html:2390`, `:2822`, `:8797`). None traces to anything. Under the trust spine, a number with no source cannot ship. Either the backend computes something honest and sourced, or reach/match/safety classification stands alone and the percentage comes off the screen. (`PRODUCT.md` still describes an older fabricated `stuProb()` function; that function is gone, but this is the same problem in a new place.)
4. **Undefined engine outputs.** The prototype displays a signal strength (0 to 100), a "confidence 86%", a "3.1σ" deviation and signed evidence weights. None of these has a definition. The engine specification must define every number it produces or remove it.
5. **Threshold versioning and point-in-time explainability** are promised in the UI and constrain the schema: each signal must record the configuration version and an evidence snapshot it was produced under.
6. **Cold start.** Grade 9 entrants, mid-year transfers and new subjects have no personal baseline. A baseline-deviation engine must say what it does until one exists, without falling back to cohort comparison.
7. **Contextual suppression** (exam periods, authorised absence, subject change) needs calendar data and absence reason codes the plan must source.
8. **The engagement domain is partly self-referential and privacy-sensitive.** Today it measures logins to CAROS itself ("no login for 21 days"). Measuring a minor's platform activity to infer wellbeing needs justification, disclosure, and possibly a better source.
9. **UAE residency versus AI.** Data at rest must stay in the UAE, but the AI features send student information to a model. Where that inference runs, whether any UAE-region option exists for the chosen model and provider, what data retention terms apply (some models require 30-day retention and are not available under zero data retention), and how data is minimised or pseudonymised before it leaves, is a first-order design question, not a detail. It may also need ACS's and counsel's explicit sign-off.
10. **Mentors are outside the school's identity system.** They are alumni volunteers without school Google accounts, adults in contact with minors, and need an identity path, a verification step and safeguarding controls that the SSO decision does not cover.
11. **Counselor cover and handover.** Four HS counselors split the school. Absence cover and case handover need either shared visibility or a logged break-glass path. Not yet decided.
12. **Parent to student linkage.** A parent can have several children, possibly at different grades. The prototype keys family data by grade because of its demo switcher. Linkage must come from the SIS contacts, and a magic link must be bound to a verified relationship.
13. **Parents get no email in v1.** The parent portal then only works for parents who remember to open it, which `PRODUCT.md` names as the failure mode. "Parent email drafts" as an AI feature therefore produces drafts with no delivery channel. The plan must say where those drafts go.
14. **Student disclosures.** The discovery chat and personal statement tools accept free text from minors. A student may disclose something that is a safeguarding matter. The system must detect and route that to a human, and the model must never attempt to counsel.
15. **Prompt injection path.** Students and teachers write free text that a counselor-facing model later reads (co-pilot, briefs). That is an injection surface into the most privileged AI feature.
16. **Demonstration data under a real name.** A tenant is either synthetic or real, never both. The marker appears whenever a real school's name sits over synthetic data and never over real data.
17. **Letter engine claim.** The ACS deck quotes 190 counselor hours returned per term from letter drafting. Generation is deferred, so the claim is ahead of the build.
18. **Demo apparatus is not product.** The role switcher, grade preview and track preview exist for demos. Real users have one role (staff may have several), and grade comes from the SIS.

---

## 12. Rules for every pass

1. **Plan on the decisions in section 3; never touch the invariants in section 4.** Challenge openly, as described there.
2. **Evidence standard.** Where you rely on research, regulation, pricing or a vendor's capability, cite a source you can name precisely (author, title, year, or the exact regulation and article, or the vendor documentation page). If you believe something but cannot source it, label it an assumption. Never invent a citation. This product's rules forbid fabricated benchmarks, and a fabricated paper in the plan is the same failure. If you have web search, verify current facts (cloud region availability, model pricing, API capabilities, regulatory status) rather than relying on memory.
3. **Separate what is decided from what is open.** End with a list of open decisions, each with the options, your recommendation, and who has to decide (Davide, ACS, counsel, a counselor).
4. **Every unknown about the school becomes a question.** Add it to a section titled "Questions for ACS" at the end of your output, in the style of `ACS-IT-QUESTIONS.md`.
5. **Write for execution.** The reader is a builder working with a coding agent across many sessions, and teammates working in parallel. Prefer concrete schemas, interfaces, state machines and acceptance criteria to prose about principles.
6. **Be honest about uncertainty and cost.** Where something cannot be validated without real school data, say so and say what would validate it.
7. **Save your output** to `backend-plan/out/` under the filename your pass prompt gives.

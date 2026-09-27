# CAROS implementation roadmap

**Status:** synthesis of the backend design passes, not a replacement for them.  
**Planning baseline:** backend plan revised 24 September 2026. The April 2027 target and all session estimates are assumptions; re-plan at the stated checkpoints.  
**Purpose:** give the team an execution view of the existing design, its dependencies, and the conditions for using real student data.

## Product outcome

Build a multi-school counseling platform that can safely ingest school records, produce explainable signals against each student's own history, and support human-owned interventions. The first production slice is the counselor morning workflow plus teacher referrals and safeguarding escalation. Parent/student university workflows, the Diploma module, AI, and broader integrations follow behind separate readiness gates.

The backend plan is much more than a server behind the prototype. It replaces the single-file demo with a typed monorepo, a tenant-isolated data platform, an import pipeline, a deterministic signal engine, role-specific apps, and controlled background jobs. The prototype remains the source of interaction and domain examples; it is not the production architecture or a source of real data.

## Delivery sequence

| Stage | Scope and exit evidence | Dependency / gate |
|---|---|---|
| **0. Resolve immediate blockers** | Confirm the infrastructure, database, RPC and test-tool choices listed as O-decisions; agree frozen spec copies and demo policy. Start the ACS, counsel, IT and safeguarding questions that block later work. Record owners and answers in the decisions log. | These activities run alongside coding. Legal and school answers are external dependencies; unanswered questions must remain explicit blockers. |
| **B0 · Foundations** | Monorepo/toolchain, CI, Azure UAE North staging, database migrations and roles, tenant context, authorization matrix and RLS, audit/event primitives, synthetic ACS and second-school tenants, UI shell, health checks, runbooks. Prove isolation with positive and negative RLS/auth tests on both tenants. | **G-CI:** each PR runs the tenant-isolation suite for both tenants. This is the foundation for every feature; do not build product screens on unproven authorization. |
| **B1 · Facts and identity** | Import source files through the same pipeline intended for school data; normalize people, rosters, calendars, grades and attendance; mapping profiles, identity resolution, dry-run/diff/approval/rollback; staff identity and sessions; support access grants. Validate against adversarial Veracross-shaped and iSAMS-shaped fixture packs. | Depends on B0. Real imports remain prohibited until the tenant is deliberately moved to `shadow` or `live` and its onboarding checks pass. |
| **B2 · Engine and sweep** | Implement the signal engine as a pure, deterministic, versioned package. Add personal baselines, domain rules, cold-start behavior, contextual handling, case lifecycle, shadow evaluations, nightly jobs, retries/watchdogs, and counselor judgement logging. Reproduce expected cases from the generated rules for both synthetic schools. | Depends on stable canonical facts and engine decisions from counselors. **G-SHADOW:** deterministic scenario/property suite passes and the scheduled sweep completes seven consecutive staging nights. Thresholds and go-live bars are recorded before observing shadow results. |
| **B3 · Counselor morning and safeguarding** | First deliver referrals, the safety route, escalation acknowledgement, audit/access history, notifications, and a counselor log while tiers remain hidden. Then port the caseload sheet, evidence-chain case file, command center, dimensions, and demo workflows for reveal and live operation. | Depends on B1/B2 and the safeguarding route being configured and rehearsed. **G-DEMO:** the end-to-end staging demo works across synthetic ACS and Wellesmere tenants. |
| **B4 · Pilot readiness** | Privacy notices and DPIA evidence, retention/SAR/restriction procedures, production deployment in UAE North, WAF, canary tenants, independent penetration test and retest, restore drills, incident/on-call practice, onboarding runbook, school-specific policy and consent records. | **G-REAL:** the checklist in security pass §9.13 is complete and signed off. Only then may the first real record enter the system. A date on the calendar does not waive this gate. |
| **Shadow pilot → G-LIVE** | Import at least 20 weeks of history where available. Run the production engine silently: counselors see no engine tiers, teacher concerns remain usable, and counselors log who they supported and why. Hold blinded review sessions at weeks 4 and 8, compare against pre-registered criteria, inspect false positives/misses, and publish a decision record. | **G-LIVE:** pooled, pre-registered performance criteria are met over at least 40 blindly judged cases, with counselor and safeguarding-lead acceptance. Until then, the engine does not drive visible triage. |
| **B5 · Application season** | Student and parent records, guardian activation and relationship restrictions, messages/meetings, university requirements, deadlines, offers, documents, statements and the lexicon-only safety screen. Keep deterministic admissions facts source-linked. | After G-LIVE; before the school's relevant application deadlines. Parent/student privacy rules and notification inventory must be approved. |
| **B6 · Diploma** | IB subject selection and its rule gates, teacher/coordinator sign-off, CAS and coordinator oversight, Extended Essay proposals/supervision/reflections. ManageBac remains the system of record where used; CAROS mirrors the agreed data. | After G-LIVE; schedule around the selection round. The subject-selection meeting record is enforced in domain/database transitions, not just by disabling a button. |
| **B7 · AI, feature by feature** | Build the pseudonymising gateway, allowlisted/quarantined reader, schemas, output validators, leak scanner, prompt/model registry, cost limits, eval harness and failure behavior. Enable each approved feature independently, starting with lower-risk counselor assistance and proceeding only after its measured acceptance bar. | **G-AI per feature:** G-LIVE, zero-data-retention/provider terms, transfer/legal basis, ADEK consent where required, school written acceptance, and passing deterministic + judged + school-labelled evals. No model makes a tier, safeguarding decision, approval, or unsourced factual claim. |
| **B8 · Discovery, mentors, reporting** | Student discovery and counselor approval loop, student-only XP, vetted mentor access with in-platform messaging and in-person sessions, and per-tenant reporting aggregates. | After core workflows and safeguarding controls are established. Apply small-cell suppression and keep counselor, parent, teacher and mentor surfaces ungamified. |
| **B9 · Connectors and scale** | Add Veracross, ManageBac and Classroom connectors in the order ACS confirms; add iSAMS and a second real school; improve school onboarding and scale/operations. | Only after the import contract is proven with fixtures and the first-school operating model is stable. Tenant-specific behavior belongs in profiles/configuration, not adapter conditionals. |

## Critical path to the first real record

The first real record depends on **B0 → B1 → B2 → the pre-G-REAL portion of B3 → B4 → G-REAL**. The plan targets the first fortnight of ACS's spring term in 2027, assumed to begin 5 April. Its own capacity estimate is about 139 build sessions plus roughly 50 reviews, with a narrow margin for a solo builder. The fallback is the first fortnight of the 2027–28 year (August 2027).

The calendar checkpoints are decision points, not ceremonial status reviews:

- **23 October 2026:** measure actual build rate/rework; B0 should be done or within four sessions; counsel engaged; urgent ACS questions sent/answered or chased. Below six sessions per week means communicate the August fallback.
- **17 December 2026:** B1 complete, B2 engine scenarios green, penetration test booked, and the key school data/calendar/security answers received. If any are missing, move the target to August.
- **15 February 2027:** G-REAL scope code-complete, production and canary running, pen test underway, and any required ADEK request not refused. If not, move to August.

The 2026–27 build deliberately does not include full counselor UX before first data, application and Diploma modules during shadow, or AI before G-LIVE. The plan defers these to preserve the non-negotiable privacy, authorization, engine-validation, and safeguarding work. Shadow mode itself is expected to continue into the 2027–28 year.

## Cross-cutting rules for implementation

- **One data path per operation:** UI calls domain functions; domain functions enforce state transitions and authorization; database RLS remains a second enforcement layer. Do not let screens issue privileged SQL or implement their own permission checks.
- **Tenant isolation first:** tenant identity is established before data access; separate database identities are used for web, worker, support, migration and scheduled jobs. Every cross-tenant job is constrained to explicit school IDs and tested adversarially.
- **Evidence and interpretation stay separate:** retain source facts and versioned derived snapshots, so a historical signal can be reconstructed with the rule/configuration versions that produced it.
- **Rules own consequential outcomes:** the engine and domain rules determine tiers and workflow eligibility. AI can write within a validated evidence envelope, and every user-facing factual statement needs provenance.
- **Human action is explicit:** escalation, approvals, reassignment, parent activation and other consequential changes are authorized domain transitions with idempotency, audit records and appropriate confirmation/attribution.
- **Configuration carries school variation:** calendars, terminology, programme structure, source mappings, safeguarding routes and retention settings are tenant data. Core tier meaning and product invariants do not vary by school.
- **Synthetic fixtures are a first-class test environment:** every change must preserve both synthetic tenants. No real data enters local development, CI, coding-agent context, or ordinary support tooling.
- **A gate is a verifiable evidence bundle:** each gate needs named approvers, concrete artifacts, and recorded exceptions. A missing external answer cannot be converted into an assumed approval.

## Highest-risk dependencies to track

1. **ACS and counsel decisions:** calendar and delivery cadence/history export; school identity/Google configuration; DPA, legal basis, notices, retention, parental activation; safeguarding categories/routes/SLA; IT review and pen-test scope; ADEK Policy 7.1.3.a interpretation and consent. The merged question list is [ACS-IT-QUESTIONS.md](ACS-IT-QUESTIONS.md); the legal analysis and exact gates are in pass 4 and pass 6.
2. **Data and engine quality:** the engine needs sufficient history and counselor-labeled judgments. Lack of dated intervention history weakens lead-time measurement; low event counts can extend shadow mode. Keep the engine silent until the pre-registered bar is met.
3. **Solo capacity:** estimates assume eight build sessions and four review sessions per week, with 20% rework. Reforecast from actual throughput at each checkpoint and take only the documented cuts; do not cut security, RLS, engine scenarios, escalation, or required reviews.
4. **Residency and recovery:** student data stays in UAE regions. The cross-country cold-copy choice is unresolved and requires counsel/school/ADEK input; verify that the chosen backup can actually be restored under the agreed failure scenario.
5. **AI approval and data flow:** ZDR alone does not settle transfer basis, permitted fields, provider retention, consent, or feature acceptance. Gate each feature separately and preserve the deterministic product in degraded mode.
6. **Plan/code drift:** the backend plan is a design, not a build, and its source prototype was frozen at commit `fb28217`. Keep the spec copies pinned, map each ported behavior to current code, and record decisions when the code or school facts change.

## First execution moves

1. Start B0 with its tenancy spine and CI order; complete the two-tenant RLS/auth harness before product domain implementation.
2. In parallel, assign an owner and due date to each “ask now” item in the backend-plan index. Engage counsel on C25 early because its answer can move ADEK consent onto the G-REAL critical path.
3. Use synthetic fixtures to build and validate the full import path before requesting real historical data. Resolve the weekly-vs-termly source cadence with ACS before finalizing the import job schedule.
4. Implement the signal engine as a pure package against synthetic scenarios, then run the same engine in staging shadow mode. Do not build tier-driven counselor screens against a separate mock engine.
5. Keep an always-current `docs/PLAN.md` with only: next task, blocked tasks, gate status, decision links, and checkpoint forecast. The detailed task breakdown and acceptance criteria remain in [pass 6](out/06-build-sequence.md).

## Source of detail

This roadmap summarizes, and must defer to, the detailed specifications: [architecture and data model](out/01-architecture-and-data-model.md), [ingest and integrations](out/02-ingest-and-integrations.md), [signal engine](out/03-signal-engine.md), [security and privacy](out/04-security-privacy-compliance.md), [AI design](out/05-ai-design.md), and [build sequence, tests, gates, and open decisions](out/06-build-sequence.md). Pass 7's adversarial review and pass 8's changelog explain why decisions changed. The [backend-plan index](out/README.md) is the current status snapshot.

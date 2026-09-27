# CAROS backend · immediate next steps

**Purpose:** turn the backend plan's “start B0 / this week” notes into an execution checklist.  
**Baseline:** plan revision 2026-09-24; planned start week 2026-09-28. Reconfirm dates and availability before treating them as commitments.  
**Status at baseline:** B0 is marked not started. This file records proposed work; unchecked items are not evidence that an external action has happened.

This is the short-range companion to [ROADMAP.md](ROADMAP.md). The detailed task briefs, requirements and acceptance criteria remain in [build sequence §1](out/06-build-sequence.md). Use `docs/PLAN.md` in the backend implementation repository as the live status board once B0.14 creates it.

## First working session

### 1. Establish the decision and work log

- [ ] Create the implementation repository/workspace from the approved backend plan and make `main` the integration branch.
- [ ] Create `docs/PLAN.md` with: current phase/task, next task, blocked tasks, gate checklist, open decisions, external dependencies, checkpoint forecast, and session notes.
- [ ] Pin the exact planning inputs in `docs/spec/`: `PRODUCT.md`, `CONTEXT.md`, passes 1–8, and their source commit/revision. Treat those copies as the build contract; record changes through decision records.
- [ ] Add a decision log and transcribe the currently open O-decisions with owner, required-by gate, recommendation, status, and link to evidence. Do not reopen decisions the index marks closed.
- [ ] Confirm scope boundary for the first pilot: ACS tenant plus synthetic Wellesmere tenant, counselor/teacher safety slice first, and no real student data until G-REAL.

**Done when:** a new contributor can identify the canonical specs, current task, open decisions, and real-data gate without relying on chat history.

### 2. Close the B0 choices that affect the scaffold

The plan records recommendations, but the following are still listed as decisions. Record an explicit decision before the relevant dependency is baked into the repository or cloud resources:

| Decision | Plan recommendation | Resolve before |
|---|---|---|
| O1 · IaC tool | Terraform/OpenTofu with `azurerm` | Terraform module and state |
| O2 · RPC layer | tRPC; add an OpenAPI connector surface only when a non-TypeScript caller exists | API/app scaffold |
| O3 · PostgreSQL major | PostgreSQL 17 at pilot; revisit 18 after extension compatibility | First database migration |
| O4 · Test runner | Vitest 5, with Playwright for browser flows | Workspace scaffold |
| O5 · Second synthetic school | Wellesmere, KHDA, after directory/name check; status says checked | Synthetic seed is made visible |
| O6 · GitHub plan | GitHub Team for private-repo rulesets and environments | Ruleset and deployment controls |
| O8 · XLSX import | Accept XLSX at pilot; parse cells as text | Import parser contract |
| O9 · Initial data delivery | Studio upload for first four weeks; use Veracross Data Export Package over allowlisted SFTP if ACS licenses it; otherwise the approved Blob SFTP/container fallback | ACS import rehearsal and endpoint provisioning |
| O10 · Withdrawal grace | 14 days | Roster lifecycle implementation |
| O13 · Frozen specs | Commit copies with source commit hash | First implementation PR |
| O14 · Production maintenance window | Custom Saturday 09:00 local | Production operations setup |
| O97 · Fictional coordinator | Use the checked fictional name; never seed a real ACS staff member | Seed and demo tenant |
| O104 · Model accounts/limits | Opus build under ZDR organisation; separate Fable review account; verify capacity for the planned cadence | First coding-agent session and B0.16 |
| O105 · Prototype/Product edits | The prototype is frozen; separately decide whether to correct the fictional coordinator and Extended Essay guide wording in source docs | Any edit outside `backend-plan/` |

O103 is deliberately not decided by discussion: B0.16's bake-off supplies the evidence and decision record. O15–O106 that block G-REAL or later gates do not block the B0 scaffold, but must be tracked from day one in the external dependency list.

**Done when:** each row has a dated decision record, a named owner, and any unresolved choice has a bounded fallback. No cloud or schema choice is silently inferred from a recommendation.

### 3. Start external work in parallel

Assign named people and due dates in the live plan. These are requests and preparation tasks; completion requires a written answer or a traceable artifact.

- [ ] **ACS consent for use of its name/crest (Q49):** request written consent that explicitly covers counselor training and demonstrations to other schools. If permission is unavailable, record the unbranded-demo decision and remove ACS branding from the new demo tenant before it is shown.
- [ ] **ADEK Policy 7.1.3.a (Q149, Q150):** ask ACS how it handled this with existing vendors and who submits an ADEK request; engage counsel immediately on C25, whether in-country Microsoft hosting counts as “sharing.” This answer can make ADEK consent a G-REAL blocker.
- [ ] **School calendar (Q165):** confirm term dates, Ramadan/Eid hours, working week, holidays, freeze windows and timezone. Recalculate T and every back-scheduled date from ACS's answer.
- [ ] **DPA/legal basis (Q30, Q31, Q32, Q109):** obtain ACS's DPA template/signatory and data-protection contact; ask how parent permission for vendor processing is recorded. Ask counsel to begin the DPA and advise on minors' legal basis and notices.
- [ ] **IT review (Q36, Q113):** get the questionnaire, evidence expectations, approver and sign-off date. Start a pen-test shortlist (CREST-accredited or DESC Cyber Force listed) and obtain scope/lead-time estimates; do not book a date as confirmed until accepted.
- [ ] **Data export (Q2a, Q70, Q73):** confirm weekly-pack contents and source delivery mechanism, Veracross licensing, XLSX/CSV shapes, SFTP/Blob constraints, update/correction semantics and source owner.
- [ ] **History (Q83, Q100):** determine which historical weeks and intervention records exist, how they can be supplied under the DPA, and how records without date of birth are treated. Do not request or import real files before the relevant legal gate.
- [ ] **Google identity (Q19, Q141):** request Workspace app approval, edition and required scopes; identify the delegated-reader administrator role and who can prove the domain.
- [ ] **Safeguarding and operations:** identify the CPO/delegate, referral categories/routes, acknowledgement SLA and approved contact channel; obtain escalation contacts and school incident-tabletop participants.
- [ ] **Other week-one setup:** submit UAE Central access request; confirm Azure subscriptions for staging, production and restore drills plus PIM; open the ZDR build organization and verify limits; open the separate Fable review account; create the Google Cloud project and submit brand verification; start DPIA outline/DPO search; request cyber-insurance quote; verify Wellesmere name/regulator against the KHDA directory.

**Done when:** each item is either evidenced as complete, has a named responder and next follow-up date, or is explicitly marked blocked with the gate/date it threatens. Keep legal questions with counsel and operational facts with ACS IT; do not convert either into engineering assumptions.

## B0 build order

Run one task per branch/PR as the source plan specifies. Every task has a brief and acceptance criteria; update `docs/PLAN.md` after each merge. The order below preserves dependencies while allowing infrastructure and external setup to overlap.

| Order | Task | Immediate output and completion check |
|---:|---|---|
| 1 | **B0.1 Workspace scaffold** | All apps/packages exist; pinned pnpm/Node/tooling; strict TypeScript, formatting, dependency boundaries, Vitest, Playwright, Turborepo. Fresh clone installs and `pnpm ci` passes; a deliberate forbidden import fails. |
| 2 | **B0.2 CI skeleton** | PR pipeline with PostgreSQL service and required checks. A deliberately failing check prevents merge. |
| 3 | **B0.3 Repository controls** | GitHub Team, solo-mode ruleset, staging/production environments, production required reviewer, no force-push, replacement guard, repository hooks. Verify guardrails with controlled negative cases; no production credentials on build machines. |
| 4 | **B0.4 Azure staging** | Terraform/OpenTofu module and staging applied in UAE North. CMK and geo-redundant backup are required at creation; configure storage, internal Container Apps, Key Vault, logs, registry and action group. `/health` works; IaC plan is clean; record UAE Central request. |
| 5 | **B0.5 Roles and spine migrations** | PostgreSQL roles/schemas/spine tables, registry and triggers. Apply migrations from an empty database in CI; verify all school-owned tables are registered and privilege conventions hold. |
| 6 | **B0.6 Tenant DB context and migrator** | `withTenant()` sets the scoped role and tenant context; pool is not exported; migration job handles transactional and explicitly non-transactional migrations. No-context queries see zero tenant rows; staging migration runs before revision swap. |
| 7 | **B0.10 Contracts and matrix source** | Shared event/audit/domain contracts, engine input/output types, connector types and `authz/matrix.json`. All packages compile against the contracts. This can be prepared alongside B0.5–B0.6, but land before engine work. |
| 8 | **B0.7 Authorization mechanism** | `auth.allowed()`, `auth.protect()`, scope predicates, capability matrix generation, narrowing rules, and notification enqueue. Each permission qualifier has an enforcing mechanism and negative fixture. Complete the B0.16 comparison before accepting the final implementation. |
| 9 | **B0.8 RLS/authz harness** | Generate tests from permission data; test positive and negative reads/writes, role separation, job isolation, no-widening rules, both tenants. Every permission row has fixtures; suite runs in CI under five minutes. This is the G-CI security proof. |
| 10 | **B0.9 Audit/event primitives** | Tier-allowlisted `audit.record()`/`events.emit()`, per-school audit chain, schema-validated details and partition maintenance. Reject unknown actions/fields; verify chain over 10,000 seeded entries. |
| 11 | **B0.11 Tenant CLI and synthetic seeds** | Idempotent CLI creates ACS and Wellesmere demo tenants plus CI time-shift tenant and fictional personas/roles. Refuse to seed a real tenant; pass no-real-data scan; ACS marker cannot be disabled. |
| 12 | **B0.12 UI system and shell** | Port design tokens/primitives, role navigation and responsive shell. Render visual check page for both tenants; demonstration marker follows school record and cannot be separated from ACS letterhead; check reduced motion and 375px. |
| 13 | **B0.13 Worker bootstrap** | Worker identity, pg-boss job store, validated ID-only payloads, heartbeat, partition job and safe structured logging. Confirm heartbeat on staging and log scanner finds no seeded personal names. |
| 14 | **B0.14 Operational docs** | `CLAUDE.md`, live `docs/PLAN.md`, DR records, frozen specs, runbook skeleton, doc verification and generated-doc checks. Deliberately invalid doc reference fails CI. |
| Parallel | **B0.15 Non-code checklist** | Track every external/infrastructure item above with due dates and evidence in `docs/PLAN.md`. No checkbox is closed by verbal assumption. |
| After B0.7 brief | **B0.16 Model bake-off** | Give identical authorization task and tests to Opus and Fable in separate worktrees using synthetic-only content; blind cross-review; judge tests first; record per-category writer decision. Winning accepted implementation becomes B0.7. |

The exact scope may require splitting these into multiple small sessions, but keep each acceptance criterion intact. The plan estimates 22 sessions plus reviews for B0; compare actual throughput with the April critical path at CP1.

## First two-week rhythm

This is a practical ordering of the plan, not a promise that external responders will meet these dates.

### Days 1–2

- Set up the status/decision log and pin source specifications.
- Resolve O1–O6, O8, O10, O13, O14 and O104 to the point that scaffold work can start; do not wait on unrelated G-REAL legal questions to create the workspace.
- Start B0.1 and B0.2; make CI the path every later change follows.
- Send/assign the ACS and counsel asks; submit the UAE Central request and open security/provider accounts.

### Days 3–5

- Complete repository controls (B0.3) and begin the staging IaC task (B0.4).
- Define B0.5 migration conventions and implement the role/schema foundation only after O3 is recorded.
- Confirm the database migration job and tenant context design before any domain table or endpoint is written.
- Hold a short review of the first week: session throughput, blocked external answers, CI reliability, and whether the planned April pace remains credible.

### Week 2

- Land role/spine migration and tenant context in small reviewed slices (B0.5–B0.6).
- Define contracts and permission matrix as source data (B0.10), then implement authorization and generated negative tests (B0.7–B0.8).
- Start audit/event primitives only after the database identity and caller tier are correctly established (B0.9).
- Seed the two synthetic tenants early enough that every new security test runs against both (B0.11).
- Update the checkpoint forecast with actual build/review capacity, not the plan's assumed session count.

## Stop conditions

Pause the affected work and record a blocker rather than making an assumption if:

- Tenant isolation or role-scope tests fail, or a permission qualifier lacks a negative test.
- Any real student or family data appears in a local workspace, CI artifact, agent prompt, log, or synthetic seed.
- A cloud resource cannot meet the UAE location, CMK, backup, or recovery requirement as designed.
- Safeguarding routing, owner, acknowledgement, or audit behavior is not confirmed and testable.
- The accepted ACS export cannot support the agreed canonical facts/cadence, or the source-to-student identity match is ambiguous.
- The calendar/capacity checkpoints indicate the target cannot be met without cutting a non-negotiable security, privacy, engine, or safeguarding requirement.
- A legal or school approval required for a gate is missing. This blocks the relevant gate; it is not a reason to silently turn on the feature.

## Decisions and evidence to keep current

For each task, attach the PR, CI run, review verdict and relevant decision record. For each external gate, attach the signed/approved artifact or the exact response and date. Keep the live board concise; this document is the execution checklist, [ROADMAP.md](ROADMAP.md) is the phase overview, and [pass 6](out/06-build-sequence.md) remains the specification of record for detailed scope.

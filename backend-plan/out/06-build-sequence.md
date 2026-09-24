# CAROS backend · Pass 6 · Build sequence

Written 2026-09-23 against `index.html` at commit `fb28217` (10,048 lines), `backend-plan/CONTEXT.md`, `PRODUCT.md`, `PHASES.md`, and the five earlier passes (`out/01` to `out/05`). Every tooling, platform and vendor claim that no earlier pass had already verified was checked on 2026-09-23 against a named page and is cited where it is made and again under Sources; claims that could not be checked are labelled as assumptions. Session counts and calendar figures in this pass are **planning assumptions for one builder with a coding agent and two to three part-time teammates**, not commitments, and are marked so where they appear.

This pass turns the five earlier passes into an order of work. It does not redesign anything they settled; where it found them disagreeing with each other it says so (§12) and plans on the later pass.

## 0. Read this first

### 0.1 Departures from section 3 of CONTEXT.md

**None.** Every decision in section 3 is planned on. Three things this pass does are narrowings a reader must know before the phases make sense:

1. **The complete schema is applied in slices, and the slices are set here.** Pass 1 designed 135 tables in 19 schemas and its §5.6 says a module's migrations land in the phase that first serves it. Passes 2 to 5 numbered their schema deltas D1 to D75 "in migration order" *within each pass*. Those numbers are design identifiers, not the order the migrations are applied: pass 4's `auth.school_domain` (D37) is needed at the first sign-in, long before pass 3's engine tables (D17 to D32) exist. §1.12 gives the applied order, phase by phase, and every D-number lands exactly once.
2. **Pass 1's 83 default permission rows are never applied.** Pass 4 §3.6 replaced them and its D36 deletes them. The first migration that creates `auth.role_permission` seeds pass 4's matrix directly, so no screen is ever built against a matrix that is later replaced.
3. **"The thin slice" is agreed in content and split into four phases** (B0 to B3, §1.13), because as one phase it is about a hundred agent sessions with no checkable "done" in the middle, because the engine is parallel work by a different person and a different model, and because pass 1's narrative seed layer means the first demoable build does not have to wait for the engine.

### 0.2 Where the code and the documents disagree

The code wins. This pass read the router, the navigation and the write-side handlers of the prototype to fix the port checklist (§6.2), and found these differences with CONTEXT.md §8 and §9:

| Topic | Document says | `index.html` does | Consequence for the build |
|---|---|---|---|
| Counselor views (CONTEXT §8) | `command` and `si-cases` listed as two views ("command centre", "priority queue") | the router maps both to `vCommand` (`index.html:9010`, `:9011`), and `si-interventions` to `vWork` (`:9012`) | one screen with a filter, not two; the router's chain has 25 counselor route keys (plus the ten dimension keys and the open case or file), rendered by 21 distinct view functions, and the port counts screens, not keys |
| The caseload sheet (CONTEXT §8) | four views `cohort-schedule`, `cohort`, `cohort-all`, `today` | all four render `vSheet` (`:9003`, `:9007`) | one screen with four modes |
| The dimension pages | "the ten dimension pages (`DIMS`)" | `DIMS[S.cv]` dispatches to one `vDim(S.cv)` (`:9002`, `:3263`) | one screen component, ten rule sets from `config.rule_set_version 'dimensions'` (pass 3 §9.3) |
| Student and parent navigation (CONTEXT §6) | "grade-conditional (`roleNav`, `index.html:1898`)" | confirmed at `:1898` to `:1947`; the student list has 11 possible entries across grades and tracks, the parent list 8; Grade 10's `stuclass` entry is the selection form itself, not a record | the port carries the grade and track conditions as data on the tenant (`sis.year_group.stage`, `sis.programme.family`), never as literal grade numbers (pass 1 DR-8 second-school checklist) |
| Audit events written (CONTEXT §9) | the mutation inventory lists an event per action | `logAudit(...)` is called with 33 distinct action keys; three of them (`PRIORITY_CHANGE`, `CASE_REASSIGNED`, `CASE_CLOSED`) from more than one handler; several actions in the inventory write nothing (`FILE_ACCESS`, bulk actions, mentor actions, roadmap XP) | the port writes pass 1's 84-key taxonomy plus pass 4's additions through `audit.record()`, not the prototype's subset; every domain function names its action in its session brief |
| Route-states | not counted | `PHASES.md` P0 verified "all 98 route-states render without a console error" | 98 is the port's completeness count; the checklist in §6.2 is organised by those states |
| Write-side handlers (CONTEXT §9: `bind()` at `:9141`) | confirmed | 479 `data-*` attribute occurrences across roughly 100 distinct handler kinds | each write handler maps to one domain function (pass 1 DR-2's single path); the mapping table is the first artefact of each screen's port (§6.1) |
| Demo apparatus (CONTEXT §11.18) | role switcher, grade preview and track preview are not product | `roleBar()`, `S.previewGrade`, `gradeSwitcher()` (`:9090`) | not ported; the Next.js app has one acting role per session (pass 4 §2.4); the synthetic tenants carry real memberships for the demo personas instead |

### 0.3 What passes 1 to 5 handed to this pass

Pass 1 §7 asked for: the order in which §2's schemas are migrated (§1.12); the thin slice and its tables (§1.1 to §1.4); the RLS suite and the second-school checklist as week-one tests (B0, §5.4); the restore drill before real data (B4, §7.6); the Container Apps Job for migrations (§7.3); `docs/PLAN.md` and `CLAUDE.md` content (§3.2, §3.3); the UAE Central access request as a week-one task (B0). Pass 2 §13 asked for: the Studio's four screens in the thin slice (B1); the fixture packs as week-one tests (B1, §5.5); migrations D1 to D16 in its order (§1.12); the SFTP endpoint in Terraform (B4, open decision on Blob SFTP verified in the portal, §7.2); connector adapters after four green weeks (B9); the "four green weeks" gate before auto-approval (§1.11); the `expected_cadence` panel (B3). Pass 3 asked for: `packages/engine` as a pure library with the scenario suite as its acceptance test, built before any screen and before the narrative layer is retired (B2); the calibration script beside it (B2); D17 to D32 in order (§1.12); the alert rules and `/health/sweep` in the sweep's definition of done (B2, §7.4); the elicitation session before the first configuration version (§1.11); shadow mode as the pilot's first phase with the counselor log in the thin slice (B2, §1.11); the backtest as a gate when history exists (§1.11); Fable 5.1 for the statistics and the tiering rows, and a review by a different model (§4). Pass 4 asked for: the week-one items that cannot be retrofitted (B0); the §9.13 list as a phase gate (B4, §8); the Google Workspace and safeguarding-route onboarding checklists (§9); the RISC receiver early (B1); the DPA, DPO and notices as non-code deliverables (B4, §8); the penetration test and tabletop before the first real record (B4, §8); D33 to D60 (§1.12); the support console in the thin slice (B1); the `no-real-data` and log-scanner tests from the first commit (B0); the SFTP verification (§7.2); six runbooks (§7.7). Pass 5 asked for: the week-one non-code items (the ZDR conversation, the organisation and workspaces, the smoke test) (B0 and B7); the build order inside the AI phase (B7); D62 to D75 (§1.12); the eval runner as a CI gate from the first AI commit (B7, §5.6); labelling sessions before each feature's acceptance (§8); the Extended Essay guide decision before the IB module is built for a 2027 cohort (B6, §13); the cost script's home (`packages/ai/tooling/cost.py`, B7).

### 0.4 The build sequence on one page

Ten phases, each an integration milestone on `main` with a checkable "done". Four streams run inside them (§2). Four gates sit on the sequence, and none can be skipped.

| Phase | Name | What exists when it is done | Gate at exit |
|---|---|---|---|
| **B0** | Foundations | the repository, CI with both synthetic tenants, staging in UAE North with CMK and geo-redundant backup set at creation, the spine tables (core, auth, config, audit, events, privacy, doc, notify), `withTenant()`, `auth.protect()`, pass 4's matrix, the RLS suite, the tenant CLI, the plan file and `CLAUDE.md` | **G-CI**: every PR runs the RLS suite against both tenants |
| **B1** | Facts and identity | `packages/ingest` end to end, the Mapping Studio, both fixture packs imported through the real pipeline, Google sign-in for staff, sessions and step-up, the support console, the RISC receiver | fixtures.spec and roster-security green on both tenants |
| **B2** | Engine and sweep | `packages/engine` with S1 to S23 and the property tests, the sweep jobs, the two watchdogs and the alert rules, thresholds versioning with the what-if run, the counselor log and the shadow view | `engine-reproduces-seed` diff equals pass 3's expected list; a staging sweep completes on schedule for seven nights |
| **B3** | The counselor's morning | the caseload sheet, the case file with its evidence chain, the flags inbox, the teacher register and "what I've logged", meetings, the structured escalation with the reference-only email and acknowledgement, access logging and the audit screen, in-app notifications, the outbox | **G-DEMO**: Demo 1 on staging (§6.5) |
| **B4** | Pilot readiness | privacy tooling (notices, SAR pack, erasure with restore replay, restriction), production in UAE North, WAF, the pen test and its fixes, the review pack, the restore drills, on-call, the onboarding runbook and CLI, the elicitation session | **G-REAL**: pass 4 §9.13 complete; the first real record may move |
| **B5** | The application season | the university module (targets, applications, offers, documents, statements, the classification rule over sourced reference data, deadlines and nudges), the parent portal (activation, magic links, messages, meetings), the student record surfaces | Demo 2 |
| **B6** | The Diploma | IB subject selection with its two gates, the demand sheet, CAS, the Extended Essay with the 2027 guide decision made, the coordinator views | Demo 2 (with B5) |
| **B7** | AI | the gateway, pseudonymiser, validator and leak scanner; the registry and prompts; the quarantined reader and the safety screen; then the six features in pass 5 §9.6's order, each behind its eval bar and the school's written acceptance | **G-AI** per feature |
| **B8** | Discovery, mentors, reporting | the discovery flow in both modes with the approval gate, XP, the mentor path (vetting, passkeys, pairings, held messages), the reporting views over the event stream | Demo 3 |
| **B9** | Connectors, second school, scale | the Veracross, ManageBac and Classroom adapters in the order ACS's answers dictate, the iSAMS adapter, the second real school, the year-1 items | the second school onboarded with a human at six steps only (pass 2 §9) |

The **pilot overlay** (§1.11) runs across B4 to B7: onboarding (pass 2 §9 steps 1 to 15) as soon as G-REAL is passed, then six to eight weeks of shadow mode with teacher flags live and no visible tiers, then the reveal sessions, then **G-LIVE** (pass 3 §14.5's six criteria), then the AI features one at a time as the school accepts them. B5 and B6 land during shadow mode, so that the day the counselors go live the application season and the Diploma module are there too.

**Three demos.** Demo 1 (end of B3) is the first build a school can be shown that the prototype cannot match: real sign-in, the real engine over the twelve weekly ACS packs, an escalation that goes somewhere, and the same product running the British school. Demo 2 (end of B6) adds the family, the student and the Diploma. Demo 3 (end of B8) adds the AI features on synthetic data with their labels and evidence panels. §6.5 says exactly what each shows and what it does not.

**Streams.** Davide (spine, identity, signals domain, notify, audit, privacy, infrastructure, the worker); teammate A (ingest, record, the Studio); teammate B (the engine, thresholds, shadow tooling); teammate C (IB and university domains and their screens). Each module's screens are built by the module's owner against a shared UI kit; §2.5 says what collapses if fewer people are available.

---
## 1. The phases

### 1.0 Conventions

- **A phase is an integration milestone on `main`**, not a calendar block. It is done when its acceptance criteria are checked by someone other than the person who built the last piece, its tests are in CI, its `docs/PLAN.md` entry reads `complete <date> (commit …)`, and `CLAUDE.md` has been rewritten from the build (§3.6). Phases overlap: B2 starts in B0's second week; B5 and B6 run during the pilot's shadow period.
- **A task is one agent session**: two to four hours, one branch, one pull request, one owner, one model, a written brief (§3.1). The task tables below give each task's owner stream (D = Davide, A, B, C, per §2.1), its model (O = Opus 5.5, F = Fable 5.1) and effort, and a **Rev** column naming the model that must review it when it differs from the writer. Session counts per phase are planning assumptions.
- **Model lines** follow `PHASES.md`: `**Model:** … · **Why this model:** …`. The reservation rule for Fable 5.1 is in §4.2; the review rule in §4.3.
- **Migrations** are named `NNNN_<phase>_<subject>.sql` and applied in the order of §1.12. A D-number from passes 2 to 5 lands once, in the phase named there. A phase never creates a table nothing in that phase reads or tests (pass 1 §5.6).
- **"Both tenants"** always means the ACS and Wellesmere synthetic tenants (pass 1 DR-8). A screen or rule is not done until the Wellesmere checklist assertions for it pass.
- Line references are to `index.html` at `fb28217` and drift; the port checklist (§6.2) carries function names so it survives drift.

### 1.1 B0 · Foundations

**Status:** not started · **Depends on:** nothing · **Model:** Opus 5.5, high effort for the scaffold, CI, infrastructure and UI kit; **Fable 5.1, max effort** for the four tenancy pieces (roles and spine migration, `withTenant()` and the migrator, `auth.allowed()` and `auth.protect()`, the RLS harness) · **Reviewed by:** the other model on every Fable task and on the Terraform module
**Why this model:** most of B0 is scaffolding Opus 5.5 does quickly and well; the tenancy layer is written once, every later line trusts it, and a hole in it is invisible until a school reads another school's child.

**Scope.** The repository of pass 1 DR-3 with every package present (stubs where the phase does not fill them); the toolchain (pnpm 12, Turborepo 2.11, Node 24, TypeScript strict, Biome, `dependency-cruiser` with DR-3's import matrix, Vitest 5, Playwright, Drizzle 0.45 pinned with `drizzle-kit generate` and `drizzle-kit check`, pg-boss 12); the supply-chain settings of pass 4 §9.8 from the first commit (`minimumReleaseAge = 10080` for production dependencies, lifecycle-script allowlist, gitleaks, Renovate, Trivy, pinned Actions); the GitHub organisation on a **GitHub Team** plan, because rulesets, branch protections and deployment environments on a private repository need it ([about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets): rulesets are for "customers on GitHub Team and GitHub Enterprise plans"; [environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments): "Organizations with GitHub Team and users with GitHub Pro can configure environments for private repositories"); the ruleset, `CODEOWNERS` and the anti-overwrite checks of §2.4; CI (§5.8); the Terraform module of pass 1 DR-9 applied to **staging** in UAE North with the two creation-time settings that cannot be retrofitted made non-optional in the module: customer-managed keys on the server and the storage accounts (pass 4 §9.2) and geo-redundant backup (pass 1 DR-1); the UAE Central access request submitted; the Azure Monitor action group with email, SMS and voice to +971 numbers ([action groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups) lists country code 971 under both SMS and voice support; voice calls to the UAE come from a US number); GitHub Actions authenticating to Azure by OIDC federated credentials with no stored secret ([Azure Login with OIDC](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)); the **spine** of the schema (below); `withTenant()`, the migrator as a Container Apps Job, `auth.allowed()`, `auth.protect()`, `audit.record()`, `audit.chain()`, `events.emit()`, `core.ensure_month_partitions()`; pass 4's permission matrix seeded as the default rows; the RLS and authz harness; the tenant CLI (`tooling/tenant`, pass 2 §9 step 3) creating both synthetic `core.school` rows with modules, calendars, year groups, programmes, timetable periods and the demo personas' memberships; the UI kit ported from `DESIGN.md` into `packages/ui` (the three token layers, the tier marks `U C R M P`, the run cells, `tally`, `empty`, the letterhead from `core.school.brand`, the demonstration marker driven by `core.school.demonstration_marker`); the app shell with role navigation as data; tRPC mounted at `/api/trpc` with a health router; `/health` and `/health/sweep`; the worker with its heartbeat line and the partition job; `CLAUDE.md`, `docs/PLAN.md`, `docs/decisions/`, `docs/spec/` (frozen copies of `CONTEXT.md`, `PRODUCT.md` and `out/01` to `out/06` with their commit hash), the runbook skeleton, `.claude/rules/` and the hooks (§3.4); the documentation checks (§3.6).

**The spine (tables B0 creates).** `core.school`, `core.school_module` (with D10 and D60 keys documented), `core.person`, `core.staff_profile`, `core.meeting`; all nine `auth.*` tables with D33 (sensitivity), D34 (`export`), D35 (`mentor_coordinator`), D36 (the matrix and `auth.forbid_widening()`), D37 (`auth.school_domain`), D38 (no JIT), D39 (session columns), D44 (support grants); `config.rule_set_version` and `config.vocabulary` with D7 and D27's attribute schemas, D49's vocabularies, D8 `config.grade_scale`; `ref.source`, `ref.grade_scale`; `sis.academic_year`, `sis.term`, `sis.calendar_period`, `sis.school_day`, `sis.year_group`, `sis.programme`, `sis.timetable_period` (the tenant module's own); `doc.file` (D13 kinds); `notify.template` (D47 allowlists), `notify.outbox`, `notify.preference`, `notify.in_app`; `audit.action` (pass 1's 84 keys plus D9, D48, D71) and `audit.entry`; `events.name` (52 keys plus D9 and D28) and `events.event`; `privacy.retention_class` (pass 1's rows updated by D14 and D50, every number marked proposal), `privacy.table_registry`, `privacy.erasure_request`, `privacy.erasure_log`. Everything else lands in the phase that serves it (§1.12). Two things are hand-written SQL beside the generated files: the policies and the `SECURITY DEFINER` helpers owned by `caros_policy`, and the roles. One correction to pass 1 (flagged in §12): the DDL creates `caros_owner` as `NOLOGIN` while DR-4 has migrations run as it; B0 adds `caros_migrator LOGIN` (credential in Key Vault, used only by the migration job) which runs `SET ROLE caros_owner` as its first statement and sets `app.actor_kind = 'migration'`.

**Tasks (planning estimate: 15 sessions plus reviews; two to three weeks with two people).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B0.1 | Workspace scaffold: every package and app of DR-3, tsconfig, Biome, `dependency-cruiser` rules, Vitest, Playwright, `turbo.json`; `pnpm ci` runs a trivial test in every package | D | O high | | a fresh clone runs `pnpm i && pnpm ci` green; the boundary check fails a deliberately bad import in a test |
| B0.2 | `ci.yml` with the jobs of §5.8 and a PostgreSQL 17 service container; required checks named in the ruleset | D | O high | | a PR that breaks any job cannot merge |
| B0.3 | GitHub organisation, ruleset on `main`, `CODEOWNERS`, environments `staging` and `production` (required reviewer on production), the wholesale-replacement check (§2.4), the repository hooks (§3.4) | D | O medium | | force-push refused; a PR replacing 80% of a file without the label fails |
| B0.4 | Terraform module with CMK, geo-redundant backup, ZRS and immutable containers, per-tenant encryption scopes, Container Apps environment (internal), ACR, Key Vault (Premium, purge protection, RBAC), Log Analytics, ACS Email, action group, OIDC federation; applied to staging; state in a UAE North storage account | D | O high | F | `terraform plan` clean on main; both apps answer `/health` on staging; the action group test SMS arrives; UAE Central request ticket recorded in `PLAN.md` |
| B0.5 | Migration 0001: extensions, roles (including `caros_migrator`), schemas, the spine tables, enums, append-only triggers, partitions, the classification and reclassification triggers | D | **F max** | O | applies from zero in CI; every spine table registered; the registry and convention tests pass |
| B0.6 | `withTenant()` (pass 1 DR-4 verbatim contract), the un-exported pool, the migrator image and the Container Apps Job | D | **F max** | O | a query without context returns zero rows on every tenant table; the pool cannot be imported (lint test); the job applies a migration on staging before the revision swap |
| B0.7 | `auth.allowed()`, `auth.protect()`, the scope predicates, the matrix seed (pass 4 §3.6 rows as `school_id IS NULL`), `auth.forbid_widening()` | D | **F max** | O | policy-presence test: every `school_id` table has `tenant_isolation` and `role_read` with `FORCE`; the narrowing trigger refuses a wider school row and any `safeguarding` override |
| B0.8 | The RLS and authz harness in `packages/db/test/{rls,authz}`: generated from `auth.role_permission` and a fixture map; the eight "see nothing" cases; column cases; `caros_owner` with `FORCE`; both tenants | D | **F high** | O | a matrix row without fixtures fails the build; the suite runs on every PR in under five minutes |
| B0.9 | `audit.record()`, `audit.chain()` with the per-school advisory lock, `events.emit()`, `core.ensure_month_partitions()`, the per-action `detail` schemas in `packages/contracts/audit/` (D48) | D | O high | F | an entry with an unknown key or a 65-character value is refused; the chain verifies over 10,000 seeded entries; partitions exist a quarter ahead |
| B0.10 | `packages/contracts` skeleton: jsonb shapes for the spine, the event and audit payloads, the `StudentEvaluationInput` and `EvaluationResult` types from pass 3 §13.1 (so B2 can start), the connector types from pass 2 §7.1 (so B1 can start) | D | O medium | | every package compiles against them; two approvals required on the package |
| B0.11 | `tooling/tenant` CLI and `packages/seed` layer one for people and calendar: both `core.school` rows (ACS `real_institution` marker on; Wellesmere unbranded, marker off), modules, year groups with stages, programmes with scales, terms, periods, school days, demo personas with memberships and capabilities (Ms Haddad `caseload_lead`, Mr Diaz `ib_coordinator`, Mr Okonkwo `safeguarding_lead`, a `school_admin` each; Wellesmere's DSL who also teaches) | D | O high | | `pnpm seed --tenant acs --anchor <date>` is idempotent; the seed refuses a `real` tenant; the `no-real-data` test passes |
| B0.12 | `packages/ui` from `DESIGN.md` and the app shell: tokens, tier marks, run cells, `tally`, `empty`, the letterhead, the demonstration marker (a generated column, not a flag), role navigation from data, reduced-motion rules, 375px | D | O high | | a Storybook-free visual check page renders every primitive for both tenants; the marker shows for ACS and not for Wellesmere; `web-design-guidelines` review clean |
| B0.13 | `apps/worker` bootstrap: pg-boss with the `pgboss` schema, the heartbeat log line every five minutes, `partition.maintain`, the structured logger with the allowlisted serializer (pass 4 §9.4) and the lint rule | D | O medium | | the log-scanner test finds no seed name in captured logs; the heartbeat appears in Log Analytics on staging |
| B0.14 | Documentation: `CLAUDE.md` (§3.3), `docs/PLAN.md` with B0 to B9 and the B1 briefs, `docs/decisions/DR-01` to `DR-16` extracted from the passes, `docs/spec/` copies, `docs/runbooks/README.md`, `tooling/docs/verify-claude-md.ts` and the generated-docs jobs (§3.6) | D | O high | | `verify-claude-md` passes; the docs job fails on an unresolvable identifier planted in a test |
| B0.15 | Week-one non-code checklist: UAE Central access; GitHub Team; Azure subscriptions and PIM; the Anthropic conversation on ZDR opened and the dedicated organisation with `production` and `staging` workspaces pinned to `us` (pass 5 §8.6); a Google Cloud project for the sign-in client and its brand verification submitted; DPO search opened; DPA drafting started from pass 4 §1.4; penetration-test firm shortlist (CREST-accredited or DESC Cyber Force listed, §8); cyber-liability insurance quote; the ACS name-on-demo consent letter sent (question 49); the KHDA directory check of "Wellesmere" | D | none | | each item has a date and a reference in `PLAN.md` |

**Acceptance criteria.** CI green on a fresh clone; the RLS suite proves tenant A sees and writes nothing of tenant B for every tier role and every spine table, with no context, and as the owner under `FORCE`; the matrix suite is generated and covers every default row with a positive and a negative fixture; `drizzle-kit check` passes; the registry, convention and no-second-copies tests pass; staging serves both apps from `main` with migrations applied by the job; the drift check job runs nightly on staging; the action group delivers to a phone; `verify-claude-md` passes; the fifteen week-one items are dated. **Done includes** every test named above running on every pull request.

### 1.2 B1 · Facts and identity

**Status:** not started · **Depends on:** B0 (G-CI) · **Model:** Opus 5.5, high effort for the pipeline, the transforms, the Studio and the record module; **Fable 5.1, max effort** for the identity ladder, sign-in and sessions, the support-grant path and the RISC receiver · **Reviewed by:** the other model on each of those four, and Opus 5.5 reviews the roster security section and the rollback
**Why this model:** the pipeline is large and well specified, which suits Opus 5.5; the ladder decides who a person is, sign-in decides who is in the building, and the grant path is the only way a CAROS person ever reaches real data, so those four get the model whose mistakes are rarest and the other model's eyes.

**Scope.** `packages/ingest` exactly as pass 2 §2 to §5: the canonical envelope, the mapping profile schema and the closed transform set with property tests, the state machine (D1), the jobs (`ingest.scan`, `parse`, `map`, `validate`, `diff`, `commit`, `after_commit`, `rollback`, `purge`), validation and reason codes, the dry-run preview with the non-collapsible security section, the rejection report, idempotent re-import, rollback with `signals.reopenAfterRollback` stubbed until B2, the identity ladder with candidates and merges, normalisation of grade scales (`config.grade_scale` before `ref.grade_scale`), attendance, behaviour, rosters, contacts, calendar and subjects; the record tables and views (§1.12); both fixture packs with `expected.json`, generated deterministically under `packages/seed/src/fixtures/<tenant>/`; the Mapping Studio's five screens under `apps/web/app/(staff)/admin/ingest/` (Sources, Profiles with the three-pane editor, Imports, Identity decisions, Cadence) for the `school_admin` capability; pass 4's identity for people the school already knows: Google OIDC with PKCE and `openid email profile` only, `hd` validated in the token against `auth.school_domain` before any tenant query, mapping on `sub` then corroborated email, nothing created at sign-in, one acting role per session, server-side sessions with the lifetimes of pass 4 §2.4, step-up with `prompt=login`, anomaly rules, the daily expiry job; the RISC receiver for Google Cross-Account Protection; the support console (grant request, school approval under step-up, masked views, `caros_t_support`, `SUPPORT_ACCESS`); the admin screens People and Memberships (pass 4 §2.5) with four-eyes on a second `school_admin`; `record` read functions for the student file tabs (academic, attendance, behaviour, transcript) so B3 can render them; `PREVIEW_ACCESS`, `FILE_ACCESS` and `DIRECTORY_SEARCH` written by the read functions.

**Not in B1.** Parent and mentor sign-in (B5, B8): parents need the activation-code flow and nothing to look at yet; students sign in through the same Google path but see nothing until B5, so student sign-in is tested in B1 and switched on for real students at onboarding step 18. Live connectors (B9). The SFTP endpoint (B4).

**Tasks (planning estimate: 28 sessions; five to six weeks with two people, in parallel with B2).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B1.1 | Migrations for `sis.student`, `enrolment`, `external_identity`, `subject`, `section`, `section_teacher`, `section_membership`, `assessment`, `grade`, `attendance_event`, `behaviour_event`, `transcript`, `engagement.activity_event` (partitioned, with D56), `family.guardian_link` (with D42), `core.person_name_history`; D1 to D6, D8, D11 to D16; the `sis.v_current_*` views (D12) and `sis.v_attendance_teacher` (D59) | A | O high | F | registry, RLS and no-second-copies tests extend automatically; `drizzle-kit check` clean |
| B1.2 | Canonical records and the profile schema (`MappingProfileSchema`, bindings, expectations, natural keys) in `packages/contracts/ingest`; the 19-op transform set with property tests | A | O high | | a profile using an unknown op is refused; every op has a property test |
| B1.3 | `ingest.scan`, `ingest.parse` (encodings, BOM, XLSX as text, ZIP with `manifest.csv`), chunked staging | A | O high | | the ACS and Wellesmere encoding defects produce their codes |
| B1.4 | Identity ladder, `identity_candidate`, `identity_merge` with 30-day reversal, `core.person.match_key` | A | **F max** | O | rung tests: `4412` vs `004412` resolves by rung 1; the shared-email guardian pair becomes one person with two contacts; a name-only match never auto-resolves |
| B1.5 | `ingest.map` and `ingest.validate`: row and cross-row checks, expectations, `forbidden_columns` before staging | A | O high | | every reason code in pass 2 §2.6 is produced by at least one fixture row |
| B1.6 | `ingest.diff` with the security section; `ingest.commit` in dependency order in 2,000-row chunks with `lock_timeout = 5s`; `import_change`; `ingest.after_commit` (recompute `normalised_pct`, refresh school days, C22 closures stubbed to a domain hook) | A | O high | O (security section by a second Opus session) | the week-44 correction produces exactly two supersedes; a truncated roster fails `max_end_ratio` and commits nothing |
| B1.7 | `ingest.rollback` and `ingest.purge`; `IMPORT_*` audit actions and events | A | O high | | rollback refuses when a later import holds the rows; reason under 20 characters refused |
| B1.8 | Normalisers: grade scales and predicted versus achieved, attendance codes with reasons and `session_key`, behaviour categories, rosters as a security property (pass 2 §5.4 rules 1 to 7), contacts and relationships (no emergency contacts), calendar periods, canonical subjects | A | O high | F (rosters) | `roster-security.spec.ts` passes on Wellesmere; a GCSE `9` is not 9% |
| B1.9 | Fixture generators and `expected.json` for both tenants (term-start pack, twelve weekly packs, reporting pack; Michaelmas, Lent, correction) reproducing the authored series (Ahmed 91, 93, 89, 92, 90, 88, 74, 41) | A | O high | | `fixtures.spec.ts` imports every pack in order against an ephemeral database and matches `expected.json` exactly; regeneration is byte-identical |
| B1.10 | Studio: Sources and Profiles (three-pane editor, lookups pre-seeded, run against sample, activate only after a clean dry run) | A | O high | | Playwright: author a profile against the sample, activate it, on both tenants |
| B1.11 | Studio: Imports (upload by single-use SAS, batch assembly, progress, preview with the security section above the fold, approve with the summary hash, rejection report CSV, rollback) and Cadence | A | O high | | Playwright: the full round trip as `school_admin`; a stale preview must be re-run |
| B1.12 | Studio: Identity decisions queue (link, create, skip) re-queuing validation | A | O medium | | deciding a candidate re-runs `ingest.validate` for the batch |
| B1.13 | Google sign-in: OIDC with PKCE, `hd` and `nonce` validation, `auth.school_domain`, person mapping, "no access" page, `IDENTITY_BOUND`, `SIGN_IN_DENIED`, no JIT | D | **F max** | O | a token with an unknown `hd` is rejected before `withTenant()`; a person with no membership sees "no access"; a test Workspace domain mapped to the ACS synthetic tenant signs a tester in as Ms Haddad |
| B1.14 | Sessions: server-side rows, `__Host-caros_s`, lifetimes per population, acting-role choice, re-authentication on switch, step-up (`prompt=login`, ten minutes), CSRF, revocation, the expiry job, anomaly alerts | D | **F max** | O | session tests including "same id from two ASNs"; step-up required for every action in pass 4 §2.4's list (table-driven test) |
| B1.15 | RISC receiver: Google Cloud project, event-type registration, signed-token validation, `sessions-revoked` and `account-disabled` revoke within seconds; optional Directory reconciliation behind a flag | D | **F high** | O | a signed test event revokes a session in under five seconds; malformed tokens are rejected and counted |
| B1.16 | Support console: grant request and approval under step-up, four-eyes path, masked views, `caros_t_support`, `SUPPORT_ACCESS`, the monthly review query; admin screens People and Memberships with four-eyes on a second `school_admin` | D | **F max** | O | no grant → zero rows; masked grant → pseudonyms; expired grant → zero rows in the same session; `AUDIT_ACCESS` written on the audit screen |
| B1.17 | `record` module read functions for the student file tabs and the teacher register roster, writing `FILE_ACCESS` and `DIRECTORY_SEARCH` in the read transaction; tRPC routers for `record` and `ingest` | A | O high | | authz suite extended for `academic`, `attendance`, `behaviour`, `directory`, `ingest`; a teacher's attendance read goes through `sis.v_attendance_teacher` and has no reason text |
| B1.18 | Perf and hardening: a 1,300-student roster resolves in under a second; 250 MB file limit; content-type by magic bytes; Defender for Storage scan gate (`scan_status = 'clean'`); the export-injection fixture test | A | O medium | | the perf test and the upload tests (EICAR, polyglot, oversize) pass |

**Acceptance criteria.** Both fixture sets import through the real pipeline with `expected.json` matched exactly; `roster-security.spec.ts` passes; the Studio round trip runs in Playwright on both tenants under `school_admin`; staff sign in through Google on a test Workspace domain and land on their imported person; a token from an unmapped domain never reaches a tenant query; the support path behaves as pass 4 §3.8's three support cases require; every read of a student's file writes its access entry; the authz suite covers the new classes. **Done includes** `fixtures.spec.ts`, `roster-security.spec.ts`, the profile specs, the identity-ladder tests, the session and step-up tests, the RISC test and the upload tests in CI.

### 1.3 B2 · Engine and sweep

**Status:** not started · **Depends on:** B0.10 (the contracts) for the engine package, which starts in B0's second week; B1 (facts and `sis.v_current_*`) for the sweep orchestration · **Model:** **Fable 5.1, max effort** for `packages/engine` (the series and band, the detectors, levels, cold start, suppression, the combination table, hysteresis, the templates, the `engine.tiering` rows and the calibration scripts); Opus 5.5, high effort for the domain loader and writer, the sweep jobs, the watchdogs and alert rules, the thresholds screen, the counselor log and shadow view · **Reviewed by:** Opus 5.5 reviews the engine (pass 3 asked for a review by a different model from the one that wrote it); Fable 5.1 reviews the writer's transaction and the deterministic-id policy
**Why this model:** the statistics are the product's mechanism and their errors are silent (a floor set wrong is a quiet student never seen, or a queue nobody opens); the orchestration is well specified and testable, which is Opus 5.5's ground.

**Scope.** `packages/engine` as pass 3 §13.1: `evaluateStudent(input): EvaluationResult`, pure, total, deterministic, versioned; the four JSON schemas published (D31); the scenario suite S1 to S23 with generators and expectations in `packages/engine/test/scenarios/`; the five property tests (determinism, monotonicity, suppression never raises, no comparison, hysteresis); the golden-file test; the lint bans on `Date.now()`, `Math.random()` and the environment; `packages/engine/tooling/calibrate.py` and `calibrate_tiers.py` with the known-parameter ARL check (`k = 0.5`: `h = 5` gives an ARL of about 928 one-sided) committed beside the package; the engine tables and D17 to D32 (§1.12); the domain loader `packages/domain/signals/load.ts` (one query per table batched by student ids, through `sis.v_current_*`, per-domain `as_of` from `ingest.expected_cadence` and the newest fact); the writer (one transaction per student; snapshots content-addressed; `uuid_generate_v5` ids for signals and evidence; the case open or move through the trigger; events and audit); the sweep jobs of pass 3 §13.2 (`sweep.schedule`, `run`, `batch`, `finalize`, `event`, `backfill`, `whatif`, `watchdog`) with the deadlines and retries; the external watchdog as a Container Apps Job; the Azure Monitor scheduled-query alert rules of pass 3 §13.8 and `/health/sweep`; `signals.reopenAfterRollback`; the `ingest.after_commit` hooks (dirty marking of `(student, measure, week)` on supersede; backfill enqueue for a scheduled pack; C22 closure); the thresholds screen (`vThresholds` port: propose, activate as `caseload_lead`, the what-if run, guards 1 to 6, the disabled-domain banner and `config.domain_disabled`); the platform default rule sets version 1 and the ACS version 1 derived from `S.thresh` (`acad 2, att 3, eng 14, persist 3`, mapped to the new parameter names with the seed note recording the mapping) and a Wellesmere version 1; the counselor log table and API (its thirty-second row on the sheet is B3's), the shadow view, `signal.shadow` and `counselor_log` data classes in the matrix and the authz suite.

**Tasks (planning estimate: 26 sessions; five to six weeks with one engine builder and Davide, in parallel with B1).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B2.1 | Series builder and the personal band: school weeks, the baseline window, median and MADn with floors, `phase` (cold, self-starting, band, full), the run cells with the minimum-meaningful-change rule | B | **F max** | O | S4, S6, S13, S14 pass; the band never reads another student (the no-comparison property) |
| B2.2 | Detectors: band, shock, one-sided CUSUM with onset, the scale-free rule, Theil–Sen for the sentence; levels 0 to 3 per measure and per domain | B | **F max** | O | S1, S3 pass; the ARL check reproduces the literature figures |
| B2.3 | Cold start and self-starting CUSUM; the `baseline_established` monitor case | B | **F max** | O | S5 passes; a transfer's first month surfaces a genuine collapse at `monitor` only |
| B2.4 | Suppression: calendar kinds, absence spans, section changes, counselor and teacher context, the common-cause guard; every check recorded fired or not | B | **F max** | O | S9, S10, S11, S12 pass |
| B2.5 | Domains: academic (per section, mocks apart, `missing` as a submission series), attendance and punctuality (per-session where present), behaviour, teacher concern with corroboration, university rules as inputs, positive change, recovery and relapse; retrospective rules and the cadence modes | B | **F max** | O | S2, S7, S8, S16, S21 pass |
| B2.6 | Combination table and persistence, the tiering rows as data in the closed grammar, hysteresis (exit weeks, the 14-day person hold, the 24-hour and 7-day caps), auto-review, the daytime asymmetry as a flag on the result | B | **F max** | O | S17, S18, S19, S22 pass; the hysteresis property holds over generated series |
| B2.7 | Templates: every rule's headline and evidence sentence from `template_args` restricted to numbers, dates and enumerated labels; the move-why template | B | O high | F | a template cannot bind a free-text field (schema test); every S-scenario's final evidence sentences match |
| B2.8 | The JSON schemas D31 with every bound of pass 3 §10.1; `engineVersion`, the changelog rule, the golden files | B | O high | | a value outside a bound is refused with the bound in the message |
| B2.9 | Calibration scripts committed with their outputs; the appendix simulation reproduced; `pnpm test --filter engine` under one second | B | O medium | | the numbers in pass 3 §3.6 and §11.1 are regenerated within rounding |
| B2.10 | Migrations for `signal.*` (all but `escalation`), D17 to D32, D56, D58, D60; the `sweep_run` nightly index; `signal.week_run()`, `signal.v_last_contact`, `signal.v_shadow_queue` | D | O high | F | registry and RLS suites extend; the counselor log and shadow view are invisible to teachers, students, parents, mentors and out-of-caseload counselors (test) |
| B2.11 | Domain loader and writer: `load.ts`, the input DTO, one transaction per student, deterministic ids, snapshots, the case trigger path, events, audit | D | O high | F | a replayed write is an upsert with no duplicates; a crash mid-batch leaves no half-written student (fault-injection test) |
| B2.12 | `sweep.schedule`, `sweep.run`, `sweep.batch`, `sweep.finalize` with the DR-6 assertions and the overnight comparison; `sweep.event` with the daytime asymmetry and the five-minute coalescing; `sweep.backfill`; `sweep.whatif` | D | O high | F | the event test: a flag raises within five minutes and never lowers except on context; the backfill test S20 |
| B2.13 | Watchdogs and alerts: `sweep.watchdog` at 05:45 local, the Container Apps cron job, the scheduled-query alert rules (no completion by 05:30, partial, duration over two hours, heartbeat absent 20 minutes, `students_failed`, `domain.quiet`, `budget.exceeded`, `common_cause.detected`, churn over 10%, assertion failures), `/health/sweep`, the non-dismissible banner | D | O high | | on staging: a stopped worker pages within 20 minutes; a deliberately failed run raises the banner; `/health/sweep` reports per school without identifiers |
| B2.14 | `ingest.after_commit` hooks: dirty marking on supersede, backfill enqueue for scheduled packs only, C22 closure through the domain, `signals.reopenAfterRollback` | A | O high | | S15 passes end to end through a corrected import |
| B2.15 | Thresholds screen: sections for the three rule sets, propose and activate, the what-if run, guards 1 to 6, the disabled-domain banner, the version note with the engineer's acknowledgement in shadow | B | O high | | the what-if delta guard and the mass-change guard fire in tests; activation needs `caseload_lead` |
| B2.16 | `engine-reproduces-seed`: the twelve ACS packs imported in sequence, backfill evaluations, the diff against the narrative layer with pass 3's expected list (thirteen match on the day, Maryam one week later, Hana one tier below) | B | O high | F | the diff equals the expected list; the narrative layer for signals is then retired from the seed |
| B2.17 | Seven staging nights: the sweep runs on schedule for both tenants; the alert rules stay silent; the drift check and `tier_yesterday` assertion pass | D | none | | seven consecutive `sweep.completed` lines by 05:30 Asia/Dubai |

**Acceptance criteria.** The scenario and property suites pass and run in under a second; the engine imports nothing from `fairness` or the database (tests); the seed reproduction diff equals the expected list; the sweep completes on seven consecutive staging nights inside its window with the alert rules silent; a stopped worker pages within twenty minutes; the event path raises and never lowers except on context; the what-if run returns in seconds at pilot scale; the thresholds activation path requires `caseload_lead`. **Done includes** S1 to S23, the property tests, the golden files, the loader and writer fault tests, the sweep smoke test (§5.7), the watchdog test, the RLS additions and the calibration check in CI or, for the staging nights, in the drill log.

### 1.4 B3 · The counselor's morning

**Status:** not started · **Depends on:** B1 and B2 · **Model:** Opus 5.5, high effort for the screens and the case, intervention, flag and meeting mutations; **Fable 5.1, max effort** for the escalation (the state machine, the route, the reminders, the acknowledgement scope), the access-logging discipline and the template renderer with its allowlists · **Reviewed by:** the other model on the escalation and the renderer; Fable 5.1 reviews the table-driven "every mutation writes its audit action" test
**Why this model:** the screens are a port of a specification that exists and renders, and the mutations are a state machine pass 1 wrote out transition by transition; the escalation is the one act in the product that is consequential in the world, and the email that carries it must be provably empty of the child.

**Scope.** The `signals` module: every transition of pass 1 DR-7 (C1 to C22, I1 to I6) as a named domain function that begins with `assertAllowed`, writes its audit action and its event in the same transaction, and is reachable only through its tRPC procedure; the counselor surfaces of CONTEXT §8 that the engine feeds: the caseload sheet in its four modes with the run, "what changed overnight" from `tier_yesterday`, the missed-night comparison line, the `expected_cadence` panel (pass 2's one new element), the counselor log row and Friday prompt, bulk acknowledge and bulk reassign with their audit actions; the command centre and priority queue as one screen; signal intelligence (`si-why`: the descriptive cohort tiles stay, the matrix colours by domain level, no ranking); the case file (`vCase`) with the level, breadth and window in place of the removed strength, confidence and severity (pass 3 §9), the evidence chain from `evidence_item` with source labels and as-of dates, the baselines tab, interventions and steps, staff-only notes as superseding rows, counselor context with the re-evaluation, the "who has looked at this file" panel, and escalation; the interventions view; the flags inbox with attach and dismiss writing the routed note in its three-word vocabulary; meetings; the five student-intelligence dimension pages (attendance, punctuality, academic, engagement, behaviour) over pass 3's `dimensions` rule set (the five application dimensions arrive with B5); the 360° file list and the file's record tabs from B1; the teacher surfaces: the class register (first), my classes, the flag modal with kinds, tags and lesson period, and "what I've logged"; the escalation end to end as pass 4 §5: the route configuration screen (`school_admin` under step-up with a `safeguarding_lead` co-signature, `school_route_history`), `core.school.safeguarding_contacts`, the structured referral form with step-up, the reference-only email through the outbox, the in-app status line, reminders at 60 and 120 and 240 minutes and the 24-hour banner with the direct-report record, the acknowledgement screen under the `ESC` scope, the outcome vocabulary and the ADEK 24-hour countdown; the outbox delivery worker with the Azure Communication Services Email adapter (Mailpit locally), the in-app channel, and the template renderer that refuses undeclared variables; the audit screen (`caseload_lead` and `school_admin`, step-up, `AUDIT_ACCESS`); in-app notifications; the `arch` page ported as an honest description of the sweep and the pull pipeline (passes 2 and 3 §0.2), because the frozen demo's copy is wrong.

**Not in B3.** The `prove` reporting page and the `pilot` page (B8, when there are events to report); the co-pilot (B7); the five application dimensions (B5); parent, student and mentor surfaces (B5, B6, B8).

**Tasks (planning estimate: 34 sessions; six to seven weeks with three people).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B3.1 | Migrations: `signal.escalation` with D45 and D46, D43 on `auth.caseload_assignment`, `family.contact_log`; vocabularies seeded (`flag_tag` with severities, `intervention_type`, `meeting_kind`, `meeting_topic`, `context_kind` with effects, `behaviour_category`, `absence_reason`, `access_purpose`, `escalation_outcome`) | D | O high | F | registry, RLS, matrix and no-second-copies tests extend; `flag_tag` attribute schema validated on insert |
| B3.2 | Case mutations C2, C5 to C14, C17, C18 and interventions I1 to I5 as domain functions with `assertAllowed`, audit and events; bulk acknowledge and reassign | D | O high | F (the audit-coverage test) | a table-driven test proves every domain function in `packages/domain/signals` writes exactly its named audit action and event; C18 refuses while an intervention is open |
| B3.3 | Cover and handover: planned cover, break-glass self-grant (20-character reason, 24 hours, step-up, notices to owner and lead, weekly digest), reassignment; `purpose = 'cover:<id>'` on reads | D | **F max** | O | the eight "see nothing" cases include ended cover and reassignment; the digest lists every break-glass use |
| B3.4 | Escalation: route configuration and history, contacts, the structured form under step-up, C15 in one transaction, the reference generator (random, non-sequential), the outbox rows, `ESCALATED_SAFEGUARDING` with identifiers only | D | **F max** | O | `UNIQUE (school_id, case_id)` holds; a second escalation on a case is impossible in the UI and the API; names never enter `audit.entry` (test) |
| B3.5 | Escalation clocks: reminders at 60, 120 (deputy), 240 (oversight) minutes, `unacknowledged_24h` with the banner and `DIRECT_REPORT_RECORDED`; the `school_hours` clock option; outcome closing with the vocabulary; `ESC` scope until 90 days after outcome | D | **F max** | O | timers tested with a fake clock; oversight receives only the fact, never content; the `ESC` scope expires in the authz suite |
| B3.6 | Acknowledgement screen for `safeguarding_lead` holders: sign-in, step-up, the case under `ESC`, acknowledge, the recipient's private note, close with outcome | D | O high | F | a lead who is not a counselor sees nothing but escalations (matrix test); acknowledgement tells the counselor at once |
| B3.7 | Outbox delivery worker, the ACS Email adapter with the custom domain, Mailpit locally, the in-app channel, retries and `not_before`, bounce handling, the 30-per-minute new-domain limit respected | D | O high | | a queued row is delivered within one minute on staging; a bounced address is `suppressed` |
| B3.8 | Template renderer with allowlists (D47): `safeguarding_escalation` with exactly six variables, `escalation_reminder`, `meeting_confirmation`, `student_deadline_nudge`, `magic_link`, `parent_activation`; `packages/notify/test/templates.spec.ts` | D | **F high** | O | the rendered escalation contains the reference and URL and none of the fixture student's name, initials, year, tier, headline, reason or evidence; an undeclared variable fails the CHECK |
| B3.9 | Caseload sheet: four modes, the run from `signal.week_run()`, overnight column from `tier_yesterday` and `moved_why`, the missed-night line, the `expected_cadence` panel, `CASELOAD_VIEW` per render, the counselor log row and Friday prompt, bulk actions | D | O high | | Playwright on both tenants; Wellesmere shows Years and the DSL label; the marker shows on ACS only |
| B3.10 | Command centre and priority queue (one screen), signal intelligence (`si-why`) with the matrix by domain level and the descriptive cohort tiles | D | O high | | no screen orders students by any score (the no-comparison UI test greps the rendered DOM for rank words and sorted meters) |
| B3.11 | Case file: header (tier, level, breadth, window, `cold_start`), evidence chain with source labels and as-of, baselines tab with the band and the run, interventions and steps, notes (superseding), context (with re-evaluation status), the access panel, the escalate action, `CASE_ACCESS` and `NOTE_ACCESS` in the read transaction | D | O high | F (access logging) | a file open writes `FILE_ACCESS` with `purpose` when the reader is not the owner; the evidence sentence is pass 3's stored `summary`, never recomputed |
| B3.12 | Interventions view, meetings view and `core.meeting` recording with actions; `family.contact_log` entry and `PARENT_CONTACT` | D | O medium | | `signal.v_last_contact` updates on a recorded meeting |
| B3.13 | Flags inbox: attach (C13) with the routed vocabulary, dismiss, merge (C12); the "what I've logged" teacher view showing only the three routed phrases | D | O high | | a teacher never sees a tier or that a case exists (grep test on the rendered teacher pages) |
| B3.14 | Teacher register and my classes from roster rows only; the flag modal (kinds, tags with severity, lesson period, the "who will see this" line); `TEACHER_FLAG`; the event evaluation enqueued; 375px | A | O high | | a teacher after a roster move loses the student (authz suite); a flag with a safeguarding-relevant tag evaluates within five minutes (S7 end to end) |
| B3.15 | The five student-intelligence dimension pages over the `dimensions` rule set; `vDim` as one component | D | O medium | | the three formerly hard-wired dimensions are computed from series (no student-id literals anywhere: lint test) |
| B3.16 | Audit screen, the file access panel, in-app notification centre, the honest `arch` page | D | O medium | | every audit-screen query writes `AUDIT_ACCESS` and shows it |
| B3.17 | Accessibility and copy pass on every B3 screen: keyboard, focus, `aria-live` for the sheet, reduced motion, the six type roles from `DESIGN.md`, no severity by colour alone | D | O medium | | `web-design-guidelines` review with no blocking finding; Playwright axe checks pass |
| B3.18 | Demo 1 script and rehearsal on staging with both tenants (§6.5); route-state count for counselor and teacher against the 98 | D | none | | every counselor and teacher route-state renders with zero console errors on both tenants; the script runs in twenty minutes |

**Acceptance criteria.** The Demo 1 script runs end to end on staging for both tenants; every counselor and teacher route-state renders without error; every mutation writes its audit action and event (table-driven test); every sensitivity-3 read writes its access entry; the escalation's email is provably free of the child, its timers fire on a fake clock, its acknowledgement needs the capability and step-up, and it cannot double-fire; the routed note never states a tier; the Wellesmere checklist assertions for these screens pass; the accessibility review passes. **Done includes** the Playwright flows (morning ritual; teacher flag to attachment; escalation to acknowledgement; cover and break-glass), the template content test, the timer tests, the audit-coverage test and the no-comparison UI test in CI.

### 1.5 B4 · Pilot readiness

**Status:** not started · **Depends on:** B3 (G-DEMO) · **Model:** Opus 5.5, high effort for the tooling, the runbooks, the review pack and the production Terraform; **Fable 5.1, max effort** for erasure with restore replay and offboarding key destruction (irreversible by design), for the legal-basis and classification gates, and for the review of the production Terraform apply · **Reviewed by:** the other model; any penetration-test finding in authorization is fixed with Fable 5.1 and reviewed by Opus 5.5
**Why this model:** this phase is where the irreversible things happen: keys, erasure, production. Most of it is procedure and tooling, which Opus 5.5 does well; the three irreversible pieces get the reserved model.

**Scope.** Pass 4's §9.13 list, in order, as a phase gate, plus the pilot's non-code work. Privacy tooling: the three notices as versions with acknowledgement on first sign-in (D51); the `legal_basis_attestation` trigger that keeps a `real` tenant in `onboarding` (D45); the SAR request and pack generator from `privacy.table_registry` with the redaction screen and its vocabulary (D52), delivered in the portal only, watermarked; the erasure job with `erased_external_identity` (D52) and the restore replay step in the restore runbook; `processing_restriction` with the engine hook (D58); the retention jobs per class, each number a proposal; offboarding: the exit pack, the read-only month, key destruction; the weekly audit anchor to a locked immutable container and the verification job; `pgaudit` for DDL and ROLE. Production: the Terraform module applied to `caros-prod` (server created with CMK and geo-redundant backup, zone-redundant HA, the second Key Vault in UAE Central, Application Gateway WAF v2 in detection mode two weeks before the first real import then prevention, PIM with no standing access, the release pipeline with the production environment approval, the nightly tenant canary, the drift check); the SFTP endpoint if the pilot uses it: Azure Blob SFTP needs a hierarchical-namespace account, authenticates local users by SSH key and keeps port 22 open even when disabled ([SFTP support](https://learn.microsoft.com/en-us/azure/storage/blobs/secure-file-transfer-protocol-support)); the page lists no regions, so the UAE North check is done in the portal in this phase and the fallback is pass 2's container; the SFTP watcher job. Drills: all five of pass 1 DR-9 run once before real data, with the erasure replay, recorded in the drill log that the release pipeline reads. A load test of the morning burst (pass 4 T13) with a tool of Davide's choice (assumption: k6). The onboarding runbook (`docs/runbooks/tenant-onboarding.md`) and the tenant's onboarding checklist record covering pass 2 §9's twenty steps, the Google Workspace configuration checklist of pass 4 §2.1 (Limited for the staff and student units, under-18 designation confirmed, RISC receiver registered, the optional Directory scope), and the safeguarding route set-up with a test referral delivered to the CPO. The review pack organised by ADEK Digital 5.5.1 a to h (pass 4 §9.12): the ASVS 5.0 Level 2 self-assessment (ASVS 5.0.0 was released in May 2025 with three verification levels per secondary sources; [OWASP ASVS](https://github.com/OWASP/ASVS)); the whitepaper from pass 4 §§2 to 7; Annex 1 generated from the registry; the DPA with annexes signed; the DPO appointed; the notices approved by the school; the penetration test by an independent firm, scoped to the web application, the API, authentication and tenant isolation, run against staging with synthetic data, highs fixed and retested within 30 days (CREST-accredited firms operate in the UAE under the Dubai Cyber Force scheme run by CREST with the Dubai Electronic Security Center, [CREST](https://www.crest-approved.org/membership/dubai-cyber-force-program/)); the incident tabletop with ACS IT and the CPO; the support-grant path exercised once with the school; cyber-liability insurance; the on-call rota and the sweep-failed runbook (§7.5); the shadow comparison report (pass 3 §14.3) as a masked support-console report; the school's monthly report skeleton; the elicitation session (pass 3 §10.5) with the four counselors, producing ACS's `engine.thresholds` and `engine.tiering` version 1 in shadow with every departure from the default traced to an answer.

**Tasks (planning estimate: 22 sessions of code plus the external lead times; four weeks of build, and the external items decide the calendar).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B4.1 | Notices (D51): three audiences, versions, approval fields, acknowledgement on first sign-in and on each new version; the matrix rendered from `auth.role_permission` inside the notice | D | O high | | a person with an unacknowledged current notice is routed to it before any screen |
| B4.2 | Legal-basis attestation and the `onboarding` gate (D45 trigger); fixture and real classification gates re-verified | D | **F high** | O | a `real` tenant cannot become `active` without the attestation; the seed refuses it; fixture imports refused |
| B4.3 | SAR request, pack generator (JSON and PDF from the registry, access history without staff names, generations by record type), the redaction screen and vocabulary, portal delivery with watermark, 30-day expiry | D | O high | F | a synthetic student's pack contains every registered table where they are subject (test compares the registry to the pack) |
| B4.4 | Erasure: request, 30-day schedule, the job (tombstone, scrub `pii_columns`, delete or anonymise by class, blob purge, pseudonym maps, external identities hashed), `ERASURE_EXECUTED`, the destruction statement; the restore replay script | D | **F max** | O | after erasure, a full-text search of every registered table and the blob store for the person's strings finds nothing; a restored server replays the erasure before use (drill 1) |
| B4.5 | Restriction and objection: `processing_restriction`, the engine skip, the frozen-case banner, exclusion from co-pilot and exports; parental access at 18 default with `student_objection_18` | D | O high | F | S-style test: a restricted student is skipped by the sweep and excluded from a SAR of another student's data |
| B4.6 | Retention jobs per class with the proposal numbers, `RETENTION_PURGE`; the weekly audit anchor and verification (P1 on mismatch); `pgaudit` settings in Terraform | D | O high | | the anchor blob lands in the locked container; a tampered entry in a test database is detected |
| B4.7 | Offboarding: exit pack, read-only month, key destruction in Key Vault, `TENANT_OFFBOARDED`, the destruction certificate; the restore runbook's offboarding replay | D | **F max** | O | a drill offboards a synthetic tenant on staging and the raw-import container becomes unreadable |
| B4.8 | Production Terraform: apply to `caros-prod`; WAF in detection mode; PIM; the release workflow with the production environment, deployment-branch rule (tags only), the drill-log check, the staging soak check; the nightly canary | D | O high | F | a release deploys by tag with Davide's approval; rollback to the previous revision works in a rehearsal |
| B4.9 | SFTP: portal check of Blob SFTP in UAE North; per-tenant local user with `Create` and `Write` only, egress IP allowlist, host keys published; else the container; the watcher job creating imports | A | O high | | a dropped file becomes a `received` import; the tenant user cannot list or read |
| B4.10 | Restore drills 1 to 5 scripted in `tooling/restore-drill/`, the drill log, the CI check that blocks a production deploy after a quarter without a drill | D | O high | | all five drills pass on staging with the erasure replay; the log records time and point achieved |
| B4.11 | Load test of the morning burst and the sweep at pilot and year-1 shapes; Container Apps scale ceilings set | D | O medium | | p95 under the feature timeouts at 3× pilot concurrency (assumption for the bar) |
| B4.12 | Onboarding runbook and checklist record; `tooling/tenant` completed for a real tenant (classification `real`, first `school_admin` from the DPA, domains, route, modules, cadence); the Google Workspace configuration checklist; the safeguarding route set-up with the test referral | D | O high | | a dry onboarding of a third synthetic tenant runs steps 3 to 20 with a human at the steps pass 2 §9 lists |
| B4.13 | Review pack: ASVS L2 self-assessment with evidence links to CI, the whitepaper, Annex 1 generated, the CI control list (pass 4 §9.11) rendered from the test names | D | O high | | every control in pass 4 §9.11 links to a passing test in the latest CI run |
| B4.14 | Penetration test: scope, firm, staging target with synthetic data, findings triage, fixes, retest | D | O high (F for authorization findings) | | highs closed and retested; the report in the pack |
| B4.15 | Shadow comparison report (overlap, lead time, engine-only, counselor-only with `data_gap` versus `engine_miss`, noise per detector, reliability) in the support console, masked | B | O high | | the report runs over the synthetic tenants' log rows |
| B4.16 | Elicitation session with the ACS counselors (Davide, no model): the twelve vignettes, Parts B to F; ACS `engine.thresholds` and `engine.tiering` version 1 in shadow with the mapping table in the version note | D + B | none | | the version note traces every departure from the default to an answer; disagreements recorded |
| B4.17 | Non-code gate items with evidence: DPO appointed; DPA signed with annexes; notices approved; insurance bound; tabletop held; support grant exercised with the school; on-call rota published; the CPO's test referral acknowledged | D | none | | the §9.13 checklist in `PLAN.md` has a date and a reference per line |

**Acceptance criteria.** Every line of pass 4 §9.13 has evidence; the five drills are logged; the pen test's highs are closed; production deploys by tag with approval and rolls back in a rehearsal; the SAR and erasure tests pass; the canary runs nightly in production against the two synthetic tenants (allowed there only as signed demo tenants, pass 1 DR-9, or against a dedicated canary pair); ACS's thresholds version 1 exists in shadow. **Done includes** the SAR, erasure, restriction, anchor, offboarding and drill tests, the load-test report, and the CI drill-log check.

### 1.6 B5 · The application season

**Status:** not started · **Depends on:** B3; its domain work can start when B1 is done · **Model:** Opus 5.5, high effort; **Fable 5.1, max effort** for the reach, match and safety classification rule and the fee-status rule (numbers a family sees, invariant 3), for parent activation and magic links (identity for people the school does not know), and for the deterministic safety screen's routing · **Reviewed by:** the other model on those three
**Why this model:** the module is broad and mostly a faithful port; the classification and fee-status rules decide what a family reads about money and chances, and the parent link decides which adult sees which child.

**Scope.** The university module: `uni.*` and the global reference tables with `ref.source` on every row; the classification rule (pass 5 §2.3) as `config.rule_set_version 'uni.classification'`, recomputed by the sweep and on predicted-grade or requirement change, with `classification_abstention` when nothing is on file and the inputs printed; `ref.admission_statistic` for published institution-wide rates, labelled as such (D73); the reference-data curation tool (`tooling/ref`) so that every institution, course, requirement, cost and deadline row a school can see carries a source URL and retrieval date, with the seeded `seed://prototype` rows visibly labelled unsourced until replaced (the number of institutions to curate for the pilot is an open scope item, §13); deadlines and the student nudges at T-21, T-14, T-7 and T-2 through the outbox with `dedupe_key`; document requests with the reference SLA chases; statements and versions with the counselor review queue; the reference-letter records of pass 5 §3.10 (D72: activity records, teacher comments, reference notes, consent columns) with human-written letter versions only; AP exam registrations; the five application dimension pages over `uni.v_application_pack`; the counselor screens `app-season`, `app-flow`, `app-letter` (as a human-written versions screen), `psreviews`, and the file's university tab; the student screens my subjects, subject record, my progress (Grade 11 and above), university targets (Grade 12, no probability), Personal Statement Lab, AP exams, the high school guide and the IB-or-AP explainer with its synthetic alumni content labelled; the parent portal: activation codes (D41) issued by a `school_admin`, the email-must-equal-SIS rule, browser-bound single-use magic links, the co-holder rule, the child switcher, overview, messages (in-app), meet the counselor with slots and requests and the confirmation template, grades and transcripts (Grade 11 and above), university requirements (Grade 12), AP exams, the guide, the Parents admin screen; student sign-in switched on for the synthetic tenants; the student's "I need to talk to someone" channel writing an `urgent_request` reflection; `packages/safety` layer 1 (the deterministic screen, pass 5 §6.2) on every student free text, `signal.safety_alert` (D68), the counselor alert and the two-school-hour route, the school-approved `safety_response` template with the confirmed helplines; the student surfaces in deterministic mode where a later model feature would sit (statement read absent; discovery in B8).

**Tasks (planning estimate: 36 sessions; seven weeks with two people, overlapping the shadow period).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B5.1 | Migrations: `uni.*` (all eleven), the remaining `ref.*`, `family.message`, `family.meeting_slot`, `family.meeting_request`, D11, D41, D68, D72, D73 (except archetype columns), the `uni.classification` rule-set kind and its schema, `probability`, `chance`, `likelihood` on the forbidden list | C | O high | F | registry, RLS, matrix and no-second-copies tests extend |
| B5.2 | Reference-data curation tool and the first sourced set for the pilot's demo targets; `ref.source` rows with URL and retrieval date; the UI source label; unsourced rows hidden or labelled | C | O high | | no `ref` row renders without a source label; the seeded prototype rows are labelled unsourced |
| B5.3 | The classification rule and its recompute paths; fee-status rules by passport with the Canada demonstration; abstentions | C | **F max** | O | the rule never reads nationality, sex or a fairness label (test); P4's two students differ only on the cost page; classification inputs print on every target |
| B5.4 | Applications, offers, document requests with `chase_count`, the reference SLA rule, `document.chased` events, the outbox chases | C | O high | | a document past T-14 is chased once per cadence with a `dedupe_key` |
| B5.5 | Deadlines and student nudges (T-21, 14, 7, 2) through the outbox; `notify.preference`; `application.deadline_nudge_sent` | C | O high | | the nudge template names the institution and date and nothing about standing (template test) |
| B5.6 | Statements: versions, `psreviews`, the Personal Statement Lab in deterministic mode, `PS_SUBMITTED`, `PS_REVIEWED` | C | O high | | a submitted version reaches the queue; the safety screen runs on every saved version |
| B5.7 | Letter engine records (D72) and the `app-letter` screen as human-written versions with the evidence panel rendered from citation rows; `student_consent_at` | C | O high | | a version with `produced_by = 'model'` is refused before B7 (test) |
| B5.8 | Counselor screens `app-season`, `app-flow`, the five application dimension pages over `uni.v_application_pack`, the file's university tab | C | O high | | the ten dimension pages now all exist; Wellesmere shows UCAS-only deadlines |
| B5.9 | Student record surfaces: my subjects, subject record, my progress, targets without probability, AP exams, the guide, the IB-or-AP explainer with the synthetic label | C | O high | | Grade and Year labels from the tenant; the probability meter is absent (DOM test) |
| B5.10 | Parent activation (D41), magic links (256-bit, hashed, 15 minutes, browser-bound, rate limits), the co-holder rule, reactivation on address change, the Parents admin screen | D | **F max** | O | a forwarded link fails on another device; the second co-holder is named on messages; three links an hour per address |
| B5.11 | Parent portal: child switcher over `linked_children`, overview, messages in-app, meeting slots and requests with the confirmation template, grades and transcripts by grade rule, university requirements, AP exams, the guide; uniform not-found for non-linked ids | D | O high | | Playwright: a guardian with two children in different years sees each under its navigation and never a sibling's row from the other context |
| B5.12 | `packages/safety` layer 1: the lexicon, the pattern screen under 50 ms, `safety_alert`, the counselor alert and the two-school-hour route, the `safety_response` template with the school's contacts, the "I need to talk to someone" action | D | **F max** | O | the corpus's direct positives are caught by layer 1 alone at the pass-4 routing rules; the student never sees a model-written word |
| B5.13 | Student sign-in enabled on the synthetic tenants; the student notice; the under-13 flag from the date of birth | D | O medium | | an under-13 synthetic student is flagged and gated |
| B5.14 | Accessibility and 375px pass on every parent and student screen; Demo 2 script part one | C | O medium | | axe checks pass at 375px; the demo script runs |

**Acceptance criteria.** Every family and university route-state renders on both tenants; the classification and fee-status rules pass their tests and never read a protected column; every reference figure a family sees carries a source label; the parent flows pass in Playwright with the link and activation rules enforced; the nudge and chase templates pass the content test; the layer-1 safety screen routes the corpus's direct positives; the Wellesmere checklist assertions for these screens pass. **Done includes** the rule tests, the outbox dedupe tests, the parent identity tests, the safety layer-1 corpus test and the Playwright flows in CI.

### 1.7 B6 · The Diploma

**Status:** not started · **Depends on:** B3 (case file, meetings), B1 (rosters and `feeder_set_key`), and the Extended Essay guide decision (question 133) before the essay part is built · **Model:** Opus 5.5, high effort; **Fable 5.1 reviews** the two gates (the `selCheck` port and the approval gate of invariant 6; the capacity stamp of invariant 8) and the coordinator's cross-caseload scope · **Reviewed by:** Fable 5.1 on the gates, Opus 5.5 on the rest by a second session
**Why this model:** the module is the most literally specified part of the prototype (its rule engine `selCheck` is code today), so a faithful port suits Opus 5.5; the two gates are the module's reason to exist and a wrong port would be invisible on screen.

**Scope.** `ib.*` (twenty tables) and D70; the catalogue and its per-level periods, prerequisites and subject teachers seeded from the prototype for ACS and absent for Wellesmere (modules off); the selection round and the S1 to S10 state machine with `selCheck` ported into `packages/domain/ib/selCheck.ts` returning `block`, `ask` and `ok` findings exactly as `index.html:4671` does, the version bump on submission, sign-offs deleted when a pick changes, and the approval gate as both the database `CHECK` and the domain guard; the demand and viability views, counted per subject; the coordinator views (`vSelQueue`, `vSelStudent`, `vSelDemand`), the teacher sign-off queue (`vTSelReview`, `vTSelCard`: HL picks, own subjects only), the Grade 10 student form (`vSelForm`, `vSelChooser`, `vSelSubmittedPanel`) with the review-slot request; the review conversation recorded as a `core.meeting` of kind `selection_review`; CAS: catalogue, interests, the ledger with `imported_balance` rows, reflections with the seven outcomes, `ib.v_cas_totals`, the coordinator cohort and detail views, the student activities page and the Diploma core tabs (CAS, TOK described and not tracked, EE), CAS nudges; the Extended Essay: rounds carrying `ee_guide_key`, milestones as data per round (the three RPPF sessions under `ee_2018`, the single reflective statement under `ee_2027`), real due dates per year group, the E1 to E11 state machine, `ee_stamp_capacity` recording load and over-capacity and never blocking, the teacher queue with load on every card, the coordinator aggregate, the student proposal and status pages, reflections, drafts as `doc.file`, milestone-overdue events and nudges, the near-duplicate check with `pg_trgm` for the coordinator only; module gating so that Wellesmere shows no IB navigation, queue or CAS page.

**Tasks (planning estimate: 30 sessions; six weeks with one person plus reviews).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B6.1 | Migrations: `ib.*`, D70 (`ref.ee_guide`, `ref.ee_criterion`, the two seed guides with descriptors left for the school), D10's module keys; catalogue seed for ACS | C | O high | F | registry, RLS and matrix tests extend; the `ib_cohort` scope is exercised in the authz suite |
| B6.2 | `selCheck` port with findings `block`, `ask`, `ok`: group coverage, HL count, period clashes (including `sis.section_meeting` week B), prerequisites against `feeder_set_key`, goal alignment, viability | C | O high | **F** | a golden test replays the prototype's seeded selections through the port and matches its findings one for one |
| B6.3 | Selection state machine S1 to S10, the version bump, sign-off deletion on change, the review-meeting gate as CHECK and domain guard, `SUBJECTS_SENT`, `SUBJECT_SIGNOFF`, `SUBJECT_REVIEW`, `SUBJECTS_APPROVED`, `SUBJECTS_RETURNED` | C | O high | **F** | approval without `review_meeting_id` is refused at both layers (test); a teacher can sign off only HL picks of their own subjects |
| B6.4 | Demand and viability views and the demand sheet; a subject's viability counted once, never per level | C | O medium | | the prototype's "five at-risk courses, not nineteen" case is a test |
| B6.5 | Coordinator queue and student detail; the conversation recording; return with a note; the round's open and close and S10 | C | O high | | Playwright: submit, sign off, record conversation, approve, on ACS; the queue is absent on Wellesmere |
| B6.6 | Student form and chooser at Grade 10 (`stage = 'pathway_choice'` from the tenant, never the literal 10), the reason per pick, the block and ask findings rendered, the slot request | C | O high | | a Wellesmere Year 11 sees no selection form (test) |
| B6.7 | CAS: catalogue, interests captured where used, the ledger, reflections and outcomes, `imported_balance`, `ib.v_cas_totals`, nudges, `CAS_ENTRY`, `CAS_REFLECTION`, `CAS_NUDGE`, `CAS_REVIEWED` | C | O high | | the ledger total equals the prototype's `hrs` and the recent log equals its `entries` (port test) |
| B6.8 | CAS coordinator cohort and detail views; the student activities page and the Diploma core tabs; TOK described only | C | O medium | | the Diploma cohort view never totals with the caseload (a query test that no function returns their union) |
| B6.9 | EE rounds, guides, milestones as data for both reflection models, due dates per year group | C | O high | F | the coordinator picks the guide per round; milestones and their owners render from the round |
| B6.10 | EE state machine E1 to E11 with `ee_stamp_capacity`, wait days, the stalled rule, `EE_PROPOSED`, `EE_SUPERVISOR`, `EE_REFINE`, `EE_PASSED`, `EE_ASSIGNED`, `EE_REFLECTION` | C | O high | **F** | an assignment over the guide succeeds and records it; a proposal is stalled only past `wait_days` |
| B6.11 | Teacher EE queue with load on the card, accept, sharper question, pass to a colleague; the supervision view; reflection recording | C | O high | | `ee_party` scope holds in the authz suite; a teacher sees only essays targeted at them |
| B6.12 | Coordinator aggregate and student essay page; the near-duplicate check; drafts as files with the scan gate | C | O medium | | duplicates are shown to the coordinator only |
| B6.13 | Student EE propose and status pages, reflections view, the nudge | C | O medium | | 375px pass |
| B6.14 | Milestone-overdue events and nudges through the outbox; the coordinator's "drifting" list | C | O medium | | `ee.milestone_overdue` emitted once per milestone per day |
| B6.15 | Accessibility pass; Demo 2 script part two; Wellesmere module-off assertions for every IB screen | C | O medium | | every IB route-state renders on ACS and is absent on Wellesmere |

**Acceptance criteria.** The `selCheck` golden test matches the prototype; the two gates hold at both layers; capacity warns and records; the Diploma cohort and the caseload are never totalled; every IB route-state renders on ACS and is absent on Wellesmere; the EE round runs under either guide. **Done includes** the golden test, the gate tests, the union test, the Playwright flows and the module-off assertions in CI.

### 1.8 B7 · AI

**Status:** not started · **Depends on:** B3 (cases and evidence), B4 (production and the school's acceptances), B5 for the parent draft and the EE feedback, and the written ZDR arrangement before any student-derived generation on a real tenant · **Model:** **Fable 5.1, max effort** for the pseudonymiser and final scan, the validator, the leak scanner, the co-pilot's plan compiler (grammar to parameterised SQL), the quarantined reader and the safety screen's routing; Opus 5.5, high effort for the gateway plumbing, the provider adapter, prompts, envelope builders, screens, the eval runner and reports; the eval judge as pass 5 §10.1 (Opus 5 judges Opus 5.5 outputs; Opus 5.5 judges Sonnet 5 outputs) · **Reviewed by:** Opus 5.5 reviews every Fable piece; Fable 5.1 reviews the prompt constitution and each feature's envelope allowlist
**Why this model:** the mechanisms that keep a child's name inside the country and keep a model's sentence honest are exactly the subtle, expensive, hard-to-see class; the features themselves are mostly plumbing and prose.

**Scope.** Pass 5 §3.0's gateway with its eleven steps as one path in `packages/ai`; the pseudonymiser and the final scan (R4), typed minimisation from `ai.feature_policy.allowed_fields` (R5), `caros_t_ai` (D55), the validator V1 to V10 with one repair round, the canary and its monthly rotation, plain-text rendering; the registry (D62) seeded with the five rows of pass 5 §9.1 including the two rows that exist to be refused; `ai.model_config` (D64) with `active_needs_eval`, `ai.eval_run` (D65), `ai.thread` and the generation columns (D63), `ai.provider_account` (D53, D74) with the evidence fields, `ai.feature_policy` rows all off (D74), the `AI_*` audit actions (D71); the prompt repository layout and the constitution with two `CODEOWNERS` approvals; the Anthropic adapter over the official SDK exposing only `messages.create`, `messages.stream`, `messages.parse` and `messages.count_tokens` (provider-surface test), `inference_geo: "us"` on every call, `cache_control` on the stable layers, no Batch or Files API (R13); the smoke test that structured outputs, `inference_geo`, caching at the feature's prefix length and streaming compose on Opus 5.5 and Sonnet 5 (a 400 here changes pass 5 §3.0.2), and the injection suite's measurement of the two envelope deliveries in the phase's first week (open decision 7); the quarantined reader (D69 columns) and the safety screen's layer 2 with the 400-message corpus, routing, the under-13 gate and the mentor-message hold; then the features in pass 5 §9.6's order: headline rephrase in the sweep's tail, the meeting brief with pre-warming (D67), the co-pilot (threads, plan, execute, write, the coverage rule, `copilot.max_students`, the six promises as assertions), the parent email draft (the parent role's allowlist, the bilingual pair), the Extended Essay feedback (criteria from D70; the coordinator's labels); the discovery model mode lands in B8 when the deterministic flow exists; the eval runner writing `ai.eval_run` and an HTML report, the deterministic tier on every PR touching `packages/ai`, `packages/contracts/ai` or a prompt, the judged tier nightly; the suites and the adversarial profiles of pass 5 §10.2 and §10.3; the cost script `packages/ai/tooling/cost.py`; the daily ceiling, the circuit breaker with the Claude Platform on AWS fallback row (only with its own ZDR evidence, R15), the degraded-mode matrix (every feature has a deterministic result); the labelling sessions with the school scheduled before each feature's acceptance (questions 129, 132, 133); the AI label rendered from the generation row on every surface.

**Tasks (planning estimate: 36 sessions; seven to eight weeks with two people; the school's acceptances decide when each feature runs for real).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B7.1 | Migrations: D53 to D55, D62 to D65, D67, D69, D71, D74; the registry seed with `terms_verified_at`; `ai.feature_policy` rows off; `caros_t_ai` grants and column denials | D | O high | F | the refusal test refuses `claude-fable-5-1` (Covered) and `claude-haiku-4-5` (no geo pin) for every student-derived feature |
| B7.2 | Pseudonymiser: per-generation tokens, directory scan with name history, identifier patterns, the reverse map encrypted per tenant with 30-day expiry, re-identification only at render | D | **F max** | O | the leak scanner runs every envelope builder over both tenants with zero hits; P4's twins produce byte-identical envelopes |
| B7.3 | Validator V1 to V10: citations resolve, token fidelity, coverage, no comparison, no directory string, no URL or markup, one repair round; `AI_OUTPUT_FLAGGED` | D | **F max** | O | a planted out-of-envelope number, a ranking phrase and a canary each fail the validator (tests) |
| B7.4 | Gateway steps 1 to 11 with policy checks, `assertAllowed` before retrieval (the `dependency-cruiser` rule), retrieval under `caros_t_ai` inside the user's transaction, `AI_PROMPT_BUILT` with `input_refs`, storage pseudonymised, `usage.inference_geo` check with `refused_post_hoc` and suspension | D | O high | F | `copilot-scope` test: a plan naming another caseload's student returns zero rows; support cannot run the co-pilot |
| B7.5 | Provider adapter on the official SDK, the surface test, `inference_geo`, structured outputs via `messages.parse`, streaming, cache breakpoints; the smoke test on both models; the prefix-length measurement | D | O high | | the smoke test passes in the staging workspace; the measured prefixes exceed the cache minimums |
| B7.6 | Prompt repository: `_constitution/1.0.0.md`, per-feature templates and changelogs, `prompt_sha256`, the tenant layer with sorted keys; `CODEOWNERS` two approvals on the constitution | D | O high | F | a prompt PR without a version bump, changelog line and `eval_run` id fails the check |
| B7.7 | Eval runner: cases in `packages/ai/evals/<feature>/cases/`, gold before model, splits, the three grader tiers, `ai.eval_run`, the HTML report, CI gating of the deterministic tier, nightly judged tier; the `no-real-data` test extended to the eval directories | B | O high | | a case without gold fails the runner; the judge is never the generator's model (assertion) |
| B7.8 | Quarantined reader: one untrusted text per call, the fixed schema, `extraction` columns, `instructions_to_ai`, the 300-text corpus with 60 injection strings | D | **F max** | O | the corpus bars hold; a hostile teacher note becomes a flag the answer must mention |
| B7.9 | Safety screen layer 2: Sonnet 5 classifier with the schema, synchronous on discovery turns and asynchronous elsewhere, the routing clocks, `means_or_plan_mentioned` immediate route, `cleared_by_model`, the under-13 gate, the mentor hold, the circuit-breaker behaviour; the 400-message corpus reviewed by the safeguarding lead | D | **F max** | O | recall ≥ 0.95 direct, ≥ 0.85 indirect, ≥ 0.98 on `likely` positives; 0 hard negatives at `likely`; the lead agrees with ≥ 28 of 30 dispositions |
| B7.10 | Injection harness: 120 strings planted in every untrusted surface on both tenants; the envelope-delivery comparison; the canary | D | **F high** | O | 0 changed facts, 0 canary leaks, 0 cross-student mentions, 0 actions; the better delivery recorded in the decision log |
| B7.11 | Headline rephrase in the sweep's tail (Sonnet 5), set-equality validation, `headline_generation_id`, "prefer rule wording", the review-first policy option | B | O high | | 200-headline suite: token set equality on every case; the sweep never waits |
| B7.12 | Meeting brief: deterministic body, model synthesis, `MeetingBrief` schema, pre-warming after the sweep, regeneration on dirty facts, `brief_generation_id`, the meetings-view and case-file entry points | D | O high | F (allowlist) | 46-case suite; the opening line contains no fact token; the note-body policy defaults to excluded |
| B7.13 | Co-pilot: `ai.thread`, the plan call, the grammar compiler to parameterised SQL, the cap, the write call, `CopilotAnswer`, the coverage rule, the fixed ranking refusal, `COPILOT_QUERY` and `CASELOAD_VIEW`, the screen (`vCopilot` port with the boundaries card as tests) | D | **F max** (compiler) / O high (rest) | O / F | the 150 + 60 + 40 suite; the six promises hold; nothing the model emits is executed as SQL (test) |
| B7.14 | Parent email draft: the parent-role allowlist envelope, `ParentDraft`, promise-word list, length, the bilingual pair, consumption into `family.message` in-app, `PARENT_CONTACT` | D | O high | F (allowlist) | the 120-case suite; no fact outside `facts_used`; nothing enters the outbox |
| B7.15 | Extended Essay feedback: `EEFeedback`, criteria citations from the round's guide, never a rewritten question, `feedback_generation_ids`, the coordinator's visibility | C | O high | F | the 160-case suite labelled by the coordinator; an eight-word quoted candidate question is refused |
| B7.16 | Failure handling: timeouts per feature, the circuit breaker and the fallback account with R15 evidence, the daily ceiling with the 80% and 100% behaviours, the safety exemption, refusal and validator rate alarms, the degraded-mode matrix rendered as banners | D | O high | | each row of the matrix has a test that flips the failure and asserts the screen's behaviour |
| B7.17 | Cost script, `cost_usd` on every generation from the registry, the school's monthly AI line, the 14-day cost-anomaly alert, the registry-age alarms | D | O medium | | the script reproduces pass 5 §11.3 within rounding |
| B7.18 | Promotion protocol tooling: terms check, shape smoke, suite at neighbouring efforts, sign-off fields, `AI_MODEL_SWITCHED`, the 14-day watch with automatic rollback | D | O high | | a promotion without a passing `eval_run` is refused by `active_needs_eval` |
| B7.19 | Labelling sessions with the school (questions 129, 132, 133) and the human samples; the per-feature acceptance records (`school_accepted_residual_retention_at`) | D | none | | each feature's 30-item sample is rated before its policy row is enabled |
| B7.20 | Demo 3 preparation on synthetic data: every feature with its label, evidence panel and "built from N records" line | D | none | | the demo runs with the AI on against the synthetic tenants only |

**Acceptance criteria.** Pass 5 §10.4's bars hold for every shipped feature; the leak scanner and injection zeros hold; the provider-surface, schema-hygiene, refusal and `copilot-scope` tests pass; the smoke test passes on both models; no feature runs on a real tenant until its policy row is enabled by the school in writing, the ZDR evidence is recorded and its eval run is signed; the degraded-mode matrix is tested row by row. **Done includes** every suite in pass 5 §10.2 with its runner in CI (deterministic tier per PR, judged tier nightly) and the human samples recorded in `ai.eval_run`.

### 1.9 B8 · Discovery, mentors, reporting

**Status:** not started · **Depends on:** B5 (student surfaces, safety layer 1), B7 for the discovery model mode and the mentor classifier hold · **Model:** Opus 5.5, high effort; **Fable 5.1, max effort** for mentor credentials (passkeys, the password-plus-TOTP fallback), the pairing controls and the message holds (an adult in contact with a minor), and Fable reviews the discovery approval gate and the XP single-writer rule · **Reviewed by:** the other model
**Why this model:** the discovery flow is a port of code that runs today; the mentor path is the one place an outsider adult reaches a child, and its credential and hold logic must be right the first time.

**Scope.** Discovery: `discovery.*` with D66, `ref.discovery_question` (folding `ref.onboarding_question`), `ref.archetype` version 1 and `ref.archetype_claim` with D73's kinds and verification (a sentence with an unsourced claim does not render; the Stanford GSB undergraduate claim removed; named programmes and medical durations hidden until sourced); `packages/discovery` as a pure package with the ported scorer, goal classifier, queue and the differential tests; the survey with a real "skip for now", the chat in deterministic mode with canonical questions and keyword extraction, narrowing, the analysis page with the honest flat-profile text and the alumni precedent counts under small-cell suppression (from `uni.destination` when the school supplies it), proposals and submission (P1), the counselor approvals screen with approve, amend inline and send back with structured reasons that become constraints (P2 to P6), approved pathways with the roadmap snapshot, roadmap progress and `xp_ledger` written only by the discovery module (P7, invariant 10), the celebration on the student side only; then the model mode of pass 5 §3.4 and §3.5 (tag extraction, the phrased next question, `PathwayAnalysis`, the synchronous safety screen, `paused_safety`) behind `feature_policy.discovery_chat` and `pathway_analysis` with R8 acceptance and the under-13 gate, and the differential evals P1 to P10. Mentors: `mentor.*` with D40 and D57; the `mentor_coordinator` screens (vetting record with expiry, invitations, pairings arranged by the school, held messages); the mentor identity path (7-day invitation, passkey, the fallback of a 12-character password checked against the Pwned Passwords range API and stored with Argon2id plus mandatory TOTP, 12-hour and 30-minute sessions); the student's find-a-mentor and network pages, the mentor's requests and mentees pages, append-only messages with the pattern hold and, with B7, the classifier hold, twenty messages a day per student, scheduled sessions with no recording, the parent's "a pairing exists" line; consent recorded on the pairing. Reporting: `reporting.mv_*` refreshed after the sweep; the `prove` page from `events.event` with the four metric families and an honest "not enough events yet" state, never a target shown as a measurement; the `pilot` page; the two ADEK guidance indicators (student coverage, counselor-student ratio) for the school's annual report; the school's monthly report (head hash, grants, rotations, AI lines); the per-teacher concern-rate report for the `caseload_lead` only.

**Tasks (planning estimate: 26 sessions; five weeks with two people).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B8.1 | Migrations: `discovery.*`, D66, `ref.discovery_question`, `ref.archetype` and claims with D73 columns; `mentor.*`, D40, D57; `reporting.mv_*` | C | O high | F | registry, RLS and matrix tests extend; only the discovery module can write `xp_ledger` (grant and boundary test) |
| B8.2 | `packages/discovery`: scorer, goal classifier, queue, the "enough signal" rule, differential and deterministic-mode tests | C | O high | | P3's twins differ in exactly one tag; P1 ends with `ranked_archetypes = null` |
| B8.3 | Survey with skip, deterministic chat, narrowing, the analysis page, precedent counts with suppression, submission | C | O high | | Playwright on both tenants; a bank question naming IB is absent on Wellesmere |
| B8.4 | Counselor approvals: approve, amend inline, send back with structured reasons, regeneration under constraints, `PATHWAY_*` audit | C | O high | **F** | send-back without reasons is refused at both layers; the regenerated analysis differs from the previous one |
| B8.5 | Roadmap, progress, XP once per step, the celebration on the student surface only | C | O medium | F | a second completion awards nothing; no XP code exists outside the discovery module (boundary test) |
| B8.6 | Discovery model mode: tag extraction, phrased questions, `PathwayAnalysis`, the synchronous safety screen and `paused_safety`, the evals P1 to P10 | C | O high | F | the discovery suite bars of pass 5 §10.4 |
| B8.7 | Archetype claims: kinds, sources, verification status, `safe_text`; the render rule; the removal list from pass 5 §2.5 | C | O medium | | an unverified claim never renders (DOM test) |
| B8.8 | Mentor identity: invitation, passkey registration and assertion, the password-plus-TOTP fallback, sessions, `MENTOR_INVITED` | D | **F max** | O | a breached password is refused; TOTP is mandatory on the fallback; recovery only by re-invitation |
| B8.9 | Vetting record and expiry, pairings arranged by the school, `share_scope`, ending a pairing, `PAIRING_ENDED` | D | **F max** | O | `active` requires `verified` and an arranger; a mentor sees only paired students' name, year and goal (column tests) |
| B8.10 | Messages append-only with the pattern hold, the coordinator's held-message review, the rate limit, thread visibility to counselor, coordinator and lead with the header line; sessions with no recording | D | **F high** | O | a message with a phone number is held; the thread header names who can read it |
| B8.11 | Student find-a-mentor and network pages; mentor requests and mentees pages; the parent's pairing line | C | O medium | | no email or phone column exists in `mentor.*` (schema test) |
| B8.12 | Reporting: materialised views refreshed after the sweep, the `prove` page with the four families and the honest empty state, the `pilot` page, the ADEK indicators, the monthly school report, the teacher concern-rate report for the lead | D | O high | | no figure on `prove` comes from anything but `events.event`; the page says "targets, not measurements" until events exist |
| B8.13 | Demo 3 script; accessibility pass on the new surfaces | C | O medium | | the script runs; axe passes at 375px |

**Acceptance criteria.** The approval gate holds at both layers; XP has one writer; the flat profile ends honestly; the mentor path passes its credential, column and hold tests; reporting shows only computed figures. **Done includes** the discovery differential tests, the mentor identity tests, the boundary tests and the reporting tests in CI.

### 1.10 B9 · Connectors, second school, scale

**Status:** not started · **Depends on:** the pilot's four green weeks (pass 2 §9 step 16); ACS's answers to questions 77 and 81 for the adapter order; pass 4 §6.6 and question 14 before the Classroom adapter runs for a real tenant · **Model:** Opus 5.5, high effort; **Fable 5.1 reviews** every adapter's `verify()` (write-scope detection) and credential handling, and the isolated-deployment rehearsal · **Reviewed by:** Fable 5.1 on those; Opus 5.5 elsewhere
**Why this model:** adapters are I/O against documented APIs; the one subtle failure is a token that can write, which `verify()` must catch.

**Scope.** `VeracrossDataApiConnector` (OAuth client credentials with list and read scopes only, `on_or_after_update_date` cursors, the 1-request-per-second and 3,000-per-night assumptions read off the real page at onboarding, the NAT egress IP), `ManageBacConnector` (read-only token, `/v2p2/auth/permissions` must list no write-capable resource, `modified_since`), `GoogleClassroomConnector` (the school-created reader account under domain-wide delegation, read scopes, nightly polling, the engagement domain's seven conditions), in the order ACS's answers dictate; `ISAMSBatchConnector` (XML to envelopes) for the second school; the OneRoster profile family; the Maia CSV profile run weekly by a counselor; the `uni.destination` import for alumni counts; auto-approve policies per source with the security-section rule; connector runs, cursors, `CONNECTOR_VERIFIED`, `CREDENTIAL_ROTATED`; the second real school onboarded with a CAROS human at steps 1, 2, 8, 11, 14, 15 and 19 only (pass 2 §9), measured as under three profile versions per import kind before four green weeks; the isolated single-school deployment rehearsed once from the same module with `deployment_mode = "single"` so the promise is real before a school asks; the year-1 items: PostgreSQL 18 review once the extension list is clean, Drizzle 1.0 after two GA minor releases, `apps/api` (Hono and `@hono/zod-openapi`) only when a non-TypeScript caller exists, the PgBouncer transaction-pooling test in the RLS suite before any pooler, the in-country inference review with counsel's C3 and the eval scores (pass 5 open decision 1), Sonnet 5.5 and Haiku 5.5 as `candidate` rows through pass 5 §9.5, SOC 2 Type I within six months of the first real record then Type II, ISO/IEC 27001 within twenty-four (timing assumptions, pass 4 §9.12); the letter engine's generation stays deferred until real letters exist to draft and time and counsel has answered C20.

**Tasks (planning estimate: 28 sessions; spread over the pilot's second term and year 1).**

| # | Task | Owner | Model | Rev | Done when |
|---|---|---|---|---|---|
| B9.1 | Connector runtime: `RateLimitedHttp`, run budgets, cursors, JSON Lines raw artefacts, pause after three failures, the Studio's connector screens, credential rotation with re-verify | A | O high | F | a run whose budget is spent ends `partial` and advances only completed resources |
| B9.2 | Veracross Data API adapter with `verify()` refusing write scopes; field bindings read off the real pages at onboarding | A | O high | F | a token with a write scope fails `verify()`; the ACS weekly pack becomes a nightly connector without a profile change |
| B9.3 | ManageBac adapter with the permissions check; the CAS and EE record-system decision applied per school (D10) | A | O high | F | a token that can write fails `verify()` |
| B9.4 | Google Classroom adapter under the seven conditions; the engagement module flag; the engine's `occurred_on` read | A | O high | F | no time-of-day column is readable by the engine (test) |
| B9.5 | iSAMS Batch adapter (XML to envelopes) and the OneRoster profile family; the Maia CSV profile; `uni.destination` | A | O high | | the Wellesmere fixture also imports through the XML path |
| B9.6 | Second real school onboarding with the runbook; the profile-version metric | D | none | | a human at the seven steps only; under three profile versions per kind |
| B9.7 | Isolated single-school deployment rehearsal in a throwaway subscription from the same module | D | O high | F | the app refuses to start with two active schools in `single` mode; RLS unchanged; torn down after the drill |
| B9.8 | Year-1 platform items: PostgreSQL 18 review, Drizzle 1.0, the PgBouncer test, `apps/api` if a caller exists | D | O high | F (PgBouncer) | each has a decision record |
| B9.9 | Certification work: SOC 2 Type I evidence from the CI control list and the runbooks; the audit firm engaged | D | O medium | | the Type I report within six months of the first real record (assumption) |

**Acceptance criteria.** Each adapter passes `verify()` against a token with write reach (negative test) and pulls its fixture into the same pipeline as a file; the second school onboards at the target; the isolated deployment rehearsal passes the RLS suite as one tenant. **Done includes** the adapter tests, the isolation rehearsal record and the year-1 decision records.

### 1.11 The pilot overlay

The pilot is not a phase; it is a sequence of the school's own steps laid over B4 to B7, gated by G-REAL at its start and G-LIVE in its middle. Weeks are counted from G-REAL and are planning assumptions; pass 2 §9 gives the twenty steps and pass 3 §14 the shadow protocol.

| Week | What happens | Gate or output |
|---|---|---|
| 0 | G-REAL passed (§1.5). Onboarding steps 1 to 9: agreement and DPA with the data delivery schedule as `ingest.expected_cadence`; the discovery call; the tenant created `real` and `onboarding`; the school's Workspace admin sets CAROS to Limited, confirms the under-18 designation, registers the RISC receiver; the first `school_admin` and `caseload_lead`; the calendar entered and confirmed; the pseudonymised sample; profiles version 1 on the samples; the delivery path (upload, SFTP or, later, a connector) verified | the tenant stays `onboarding` until the legal-basis attestation is recorded |
| 1 to 2 | Steps 10 to 13: full historical backfill oldest first (two academic years where ACS has them, question 83); the data-quality review; identity checks (three staff and two students sign in and land on their persons; Classroom `userId` against OIDC `sub`); caseload assignments and the cover policy | previews approved by the school's `school_admin` |
| 2 | Step 14: ACS's `engine.thresholds` and `engine.tiering` version 1 from the elicitation (B4.16) activated **in shadow**; step 15: the first backfill sweep and the retrospective validation report; **the backtest** (pass 3 §15.2) over the two years of history if the counselors' dated handled-case records exist, otherwise recorded as not possible | the backtest report and a proposed first configuration, or a written statement that history cannot carry it |
| 3 onward | Step 16: weekly packs arrive; the `school_admin` approves every preview for four weeks, then auto-approval per policy for the kinds the school agrees; teacher rollout (step 18): flags are live throughout shadow because the inbox needs no engine; the counselor log begins (thirty seconds a day); no tiers are visible | **four green weeks** gate auto-approval and the connectors (B9) |
| 6 and 10 | Reveal sessions at the end of shadow weeks 4 and 8 (pass 3 §14.4): engine-only students walked through with the evidence chain; counselor-only students classified `data_gap` or `engine_miss`; threshold changes become new **shadow** versions | the comparison report (B4.15) per counselor and per school |
| 6 to 12 | B5 and B6 land on production behind their module flags; students sign in once B5 gives them something to see; parents once guardian links are verified and activation codes are handed out through the school's chosen channel (question 124) | Demo 2 for ACS leadership on the real tenant with real data only for staff who already hold it |
| 8 to 12 | Shadow exit when pass 3 §14.5's six criteria hold: at least six weeks of weekly data; precision at or above the counselors' bar (default 60% at check-in and above, 25% at review); every miss classified and answered; no unexplained fairness trigger; four weeks of on-time sweeps; the four counselors agree with disagreements recorded | **G-LIVE**: the `caseload_lead` activates the first live version; steps 19 and 20; `core.school.status = 'active'`; the first live nightly sweep; the marker is off because the tenant is `real` |
| after G-LIVE | The counselor log continues one more term; B7's features are switched on one at a time as the school accepts each in writing and its eval run is signed, in pass 5 §9.6's order, and only after the ZDR arrangement is recorded; the fairness screen runs at shadow exit and quarterly | **G-AI** per feature |
| second term | Connectors after the four green weeks in the order ACS's answers dictate (B9); the counselor log's second term ends; the first monthly reports carry real reporting figures | |

Two things the overlay makes explicit. **The pilot can run for months with the AI off and lose nothing that makes CAROS CAROS** (pass 4 §6.1); the shadow period is that time. **The demonstration marker has two real branches**: it is on for the synthetic ACS tenant used in demos and training, and off for the real one; the two are different tenants, and the classification trigger stops either from becoming the other.

### 1.12 The migration map

The D-numbers of passes 2 to 5 land once each, in the phase named here. File names are illustrative; the sequence within a phase is the pass's own order unless a dependency forces otherwise. Every migration is a pull request reviewed as SQL (pass 1 DR-2), and `drizzle-kit check` guards the history against two branches generating in parallel ("extremely useful when you have multiple developers working on the project and altering database schema on different branches", [drizzle-kit check](https://orm.drizzle.team/docs/drizzle-kit-check)).

| Phase | Migrations | Creates or changes | D-numbers landed |
|---|---|---|---|
| B0 | `0001_b0_roles_extensions`, `0002_b0_spine`, `0003_b0_policies`, `0004_b0_seed_global` | roles including `caros_migrator`; the 19 schemas; the spine tables of §1.1; `auth.protect()`, `auth.allowed()`, the helpers; global seeds (`auth.data_class` with sensitivity and pass 3's three classes, `auth.role`, `auth.capability`, the matrix, `audit.action` with every key from passes 1 to 5, `events.name` with every key, `privacy.retention_class` with every proposal, `notify.template` versions, `config.vocabulary` platform defaults with attribute schemas, `ref.grade_scale`) | D7, D8, D9 (keys), D14, D27, D28, D30, D33, D34, D35, D36, D37, D38, D39, D44, D47, D48, D49, D50, D71 (keys); D15 is subsumed by the matrix rows of pass 4 §3.6 and is not applied separately |
| B1 | `0005_b1_record`, `0006_b1_ingest`, `0007_b1_views` | the `sis` record tables, `engagement.activity_event`, `family.guardian_link`, `core.person_name_history`, `core.person.match_key`, `sis.section_meeting`; `ingest.*` complete; `sis.v_current_*`, `sis.v_attendance_teacher` | D1, D2, D3, D4, D5, D6, D12, D13, D16 (registry entries and tests), D42, D56, D59 |
| B2 | `0008_b2_signal`, `0009_b2_config_engine`, `0010_b2_fairness` | `signal.*` except `escalation`; the engine deltas; `signal.counselor_log`, `signal.v_shadow_queue`; `core.school.sweep_hour`; `sis.student.processing_restricted_domains`; `fairness.group_label` with no application grant; the engagement module flag | D17, D18, D19, D20, D21, D22, D23, D24, D25, D26, D29, D31 (schemas in the package), D32, D58, D60 |
| B3 | `0011_b3_escalation`, `0012_b3_cover_contact` | `signal.escalation` restructured, `core.school` safeguarding columns and route history, the legal-basis column (its trigger in B4), `auth.caseload_assignment` cover columns, `family.contact_log` | D43, D45 (columns), D46 |
| B4 | `0013_b4_privacy`, `0014_b4_gates` | `privacy.notice_version`, `notice_ack`, `sar_request`, `processing_restriction`, `erased_external_identity`; the attestation trigger; retention numbers reconfirmed | D45 (trigger), D51, D52 |
| B5 | `0015_b5_ref`, `0016_b5_uni`, `0017_b5_family`, `0018_b5_safety` | the remaining `ref.*` with `ref.admission_statistic`; `uni.*` with D11 and D72; `family.message`, `meeting_slot`, `meeting_request`; `auth.activation_code`; `signal.safety_alert`; the `uni.classification` rule-set kind; the forbidden-column additions | D11, D41, D68, D72, D73 (except the archetype columns) |
| B6 | `0019_b6_ib`, `0020_b6_ee_guides` | `ib.*`; `ref.ee_guide`, `ref.ee_criterion`, the round's guide key, `feedback_generation_ids`; D10's keys in use | D10, D70 |
| B7 | `0021_b7_ai_registry`, `0022_b7_ai_tier`, `0023_b7_ai_features` | `ai.model`, `ai.provider_account`, `ai.feature_policy`, `ai.thread`, `ai.eval_run`; the generation columns; `caros_t_ai`; `core.meeting.brief_generation_id`; the extraction columns | D53, D54, D55, D62, D63, D64, D65, D67, D69, D74, D75 (tests) |
| B8 | `0024_b8_discovery`, `0025_b8_mentor`, `0026_b8_reporting` | `discovery.*`, `ref.discovery_question`, `ref.archetype` and claims with the D73 columns; `mentor.*`, `auth.credential`, the vetting and hold columns; `reporting.mv_*` | D40, D57, D66, D73 (archetype columns) |
| B9 | `0027_b9_destination` and adapter-specific config only | `uni.destination`; no new tenant tables for the adapters (`ingest.connector_run`, `source_cursor` exist since B1) | none |

Three deviations from the passes' own numbering, each for a dependency: D11 (columns on `uni.*`) waits for the `uni` tables in B5; D15's permission row is part of the matrix seed in B0; D56 lands with the table it alters in B1, and D58 and D60 with the engine that reads them in B2. The revision pass should record these in the D-tables of passes 2 to 5.

### 1.13 The thin slice as proposed, and what this pass changes

The prompt's thin slice is right about content and this pass keeps every item in it. It changes four things, openly.

1. **It is four phases, not one.** Tenancy, identity, ingest, the engine and sweep, the queue, the file, the teacher loop, audit and the escalation are about a hundred agent sessions. A phase with no checkable "done" for three months is how documentation drifts and how a bad merge goes unnoticed for weeks. B0 to B3 each end in something a second person can verify.
2. **It grows by five items the passes showed are not optional.** The Mapping Studio (the seed cannot run without a profile, pass 2 DR-11); the counselor log and the shadow view (the pilot's first phase is shadow mode, pass 3 §14); the support console (onboarding runs through a grant, pass 4 §3.7); the RISC receiver (deprovisioning within seconds is what makes "suspend the Google account" the school's kill switch, pass 4 §2.1); the CPO's acknowledgement screen (an email that says "sign in to acknowledge" without a screen to acknowledge on is a false promise, pass 4 §5.3).
3. **"Identity" in the slice means staff.** Students sign in through the same path but have nothing to see until B5; parents need an activation flow that is B5's; mentors are B8's. Building the parent and mentor paths in the slice would delay Demo 1 by the two riskiest identity pieces for no demo.
4. **The first demoable build does not wait for the engine to be finished.** Pass 1 DR-8's narrative seed layer exists so the screens can be built and shown before the engine is; B3 is built against it, and B2's `engine-reproduces-seed` retires it. Demo 1 (§6.5) is shown with the real engine because B2 lands before B3 ends, but nothing in the plan depends on that ordering.

One thing the prompt's list implies and this pass does not do: it does not put the nightly sweep's operations (alerting, the watchdogs, on-call) after the slice. They are inside B2's definition of done, because a sweep nobody is told about has not been built.

---
## 2. Parallel workstreams

### 2.1 Four streams and their ownership

Pass 1 DR-3 fixed the package ownership and §4 the module ownership. This pass turns them into four streams. The assignment of Faisal, Qasim and Taha to A, B and C is Davide's call and depends on their availability and skills, which this pass does not know; the streams are defined so that any assignment works and so that two of them can be one person if it must (§2.5).

| Stream | Person | Owns (packages, modules, screens) | Starts | Busiest in |
|---|---|---|---|---|
| **D · spine** | Davide | `packages/db`, `packages/contracts` (as the second approver), `apps/worker`, `infra/`, the `tenant`, `identity`, `signals` (domain and screens), `notify`, `audit and reporting`, `privacy` modules, `packages/ai` gateway, `packages/ui` and the app shell, `docs/` | B0 week 1 | every phase; the only stream in B0 and B4 |
| **A · facts** | teammate A | `packages/ingest`, the `record` module and its read functions, the Mapping Studio, the fixtures, the teacher register (B3.14), the SFTP watcher, the connectors (B9) | B0 week 2 (fixture generators against the contracts) | B1, B9 |
| **B · engine** | teammate B | `packages/engine`, the calibration scripts, the thresholds screen, the counselor log and shadow tooling, the comparison report, the eval runner (B7.7), headline rephrase | B0 week 2 (the pure package needs only `packages/contracts`) | B2, B4, B7 |
| **C · programmes** | teammate C | the `university`, `ib`, `discovery` and `mentor` modules (domain and screens), the reference-data tool, the EE feedback feature | B1 (its domain code can start once the record tables exist) | B5, B6, B8 |

Rules that keep the streams apart, all enforced by tooling rather than memory: a stream edits only its own packages and its own folders under `packages/domain/<module>`, `packages/api/<module>` and `apps/web/app/(role)/<module>`; cross-module reads go through the other module's `index.ts` (the `dependency-cruiser` rule of DR-3 fails the build otherwise); `packages/contracts` changes need two approvals and are proposed by the stream that needs them and merged before the work that uses them; `packages/db/migrations` accepts a migration from any stream in its own schema, reviewed by D, one migration per pull request, `drizzle-kit check` in CI; `packages/ui` is D's, and a screen that needs a new primitive proposes it there first.

### 2.2 Contracts and integration points

Every seam between streams is a typed artefact in `packages/contracts` with a test that proves both sides honour it. The six seams:

| Seam | Producer → consumer | The contract | The test that proves it | Phase |
|---|---|---|---|---|
| Envelopes | A (`packages/ingest`) → A (`record`) | `CanonicalEnvelope<K>` and `CanonicalRecord[K]` Zod schemas; natural keys per kind (pass 2 §3.4, §7.1) | `fixtures.spec.ts` against `expected.json`; the `sis.v_current_*` views' row counts after commit | B1 |
| Facts to the engine | A (`record`) → B via D's loader | `StudentEvaluationInput` (pass 3 §13.1): per-domain `as_of`, calendar, sections, series, events, university rule outputs, case state, configuration | `packages/domain/signals/test/load.spec.ts`: the loader over both fixtures produces inputs that validate against the schema; `engine-reproduces-seed` end to end | B2 |
| Engine to signals | B (`packages/engine`) → D (`signals` writer) | `EvaluationResult` with drafts for snapshots, signals, evidence, suppressions, rule hits and the proposal; `inputHash` | the writer's replay test (an upsert, no duplicates); S23 | B2 |
| Signals to notify | D (`signals`) → D (`notify`) | outbox rows with `template_key`, `template_version`, `dedupe_key`, identifiers-only payloads validated per template | `packages/notify/test/templates.spec.ts`; the outbox dedupe test | B3 |
| Server to browser | every module's `packages/api` router → `apps/web` | the inferred tRPC router type; no hand-written client type; procedures validate with the `contracts` schemas | the type check itself; Playwright per screen; the `'use server'` lint rule (no Server Actions for mutations) | every phase |
| Records to the model | every module's read functions → D (`packages/ai`) | the per-feature envelope builders with accessors generated from `ai.feature_policy.allowed_fields` (an out-of-allowlist field is a compile error) | the leak scanner over both tenants; `envelope-allowlist`; `schema-hygiene` | B7 |

Two more seams are contracts by convention rather than by type: the rule-set parameter schemas (`packages/engine/schemas/*.schema.json`, D31) that the thresholds screen (B) and the domain layer (D) both read, and the audit `detail` schemas (`packages/contracts/audit/`, D48) that every module writes against.

### 2.3 What proceeds concurrently

A planning calendar in weeks from the first commit, on the assumption of Davide full time and three teammates part time. It is a picture of dependencies, not a promise.

| Weeks | D · spine | A · facts | B · engine | C · programmes |
|---|---|---|---|---|
| 1 to 3 | B0: repository, CI, Terraform, spine, tenancy, UI kit, docs, week-one items | fixture generators against `packages/contracts` (B1.9 start) | `packages/engine` series and band, detectors (B2.1 to B2.3) | reference-data curation tool design; reads the passes |
| 4 to 9 | B1 identity (B1.13 to B1.16); B2 loader, writer, sweep jobs (B2.10 to B2.13) | B1 pipeline, Studio, record reads (B1.1 to B1.12, B1.17, B1.18) | B2.4 to B2.9, B2.15, B2.16 | `uni` and `ib` domain functions against the record tables (B5.3, B5.4, B6.2, B6.3 early, no screens) |
| 10 to 16 | B3 signals domain, escalation, outbox, screens (B3.1 to B3.13, B3.15 to B3.18) | B3.14 teacher register and flag modal; B4.9 SFTP; connector runtime design | B2.17 staging nights; B4.15 comparison report; the calibration write-up | B5 domain and reference data (B5.1 to B5.7) |
| 17 to 21 | B4: privacy tooling, production, drills, review pack, pen-test fixes, runbooks, on-call | B4.12 onboarding tooling with D | B4.16 elicitation with D; backtest tooling | B5 screens (B5.8, B5.9), B6.1 to B6.8 |
| G-REAL | onboarding steps 1 to 15 with the school (D and A); shadow begins | | backtest if history exists | |
| 22 to 30 | B5 parent identity and portal (B5.10 to B5.13); B7.1 to B7.6, B7.8 to B7.10 (the AI mechanisms, no features) | B9 connector runtime after four green weeks | B7.7 eval runner; B7.11 headline rephrase | B6.9 to B6.15; B5.14; B8.1 to B8.5 |
| G-LIVE | first live sweep | | reveal sessions, shadow exit numbers | |
| 31 to 40 | B7 features in order (B7.12 to B7.20); B8 mentors (B8.8 to B8.11); B8.12 reporting | B9 adapters in the order ACS dictates | B7 evals per feature | B8 discovery (B8.2 to B8.7), B7.15 EE feedback |
| year 1 | B9 platform items; certification; the isolated-deployment rehearsal | second school's connectors | model candidates through the promotion protocol | second school's programmes |

The integration points where streams must meet, and when: the `contracts` for envelopes and the engine input (week 1 to 2, D writes them from passes 2 and 3 so A and B can start); the loader (week 6, D and A); `engine-reproduces-seed` (week 9, A's fixtures, B's engine, D's writer); the teacher flag's event evaluation (week 12, A's modal, D's `sweep.event`, B's corroboration rule); the thresholds screen's what-if (week 9, B's engine, D's snapshots); the escalation's outbox (week 13, D only); the record tabs on the case file (week 11, A's read functions in D's screen); the classification recompute in the sweep (week 15, C's rule in D's `sweep.finalize`); the envelope builders (weeks 22 to 30, every module's read functions into D's gateway).

### 2.4 Branch and review discipline

The failure this repository has already suffered was a merge that replaced a file wholesale and a documentation set that described a build that no longer existed. The discipline below makes both structurally hard, and every rule is a machine check, not a request.

**Repository shape.** Many small files, one concern each; no file over 800 lines except generated ones (a lint rule); generated files (`packages/db/migrations/meta/`, the tRPC types, the generated docs) are never hand-edited (a CI check regenerates and diffs).

**Trunk and branches.** One long-lived branch, `main`. Every change on a short-lived branch named `<stream>/<phase>.<task>-<slug>` (for example `a/b1.6-commit-chunks`), living days not weeks. Squash merge only, so `main` has one commit per pull request and a linear history. Agent sessions run in git worktrees, one session per worktree (`claude --worktree <name>` creates an isolated checkout, [Claude Code worktrees](https://code.claude.com/docs/en/common-workflows)); two sessions never share a working copy.

**The ruleset on `main`** (GitHub rulesets, a Team-plan feature): require a pull request; require the `ci` checks listed in §5.8 to pass; require review from code owners; dismiss stale approvals on new commits; require conversation resolution; require linear history; block force pushes; restrict deletions; require deployments to succeed is not used (deploys follow merges). The branch-protection option list is GitHub's ([about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)). No one, including the organisation owner, is exempt from the ruleset on `main`; the bypass list is empty.

**`CODEOWNERS`.** One owner per stream's paths; two required approvals on `packages/contracts/**`, `packages/db/migrations/**` when the migration touches `audit.*` or `auth.*` (pass 4 §4.2), and `packages/ai/prompts/_constitution/**` (pass 5 §9.2); the engine builder owns `packages/engine/**`; D owns `infra/**` and `packages/db/**`. An approval from any listed owner satisfies the requirement ("an approval from any of the owners is sufficient", [about code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)), so the two-approval paths are enforced by the ruleset's approval count on those paths, not by `CODEOWNERS` alone.

**The wholesale-replacement check.** A CI job (`tooling/ci/wholesale.ts`) computes, for every file changed in the pull request, the share of its lines that are deleted and re-added. A file over 200 lines whose diff replaces more than 60% of it fails the job unless the pull request carries the label `wholesale-rewrite` and a one-line reason in its description. The label is applied by a human, never by the agent (a hook refuses `gh pr edit --add-label wholesale-rewrite` from an agent session). This is the check that would have caught commits `0daf069` and `c045a6f`.

**Conflicts.** An agent never resolves a merge conflict by taking one side of a file wholesale; `CLAUDE.md` says so and the wholesale check enforces it. A conflicting branch is rebased by its owner in a session whose only task is the rebase, with the conflict list in the brief.

**Migrations.** One migration per pull request; `drizzle-kit generate` output reviewed as SQL; hand-written policy SQL in the same numbered sequence; `drizzle-kit check` in CI; a merged migration is immutable (a hook refuses edits to any file under `packages/db/migrations/` that exists on `main`; a correction is a new migration); expand-and-contract with the drop two releases later (pass 1 DR-9); `drizzle-kit push` refused by a hook unless `DATABASE_URL` points at `localhost`.

**Reviews.** Every pull request is reviewed by a person other than its author, and, for the tasks marked in §4.3, by a model other than the one that wrote it (the review session's brief names the model and attaches the diff). A review that changes the pull request's scope is a new task. The pull request template carries: the task id from `docs/PLAN.md`, the model and effort used, the tests added, the acceptance line it satisfies, and "docs touched" with the `PLAN.md` line.

**Secrets and data.** No secret in the repository (gitleaks in CI, push protection on); no real tenant data anywhere in the repository or in CI (the `no-real-data` test; CI runs on GitHub-hosted runners, which GitHub hosts "on virtual machines in Microsoft Azure" with no region choice, [about GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners), so CI must never hold anything that is not synthetic); no agent session ever holds a support grant or a production credential (`CLAUDE.md`, and the support console rejects an automation user agent).

**Releases.** A release is a tag `vYYYY.MM.DD-n` on `main` after a staging soak (§7.1); the changelog is generated from the squash commits' pull-request titles, so the title is the changelog line.

### 2.5 If there are only two people

The streams are defined so that the plan degrades rather than breaks. With Davide and one teammate: the teammate takes A in B1 and C from B5, Davide takes D and B (the engine is Fable 5.1's work with Davide reviewing; the loss is the independent human eye on the statistics, replaced by the Opus 5.5 review and the calibration scripts); B2 and B1 no longer overlap fully, which pushes Demo 1 out by roughly the length of B2's engine tasks (planning assumption: four to five weeks); B5 and B6 are sequential, so Demo 2 moves by about six weeks. With Davide alone, the order is B0, B1, B2, B3, B4 strictly in sequence, Demo 1 at roughly week 20 rather than 14, and B5, B6, B7 and B8 each a quarter; the plan file, the contracts and the tests keep their value because they are what lets one person put work down and pick it up.

---
## 3. Working with a coding agent across many sessions

### 3.1 Session-sized tasks

A session is one task from `docs/PLAN.md`, two to four hours, one worktree, one branch, one pull request. The task tables in §1 are the first cut; `PLAN.md` carries the live list and each task's **brief**. A brief is short and answers five questions, in this order, because the agent reads it before anything else:

```
### B3.4 · Escalation: raise, route, reference, outbox rows
Stream: D · Model: Fable 5.1, max · Reviewer: Opus 5.5 · Attempts: 0 · Status: ready
Reads first: docs/spec/04-security-privacy-compliance.md §5.1 to §5.3; docs/decisions/DR-14-escalation.md;
             packages/contracts/audit/ESCALATED_SAFEGUARDING.json; packages/domain/signals/README.md
Produces:    packages/domain/signals/escalation.ts (raise), packages/api/signals/escalation.ts,
             migrations/0011_b3_escalation.sql (D45 columns, D46), packages/domain/signals/test/escalation.spec.ts
Done when:   UNIQUE (school_id, case_id) holds and the API returns 409 on a second raise;
             the form refuses observed < 40 and why_now < 20 characters; step-up within 10 minutes is required;
             one transaction writes the escalation, the case move to urgent/act, one outbox row per order-1 recipient,
             ESCALATED_SAFEGUARDING with identifiers only, and case.escalated; names never appear in audit.entry (test);
             the Wellesmere tenant uses "Designated Safeguarding Lead" in every string (test)
Out of scope: reminders and the 24-hour banner (B3.5); the acknowledgement screen (B3.6); the email template (B3.8)
Updates last: PLAN.md status and attempts; docs/decisions if a decision was made; the PR template fields
```

Rules for briefs: a task that cannot be described in this shape is two tasks; "done when" lists checks, never adjectives; every task names the spec sections it implements so that the pass outputs stay the specification and the code stays the truth; the brief is written by the stream owner before the session, and a session that finds the brief wrong stops and rewrites the brief rather than the scope.

**The attempt counter.** `Attempts` counts sessions that ended with the task not done (acceptance still red, or the reviewer rejected). At two, the task is re-planned: the owner reads both sessions' closing notes, narrows or splits the task, and the third attempt runs on Fable 5.1 with both notes attached, whatever the task's default model (§4.2). At four, the task goes to a person without an agent for a day, because the problem is usually the specification.

### 3.2 `docs/PLAN.md`

The plan file is the one document every session reads after `CLAUDE.md` and updates before it ends. It is short at the top and long at the bottom.

```
# CAROS backend · plan
Updated: 2026-11-03 by <person> in <PR>.   Current phase: B1.   Next milestone: G-DEMO (B3).

## Now
- B1.6 commit chunks (A, in progress, PR #142)
- B1.13 Google sign-in (D, ready)
- B2.4 suppression (B, in progress, PR #139)

## Blocked
- B4.9 SFTP: waiting on the portal check of Blob SFTP in UAE North (Davide, by 2026-11-10)
- B1.15 RISC: waiting on the Google Cloud project's receiver approval

## Gates
- G-CI passed 2026-10-12 (commit …)
- G-DEMO: not yet · G-REAL: not yet (13 of 14 §9.13 items open) · G-LIVE: not yet · G-AI: not yet

## Week-one items (B0.15)
| item | owner | date | reference |
...

## Phases
### B0 · Foundations · complete 2026-10-12 (commit …)
### B1 · Facts and identity · in progress
#### Tasks
| # | task | owner | model | rev | attempts | status | PR |
...
#### Briefs
### B3.4 · …   (the brief format of §3.1)
...
## Decisions log (one line each, newest first, linking docs/decisions/)
## Session notes (one line per session: date, task, outcome, what the next session should know)
```

Three rules. The **Now** list never holds more than one task per stream; a stream with two "in progress" lines has a review it has not done. A task's line changes only in the pull request that does the work, so the plan and the code move together and a reviewer sees both. The **Session notes** line is the hand-off between sessions and is written even when the session failed, because the next attempt reads it first.

### 3.3 `CLAUDE.md` for the backend repository

Written by B0.14 and rewritten from the build at the end of every phase (§3.6). Under 200 lines, because Claude Code loads it into every session and its own guidance is to keep the file short and specific ("target under 200 lines per CLAUDE.md file", [How Claude remembers your project](https://code.claude.com/docs/en/memory)). No line numbers, because they drift. The draft:

```
# CAROS backend: working instructions

This is the production backend and Next.js app for CAROS (Counselor OS). The prototype in the
EdTech repository (index.html) is frozen and is the behavioural specification; nothing is ported
from it without first writing down the rule it encodes (docs/screens/<screen>.md).

This file describes the build as it stands after phase <N> (<date>). It is rewritten from the
code at the end of every phase. If a name here does not exist in the code, the code is right and
this file is stale: fix the file in the same PR. `pnpm docs:verify` checks every identifier here.

## Read first, update last
1. Read docs/PLAN.md. Find your task under "Now". Read its brief. Do only that task.
2. Read the spec sections the brief names (docs/spec/ holds frozen copies of the plan passes).
3. Before ending: update the task line and attempts in docs/PLAN.md, add a session note, and
   fill the PR template. If you decided something, add a docs/decisions/ file.

## The shape (pass 1 DR-2, DR-3)
- pnpm workspace, Turborepo. apps/web (Next.js App Router) and apps/worker (pg-boss) both call
  packages/domain. packages/contracts is the only package everyone may import.
- Every mutation: tRPC procedure → domain function → withTenant() transaction → audit.record()
  and events.emit() in the same transaction. Server Actions are not used for data. There is no
  way to run a query outside withTenant(); do not look for one.
- Every domain function starts with assertAllowed(class, action, subjects). A query before it
  fails the build (dependency-cruiser).
- packages/engine is pure: no I/O, no database, no Date.now(), no Math.random(). It exports
  evaluateStudent(input): EvaluationResult. The domain layer loads and writes.
- Derived values are views or functions, never columns. The forbidden-column test lists them.
- Migrations: drizzle-kit generate; hand-written SQL for policies; one migration per PR;
  a merged migration is never edited; drizzle-kit push is refused outside localhost.

## Invariants (CONTEXT §4; product, not configuration)
- Five tiers, one order: urgent → checkin → review → monitor → good. Never collapsed or renamed.
- Signals are personal. Nothing compares or ranks students, including any AI answer.
  The engine's no-comparison property test is the executable form of this rule.
- Rules decide, the model writes. No number, date, tier or level a user sees comes from a model.
- Provenance: every signal keeps its inputs, the rule-set versions and an evidence snapshot.
- Escalation is one act per case, structured, step-up gated, audited with identifiers only; the
  email carries a reference and nothing about the student.
- A selection cannot be approved without a recorded review meeting (a CHECK and a domain guard).
- Caseload and Diploma cohort are never totalled. No function returns their union.
- EE supervision capacity warns and never blocks.
- Never fabricate: no testimonials, customers, outcomes, benchmarks, pricing, press, sources.
- Gamification exists on the student side only; only the discovery module writes xp_ledger.
- Mentor contact is in-platform only; "match" means reach/match/safety and nothing else.

## Tenancy and data
- Every tenant table has school_id first and composite foreign keys; RLS with FORCE on all of
  them; the tenant policy is RESTRICTIVE; a query with no context sees nothing.
- Two synthetic tenants, ACS (marker on) and Wellesmere (marker off, British, no IB). A screen
  is not done until it passes on both. Never write "Grade", a year number, "Child Protection
  Officer" or any ACS name as a literal; read them from the tenant.
- Real tenant data never enters this repository, a test, a fixture, a log line or a session.
  You never hold a support grant. If you see a real name where a synthetic one should be, stop.
- Nothing personal leaves the UAE except through packages/ai's gateway, pseudonymised, to a
  model on the registry with covered_model = false and zdr_eligible = true, inference_geo "us".

## How to work
- One task per session, in a worktree (claude --worktree <task>), one PR. Never merge; never
  force-push; never resolve a conflict by taking one side of a file. Never edit generated files.
- Tests are the definition of done. Add the test the brief names before the code it tests.
- Prefer the spec's names for tables, columns, jobs, audit actions and events. Do not invent
  parallel vocabulary. If the spec is wrong, say so in the PR and the decisions log; do not
  silently diverge.
- Copy in this repository is written to be read aloud: no em dashes, short sentences.
- Do not add a dependency without the cooldown (pnpm minimumReleaseAge) and a line in the PR.

## Commands
- pnpm ci            everything CI runs, locally (typecheck, lint, boundaries, unit, db, e2e)
- pnpm db:migrate    apply migrations to DATABASE_URL (localhost only from a session)
- pnpm seed --tenant acs|wellesmere --anchor <date>
- pnpm test --filter engine        the scenario and property suites (under a second)
- pnpm test --filter db            the RLS, authz, registry and convention suites
- pnpm docs:verify                 every identifier in CLAUDE.md and docs/ resolves
- pnpm dev                         web + worker + Postgres + Azurite + Mailpit via Compose

## Where things are
- docs/PLAN.md (the plan), docs/decisions/ (DR-01…), docs/spec/ (frozen plan passes and
  CONTEXT.md, PRODUCT.md), docs/screens/ (rule ledgers per ported screen), docs/runbooks/,
  docs/generated/ (schema, API, audit actions, events; never hand-edited).
- packages/db/migrations (SQL), packages/db/src/schema (Drizzle), packages/engine/test/scenarios
  (S1…S23), packages/seed/fixtures/<tenant>/<pack>, packages/ai/prompts/<feature>/<semver>.md.

## Models and reviews (docs/PLAN.md carries the per-task line)
- Opus 5.5 builds by default. Fable 5.1 for: RLS policies and auth.allowed(), safeguarding
  routing, engine statistics and tiering rows, irreversible migrations, pseudonymiser and
  validator, and any task that has failed twice. A different model reviews those tasks.
```

Two things about this file. It repeats nothing that `docs/generated/` can produce (the table list, the API, the audit actions), because a hand-maintained inventory is the first thing to drift. And the paragraph about the demonstration data and real data is in the invariants, not in a footnote, because the prototype's own `CLAUDE.md` learned that lesson.

### 3.4 `.claude/rules/` and hooks

Claude Code loads `.claude/rules/*.md` alongside `CLAUDE.md` and scopes a rule to files by a `paths` frontmatter ([memory docs](https://code.claude.com/docs/en/memory)), so the long, path-specific guidance lives there and does not cost every session its context:

| Rule file | `paths` | Carries |
|---|---|---|
| `db.md` | `packages/db/**` | migration naming, the immutability rule, the policy pattern (`auth.protect()` call per table), the registry entry, the conventions test list, expand-and-contract |
| `engine.md` | `packages/engine/**` | purity, determinism, the scenario file format, the changelog rule, "a template binds numbers, dates and labels only", the no-`fairness`-import rule |
| `domain.md` | `packages/domain/**` | `assertAllowed` first, the audit action and event per function, one transaction, the state-machine tables of pass 1 DR-7 as the source of transition names |
| `ingest.md` | `packages/ingest/**` | the closed transform set, no tenant slug in code, rosters are permissions, adapters never import the database |
| `ai.md` | `packages/ai/**`, `packages/contracts/ai/**` | the eleven steps, the envelope rules, the prompt PR rule (version, changelog, eval run), no tenant string in a schema, the model registry is a migration |
| `web.md` | `apps/web/**`, `packages/ui/**` | rules live in the domain, never in a component; the rule ledger before a port; the marker and letterhead; both tenants; 375px; no severity by colour alone; the AI label from the generation row |
| `notify.md` | `packages/notify/**` | allowlisted variables, identifiers only, the content test per template |
| `copy.md` | `**/*.tsx`, `**/*.md` | the writing rules from `PRODUCT.md` and `DESIGN.md`: register per audience, no eyebrow above a heading, no em dashes |

Hooks (`.claude/settings.json`), because "Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook" ([memory docs](https://code.claude.com/docs/en/memory); hook events and the blocking exit code are in [Hooks](https://code.claude.com/docs/en/hooks)):

| Event | Hook | Blocks or does |
|---|---|---|
| `PreToolUse` on `Bash` | `hooks/guard-git.sh` | exits 2 on `git push --force`, `git push -f`, `git merge` into `main`, `git rebase` of `main`, `gh pr merge`, `gh pr edit --add-label wholesale-rewrite`, `drizzle-kit push` unless `DATABASE_URL` matches `localhost`, `terraform apply` outside CI |
| `PreToolUse` on `Edit` and `Write` | `hooks/guard-files.sh` | exits 2 on a path under `packages/db/migrations/` that exists on `main`, on `docs/generated/**`, on `packages/db/migrations/meta/**`, and on any write whose content contains a string from the real-names blocklist |
| `SessionStart` | `hooks/session-start.sh` | prints the "Now" block of `docs/PLAN.md` and the brief of the task the worktree branch name points at |
| `Stop` | `hooks/session-end.sh` | if the worktree has changes and `docs/PLAN.md` is untouched, prints a reminder that the task line and session note are missing (it cannot block, and should not) |
| `PostToolUse` on `Bash` matching `pnpm test` | `hooks/record-test.sh` | appends the test summary to the session note draft, so the closing note is written from evidence |

### 3.5 What every session reads first and updates last

Reads first, in order: `CLAUDE.md` (loaded automatically), the `Now` block and the task's brief in `docs/PLAN.md` (printed by the hook), the spec sections the brief names under `docs/spec/`, the module's `README.md` in `packages/domain/<module>/` (one screen of text: the tables it owns, its public functions, its audit actions), and the rule ledger `docs/screens/<screen>.md` when the task ports a screen. Nothing else is read up front; the agent reads code as it needs it.

Updates last, in the same pull request: the task line in `docs/PLAN.md` (status, attempts, PR), one session note, a decision record if a decision was made, the module `README.md` if a public function was added or changed, the rule ledger if a screen rule was implemented, and the PR template's five fields. A pull request whose diff touches `packages/` and not `docs/PLAN.md` fails a CI check (`tooling/ci/plan-touched.ts`) unless labelled `chore`.

### 3.6 Keeping the documentation from drifting

The prototype repository's own `CLAUDE.md` records that its documentation twice described a build that no longer existed, and that reading it as truth cost real work. Five mechanisms, all of them checks:

1. **Generate what can be generated.** `docs/generated/schema.md` from the Drizzle schema plus `privacy.table_registry` (table, class, subject column, retention class, the `auth.protect()` arguments); `docs/generated/api.md` from the tRPC routers (procedure, input schema, the domain function it calls); `docs/generated/audit-actions.md` and `events.md` from `audit.action` and `events.name`; `docs/generated/runbooks.md` from the directory; `docs/generated/jobs.md` from the worker's queue registrations. CI regenerates and fails on a diff, so a hand edit of a generated file cannot land.
2. **Verify every named identifier.** `pnpm docs:verify` (`tooling/docs/verify-claude-md.ts`) extracts every backticked identifier from `CLAUDE.md`, `docs/PLAN.md`, `.claude/rules/*.md`, `docs/decisions/*.md` and `packages/*/README.md`, and checks that a path exists, an export exists (through the TypeScript program), a table or column exists (through the schema snapshot), a job name is registered, or an audit action or event key is seeded. An identifier that does not resolve fails CI unless it is followed by `(planned)`; a `(planned)` marker older than one phase fails too. This is the check the prototype repository did not have.
3. **Rewrite `CLAUDE.md` from the build at the end of every phase.** The last task of each phase is a documentation session whose brief is "describe the build as it stands; delete every sentence that describes intention". The prototype's P8 did exactly this and its `CLAUDE.md` became an authority again.
4. **Specification stays frozen and labelled.** `docs/spec/` holds the pass outputs with their commit hash and a header saying they describe a design, not a build; the rule ledgers and decision records are where the design and the build are reconciled, and the code wins.
5. **No line numbers in prose.** A rule ledger cites the prototype by function name (`vCase`, `selCheck`) and the build by file path and export, never by line; a lint on `docs/` fails on `:\d+` after a file name.

---
## 4. The model and effort for each phase

### 4.1 The table

The per-phase lines are at the head of each phase in §1 in `PHASES.md`'s form. Collected:

| Phase | Model | Why this model | Reviewed by a different model |
|---|---|---|---|
| B0 Foundations | Opus 5.5, high; **Fable 5.1, max** for roles and spine, `withTenant()`, `auth.allowed()` and `auth.protect()`, the RLS harness | scaffolding is Opus 5.5's ground; the tenancy layer is written once and every later line trusts it | every Fable task by Opus 5.5; the Terraform module by Fable 5.1 |
| B1 Facts and identity | Opus 5.5, high; **Fable 5.1, max** for the identity ladder, sign-in and sessions, the RISC receiver, the support console | the pipeline is large and specified; the ladder, sign-in and the grant path decide who a person is and who may look | the four Fable tasks by Opus 5.5; the security section and rollback by a second Opus session |
| B2 Engine and sweep | **Fable 5.1, max** for `packages/engine` and the tiering rows; Opus 5.5, high for loader, writer, jobs, watchdogs, thresholds screen | the statistics fail silently; the orchestration fails loudly | the engine by Opus 5.5 (pass 3's requirement); the writer by Fable 5.1 |
| B3 The counselor's morning | Opus 5.5, high; **Fable 5.1, max** for the escalation, access logging and the template renderer | a port of a rendered specification; the escalation is the one consequential act | the escalation and renderer by Opus 5.5; the audit-coverage test by Fable 5.1 |
| B4 Pilot readiness | Opus 5.5, high; **Fable 5.1, max** for erasure with restore replay, offboarding key destruction, the legal-basis gate, the production Terraform review | procedure and tooling, with three irreversible pieces | the irreversible pieces by Opus 5.5; authorization findings from the pen test by Fable 5.1 then Opus 5.5 |
| B5 The application season | Opus 5.5, high; **Fable 5.1, max** for the classification and fee-status rules, parent activation and links, safety layer 1 routing | a broad port; three pieces decide what a family reads or which adult sees which child | the three by Opus 5.5 |
| B6 The Diploma | Opus 5.5, high | the most literally specified module; `selCheck` is code today | the `selCheck` port, the approval gate and the capacity stamp by **Fable 5.1** |
| B7 AI | **Fable 5.1, max** for the pseudonymiser, validator, leak scanner, plan compiler, reader and safety routing; Opus 5.5, high for plumbing, prompts, screens, evals | the mechanisms that keep a child's name in the country and a sentence honest | the Fable pieces by Opus 5.5; the constitution and each envelope allowlist by Fable 5.1; evals judged by a model other than the generator (pass 5 §10.1) |
| B8 Discovery, mentors, reporting | Opus 5.5, high; **Fable 5.1, max** for mentor credentials, pairings and holds | a port, plus the one path where an outside adult reaches a child | the mentor pieces by Opus 5.5; the approval gate and XP single writer by Fable 5.1 |
| B9 Connectors, second school, scale | Opus 5.5, high | I/O against documented APIs | each adapter's `verify()`, credential handling and the isolation rehearsal by Fable 5.1 |

Effort settings, stated once because Opus 5.5's API default is `medium` (pass 5 §9.1) and a session that inherits it does less than the task needs: **high** for every build task in the tables; **xhigh** for the tasks marked as ports of rule engines or orchestration (B2.10 to B2.13, B6.2, B6.3, B6.10, B7.4, B7.13); **medium** for documentation, accessibility passes, scaffolding and rehearsals; **max** for every Fable 5.1 task. No task in this plan runs at `low`; research sub-agents inside a session may.

### 4.2 The reservation rule

Opus 5.5 is the default builder. Fable 5.1 is reserved for work where a subtle error is expensive and hard to see, and the plan names the tasks rather than leaving it to judgement in the session:

- **Authorization and row-level security:** B0.5, B0.6, B0.7, B0.8, B1.16, B3.3, B7.4 (retrieval under `caros_t_ai`), and any pull request that changes `auth.allowed()`, `auth.protect()`, a `SECURITY DEFINER` helper or a policy, in any phase.
- **Safeguarding routing:** B3.4, B3.5, B3.8, B5.12, B7.9, B8.10, and any change to `core.school.safeguarding_route`'s handling or the `safeguarding_escalation` template.
- **The engine's statistics and tiering rows:** B2.1 to B2.6, and any change to a default, a detector, the combination table or hysteresis in a later phase.
- **Schema changes that are hard to reverse:** B0.5 (the spine), B4.4 and B4.7 (erasure, key destruction), B4.8 (the production apply with its creation-time settings), B9.7, and any migration that drops or renames a column (the "contract" half of expand-and-contract).
- **Identity for people the school does not know, and credentials:** B1.4, B1.13, B1.14, B1.15, B5.10, B8.8, B8.9.
- **The AI trust mechanisms:** B7.2, B7.3, B7.8, B7.13's compiler.
- **Anything Opus 5.5 has failed at twice** (§3.1's attempt counter), with both closing notes attached to the third attempt's brief.

Everything else runs on Opus 5.5. The reservation is written into `docs/PLAN.md`'s task lines and into the pull request template, so a task run on the wrong model is visible at review.

### 4.3 Review by a different model

Marked in the `Rev` column of every task table and collected here so the rule is auditable: every Fable 5.1 task is reviewed by Opus 5.5, and the following Opus 5.5 tasks are reviewed by Fable 5.1 because they implement an invariant or a gate: B0.4 (the Terraform module's creation-time settings), B0.9 (the hash chain), B1.1 and every later migration that touches `auth.*` or `audit.*`, B1.8 (rosters as permissions), B2.7 (templates cannot invent a number), B2.10 to B2.12 (the writer and the sweep), B3.2 (the audit-coverage test), B3.11 (access logging), B5.7 (no model-produced letter before B7), B6.2, B6.3, B6.10 (the two gates and the capacity stamp), B7.6 (the constitution), B7.12 and B7.14 (envelope allowlists), B8.4 and B8.5 (the approval gate and XP), B9.2 to B9.4 (`verify()`), B9.7 and B9.8's PgBouncer test. A review session's brief names the model, attaches the diff and the acceptance list, and ends in a written verdict on the pull request; the writer's model may not approve its own work. Pass 3's requirement that the engine be reviewed by a model other than the one that wrote it is B2's `Rev` column, and pass 7's adversarial review by Opus 5.5 applies to this plan itself.

### 4.4 What the agent costs

Pass 5 verified Opus 5.5 at $4 input and $20 output per million tokens with cache reads at $0.20, and Sonnet 5 at $2 and $10 (pass 5 §11.2, [pricing](https://platform.claude.com/docs/en/about-claude/pricing)). Fable 5.1's list price is $10 and $50 per million on the same page as carried in the Claude API skill's cached table dated 2026-06-24, not independently re-fetched by this pass. An order-of-magnitude estimate, easily wrong by a factor of three: about 280 sessions (the sum of §1's planning estimates), a fifth of them on Fable 5.1, each session reading a few million tokens mostly from cache and writing a few hundred thousand, puts the agent's bill in the low thousands of dollars for the whole plan to B9, well under the penetration test, the DPO and the insurance. CONTEXT §2 says budget is not the binding constraint; the reservation rule exists for correctness, not for cost.

---

## 5. Tests

### 5.1 The suites, where they live and when they run

| Suite | Package and path | Proves | Runs |
|---|---|---|---|
| RLS | `packages/db/test/rls/` | tenant isolation for every tier role and every tenant table, fail-closed, `FORCE`, the eight "see nothing" cases; both tenants | every PR |
| Authz matrix | `packages/db/test/authz/` (generated) | every (role or capability, class, action) cell with a positive and a negative fixture; column cases; verb cases; narrowing; support | every PR |
| Registry and conventions | `packages/db/test/schema/` | every tenant table registered, protected, composite-keyed, timestamped; no forbidden derived column; no display strings; the policy-presence check; `drizzle-kit check` | every PR |
| Engine scenarios and properties | `packages/engine/test/` | S1 to S23; determinism, monotonicity, suppression never raises, no comparison, hysteresis; golden files; no `fairness` or database import | every PR (under a second) |
| Seed reproduction | `packages/seed/test/engine-reproduces-seed.spec.ts` | the engine over the fixture facts equals pass 3's expected diff | every PR touching `engine`, `ingest`, `seed` or `signals` |
| Fixtures and profiles | `packages/ingest/test/fixtures.spec.ts`, `profiles/<tenant>/<kind>.spec.ts`, `roster-security.spec.ts`, transform property tests, parser fuzz | both export shapes through the real pipeline against `expected.json`; rosters as a security property | every PR |
| Domain contracts | `packages/domain/*/test/` | every mutation writes its audit action and event; state-machine transitions and guards; the loader's inputs validate; the writer replays as an upsert; caseload and cohort never union; only discovery writes XP | every PR |
| API structure | `packages/api/test/structure.spec.ts` | every procedure validates with a `contracts` schema and calls exactly one domain function with no other logic (a ts-morph structural test); no `'use server'` outside the allow-list | every PR |
| Notify | `packages/notify/test/templates.spec.ts` | every template's content rule; undeclared variables refused; outbox dedupe | every PR |
| Safety | `packages/safety/test/` | the corpus, routing clocks, the template, the timeout behaviour, the under-13 gate | every PR (layer 1); nightly with the model (layer 2) |
| AI mechanisms | `packages/ai/test/{leak-scanner, refusal, validator, injection, copilot-scope, schema-hygiene, envelope-allowlist, provider-surface}` | pass 5 §10.4's hard zeros | every PR touching `packages/ai`, `packages/contracts/ai` or a prompt |
| AI evals | `packages/ai/evals/<feature>/` with the runner | the suites of pass 5 §10.2 and the profiles of §10.3 | deterministic tier every PR; judged tier nightly on `main`; full run for a promotion |
| Web | `apps/web/test/` (Playwright, axe) | every route-state renders on both tenants; the demo flows; the Wellesmere checklist assertions; the no-comparison DOM test; 375px; the AI label present | every PR (smoke) and nightly (full) |
| Logs and data hygiene | `packages/web/test/log-scanner`, `packages/seed/test/no-real-data` | no seed name or email in captured logs; no real name in seeds, fixtures or eval cases | every PR |
| Sweep smoke | `apps/worker/test/sweep-smoke.spec.ts` | §5.7 | every PR (fake clock) and nightly on staging (real clock) |
| Production checks | the tenant canary, the drift check, the `tier_yesterday` assertion, the chain verification, the drill log check | the running system still holds the properties the suites proved | nightly, weekly, quarterly, per deploy (§7.4, §7.6) |

### 5.2 Signal engine unit tests

The adversarial synthetic set is pass 3 §15.1, and it is the acceptance test for every engine change: S1 the strong student quietly declining, S2 the struggling student genuinely recovering, S3 the single outlier, S4 the term break, S5 the transfer in, S6 missing weeks, S7 the teacher concern only, S8 relapse inside the window, S9 the exam period suppressed for one year group, S10 the subject change, S11 the authorised absence, S12 the school-wide bad week, S13 the tiny wobble, S14 the ordinal series, S15 the corrected import, S16 the positive-only student, S17 and S18 the counselor downgrade with and without new evidence, S19 hysteresis at the edge, S20 the weekly backfill, S21 the retrospective term, S22 the threshold change, S23 the fifteen authored cases. Each scenario file carries its generator (weekly points per measure with a named noise seed, calendar periods, absence spans, flags, context, case state) and its expectation per week (level per measure, rule hits, proposed tier, onset week) and its final evidence sentences. The five property tests run over generated series. The golden-file test pins byte-identical output for the same input. The calibration scripts reproduce pass 3 §3.6 and §11.1 and the known-parameter ARL figures, and any change to a level threshold or a tiering row re-runs them. `engine-reproduces-seed` is the bridge to the fixtures: the twelve ACS weekly packs imported in sequence, the backfill evaluations, and the diff against the narrative layer equal to the expected list (thirteen tiers match on the authored day, Maryam's `good` one week later, Hana one tier below under the default relapse uplift).

### 5.3 Contract tests between modules

One test per seam in §2.2, plus the structural tests that keep the seams the only path: `packages/contracts` schemas round-trip every fixture record; the loader produces inputs that validate against `StudentEvaluationInput` for every student in both tenants; the writer replays an `EvaluationResult` as an upsert with no duplicate signal or evidence ids; `packages/api`'s structural test proves every procedure is `input(schema) → one domain function`; the `dependency-cruiser` rules fail a build in which a module imports another module's internals, an adapter imports the database, `packages/ai` imports the worker's system context, or a domain function queries before `assertAllowed`; the template allowlists and envelope allowlists are tests, not reviews; the rule-set and audit `detail` schemas are validated on insert and tested with an out-of-bound value and an unknown key.

### 5.4 Authorization tests

The RLS suite and the generated matrix suite run against **both** synthetic schools on every pull request (pass 1 DR-4, pass 4 §3.8): for each tier role and each tenant table, tenant A with tenant B's data present sees and writes nothing; no context sees nothing; the owner under `FORCE` sees nothing; every `auth.perm_scope` is exercised with a student who is in the caseload, in the roster, self, a linked child, a paired mentee, and none of those; the eight "see nothing" cases (no context; expired session; ended membership; ended cover; ended guardian link; ended pairing; teacher after a roster move; counselor after reassignment); the column cases (mentor revoked columns; teacher attendance view without reasons; guardian tier without nationality); the verb cases (`approve`, `escalate`, `configure`, `export` refused in the domain layer for every role without the row, even when `read` exists); the narrowing trigger; the three support cases. The suite is generated from `auth.role_permission` and a fixture map, so a new row without fixtures fails the build, and a school override in a test tenant is exercised too. The Wellesmere checklist (pass 1 DR-8) is the second-school half: no "Grade" literal, no ordinal assumption, no IB navigation when the modules are off, the safeguarding label and counselor title from the tenant, scales through `ref.grade_scale`, the calendar from the tenant, UCAS-only deadlines, no ACS string in code, the marker off. Two module-boundary invariants are tests: no function returns the union of the caseload and the Diploma cohort, and no code outside the discovery module writes `xp_ledger`. In production, the nightly tenant canary (pass 4 T1) signs in as one synthetic canary tenant's counselor and asserts zero rows from the other, and alerts on any query plan without `school_id`.

### 5.5 Import tests against both export shapes

`fixtures.spec.ts` imports the Veracross-shaped ACS packs (term start, twelve weekly, one reporting) and the iSAMS-shaped Wellesmere packs (Michaelmas, Lent, the correction) in order through the real pipeline against an ephemeral database and asserts `expected.json` exactly: counts per status and code, the people summary, the security section, the rows the correction supersedes, and the `sis.v_current_*` views after `after_commit`. The 26 deliberate defects of pass 2 §8 are each a line in the oracle (the locale date, the padded id, the name change, the transfer and withdrawal, the shared guardian email, the cover teacher, the teacherless section, the set move, the duplicates, the unmapped code, the grade without membership, the stale pack, the truncated roster, the two-score correction, the forbidden column, the missing submissions, the exam period; the `N` to `I` recode, the leaver in a set, the DSL who teaches, the emergency contact, the Windows-1252 file, the GCSE `9` and A-level `A*`, the `UPN` column, the two-week timetable). `roster-security.spec.ts`, the profile specs, the transform property tests, a parser fuzz test over malformed CSV and XLSX, the export-injection fixture, the 250 MB limit and the scan gate complete the set. The test that fails the build if any adapter or profile references a tenant slug is the one that keeps the second school cheap.

### 5.6 AI evals

Pass 5 §10 is applied as written: the suites (co-pilot 150 + 60 + 40 refusals; brief 46; parent draft 120; discovery 60 profiles × 3 seeds on both tenants; EE 80 × 2 guides; headline 200; safety 400; reader 300; injection 120 × surfaces; pseudonymiser and leak scanner over both directories), the ten adversarial profiles, and the pass bar (§10.4) recorded as `suite_version` thresholds. The runner refuses a case without a gold answer written before the model ran, keeps train, validation and test splits, and treats a case a prompt change breaks as a regression until a person re-labels it. The deterministic tier gates every pull request that touches the AI packages or a prompt; the judged tier runs nightly on `main` and in full for a promotion; the human sample (30 items per feature, 27 accepted; 28 of 30 dispositions for safety) is labelled by the school's people (questions 129, 132, 133) and blocks shipping. The promotion protocol (pass 5 §9.5) is tooling, not a document: `active_needs_eval` refuses a configuration without a passing run, `AI_MODEL_SWITCHED` records the switch, and the 14-day watch rolls back on a doubling of flagged outputs or refusals. Before any suite runs for real, the week-one smoke test proves structured outputs, `inference_geo`, caching and streaming compose on Opus 5.5 and Sonnet 5.

### 5.7 The smoke test of the nightly sweep

Three levels, because the sweep is the product's ritual and its failure mode is silence.

1. **In CI, on every pull request, with a fake clock.** An ephemeral database with both tenants seeded; the clock advanced past each tenant's `sweep_hour`; `sweep.schedule` enqueues `sweep.run` once per tenant and never twice (the nightly index); the batches run; `sweep.finalize` sets `succeeded`, `students_evaluated` equals `students_in_scope`, `tier_yesterday` equals the recomputation from `case_tier_history`, `sweep.completed` is emitted and the structured log line is written, `/health/sweep` reports today for both tenants; then the failure paths: a batch made to throw leaves `partial` with `students_failed` and yesterday's tier on the sheet with its line; a run that cannot start is `failed`; with the worker stopped, `sweep.watchdog` emits `sweep.missed` and the banner appears; a daytime flag runs `sweep.event` within the coalescing window and never lowers a tier; a scheduled pack commit runs `sweep.backfill` and only the final week opens cases.
2. **On staging, every night, with the real clock.** The cron runs for both tenants at 02:00 Asia/Dubai; the alert rules (§7.4) stay silent; the seven-night acceptance of B2.17 is the first pass and the check is permanent afterwards; once a month a deliberate stop of the worker proves the page arrives within twenty minutes.
3. **In production, from B4 onward.** The canary tenant pair runs the sweep every night before and after the first real school, so the path that matters most has run hundreds of times before it runs for a child.

### 5.8 CI gates and their order

`ci.yml` runs on every pull request and on `main`. Jobs, in the order they are required to pass, with durations as planning assumptions:

| Job | Contents | Required |
|---|---|---|
| `check` (2 min) | typecheck, Biome, `dependency-cruiser` boundaries, the `'use server'` lint, `docs:verify`, generated-docs diff, `plan-touched`, the wholesale-replacement check, gitleaks, `npm audit signatures`, the lockfile and cooldown check | yes |
| `unit` (3 min) | Vitest across packages, including the engine suite and the AI mechanism tests | yes |
| `db` (6 min) | migrations from zero, `drizzle-kit check`, seed both tenants, the RLS, authz, registry and convention suites, the domain contract tests, `fixtures.spec.ts`, `engine-reproduces-seed`, the sweep smoke with a fake clock, the log scanner, `no-real-data` | yes |
| `e2e` (8 min) | Playwright smoke on both tenants with axe; the full Playwright set nightly | yes (smoke) |
| `images` (5 min, `main` only) | build `web` and `worker`, Trivy scan, attestations, SBOM, push to the registry | for deploy |
| `evals-deterministic` (varies) | only when `packages/ai`, `packages/contracts/ai` or a prompt changed | yes when triggered |
| nightly | the judged eval tier, the full Playwright set, the staging sweep check, the drift check, the tenant canary (production), the `tier_yesterday` assertion | reported, pages on failure where §7.4 says so |
| weekly | the audit chain verification, the Renovate batch, the external attack-surface scan | reported |
| quarterly | the restore drill log freshness (blocks a production deploy when stale) | pre-deploy |

---
## 6. The frontend rebuild

### 6.1 Principles of the port

The prototype is the specification and it is frozen, so the Next.js app is the only place a school will see anything new. Five rules keep the port from losing what the prototype encodes.

1. **Rules move to the domain before the screen is ported.** Every rule the prototype enforces in a view or a handler (`selCheck` gating a submission, the approval button disabled without `rec.talk`, `teacherQueue()` filtering to HL picks of the teacher's own subjects, `casSum` reading `hrs` and `entries` as different numbers, the routed note vocabulary, the escalation's confirm-and-reason) becomes a domain function or a rule set first, with a test, and the component calls it. A component in `apps/web` contains no rule; a lint on `apps/web` fails on imports from `packages/db` and on any arithmetic over record fields that is not display formatting.
2. **A rule ledger precedes every screen.** `docs/screens/<screen>.md`, written in the port session's first half: the prototype function(s) and route-states; every rule the screen encodes, by function name; where each rule now lives (domain function, view, rule-set key); the test that pins it; the handler map (each `data-*` action → domain function → audit action → event); what is deliberately not ported and which pass says why. The ledger is the reviewer's checklist and the reason a later change to the screen cannot silently drop a rule.
3. **Derived values are read, never recomputed in the browser.** The run comes from `signal.week_run()`, the counts from the domain's named functions, the dimension statuses from the `dimensions` rule set, the demand from the views. The prototype's own comments record why (pass 1 DR-6).
4. **Both tenants, every screen.** A screen's Playwright test runs on ACS and Wellesmere, and the Wellesmere checklist assertions for that screen are in the same file.
5. **The visual system is ported once.** `DESIGN.md`'s tokens, type roles, marks and named rules become `packages/ui` in B0.12 and every screen composes from it; the `impeccable` and `web-design-guidelines` skills that governed the prototype's phases are the review tools for the port sessions (they are not required by this planning pass, but the quality floor they carry is the one the school has already seen).

### 6.2 The screen inventory by phase

From the router at `index.html:9003` to `:9099` and `roleNav` at `:1898`. The 98 route-states `PHASES.md` P0 verified are the completeness count; a phase's port is done when its share of them renders on both tenants without a console error.

| Role | Route key(s) | Prototype function(s) | Phase | What changes in the port |
|---|---|---|---|---|
| Counselor | `cohort-schedule`, `cohort`, `cohort-all`, `today` | `vSheet` | B3 | one screen, four modes; the run from `week_run()`; overnight from `tier_yesterday`; the `expected_cadence` panel; the counselor log row |
| Counselor | `command`, `si-cases` | `vCommand` | B3 | one screen with a filter |
| Counselor | `si-interventions` | `vWork` | B3 | |
| Counselor | `si-why` | `vIntel` | B3 | matrix coloured by domain level; the cohort tiles stay as descriptive aggregates; nothing ranks |
| Counselor | `flags` | `vFlagInbox` | B3 | attach, dismiss, merge; the routed vocabulary |
| Counselor | `meetings` | `vMeetings` | B3 | |
| Counselor | the ten `DIMS` keys | `vDim` | B3 (attendance, punctuality, academic, engagement, behaviour), B5 (application progress, list balance, deadlines, documents and references, personal statements) | one component; the three hard-wired dimensions become rule-set outputs |
| Counselor | `files`, a file id | `vFiles`, `vFileOne` | B1 (record tabs), B3 (list and case tabs) | `FILE_ACCESS` on open; the visibility panel rendered from `auth.role_permission` |
| Counselor | an open case (`S.open`) | `vCase` | B3 | level, breadth and window replace strength, confidence and severity; the evidence chain from `evidence_item`; the access panel; escalation |
| Counselor | `thresholds` | `vThresholds` | B2 | versions, propose and activate, the what-if run replaces the estimate |
| Counselor | `arch` | `vArch` | B3 | rewritten to describe the sweep and the pull pipeline truthfully |
| Counselor | `app-season`, `app-flow` | `vUni`, `vFlow` | B5 | |
| Counselor | `app-letter` | `vLetter` | B5 (human-written versions), later (generation) | the evidence panel from citation rows |
| Counselor | `psreviews` | `vPSReviews` | B5 | |
| Counselor | `ib-selections`, `ib-demand`, `ib-cas`, `ib-ee` | `vSelQueue`, `vSelStudent`, `vSelDemand`, `vCasCohort`, `vCasDetail`, `vCoordEE`, `vEEStudent` | B6 | the coordinator is the `ib_coordinator` capability |
| Counselor | `approvals` | `vApprovals` | B8 | amend and send-back with structured reasons (the prototype has neither) |
| Counselor | `copilot` | `vCopilot` | B7 | plan, execute, write; the boundaries card's promises as tests; the label from the generation row |
| Counselor | `prove`, `pilot` | `vProve`, `vPilot` | B8 | figures from `events.event` only; "targets, not measurements" until events exist |
| Counselor (new) | admin: Studio, People, Memberships, Caseload and cover, Parents, Mentors, Route, Audit, Notices, Support console | none | B1, B3, B4, B5, B8 | surfaces the prototype does not have; designed from passes 2 and 4 |
| Teacher | `class`, `tclasses`, `tlog`, the flag modal | `vTClass`, `vTMyClasses`, `vTLog`, `tflagModal` | B3 | rosters from imports only; the three routed phrases |
| Teacher | `classapprovals` | `vTSelReview`, `vTSelCard` | B6 | HL picks, own subjects |
| Teacher | `ee` | `vTEE`, `vTEECard`, `vTEEConfirm`, `vTEEStudent` | B6 | load on every card |
| Student | `discover` | `vDiscoverFlow`, `vOnboardQuiz`, `vDiscoveryChat`, `vPathwayProposals`, `vGamifiedRoadmap` | B8 | deterministic mode first; model mode behind the policy |
| Student | `guide`, `explore`, `progress`, `targets`, `pslab`, `apexams` | `vHSGuide`, `vPathExplorer`, `vStuProgress`, `vStuTargets`, `vPSLab` and its four sub-views, `vApExamsStandalone` | B5 | no probability; the synthetic alumni content labelled |
| Student | `stuclass` | `vStuSubjects`, `vStuSubjectRecord`; at the choosing stage `vSelForm`, `vSelChooser`, `vSelSubmittedPanel` | B5, B6 | the choosing stage from the tenant, not "Grade 10" |
| Student | `stucas` | `vStuCAS`, `vStuCore`, `vStuTOK`, `vStuEE`, `vStuEEPropose` | B6 | TOK described, not tracked |
| Student | `mentors`, `network` | `vStuMentors`, `vStuNet` | B8 | |
| Student (new) | "I need to talk to someone" | none | B5 | the student's reporting channel |
| Parent | overview, messages, guide, grades, uni, pathway, apexams, meetings | `vParent` with its tabs | B5 | the child switcher over `linked_children`; grade-conditional tabs from the tenant |
| Mentor | `requests`, `mentees` | `vMentorReq`, `vMentorMentees` | B8 | passkey sign-in; no contact columns |
| Cross-cutting | the ⌘K palette | `palCommands` | B3 (staff), B5 (student, parent) | role-scoped search through the same policies; `DIRECTORY_SEARCH` for whole-school search |
| Cross-cutting | role switcher, grade and track preview | `roleBar()`, `gradeSwitcher()` | not ported | demo apparatus (CONTEXT §11.18) |

### 6.3 What is not ported

The passes found these in the prototype and ruled them out. The frozen demo keeps showing them; the demo script must not read them as promises.

| Prototype behaviour | Where | Why not, and which pass |
|---|---|---|
| Signal strength 0 to 100, the meter, "confidence 86%", the severity tile, signed evidence weights | `vCase`, `caseCard`, `vIntel`, the `arch` page | undefined numbers; replaced by level, breadth and window (pass 3 §9) |
| "Every new grade … evaluated immediately, never in a nightly batch", "gradebook webhook fired" | `vArch` | no webhook exists; the sweep and the pull pipeline are the truth (passes 2 and 3 §0.2) |
| Admission probability per target, with meters | `vCase`, `vFileOne`, `vStuTargets` | traces to nothing; replaced by the sourced requirement, the rule-computed classification with its inputs, and a labelled institution-wide rate (pass 5 §2) |
| The escalation modal's "what will be sent": name, year, headline, attachments | `escalateModal` | the email carries a reference only (pass 4 §5.3) |
| The escalation reason and student names in audit text | `logAudit` calls | names never enter `audit.entry`; the reason lives on the escalation row (pass 4 §0.2) |
| "Minimum necessary visibility" rows for Year head and Head of school | the 360° file | roles that do not exist; the panel renders from `auth.role_permission` (pass 4 §0.2) |
| "Contact consent · On file" for every family; a fabricated default guardian | `parentCard`, `parentOf()` | `consent_status` renders its real value; no guardian is synthesised (passes 2 and 4) |
| "Sessions … are recorded" | mentor and student copy | CAROS records nothing (pass 4 §2.3) |
| Co-pilot answers that rank ("highest structural risk in the cohort") | `CPQ` | invariant 2; the answer schema has no comparative field (pass 5 §0.2) |
| Archetype milestone claims (test-score medians, "filters 80%", salary figures, a Stanford GSB undergraduate programme) | `ARCHETYPES` | unsourced; a claim renders only with a source (pass 5 §2.5) |
| Priya's "platform activity after 01:00", Layla's fourteen-month baseline, Ahmed's "22 months" | authored series | removed or reworded; the window is at most twenty weeks and per section (pass 3 §0.2) |
| "Estimated effect: current false-positive rate 14%" | `vThresholds` | replaced by the what-if run over stored snapshots (pass 3 §10.4) |
| The twelve-character reason box | the escalation form | a structured form with minimums ACS sets (pass 4 §5.3) |
| The pathway probability start-plus-increments | the student pathway view | fabricated in code (`PRODUCT.md`) |
| "190 counselor hours returned per term" | the letter engine copy | not computed until real letters are drafted and timed (pass 5 §3.10) |
| `METRICS` as figures | `vProve` | every figure is a target; the page says so until events exist (CONTEXT §11.2) |
| The stored `weeks[]` run, the per-track hard-coded AP timetable, the three hard-wired dimensions | data and `getStudentClasses`, `dimPunctuality`, `dimEngagement`, `dimBehaviour` | derived from facts and rule sets (pass 1 DR-6, pass 3 §9.3) |
| The Friday-and-Saturday weekend, "Grade" as a literal, ACS staff names in code | `buildNovemberCalendar`, many views | tenant fields (pass 1 DR-8) |
| The role switcher, grade preview, track preview | `roleBar()`, `gradeSwitcher()` | demo apparatus (CONTEXT §11.18); one acting role per session (pass 4 §2.4) |

### 6.4 The shell, the tokens, the marker and the letterhead

`packages/ui` carries `DESIGN.md`'s three token layers (material, semantic, letterhead) with the letterhead rule enforced by the same grep the prototype uses (no `--school-*` token inside a tier, track or domain definition); the tier stamps and letters, the run cells, `tally`, `empty`, `head` with two arguments and no eyebrow; the six type roles; the night ledger gated to the student surface as the prototype gates it; reduced motion zeroing duration and delay; the 375px floor for the parent and student surfaces. The demonstration marker is a component bound to `core.school.demonstration_marker`, a generated column no flag can switch off, so it shows on the synthetic ACS tenant in every demo and training session and never on the real one. The letterhead reads `core.school.brand`; the safeguarding role label, the counselor title, the year-group labels and the SIS name read from the tenant everywhere a string would otherwise be typed.

### 6.5 The demos: when the first genuinely demoable build exists, and what it shows

**Demo 1 · the end of B3 (planning assumption: week 14 with three people, week 20 alone).** The first build a school should be shown, because it does things the prototype cannot: a counselor signs in with Google on the synthetic ACS tenant and sees the caseload sheet with the run and "what changed overnight" computed by the real engine over the twelve weekly packs; opens a case and reads the evidence chain with source labels and as-of dates, the baselines with the band, the interventions and notes; a teacher signs in, logs a concern from the register, and the counselor sees it attach and the case move within five minutes; the counselor escalates through the structured form, the CPO persona receives an email in the staging mailbox that names no child, signs in and acknowledges; the access panel shows who looked; the thresholds page runs a what-if; then the same product signed into as the Wellesmere school: Years, a Designated Safeguarding Lead, no IB, no marker. What it does not show, and the script says so: parents, students, the university and Diploma modules, the AI features, and any real data. Before Demo 1 there is a **Studio demo** at the end of B1 (an import with its preview and security section, a rollback), which is real and new but is for ACS's IT and registrar, not for a counselor.

**Demo 2 · the end of B6 (assumption: during the pilot's shadow period).** Adds the parent portal (activation, two children, a meeting request and its confirmation, the transcript and the requirements page with sourced figures), the student surfaces (subjects, progress, targets with the classification and its inputs, the Personal Statement Lab), and the Diploma (a selection submitted, signed off, the conversation recorded and approved; the demand sheet; CAS; the Extended Essay queue and the over-capacity assignment recorded). Shown on the synthetic tenants; to ACS staff, also on their real tenant for the surfaces they already hold rights to.

**Demo 3 · the end of B8 with B7.** Adds the co-pilot answering the prototype's five questions with citations and refusing the sixth, a meeting brief, a parent draft landing in-app, Extended Essay feedback under the 2027 guide, the discovery flow in both modes with the approval gate, the mentor path, and the reporting page with real events. On synthetic data only, with the AI label and the "built from N records" line on every output.

---

## 7. Operations

### 7.1 The deploy pipeline

Three workflows, all in `.github/workflows/`, authenticating to Azure by OIDC with no stored secret.

- **`ci.yml`** on every pull request and on `main`: §5.8.
- **`deploy-staging.yml`** on every merge to `main`: build the `web` and `worker` images once, scan, attest, push to the registry in UAE North; `terraform plan` and, from `main` only, `apply` to staging; run the migration job (`drizzle-orm/migrator` as a Container Apps Job, `lock_timeout = 5s`); swap the revision in single-revision mode, which keeps the old revision live until the new one passes its startup and readiness probes ([Container Apps revisions](https://learn.microsoft.com/en-us/azure/container-apps/revisions)); smoke: `/health`, `/health/sweep`, a sign-in as the synthetic counselor, the tenant canary; refresh the seed for both tenants at the anchor date; the Playwright smoke against staging.
- **`deploy-production.yml`** on a tag `vYYYY.MM.DD-n`: the `production` environment requires Davide's approval and accepts tags only; pre-checks that the tag's commit has been on staging for at least 24 hours with a completed nightly sweep, that the drill log is under a quarter old, and that no P1 or P2 incident is open; then the same image, migration job, revision swap, smoke and a thirty-minute watch during which any §7.4 alert rolls back. Rollback is activating the previous revision, which Container Apps retains (by default up to 100 inactive revisions, same page); the database is forward-compatible by construction, so no migration is ever reverted.

Deploys are not scheduled during the sweep window or on a school morning: the pipeline refuses a production deploy between 01:00 and 08:00 in any active tenant's timezone, and during the school's declared freeze windows (question 142).

### 7.2 Environments

Pass 1 DR-9 stands: Local (Compose with PostgreSQL 17, Azurite, Mailpit; both tenants), CI (a service container; migrations from zero), Staging (`caros-staging`, UAE North, `B2ms` without HA, no WAF, synthetic tenants only, deploy on merge), Production (`caros-prod`, UAE North with UAE Central access, DR-1 topology, real tenants plus the two canary tenants, deploy on tag), and the isolated single-school deployment from the same module with `deployment_mode = "single"`. Two additions: the **canary pair** in production, two synthetic tenants classified `synthetic`, unbranded, excluded from every report and every count, whose only purpose is the nightly isolation canary and the nightly sweep path (pass 4 T1; §12 asks the revision pass to reconcile this with pass 1 DR-9's "real tenants only" line); and the **maintenance window**. Azure Database for PostgreSQL flexible server lets a production server choose a custom one-hour maintenance window by day and start time, notifies five days ahead, and applies custom-window updates at least seven days after system-managed ones ([planned maintenance](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-maintenance)); production uses a custom window on Saturday at 09:00 Asia/Dubai (a choice: outside the sweep window and outside school hours), staging a system-managed one so it sees updates first.

### 7.3 Migrations in production

Pass 1 DR-9's expand-and-contract, applied: a release may add tables, columns, indexes (`CONCURRENTLY`, outside the transaction), policies and functions; it never drops or renames what the previous revision still reads; the drop lands two releases later as its own migration with a `contract` tag in its name, reviewed by Fable 5.1 (§4.2). The migration job runs before the revision swap with `lock_timeout = 5s` and fails fast; a failed job stops the deploy and pages; the previous revision keeps serving. A merged migration is immutable (the hook and a CI check); a wrong migration is fixed by a new one. `drizzle-kit check` guards the history; the nightly drift job diffs production against the snapshot and pages on any difference, because a hand change to production (which no person can make without a break-glass credential and a second person, pass 4 §3.7) is exactly the class of event that must not be silent. The `caros_migrator` role is the only login that can run DDL, and `pgaudit` writes `DDL` and `ROLE` events to a workspace the application identity cannot write to (pass 4 §4.2).

### 7.4 Monitoring and alerting

The sweep first, then everything else. Every alert carries identifiers only (pass 4 §9.4). Severities follow pass 4 §9.6: P1 exposure of student data, an audit-chain mismatch, a referral that could not be delivered; P2 suspected exposure, a leaked credential, a plausible path to data; P3 a vulnerability without exposure; P4 availability. Delivery is one Azure Monitor action group per severity: P1 and the sweep alerts go by SMS and voice to the on-call and email to both people; P2 by SMS and email; P3 and P4 by email and the ops channel. The action group is `Global` (regional processing is not offered in the UAE, and the payload holds no personal data).

| Alert | Condition | Severity | Runbook |
|---|---|---|---|
| Sweep not completed | no `sweep.completed` log line for an active school by 05:30 local (scheduled query every 15 minutes) | sweep (pages) | `sweep-failed.md` |
| Sweep partial or slow | `status = 'partial'`, or duration over two hours, or `students_failed > 0` | sweep (pages at 05:30, otherwise email) | `sweep-failed.md` |
| Worker silent | heartbeat line absent for 20 minutes | sweep (pages) | `worker-down.md` |
| Watchdog job failed | the external Container Apps Job did not run or reported a missing run | sweep (pages) | `sweep-failed.md` |
| Engine anomalies | `domain.quiet`, `budget.exceeded`, `common_cause.detected`, tier churn over 10% of open cases in one night, a DR-6 assertion failure | P4 to ops channel; churn and assertions page | `engine-anomaly.md` |
| Cadence missed | `import.late` for an agreed cadence | P4 email to Davide and in-app to the `school_admin` | `import-late.md` |
| Connector paused | three consecutive failures | P4 email; in-app to the `school_admin` | `connector-paused.md` |
| Outbox stuck | a queued row older than 30 minutes, or any `safeguarding_escalation` row not sent within 5 minutes | the escalation case is P1 (pages); otherwise P4 | `outbox-stuck.md` |
| Audit chain mismatch | the weekly verification finds a break | P1 (pages) | `incident-response.md` |
| Key access failure | Resource Health or Activity Log reports the server or a storage scope cannot reach its key | P1 (pages) | `key-access-failure.md` |
| Tenant canary failed | the nightly canary sees a row from the other tenant, or a query plan without `school_id` | P1 (pages) | `incident-response.md` |
| Drift | production schema differs from the snapshot | P2 (pages) | `schema-drift.md` |
| Sign-in anomalies | over 20 `SIGN_IN_DENIED` for a domain in a day; a staff session from a new country or AS; more than 5 failed magic-link requests per address per hour | P3 email; the AS and country case in-app to the person and the `school_admin` | `sign-in-anomaly.md` |
| Access anomalies | a teacher opening more than 3× their roster in an hour; a counselor above 3× caseload; export volume | P2 email; visible to the `caseload_lead` | `access-anomaly.md` |
| WAF | blocked-request spike, rule-set errors in prevention mode | P4 email | `waf.md` |
| Certificates and DMARC | certificate expiry within 14 days; DMARC aggregate failures | P4 email | `certificates.md` |
| AI | refusal rate over 1% on a feature; validator refusals over 5% in an hour (pauses the feature); `refused_post_hoc` (suspends the feature); a final-scan hit; cost per generation doubling; the circuit breaker open over 30 minutes; safety-screen volume at 3× expected | P2 for geo and scan; P3 otherwise | `ai-incident.md`, `model-promotion.md` |
| Support grants | any grant created; any four-eyes grant; a `safeguarding_flag` grant | email to Davide and the school's approver; monthly review | `grant-approval.md` |
| Availability | `/health` and `/health/sweep` availability tests from Azure Monitor fail | P4 email; P2 during school hours | `deploy-and-rollback.md` |

Dashboards, three: the sweep board (per school: last run, duration, partials, students failed, alert history), the ingest board (cadence, last as-of, previews waiting, rejections, connector runs), and, from B7, the AI board (pass 5 §10.6's production signals). The school's own view is the monthly report (head hash, grants, rotations, sweep completion, the AI lines), never the dashboards.

### 7.5 On-call for a very small team

On-call means one thing above all: **the sweep window, 05:30 to 07:30 local on school days**, when a page means a counselor may arrive to a sheet that lies. Everything else has a slower clock.

- **Rota:** two people, alternating weeks, published in `docs/ops/rota.md` and mirrored in the action group; the second person is the escalation contact after 15 minutes without acknowledgement (Azure Monitor SMS supports a reply to acknowledge). During the pilot the first person is Davide; the second is whichever teammate owns the worker that phase.
- **What a page means in the sweep window:** open `sweep-failed.md`; the watchdog has already put the banner on every counselor's sheet ("tiers are as of the sweep of …"), so no counselor is misled; re-run `sweep.run` with trigger `manual` and a reason; if it cannot complete by 07:30, message the school's agreed morning contact through the agreed channel (question 147) with the one sentence the runbook gives; write the incident note by 09:00.
- **Outside the window:** P1 pages at any hour; P2 within business hours the same day; P3 and P4 the next working day. Weekends and school holidays: P1 only; the sweep still runs, and a failed sweep on a holiday is a P4 until the last holiday night.
- **What on-call is not:** it is not 24×7 support for the school. The DPA states response targets for breaches (24 hours, pass 4 §1.4) and the school's IT knows the morning contact; nothing else is promised. Every runbook is written so that the second person, who did not build the thing, can follow it.
- **Load:** at pilot scale the expected page rate is near zero after B2.17's seven quiet nights; a month with more than two sweep pages triggers a review of the cause, not a tougher rota.

### 7.6 Backups and restore drills

Pass 1 DR-9 and pass 4 §7.3 and §9.7 as written: 35-day point-in-time restore; geo-redundant backup to UAE Central enabled at creation; weekly vaulted backups with yearly copies for the horizon counsel sets (three proposed); Blob ZRS with soft delete, versions and a nightly GRS copy; the immutable raw-import container; backups encrypted under the CMKs of both regions; every restored server runs the RLS suite and the erasure replay before use. The optional EU cold copy waits for the school's written answer (open decision, §13) and changes nothing in the drill.

The drill calendar: the first full run of all five drills in B4 before the first real record (§1.5); quarterly afterwards, alternating which drill is run in full and which are smoke-run; every run recorded in `docs/ops/drill-log.md` with date, operator, witness, recovery time and point achieved, the erasure replay result and every surprise; a failed drill opens a blocking issue; a stale log blocks the next production deploy (the CI check). The single-tenant extraction (drill 4) is rehearsed once a year in full because it is the procedure for "restore school X without touching school Y" and the first time it is needed will not be a drill.

### 7.7 Runbooks

`docs/runbooks/`, each one page, each tested by someone who did not write it: `sweep-failed`, `worker-down`, `engine-anomaly`, `import-late`, `import-rollback`, `connector-paused`, `outbox-stuck`, `escalation-route-change`, `grant-approval`, `key-access-failure`, `schema-drift`, `deploy-and-rollback`, `restore-drill` (with the erasure replay as its last step), `erasure-and-restore-replay`, `offboarding-and-key-destruction`, `incident-response` (with the evidence pack and the 24-hour clock), `credential-rotation`, `tenant-onboarding` (pass 2 §9's twenty steps with the Google Workspace and safeguarding-route checklists), `quarterly-data-office-check` (pass 4 §1.1), `model-promotion` and `ai-incident` (pass 5 §9.5 and §12), `sign-in-anomaly`, `access-anomaly`, `waf`, `certificates`. The index is generated from the directory.

---
## 8. Gates where outside help is required

Placed on the sequence, each with who supplies it, what it blocks, and where its evidence is recorded (`docs/PLAN.md`'s gate table). Lead times are assumptions and should be written down as answers arrive.

| # | Gate | Who | Placed at | Blocks | Evidence |
|---|---|---|---|---|---|
| G1 | GitHub Team organisation; Azure subscriptions with PIM; the UAE Central access request | Davide; Microsoft | B0 week 1 | protections on a private repository; drill 2 and the geo-restore | `PLAN.md` week-one table with ticket numbers |
| G2 | Written consent to apply the ACS name and crest to synthetic data (question 49) | ACS leadership | B0 week 1 | every demo and training session under the name; already a liability | the letter in the DPA folder; the tenant's `branding_mode` |
| G3 | The KHDA directory check of "Wellesmere" (open decision, pass 1) | Davide | B0 week 1 | the second tenant's name | a note in `docs/decisions/` |
| G4 | The sign-in client's Google brand verification; sensitive-scope verification only if an OAuth client ever requests such a scope (Google states "3-5 business days" for sensitive-scope verification, [sensitive scope verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification); brand verification is described as a few business days in secondary guides and is an assumption here) | Google | B1 | the sign-in consent screen for an external client; nothing else, because the Classroom and Directory reader is a domain-wide-delegated service account the school's admin authorises | the Cloud project's verification status |
| G5 | The zero-data-retention arrangement for the dedicated Anthropic organisation, in writing, and a second for the fallback route (pass 5 R15) | Anthropic sales | conversation opened B0 week 1; needed before G-AI | any student-derived generation on a real tenant; the pilot runs with the AI off until then (pass 4 challenge 6, pass 5 challenge 10) | `ai.provider_account.zdr_confirmed_at`, `zdr_evidence_ref` |
| G6 | A DPO appointed by CAROS (may be external) | Davide | B4 | G-REAL (pass 4 §1.1, §9.13) | the appointment letter; the name in the DPA |
| G7 | The DPA drafted from pass 4 §1.4, reviewed by counsel, signed by ACS with its annexes | counsel; ACS leadership and DPO | drafting from B0; signed in B4 | G-REAL, including the pseudonymised sample and the historical exports (question 46) | the signed agreement; Annex 1 generated |
| G8 | Counsel's answers C1 to C22 and this pass's C23, with the retention numbers set (C17) | counsel | engaged in B0; answered before B4's exit | G-REAL for C1, C2, C13, C17; G-AI for C3, C18, C21, C22; the letter engine for C20 | `privacy.retention_class.set_by_counsel_at`; the decisions log |
| G9 | The school's legal-basis attestation and the three approved notices | ACS DPO and leadership | B4 | the tenant leaving `onboarding` (the D45 trigger); student and parent sign-in (pass 4 §9.12 h) | `core.school.legal_basis_attestation`; `privacy.notice_version` |
| G10 | Google Workspace configuration by ACS IT: CAROS set to Limited for the staff and student units, the under-18 designation confirmed, the RISC receiver registered, the optional Directory scope (questions 110, 126) | ACS IT | onboarding step 4 | any staff or student sign-in on the real tenant | the onboarding checklist record |
| G11 | The school's IT security review and its sign-off, with the pack organised by ADEK 5.5.1 a to h and whichever questionnaire the school uses (question 113) | ACS IT | B4 | G-REAL | the pack in the DPA folder; the sign-off |
| G12 | The penetration test: an independent firm (CREST-accredited or DESC Cyber Force listed), scoped to the web application, API, authentication and tenant isolation; highs closed and retested within 30 days; yearly after (pass 4 §9.12 d) | the firm | booked in B3 (assumption: four to six weeks' lead time); run in B4 against production before it holds a real record, so the real WAF, TLS and network are tested; retests against staging | G-REAL | the report and the retest record in the pack |
| G13 | The incident tabletop with ACS IT and the CPO; yearly after | ACS | B4 | G-REAL | the exercise record |
| G14 | Cyber-liability insurance (pass 4 §9.12 f; C16) | a broker | B4 | G-REAL | the policy |
| G15 | The CPO and the delegate named, holding accounts with the `safeguarding_lead` capability; the route configured with a co-signature; a test referral delivered and acknowledged (questions 118 to 121) | ACS CPO, HS Principal | B4 | G-REAL; the escalation feature | `core.school.safeguarding_route`; the test referral's audit entries |
| G16 | The elicitation session with the four counselors (pass 3 §10.5) | ACS counselors | B4.16, before the first configuration version | shadow mode | ACS's `engine.thresholds` version 1 note |
| G17 | The weekly export pack agreed as a condition of the pilot, with the retrospective mode named as the fallback (pass 2 §6.4, question 70) | ACS IT and registrar | the pilot agreement (onboarding step 1) | the design point of the whole engine | `ingest.expected_cadence` |
| G18 | Two academic years of pseudonymised history and, if they exist, the counselors' dated handled-case records (questions 46, 83, 103) | ACS registrar and counselors, under the DPA | onboarding step 10; the backtest at week 2 | warm baselines on day one; the backtest | the import records; the backtest report or the statement that history cannot carry it |
| G19 | The Extended Essay guide per round and the criteria wording (question 133) | ACS IB coordinator | before B6.9 | the essay half of B6 | `ib.ee_round.ee_guide_key`; the descriptors entered by the school |
| G20 | Labelling sessions: twenty questions per counselor and the 30-item reviews (question 132); the coordinator's 80 EE labels (question 133); the CPO's review of the lexicon, the student message, the helplines and the 400-message corpus (question 129) | ACS counselors, IB coordinator, CPO | before each feature's acceptance in B7 | G-AI per feature | `ai.eval_run.signed_off_by` |
| G21 | Per-feature AI acceptance in writing, including the residual-retention disclosure and R8 for the student-text features (question 137) | ACS DPO and leadership | after G-LIVE, in pass 5 §9.6's order | G-AI per feature | `ai.feature_policy.accepted_at`, `school_accepted_residual_retention_at` |
| G22 | The out-of-country cold copy decision (question 62; C12) | ACS leadership; counsel | before the DPA is signed, because it is a clause either way | nothing in the build; the DPA text | the decisions log; the DPA clause |
| G23 | Fairness labels: which, on what basis (question 106; C4, C5) | ACS DPO; counsel | before the shadow-exit fairness screen | the fairness screen's coverage; without labels the plan states the claim is untested | `fairness.group_label` import records or the written "none" |
| G24 | SOC 2 Type I, then Type II; ISO/IEC 27001 (timing assumptions: six, eighteen and twenty-four months from the first real record; a Type I report is a point-in-time opinion and a Type II covers an observation period of months, per audit-firm guidance ([Drata](https://drata.com/learn/soc-2/type-1-vs-type-2), [Vanta](https://www.vanta.com/collection/soc-2/soc-2-audit-timeline)); the AICPA sets no fixed period) | an audit firm | engaged in B9 | nothing in the pilot; later schools' reviews | the reports |
| G25 | Engagement domain enablement in writing and the Classroom reader account (question 14, 84); the Veracross OAuth application and the ManageBac read-only token (questions 78, 81) | ACS IT and leadership | before B9.2 to B9.4 run for the real tenant | the connectors and the engagement domain | `core.school_module 'engagement'`; the source-system rows with `CONNECTOR_VERIFIED` |

---

## 9. Pilot-ready checklists

What each of the three people at the school would need satisfied before real students are in the system. Every line maps to a gate above, a test in §5 or a runbook in §7.7; the lists are meant to be handed over as they stand.

### 9.1 The IT team

- The DPA signed with its annexes; the sub-processor list (Azure in UAE North and UAE Central, Azure Communication Services Email, Anthropic under ZDR for the AI features only, GitHub for code); the data sources named with their hosting (pass 4 §1.3).
- The hosting statement: all student data at rest in UAE North with in-country redundancy in UAE Central, customer-managed keys in Key Vault, 35-day point-in-time restore, weekly vaulted backups; the cold-copy position as decided.
- The Google Workspace configuration done and recorded: CAROS Limited for the staff and student units; under-18 designation confirmed; the RISC receiver registered; the Directory scope if approved; 2-Step Verification enforced on their side (question 112); the school's domains in `auth.school_domain`.
- The security review pack by ADEK 5.5.1 a to h, with their chosen questionnaire answered; the ASVS 5.0 Level 2 self-assessment with links to the passing tests; the penetration test report with highs closed; the SOC 2 timeline in writing.
- The incident process and contacts (24-hour notification to the school's named contacts, updates every 24 hours, the evidence pack); the tabletop held.
- The restore drill record and the sweep-completion metric definition; the uptime checks; the maintenance window.
- The delivery path tested end to end: upload or SFTP or, later, a connector; the weekly pack's seven files run once; the first four previews to be approved by their `school_admin`; the cadence panel showing "on time".
- The support-grant path exercised once with them, so they have seen that CAROS cannot read their data without their approval and that every read is logged and visible to them.
- The retention schedule as configured, the SAR and erasure procedures, the offboarding procedure with key destruction and the destruction certificate.
- The first `school_admin` named in the DPA and holding the capability; four-eyes on a second.
- The change-freeze windows agreed (question 142) and the deploy calendar's respect for them.

### 9.2 The Child Protection Officer

- The safeguarding route configured with at least two recipients and oversight, co-signed, with the clock (continuous or school hours) and the SLA chosen (question 119); a test referral raised, delivered, acknowledged and closed by them.
- The referral email reviewed: a reference, the counselor's name, the time and a link, and nothing about the child (question 120).
- The referral form's fields and minimums matched to their policy (question 60); the outcome vocabulary matched to how they record outcomes (question 121); the ADEK 24-hour countdown shown as a reminder, never as a claim that CAROS reported.
- The direct-report banner and the contacts (ADEK CPU 80085, the Family Care Authority 800444, Police 999) confirmed as the school's own list.
- Who sees an escalation, and for how long (recipients while open and 90 days after; the lead sees existence and status only; support never without their separate approval); the SAR exclusion of safeguarding rows as the school's controller decision (C8).
- The teacher-identity rule: a reporting teacher is identified to the CPO inside CAROS and redacted from every family-facing output (Wadeema Article 44).
- The student's "I need to talk to someone" channel and the fixed message a student sees on a safety flag, written by the school, with the confirmed helplines (question 129); the two-school-hour route to the CPO when a counselor does not open a flag; all of this working in deterministic mode before any model is involved.
- Their acceptance that shadow mode records inferences nobody acts on for six to eight weeks, and who at the school may see those records (question 105).
- The mentor programme's vetting policy if and when mentors are enabled (question 122), and that sessions are never recorded by CAROS.
- Later, before the safety screen's model layer: their review of the lexicon and the corpus dispositions, and their signature on the eval run.

### 9.3 The counselor

- The elicitation session done and the first thresholds written from their answers, with every departure from the default traced to something they said; a copy of the mapping.
- Their caseload exactly right: each counselor sees their own students, the cover policy chosen (question 65, 66, 127), the `caseload_lead` named.
- What the sheet shows during shadow mode: teacher flags live, no tiers; the thirty-second daily log and the Friday prompt; the reveal sessions at weeks 4 and 8 booked; the go-live bar they set themselves (precision at check-in and above, default 60%).
- Training on the synthetic ACS tenant, with the demonstration marker visible, before they touch the real one (question 144); the morning ritual rehearsed: sign in, the sheet, "what changed overnight", open a case, accept, intervene, note, escalate.
- What parents and students can and cannot see, rendered from the matrix inside their own notice; that a counselor note is included in a subject-access pack after the school's redaction review (question 128), so they write notes knowing it.
- The escalation rehearsed with the CPO's test referral: the form, the step-up, what the CPO receives, what acknowledgement means.
- The sweep-failed banner's meaning ("tiers are as of the sweep of …") and the morning contact channel (question 147).
- Later, for the AI features: their twenty questions each and the 30-item reviews, and the knowledge that every AI output is labelled, cites its records, never ranks, and never sends anything outside the platform.

---

## 10. Risks, ranked

Likelihood and impact are judgements, not measurements. Ranked by expected cost to the pilot.

| # | Risk | Likelihood | Impact | Mitigation | Owner, when |
|---|---|---|---|---|---|
| R1 | ACS can only deliver termly data, so the academic, attendance and behaviour domains run in retrospective mode and the morning ritual is driven by teacher flags and the university rules alone | medium | high: the differentiator is not demonstrated on real data | the weekly pack as a condition of the pilot agreement with the retrospective mode named as the fallback (pass 2 §6.4); the Data API as the first fallback; the mode switch is data, not a deploy | Davide, at the pilot agreement (G17) |
| R2 | The engine's precision on real data is unknown until shadow mode, and the counselors' bar is not met at week 8 | medium | high: no go-live, or a go-live nobody trusts | shadow mode as the pilot's first phase; the counselor log as ground truth; the reveal protocol; the levers of pass 3 §11.1 in order; the backtest if history exists; the decision to extend shadow rather than lower the bar | teammate B and the counselors, weeks 6 to 12 of the pilot |
| R3 | The legal basis or ADEK Records 1.5.1 permission is not settled, and the tenant cannot leave `onboarding` | medium | high: no real data | counsel engaged in B0; the attestation mechanism supports both the provider-list and the per-family notice; the trigger makes the gate impossible to skip rather than easy to forget | Davide and counsel, B4 (G8, G9) |
| R4 | Google Workspace is not configured for under-18 users, or the school's edition lacks the control, and students cannot sign in | medium | medium: student surfaces wait; staff surfaces unaffected | the configuration as an onboarding gate with a written checklist; question 141 on the edition; students have nothing to see before B5 anyway | ACS IT, onboarding step 4 (G10) |
| R5 | Anthropic does not grant ZDR at pilot scale, or slowly | medium | low for the pilot, high for the AI features | the pilot runs with the AI off by design; the deterministic modes exist for every feature; open decision on the fallback routes (pass 5 open decision 2) | Davide, from week 1 (G5) |
| R6 | A country-level event destroys both UAE regions | low | catastrophic | the encrypted EU cold copy if the school and counsel agree (G22); otherwise the risk stated in the DPA; the Oracle fallback in the infrastructure module (pass 1 DR-1) | ACS leadership and counsel, before the DPA |
| R7 | Key-person risk: Davide holds the spine, the infrastructure and the on-call | high | high | runbooks tested by someone who did not write them; the two-person rota; the plan file and briefs written so a teammate can pick up any task; Fable 5.1 review sessions as a second reader of the critical code | Davide, continuous; reviewed at each phase end |
| R8 | The silent overwrite or the drifting documentation happen again | medium | high | the ruleset with an empty bypass list; the wholesale-replacement check; immutable migrations; generated docs; `docs:verify`; the phase-end rewrite of `CLAUDE.md`; worktrees per session | Davide, B0.3 and B0.14 |
| R9 | The frontend port drops a rule the prototype enforced | medium | medium to high (invariant 6 is such a rule) | the rule ledger before every screen; rules in the domain with tests; Fable 5.1 review of the gate ports; both tenants on every screen | each stream, every port |
| R10 | The penetration test finds an authorization hole late, delaying G-REAL | medium | medium | the RLS and matrix suites from B0; the test booked in B3 with a retest window; authorization findings fixed by Fable 5.1 | Davide, B3 to B4 (G12) |
| R11 | Teachers do not log concerns, and the corroboration rule has nothing to corroborate | medium | medium | the register leads the teacher surface; the 90-second flow at 375px; the routed note closes the loop within the school day (the event evaluation); the per-teacher rate report for the lead | teammate A and the caseload lead, from week 3 of the pilot |
| R12 | ACS keeps ManageBac and Maia as the records for CAS, EE and university lists, and the CAROS modules duplicate work | medium | medium | the record-system decision per module is data (D10); read-only imports where an API exists; the university list mirrored from Maia's CSV; the modules can be off | Mr Diaz, the counselors, at onboarding (pass 2 open decisions 5, 6) |
| R13 | The Extended Essay guide change is missed and the 2027 cohort is tracked under the 2018 milestones | medium | medium | both reflection models as milestone data; the guide per round entered by the coordinator (G19) before B6.9 | teammate C and the coordinator, B6 |
| R14 | The complete schema tempts the build to migrate everything early, and the first restore drill takes hours | medium | low | the migration map; a phase never creates a table it does not read and test | Davide, every migration review |
| R15 | Tooling churn: Vitest 5 is weeks old, Drizzle 1.0 is a release candidate, Opus 5.5 is a day old at planning time | medium | low to medium | pins; upgrades as decision records after two GA minor releases; the model registry and the promotion protocol; the cooldown on every dependency | Davide, B9.8 |
| R16 | Two people, not four | medium | medium: Demo 1 slips by about six weeks and Demo 2 by more | the streams degrade in a stated order (§2.5); the engine is Fable 5.1's with a human reviewer | Davide, decided by week 2 |
| R17 | The AI features' prose quality disappoints even when the bars pass, because the bars measure honesty, not charm | medium | low | the human sample is the shipping gate; the effort lever tuned on the suites; the counselors write the questions | teammate B and the counselors, B7 |
| R18 | The synthetic ACS tenant, shown under the school's name, is mistaken for real data in a screenshot | low | high: reputational and legal | the marker as a generated column; the written consent (G2); separate tenants for demo and real; the classification trigger | Davide, B0 and every demo |

---

## 11. Challenges

**Decisions recorded 2026-09-24 (Davide).** All four positions below are accepted. Passes 7 and 8 plan on them and do not reopen them.

- **C2 · Pilot timing.** Accepted: G-REAL aims at the first fortnight of a term; earlier weeks go to the historical backfill and the backtest. Open decision O33 is closed.
- **C4 · Sales demo.** Accepted: from Demo 1, sales demos use the Next.js staging build on the synthetic ACS tenant; the Vercel prototype stays deployed as the specification only. Open decision O11 is closed.
- **C5 · Penetration test target.** Accepted: the external test runs against production before it holds a real record; retests run against staging. Open decision O35 is closed.
- **C6 · Canary tenants in production.** Accepted: production holds two synthetic, unbranded canary tenants for the isolation canary and the nightly sweep path, excluded from every report. Pass 1 DR-9's "real tenants only" line is to be amended in pass 8 (§12 item 10).

Each names the decision or the brief it touches, the alternative, its cost and benefit, and what this pass planned on.

**C1 · The thin slice is four phases with additions.** *The brief's proposed first phase.* Argued in §1.13. Planned on the split and the five additions; nothing from the proposed list is dropped.

**C2 · "No fixed deadline" meets a school calendar.** *CONTEXT §2's "optimise for long-term correctness over speed to first demo".* Accepted, and it is why every phase ends in tests rather than dates. But the pilot has a calendar the decision does not price: shadow mode needs six weeks of weekly data in term time, and a shadow period that straddles a long holiday is dead time. The alternative, starting whenever the build is ready, risks landing G-REAL in the last fortnight of a term. Planned on the build's own pace, with one recommendation: aim G-REAL at the first fortnight of a term, and if the build is ready three weeks before a holiday, use those weeks for the historical backfill and the backtest rather than starting shadow mode.

**C3 · The tool that builds the safeguards is a Covered Model.** *Pass 4's rule R2 and the way this plan is executed.* Claude Code on Fable 5.1 writes the code that keeps a child's welfare record in the country; Fable 5.1 keeps prompts for thirty days under automated review. The rule concerns student-derived data, and an agent session holds none: the repository carries synthetic data only, a hook refuses writes containing the real-names blocklist, the `no-real-data` test covers seeds, fixtures and eval cases, `CLAUDE.md` forbids a session from holding a support grant, and the support console refuses an automation user agent. The alternative, building with a model under ZDR only, would cost the reserved model for the work it is reserved for and buy nothing, because no personal data is involved. Planned on the discipline above, and one question for counsel (C23): whether an AI coding assistant that reads source code and synthetic data, never tenant data, is a sub-processor to be named in the DPA.

**C4 · From Demo 1, the sales demo should be the Next.js build, not the frozen prototype.** *CONTEXT §3 "index.html stays deployed on Vercel for demos".* The prototype shows nine things the backend will not do (§6.3). Until Demo 1 exists it is the only demo and the script must skip those lines; from Demo 1, demonstrating it to a school describes a product that will not ship. The alternative, keeping the prototype as the sales demo, costs a false promise at every showing; switching costs nothing in the build. Recommendation, not a departure: after Demo 1 passes, sales demos use the staging build on the synthetic ACS tenant, and the Vercel deployment stays up as the specification. Davide decides (§13).

**C5 · The penetration test targets production, not staging.** *Pass 4 §9.12 d and pass 1 DR-9's staging without a WAF.* A test against staging tests no WAF, no production network and no production key configuration. Planned on: production exists from B4 and holds only the canary tenants until G-REAL, so the external test runs against production before the first real record, and retests run against staging. The cost is that production is provisioned a few weeks earlier than the first real record needs; it buys a test of the thing that will be attacked.

**C6 · Two synthetic tenants live in production.** *Pass 1 DR-9's "real tenants only".* Pass 4's nightly isolation canary needs them, and the sweep path should run in production before it runs for a child. Planned on a canary pair, unbranded, excluded from every report; §12 asks the revision pass to amend DR-9.

**C7 · The reserved-model rule is written into the plan file, not left to the session.** *The brief's "mark which work must be reviewed by a different model".* A session cannot judge whether its own task is subtle. Planned on naming the tasks (§4.2, §4.3) and carrying the model on the task line and the pull request template, so the wrong model is visible at review. The cost is some rigidity; it buys an audit trail of which model wrote what, which a school's reviewer may one day ask for.

---

## 12. For the revision pass

Inconsistencies between passes 1 to 5 that this pass planned around; each names what pass 6 planned on so that pass 8 can align the earlier files.

1. **Sweep job names and the watchdog hour.** Pass 1 DR-2 has `sweep.tick` and a watchdog at 06:00; pass 3 §13.2 has `sweep.schedule` and 05:45. Planned on pass 3.
2. **`caros_owner` cannot log in.** Pass 1 creates it `NOLOGIN` while DR-4 has migrations run as it. Planned on a `caros_migrator LOGIN` role that runs `SET ROLE caros_owner` (B0.5); pass 1 DR-4 and §2.2 should say so.
3. **Loose ends in pass 1's DDL.** `core.touch_updated_at()` is defined and attached to nothing; `audit.entry` and `events.event` carry `school_id` without a foreign key; the §2.4 comment counts four settings where `withTenant()` sets six plus two. State the intent or fix.
4. **Pass 2's onboarding contradicts pass 4 twice.** Step 18 uses `sso_jit`, which pass 4 D38 removes (memberships come from imports and administrators only); step 4 has the school "register the CAROS OAuth client", whereas pass 4 §2.1 has CAROS own the client in its own Google Cloud project and the school configure app access. Planned on pass 4.
5. **Pass 2's internal counts.** "Six saved queries" against a seven-file table; DR-14's two retrospective domains against three elsewhere; §7.8 cited where §7.9 is meant; `const` listed as a transform and defined as a binding; the shared-email option lettering; the `field_key` examples. Planned on the tables, not the prose.
6. **Pass 4's widening rule is stated three ways** (§3.1 "only narrow", §3.3 "a school may widen `signal` and `case_note`, never `safeguarding`", §3.8 "a school override wider than the default is refused"). Planned on §3.3's reading; the trigger and the test must match it.
7. **Column names differ between body and D-table in pass 4:** `training_opt_out_confirmed` versus `training_opt_out_confirmed_at` (D53); `notice_version` versus `notice_version_id` (D60). Planned on the D-tables.
8. **Feature keys differ between passes 1, 4 and 5.** Pass 1's `ai.model_config.feature` enum lacks `quarantined_reader`; pass 4 §6.4 uses `discovery`; pass 5 D74 uses `discovery_chat` and `pathway_analysis` and adds `quarantined_reader`. Planned on pass 5's keys.
9. **`covered_model` and `zdr_eligible` moved** from `ai.model_config` (pass 4 D53) to `ai.model` (pass 5 D62); pass 4 R2's enforcement text should point at the registry.
10. **Production holds two synthetic canary tenants** (pass 4 T1) against pass 1 DR-9's "real tenants only". Planned on the canary pair (§7.2); amend DR-9.
11. **The narrative seed layer and `strength`.** Pass 1 DR-8 seeds `evaluation.strength` with `strength_definition = 'prototype:unspecified'`; pass 3 D17 drops both columns and maps the authored word to `level`. Planned on writing the narrative layer in B3 against the B2 schema, so `strength` never exists; DR-8's text should change.
12. **The Extended Essay's 2027 guide.** Pass 1 §2.9 models three `rppf` milestones; pass 5 D70 adds `reflection_model` on the guide. Planned on milestones as data per round for both models (B6.9); pass 1 should carry `reflection_model` into the milestone design.
13. **ADEK Student Protection Policy section numbers** differ between the hosted copy pass 4 read and the official URL pass 5 cites. Reconcile.
14. **Google verification is unstated in pass 4.** Pass 6 adds brand verification for the external sign-in client and notes that sensitive-scope verification applies only to an OAuth client requesting such scopes; the delegated reader account is authorised by the Workspace admin. Pass 4 §2.1 should say so.
15. **Blob SFTP in UAE North** (pass 2 open decision 17): Microsoft's page lists no regions; the check stays a portal check in B4.9, and the fallback stands.
16. **Audit action keys** from pass 1 (84), pass 2 D9, pass 4 D48 and pass 5 D71 are seeded together in B0; the passes should say the taxonomy is one list.
17. **Reveal weeks.** Pass 3 counts weeks 4 and 8 of shadow; the pilot overlay counts from G-REAL with shadow starting at week 2. The pilot agreement should count from shadow's first sweep, as pass 3 does.
18. **D15 is subsumed** by pass 4's matrix, and D11, D56, D58 and D60 land with the tables that carry them (§1.12). The D-tables of passes 2 to 5 should note the phase each lands in.

---
## 13. Consolidated open decisions

Every open decision from passes 1 to 5, plus this pass's own, deduplicated and ordered by what blocks what. The source column gives the pass and its decision number (`P3#4` is pass 3's fourth); ACS questions and counsel questions are cited where the decision waits on them. Decisions a later pass already closed are listed at the end so nobody reopens them.

**Tier A · blocks B0 and the first commits. Davide decides, mostly in week one.**

| # | Decision (source) | Options | Recommendation | Who decides |
|---|---|---|---|---|
| O1 | Infrastructure tool (P1#5) | Terraform/OpenTofu with `azurerm`; Bicep | Terraform/OpenTofu | Davide |
| O2 | RPC layer (P1#4) | tRPC 11; oRPC | tRPC; Hono with zod-openapi for the connector API when a non-TypeScript caller exists | Davide |
| O3 | PostgreSQL major (P1#6) | 17; 18 | 17 at pilot; 18 at year 1 once the extension list is clean | Davide |
| O4 | Test runner (P1#18) | Vitest 5; Vitest 4.1 | 5 | Davide |
| O5 | Second synthetic school's name and regulator (P1#14; Q69) | Wellesmere (KHDA) after a directory check; a Sharjah school | Wellesmere, checked | Davide |
| O6 | Repository plan (pass 6) | GitHub Team; Free with weaker protections | Team, for rulesets, environments and code-owner review on a private repository | Davide |
| O7 | Signal strength and confidence (P3#3) | removed, level and breadth shown; a defined composite meter | removed; the B3 port prints level, breadth and window | Davide |
| O8 | XLSX at pilot (P2#13) | accept, read as text; CSV only | accept | Davide |
| O9 | Delivery mechanism and the SFTP implementation (P2#2, P2#17) | Studio upload; Blob SFTP; a container | upload for the first four weeks; Blob SFTP from week five if UAE North shows it in the portal, else the container | Davide, ACS IT |
| O10 | Grace period before a withdrawn person's status becomes `left` (P2#14) | 0, 14, 30 days | 14 | Davide |
| O11 | The sales demo after Demo 1 (pass 6 C4) | the frozen prototype on Vercel; the Next.js staging build on the synthetic ACS tenant | the Next.js build, with the prototype kept deployed as the specification | Davide |
| O12 | Who takes streams A, B and C (pass 6 §2.1) | any assignment; two people | decide by week 2 and record it in `PLAN.md` | Davide |
| O13 | Frozen copies of the passes in the backend repository (pass 6 §3.6) | `docs/spec/` copies with the commit hash; links to the prototype repository | copies | Davide |
| O14 | Production maintenance window (pass 6 §7.2) | custom, Saturday 09:00 local; system-managed | custom | Davide |

**Tier B · blocks G-REAL, the first real record. ACS leadership and DPO, counsel, the CPO and IT, with Davide.**

| # | Decision (source) | Options | Recommendation | Who decides |
|---|---|---|---|---|
| O15 | Encrypted out-of-country cold copy of backups (P1#1, P4#1; Q62; C12) | none, risk stated in the DPA; an EU copy under a UAE-held key with a DPA clause | the EU copy if ACS and counsel agree in writing; otherwise the risk stated | ACS leadership, counsel, Davide |
| O16 | Every retention number, the vaulted horizon and CAROS's tombstoned audit copy (P1#16, P4#7, P4#15, P4#16; Q33, Q64, Q116; C9, C10, C17) | as proposed; shorter; longer; 1, 3 or 5 yearly copies; keep 7 years or delete at termination | as proposed, 3 years, keep; counsel sets the numbers in `privacy.retention_class` | counsel |
| O17 | Legal basis for the core processing and the ADEK Records 1.5.1 mechanism (pass 4 §1.5; Q109; C1, C13) | contractual and legal-obligation bases with the provider list in enrolment terms; consent | the bases with the provider list; consent only for optional features | ACS DPO, counsel |
| O18 | Parent activation mode (P4#2; Q124) | out-of-band code; knowledge-based | codes | ACS, Davide |
| O19 | Escalation SLA, clock and the referral form's minimums (P4#19, P1#9 resolved as structured; Q60, Q119) | 120 minutes continuous; a school-hours clock; 40 and 20 characters or ACS's numbers | 120 minutes, continuous; 40 and 20 unless ACS says otherwise | ACS CPO |
| O20 | Subject-access defaults (P4#11; Q128; C7, C8) | notes included, safeguarding excluded, teacher authorship redacted; a stricter school policy | as pass 4 §7.4 | ACS DPO, counsel |
| O21 | Parental access when a student turns 18 (P4#10; C6) | continues by default, student may object; ends unless re-consented | continues by default | counsel, ACS |
| O22 | Break-glass cover parameters (P4#18; Q127) | 24 hours, 20-character reason, weekly digest; other values | as proposed | ACS counselors |
| O23 | Directory API reconciliation (P4#12; Q110) | RISC only; RISC plus a nightly Directory read | both, if the scope is approved | ACS IT |
| O24 | The delivery cadence ACS commits to (P2#1; Q70, Q73) | weekly pack; nightly Data API; fortnightly; termly with the retrospective mode named | weekly for the pilot; never termly without naming the mode in the agreement | ACS IT and registrar, Davide |
| O25 | Auto-approve defaults after four green weeks (P2#3) | facts only; facts and empty-security-section rosters; everything | facts and empty-security-section rosters | Davide, ACS `school_admin` |
| O26 | Two guardians sharing one email (P2#4, accepted by pass 4 with conditions; Q59, Q125) | one person with both contacts and co-holder codes; reject the second; a two-account login | one person with co-holder codes | ACS, Davide |
| O27 | The CAS and Extended Essay record system, and the university list of record (P2#5, P2#6; Q8 to Q13) | ManageBac stays with the modules off; CAROS with a one-time import; Maia mirrored read-only; CAROS | ask Mr Diaz; Maia mirrored while ACS uses it | ACS coordinator and counselors |
| O28 | Google Classroom as a source and the engagement domain (P1#10, P2#7, P3#2, P4#14; Q14, Q84) | off; on with pass 4 §6.6's seven conditions, with or without Classroom | off until ACS answers and approves the notice; then on with Classroom if accepted | ACS, pass 4's conditions |
| O29 | Fairness labels (P3#12, P4#17; Q106; C4, C5) | none; a subset; all four | a subset the DPO agrees to, under the EU AI Act Article 10(5) pattern; if none, the claim is stated as untested | ACS DPO, counsel |
| O30 | Certification order (P4#13) | SOC 2 Type I then II then ISO 27001; ISO first | SOC 2 first | Davide |
| O31 | Cyber-liability insurance (pass 4 §9.12 f; C16) | bind before G-REAL; later | before G-REAL | Davide |
| O32 | Who activates a threshold version in shadow (P3#15) | caseload lead with the engineer's acknowledgement; any counselor; the engineer | the lead with the acknowledgement | Davide, ACS counselors |
| O33 | When the pilot starts relative to the term (pass 6 C2) | when the build is ready; the first fortnight of a term | the first fortnight of a term, using any earlier weeks for the backfill and backtest | Davide, ACS leadership |
| O34 | A synthetic training tenant under the ACS name in production (pass 6; Q144; G2) | yes, marker on, covered by the consent letter; train on staging only | yes, if the consent letter covers it | ACS leadership, Davide |
| O35 | The penetration test's target (pass 6 C5) | production before the first real record; staging | production, retests on staging | Davide |
| O36 | Who may author and activate profiles after onboarding (P2#10; P2#11 resolved by pass 4 for rollback) | CAROS only; `school_admin` with CAROS review of a new import kind for a year | `school_admin` edits and dry-runs; CAROS reviews a new import kind for the first year | Davide |

**Tier C · blocks G-LIVE, the shadow exit. ACS counselors and the CPO, with Davide.**

| # | Decision (source) | Options | Recommendation | Who decides |
|---|---|---|---|---|
| O37 | Event-triggered evaluation for flags, context and enrolment changes (P3#1; Q67) | nightly only; the hybrid with the daytime asymmetry | the hybrid | Davide; ACS counselors on whether daytime raises are welcome |
| O38 | Commit-triggered evaluation (P2#12, P3#8) | never; the scheduled pack only; every commit | the scheduled pack only during shadow; per school policy after | Davide, ACS counselors |
| O39 | Relapse uplift (P3#4; Q90) | 0, 1, 2 tiers | 1 | ACS counselors |
| O40 | The common-cause guard (P3#5; Q95) | on at 25%; off | on | ACS counselors |
| O41 | The engine may propose `urgent` for the corroboration pattern (P3#6; Q89, Q104) | proposes; stops at `checkin` with a route flag | proposes | ACS CPO and counselors |
| O42 | Threshold scope (P3#7) | per school; per-counselor overrides | per school; revisit after the elicitation | Davide |
| O43 | `shock_opens_monitor` (P3#9) | true; false | true, measured in shadow | ACS counselors |
| O44 | Grade 8 history for Grade 9 entrants (P3#10; Q99) | import from the same SIS; do not | import if ACS exports it | ACS registrar |
| O45 | Inheritance across a level change (P3#11) | off; on | off | ACS coordinator |
| O46 | The counselor log's cadence (P3#13; Q96) | daily; weekly | daily, thirty seconds | ACS counselors |
| O47 | The shadow-exit precision bar (P3#14; Q92, Q93) | 60% at check-in and above; the counselors' number | the counselors' number | ACS counselors |
| O48 | The retrospective tier cap (P3#16) | review; monitor | review | ACS counselors |
| O49 | Recovery weeks (P3#17; Q98) | 2 to 6 | 3 | ACS counselors |
| O50 | Whether a risk-adding context may ever lower a tier (P3#18; Q91) | never; the school's choice per kind | never | ACS counselors and CPO |
| O51 | The scale estimator (P3#19) | MAD; Qn if the backtest shows lead time lost | MAD | Davide, after the backtest |
| O52 | Case lifecycle defaults (P1#11) | 90-day window, 14-day auto-review, 02:00 sweep; others | the prototype's numbers as version 1 | ACS counselors |
| O53 | Who is in the Diploma cohort in the choosing year (P1#15; Q68) | every Grade 10 student; only those who declared | every Grade 10 at ACS, confirmed | ACS |
| O54 | The school's override widening counselor visibility (P1#8 resolved by pass 4 as caseload plus cover; Q65, Q66) | keep caseload plus cover; widen `signal` and `case_note` to school scope by school override | keep, unless the team asks for the override | ACS counselors |

**Tier D · blocks G-AI, per feature. Davide, the ACS DPO, counsel, the CPO and the counselors.**

| # | Decision (source) | Options | Recommendation | Who decides |
|---|---|---|---|---|
| O55 | If Anthropic does not grant ZDR, or not in time (P5#2) | run with the AI off; Enterprise Frontier Safeguards when available; an in-country route | off, because shadow mode runs AI-off anyway; the others only with counsel | Davide |
| O56 | Provider and inference location (P5#1; Q138; C3, C21) | Claude API, US-pinned ZDR; an in-country route for another provider's models after evaluation; the safety screen alone moved in-country | the Claude API for v1; the year-1 review with counsel's answer and the eval scores | Davide, ACS DPO, counsel |
| O57 | Legal basis for the AI transfer (P4#4; C3, C18) | contractual safeguards plus notice; express custodian consent per family | contractual safeguards; consent if the DPO prefers | ACS DPO, counsel |
| O58 | AI features during shadow mode (P4#5) | off; on for staff-only features | off | Davide, ACS |
| O59 | Default models (P5#3) | Opus 5.5 writes, Sonnet 5 classifies; Sonnet 5 everywhere; Opus 5 anywhere | as designed; revisit when Sonnet 5.5 and Haiku 5.5 pass the promotion protocol | Davide, after the first eval runs |
| O60 | Covered Models after Enterprise Frontier Safeguards (P4#3, P5#19) | keep the exclusion; re-evaluate when EFS documents where retained data lives | keep; a dated review when EFS is generally available | Davide |
| O61 | Counselor note bodies in meeting briefs (P4#6, P5#11) | excluded; included by school policy | excluded | ACS counselors, DPO |
| O62 | The quarantined reader (P5#4) | on for every untrusted kind; teacher flags only; off | on | Davide |
| O63 | Discovery conversation shape (P5#5) | the scripted bank with model phrasing; free-form | scripted | Davide, ACS counselors |
| O64 | Layer 2 of the safety screen (P5#6; Q130) | on with R8 acceptance; pattern-only | on; the school decides under R8 | ACS safeguarding lead |
| O65 | Envelope delivery to the model (P5#7) | a JSON user turn; a read-only tool result | measure both in the AI phase's first week; keep the better | Davide |
| O66 | Refusal fallback mechanism (P5#8) | client-side to a named row; the server-side array form | client-side for v1 | Davide |
| O67 | Embeddings (P5#9) | none; pgvector in UAE North for lookup only | none until a measured need | Davide |
| O68 | Headline rephrase shown before review (P5#10) | shown with the rule wording beside it; held until approved | shown; a school may hold | ACS counselors |
| O69 | The parent draft's language (P5#12; Q131) | bilingual pair with English as the record; target language with a translator; English only | bilingual pair | ACS |
| O70 | What the student is told about AI (P5#13) | the plain-language label and the "your counselor can read this" line; a longer notice | as designed, inside the student notice | ACS DPO |
| O71 | Eval labelling by the school (P5#14; Q132) | the school labels, paid or in kind; CAROS alone | the school labels | ACS leadership |
| O72 | The strongest-match margin and minimum tags (P5#15) | 2 points and 3 tags; other values | as assumed until the discovery eval tunes them | Davide |
| O73 | The alumni precedent's small-cell threshold (P5#16) | 5; 10 | 5 | ACS DPO |
| O74 | Daily AI cost ceiling per school (P5#17) | $10 at pilot; another figure | $10 | Davide |
| O75 | Activation order of the features (P5#18; Q137) | pass 5 §9.6's order; the school's own | pass 5's order | ACS |
| O76 | UK course-level offer rates (P5#20) | none, university pages only; buy the UCAS Courses Data Service | none for the pilot | Davide |
| O77 | SMS reminders to the CPO (P4#8) | none in v1; a third-party provider with UAE coverage carrying the reference only | v1.1, once email has run a term | Davide, ACS CPO |
| O78 | Mentor session recording on the school's own platform (P4#9, resolved for CAROS as never; Q123) | the school records under its own policy; not at all | the school's choice | ACS |

**Tier E · year 1 and later. Davide, with ACS for the connectors.**

| # | Decision (source) | Options | Recommendation | Who decides |
|---|---|---|---|---|
| O79 | When to re-evaluate AWS `me-central-1` (P1#2) | never; when AWS resumes billing and publishes a restoration statement | the latter; the module keeps the option cheap | Davide |
| O80 | Built-in PgBouncer (P1#12) | never; at year 3 after the RLS suite passes under transaction pooling | year 3 | Davide |
| O81 | OneRoster profile family (P2#15) | in the thin slice; after the pilot | after the pilot | Davide |
| O82 | Veracross path for a connector (P2#16; Q81) | Data API v3; API Plus (OneRoster) | the Data API; API Plus only if ACS already licenses it and only for rosters and grades | Davide, ACS |
| O83 | Connector order (pass 2 §13; Q77, Q81) | Veracross, ManageBac, Classroom in the order ACS's answers dictate | decided at week five of the pilot | Davide, ACS |
| O84 | In-country inference (P5#1 option c) | keep the US route; move the safety screen first; move more | review at year 1 with C3 and the scores | Davide, ACS DPO, counsel |
| O85 | Letter engine generation (CONTEXT §3 deferred; C20) | after real letters exist to draft and time; never | after, and only once counsel answers C20 and voice samples exist with consent | Davide |
| O86 | Certification timing (pass 4 §9.12 c) | SOC 2 Type I at six months from the first real record; later | six months (assumption; the audit firm sets it) | Davide |

**Closed by a later pass, listed so they are not reopened:** WAF timing (P1#3) is "from the first real data", two weeks early in detection mode (pass 4 §9.9); the session privilege model (P1#7) is one acting role per session (pass 4 §2.4); the audit hash chain (P1#13) is on, anchored weekly (pass 4 §4.2); `strength` and `contribution` (P1#17) are removed (pass 3 §9); the escalation reason (P1#9) is a structured form (pass 4 §5.3; the minimums are O19); counselor visibility (P1#8) is caseload plus explicit cover (pass 4 §3.3; the override is O54); staged-row and raw-file retention (P2#9) are 30 and 90 days (pass 4 §7.1); rollback authority (P2#11) is the `school_admin` (pass 4 §3.6); shadow-row retention (P3#20) follows live signals (pass 4 §7.1); mentor session recording by CAROS (P4#9) is never.

---

## 14. Consolidated questions for ACS

Every question from `ACS-IT-QUESTIONS.md` (1 to 49) and passes 1 to 5 (50 to 140), deduplicated and grouped by who at the school would answer, with the original numbers in brackets so the revision pass can merge them under the file's headings. Questions this pass adds are numbered 141 to 147.

### 14.1 Systems and data · IT, registrar

- **The weekly export pack.** Can Veracross export grades, attendance and behaviour as files, per assessment and per session, weekly, ideally scheduled to a file drop CAROS hosts in the UAE; who owns it and who covers holidays; if not weekly, fortnightly; and could a read-only Data API connection replace the files later, under which security role and licence? [1, 2, 2a, 7, 70, 73, 81]
- **Attendance detail.** Per lesson as well as per day; lateness in minutes; early dismissal; whether the reason is a coded field; the code list used for ADEK's eSIS uploads and the attendance policy text. [3, 71, 72]
- **Behaviour.** Where incidents are recorded; the conduct-point or category scheme; which categories the engine should treat as serious on their own. [4, 101]
- **Rosters and the timetable.** Class lists with teachers; the period grid and rotation; whether the Grade 10 mathematics sets are identifiable; which weekdays and half days; term dates, exam and mock periods and reporting windows as an export each year. [5, 16, 50, 51, 52, 54]
- **Grade scales.** Per programme (IB, AP, ACS High School), what appears in the export; whether predicted grades are separate from working grades and where IB predictions are recorded and reported from; do all sections keep a gradebook in Veracross, or some in ManageBac, Classroom or on paper. [53, 75, 77, 102]
- **Contacts.** Guardian contacts with relationships, families with several children, shared email addresses, and whether the addresses are reliable enough for a sign-in link. [6, 21, 59, 125]
- **History.** How far back assignment grades, attendance and behaviour can be exported with dates; whether Grade 9 entrants' middle-school rows are in the same instance; whether the school holds dated records of the students counselors supported in the last two years, pseudonymisable alongside the export. [46, 83, 99, 100, 103]
- **Identifiers.** Whether Veracross Person IDs are stable and never reused; whether ManageBac's `student_id` is the Veracross number and the same Google address is used everywhere. [74, 82]
- **ManageBac.** What it is used for today; whether CAROS should read from it, take over some of the work, or neither; whether it holds prior CAS hours; whether ACS would create a read-only API token; which region hosts ACS. [8, 9, 10, 55, 76, 78]
- **Maia Learning.** What counselors and students do in it; what would never move; whether data can come out (a weekly CSV, an API), and its privacy policy and hosting for the DPA. [11, 12, 13, 79, 80]
- **Google Classroom and other systems.** Whether Classroom is used across the high school and whether the school would accept CAROS reading assignment activity through a dedicated reader account with domain-wide delegation; what other systems hold student information (wellbeing, safeguarding, learning support). [14, 15, 84]
- **Destinations.** Whether past graduates' destinations can be exported as counts. [139]
- **Who uploads.** Who would upload exports and maintain the mapping, and whether the registrar is an appropriate person to see whole-school previews. [56, 85]
- **New, pass 6.** Which Google Workspace edition ACS runs, because the control that blocks under-18 users from unconfigured third-party apps exists only in Education editions ([Google Workspace admin help](https://support.google.com/a/answer/13288950)), and who administers app access and how long adding a trusted app takes. [141]
- **New, pass 6.** Whether ACS IT would like access to a staging tenant with synthetic data for their own review before the first real import. [143]
- **New, pass 6.** Whether ACS has a Veracross sandbox or test instance CAROS could use when the connector is built after the pilot. [146]

### 14.2 Identity and accounts · IT, front office

- Which Google Workspace domains staff and students use; whether teachers share the counselors' domain; whether all Grade 9 to 12 students sign in regularly; whether 2-Step Verification is enforced. [17, 18, 58, 112]
- The process and timeline for approving a third-party app that uses Google sign-in; whether IT would approve the read-only Directory scope on the delegated reader account; whether CAROS may register a Cross-Account Protection receiver for the domain. [19, 110, 126]
- How leavers' accounts are removed, so CAROS follows the same signal. [20]
- Whether the CPO wants a CAROS account to acknowledge escalations. [57]
- How the school would hand each parent a one-time activation code, and whether families sharing an address want one shared login or separate addresses. [124, 125]
- Whether an existing process vets adults who interact with students, and whether it would apply to alumni mentors. [22, 122]
- **New, pass 6.** Staffroom and shared-device practices (shared logins, kiosk machines) that affect session timeouts and the "lock this file" control. [145]

### 14.3 Safeguarding · Lead Child Protection Officer, HS Principal

- Who the Child Protection Coordinator and the nominated delegate are, whether either is a counselor, and who receives CAROS escalations, including cover. [23, 24, 118]
- What a referral must contain at minimum and whether a structured form is closer to policy than a twelve-character reason. [60]
- The acknowledgement SLA, whether the clock runs outside school hours, who is told when a referral is not acknowledged, and what should happen then. [61, 119]
- Whether an email carrying only a reference, the counselor's name, the time and a link is acceptable. [25, 120]
- Whether a safeguarding system is already in use that escalations should feed instead of email. [26]
- How a worrying message in a chat or a draft should reach a human; the lexicon, the fixed student message and the helpline list to review; the alert volume at which the threshold should be raised. [27, 129, 130]
- What is staff-only (notes, concerns, the tier); which teacher-concern tags must route to the CPO regardless; whether the engine may propose `urgent` for a corroboration pattern. [28, 89, 104]
- Whether CAROS's outcome vocabulary matches how outcomes are recorded and whether the 24-hour ADEK window should show as a reminder. [121]
- Whether shadow-mode inferences about real students are acceptable under school policy and who may see them. [105]
- Where mentor sessions should be held and whether the school records them. [123]

### 14.4 Data protection, hosting and legal · data protection lead, leadership, legal

- Whether ADEK requires in-country hosting (none of the policies read requires it), and any business-continuity expectation for downtime and data loss. [29, 63]
- The DPA template, its signatory, and who ACS's data protection lead is and whether they approve support grants. [30, 31, 114]
- How consent is handled at enrolment and whether the enrolment terms name educational providers or a published list, so that adding CAROS satisfies ADEK Records 1.5.1. [32, 109]
- Retention: what ADEK or ACS policy requires for counseling and child-protection records, and whether ACS's Data Protection Policy names retention or vendor requirements. [33, 64, 116]
- How a parent's request for everything held is handled today, and whether counselor notes are expected in it. [34, 128]
- The AI features: whether pseudonymised processing outside the UAE is acceptable, what must never go to a model, which features should be on for the live phase and which stay deterministic, whether inference location matters beyond the PDPL, and whether aggregate safety-screen dispositions may tune the screen. [35, 135, 137, 138]
- What the IT security review consists of (questionnaire, pen test, certifications, site visit) and who signs off. [36, 113]
- The encrypted EU backup copy, or written acceptance of the country-level risk. [62]
- Whether there are under-13 students in Grades 9 to 12. [115]
- Who issues the notices to students and parents, and who approves the text. [117]
- Whether parents should see behaviour incidents in CAROS. [111]
- Fairness labels: whether nationality, gender, language background and SEN status may be supplied for the audit, on what basis; what families should be told about shadow mode and when. [106, 107]
- Written consent to use the ACS name and crest on synthetic data, including a training tenant. [49, 144 in part]

### 14.5 For the counselors · the HS counseling team

- The elicitation session: ninety minutes together before the engine is configured, plus a short individual form; the vignettes and the numbers of pass 3 §10.5. [37 to 42, 86, 87, 88, 92, 93, 94, 97, 98]
- Whether a known family circumstance should make the engine quieter, louder or the same; how much more serious a relapse is; whether a school-wide dip should be held. [90, 91, 95]
- The caseload split and cover: whether counselors see each other's cases by default, only when covering, or never; who covers absences and whether cover is time-boxed; whether a 24-hour self-service cover is acceptable. [43, 65, 66, 127]
- Whether context added to a case should change the tier immediately or overnight. [67]
- Shadow mode: whether they will keep a thirty-second daily log; whether four to eight weeks with no visible tiers is acceptable; the precision bar they would set. [44, 96, 108]
- The AI features: twenty questions each and review of the samples; which parent-message languages are needed and who checks a translation; whether one suggested opening line in a brief is useful; the reach and match thresholds. [131, 132, 136, 140]
- Which counselor and year groups pilot first, and what would make leadership call it a success. [45, 48]
- **New, pass 6.** Whether the team would train on a synthetic ACS tenant, with the demonstration marker visible, before shadow mode. [144]
- **New, pass 6.** Who is the morning contact when the overnight sweep has failed, by what channel, before 07:30. [147]

### 14.6 IB · the Diploma coordinator

- Whether every Grade 10 student is in the selection round or only those who declared. [68]
- Which Extended Essay guide each current cohort is assessed under, and the criteria wording from the school's copy. [133]
- The school's policy on AI feedback on a research question and what must be declared to the IB. [134]
- Whether ManageBac stays the record for CAS and the essay, or CAROS takes over with a one-time import. [9, 55]

### 14.7 The pilot · leadership, counseling team

- What each of the counselor, the CPO and IT would need to see before using CAROS with real students (this pass's §9 is the proposed answer). [47]
- Whether CAROS may name a fictional second school in its test data. [69]
- **New, pass 6.** Change-freeze periods (exam weeks, reporting weeks, inspections) during which CAROS should not deploy or schedule maintenance. [142]

### 14.8 Questions for counsel

C1 to C22 from passes 4 and 5 stand. This pass adds:

- **C23 (§11 C3).** Is an AI coding assistant that reads the platform's source code and synthetic data, and never a school's tenant data, a sub-processor that the DPA must name, and does the discipline described (no real data in the repository, tests and hooks that enforce it) need to appear in the DPA's security annex?

---

## Sources

Retrieved 2026-09-23 by this pass. Facts taken from passes 1 to 5 are cited to those passes, whose own Sources sections carry the vendor, regulatory and research pages they verified.

- GitHub: about rulesets https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets; about protected branches https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches; about code owners https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners; managing environments https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments; about GitHub Advanced Security https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security; about GitHub-hosted runners https://docs.github.com/en/actions/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners
- Microsoft Learn: authenticate to Azure from GitHub Actions by OpenID Connect https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect; Azure Container Apps revisions https://learn.microsoft.com/en-us/azure/container-apps/revisions; Azure Monitor action groups (SMS and voice country lists) https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups; SFTP support for Azure Blob Storage https://learn.microsoft.com/en-us/azure/storage/blobs/secure-file-transfer-protocol-support; planned maintenance for Azure Database for PostgreSQL flexible server https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-maintenance
- pnpm settings, dependency resolution (`minimumReleaseAge`, added in v10.16.0, default 1440 minutes since v11) https://pnpm.io/settings/dependency-resolution
- Drizzle Kit `check` https://orm.drizzle.team/docs/drizzle-kit-check
- OWASP Application Security Verification Standard repository https://github.com/OWASP/ASVS (the 5.0.0 release date and level structure are taken from secondary summaries; the project page returned HTTP 404 to this pass)
- Claude Code documentation: memory and CLAUDE.md https://code.claude.com/docs/en/memory; hooks https://code.claude.com/docs/en/hooks; common workflows (worktrees) https://code.claude.com/docs/en/common-workflows
- Google: sensitive scope verification https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification; manage access to unconfigured third-party apps for users designated as under 18 https://support.google.com/a/answer/13288950
- CREST, Dubai Cyber Force programme https://www.crest-approved.org/membership/dubai-cyber-force-program/
- SOC 2 Type I and Type II descriptions (secondary): Drata https://drata.com/learn/soc-2/type-1-vs-type-2; Vanta https://www.vanta.com/collection/soc-2/soc-2-audit-timeline
- Claude API pricing https://platform.claude.com/docs/en/about-claude/pricing (Opus 5.5 and Sonnet 5 prices as verified by pass 5 on 2026-09-23; the Fable 5.1 figure as carried in the bundled Claude API skill's table dated 2026-06-24, not re-fetched)
- The prototype: `index.html` at commit `fb28217` (the router at lines 9003 to 9099, `roleNav` at 1898, `bind()` at 9141, `PRIO` at 1300, the view functions listed in §6.2); `PHASES.md` (the 98 route-states, the model and effort line format)
- The plan: `backend-plan/CONTEXT.md`, `PRODUCT.md`, `backend-plan/ACS-IT-QUESTIONS.md`, `backend-plan/out/01-architecture-and-data-model.md`, `02-ingest-and-integrations.md`, `03-signal-engine.md`, `04-security-privacy-compliance.md`, `05-ai-design.md`

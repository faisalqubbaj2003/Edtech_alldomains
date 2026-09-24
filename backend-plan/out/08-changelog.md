# CAROS backend · Pass 8 · Changelog

Pass 8 revises passes 1 to 6 to apply Davide's 107 decisions on the pass 7 review (`07-review.md`, decisions recorded 2026-09-24). It runs in three sessions. This file records every change each session makes, the finding or judgment call that caused it, and the file and section it touched, and hands forward what later sessions still owe.

**Conventions.** F01 to F78 are pass 7's findings; §12.1 to §12.18 are the items of its A.5 (pass 6's inconsistency list); C1 to C11 are its judgment calls. "01 §2.4" means section 2.4 of `01-architecture-and-data-model.md`, and so on. "Decision on F09" means the `Decision (2026-09-24)` line under that finding. Pass 6's own judgment calls (its C2 to C6) are written "pass 6 decision C5" to keep them apart from pass 7's.

---

## Session 1 (2026-09-24): passes 1 and 4

Session 1 revised `01-architecture-and-data-model.md` and `04-security-privacy-compliance.md` in place, and changed no other file. Pass 7's section B ("Keep") was respected: every item it lists still stands in both files, and where a decision changed a kept design (the RLS layers, permissions as data, the reference-only escalation email, Google sign-in, parent magic links, mentor controls, the support principle, the AI rules, the demonstration marker), the change is the one the finding names and nothing wider.

### How the decisions were applied

These notes record where applying a decision needed a reading, so that Davide can check it.

1. **No new D-numbers.** Pass 4's deltas D33 to D61 are revised in place, so pass 6's migration map keeps its keys. Changes to pass 1's own tables, and new tables, are written into pass 1's DDL, which is the design source; 01 §0.3 lists them, and pass 6 must place them (handoff).
2. **A `staff` role** (01 §2.4, 04 §0.1 item 7). F16 makes `school_admin` a role and gives oversight a capability with no data grants, and F10 lets any staff role hold `safeguarding_lead`. A Principal or a CPO in the leadership team is neither counselor nor teacher, so a role with no data access of its own was needed to carry those capabilities. CONTEXT §3 allows "more roles later if needed".
3. **C1's words "no model reads student text"** are applied to the safety screen, which is what the judgment call framed. A literal reading would also switch off discovery chat, the statement read and Extended Essay feedback, all v1 features in CONTEXT §3. This is recorded as pass 4 open decision 20 for Davide to confirm.
4. **Mentor invitations are handed over off-email** (04 §2.3). C3 lists the staff emails kept and sends everything else in-app, but a mentor has no account before the invitation, and F16 forbids a credential in the outbox. The coordinator therefore hands the code over, as the school does for parent activation. Recorded as pass 4 open decision 21.
5. **Break-glass "never self-assigned"** (F16) is read as: break-glass stays a practising counselor's own emergency act, but is confirmed by the lead the same school day or lapses, is rate-limited, and nobody who administers cover (a lead or a school admin) can assign cover or a capability to themselves.
6. **F35's point 3** (two CAROS operators could activate a grant without the school) is applied by removing the CAROS-only emergency approval entirely: during an incident with the school unreachable, CAROS works on infrastructure and aggregates until a school approver responds.
7. **The leadership contact under F09** is told by the same reference-only safety-alert email C3 keeps for counselors, and oversight of unacknowledged referrals (a Principal) is in-app, because C3 lists no oversight email.
8. **"Never names" (decision on F60) applies to the escalation email too.** The CPO's email no longer names the raising counselor; the fallback line points to the counseling office. Section B keeps the email "as a reference only, rendered from an allowlist with a content test", which this preserves.
9. **A teacher's safeguarding referral opens a case** if none is open (01 C23), so that an escalation still always hangs off a case and the engine's pin applies; the teacher never sees the case.
10. **F31's "different timezone and weekend"** is applied as a third, CI-only synthetic tenant (`wellesmere-shifted`, `Europe/London`, Friday and Saturday weekend), rather than giving the fictional Dubai school a timezone it could not have.
11. **F14's reads under the escalation scope** are never included in a subject-access pack, even by the school's per-item act; every other professional record can be included item by item, as C4 says.
12. **F38 against C7.** F38 asked for B2.9 to be Fable-written; C7, decided the same day, has Opus 5.5 write every task and Fable review diffs only. Session 1 made no pass 6 change; the handoff applies F38 as "add a Fable review" under C7.

**Numbering used, for sessions 2 and 3 to continue from.** Questions for ACS 148 to 155 (the next is 156); questions for counsel C24 to C32 (the next is C33); pass 4 open decisions 20 to 22; pass 1 case transitions C23 to C25; pass 4 threat T21. Pass 4 question 126 is withdrawn (F18).

### Changes to `01-architecture-and-data-model.md`

| # | Change | Caused by | Section |
|---|---|---|---|
| 1.1 | Revision note under the title; §0.1 declares two additions (the `school_admin` and `staff` roles; outbound email per C2 and C3) and corrects the cold-copy framing | F16, F10, C2, C3, F22, F04 | header, §0.1 |
| 1.2 | New §0.3 summarising what pass 8 changed | all | §0.3 |
| 1.3 | Escalation reason row notes pass 4's structured form | pass 4 D46 | §0.2 |
| 1.4 | AWS facts corrected: disruption began 1 March 2026; UAE loss limited to data only in `mec1-az2`; Bahrain region-wide, and the country-level precedent; "relevant" billing operations | F73 | DR-1 context, §5.1, Sources |
| 1.5 | Cost table: HA storage billed twice; seven lines added (Blob SFTP, Defender for Storage, Key Vault HSM keys and the UAE Central vault, Entra ID P2, NAT gateway, support plan for Customer Lockbox); totals recomputed (pilot about $1,341 production, $1,547 with staging); two prices re-read from the Retail Prices API, three marked assumptions | F71, F61 | DR-1 cost |
| 1.6 | Residency consequence: a copy abroad needs key material abroad and ADEK consent | F22, F04 | DR-1 consequences |
| 1.7 | Migrations: Drizzle's migrator runs one transaction; a second non-transactional step for `-- no-transaction` files; `CONCURRENTLY` not needed at pilot scale | F40 | DR-2, DR-9 |
| 1.8 | Sweep job names and watchdog hour follow pass 3 (`sweep.schedule`, 05:45); scheduling keys on schools holding data via `core.schools_due_for_sweep()` | §12.1, F36 | DR-2 |
| 1.9 | pg-boss under its own login `caros_jobs` with no tenant privilege; `jobs.enqueue()` validates payloads as ids; completed jobs deleted after 7 days; registered as a non-tenant store; cross-school job test | F36 | DR-2, §2.2, §2.21 |
| 1.10 | Review discipline: solo mode while Davide builds alone; CODEOWNERS and two approvals from the second regular builder | C8, F46 | DR-3, §4 |
| 1.11 | One login role and managed identity per deployable (`caros_web`, `caros_worker`, `caros_support`, `caros_migrator`, `caros_jobs`), all `NOINHERIT`; `caros_owner` cannot log in and the migrator uses `SET ROLE` | F01, §12.2 | DR-4, §2.2 |
| 1.12 | The tier is evaluated in the policy expression (`current_user`) and passed to `auth.allowed()`; system and support honoured only for their tiers; user claims only for the membership's tier | F01 | DR-4, §2.4 |
| 1.13 | Separate teacher tier `caros_t_teacher`; the AI tier `caros_t_ai` listed and granted to web and worker | F75, F44 | DR-4, §2.2 |
| 1.14 | Policies take a per-row class, a row kind, addressee and pairing subjects, and accept the table's verb in insert and update policies | F02, F15 | DR-4, §2.4 |
| 1.15 | RLS tests added: web identity cannot `SET ROLE` to system, support or owner; `NOINHERIT` test; every verb end to end; every qualifier's negative fixture | F01, F02 | DR-4 tests |
| 1.16 | Reporting as per-tenant aggregate tables under RLS with one writer, never materialised views; convention test fails on a materialised view; `reporting` schema created | F34 | DR-6, §2.1, §2.2 |
| 1.17 | Case transitions: engine never lowers or closes a case with an unreleased escalation (C4, C11, C21); person's tier change releases the pin (C10); merge only within one student (C12); escalation uniqueness is one open per case plus an idempotency key, with `previous_escalation_id` (C15); acknowledgement by `safeguarding_lead` on any staff role (C16) | F07, F10 | DR-7.1 |
| 1.18 | New transitions C23 (a teacher's safeguarding referral, opening a case if none), C24 (information added to an open escalation), C25 (link cases across students); C13 writes `routed_key` | F10, F07, F58 | DR-7.1 |
| 1.19 | Selection: `ib.sign_off()` only, HL picks in an open round, signed as the acting teacher; sign-off card without the band; S6 records `review_meeting_version`; S7 guarded by `ib.check_approval`; definer transition functions; column-level updates; imports never write picks; IB-only engine stated as a known limitation | F17, F58, F65 | DR-7.3 |
| 1.20 | Extended Essay: rounds name their guide; ACS defaults to `ee_2027` (one reflective statement), `ee_2018` for resits; E7 and E9 read the guide; ManageBac as read-only record where kept, E1 to E10 disabled there | F62, §12.12, C10 | DR-7.4, §2.10 |
| 1.21 | Seed: fictional coordinator replaces the real ACS name; CPO on a `staff` membership; consent covers third-party sales demos; `purpose 'demo'`; regulator profile applies | F29, F43, F42, F31, F10 | DR-8 |
| 1.22 | Seed: no `strength` in any seed; narrative layer written against pass 3's schema | §12.11 | DR-8, §2.9 |
| 1.23 | Seed: `CONCERN_SUBMIT` mapped to `TEACHER_FLAG`; the `AI_DRAFT` letter entry dropped | F72 | DR-8 |
| 1.24 | Seed: `seed://` numbers never render ("not on file"); `seed://` sources staging only; production check | F30 | DR-8, §2.7 |
| 1.25 | Seed: `COURSE_CATALOG` to per-school rows, not global `ref.*`; archetype steps by programme family | F65 | DR-8, §2.7 |
| 1.26 | Seed: statements as sectioned versions; `PS_SYSTEMS` guidance and the "AI read" score not ported | F32, F66 | DR-8 |
| 1.27 | Seed: EE rounds on the 2027 guide; word limit and marks from the guide, confirmed by the coordinator | F62, F77 | DR-8 |
| 1.28 | `engine-reproduces-seed` runs over both tenants with generated expected-result lists; Wellesmere's eight cases have results from the start | F06, F31 | DR-8 |
| 1.29 | Wellesmere: explicit empty KHDA profile; tutor and Head of Year columns imported into pastoral assignments; a restricted contact in the fixture; DSL on a teacher membership | F31, F33, F57 | DR-8 |
| 1.30 | Second-school checklist: portal from the school's rule set; per-destination deadlines ("UCAS-only" removed); no "ADEK" on any Wellesmere screen, template or email; CI-only `wellesmere-shifted` tenant for timezone and weekend | F31, F65 | DR-8 |
| 1.31 | Environments: staging maps only CAROS test domains; pinned demo revision with deploy freeze and an untouched demo tenant; drills in their own subscription; production holds only real tenants and the unbranded canary pair | F43, F42, pass 6 decision C6 | DR-9 |
| 1.32 | Canary as a Container Apps job in UAE North, refusing non-canary tenants and asserting its own school id on every row; no production credential on agent machines | F42, F23 | DR-9 |
| 1.33 | Cold copy reframed as the real choice (EU ciphertext with keys abroad and an EU drill, or in-country only), ADEK consent first; restore-drill checks run in UAE North | F22, F04, F23 | DR-9 |
| 1.34 | Conventions 11 to 15: column-level writes from `writable_columns`; definer functions never executable by `PUBLIC`; no materialised views; `updated_at` by trigger; vocabularies instead of CHECK lists | F15, F17, F75, F34, §12.3, F65 | §2.1 |
| 1.35 | `core.school`: `purpose` (customer, canary, demo), immutable; one status model (onboarding, shadow, live, suspended, offboarding, offboarded) with a transition trigger; rows never deleted; classification, purpose and branding immutable; a synthetic tenant's letterhead is CAROS-only | F42, F36, F67 | §2.3 |
| 1.36 | `core.person`: guardians sharing an email stay separate persons (partial unique index) | F57 | §2.3 |
| 1.37 | `auth` schema rewritten: tiers; scopes `esc`, `addressee`, `lead_cover`, `own_pairing`, `year_group`, `tutor_group`; `auth.scope_rank()` for the narrowing rule; data classes split and added (`contact_record`, `safety_alert`, `guardian_link`, `xp`, `membership`, `session`, `notification`, `support_grant`, `privacy_request`); roles `school_admin` and `staff`; capabilities by allowed roles, with `safeguarding_oversight`, `year_lead`, `tutor`, `ucas_adviser`; `role_permission` key includes scope and `row_kind`; the first version's inline default rows withdrawn in favour of pass 4 §3.6 | F02, F15, F16, F13, F77, F33, F10, F47 | §2.4 |
| 1.38 | `auth.capability_grant` (four eyes, never to oneself); caseload validity in timestamps; `auth.pastoral_assignment` | F16, F33 | §2.4 |
| 1.39 | Pre-tenant lookups as ID-only definer functions (`auth.school_for_domain`, `auth.school_for_magic_link`, `core.schools_due_for_sweep`, `core.schools_holding_data`, `notify.schools_with_due_outbox`) | F36, F35 | §2.4, §2.18 |
| 1.40 | Scope predicates: timestamps in `in_caseload`; activation and restriction in `is_guardian_of`; new `is_pairing_mentor`, `esc_covers`, `lead_cover_active`, `in_led_year_group`, `in_tutor_group`, `support_grant_covers` (operator and table); diploma cohort through `ref.programme_family` | F57, F59, F02, F33, F35, F65 | §2.4 |
| 1.41 | `auth.allowed()` rewritten (tier argument, table, row kind, addressee, pairing, support branch by operator and table); `auth.protect()` rewritten (class expression, kind, addressee, pairing, verbs) | F01, F02, F35 | §2.4 |
| 1.42 | `notify.enqueue()`: the one way a tier writes the outbox; template and sender checks; no credential in a payload | F02, F16 | §2.4 |
| 1.43 | Definer helpers owned by `caros_policy`, `EXECUTE` revoked from `PUBLIC`; only `auth.allowed()` granted to tiers | F75 | §2.4 |
| 1.44 | Comment on transaction settings corrected (six settings plus the actor label and `SET LOCAL ROLE`) | §12.3 | §2.4 |
| 1.45 | New §2.4a: every qualifier in pass 4 §3.6 mapped to its mechanism and negative test; the matrix generated from one data file for rows and tests | F02 | §2.4a |
| 1.46 | `ref.programme_family` table replaces the ENUM (adds `ib_cp`, `igcse`, `btec`); `sis.enrolment_programme` for more than one programme; `stage_key` no longer drives the portal | F65 | §2.5 |
| 1.47 | `sis.tutor_group` and `sis.tutor_group_member`; FKs for pastoral assignments | F33 | §2.5 |
| 1.48 | `engagement.activity_event.source` and `ingest.source_system.kind` become vocabularies | F65 | §2.6, §2.16 |
| 1.49 | `ref.destination_system` table replaces the ENUM (adds `uc`); columns retyped | F65 | §2.7, §2.11 |
| 1.50 | IGCSE scale keys | F65 | §2.7 |
| 1.51 | `ref.statement_format` and `ref.reference_format` (UCAS three questions; UCAS reference sections; `generation_forbidden`) | F32 | §2.7 |
| 1.52 | `ref.regulator_profile` (contacts with hours and verified dates, reporting window and owner, category-route defaults, citations, outcome vocabulary, indicators, retention minimums, attendance reason family, review-pack checklist); empty profile for a regulator not yet analysed | F31, F09, F11, F55, F77 | §2.7 |
| 1.53 | Rule set `portal`; vocabularies `guide_course`, `engagement_source`, `source_system_kind`, `teacher_flag_routed` | F65, F58 | §2.8 |
| 1.54 | Vocabulary versions and an append-only `config.vocabulary_history`; engine snapshots attributes into rule hits | F48 | §2.8 |
| 1.55 | Flag kind `safeguarding` | F10 | §2.9 |
| 1.56 | `signal.case.shadow`: shadow cases run the live lifecycle, one open live and one open shadow case per student, read as `signal_shadow`; `evidence_item.evaluation_id` | F24 | §2.9 |
| 1.57 | Headline is never model output; `headline_generation_id` removed | F52 | §2.9 |
| 1.58 | `signal.case_escalation_pin` trigger (no engine lowering or auto-close while an escalation is unreleased; merge only within one student) | F07 | §2.9 |
| 1.59 | `signal.case_link` table | F07 | §2.9 |
| 1.60 | `signal.escalation`: `UNIQUE (school_id, case_id)` removed (replaced in D46); comment rewritten; `signal.escalation_update` table | F07 | §2.9 |
| 1.61 | Teacher flags: `routed_key` vocabulary that never reveals a case; teacher tier cannot read `case_id` or `status`; the modal's disclosure rule; flags for roster, subject and EE students; `escalation_id`; idempotency key; flag text screened by the lexicon | F58, F10, F07, C1 | §2.9 |
| 1.62 | Student reflections: the student never reads `safety_flag` | F13 | §2.9, §2.22 |
| 1.63 | `core.meeting` classed `contact_record`, staff-only; the coordinator records review conversations for the whole cohort | F15, F02 | §2.9, §2.22 |
| 1.64 | `signal.week_run()` reads the engine's `outside` flag instead of recomputing from the band | F40 | §2.9 |
| 1.65 | `ib.selection.review_meeting_version`; `ib.check_approval` trigger; sign-off through `ib.sign_off()` and `ib.v_signoff_card` | F17, F58 | §2.10 |
| 1.66 | CAS entries may be `managebac_mirror` rows; EE word limit from the guide; reflection comments for both guides; `v_diploma_cohort` through programme families | C10, F62, F77, F65 | §2.10 |
| 1.67 | Statements per destination and entry year, sectioned; `uni.statement_complete()`; references with a format, centre statement, predicted-grade snapshot; `uni.centre_statement`; `uni.school_deadline`; application pack reports completeness, not characters | F32 | §2.11 |
| 1.68 | XP ledger in its own class `xp`, student-only | F77 | §2.12, §2.22 |
| 1.69 | Guardian links: one person per SIS contact, activation per contact, restriction flags, guardians never write links; family messages scoped by sender and recipient | F57, F15 | §2.13, §2.22 |
| 1.70 | Mentors: subjects through the pairing; own-pairing scope; parents see only the pairing and headline; coordinator creates pairings; `mentor.session.mode` in person on premises only | F59, C6 | §2.14, §2.22 |
| 1.71 | Files read under their own class and kind; raw exports for the school admin only, never support | F15, F35 | §2.15, §2.22 |
| 1.72 | Access-changing imports need a different approver and never auto-approve | F57 | §2.16 |
| 1.73 | AI feature keys aligned with pass 5, less `headline_rephrase` and `safety_screen`, and without `letter_draft`; model flags on pass 5's registry | §12.8, §12.9, F52, C1 | §2.17 |
| 1.74 | `ai.reidentify()` in place of reading the pseudonym map | F44 | §2.17, §2.22 |
| 1.75 | Templates listed per pass 4 §5.8; `sender_roles`; send-time idempotency by outbox id; tokens minted at send time | F28, F02, F77, F16 | §2.18 |
| 1.76 | Audit taxonomy is one list (dedupe `PREVIEW_ACCESS` and `sweep.completed`); `allowed_tiers` on actions and event names; `audit.record()` and `events.emit()` check the caller's tier; school FKs on `audit.entry` and `events.event` | §12.16, F75, §12.3 | §2.19, §2.20 |
| 1.77 | `writable_columns` in the registry; `privacy.retention_override`; `privacy.non_tenant_store` | F15, F17, F65, F36 | §2.21 |
| 1.78 | Grants rewritten: no table-wide user writes; teacher tier column limits; no `signal` schema grant for students; safety-flag columns revoked from student, guardian and mentor tiers; contact columns only through a view; support tier on masked views only | F13, F15, F17, F35, F44, F58, F75 | §2.22 |
| 1.79 | `core.school` write policy uses the new `auth.allowed()` signature; projection views listed as the only definer views | F01, F02 | §2.22 |
| 1.80 | Every `protect()` call revised: derived subjects for child tables, shadow classes, verbs, kinds, addressees, pairings; attendance with its section subject; new tables protected; `updated_at` triggers attached; `PUBLIC` revoked on every definer | F02, F13, F15, F16, F24, F59, F75, §12.3 | §2.22 |
| 1.81 | Closing paragraph on defaults rewritten (narrow-only until question 65) | F47 | §2.22 |
| 1.82 | ER summary and module map updated (pastoral assignments, shadow cases, escalations, formats, aggregates, regulator profiles, owners after C8) | F33, F24, F07, F32, F34, F31, C8 | §3, §4 |
| 1.83 | Challenges 5.1 (dates, keys abroad, ADEK), 5.3 (settled by C2), 5.4 (roles revised), 5.5 (pass 4 adopted the form), 5.7 (no framework caching), new 5.8 (known limitations) | F73, F22, F04, C2, F60, F16, F10, F75, F65 | §5 |
| 1.84 | Open decisions 1, 7, 8, 9, 13, 15, 17 updated or closed | F22, F04, F01, F47, F29 | §6 |
| 1.85 | §7 points to this changelog's handoff; question 62 rewritten; question 56 names the role | F22, F16 | §7, §8 |
| 1.86 | Sources: AWS date, Register URL with `/5296830`, re-checked prices, migrator behaviour | F73, F71, F40 | Sources |

### Changes to `04-security-privacy-compliance.md`

| # | Change | Caused by | Section |
|---|---|---|---|
| 4.1 | Revision note; clause numbers now ADEK Student Protection Policy v1.1 | F55 | header |
| 4.2 | §0.1 rewritten: declares the departures the decisions make (content-free parent email; declared staff safety emails; the CPO notice route; teacher referrals; per-item SAR inclusion; two roles; lexicon-only screen; two AI features out); activation code not emailed; model flags on the registry | C2, C3, F28, F12, F10, C4, F14, F16, C1, F52, F77, §12.9 | §0.1 |
| 4.3 | §0.2 rows: escalation email names a role; Year head as data; safeguarding lead on any staff role; routed label; mentor sessions in person | F60, F33, F10, F58, C6 | §0.2 |
| 4.4 | §0.4 points 2, 3, 5, 6 revised (Directory read; database verbs and per-deployable identities; each reporter's 24-hour duty; the truth about free text; ADEK consent) | F18, F01, F02, F09, F20, C1, F04 | §0.4 |
| 4.5 | New §0.5 summarising the revision | all | §0.5 |
| 4.6 | Regulator: Data Office merged into the Federal Authority for AI and Data; regulations still unissued | F37 | §1.1, §1.4, §9.6, Sources |
| 4.7 | PDPL corrections: Article 9(2) conflict with ADEK 6.6.1; Article 13 a right to information with refusal grounds; Article 21 is the DPIA (CAROS drafts it; G-REAL item); Article 23's contract route narrower; Articles 5(7) and 8(4) added | F37, F14 | §1.1 |
| 4.8 | Wadeema Article 44 quotation marked as shortened; teachers' internal referral noted | F37 (citation register), F10 | §1.1 |
| 4.9 | ADEK Student Protection Policy re-cited as v1.1 with renumbered clauses; 24-hour duty is each staff member's; 3.7 emergencies; question on vendor holding case reports | F55, F09, F37 | §1.1 |
| 4.10 | Records Policy corrected (1.5.1 under transfers; five-year clause scope; 2.1.2.b clinic records) | F37 | §1.1, §7 |
| 4.11 | Digital Policy: 7.1.3.a (ADEK consent before a contractor shares data) and 6.4 (live virtual visitors) added; 7.1.2 consent procedures; ADEK consent gate and the ask-ACS-first sequence | F04, C6, F37 | §1.1 |
| 4.12 | Student Mental Health Policy cited: 3.5.1(a) and (b), 3.6; category routing as school configuration confirmed with the CPO | F09, F37 | §1.1 |
| 4.13 | Guidance Policy: four indicators, counted over one population, in the ADEK profile | F77, F31 | §1.1 |
| 4.14 | Hosting paragraph rewritten on 7.1.3.a | F04 | §1.1 |
| 4.15 | Child Digital Safety Law: under-13 gate reaches the record; consent at import; Cabinet Resolution No. 106 of 2026 noted | F56 | §1.1, §1.5, D58 |
| 4.16 | Cybercrimes Article 6; Penal Code 431 and 432 corrected | F37 (citation register) | §1.1, T7 |
| 4.17 | ICT Health Law: counselors in DoH-licensed centres may produce health data; 25-year retention; no SEN label in the pilot | F37, C11 | §1.1 |
| 4.18 | SDPC figure corrected (more than 222,000 agreements) | F37 (citation register) | §1.2 |
| 4.19 | Sub-processors: email polled not via Event Grid; Azure Monitor action groups (counts only); Microsoft engineers under Customer Lockbox; Anthropic only after ADEK consent; coding assistant; GitHub runners never read production; cold copy needs keys abroad and ADEK consent | F60, F61, F04, F23, C7, F22 | §1.3 |
| 4.20 | DPA outline: confidentiality with managed devices and location; cross-border clause with ADEK consent and the free-text truth; breach clause names the new regulator and the 9(2) conflict; DPIA row; retention row with overrides, portal delivery, pseudonymised tombstones; demonstration consent covers sales demos; fairness audit not in the pilot; school-side responsibilities annex | F61, F04, F20, F37, F65, F76, F29, F43, C11 | §1.4 |
| 4.21 | Lawful basis: three weaknesses flagged to counsel; under-13 processing; status model gate; notices state inference in the US, the free-text truth, both retention periods, no model on the screen, mentors abroad; C5 default and question 148; only the student requests after 18 | F37, F56, F36, F76, F20, F63, C1, C5, F14 | §1.5 |
| 4.22 | Google binding by email only for a person with no stored subject; Google brand verification stated; RISC dropped for Workspace; Directory read mandatory and hourly for staff; leaver runbook step | F75, §12.14, F18 | §2.1 |
| 4.23 | Parents: activation per contact enforced in the database; later links pending until approved; one person per SIS contact, restrictions suspend one contact only; reactivation enforced | F57 | §2.2 |
| 4.24 | Mentors: ADEK SPP v1.1 and Digital 6.4 cited; invitation code off-email; own pairing only, first names by default, mentors abroad; pattern holds without a classifier; grooming email to the coordinator, in-app to the lead; sessions in person only | F55, F04, C3, F16, F59, F76, C1, C6 | §2.3 |
| 4.25 | Step-up: `auth_time` through `claims`, ten-minute rule, B1 spike, staff passkey fallback; revocation list without RISC | F19, F18 | §2.4 |
| 4.26 | Identity administration: school admin as a role; bootstrap grant; domain mapping on DNS proof, approval and audit; four eyes for every capability, never for oneself; no welfare access | F16, F35 | §2.5 |
| 4.27 | Permission model: scope and row kind in the key; new capabilities; the widening rule stated once (narrow-only; the counselor widening option kept ready behind `allow_counselor_widening`); sensitivity for new classes | F02, F16, F33, F10, F47, F13, F15, F77 | §3.1 |
| 4.28 | Enforcement: tier in the policy; verbs enforced by the database; transition functions and column grants; worker's cross-tenant reads only through ID-only functions; jobs under their own login | F01, F02, F15, F17, F36 | §3.2 |
| 4.29 | Cover: timestamps; never self-assigned; break-glass only for practising counselors, two in seven days, lead confirms the same day; pastoral assignments; narrow-only until question 65 | F16, F33, F47 | §3.3 |
| 4.30 | Teachers: own tier; codes only; flag view; sign-off card without the band; routed label vocabulary; `ib.sign_off()`; concern paths for subject and EE students; the disclosure rule; the safeguarding flag as a referral | F75, F58, F10 | §3.4 |
| 4.31 | Students and parents: no meeting notes, contact log, safety alerts or XP for parents; messages by sender and recipient; own link rows only; mentor view; C5 at 18 | F15, F13, F77, F59, C5 | §3.5 |
| 4.32 | Permission matrix rewritten: new scope codes, the school admin role column, a pastoral column, new classes, per-kind qualifiers and projection views; rules for the `staff` role, oversight and leadership contacts; the "no access" symbol written as "none" | F02, F10, F13, F15, F16, F33, F58, F59, F77, style | §3.6 |
| 4.33 | Support path: every CAROS write under a school-approved write grant; request names mode, tables, location; no activation without the school; separate console app; grants bound to operator and table; masked views only; real data shown only in person or on the school's platform; Customer Lockbox; access from abroad and counsel question | F35, F61 | §3.7 |
| 4.34 | Tests: verbs positive and negative through RLS; every qualifier's negative fixture; flagged fixture per role; narrowing rule; deployable roles; support by operator and table; cross-school jobs | F02, F13, F15, F47, F01, F35, F36 | §3.8 |
| 4.35 | Audit: pass 8 action keys; tier allowlists; migration review under C8; SAR access history excluded by default; tombstoned audit copy is pseudonymised, a counsel question | F07, F09, F10, F12, F16, F35, F36, F75, F77, C8, F46, F14, C4, F37 | §4.1 to §4.4 |
| 4.36 | Escalation defined against v1.1; the reporter's own countdown and direct-report route from the start; contacts from the regulator profile; no clause numbers in UI text; teachers can escalate | F09, F55, F31, F10 | §5.1 |
| 4.37 | Route: any staff role holds `safeguarding_lead`; oversight holds `safeguarding_oversight` and gets in-app notices; leadership and emergency contacts; `safety_alert_routes` confirmed by the CPO; nightly route validation | F10, F16, C3, F09, F77 | §5.2 |
| 4.38 | The act: teacher referrals; `immediate_risk = yes` shows 999 and the Principal and notifies the whole route; one open escalation per case plus idempotency; linked later escalations; the pin; `notify.enqueue()`; the email names a role only; reminders and deputy by email, oversight in-app; the 24-hour banner restates the reporter's duty without clause numbers; updates while open; outcome vocabulary from the profile; after closing | F10, F09, F07, F02, F60, C3, F55, F31 | §5.3 |
| 4.39 | Content test covers every §5.8 email, no names, role-only senders | F60, F12, F28 | §5.4 |
| 4.40 | Channels: emails content-free; delivery status polled; no SMS in v1; ops payloads counts only | F60, C3 | §5.5 |
| 4.41 | Who sees an escalation: v1.1 numbering; status view; SAR requests about an escalated student go to the safeguarding lead; default exclusions | F55, F14, C4 | §5.6 |
| 4.42 | Student disclosures rewritten: lexicon only; every hit reaches a person; alerts staff-only and explainable; routing by category; safety-alert email; the CPO's reference-only "alert unopened" notice; helpline list split, draft until the CPO confirms, verified dates; teacher flag text screened; urgent requests never extracted | C1, F03, F13, F48, F09, F12, F11, F10, F21 | §5.7 |
| 4.43 | New §5.8: every outbound message, with recipient, channel, trigger, content allowlist and basis | F28, C2, C3, F60, F12, F77, F16 | §5.8 |
| 4.44 | AI position: Article 23 corrected, no settled basis until counsel; ADEK consent a named gate before G-AI | F37, F04 | §6.1 |
| 4.45 | Rules: R2 points at the registry; R3 both retention periods; R4 name rule tested on Arabic names, script and nicknames, independent recall, fingerprint stripped, statements not pseudonymisable, no user id, `ai.reidentify()`; R6 as columns with the free-text truth and an allowlisted AI tier; R7 nightly AI as the case owner; R8 lexicon screen and C1's scope; R9 column name | §12.9, F63, F20, F76, F44, F21, C1, §12.7 | §6.2 |
| 4.46 | Features: safety screen no model; "AI read" not ported; headline rephrase dropped | C1, F66, F52 | §6.3 |
| 4.47 | Allowlist: discovery keys; headline row removed; safety screen as lexicon; quarantined reader row allowlisted per record kind, extracting lazily | §12.8, F52, C1, F21 | §6.4 |
| 4.48 | Fairness audit: no labels in the pilot; "safeguarding" definition quoted correctly; pre-registered, pooled comparisons | C11, F55, F68 | §6.5 |
| 4.49 | Engagement flag column name | §12.7 | §6.6 |
| 4.50 | Retention: per-school overrides; Records Policy scope; safety alerts in `welfare`; `xp` row; fairness labels none in the pilot; law list with 5(7), 8(4), ICT Health 25 years | F65, F37, F48, F77, C11 | §7, §7.1, §7.2 |
| 4.51 | Erasure: non-tenant stores; tombstones are pseudonymised, a counsel question | F36, F37 | §7.3 |
| 4.52 | Subject access rewritten: narrower Article 13 reading; only the student after 18; escalated students routed to the safeguarding lead; professional records and escalation-linked items excluded by default; per-item inclusion as an explicit act | C4, F14, F37 | §7.4 |
| 4.53 | Offboarding: exit pack in the portal; `offboarding` status; school row kept as `offboarded`; audit copy subject to counsel | F76, F36, F37 | §7.5 |
| 4.54 | Threat model: T1 (no framework caching; aggregate tables; canary in UAE North keyed on `purpose`); T2; T4 (step-up proof; Directory read); T7 (articles; grants bound; Lockbox); T8 (different approver); T11 (content-free emails); T12 (own pairing; pattern holds; in person); T14 (C8); T16 (immutability; blocklist of real names; sales-demo consent); T20 (free text; both retention periods; ADEK); new T21 (development tooling) | F75, F34, F42, F10, F19, F18, F37, F35, F61, F57, F60, F59, C1, C6, C8, F67, F29, F43, F20, F63, F04, F23 | §8 |
| 4.55 | Browser leaks: self-hosted fonts, `font-src 'self'`, spell check off on sensitive fields, Chrome policy in the IT checklist | F76 | §9.1 |
| 4.56 | Key backups restore only in-geography, hence keys abroad for the cold copy | F22 | §9.2 |
| 4.57 | Veracross token scopes refuse alerts and health; Data Export Package password rotation | F54 | §9.3 |
| 4.58 | Ops alerts carry counts, not student ids | F60 | §9.4 |
| 4.59 | Incidents: new regulator; 9(2) against 6.6.1 flagged each time; on-call paging escalation job | F37, F45 | §9.6 |
| 4.60 | Cold copy rewritten as the real choice, ADEK consent first | F22, F04 | §9.7 |
| 4.61 | SFTP: password path for Veracross's scheduled export with IP allow-listing and 90-day rotation; cost noted | F54, §12.15, F71 | §9.10 |
| 4.62 | Controls a reviewer can see: canary results; qualifier fixtures; verb and narrowing suites; no-ADEK test; blocklist of every real person's name; development-tooling controls | F42, F02, F13, F47, F31, F29, F23 | §9.11 |
| 4.63 | Review pack from the regulator profile; production pen test before real data; retest split; yearly rules of engagement | F31, pass 6 decision C5, F41, F61 | §9.12 |
| 4.64 | Pre-real-data list: DPIA; 7.1.3.a clause; notices' free-text truth; Directory scope instead of RISC; step-up spike; verb suite; category routes and helplines confirmed by the CPO; ADEK consent for AI | F37, F04, F20, F18, F19, F02, F09, F11 | §9.13 |
| 4.65 | Deltas revised in place: D33 (new class sensitivities; pass 3 D30 keys), D35 (capability roles), D36 (widening rule; `allow_counselor_widening`), D37 (DNS proof, approval, definer-only writes), D39 (step-up evidence), D42 (per-contact links, restriction, no co-holder), D43 (never self-assigned, lead confirmation, lapse), D44 (kind, mode, write functions, school approval, location), D45 (status gate, category routes, verified contacts), D46 (idempotency, partial unique index, previous escalation, pin release, reporter deadline, teacher referral), D47 (§5.8 templates, role not name), D48 (pass 8 keys, `PREVIEW_ACCESS` removed, tier lists), D49 (inclusion reasons; outcomes from the profile), D50 (`xp`; overrides), D53 (flags to the registry; ADEK consent reference; reader kinds), D55 (allowlist), D56 (no hard-coded timezone), D57 (in-person sessions; coordinator pairings), D58 (under-13 consent), D59 (teacher tier), D61 (tests); note that D42, D44 and D46 land with `auth.allowed()` | F13, F15, F16, F77, F10, F47, F35, F43, F19, F57, F61, F36, F09, F11, F07, F28, F60, §12.16, F75, C4, F31, F65, §12.9, F04, F21, F44, C6, F59, F56, F02, F29, F42 | §10 |
| 4.66 | Sources: ADEK SPP v1.1 and Mental Health Policy URLs; Digital Policy clauses re-read; regulator merger | F55, F09, F04, F37 | Sources |
| 4.67 | Challenges 5, 7, 8, 9, 12 revised | C6, F22, F04, F16, F47, C4, F14 | Challenges |
| 4.68 | Open decisions 1, 4, 8, 9, 10, 11, 12, 17, 18 updated or closed; new 20 (C1's scope), 21 (mentor invitation channel), 22 (fictional coordinator name) | F22, F04, F37, C3, C6, C5, C4, F18, C11, F16, C1, F29 | Open decisions |
| 4.69 | "For other passes" points to this handoff; RISC deliverable replaced by the Directory read | F18 | For other passes |
| 4.70 | Questions for ACS 110, 114, 118 to 121, 123, 126 (withdrawn), 128 revised; 148 to 155 added | F18, F35, F10, C3, F60, F09, C6, C4, C5, F04, F57, F37 | Questions for ACS |
| 4.71 | Counsel questions C1, C2, C3, C5, C7, C8, C9, C12, C13, C15 revised; C24 to C32 added | F37, F56, F04, F14, F22, F55, F09, F61 | Questions for counsel |

### Decided items that needed nothing in 01 or 04

Their changes belong to other files and are all in the handoff below: F05, F08, F25, F26, F38, F39, F49, F50, F51, F53, F64, F68 (its engine parts; its fairness part is in 04 §6.5), F69, F70, F74, F78, §12.4, §12.5, §12.17, §12.18 (applied through F40), C9. C7 appears in 04 only as a fact (the coding assistant runs under a ZDR organisation); its build rule is pass 6's.

---

## Handoff to sessions 2 and 3

Every change another file still needs, with its finding number. Session 1 did not edit these files.

### `02-ingest-and-integrations.md`

- **F16.** D15's row `('counselor','config','configure','school','school_admin')` becomes a row for the `school_admin` role, which is no longer a counselor capability; D15 is subsumed by pass 4's matrix in any case (§12.18).
- **F17.** An import never writes a pick: a ManageBac or SIS level that differs from an approved pick becomes a conflict row for the coordinator (02 §7.4, reconcile 02:863 with 02:877).
- **F23.** Onboarding sample rows keep no free-text columns, or are processed only in-country (02 §9).
- **F25.** When a termly file carries per-assignment rows, describe delivery so the engine can backfill weekly (with pass 3).
- **F27, C10.** Add `managebac_readonly` to D10's `cas.record_system` and `extended_essay.record_system`; design the read-only mirror in §7.4 and §7.9 over the v2p3 Projects resources (CAS experiences with approval status, hours per strand, supervisor, CAS-project flag and dates; hours required; PBL projects including the DP Extended Essay template for first assessment 2027; no TOK endpoint, no CAS reflection text); mirror rows arrive as `source = 'managebac_mirror'` (01 §2.10); pin v2p3 (v2p2 is being retired); ask ACS question 78 whether the EE PBL template is enabled; correct the Challenges and open decision 5.
- **F31.** Fix the Wellesmere fixture so its eight authored cases can be produced (gradebook due dates and missing flags; the mock dip as a level input); import `TutorStaffId` and `HeadOfYear StaffId` into `sis.tutor_group*` and `auth.pastoral_assignment` (01 §2.4, §2.5, F33); support the CI-only `wellesmere-shifted` variant (01 DR-8).
- **F33.** The staff import (§4.8) creates pastoral assignments; §8.2's Wellesmere columns are imported.
- **F35.** Onboarding (§9 steps 3, 5, 8, 11, 17; §2.10): the tenant is created under the bootstrap grant (pass 4 §2.5, D44); mapping profiles are authored under a write grant; the caseload CSV loads through the Studio with a security section and preview; support rollbacks only under a write grant.
- **F40, §12.18.** Note the phase each delta lands in (with pass 6's map).
- **F54.** Add Veracross's Data Export Package as delivery option (a) in open decision 1 and question 70 (scheduled, up to twice a day, 14 runs a week, status emails; five-minute query limit; each export overwrites the last); support password SFTP with IP allow-listing and rotation for that path (pass 4 §9.10); the Veracross `verify()` refuses the alerts and health scopes; the rate limit is 300 requests per 3 minutes per access token.
- **F57.** List guardian-link gains individually in the preview's security section; uploader and approver differ for rosters, staff, contacts and caseloads; access-changing imports never auto-approve (reconcile with pass 4, which now agrees); fixtures only from a signed manifest; one person per SIS contact, never merged (supersedes open decision 4's option (b)); import restriction flags into `family.guardian_link.restriction` (D42); a new link for an activated contact is pending until the import is approved.
- **F61.** Onboarding screen-shares show real data only in person or on the school's own video platform (02:1062).
- **F65.** Attendance reasons for Wellesmere from a KHDA reason family, or a question, not DfE register codes; source systems and engagement sources as vocabularies; programme families as `ref.programme_family` (with `igcse`, `btec`, `ib_cp`) and `sis.enrolment_programme` for more than one programme; the IGCSE scale in §5.2.
- **F74.** Correct §7.3 to §7.8: API Plus has Rostering and Gradebook, no Resources, API format not OneRoster CSV; the 1EdTech listing is expired (one OneRoster 1.1 entry from 2022); ManageBac `deleted_since` covers students, parents and teachers only, `modified_since` is missing on attendance, grades, term grades and Projects, gradebook grades page at 10, tokens carry configurable scopes; a Classroom verified teacher sees only their own courses; the Edlink article does not mention `OAuth_App_Admin`; fix the §7.8 and §7.9 cross-references and 02:113 (§7.7 should be §7.8).
- **F75.** D12's views are `security_invoker`; align §4.2's staff binding with pass 4 §2.1 (bind by email only when the person has no stored Google subject).
- **§12.4.** Step 18 no longer uses `sso_jit`; step 4: CAROS owns the OAuth client and the school configures app access; add Google's rule that users designated under 18 are blocked from unconfigured third-party apps.
- **§12.5.** Internal counts: six against seven saved queries (02:735, 02:1107, 02:738 to 02:746); DR-14's two against three retrospective domains (02:66, 02:718); §7.8 cited for §7.9 (02:70, 02:249, 02:328); `const` as transform and binding (02:50, 02:376).
- **§12.15.** Blob SFTP in UAE North remains a portal check; $0.30 an hour per account; Veracross's export offers password SFTP only.
- **§12.16.** `PREVIEW_ACCESS` stays in D9; pass 4 D48 no longer seeds it.
- **Style.** Two em dashes remain in 02; remove them when the file is revised.

### `03-signal-engine.md`

- **F05, C9.** Attendance in days from the master register; a day-level floor; a minimum meaningful change above one day; unexplained absences counted in days over non-overlapping windows; z capped inside the CUSUM (for example at 3) with strong shocks through their own rule; the chart restarted when a case opens; exit and recovery on levels and the run-mean since the case opened, not on S; attendance held at weak until ACS's reason-code coverage is measured; detune before the pilot (day-level attendance, floors at the full typical noise, three weeks of persistence); re-trace Maryam and S3.
- **F06.** At least twenty in-band weeks in the fixture, or imported prior-year attendance; the expected diff generated by running the rules; a punctuality measure the authored series could come from, or late counts; one persistence definition (consecutive weeks with S ≥ h); publish `calibrate_tiers.py`; define "new items"; state the floor; regenerate §3.6, §7.3, §11.1 and the appendix from the engine's own level function.
- **F07.** §8.1 to §8.4: the engine may raise and never lower or auto-close a case with an unreleased escalation (pass 1's `signal.case_escalation_pin`); after the outcome a person sets the tier; add scenarios S24 (escalated case, quiet data, 60 days) and S25 (second concern on an escalated case).
- **F08.** The rate-limit hold applies to lowerings and repeated reversals only; a raise into `checkin` or `urgent` is never held; add the case to S19.
- **F10.** §4.5 and §7.2 rows 2, 7, 8, 12: a flag of kind `safeguarding` is a referral that goes to the route, not a row-12 engine input (pass 1 C23).
- **F23.** §15.2: the backtest runs as a job in UAE North, only aggregates leave, and the pseudonymisation key's holder is named.
- **F24, C9.** Shadow keeps its own case state as `signal.case` rows with `shadow = true` (pass 1 §2.9) and stores evidence against the evaluation; include backfill and event runs; import at least twenty weeks of history before shadow; replace point thresholds with a pre-registered interval pooled across counselors and a minimum of about 40 cases; blind the judgement with matched unflagged students; fix F05 first; rewrite D25's `v_shadow_queue` to read shadow cases and all run triggers (§14.1, §14.3, §14.5, 03:100 and 03:936).
- **F25.** Carry academic baselines across the year within a subject for two-year courses; count history in assessments; use the self-starting band instead of the cap; a termly per-assignment file runs the weekly engine as a backfill capped at `review`; working grades need a two-step drop or a drop held across two windows; non-overlapping windows for counts; the screen says which domains are still building a baseline.
- **F26.** Drop the common-cause automatic cap; keep the ops note and the prompt to declare a `calendar_period`; keep the property test strict (§7.6, C5, `sweep.finalize`, O40).
- **F31.** A Wellesmere expected-result list; resolve the precedence of termly delivery against relapse; the mock dip feeds a level; ordinal scenarios not IB-only; §7.2 rows 1 and 14 and §15.1 regulator-neutral.
- **F36.** §13.2 `sweep.schedule` and the sweep-not-completed alert key on schools holding data (`status IN ('shadow','live')`) through `core.schools_due_for_sweep()`, not "active".
- **F40.** The engine writes `outside` on every point of `feature_snapshot.series` (pass 1's `week_run()` now reads it); resolve backfill writing several evaluations per run against `UNIQUE (school_id, sweep_run_id, student_id)`.
- **F48.** Snapshot the vocabulary attribute values used into `rule_hits` and the evidence snapshot, with a test (pass 1 adds `config.vocabulary_history`).
- **F50.** §11.2 orders a tier by time raised; add the test that changing other students' data never moves a row within its tier (with pass 6).
- **F52.** Remove the headline rephrase wording (03:1082); the rule headline stands alone.
- **F64.** An `offer_condition_check` rule on the import of final results; calendar-day SLAs for university rules, or a results-period calendar kind (if chosen, pass 1's `sis.calendar_kind` needs the value).
- **F68, C11.** One-step ordinal moves stay inside the band unless held across two assessments; row 8 needs the other domain at moderate or a weak held two weeks; register, unit and window per measure in the thresholds schema; for fairness, pre-registered comparisons pooled across quarters with intervals and a multiple-comparisons rule, and no labels collected during the pilot (§12.4, D26 unused in the pilot).
- **F69.** AEI: replace the 1.6% to 4.1% figure with the report's statistic (unexcused share of absences, 35% to 55%); Faria et al. 2017: chronic absence −0.26 (primary model), course failure −0.17, no 0.23; Balfanz, Herzog and Mac Iver 2007: the 60% is for four flags (attendance, behaviour, mathematics, English); re-check every quoted sentence and number in pass 3 and mark any claim that cannot be re-found as an assumption.
- **F75.** D25's view is `security_invoker`.
- **F78.** Hana's attendance consistent between §4.7 and §7.2; Ahmed's floor 3.0; the impossible "14 weeks of history"; pilot scale about 350; example dates on the week start; S2 against §3.2 exclusion; rows 9 and 11 define "L = 1"; §2.3's "about 4%" is 6.2%.
- **§12.16.** Drop `sweep.completed` from D28 (pass 1 §2.20 seeds it).
- **§12.17.** Count reveal weeks from shadow's first sweep; the pilot agreement says so.
- **D30.** Use pass 4's keys `signal_shadow`, `counselor_log`, `fairness_label`.

### `05-ai-design.md`

- **F03, C1.** Remove the model layer and `cleared_by_model`; the lexicon is the only screen and every hit reaches a person; drop `fiction_or_quote` and `means_or_plan_mentioned`; rewrite §6.1 to §6.3, the pass bar (05:885), C22, and D68's `layers`; remove the `safety_screen` model feature from D74; revisit an add-only layer after one term.
- **F04.** The AI rules and §8 rest on ADEK consent under Digital Policy 7.1.3.a, a gate before G-AI.
- **F09.** Alert routing by category is school configuration confirmed with the CPO (pass 4 §5.2, §5.7).
- **F10.** The screen reads teacher flag text (§6.2, 05:521).
- **F11.** §6.4's message split into "someone to talk to now" (24/7 lines only: 800-SAKINA; DFWAC for Dubai) and "to report that a child is being harmed" (116111, 800444, 800988 for Dubai), each with hours; no "any time" unless every line is 24/7; Estijaba removed; the CPO confirms the list before any student sees it and each number stores its last-verified date (question 129, D68's `safety_response`).
- **F12.** Option (b): the CPO receives a reference-only "alert unopened" notice, never an automatic referral; §6.5 and D68 rewritten; `safety_alert_notice` and `alert_unopened_notice` join the content test; reconcile D71's `AI_SAFETY_ROUTED` with pass 4's `SAFETY_ALERT_ROUTED`.
- **F13.** D68's alert is class `safety_alert` (staff-only), not `student_voice`; the student and mentor tiers cannot read `safety_flag` or extraction columns; a per-role flagged fixture.
- **F14, C4.** §8.5: AI generations are excluded from the default subject-access pack.
- **F20.** §8.3, the leak scanner and the family notice: exclusions hold for columns, free text can carry any class; the name rule tested on Arabic names, Arabic script and nicknames; recall measured on a corpus written by people who did not build the pseudonymiser; the school fingerprint stripped from the envelope; personal statements treated as not pseudonymisable. The in-country safety-screen item is moot after C1.
- **F21.** The reader and the screen have their own policy rows allowlisted per record kind; extract lazily, only for kinds an enabled writer reads; drop `mentor.message` from D69; never extract urgent requests; a test fails when an extraction column fills with no consuming feature enabled; §7.2 and D69 agree.
- **F23.** Question 132: counselors' questions collected in the tenant and rewritten onto synthetic personas in-country by a named person; §10.2 eval cases; the no-real-data test covers student names.
- **F37.** C22's impact-assessment question is answered: a DPIA is required (pass 4 §1.1).
- **F44.** §3.0 and §8.4: the AI tier's grants generated from `ai.feature_policy.allowed_fields`; nightly brief pre-warming runs as the case owner under `caros_t_ai`; re-identification through `ai.reidentify()`.
- **F48.** `signal.safety_alert` keeps its lexicon version and evidence span, retained with the alert (the model and prompt version no longer apply under C1).
- **F51.** Rename the "Strongest match" stamp and the `discovery.strongest_match_margin` key ("closest fit"); lint UI copy for "match" (§3.5, §5, §9, D74).
- **F52.** Drop the headline rephrase from v1 (05:11, 05:246, 05:355, 05:828); remove its D74 row and the `headline_rephrase_requires_review` key.
- **F53.** Keyword tags as a floor the model may add to with quoted spans, never remove; the student sees and corrects the tags and may submit any archetype; `answer_kind` never ends a session; the compiled co-pilot filter shown above every answer, with raw text searched too; `too_broad` and `doubtful` kept off the supervisor's decision screen.
- **F62.** Default ACS's rounds to the 2027 guide, `ee_2018` for resits; re-ask question 133 about the May 2027 and May 2028 cohorts (§0.2, Challenge 9, D70).
- **F63.** The notice and C18 state both periods (flagged content up to 2 years, classification scores up to 7) and what "flagged" means; drop "pseudonymised fragment" as an overstatement.
- **F69.** Correct the Naviance quotation and its attribution (05:84); re-check every quoted sentence and number in pass 5.
- **F70.** A thinking-token allowance per feature in the cost script, measured in B7.5's smoke test; relabel the §11.2 price table.
- **F76.** No user id, or a random one per generation, in request metadata; the notice says "inference in the United States"; mentors abroad in the consent text (§8).
- **F77.** Drop per-target institution-wide admit rates from student and parent screens, or label them; fix `mentions_others` putting a second student into a single-student envelope; the coordinator confirms Extended Essay word limits and marks.
- **§12.8.** D74's feature list without `headline_rephrase` and `safety_screen`; pass 1's CHECK now matches.

### `06-build-sequence.md`

- **F01, C7.** B0.5 to B0.8: the per-deployable login roles, `NOINHERIT`, the tier in the policy expression, `caros_migrator`; B0.8 tests that the web identity cannot `SET ROLE` to system, support or owner; the B0 bake-off runs on this rewrite (Opus 5.5 and Fable 5.1 on the same brief, judged by acceptance tests and cross-review).
- **F02.** B0.7 seeds the matrix through pass 1 §2.4a from `matrix.json`; §5.4 adds positive end-to-end tests for every verb through RLS.
- **F04, F39.** ADEK consent as a named gate before G-AI and before any EU cold copy (G5, G7, G21, G22); ask ACS about 7.1.3.a with its other vendors first (question 149), then the request and evidence pack (question 150), raised this term.
- **F05, F06.** B2.9, B2.16 and §5.2 acceptance on the corrected fixture and published script.
- **F07.** B3.4's brief and the backend `CLAUDE.md` (06:606): the pin, one open escalation per case, updates, linked escalations; scenarios S24 and S25.
- **F09, F55.** B3.5 and §9.2 (06:1031, 06:1032): the reporter's countdown from the moment of escalation, category routing configuration, 999 and the Principal on `immediate_risk`, no clause numbers in UI text, 80085 labelled as the Ministry of Education's line.
- **F10.** B3.14: the flag modal's disclosure rule, the safeguarding flag kind as a referral, the lexicon on teacher text, flags for subject and supervision relationships.
- **F11, F12.** B5.12 and B3.8: the helpline split confirmed by the CPO; templates `safety_alert_notice` and `alert_unopened_notice` with the content test.
- **F13.** A per-role flagged fixture test.
- **F14, C4.** B4.3 rewritten with an escalated-student fixture and the default exclusions; §9.3.
- **F15, F16.** B3.3 and B3.6: break-glass for practising counselors with the lead's same-day confirmation, capability four eyes, the `school_admin` role, `notify.enqueue()`.
- **F17.** B6.3 tests the approval trigger (student, kind, held_at window, notes, version); the backend `CLAUDE.md` line (06:608) names the trigger.
- **F18.** Remove RISC from B1's scope (06:43, 06:107), B1.15, §1.13's thin slice, the §9.1 G-REAL checklist and O23; the Directory read is mandatory, hourly for staff; the leaver runbook step.
- **F19.** A B1 spike before B1.14: `auth_time` through `claims`, the ten-minute rule, a live-session test; the staff passkey fallback.
- **F20, F21, F44, F53.** The B7 tasks follow pass 5's revision.
- **F22.** G22 and R6: the cold copy's real choice, with key material abroad and an EU restore drill on synthetic data.
- **F23.** C3 (06:1095), §2.4 and the hooks (06:679, 06:680): Read and Bash hooks refusing paths outside the repository and `az` or `psql` against production; no production credential on agent machines; §5.8's canary off GitHub-hosted runners; the backtest, canary and restore checks as jobs in UAE North.
- **F24, C9.** §1.11 shadow on the live engine; at least twenty weeks of history before shadow; G-LIVE bars as pooled pre-registered intervals.
- **F25, F26.** B2.4 and O40 follow pass 3's revision.
- **F27, C10.** B9.3, R12, O27: the ManageBac CAS mirror moves earlier than B9.
- **F28, C2, C3.** B3.8, B5.4, B6.14 and §7.4 (06:949) build exactly pass 4 §5.8's templates; everything else in-app.
- **F29.** B0.11 seeds the fictional coordinator; the blocklist covers every real person in PRODUCT.md and the prototype; G2's consent letter names third-party sales demos.
- **F30.** B5.2: `seed://` rows in staging only, a production check, "not on file".
- **F31.** B2.16, B3.4's brief, B8 (06:328, 06:345), §9.2: the regulator profile; Wellesmere's expected results; the no-ADEK test; the CI-only shifted tenant; remove "UCAS-only" from the Wellesmere assertion.
- **F32.** B5.6 and B5.7: sectioned statements, reference formats, the centre statement, the predicted-grade snapshot, internal deadlines.
- **F33.** Place pastoral assignments and tutor groups.
- **F34.** B8.12 and §1.12 (06:405): per-tenant aggregate tables under RLS.
- **F35.** B1.13 (staging maps only CAROS domains), B4.12, §1.11 (06:384): the bootstrap grant and write grants.
- **F36.** §1.11 (06:379 to 06:385): ACS moves `onboarding → shadow` at G-REAL and `shadow → live` at G-LIVE; §7.4 (06:932) alerts key on holding data; pg-boss under its own login.
- **F38, C7.** Regenerate §4.1 to §4.3 from the task tables; add a Fable review to every silent-error task F38 lists (B2.9, B2.13, B2.8, B2.15, B4.15, B4.6, B7.5, B7.16, B7.18, B8.12, B0.12, B0.13, B1.5, B1.17, B3.7, B5.11, B6.8, B6.11, B8.7, B8.11); under C7 Opus 5.5 writes every task and Fable 5.1 reviews diffs only, so F38's "make B2.9 Fable-written" becomes "Fable reviews B2.9"; a category where the bake-off shows Fable clearly better moves back to Fable.
- **F39, C8.** Replace week counts with D-session counts on the critical path; target G-REAL in the first fortnight of the spring term 2027 (April 2027), Davide building alone; map the phases onto ACS's 2026-27 and 2027-28 calendars; back-schedule every external gate (pen-test booking, DPA, DPO, insurance, ADEK consent, the ACS IT review, and now the DPIA) from April 2027; plan against subscription usage limits, not dollars; drop the ownership rebalance until a teammate exists; state plainly what must be cut or deferred for April to hold; fix C2's backfill wording.
- **F40.** Make §1.12 the single source; D61 in B0 and D75 in B7; regenerate B1.1, B2.10 and B7.1; fix the placement gaps (`core.meeting`'s FKs, `uni.destination` read by B8, `ai.generation`, `ai.model_config`, `ai.pseudonym_map`); dedupe `PREVIEW_ACCESS` and `sweep.completed`; the migrator's non-transactional step; D42, D44 and D46 land with `auth.allowed()` in B0; place pass 8's new pass 1 objects: `ref.programme_family`, `ref.destination_system`, `ref.statement_format`, `ref.reference_format`, `ref.regulator_profile`, `sis.enrolment_programme`, `sis.tutor_group`, `sis.tutor_group_member`, `auth.capability_grant`, `auth.pastoral_assignment`, `config.vocabulary_history`, `signal.case_link`, `signal.escalation_update`, `uni.centre_statement`, `uni.school_deadline`, `privacy.retention_override`, `privacy.non_tenant_store`, the `reporting` and `jobs` schemas, and the projection views of pass 1 §2.4a.
- **F41, F61.** B4 and B4.14 follow pass 6 decision C5; application-layer retests on staging, production-layer retests on production while it holds only canaries; yearly tests' rules of engagement; G12.
- **F42.** B4's acceptance (06:230), §5.4, §5.8, §7.2 and O34: the canary pair unbranded with `purpose = 'canary'`, a Container Apps job in UAE North; a test that every report keys on `purpose`; close O34 as "train on staging".
- **F43.** §7.1, §7.2, B4.7, B4.10, B4.11, §9.3, G2: the pinned demo revision and deploy freeze; drills in their own subscription; staging maps only CAROS test domains.
- **F45.** §7.5: a job that pages the second person if an alert is still firing after 15 minutes.
- **F46, C8.** §2.4 and §2.5: solo mode, review service level, CODEOWNERS when a second builder joins.
- **F47.** §12 item 6, B0.7, O54 and §5.4: narrow-only by default, the `allow_counselor_widening` option, tests on pass 4 §3.1's rule.
- **F49.** The backend `CLAUDE.md` quotes CONTEXT §4 verbatim, with the backend's mechanisms beneath each invariant.
- **F50.** Add the prototype's sorts (the sheet's "loudest run", the CAS cohort by gap) to §6.3; bind B3.9 to tier then time; replace the DOM grep with the ordering test, on B3.9.
- **F51.** Add "Strongest match" and "asked to be matched" to §6.3; O72.
- **F52.** Remove the headline rephrase from B7.11.
- **F54.** B4.9 and B9.2 follow pass 2's revision.
- **F56.** B5.13: the under-13 gate reaches the record, with consent checked at import.
- **F57, F58, F59.** The parent import rules; §6.2 (06:853) the teacher sign-off view without a band; the mentor tasks.
- **F60.** §7.4 (06:928): the ops channel receives counts, not ids; email status polled.
- **F62.** B6 (06:262), G19, R13: the 2027 guide by default.
- **F65.** B5 (06:237), B6.6 (06:276), §6.2 (06:856, 06:861): per-school portal rules, the catalogue per school, archetype steps by programme, the IB-only limitation documented.
- **F66.** §6.2's `psreviews` row (06:846) and §6.3: the "AI read" score is not ported.
- **F70.** B7.17: the thinking allowance.
- **F72.** Move O11, O33 and O35 to the closed list; the audit key count is 37 with computed actors; map `CONCERN_SUBMIT` and drop the `AI_DRAFT` letter entry (pass 1 DR-8 now does); place the CAS "Ask to join" action (`index.html:9311`) in B6 or record that it is not ported.
- **F75, F76.** No framework caching on authenticated routes; the IT checklist's Chrome policy line; self-hosted fonts (§9.1).
- **F77.** B8.12 defines ADEK's four indicators over one population.
- **F78.** §4.4 (06:743) and §14: tag each consolidated ACS question with the gate it blocks.
- **§12.1 to §12.18.** Mark §12 items 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14 and 16 as resolved by pass 8 in passes 1 and 4; items 4, 5 and 15 go with pass 2's revision; item 17 goes to the pilot agreement; item 18 is F40.
- **C5, C6, C11.** Add question 148 to §14; mentor sessions in person only in v1; the pilot documents state that no fairness audit runs.
- **New ACS questions and counsel questions.** Add pass 4's questions 148 to 155 and counsel questions C24 to C32 to §14's consolidated lists; record question 126 as withdrawn.

### `CONTEXT.md` (in `backend-plan/`, outside session 1's scope)

- **F28, C2, C3.** Section 3's "Outbound notifications" row: content-free transactional email to parents (magic links and role-only notices); declared reference-only safety emails to staff (the counselor's safety alert, escalation reminders and deputy routing to the CPO's route, the CPO's "alert unopened" notice, grooming alerts to the mentor coordinator); everything else in-app.
- **F16, F10.** Section 3's "Roles" row: `school_admin` as a role and a `staff` role carrying capabilities, beside the five.
- **C1, F52.** Section 3's "AI features in v1": the safety screen is a lexicon with no model; no headline rephrase.
- **C6.** Invariant 11's note: v1 mentor contact is CAROS messaging and in-person sessions on school premises.

### `ACS-IT-QUESTIONS.md` (in `backend-plan/`, outside session 1's scope)

- It carries the numbering the passes continue. Pass 6 §14 consolidates the questions, so adding 148 to 155, and marking 126 withdrawn, there is optional; whoever does it keeps pass 4's wording.

### Outside `backend-plan/` (Davide's decision; no session edits these)

- **F29.** `index.html` still names the prototype's coordinator "Mr. A. Diaz", the surname of the real ACS staff member PRODUCT.md names; the decision asks for a fictional name in the prototype too. The file is frozen as the sales demo, so this needs Davide's explicit go-ahead.
- **F62.** PRODUCT.md describes "the three mandatory reflection sessions" of the Extended Essay; both current ACS cohorts follow the 2027 guide's single reflective statement.

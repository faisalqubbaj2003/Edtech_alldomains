# CAROS backend · Pass 2 · Ingest and integrations

Written 2026-09-23 against `index.html` at commit `fb28217` (10,048 lines), `backend-plan/CONTEXT.md`, `PRODUCT.md`, `backend-plan/out/01-architecture-and-data-model.md` (pass 1) and the prototype's own code wherever the documents disagreed. Every vendor claim below was checked against a vendor page on 2026-09-23 and is cited where it is made and again under Sources. Where a vendor page could not be read (several are rendered only by JavaScript or sit behind a partner login), the fact is taken from a named secondary source and labelled as such, or is labelled an assumption. Nothing here is a fabricated citation.

## 0. Read this first

### 0.1 Departures from section 3 of CONTEXT.md

**None.** Every decision in section 3 is planned on: termly CSV first, the per-school column mapping as data, a connector interface with live adapters later, reading from the incumbent systems so nobody maintains anything twice, Google Workspace identity, UAE residency, the overnight batch. Three of those decisions are challenged in §11 (Challenges), and one of them, "termly CSV first", carries a consequence that the decision did not price in: a termly *cadence* cannot power the morning ritual for the academic and attendance domains, whatever the file format. §6 sets out what a termly file supports and what the pilot must ask ACS for instead. That is a request to the school, not a departure from the decision.

### 0.2 Where the code and the documents disagree

The code wins in each case; the pipeline follows it.

| Topic | Document says | `index.html` does | Consequence for ingest |
|---|---|---|---|
| Data arrival (`arch` page, `index.html:2966`) | CONTEXT.md §3: termly CSV export; §11.1: the "immediate evaluation" copy is wrong | The worked example says "`${SIS}` gradebook webhook fired. Raw payload: student s1, subject MATH, assessment ASM-4471, score 41, recorded 12 Nov 09:14" | There is no webhook. No Veracross, ManageBac or iSAMS document retrieved describes push notifications to a vendor, and Veracross's own event endpoint is a pull with an `on_or_after_update_date` filter (§7.3). The pipeline is pull-only and file-first; the demo copy is a second thing the frozen `arch` page gets wrong, alongside "never in a nightly batch" |
| Evidence provenance (`evidence[].src`) | CONTEXT.md §7 lists `src` as free text | Values are `Gradebook · ${SIS}`, `Attendance · ${SIS}`, `CAROS platform`, `University Journey OS`, `Teacher concern · <name>`, `Mentor system`, `Deadline radar`, `Essay workspace`, `Documents & references` (26 distinct strings, 9 of them `CAROS platform`) | Every imported fact carries `import_id` and every import carries `source_system_id`, so the evidence chain prints the *system* and the *import date* the fact came from, not a string. The `SIS` constant (`index.html:1271`, `SIS=SCHOOL.sis`) becomes `core.school.sis_name`, already in pass 1 |
| Roster shape (`TEACHER.classes`, `index.html:3549`) | CONTEXT.md §7 notes rosters are "internally incoherent" | `12A/Ma1` "Grade 12 Mathematics: Analysis & Approaches HL" holds `s1..s6`, of whom `s3` is the only student with a Grade 12 IB timetable; `10C/Ma3` holds one student | Confirms pass 1's rule: rosters are imported and never typed. §5.4 adds the validation that makes a roster import a security review, not a data load |
| Per-student timetable (`getStudentClasses`, `index.html:4150`) | CONTEXT.md §7: "timetables" | Grade 12 IB reads a per-student table (`G12_IB_TIMETABLE`); Grade 11+ AP returns one hard-coded list for *any* AP student | The backend derives a student's classes from `sis.section_membership` only; there is no per-track fallback list. A student with no memberships gets the honest empty state the code's own comment asks for |
| Grade scales (`STUDENTS[].pred`, `index.html:1316`) | CONTEXT.md §7: "in the scale of the student's track" | `s1` (Grade 12, `pred:"AAB"`, A-level letters), `s3` (IB, `pred:"39/45"`), `s17` (`pred:"—"`), `gpa:"3.7"` strings; `G12_IB_TIMETABLE` rows carry `scale:"ib"` and AP rows `scale:"pct"` | Predicted grades are typed rows (`sis.grade.kind='predicted'`, `scale_key`), one per subject, never a string; a summary like "39/45" is derived. §5.1 |
| Punctuality (`baselines.attendance`, `s14`) | CONTEXT.md §7: attendance "codes including lateness" | `s14`'s series is "First-period punctuality (on-time %)"; `s1`'s is "Punctuality (on-time %)"; `dimPunctuality` (`index.html:3135`) is hard-wired per student id | First-period punctuality needs **per-session** attendance with a period reference. A daily register cannot produce it; §6 says so and §5.2 carries `timetable_period_id` and `session_key` on every attendance row |
| Coursework submission (`s15`) | not mentioned | "Coursework submitted (rolling %)" series with "Two Mathematics deadlines missed" | Needs per-assignment due dates and submission states. A termly grade file has neither; Google Classroom and ManageBac coursework do (§7.4, §7.6) |
| Parent record (`PARENTS`, `index.html:3695`) | CONTEXT.md §11.12: linkage must come from SIS contacts | One guardian per student, `consent:true` on every row, `parentOf()` fabricates a default guardian for anyone missing | Guardian links come only from the contacts import (`verified_source='sis_import'`); `consent_status` stays `unknown` unless a consent column is mapped. No default guardian is ever synthesised |
| Transcript summary (`TRANSCRIPTS`, `index.html:3784`) | CONTEXT.md §7 | `ib:"39 predicted"`, `gpa:"3.9 / 4.0"`, `issued:"Expected 26 Jun 2026"` strings | `sis.transcript.summary` (pass 1) holds the school's own issued figures as issued, because a transcript is a document the school produced, not a computation; the engine never reads it |
| CAS history (`CASREC`, `index.html:4639`) | CONTEXT.md §7 warns `hrs` ≠ `entries` | confirmed | Imported history from ManageBac is one `imported_balance` row per strand (pass 1); §7.4 says what ManageBac can and cannot give |

### 0.3 What pass 1 handed to this pass

Pass 1 §7 asked this pass for: the `ingest.*` tables and every `import_id` column; the fixture source kind and the classification trigger; the two seed exports (Veracross-shaped, iSAMS-shaped) as first fixtures; `sis.external_identity` for identity resolution; `sis.section.feeder_set_key` and `sis.calendar_period.affects_domains` as normalisation targets; `ref.grade_scale`; the rule that rosters are imported and never typed; and whether termly exports can populate `sis.grade` per assessment and `sis.attendance_event` per session, and what the weekly run looks like if they cannot. Each is answered below; §10 lists every schema delta this pass needs from pass 1, so pass 6 can sequence the migrations.

---

## 1. Decision records

### DR-10 · The ingest pipeline is pull-only, file-shaped, and one path for every source

**Context.** Section 3 wants CSV first and live connectors later "as adapters, not rewrites". The prototype's `arch` page imagines a webhook. No vendor in scope documents one to third parties (§7). Every source that matters at ACS is *pulled*: a file someone exports, or an API someone polls.

**Options.** (1) Two pipelines: a CSV importer now, a streaming connector framework later. Rejected: the second pipeline would re-implement identity resolution, validation, diffing and rollback, and the two would drift. (2) A record-stream pipeline where a CSV is one adapter that yields records, and a live connector is another adapter that yields the same records, after which everything is shared. Chosen.

**Decision.** Every source produces a stream of **canonical envelopes** (`{kind, record, sourceRef, observedAt}`; §7.1). The CSV adapter produces them by parsing a file and applying a mapping profile. A live adapter produces them by calling an API and applying its own per-school configuration. From the envelope onward there is one pipeline: stage, resolve identities, validate, diff against the current state, preview, commit under an `ingest.import` row, and roll back by that row. A live connector run is therefore an import with `import_kind` set and a `connector_run_id`, and it is rolled back the same way a bad file is. The interface has **no write method**: nothing in CAROS can ever write to a school's SIS, LMS or application system.

**Consequences.** A second school with a different SIS costs a mapping profile (data) or an adapter (code shared by every school on that system), never a school-specific branch. The dry-run diff, the rejection report and rollback exist once. The fixture source (`ingest.source_system.kind='fixture'`, pass 1) is simply the CSV adapter fed from the repository, which is why the seed exercises the real pipeline.

### DR-11 · Per-school differences are a mapping profile, validated by a published schema, authored in a Mapping Studio

**Context.** "Each school's differences are data, never code" is the decisive requirement. Pass 1 created `ingest.mapping_profile` with `mapping jsonb` and `schema_version`, and left the shape to this pass.

**Decision.** A mapping profile is a JSON document (§3) that binds a file layout to canonical fields using a **closed set of pure transforms** (`trim`, `date`, `lookup`, `split`, `regex`, `coalesce`, `const`, `scale`, and a dozen others; §3.3). There is no expression language, no scripting hook, no per-school code path. The transform set is implemented once in `packages/ingest/src/transform/` with property tests; a school that needs a transform the set lacks gets the transform added to the set for everyone, behind a schema version bump. Profiles are versioned rows; an import records the exact profile version it ran under, so a re-import of the same file under a new profile is a new import that supersedes the old one, and a signal produced from an imported fact can name the profile version that produced the fact (invariant 4, provenance).

**Who authors it, through what.** Version 1 of a school's profiles is authored by a **CAROS onboarding engineer** during onboarding (§9), in the **Mapping Studio**: an admin screen in `apps/web` under the `school_admin` capability that loads a sample file, detects headers and encodings, lets the author bind columns, runs the transforms on the sample, shows rejections and warnings live, and saves a draft version. The school's `school_admin` can clone and edit a profile later (a new column in an export, a renamed attendance code). A profile becomes `active` only after a dry run on a real file passes its expectations (§3.5). The CAROS engineer reaches a real school's Studio through a support grant (pass 1 §2.4), which is time-boxed and audited, and works first on a **pseudonymised sample** the school produces (§9, step 7) so that the first contact with real welfare data is the school's own dry run, not our engineer's screen.

**Consequences.** Profiles for the two synthetic tenants live in the repository (`packages/seed/profiles/`), because they are test fixtures. Real schools' profiles live only in the database, in the tenant, under the `config` data class. The Studio is the first admin surface the Next.js app needs and pass 6 should place it in the thin slice, because the seed cannot run without a profile.

### DR-12 · Identity resolution keys on the source system's identifier, never on a name

**Decision.** `sis.external_identity (system, external_id) → person` is the only automatic path to an existing person. A student number and a school Google address are second and third rungs that resolve only with corroboration (§4.2). Names, however normalised, only ever propose a candidate for a human to accept in the Studio. Two source identifiers may point at one person (a re-enrolled student who was given a new SIS id; two guardians sharing one address); one source identifier never points at two. Merges are recorded, audited and reversible for 30 days (§4.6).

### DR-13 · Facts are superseded, never edited; idempotency is by content and by natural key

**Decision.** Two layers, both from pass 1's schema. (1) **File level:** `ingest.import.idempotency_key = sha256(file bytes) ‖ profile_version_id`. Uploading the same file twice under the same profile returns the existing import and does nothing. (2) **Row level:** every canonical record has a **natural key** (§3.4; for a grade it is student, assessment and grade kind; for an attendance event it is student, day and session or period). A commit compares each staged row to the current row with that key: identical rows are `unchanged`, differing rows insert a new fact and set `superseded_by_import_id` on the old one, new keys insert. A corrected file therefore re-imports cleanly: only the corrected rows produce new facts, and the old ones remain readable under their import for explainability. Rollback of import N reverses exactly the rows in `ingest.import_change` for N, restoring the superseded rows, and refuses if a later import N+1 has since superseded any of N's rows (roll back N+1 first).

### DR-14 · Cadence, not format, is the pilot's binding constraint

**Decision.** The pipeline accepts termly files. The product needs **weekly** academic, attendance and behaviour deliveries, or a live connector, for the domains that drive the morning ritual. The onboarding agreement asks ACS for the weekly export pack in §6.4, and the tenant carries `ingest.expected_cadence` per import kind so the sweep can print "attendance as of 14 November" on every screen instead of implying currency it does not have. If ACS can only deliver termly, the engine runs the academic and attendance domains in retrospective mode (§6.3) and the pilot's success criteria are written for that.

### DR-15 · Source-of-truth precedence is a table, and a disagreement is a stored fact

**Decision.** `ingest.precedence` (§7.8) lists, per canonical field, the systems that may supply it in order. Every imported fact keeps its source. Reads pick by precedence at read time; when two active sources disagree on one natural key inside a window, the pipeline writes an `ingest.conflict` row and shows it in the import report rather than silently choosing. Nothing that the school maintains in Maia or ManageBac is re-keyed by a student in CAROS while that source is connected (§7.9).

### DR-16 · No integration middleware in the data path

**Context.** Edlink and Wonde sell exactly the adapter layer this pass designs, and both already connect to Veracross or iSAMS. **Decision.** Not used. Edlink states that "any information collected through the Service is stored and processed in the United States" ([Edlink privacy policy](https://ed.link/docs/legal/privacy)); Wonde's storage is "based in Ireland which keeps all school data within the European Economic Area" ([Wonde UK security FAQ](https://www.wonde.com/about/security/faqs/uk/)). Either would route student data through a third country before it reaches UAE North, which section 3's residency decision rules out. The cost of building the two live adapters ourselves is in §7; it is real but bounded, and it keeps the only copies of ACS's data in the tenant.

---

## 2. The import pipeline, end to end

### 2.1 The state machine

An import is one file (or one connector run) under one profile version. Imports are grouped in a **batch** when a delivery has several files that must be checked together (students, rosters and grades from the same export run), because a grade row cannot be validated without the section and student rows it refers to.

```
received ──parse──▶ parsed ──map+resolve──▶ staged ──validate──▶ validated ──diff──▶ previewed
   │                  │                        │                     │                  │
   └──────────────────┴────────────────────────┴─────────────────────┴──▶ failed        ├──approve──▶ approved ──commit──▶ committed ──▶ superseded
                                                                                        │                                        └──▶ rolled_back
                                                                                        └──reject──▶ discarded
```

| State | Meaning | Who moves it | Writes |
|---|---|---|---|
| `received` | Bytes are in blob storage under the immutable raw-import container; `doc.file` row exists; `idempotency_key` computed; virus scan queued | upload handler (school_admin) or connector job (system) | `ingest.import`, `doc.file`, audit `IMPORT_RECEIVED` |
| `parsed` | File decoded (encoding, BOM, delimiter, header row) into `ingest.staged_row.raw`; row count and header set recorded | worker | `staged_row` |
| `staged` | Mapping profile applied; each row has `canonical` JSON or a `rejection`; identity ladder run; `resolved` ids or an `identity_candidate` | worker | `staged_row.canonical`, `identity_candidate` |
| `validated` | Cross-row and cross-file checks passed or failed with reasons; expectations evaluated | worker | `staged_row.status`, `import.summary` |
| `previewed` | Diff computed against current facts; the dry-run report is readable | worker | `staged_row.diff`, `import.summary` |
| `approved` | A person with `school_admin` (or the connector's auto-approve policy, §7.2) accepted the preview; identity candidates resolved or deferred | school_admin | audit `IMPORT_APPROVED` |
| `committed` | Facts written; `import_change` complete; downstream jobs enqueued (recompute normalised grades, refresh school days, event-triggered evaluation) | worker | facts, `import_change`, audit `IMPORT_COMMITTED`, event `import.committed` |
| `superseded` | A later import replaced every row this one inserted | worker, when the last live row is superseded | |
| `rolled_back` | Reversed; facts restored | school_admin, or CAROS support with a grant | audit `IMPORT_ROLLED_BACK` |
| `failed` | Unrecoverable at any step; the raw file stays for the retention period so it can be re-run | worker | `import.error` |
| `discarded` | Preview rejected by the approver; nothing committed | school_admin | audit `IMPORT_DISCARDED` |

Pass 1's `ingest.import.status` CHECK lists `uploaded, validating, validated, dry_run, committing, committed, failed, rolled_back`. The list above supersedes it (§10, delta D1): `received` replaces `uploaded`, `parsed`/`staged`/`previewed`/`approved`/`superseded`/`discarded` are added, and `validating`, `dry_run`, `committing` become transient job states rather than stored statuses (a job crash leaves the row in the last durable state and the retry re-runs the step, which is idempotent).

Connector runs use the same states. A scheduled ManageBac pull is `received` when its envelopes have been written to staging as a JSON Lines file in the same raw-import container (so that even an API pull has a raw artefact to replay), and proceeds identically. Auto-approval for connectors is a per-source policy (§7.2): the preview is still produced and kept, so a bad automatic commit is diagnosable and reversible.

### 2.2 Upload and retention of the raw file

- **Who may upload.** A staff member whose membership carries `school_admin` (pass 1 §2.4, `('counselor','ingest','write','school','school_admin')`). Uploads are a tRPC mutation that returns a short-lived, single-use blob SAS URL scoped to the tenant's raw-import container and to one blob name (`<school_id>/sis_export/<import_id>`), so the bytes never transit the web tier. The client then calls `ingest.finalise(import_id, sha256)`; the worker verifies the hash against the blob.
- **Accepted formats at pilot.** CSV and TSV (RFC 4180 quoting, any of UTF-8, UTF-8 with BOM, UTF-16 LE/BE with BOM, Windows-1252 declared in the profile), XLSX (first sheet or a named sheet, read as text so Excel's date and leading-zero mangling is visible rather than silent), JSON Lines (connector runs), and ZIP containing any of these plus a OneRoster `manifest.csv` (§7.7). Size limit 250 MB per file; a Grade 9 to 12 school year of assignment grades is under 20 MB.
- **Where it lives.** `doc.file.kind='sis_export'`, data class `ingest`, retention class `raw_import` (pass 1 proposes 90 days, `after_expiry='delete'`), in the immutable container with a time-based retention policy equal to that class (pass 1 DR-9). Immutability is what makes "re-run the exact bytes we validated" a fact and not a hope, and what makes a disputed import reconstructable.
- **Scanning.** `scan_status` must be `clean` before parsing. A file is text or a zip of text; anything else is `failed` with `reason_code='unsupported_type'`.
- **Personal data in staging.** `ingest.staged_row.raw` and `.canonical` hold personal data (names, grades) and are in the `raw_import` retention class: purged 90 days after commit, or 14 days after `failed`/`discarded`, whichever is sooner. After purge the import row, its counts and its `import_change` (identifiers only) remain, so provenance survives the raw data.

### 2.3 Tables this pass adds or changes

Pass 1's `ingest.source_system`, `mapping_profile`, `import`, `import_rejection`, `import_change` stand. The following are added; every one follows pass 1's conventions (tenant column first, composite foreign keys, registry entry, RLS via `auth.protect()`, data class `ingest`).

```sql
-- A delivery of one or more files that must be validated together.
CREATE TABLE ingest.import_batch (
  school_id        uuid NOT NULL REFERENCES core.school (id),
  id               uuid NOT NULL DEFAULT gen_random_uuid(),
  source_system_id uuid NOT NULL,
  label            text NOT NULL,                     -- "Semester 1 2026/27 · week 12"
  as_of            date NOT NULL,                     -- the date the export represents (the registrar states it; never inferred from upload time)
  status           text NOT NULL DEFAULT 'open' CHECK (status IN ('open','previewed','approved','committed','rolled_back','discarded','failed')),
  created_by       text NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  approved_by      text, approved_at timestamptz,
  committed_at     timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, source_system_id) REFERENCES ingest.source_system (school_id, id)
);
ALTER TABLE ingest.import ADD COLUMN batch_id uuid,
  ADD COLUMN connector_run_id uuid,
  ADD COLUMN as_of date,                                -- copied from the batch, or stated for a single file
  ADD COLUMN profile_schema_version text,               -- the mapping schema version the profile was validated against
  ADD COLUMN row_count integer, ADD COLUMN header_columns text[],
  ADD COLUMN approved_by text, ADD COLUMN approved_at timestamptz,
  ADD FOREIGN KEY (school_id, batch_id) REFERENCES ingest.import_batch (school_id, id);

-- One row per parsed line. raw and canonical are personal data: retention class raw_import.
CREATE TABLE ingest.staged_row (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  import_id     uuid NOT NULL,
  row_no        integer NOT NULL,                      -- 1-based line number in the source, after the header
  entity_kind   text,                                  -- 'student','enrolment','guardian','guardian_link','staff','subject','section',
                                                       -- 'section_teacher','section_membership','assessment','grade','attendance_event',
                                                       -- 'behaviour_event','calendar_period','timetable_period','activity_event',
                                                       -- 'university_target','application','document_status','cas_balance','ee_record'
  raw           jsonb NOT NULL,                        -- {"Column Header": "cell"} exactly as parsed
  canonical     jsonb,                                 -- the CanonicalRecord after transforms, validated by its Zod schema
  natural_key   text,                                  -- computed from canonical (§3.4); NULL if the row was rejected before it could be
  resolved      jsonb,                                 -- {"student_id":..,"section_id":..} after identity resolution
  status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','ok','warning','rejected','needs_decision')),
  codes         text[] NOT NULL DEFAULT '{}',          -- reason codes (§2.6), zero or more
  diff          jsonb,                                 -- {"op":"insert"|"supersede"|"unchanged"|"end","before":{...},"after":{...}}
  target_table  text, target_row_id uuid,              -- set at commit
  PRIMARY KEY (import_id, row_no),
  FOREIGN KEY (school_id, import_id) REFERENCES ingest.import (school_id, id)
);
CREATE INDEX staged_row_status ON ingest.staged_row (import_id, status);
CREATE INDEX staged_row_key ON ingest.staged_row (school_id, entity_kind, natural_key);

-- A person match the ladder could not settle automatically (§4.2).
CREATE TABLE ingest.identity_candidate (
  school_id      uuid NOT NULL REFERENCES core.school (id),
  id             uuid NOT NULL DEFAULT gen_random_uuid(),
  import_id      uuid NOT NULL, row_no integer NOT NULL,
  person_kind    core.person_kind NOT NULL,
  incoming       jsonb NOT NULL,                        -- the identifying fields from the row (names, DOB, ids, email)
  candidates     jsonb NOT NULL,                        -- [{"person_id":..,"rung":"email","evidence":{...}}, ...]
  decision       text CHECK (decision IN ('link','create','skip')),
  decided_person_id uuid,
  decided_by     text, decided_at timestamptz, note text,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (import_id, row_no),
  FOREIGN KEY (school_id, import_id) REFERENCES ingest.import (school_id, id),
  FOREIGN KEY (school_id, decided_person_id) REFERENCES core.person (school_id, id)
);

-- A merge of two persons found to be one human (§4.6). Reversible for 30 days.
CREATE TABLE ingest.identity_merge (
  school_id          uuid NOT NULL REFERENCES core.school (id),
  id                 uuid NOT NULL DEFAULT gen_random_uuid(),
  survivor_person_id uuid NOT NULL,
  merged_person_id   uuid NOT NULL,
  reason             text NOT NULL CHECK (char_length(reason) >= 20),
  repointed          jsonb NOT NULL,                     -- [{"table":"sis.grade","rows":412}, ...] from privacy.table_registry
  merged_by          text NOT NULL, merged_at timestamptz NOT NULL DEFAULT now(),
  reversed_at        timestamptz, reversed_by text,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, survivor_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, merged_person_id) REFERENCES core.person (school_id, id)
);

-- Former names, so search, letters and a counselor's memory still work after a change (§4.3).
CREATE TABLE core.person_name_history (
  school_id    uuid NOT NULL REFERENCES core.school (id),
  id           uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id    uuid NOT NULL,
  given_name   text NOT NULL, family_name text NOT NULL, preferred_name text,
  valid_from   date NOT NULL, valid_to date,
  import_id    uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);

-- External identifiers for things that are not people: sections, subjects, assessments,
-- calendar periods, activities. sis.external_identity (pass 1) stays for people.
CREATE TABLE ingest.external_ref (
  school_id    uuid NOT NULL REFERENCES core.school (id),
  system       text NOT NULL,                           -- 'veracross','isams','managebac','maia','google_classroom','fixture'
  entity_kind  text NOT NULL,                           -- 'section','subject','assessment','term','calendar_period','activity','course'
  external_id  text NOT NULL,
  table_name   text NOT NULL, row_id uuid NOT NULL,
  first_seen_import_id uuid, last_seen_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (school_id, system, entity_kind, external_id)
);
CREATE INDEX external_ref_row ON ingest.external_ref (school_id, table_name, row_id);

-- Live connector runs (§7.2). Each run yields exactly one ingest.import per import_kind pulled.
CREATE TABLE ingest.connector_run (
  school_id        uuid NOT NULL REFERENCES core.school (id),
  id               uuid NOT NULL DEFAULT gen_random_uuid(),
  source_system_id uuid NOT NULL,
  trigger          text NOT NULL CHECK (trigger IN ('scheduled','manual','backfill')),
  started_at       timestamptz NOT NULL DEFAULT now(), finished_at timestamptz,
  status           text NOT NULL DEFAULT 'running' CHECK (status IN ('running','succeeded','partial','failed')),
  cursor_before    jsonb, cursor_after jsonb,           -- per resource: {"students":{"modified_since":"..."}, ...}
  requests_made    integer NOT NULL DEFAULT 0, rate_limited integer NOT NULL DEFAULT 0,
  error            jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, source_system_id) REFERENCES ingest.source_system (school_id, id)
);
CREATE TABLE ingest.source_cursor (
  school_id        uuid NOT NULL REFERENCES core.school (id),
  source_system_id uuid NOT NULL,
  resource         text NOT NULL,                        -- 'students','memberships','attendance:class','submissions', ...
  cursor           jsonb NOT NULL,                       -- adapter-defined: a timestamp, a page token, an etag
  updated_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (source_system_id, resource),
  FOREIGN KEY (school_id, source_system_id) REFERENCES ingest.source_system (school_id, id)
);

-- What each source may say about which field, in order (§7.8), and where two sources disagreed.
CREATE TABLE ingest.precedence (
  school_id     uuid REFERENCES core.school (id),        -- NULL = platform default
  field_key     text NOT NULL,                           -- 'student.enrolment','section.level','grade.assessment','attendance.session', 'university.target', ...
  systems       text[] NOT NULL,                         -- first wins: '{veracross,managebac,google_classroom}'
  PRIMARY KEY (school_id, field_key)
);
CREATE TABLE ingest.conflict (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  import_id     uuid NOT NULL,
  field_key     text NOT NULL, natural_key text NOT NULL,
  winning_system text NOT NULL, losing_system text NOT NULL,
  winning_value jsonb, losing_value jsonb,
  detected_at   timestamptz NOT NULL DEFAULT now(),
  resolved_at   timestamptz, resolved_by text, resolution text,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, import_id) REFERENCES ingest.import (school_id, id)
);

-- Cadence the school agreed to, so the UI can print staleness honestly (DR-14).
CREATE TABLE ingest.expected_cadence (
  school_id        uuid NOT NULL REFERENCES core.school (id),
  import_kind      text NOT NULL,
  every_days       smallint NOT NULL,                    -- 7 for the weekly pack, 1 for a nightly connector, 90 for termly
  grace_days       smallint NOT NULL DEFAULT 2,
  last_as_of       date,                                 -- maintained by commit
  PRIMARY KEY (school_id, import_kind)
);
```

`sis.attendance_event` gains `session_key text` (an AM/PM register or a named session where the school has no period grid) and `source_status_raw text` (the SIS's own status string, kept verbatim). `sis.grade` gains `missing boolean` (a gradebook "missing" or zero-for-not-submitted marker, which the engine must treat differently from a low score). `sis.section` gains `external_key` via `ingest.external_ref` rather than a column. `config.vocabulary` gains the vocabularies `subject_canonical`, `year_group_alias`, `attendance_status` and `enrolment_status`. All in §10.

### 2.4 The jobs

All in `apps/worker` on pg-boss, queue names prefixed `ingest.`; each step is idempotent on `(import_id, step)` and re-runnable.

| Job | Singleton key | Does | Fails when |
|---|---|---|---|
| `ingest.scan` | import | Waits for `doc.file.scan_status`; moves to `parsed` via `ingest.parse` | infected or scan timeout (24 h) |
| `ingest.parse` | import | Detects encoding (BOM, then declared, then heuristic), delimiter and header row per profile; streams rows into `staged_row.raw` in chunks of 5,000 inside short transactions; records `row_count`, `header_columns` | header does not match `required_columns`; ragged rows beyond `max_ragged_rows` |
| `ingest.map` | import | Applies transforms per row; validates `canonical` against the Zod schema for the entity kind; computes `natural_key`; runs the identity ladder (§4.2) with a per-import cache; writes `identity_candidate` rows | never fails the import; rejects rows |
| `ingest.validate` | batch | Cross-row and cross-file checks (§2.5); evaluates expectations; sets `validated` or `failed` | an expectation with `severity='fail'` is violated |
| `ingest.diff` | batch | For each `ok`/`warning` row, loads the current fact by natural key and computes `diff`; computes the **security section** of the preview (§5.4); sets `previewed` | none |
| `ingest.commit` | batch | In natural-key dependency order (persons → enrolments → subjects → sections → section teachers → memberships → assessments → grades → attendance → behaviour → calendar), in transactions of at most 2,000 rows with `lock_timeout = 5s` (pass 1 DR-9): insert or supersede, write `import_change`, stamp `target_row_id`; then `ingest.after_commit` | any transaction error: the batch is left partially committed *and marked so*, and `ingest.commit` resumes from the last completed chunk on retry, because each chunk is idempotent by natural key |
| `ingest.after_commit` | batch | Recompute `normalised_pct` for touched grades; refresh `sis.school_day` for touched years; close cases for students who left (pass 1 C22); enqueue `sweep.run` with trigger `event` for students whose facts changed if the school's policy allows daytime evaluation (pass 3); update `expected_cadence.last_as_of`; write `import.committed` | |
| `ingest.rollback` | batch | Reverse `import_change` rows in reverse dependency order; refuse if any row has since been superseded by a later import; re-run `after_commit` for touched students | a later import holds the rows |
| `ingest.purge` | nightly | Deletes `staged_row.raw/canonical`, `import_rejection.raw_row` and raw files past their retention | |
| `ingest.connector.tick` | 15 min | For each active live source, enqueue `ingest.connector.run` when its schedule is due in the school's timezone | |
| `ingest.connector.run` | source + local date + resource | Pull with cursor, write JSON Lines to the raw container, create the import, run the pipeline; auto-approve per policy | 401/403 (credentials or scopes), or 429 beyond the retry budget |

Progress is reported through `import.summary` (`{parsed, mapped, ok, warning, rejected, needs_decision, inserts, supersedes, unchanged, ends}`) which the Studio polls.

### 2.5 Validation

Validation never edits a row. It either accepts, warns, rejects, or asks for a decision, and it says why in a code the uploader can act on.

**Row-level (in `ingest.map`).** Schema validity of the canonical record (types, enums, ranges: a percentage in 0..100, an IB grade in 1..7, a date inside the academic year ± 1 year, a birth date that makes the student 10 to 22 years old); required fields present; unknown lookup values (an attendance code the profile does not map) → `warning` with the raw value kept, never a silent default; duplicate natural key inside the file → both rows `rejected` with `duplicate_in_file` unless byte-identical (then the second is `unchanged`).

**Cross-row and cross-file (in `ingest.validate`).**

| Check | Result |
|---|---|
| Every referenced student, section, teacher, guardian and assessment resolves within the batch or the database | reject the row (`unresolved_reference`) |
| A grade row's student is a member of the grade's section on `recorded_on` | warning (`grade_without_membership`); imported, because gradebooks outlive rosters by days |
| An attendance row's period exists in the timetable grid | warning; `timetable_period_id` left NULL, `session_key` kept |
| A roster file that is declared `snapshot: true` omits students who have an active enrolment | those enrolments are listed in the preview's **ends** section and are ended on commit only if the profile's `absence_policy='end'` (§4.4) |
| A teacher in a roster does not resolve to a staff person with an active `teacher` membership | reject the `section_teacher` row (`unknown_teacher`); the section is still imported with no teacher, so it is visible to nobody rather than to a guess (§5.4) |
| A membership's dates fall outside the section's academic year | reject |
| A student's enrolment ordinal changed by more than one year group since the last import | warning (`year_jump`), needs no decision but is highlighted |
| A guardian email already belongs to a staff or student person | reject the link (`email_collision`) and open an identity candidate |
| Expectation: `min_rows`, `max_reject_ratio`, `max_end_ratio`, `required_columns`, `as_of_within_days` | `severity='fail'` fails the batch; `severity='warn'` warns |

A failed batch commits nothing. A batch with warnings commits everything not rejected. Rejected rows never block accepted rows unless an expectation says so, because a registrar with 1,240 good rows and 3 bad ones should not have to fix the 3 before the 1,240 are useful; the 3 come back in the rejection report.

### 2.6 Reason codes

Every rejection or warning carries one of these, stored in `staged_row.codes` and `import_rejection.reason_code`, rendered in the report with the raw row (until purge) and the column that caused it.

`unsupported_type`, `encoding_undetectable`, `header_mismatch`, `ragged_row`, `required_missing:<field>`, `type_invalid:<field>`, `range_invalid:<field>`, `date_unparseable:<field>`, `enum_unknown:<field>` (warning), `lookup_unmapped:<table>:<value>` (warning), `duplicate_in_file`, `unresolved_reference:<kind>`, `identity_ambiguous`, `identity_new_unexpected` (a roster refresh found a student the school did not declare as new), `unknown_teacher`, `grade_without_membership` (warning), `period_unknown` (warning), `year_jump` (warning), `email_collision`, `stale_as_of`, `expectation_failed:<name>`, `mass_change:<kind>` (warning, security section), `conflict:<field>` (warning, §7.8).

### 2.7 The dry-run preview

The preview is the product of `ingest.diff` and is what the approver reads before anything changes. It is the same object for a file and for a connector run, and it is kept after commit so an approver can be asked later "what did you approve?".

```
Batch "Semester 1 2026/27 · week 12" · Veracross CSV · as of 14 Nov 2026 · profile grades v3, attendance v2, roster v4
─────────────────────────────────────────────────────────────────────────────────────────────
Files            rows    ok   warn  reject  decide     inserts  supersedes  unchanged  ends
grades.csv      6,412  6,401     9       2       0       1,180          14      5,207     0
attendance.csv 18,930 18,930     0       0       0       2,306           0     16,624     0
roster.csv      2,208  2,205     0       3       0          12           0      2,190     3
─────────────────────────────────────────────────────────────────────────────────────────────
People           new students 0 · name changes 2 · transfers in 1 · ends 3 (withdrawn 2, left 1) · new guardians 0 · guardian link changes 4
Security         teachers gaining students: Mr Davies +2 (12A/Ma1), Ms Fahri +1 (12B/Ec2) · teachers losing students: 1 · sections with no teacher: 1 (10C/Ma3)
Warnings         lookup_unmapped:attendance_code:"EX" ×9 (kept raw) · grade_without_membership ×0
Rejections       unknown_teacher ×3 ("J. Davies (cover)") · duplicate_in_file ×2 (grades.csv rows 4,411 and 4,412)
Conflicts        none
Cadence          grades: last as-of 7 Nov → 14 Nov (on time) · attendance: on time · roster: on time
Engine           students whose series change: 214 · earliest week touched: W10 · daytime re-evaluation: off (school policy)
```

Under the summary, every changed row is listed as before/after with its natural key, filterable by entity, code and student, and downloadable as CSV. The **security section** is not collapsible and must be scrolled past to reach Approve (§5.4). Approval records who approved and the summary hash; if the underlying facts change between preview and approve (another import committed), the preview is stale and must be re-run.

### 2.8 The rejection report

Delivered in the Studio and as a CSV the uploader can open next to their export: `row_no, entity_kind, code, column, raw_value, message, suggested_fix`. `suggested_fix` is deterministic text per code ("Add teacher 'J. Davies (cover)' to the staff export, or map cover teachers to a real staff id in profile roster v4, lookup `teacher_alias`"). The report is retained with the import (rows purged after 90 days, codes and counts forever). Rejected rows are **not** silently retried on the next import: the next file either contains a corrected row (which resolves normally) or the same bad row (which is rejected again with the same code, so the count of repeats is visible in the cadence panel).

### 2.9 Idempotent re-import of a corrected file

1. The registrar fixes the export and uploads it. Its bytes differ, so it is a new import with a new `idempotency_key`; its `as_of` is the same date.
2. `ingest.diff` finds most natural keys `unchanged`, the corrected rows `supersede`, and any rows the correction removed as candidates to `end` (only if `snapshot: true`).
3. Commit writes only the differences; the earlier import stays `committed` with its rows partly superseded, and becomes `superseded` when nothing it inserted is live.
4. Uploading the *same* bytes again returns the existing import (`409` with its id in the API, a friendly "already imported on 14 Nov, 08:12 by R. Al Ali" in the Studio).
5. Signals already produced from superseded facts are not rewritten; the next sweep evaluates on the corrected facts and pass 3's rule for "the fact behind a signal was superseded" (open item for pass 3, §13) decides whether to annotate or close.

### 2.10 Rolling back a bad import

`ingest.rollback(batch_id, reason)` requires `school_admin` (or a support grant) and a reason of at least 20 characters. It refuses with a list of blocking later imports if any of its rows has been superseded since. It reverses `import_change` in reverse dependency order: rows it inserted are deleted (they have never been visible to anything but reads, since facts are never updated in place), rows it superseded get `superseded_by_import_id = NULL`, enrolments it ended are reopened, memberships it ended are reopened, external refs it created are removed. It then re-runs `after_commit` for the touched students, writes `IMPORT_ROLLED_BACK`, and leaves the raw file and the preview intact. Case closures that `after_commit` produced (C22, student left) are reopened by the domain function `signals.reopenAfterRollback` only if the case was closed with outcome `left_school` by that import's `after_commit`; a counselor's own closures are never touched.

What rollback does not do: it does not unsend a nudge or an escalation email that a re-evaluation triggered, and it does not delete audit entries or product events. Those are the record of what happened.

### 2.11 The Mapping Studio

Screens, all under `apps/web/app/(staff)/admin/ingest/`, capability `school_admin`:

1. **Sources**: the school's `ingest.source_system` rows; add a CSV source, a fixture source (synthetic tenants only, enforced by pass 1's trigger), or a connector (credentials go to Key Vault by reference, never into `config`).
2. **Profiles**: list by import kind and version; clone, edit as draft, run against a sample, activate, retire. The editor is three panes: detected columns on the left, canonical fields in the middle with a binding per field (`from`, `const`, or a transform chain), and a live sample of ten transformed rows plus their validation codes on the right. Lookups are tables the author fills (raw value → canonical value and attributes), pre-seeded from the platform vocabularies (DfE codes, Veracross statuses, ADEK reasons; §5.2).
3. **Imports**: upload, batch assembly, progress, preview, approve, rejection report, rollback, history with who-did-what.
4. **Identity decisions**: the queue of `identity_candidate` rows, each showing the incoming fields and the candidates with the rung that proposed them; decide link, create or skip. Deciding re-queues `ingest.validate` for the batch.
5. **Cadence**: per import kind, the agreed cadence and the last `as_of`; a late delivery shows here and on the counselor's caseload header ("Attendance as of 7 Nov, expected weekly").

The Studio never shows student welfare data: it shows SIS facts (names, grades, attendance) because that is what it imports, under the `ingest` data class, and every open of a preview writes `FILE_ACCESS`-class audit entries for the students it lists (pass 4 decides the exact action key; §13).

---

## 3. The mapping profile

### 3.1 Shape

A profile is one JSON document per `(source_system, import_kind)`, versioned in `ingest.mapping_profile.mapping`, validated on save against `MappingProfileSchema` in `packages/contracts/src/ingest/mapping-profile.ts` (Zod 4; the JSON Schema is generated from it and published at `docs/schemas/mapping-profile-1.0.json`). `schema_version` is the contract's version; a profile saved under 1.0 is still readable when 1.1 adds a transform, and a profile that uses a 1.1 transform cannot be activated on a 1.0 runtime.

```jsonc
{
  "schema_version": "1.0",
  "import_kind": "grades",                    // one of the entity kinds in §2.3, or a multi-entity kind (§3.6)
  "file": {
    "format": "csv",                          // csv | tsv | xlsx | jsonl | oneroster_zip
    "encoding": "auto",                       // auto | utf-8 | utf-8-sig | utf-16 | windows-1252
    "delimiter": ",",
    "quote": "\"",
    "header_row": 1,                          // 1-based; 0 = no header, columns addressed by index
    "skip_rows_after_header": 0,
    "sheet": null,                            // xlsx only
    "null_tokens": ["", "N/A", "n/a", "-", "—", "NULL"],
    "trim_cells": true,
    "date_formats": ["M/d/yyyy", "yyyy-MM-dd", "d MMM yyyy"],   // tried in order; Unicode CLDR patterns
    "time_zone": "school"                     // dates without a zone are school-local
  },
  "row_filter": {                             // optional; rows failing the filter are skipped, not rejected
    "all": [ { "column": "Enrollment Status", "in": ["Enrolled", "Re-enrolled"] } ]
  },
  "identity": {                               // how people in this file are keyed (§4)
    "student": { "system": "veracross", "external_id": { "from": "Person ID" },
                 "student_number": { "from": "Student ID" }, "email": { "from": "Email" } },
    "teacher": { "system": "veracross", "external_id": { "from": "Teacher Person ID" } }
  },
  "fields": {                                 // canonical field -> binding
    "assessment.external_ref":   { "from": "Assignment ID" },
    "assessment.title":          { "from": "Assignment" },
    "assessment.kind":           { "from": "Category", "transform": [ { "lookup": "assessment_kind" } ], "default": "assessment" },
    "assessment.occurred_on":    { "from": "Date Assigned", "transform": [ { "date": {} } ] },
    "assessment.max_score":      { "from": "Max Points", "transform": [ { "number": {} } ] },
    "assessment.weight":         { "from": "Weight", "transform": [ { "number": {} } ], "optional": true },
    "section.external_id":       { "from": "Class ID" },
    "grade.kind":                { "const": "achieved" },
    "grade.value_raw":           { "from": "Score" },
    "grade.scale_key":           { "from": "Class ID", "transform": [ { "lookup": "section_scale" } ], "default": "pct" },
    "grade.missing":             { "from": "Missing", "transform": [ { "bool": { "true": ["Y","Yes","1"], "false": ["", "N", "No", "0"] } } ], "default": false },
    "grade.recorded_on":         { "any": [ { "from": "Date Graded" }, { "from": "Date Assigned" } ], "transform": [ { "date": {} } ] }
  },
  "lookups": {
    "assessment_kind": { "Test": "exam", "Quiz": "assessment", "Homework": "homework", "Project": "coursework", "Mock": "mock" },
    "section_scale":   { "12A/Ma1": "ib_1_7", "12B/Ec2": "ib_1_7" }   // usually derived from the section's programme instead (§5.1)
  },
  "natural_key": ["student.external_id", "assessment.external_ref", "grade.kind"],
  "snapshot": false,                          // true = the file is the complete current set; absences may end rows (§4.4)
  "absence_policy": "ignore",                 // ignore | end   (only meaningful when snapshot is true)
  "expectations": [
    { "name": "min_rows", "value": 500, "severity": "fail" },
    { "name": "max_reject_ratio", "value": 0.02, "severity": "fail" },
    { "name": "required_columns", "value": ["Person ID", "Class ID", "Assignment ID", "Score"], "severity": "fail" },
    { "name": "as_of_within_days", "value": 10, "severity": "warn" }
  ],
  "notes": "Axiom saved query 'CAROS weekly assignment grades' · owner: registrar"
}
```

### 3.2 Bindings

A binding is one of:

| Form | Meaning |
|---|---|
| `{"from": "<header>"}` | the cell under that header (or `{"index": 3}` when there is no header row) |
| `{"const": <value>}` | a literal |
| `{"any": [binding, binding]}` | the first binding that yields a non-null value |
| `{"concat": {"sep": " ", "of": [binding, binding]}}` | joined values |
| plus `"transform": [op, ...]` | applied left to right to the bound value |
| plus `"default": <value>` | used when the result is null and the field is not required |
| plus `"optional": true` | null is acceptable; otherwise a null required field is `required_missing` |

Every binding is total: it either produces a value of the field's declared type or a typed rejection code. There is no way to run code.

### 3.3 The transform set (closed)

| Op | Parameters | Behaviour |
|---|---|---|
| `trim` | | strip surrounding whitespace, collapse internal runs to one space |
| `upper`, `lower`, `titlecase` | | case folding (locale-insensitive) |
| `number` | `decimal: "." \| ","`, `thousands` | parse to a numeric; `"41%"` → 41 with `percent: true` |
| `date` | `formats` (overrides file defaults) | parse to a date; two-digit years are rejected unless `century` is set; Excel serial numbers accepted when `excel_serial: true` |
| `datetime` | `formats`, `zone` | parse to an instant |
| `bool` | `true: [...]`, `false: [...]` | tokens are case-insensitive |
| `split` | `sep`, `index` | take one part |
| `regex` | `pattern`, `group`, `flags` | a capture group; RE2 syntax only (no backtracking), so a profile cannot hang the worker |
| `replace` | `pattern`, `with` | RE2 |
| `lookup` | `table`, `else: "reject" \| "keep" \| "null" \| <value>` | map through a named lookup; unmapped values warn (`lookup_unmapped`) and behave per `else` (default `keep` keeps the raw value and marks the row `warning`) |
| `scale` | `key` | validate a raw grade against `ref.grade_scale[key]` and set `value_numeric`; does not compute `normalised_pct` (the commit does) |
| `coalesce` | | first non-null in a list-valued binding |
| `pad_start` | `length`, `char` | `"42"` → `"00042"` (student numbers exported by Excel with leading zeros lost) |
| `strip_diacritics` | | for matching only, never for storage (§4.5) |
| `map_year_group` | | resolve a label (`"Grade 12"`, `"12"`, `"Year 13"`, `"G12"`) through `config.vocabulary 'year_group_alias'` to a `sis.year_group.id` |
| `map_subject` | | resolve a subject code or name through `subject_canonical` aliases |
| `minutes` | | `"0:12"`, `"12 min"`, `"12"` → 12 |

Adding an op is a change to `packages/ingest` with tests and a `schema_version` bump. That is the whole extension mechanism. A school that seems to need something bespoke either needs a new general op, a lookup table, or a different export from their SIS; it never needs code of its own.

### 3.4 Natural keys per entity kind

The natural key is what makes re-import idempotent and what the diff is computed on. It is computed from canonical fields after identity resolution, so two files that spell a student differently but carry the same SIS id produce the same key.

| Entity kind | Natural key | Target table |
|---|---|---|
| `student` | `person` (resolved) | `core.person`, `sis.student` |
| `enrolment` | `student, academic_year` | `sis.enrolment` |
| `staff` | `person` | `core.person`, `core.staff_profile`, `auth.membership` (source `import`) |
| `guardian` | `person` | `core.person` |
| `guardian_link` | `guardian person, student` | `family.guardian_link` |
| `subject` | `code` | `sis.subject` |
| `timetable_period` | `code` | `sis.timetable_period` |
| `section` | `academic_year, external_id` | `sis.section`, `ingest.external_ref` |
| `section_teacher` | `section, teacher person, started_on` | `sis.section_teacher` |
| `section_membership` | `section, student, started_on` | `sis.section_membership` |
| `assessment` | `section, external_ref` (or `section, title, occurred_on` when the SIS gives no id) | `sis.assessment`, `ingest.external_ref` |
| `grade` | `student, assessment, kind` | `sis.grade` (supersede) |
| `attendance_event` | `student, day, coalesce(timetable_period, session_key, 'DAY')` | `sis.attendance_event` (supersede) |
| `behaviour_event` | `student, external_ref` (or `student, occurred_at, category`) | `sis.behaviour_event` (supersede) |
| `calendar_period` | `academic_year, kind, label, starts_on` | `sis.calendar_period` |
| `activity_event` | `student, source, ref` | `engagement.activity_event` (insert-only) |
| `university_target` | `student, external_ref` (Maia list item id) | `uni.student_target` |
| `application` | `target, external_ref` | `uni.application` |
| `document_status` | `student, kind, application` | `uni.document_request` |
| `cas_balance` | `student, strand, covers_to` | `ib.cas_entry` (`imported_balance`) |
| `ee_record` | `student, round` | `ib.ee_essay` (fields the source owns only; §7.9) |

### 3.5 Expectations

Named, typed checks a profile declares about the *file*, evaluated in `ingest.validate`: `min_rows`, `max_rows`, `max_reject_ratio`, `max_warning_ratio`, `max_end_ratio` (share of currently active rows a snapshot would end; default `fail` above 0.10 to catch a truncated roster), `required_columns`, `forbidden_columns` (a column the school promised to strip, such as a national ID number: its presence fails the import before the bytes leave staging), `as_of_within_days`, `students_all_known` (fail on `identity_new_unexpected`; for weekly grade files where new students should only arrive through the roster file). Each has a `severity` of `fail` or `warn`.

### 3.6 Multi-entity files

A real export often carries several entities per row (a roster row names a section, a teacher and a student; a grades row names an assessment and a grade). `import_kind` may be a composite (`roster` = section + section_teacher + section_membership; `grades` = assessment + grade; `contacts` = guardian + guardian_link; `enrolment` = student + enrolment). The profile binds fields with their entity prefix and the mapper emits one canonical envelope per entity per row, de-duplicated by natural key inside the file (a section named on 24 roster rows becomes one section envelope). Rejecting one entity of a row does not reject the others unless they depend on it (a membership needs its section).

### 3.7 Testing a profile

`packages/ingest/test/profiles/<tenant>/<kind>.spec.ts` runs each seed profile over its fixture and asserts the exact counts of `ok / warning / rejected / needs_decision` and the codes (§8). The Studio's "run against sample" is the same function. A profile cannot be activated unless its last dry run on this school's data produced zero `fail` expectations, and the activation records that dry run's import id.

---

## 4. Identity resolution

### 4.1 What is being resolved

Four kinds of person arrive from outside: students (SIS, ManageBac, Google Classroom, Maia), staff (SIS, ManageBac, Google), guardians (SIS contacts, ManageBac parents) and, later, mentors (never imported; pass 4). Sections, subjects, assessments and calendar periods are resolved by `ingest.external_ref` on their source id and need no ladder.

The stable CAROS key is `core.person.id`. Every source identifier a person is known by is a row in `sis.external_identity (system, external_id)` (pass 1), and a person may hold several: `veracross:44120`, `managebac:88213`, `google:1102484959…`, `maia:ML-5591`, and a second `veracross:` id if the SIS re-created them. The Google `sub` is the OpenID identifier, which Google documents as "unique among all Google Accounts and never reused", adding that an account "can have multiple email addresses at different points in time, but the `sub` value is never changed" ([Google OpenID Connect](https://developers.google.com/identity/openid-connect/openid-connect)). Google Classroom identifies users "by the unique ID or email address of the user, as returned by the Directory API" ([Classroom: manage users](https://developers.google.com/workspace/classroom/guides/manage-users)). Whether the Directory id and the OIDC `sub` are the same number is not stated on either page; it is treated as an assumption and verified at onboarding (§9, step 12) by signing in one test account and comparing the `sub` with the id the Classroom API returns for the same user.

### 4.2 The ladder

Run per incoming person envelope, in order; the first rung that yields exactly one person resolves; a rung that yields more than one, or a rung marked *corroborate* that yields one without corroboration, produces an `identity_candidate` and the row is `needs_decision`.

| Rung | Match on | Auto-resolve? | Notes |
|---|---|---|---|
| 1 | `sis.external_identity(system, external_id)` | yes | the normal case after the first import |
| 2 | `sis.student.student_number` = incoming student number (students only) | yes, and writes the rung-1 row for this system | the school's own human-facing number is stable across Veracross and ManageBac at a school that keys ManageBac's `student_id` field to it (question 74) |
| 3 | `core.person.email` = incoming school email, same `kind` | yes **if** DOB also matches, or if the source is the SIS itself and the person has no SIS identity yet; else candidate | school Google addresses are reissued to new people rarely but not never; DOB is the corroboration |
| 4 | `google_subject` = incoming Google id (from Classroom) | yes | only Classroom and SSO supply it |
| 5 | normalised `family_name` + normalised `given_name` + `date_of_birth`, same kind, active | candidate, auto-accept only when the source is the SIS, the match is unique and DOB is present | normalisation in §4.5 |
| 6 | normalised names only | candidate, never auto | shown with the rung so the decider knows how weak it is |
| 7 | nothing | create, unless the profile expects `students_all_known` | a new `core.person` and, for students, `sis.student` |

Guardians add a rung between 3 and 5: SIS guardian id (`external_identity`), then email, then (name + linked student). Staff use rungs 1, 3, 4, 5. The ladder never reads across tenants.

Performance: the ladder is a set of indexed lookups (`external_identity`, `student_number`, `email`, `google_subject`) plus one query on a materialised `core.person_match_key` (normalised names + DOB) that pass 1 does not have and §10 adds (D6). A 1,300-student roster resolves in under a second.

### 4.3 Name changes

The SIS is the authority on a person's name. When rung 1 resolves a person whose incoming names differ from the stored ones, the mapper emits an `update` on `core.person` (the one place the pipeline updates rather than supersedes, because a person is an entity, not a fact) and appends the outgoing names to `core.person_name_history` with `valid_to = as_of - 1 day`. The preview lists name changes under People. Nothing else changes: the person id, memberships, cases, notes and letters all stay attached. Search (`⌘K`) matches current and historical names. A `preferred_name` change is handled the same way. A name change combined with a *different* external id is not a name change; it is rung 5 or 6, and a candidate.

### 4.4 Transfers, withdrawals and the meaning of absence from a file

- **Transfer in mid-year.** The enrolment row arrives with `status = transferred_in` (or the profile derives it from a `joined_on` after the term start) and `valid_from = joined_on`. `sis.student.joined_on` is set. The engine sees a student with no history and applies its cold-start rule (pass 3); the caseload sheet shows "joined 3 Nov" instead of an empty run.
- **Transfer out and withdrawal.** Two ways to learn it. Explicitly: an enrolment status of `withdrawn` or `transferred_out` with a `left_on`, which ends the enrolment (`valid_to = left_on`) and sets `sis.student.left_on`. Implicitly: a file declared `snapshot: true` with `absence_policy: 'end'` no longer contains the student; the preview lists them under **ends** and, on commit, the enrolment is ended at `as_of - 1 day` with status `withdrawn` and a note `ended_by_snapshot`. A file with `absence_policy: 'ignore'` (the default, and the only allowed value for partial files like weekly grades) never ends anything.
- **After the enrolment ends.** `ingest.after_commit` closes open cases with outcome `left_school` (pass 1 C22), ends `section_membership` rows, ends `caseload_assignment` rows, and marks `core.person.status = 'left'` after a 14-day grace period (a job, not the commit, so a registrar's mistake corrected within two weeks leaves no trace beyond the audit). Sessions are revoked at `left` (pass 4). Data is retained per class (pass 4); nothing is erased by an import.
- **Return.** A student who left and re-enrols keeps their person id (rung 1 or 2), gets a new enrolment row, and their history resumes; the engine decides how much of it to trust after a gap (pass 3).
- **Graduation.** `status = graduated` at the academic year end from the roll-over import; the person stays for the alumni and mentor paths (pass 4 owns the retention and the mentor route).

### 4.5 Normalisation for matching (never for storage)

Applied only inside rungs 5 and 6 and the candidate display: Unicode NFKC, case fold, `strip_diacritics`, collapse whitespace and hyphens, drop honorifics and generational suffixes, and for Arabic-derived Latin names treat `Al`, `Al-`, `El`, `Bin`, `Bint`, `Abu` prefixes as detachable tokens so that `Al Mansoori` and `Almansoori` compare equal. Arabic-script names are compared after NFKC only; no transliteration is attempted, because a transliteration match is exactly the kind of guess DR-12 forbids. The stored name is always the source's spelling.

### 4.6 Duplicates and merges

- **Inside one file:** two rows with the same natural key are `duplicate_in_file` (§2.5).
- **Across systems:** by design, one person holds many external identities; that is not a duplicate.
- **Two persons, one human** (the SIS re-created a returning student under a new id; a guardian was entered twice with two spellings): a `school_admin` merges them in the Studio with a reason. The merge repoints every foreign key listed in `privacy.table_registry` for `core.person` and `sis.student` from the merged to the survivor, moves external identities, appends the merged names to the survivor's name history, marks the merged person `status = 'erased'` with `erased_at` (it is a tombstone, not an erasure request), and records the repointed tables and counts in `ingest.identity_merge`. It is reversible for 30 days by the stored counts and `import_change`-style reversal; after 30 days the tombstone is retained and reversal needs a support grant. Merging two *students* with open cases merges the cases (pass 1 C12) with the merge reason.
- **One person, two humans** (a shared SIS id, which happens when a school reuses ids): cannot be fixed by an import. The Studio's "split" is a manual, audited operation for pass 4's break-glass path; it is listed, not designed, here.

### 4.7 Siblings and guardians

Siblings are distinct students who share guardians. The contacts import produces one `guardian` envelope per SIS contact and one `guardian_link` per (contact, student) with `relationship`, `is_primary` (from the SIS's primary or custodial flag), and `contact_pref` when the SIS has it. The guardian ladder keys on the SIS contact id, then email. Consequences and rules:

- One guardian person may link to several students in different year groups; the parent portal shows each child under that child's grade-conditional navigation (`roleNav`), never a merged view (invariant 7 is about populations, but the same discipline applies).
- **Shared email between two guardians** (pass 1's Wellesmere seed includes one such pair) collides with `core.person UNIQUE (school_id, email)`. Options: (a) make the uniqueness partial to staff and students and allow two guardian persons with one email, which breaks magic-link sign-in (whose account is it?); (b) one guardian person per email, with both SIS contact ids attached as external identities and one `guardian_link` per child carrying the relationship of the *primary* contact; (c) reject the second contact and open an identity candidate. Recommendation: **(b)**, with the link's `relationship` set to "Parents (shared address)" when the two SIS relationships differ, and the preview flagging it, because a shared family inbox is one login identity in every practical sense and the alternative is a portal nobody can enter. Pass 4 must accept or reject this for consent and audit purposes (§13; open decision 4).
- A guardian email that already belongs to a staff or student person is `email_collision` and a candidate, never auto-linked: a teacher who is also a parent is two memberships on one person, and only a human should say so.
- `consent_status` is set from a consent column only if the profile maps one; otherwise `unknown`. Pass 4 decides what `unknown` permits.
- A guardian whose every link has ended (all children left) is ended with the last link and follows the guardian retention class.

### 4.8 Staff

Teachers and counselors are resolved by SIS staff id, then school Google email (which SSO also uses, so an SSO sign-in and a roster import land on the same person; a mismatch shows up on first sign-in as a person with two identities and no membership, which pass 4's admin flow resolves). A staff import creates or updates `core.person`, `core.staff_profile` and a `teacher` membership with `source = 'import'`. It never creates a `counselor` membership or grants a capability: those are administrative acts in CAROS (pass 4), because a job title in an SIS export is not an authorisation. A staff person absent from a staff snapshot is ended with the same grace as a student, and their section-teacher rows end with them.

---

## 5. Normalisation

The rule for every table in this section: the raw value is stored verbatim and the normalised value sits beside it, computed by a versioned table, so that a change in the table is a recompute and never a loss.

### 5.1 Grade scales, predicted versus achieved

**Scales.** `ref.grade_scale` (pass 1) is seeded with:

| key | kind | steps | Source |
|---|---|---|---|
| `pct` | numeric | 0 to 100 | definitional |
| `ib_1_7` | ordinal | 1..7 | IB subject grades run 1 to 7; TOK and the Extended Essay contribute up to 3 core points; the Diploma maximum is 45 and the minimum award is 24 points subject to the published passing conditions. The IB's own pages ([DP passing criteria](https://ibo.org/about-the-ib/what-it-means-to-be-an-ib-student/recognizing-student-achievement/about-assessment/dp-passing-criteria/), [Understanding DP assessment](https://ibo.org/programmes/diploma-programme/assessment-and-exams/understanding-ib-assessment/)) returned HTTP 403 on retrieval on 2026-09-23; the figures are corroborated by two secondary summaries ([Structural Learning](https://www.structural-learning.com/post/ib-scoring-and-grades-explained), [RevisionDojo](https://www.revisiondojo.com/blog/how-is-the-ib-scored)) and must be re-verified against the IB page before the reference set ships |
| `ib_points_45` | numeric | 0 to 45 | as above; a *derived* total (six subjects plus core), stored only when the school issues it as a fact (a transcript, a final result) |
| `ib_core_letter` | ordinal | E, D, C, B, A | TOK and EE letter grades; same sources |
| `ap_1_5` | ordinal | 1..5 | "AP Exams are scored on a scale of 1 to 5" ([College Board, About AP Scores](https://apstudents.collegeboard.org/about-ap-scores)); scores for the May sitting are released from early July (reported 6 July for 2026 by [secondary press](https://scholarly.so/blog/when-do-ap-scores-come-out-2026); the College Board's own release page returned 404 on retrieval) |
| `a_level` | ordinal | A*, A, B, C, D, E, U | for the second synthetic tenant; UK awarding-body scale, definitional |
| `gcse_9_1` | ordinal | 9..1, U | same |
| `gpa_4` | numeric | 0.0 to 4.0 (4.3 where weighted) | US convention; the school states which |
| `letter_us` | ordinal | A+, A, A-, B+, …, F | US letter grades; the school states its own percentage bands |
| `school:<slug>:<key>` | either | as declared | a school's own scale, declared in the profile or read from the source (ManageBac's `term-grade-scales` endpoint maps percentage thresholds to marks per programme; §7.4) |

**The normalised percentage.** `sis.grade.normalised_pct` exists so that screens can sort and colour across scales and so the university classification rule can compare a predicted grade with a requirement expressed in the same family. For numeric scales it is the value rescaled to 0..100. For ordinal scales it is the **midpoint of a band that CAROS assigns by convention**, recorded in `ref.grade_scale.steps` with `source_id` pointing at a `ref.source` row titled *CAROS convention, unsourced*, because no examination board publishes a percentage equivalence for its grades (IB grade boundaries differ by subject and session). Two consequences follow and are binding on pass 3: the engine computes deviation **within one scale per series** (Ahmed's Mathematics is a series in the unit his gradebook uses, and an IB 1 to 7 series is analysed as an ordinal series, not as percentages), and no screen ever prints the normalised value as if it were a mark. A school that supplies its own percentage-to-mark table (ManageBac's endpoint, or a registrar's table in the profile) gets a `school:` scale with a sourced conversion, and that conversion outranks the convention.

**Kinds.** `sis.grade.kind` (pass 1: `achieved | working | predicted | final`) is set by the profile, never inferred from a number:

- `achieved`: a result on an assessment that happened (`assessment.kind` in `assessment, coursework, homework, mock, exam`). Feeds the academic series.
- `working`: the teacher's current overall grade for the section at a date (`assessment.kind = 'term_grade'` or `'report'`, `occurred_on` = the reporting date). Feeds the academic series at reporting cadence and the transcript view.
- `predicted`: a forecast of a final grade, dated (`assessment.kind = 'predicted_grade'`). At an IB school the predicted grade the coordinator submits to the IB is reported by a coordinator's guide to be entered on IBIS with a deadline "around April 30" ([Faria, IB DP Coordinator's Guide, April](https://guide.fariaedu.com/monthly-ib-diploma-programme-coordinator-guide/april); the IB's Handbook of Procedures is not public); schools also issue predictions to universities earlier in the application year, and those are separate rows with their own dates. Feeds the reach/match/safety classification and the parent's transcript page; **never** the academic deviation series, because a prediction is a judgement, not an observation.
- `final`: an examination board's result (IB July results, AP July scores, A-level August). Feeds outcomes reporting and the transcript; it also closes the loop on predicted-versus-achieved for the letter engine (pass 5).

`sis.grade.missing = true` marks a gradebook cell the SIS reports as missing or not submitted. Some gradebooks export it as a zero; the profile's `bool` on a "Missing" column is what distinguishes "scored 0" from "did not submit", and pass 3 must treat the two differently (a missing assignment is a submission signal, not an attainment one; it is what makes the prototype's "coursework submitted" series computable).

### 5.2 Attendance

**Canonical record.** `sis.attendance_event` (pass 1) plus this pass's `session_key` and `source_status_raw`:

| Field | Meaning |
|---|---|
| `day` | school-local date |
| `timetable_period_id` | the period, when the register is per lesson and the profile can map the period code; NULL otherwise |
| `session_key` | `AM`/`PM` for a twice-daily register, a period code the grid does not know, or `DAY` for a whole-day record |
| `section_id` | the class, when per-lesson |
| `code` | `present, absent, late, left_early, remote, unknown` |
| `authorised` | true, false, or NULL when the source does not say |
| `reason_code`, `reason_label` | the source's own code and its label (`M`, "Medical or dental appointment") |
| `minutes_late` | when the source gives it |
| `source_status_raw` | the exact source string |

**Mapping.** Attendance statuses go through a lookup whose rows are `config.vocabulary` entries of vocabulary `attendance_status` (the *status*: present, absent, late…) and `absence_reason` (the *reason*, with attributes `{authorised, counts_as, suppresses:[domains]}`), both pre-seeded per source family and overridable per school. Three seed families:

1. **DfE register codes (England, from August 2024)**, for iSAMS-shaped and any British-curriculum school. Extracted from the statutory guidance *Working together to improve school attendance*, August 2024 ([DfE PDF](https://assets.publishing.service.gov.uk/media/66bf300da44f1c4c23e5bd1b/Working_together_to_improve_school_attendance_-_August_2024.pdf)), which classifies each code "for statistical purposes":

   | Code | Description | Statistical class | CAROS `code` / `authorised` / suppresses |
   |---|---|---|---|
   | `/` `\` | present (AM, PM) | present | `present` |
   | `L` | late arrival before the register is closed | attending | `late`, authorised NULL |
   | `K` `V` `P` `W` `B` | LA provision, educational visit, sporting activity, work experience, other approved educational activity | approved educational activity | `present` with `reason_code` kept; suppresses attendance |
   | `C` `C1` `C2` `E` `I` `J1` `M` `R` `S` `T` | leave of absence (exceptional; regulated performance; part-time timetable), suspended or excluded, illness, interview, medical or dental, religious observance, study leave, parent travelling | authorised absence | `absent`, authorised `true`; `I` and `M` suppress attendance and engagement; `S` suppresses academic and engagement; `E` suppresses nothing and is behaviour-relevant |
   | `G` `N` `O` `U` | holiday not granted, reason not yet established, other or unknown, arrived after registration closed | unauthorised absence | `absent` (`U` → `late`), authorised `false`; `N` is re-coded within 5 school days per the guidance, so a later file will supersede it |
   | `D` `Q` `X` `Y1`…`Y7` | dual registered, lack of access arrangements, not required to attend, unable to attend (transport, travel disruption, premises closed, site closed, custody, public health, other unavoidable cause) | not a possible attendance | `unknown` with `counts_as = 'excluded'`: the day is removed from the denominator, never counted as absence |
   | `Z` `#` | prospective pupil, planned whole-school closure | not collected | row skipped; `#` also feeds `sis.school_day` |

2. **Veracross statuses**, for the pilot. Veracross tracks daily ("master") attendance and class attendance separately, both from the same interface (community articles *Tracking Daily or Class Attendance* and *Attendance Overview*, JavaScript-rendered and not readable on retrieval; the four categories Absent Excused, Absent Unexcused, Tardy Excused, Tardy Unexcused, plus Early Dismissal, and a free-text note field, are taken from those articles' search snippets and from one school's published Veracross attendance guide ([Riverdale, Enter Student Attendance](https://howdoi.riverdale.edu/wiki/Enter_Student_Attendance)); **treat the exact status strings as an assumption until ACS's export is seen**). Mapping: Present → `present`; Absent E → `absent`, authorised true; Absent U → `absent`, false; Tardy E/U → `late` with authorised accordingly; Early Dismissal → `left_early`. The note field carries the reason as free text; the profile's `regex` lookups can lift common phrases ("medical", "school trip", "family") into `reason_code`, and anything else stays as `reason_label` unclassified, with `authorised` from the E/U flag. Whether Veracross's "attendance reason" is a coded field at ACS is question 71.

3. **ADEK reasons**, for an Abu Dhabi school's *authorised* set. Press reports of ADEK's updated attendance policy (September 2025) list the excused categories as illness, pre-scheduled medical appointments, death of a first- or second-degree relative, official government commitments, participation in competitions or events, official public holidays, study leave for examinations with ADEK approval, and government-mandated closures, with medical notes limited to three consecutive days and twelve days a year before a Department of Health certificate is required, and with absence to be uploaded daily to eSIS ([The National, 22 Sep 2025](https://www.thenationalnews.com/news/uae/2025/09/22/abu-dhabi-updates-rules-on-pupil-absences-for-private-schools/); [Khaleej Times](https://www.khaleejtimes.com/uae/education/school-attendance-rules-abu-dhabi)). The policy text itself was not retrieved and is question 72; the seed rows carry `source: press` until it is.

**What suppression reads.** `absence_reason.attributes.suppresses` lists the signal domains a reason suppresses for the days it covers (`{"suppresses":["attendance"]}` for an authorised medical absence; `["academic","engagement"]` for study leave). `config.rule_set_version 'engine.suppression'` (pass 1) says how far a suppression extends (the days themselves; a window after) and is pass 3's; the vocabulary only says *which* reasons are of *which* kind. A day with `counts_as = 'excluded'` is not a school day for that student.

**Lateness.** `late` with `minutes_late` where the source gives minutes; the prototype's "lates within a 10-school-day window" (`S.thresh.att`) counts rows with `code = 'late'` and, for "first-period punctuality", rows whose `timetable_period_id` is the first period of the day pattern or whose `session_key = 'AM'`. If the register is daily only, first-period punctuality cannot be computed and the dimension says so (§6).

### 5.3 Behaviour

`sis.behaviour_event.category_key` maps through vocabulary `behaviour_category` with attributes `{polarity: 'negative'|'positive'|'neutral', severity_default: 1..3, points_sign: -1|0|+1}`. Source shapes: Veracross "Behavior" records (Edlink's inventory lists Behavior among the Data API areas, §7.3); ManageBac behaviour notes with `behavior_type`, `incident_time`, `notes`, `next_step`, `reported_by` ([ManageBac v2.2 behavior notes](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/behavior-notes.md)); iSAMS Rewards & Conduct "Module Types / Fields / Records" and Discipline Manager detentions (§7.5). Positive records (merits, commendations) are imported too, with `polarity = 'positive'`, because the prototype's `positive` domain needs them. `description` is staff-only (pass 1) and is minimised on import: the profile may map it, and the school may choose not to (`forbidden_columns`).

### 5.4 Timetables and rosters, as a security property

A roster decides which teacher sees which student (`auth.perm_scope 'roster'`, pass 1). So a roster import is a permissions change, and the pipeline treats it as one:

1. **Sources only.** `sis.section`, `sis.section_teacher` and `sis.section_membership` have no create or edit mutation in the domain layer other than `ingest.commit` and pass 4's time-boxed cover assignment. The seed goes through ingest too.
2. **Teachers must resolve to staff.** A section-teacher row whose teacher does not resolve to a `core.person` with an active `teacher` membership is rejected (`unknown_teacher`). The section is still created; a section with no teacher is visible to no teacher. Guessing would grant access.
3. **Memberships must be inside the section's year and the student's enrolment.** Otherwise rejected.
4. **Effective dating.** Every membership and teacher row has `started_on`; a snapshot ends rows that are absent with `ended_on = as_of - 1`. Access is evaluated on current rows only (`ended_on IS NULL`), so a student who moved sets stops being visible to the old teacher on commit, and the old teacher's flags about them stay attached to the student (flags are about a student, not a section).
5. **The security section of the preview.** `ingest.diff` computes, per teacher, the students they would gain and lose, the sections that would have no teacher, and any teacher who would gain more than `mass_change_threshold` students (default 40) or any student outside the year groups they currently teach. It is printed above the fold and must be scrolled past to approve. A connector with auto-approve (§7.2) may not auto-approve a roster batch whose security section is non-empty beyond the school's tolerance; those batches wait for a human.
6. **Timetable grid.** `sis.timetable_period` (codes, sequence, times) comes from the SIS's period definition (Veracross block groups and rotation days; ManageBac's academic-year calendar with rotation days; iSAMS "Weeks, Days & Periods"). Sections with rotating meeting times need more than pass 1's single `timetable_period_id`: §10 adds `sis.section_meeting (section_id, day_of_cycle, timetable_period_id)` (D5), and `sis.section.timetable_period_id` is kept as "the period this section is timetabled in for clash purposes" for schools where a course sits in one block, which is the IB selection module's model (`ib.subject_level_period`, pass 1).
7. **Feeder sets.** `sis.section.feeder_set_key` (pass 1; the IB prerequisite check compares a Grade 10 mathematics set) is set by a profile lookup on the section code or name (`"10C/Ma3 (Foundation)"` → `foundation`). Question 54 in pass 1 asks whether the sets are identifiable in the export.
8. **Tests.** `packages/ingest/test/roster-security.spec.ts` asserts, over the Wellesmere fixture: a teacher absent from the staff file gains nothing; a truncated roster (50% of rows) fails `max_end_ratio`; a membership outside the enrolment is rejected; after a snapshot moves a student between sets the old teacher's `roster` scope no longer returns the student; the preview's security section lists exactly the gains and losses.

### 5.5 Parent contacts and relationships

Canonical `guardian` fields: `external_id`, names, `email`, `phone`, `language_pref`, `contact_pref`; canonical `guardian_link` fields: `student external_id`, `guardian external_id`, `relationship` (raw, plus a lookup to a small canonical set: mother, father, guardian, step-parent, grandparent, other), `is_primary`, `consent` (optional), `lives_with` (optional, recorded, unused in v1). Sources: Veracross Households, Household Members and Relationships (Edlink's inventory lists all three plus Emergency Contacts and Relatives, §7.3); ManageBac parents with `child_ids` ([ManageBac v2.2 parents](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/parents.md)); iSAMS Contacts and Contact types (§7.5). Rules in §4.7. Emergency contacts who are not guardians are not imported: CAROS has no use for them and importing them widens the personal data held for no purpose.

### 5.6 The school calendar and exam periods

- `sis.academic_year` and `sis.term` from the SIS (Veracross Years and Grading Periods; ManageBac academic years and terms per programme via `/v2p2/school/academic-years` ([ManageBac v2.2 academics](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/academics.md)); iSAMS School Terms). One `calendar` profile per source; the seed creates the years around the anchor date (pass 1 DR-8).
- `sis.calendar_period` rows of kind `holiday`, `inset`, `event` from the SIS calendar export where one exists (Veracross Events, ManageBac's academic-year calendar with rotation days and vacation exclusions, iSAMS Calendar Manager). Rows of kind `exam_period`, `mock_period`, `reporting_window` are rarely in an SIS export as such; they are entered in the Studio's calendar screen by the `school_admin` or the IB coordinator from the school's published calendar, with `affects_domains` chosen from the domain list and `year_group_ids` where the period applies to some year groups only (Grade 12 mocks). Each row records `source = 'manual'` and who entered it. A term boundary is itself a suppression-relevant fact (pass 3 asked for "term boundaries and seasonality").
- `sis.school_day` is materialised by `ingest.after_commit` from the year's dates, `core.school.weekend_days`, `holiday` periods and `#`-coded closures, and is what "within 2 school days" reads (pass 1).
- Ramadan and other observance periods that change school hours are `calendar_period` rows of kind `other` with `affects_domains` set by the school; question 42 in ACS-IT-QUESTIONS.md already asks the counselors when a signal is expected and not worrying.

### 5.7 Subjects and canonical keys

`sis.subject.canonical_key` maps a school's course to a platform vocabulary `subject_canonical` (`mathematics`, `mathematics_aa`, `mathematics_ai`, `physics`, `economics`, `english_literature`, …, with aliases). It is what lets an offer condition "AAB including Mathematics" (`uni.offer.conditions_structured.required_subjects[].key`) and an entry requirement (`ref.entry_requirement.structured.subjects[].key`) be checked against a student's sections, and what `ib.subject.sis_subject_id` links through. The profile's `map_subject` op resolves codes and names through the aliases; unmapped subjects are imported with `canonical_key = NULL` and listed in the preview so the admin can map them once, in the vocabulary, for every future import.

---

## 6. The granularity problem

### 6.1 What the engine wants

From the prototype's own series: eight weekly points per domain per student (`baselines.*.series`, `pts: W1..W8`); a per-assessment academic series ("Mathematics 74%, his first result outside his personal band in 22 months"); per-session attendance ("three late arrivals in ten school days", "first-period punctuality"); coursework submission rates with missed deadlines; behaviour incidents by date; engagement daily. Pass 3 will specify the statistics; this pass says what the data can carry.

### 6.2 What a realistic termly export supports

The distinction that matters is between what a termly file *contains* and *when* it arrives. A Veracross Axiom query can be exported to Excel or CSV from the query's Action menu, and a delimited "Export to File" can be produced from an Axiom report (community articles *Exporting Data to Excel or CSV File* and *Guide: Axiom*, JavaScript-rendered; content taken from their search snippets). The Data API's inventory includes assignment grades, class attendance and master (daily) attendance, and behaviour (§7.3), so those tables exist in the SIS and can be queried by date. A termly export can therefore contain **daily** attendance rows and **per-assignment** grade rows; what it cannot do is deliver them before the term ends.

| Domain | A termly file can contain | Weekly baseline from termly delivery | What is lost |
|---|---|---|---|
| Academic | per-assignment scores with dates (if the school runs a gradebook in the SIS); otherwise one working grade per subject per term | computable retrospectively for the term just ended: 10 to 14 weekly points per subject at ACS's semester length | a signal fires the day the file lands, up to 16 weeks after the change; "what changed overnight" is replaced by "what changed last term" |
| Attendance | per-day and per-lesson rows with status and reason | as above | the two-school-day check-in SLA is meaningless on data that is a term old |
| Behaviour | dated incidents | as above | same |
| Teacher concern | not from the SIS at all; lives in CAROS | live | none |
| Engagement | not from the SIS; CAROS activity and, if connected, Google Classroom | live | none |
| University progress | not from the SIS; CAROS, and Maia by CSV | as often as the counselor exports | none, if the export is weekly |
| Positive | derived from the above | | |

So with termly delivery three of the six domains that define the differentiator are retrospective. The engine can still be *validated* on termly history (pass 1 §8, question 46: pseudonymised historical exports to test whether the engine would have noticed students earlier), and the baselines can be *built* from it, which is real value at onboarding. But the product's core mechanism, personal deviation surfaced overnight so a counselor acts within two school days, **cannot run on termly delivery for academic, attendance and behaviour**, and this pass says so plainly. It is not a pipeline limitation; no pipeline can evaluate data it has not received.

### 6.3 What the engine does under each cadence

Stated here so pass 3 can specify it and so the pilot agreement can name it.

| Cadence (per domain) | Sweep behaviour | What the counselor sees |
|---|---|---|
| Nightly connector or daily file | as designed: the run is evaluated on data as of yesterday | the morning ritual |
| Weekly file (the pack in §6.4) | the file lands, `after_commit` runs a **backfill** evaluation (`sweep_trigger = 'backfill'`, pass 1) that evaluates each week since the last `as_of` in order, as of that week, so the tier history is honest about when each move would have happened; only the final state opens or re-tiers cases; earlier weeks' would-have-fired signals are recorded with `evaluation.suppressions`-style annotations for shadow comparison | "what changed this week", with the as-of date printed on the sheet; the SLA clock starts at the commit, not the observation, and the case shows both dates |
| Fortnightly | as weekly; the check-in SLA of two school days still holds from commit, but the persistence rule (`S.thresh.persist`, consecutive weeks) needs two files to see two weeks; pass 3 must decide whether a fortnightly file may count as two observations | as above, with a visible "data arrives fortnightly" note on the thresholds page |
| Termly | **retrospective mode**: the domain's series are built and displayed; deviation signals are computed but land as `review` at most and are labelled "from the Semester 1 export"; the domain is excluded from the urgent and check-in tiers by configuration (`engine.tiering`, pass 3), because an urgent tier with a two-day SLA on 12-week-old data would be a false promise; recovery and relapse detection still work across terms | the caseload sheet marks the domain "termly"; the case file's run shows the term's weeks; the morning ritual is driven by the live domains |

The tenant's `ingest.expected_cadence` is what selects the mode per domain; it is data, so a school that moves from termly to weekly moves modes without a deploy.

### 6.4 The minimum export the pilot must ask ACS for

The **weekly export pack**: six Axiom saved queries (or scheduled report exports) that a registrar or IT person runs every Monday before 09:00, or that a scheduled job at the school drops on an SFTP endpoint CAROS provides (§9 step 9; question 73). Each file carries the same columns every week so one profile version serves all year. Columns are named here as canonical needs; the Veracross field names are whatever the query designer exposes, and the profile binds them.

| # | File | Cadence | Rows | Columns needed (canonical) | Why |
|---|---|---|---|---|---|
| 1 | `assignment_grades` | weekly, rows with a graded or missing date in the last 21 days (overlap on purpose, idempotent by key) | one per student per assignment | student external id, section external id, assignment external id, assignment title, category, date assigned, date due, date graded, score, max score, missing flag, (weight) | the academic series and the coursework-submission series |
| 2 | `attendance` | weekly, last 21 days | one per student per day (master) plus one per student per lesson (class) | student external id, date, period code or AM/PM, section external id (class rows), status, excused flag, reason or note, minutes late | attendance and punctuality series; suppression |
| 3 | `behaviour` | weekly, last 21 days | one per incident | student external id, date-time, category, points, severity, reported-by staff id, (description) | behaviour domain, positive domain |
| 4 | `roster` | weekly, full snapshot | one per student per section, and one per teacher per section | section external id, code, name, subject code, level, period/block, academic year, teacher external id(s), student external id, start date | rosters are permissions; weekly keeps them right within days of a set change |
| 5 | `enrolment_and_contacts` | at term start and on request; weekly is cheap | one per student, one per guardian link | student external id, student number, names, preferred name, DOB, gender (optional), nationality (fee-status only), year group, programme/track, homeroom, counselor, enrolment status, joined, left, school email; guardian id, names, relationship, primary flag, email, phone, language, contact preference | identity, enrolment, the parent link |
| 6 | `term_grades_and_predictions` | at each reporting window | one per student per subject | student external id, section external id, term, working grade, predicted grade, scale, teacher comment (optional) | transcript page, predicted-versus-achieved, university classification |
| 7 | `calendar` | yearly and on change | one per period | year, terms with dates, holidays, exam and mock periods with year groups, reporting windows | school days, suppression |

If ACS cannot run 1 to 3 weekly, the fallback in order of preference is: (a) read-only Data API access to the same three areas (§7.3), which turns the pack into a nightly connector; (b) fortnightly files; (c) a Google Classroom connection for the academic and coursework series, which gives per-assignment due dates, submission states, the `late` flag and assigned grades daily without touching the SIS (§7.6), with attendance and behaviour remaining termly and retrospective. Termly-only for all three is the retrospective mode of §6.3 and should be written into the pilot agreement as such.

### 6.5 What this does to the seed and to pass 3

The ACS fixture (§8) is built as **weekly packs**, twelve of them, so that the engine's reproduction test (pass 1 DR-8) runs the real cadence: each pack is imported in sequence in the test, and the backfill evaluation must reproduce the authored series. The Wellesmere fixture is built as **termly** files plus one mid-term correction, so retrospective mode and re-import are exercised. Pass 3 is asked (§13) to define the backfill evaluation, the fortnightly persistence rule, the retrospective tier cap, and how a superseded fact behind a signal is handled.

---

## 7. The connector interface and the incumbent systems

### 7.1 The interface

In `packages/contracts/src/ingest/connector.ts` (types) and `packages/ingest/src/connectors/` (adapters). Read-only by construction: the interface has no method that sends data anywhere but CAROS.

```ts
export type SourceKind = 'csv' | 'fixture' | 'veracross' | 'managebac' | 'isams' | 'google_classroom' | 'maia_csv';

export type ImportKind =
  | 'enrolment' | 'contacts' | 'staff' | 'subjects' | 'timetable' | 'roster'
  | 'grades' | 'term_grades' | 'attendance' | 'behaviour' | 'calendar'
  | 'activity' | 'university' | 'documents' | 'cas_balance' | 'ee_record';

export interface CanonicalEnvelope<K extends EntityKind = EntityKind> {
  kind: K;
  record: CanonicalRecord[K];          // Zod-validated shape per entity kind (§3.4 keys, §5 fields)
  sourceRef: { system: string; resource: string; externalId?: string; rowNo?: number; url?: string };
  observedAt: string;                  // ISO instant the source reported, or the file's as_of
}

export interface Capability {
  importKind: ImportKind;
  granularity: 'per_session' | 'per_day' | 'per_assessment' | 'per_term' | 'per_event' | 'snapshot';
  delta: boolean;                      // supports "changed since cursor"
  cadenceMin: 'realtime' | 'hourly' | 'daily' | 'weekly' | 'termly';
  notes?: string;
}

export interface Connector {
  readonly kind: SourceKind;
  /** What this source can supply, given the school's configuration. */
  capabilities(ctx: SourceContext): Promise<Capability[]>;
  /** Credentials resolve, the token has only the scopes we asked for, and none of them writes. */
  verify(ctx: SourceContext): Promise<VerifyResult>;
  /** Cheap reconnaissance for the Studio: academic years, programmes, sample records, detected fields. */
  discover(ctx: SourceContext): Promise<Discovery>;
  /** Pull one import kind from a cursor. Yields envelopes; never mutates the source. */
  pull(ctx: SourceContext, req: { importKind: ImportKind; cursor?: Cursor; window?: { from: string; to: string } }):
    AsyncIterable<CanonicalEnvelope>;
  /** The cursor to store after a successful run. */
  nextCursor(ctx: SourceContext, req: PullRequest, last?: CanonicalEnvelope): Cursor;
}

export interface SourceContext {
  schoolId: string; sourceSystemId: string;
  config: SourceConfig;                // per-school, per-source data (§7.2); no secrets
  secrets: SecretRef;                  // Key Vault reference resolved inside the worker only
  clock: { schoolToday(): string; now(): string };
  http: RateLimitedHttp;               // one client per source with the source's documented limits and 429 handling
}
```

The CSV adapter's `pull` parses a file and applies a mapping profile; `discover` returns headers and sample rows; `capabilities` are whatever the profiles declare. Live adapters carry their field bindings in code (shared by every school on that system) and their per-school variation in `SourceConfig` (base URL region, programme codes, attendance category meanings, year-group mapping, which classes count as IB, auto-approve policy). That configuration is validated by a per-adapter Zod schema and edited in the Studio. `dependency-cruiser` forbids any adapter from importing `packages/db`: adapters produce envelopes; the pipeline persists them.

### 7.2 Connector runs

- **Schedule.** `ingest.connector.tick` every 15 minutes enqueues `ingest.connector.run` per active source and resource when its schedule (in the school's timezone; default 22:30 local so the sweep at 02:00 sees today) is due and no run exists for that local date.
- **Windows and overlap.** Each resource pulls "changed since cursor" where the source supports delta (`modified_since` on ManageBac; `on_or_after_update_date`-style filters on Veracross; `updateTime` filters are not offered by Classroom's list endpoints, which are paged and filtered by state instead) and otherwise a rolling window of 21 days, re-keyed by natural key so overlap is harmless.
- **Raw artefact.** Envelopes are written as JSON Lines to the raw-import container before staging, so a connector run is replayable exactly like a file.
- **Auto-approve.** `SourceConfig.autoApprove: { grades: true, attendance: true, behaviour: true, roster: 'if_security_section_empty', enrolment: false, contacts: false }`. Anything not auto-approved waits in the Studio and the school_admin is notified in-app. A batch whose expectations `fail` is never auto-approved.
- **Rate limits and retries.** One `RateLimitedHttp` per source with a token bucket set below the documented limit, honour of `Retry-After` and `X-RateLimit-Reset`, exponential backoff with jitter, and a run budget (requests and wall time) after which the run is `partial` with its cursor advanced only for completed resources.
- **Credentials.** Client id and secret (or API token) live in Key Vault under `<school_id>/<source_system_id>/…`; `ingest.source_system.config` holds only the reference. Rotation is a Studio action that writes the new secret and re-runs `verify`. `verify` fails if the token can reach a write endpoint we did not ask for, where the vendor lets us test that (ManageBac's `/v2p2/auth/permissions`; Veracross scope errors).
- **Failure.** 401/403 opens an in-app alert to the school_admin and a Monitor alert to CAROS; the source is paused after three consecutive failures. `ingest.expected_cadence` then shows the domain as stale on the caseload sheet.

### 7.3 Veracross (SIS at ACS)

**What is documented.** Veracross exposes a **Data API (v3)** and, as a premium add-on, **API Plus for Academics**, which serves the same data in OneRoster 1.1 form.

- *Authentication.* OAuth 2.0 client-credentials: "access tokens created with client credentials are only for secure, server-side access to school data"; a token is created for a stated list of scopes, and "you can only create access tokens with scopes that have been pre-approved on your OAuth Application at each school"; the token lifetime "isn't configurable and is currently set to 1 hour" ([Veracross API: Access Tokens](https://api-docs.veracross.com/docs/docs/097f6c769cafb-access-tokens); the page is JavaScript-rendered and these sentences come from its search snippets). Scope strings are of the form `students:list`, `students:read` (same page), and the school-facing names used when a vendor asks for them are of the form "List Students", "List Academics: Assignment Grades", "Read Academics: Class Assignment" ([Edlink, Connecting Veracross](https://ed.link/docs/providers/veracross/connecting)). Read-only access is therefore the normal case: CAROS asks only for `*:list` and `*:read` scopes, and a token cannot exceed what the school pre-approved.
- *Who at the school grants it.* A user holding the supplemental **`OAuth_App_Admin`** security role (which SysAdmin does not include) creates an Integration Partner in Axiom's Identity & Access Management, starts the integration to generate an OAuth Application record, and enables scopes on its Scopes tab; the vendor then receives credentials ([Veracross community, *Creating an OAuth Application: School Workflow* and *OAuth Applications and Veracross Overview*](https://community.veracross.com/s/article/Creating-an-OAuth-Application-School-Workflow), JavaScript-rendered, summarised from search snippets; corroborated step by step by [Orah's Veracross guide](https://success.orah.com/en/articles/5597576-how-to-enable-and-use-the-veracross-integration) and Edlink's). 
- *Rate limits.* The API documentation has a "Rate Limiting" page that could not be retrieved. The one figure retrieved is from a secondary source: the Authorization API allows "up to 300 requests every 3 minutes" per OAuth application, with HTTP 429 beyond it, and the Data API "also implements rate limiting based on the OAuth Application record" ([Edlink, Veracross Integration Challenges](https://ed.link/community/veracross-integration-challenges/)). **Assumption:** plan the adapter at one request per second with 429 handling and a nightly budget of 3,000 requests, and read the real limit off the page during onboarding.
- *Data areas.* Edlink's inventory of what the Veracross API exposes ([What Data Can the Veracross API Access](https://ed.link/community/what-data-can-the-veracross-api-access/)) lists, among others: Students, Parents, Relationships, Households, Household Members, Emergency Contacts, Staff/Faculty, Class Teachers; Classes, Courses, Subjects, Departments, Enrollments, Rosters, Block Groups, Class Meeting Times, Rotation Days; Class Assignments, Assignment Grades, Grading Periods, Numeric Grades, Qualitative Grades, GPAs, Rubrics; **Class Attendance** and **Master Attendance** as separate areas; Behavior; Years; Events. Individual endpoint pages exist in the docs for classes, relationships, events (with an `on_or_after_update_date` filter) and "Academics: Student Alerts" ([Read Classes](https://api-docs.veracross.com/docs/docs/dbdb475f46cea-read-classes), [Read Relationships](https://api-docs.veracross.com/docs/docs/56ec0b06079ff-read-relationships), [List Events](https://api-docs.veracross.com/docs/docs/1e238d1b394d6-list-events), [List Academics: Student Alerts](https://api-docs.veracross.com/docs/docs/d925f0ea0fad1-list-academics-student-alerts)).
- *Change notification.* None documented to vendors. Polling with update-date filters is the model.
- *OneRoster.* API Plus for Academics is "a premium add-on" that serves OneRoster 1.1 at `https://oneroster.veracross.com/{school route}/ims/oneroster/v1p1/`, with the Rostering, Resources and Gradebook (line items, results, categories) services; "newly and late-enrolled students must be assigned an institution grouping value in order to appear in the OneRoster API", and mapping changes "do NOT trigger automatic change syncing on the vendor side" ([Veracross community, *API Plus for Academics: Overview* and *Self Start Guide*](https://community.veracross.com/s/article/API-Plus-for-Academics-Overview), JavaScript-rendered, from search snippets; [Using the OneRoster API](https://api-docs.veracross.com/docs/api-plus-for-academics/bd08d5lpygdl1-using-the-one-roster-api)). Veracross holds a 1EdTech certification listing ([1EdTech: Veracross](https://site.imsglobal.org/certifications/veracross)). OneRoster carries no attendance (§7.8), so API Plus alone cannot feed the attendance domain.
- *File export.* Axiom query results export to Excel or CSV, and Axiom reports can produce a delimited "Export to File" ([Veracross community, *Exporting Data to Excel or CSV File*](https://community.veracross.com/s/article/Exporting-Data-to-Excel-or-CSV-File), from search snippets). Whether an export can be scheduled unattended at ACS is question 73.

**Which CAROS fields it feeds.**

| Veracross area | Import kind | CAROS target | Precedence |
|---|---|---|---|
| Students, Enrollments, Years | `enrolment` | `core.person`, `sis.student`, `sis.enrolment`, `sis.external_identity(veracross)` | 1st for identity and enrolment |
| Households, Household Members, Relationships, Parents | `contacts` | `core.person` (guardian), `family.guardian_link` | 1st |
| Staff/Faculty, Class Teachers | `staff`, `roster` | `core.person` (staff), `core.staff_profile`, `auth.membership(teacher, import)`, `sis.section_teacher` | 1st |
| Classes, Courses, Subjects, Rosters, Block Groups, Rotation Days, Class Meeting Times | `subjects`, `timetable`, `roster` | `sis.subject`, `sis.timetable_period`, `sis.section`, `sis.section_meeting`, `sis.section_membership` | 1st |
| Class Assignments, Assignment Grades | `grades` | `sis.assessment`, `sis.grade(achieved)` | 1st for achieved grades |
| Grading Periods, Numeric/Qualitative Grades | `term_grades` | `sis.assessment(term_grade)`, `sis.grade(working)`; predicted where the school records it here | 1st for working; ManageBac may be 1st for IB predicted (question 75) |
| Master Attendance, Class Attendance | `attendance` | `sis.attendance_event` (day rows and period rows) | 1st |
| Behavior | `behaviour` | `sis.behaviour_event` | 1st |
| Events, Years | `calendar` | `sis.academic_year`, `sis.term`, `sis.calendar_period(holiday, event)` | 1st for dates; exam periods manual |

**Adapter plan.** `VeracrossConnector` with resources `students`, `enrollments`, `households`, `relationships`, `staff`, `classes`, `class_teachers`, `rosters`, `assignments`, `assignment_grades`, `grading_periods`, `numeric_grades`, `master_attendance`, `class_attendance`, `behavior`, `years`, `events`; cursor = the update-date filter where the endpoint has one, else a 21-day window; `verify` requests a token with exactly the read scopes and fails if any scope is refused or if the school's application also pre-approved a write scope we did not request (the vendor's design makes the second case impossible to exploit, but it is worth telling the school). A `VeracrossOneRosterConnector` over API Plus is a second, smaller adapter for schools that already pay for it (rostering and gradebook only). Until the Data API pages are read in full during onboarding, field names are assumptions and the fixture (§8.1) is labelled so.

### 7.4 ManageBac (IB Diploma at ACS)

**What is documented** ([ManageBac public REST API, v2.2](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/authentication.md); each endpoint page is cited inline).

- *Regions and base URLs.* `https://api.managebac.com` (Canada), `https://api.managebac.cn` (China), `https://api.us.managebac.com` and `https://api.managebac.us` (US) ([authentication](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/authentication.md)). ManageBac states it is "hosted in the cloud across Amazon Web Services data centres in Canada, the United States, and China", the location depending on the school and local law ([ManageBac FAQ](https://help.managebac.com/hc/en-us/articles/360031510571-ManageBac-FAQs)). ACS's region is question 76; it matters because it tells us where ACS's IB records already sit.
- *Authentication.* Three methods: an OAuth 2.0 bearer token from `/oauth/token` with `grant_type=client_credentials` (a JWT with `expires_in` and granted scopes), or an `auth-token` header, or an `auth_token` query parameter (discouraged); `/v2p2/auth/permissions` "retrieves all resources that the passed authentication token is currently authorized to access" ([authentication](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/authentication.md)). Tokens are generated by the school in Settings → Develop → **API Manager**, where a token can be created as **Read-only** ([Kognity help, *How to get the ManageBac API token*](https://intercom.help/kognity/en/articles/5316174-how-to-get-the-managebac-api-token-to-set-up-classes-in-kognity), a vendor's guide; the ManageBac help-centre article on the API Manager is behind a login). A read-only token is tenant-wide: it can read every student and teacher the API exposes, so the token is the school's data and is handled as such (Key Vault, rotation every six months, which is also Faria's own recommendation: rotate credentials and place tokens in a header rather than a query string, [Faria Suite security](https://guide.fariaedu.com/integrations-portal/faria-suite/integrating-with-faria-suite-apis/security.md)).
- *Rate limits.* Per IP; the documented example is "50 requests per second (per IP)", adjustable "at any time without prior notice"; a 429 carries `X-RateLimit-Limit`, `X-RateLimit-Period` and `X-RateLimit-Reset` headers ([rate limitations and throttling](https://guide.fariaedu.com/integrations-portal/faria-suite/integrating-with-faria-suite-apis/rate-limitations-and-throttling.md)). Pagination is `page` and `per_page` with a `meta` block (`current_page`, `total_pages`, `total_count`, `per_page`), default 100 and maximum 200 per page; delta by `modified_since`, and for students, parents and behaviour notes also `deleted_since` ([pagination, delta and filtering](https://guide.fariaedu.com/integrations-portal/faria-suite/integrating-with-faria-suite-apis/pagination-delta-filters.md); [students](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/students.md)).
- *Endpoints.* Students (`id`, `student_id` / `identifier` as the school's own id, `email`, names, `year_group_id`, `homeroom_advisor_id`, `parent_ids`, `graduating_year`, `nationalities`, `graduated_on`, `withdrawn_on`; archive requires a withdrawal or graduation date); parents (`child_ids`, contact fields); classes (`grade`, `program`, `subject_id`, `applicable_levels`, `start_term_id`, `end_term_id`, teachers); memberships (`GET /v2p2/classes/{id}/students` returns "a mapping of student IDs to their level (SL or HL)"; `GET /v2p2/memberships` school-wide with `level` 0 = SL, 1 = HL) ([memberships](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/memberships.md)); year groups with advisors, including "the Homeroom, CAS, EE, TOK, and Project-based Learning advisors" ([year groups](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/year-groups.md)); attendance per class by term or date and homeroom attendance per year group by term or date, with categories per academic year (`label`, `abbreviation`, `status_type` present/absent/late), per-record `status`, `note`, `period`, `rotation_slot`, and parent-submitted **excusals** (`start_date`, `end_date` 1 to 12 days, `comment`) ([attendance](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/attendance.md)); behaviour notes (`incident_time`, `behavior_type`, `notes`, `next_step`, `reported_by`; filters `modified_since`, `student_ids`) ([behavior notes](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/behavior-notes.md)); coursework: tasks per class with `due_date`, per-task student results with criterion-level detail, and "all gradebook grades for every student in a class" per term via `GET /v2p2/classes/{class_id}/assessments/term/{term_id}/grades` ([coursework](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/coursework.md)); academics: academic years and terms per programme, a calendar with rotation days, subjects and subject groups, `term-grade-scales` mapping percentage thresholds to marks, and published term reports downloadable as PDF or as a "term grades" ZIP ([academics](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/academics.md)).
- *What is absent.* **No CAS, Extended Essay, TOK or portfolio endpoints** appear anywhere in the v2 to v2.3 index or the "extended APIs" page ([llms.txt index](https://guide.fariaedu.com/llms.txt); [extended APIs](https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/extended-apis.md), retrieved 2026-09-23). The only IB-core data the API exposes is which staff are the CAS and EE advisors of a year group. Term reports can be downloaded as files.
- *OneRoster.* ManageBac imports and exports **OneRoster 1.2 CSV** through its Data Exchange hub, using a "ManageBac+ OneRoster Dialect" that extends the base files (manifest, academicSessions, orgs, courses, classes, roles, users, enrollments, with grade mappings), and it "is not able to import from other OneRoster systems that only export base OneRoster data"; OneRoster **REST** is "on the roadmap" ([ManageBac OneRoster 1.2 CSV custom specification](https://guide.fariaedu.com/managebac-oneroster-custom-specification); [CSV bindings](https://guide.fariaedu.com/integrations-portal/managebac/oneroster-1.2/csv-bindings.md); [REST bindings](https://guide.fariaedu.com/integrations-portal/managebac/oneroster-1.2/rest-api-bindings.md)). Faria reports "18 new endpoints and 10 updated ones since August 2024", including coursework APIs ([Faria, Connected by Design](http://www.faria.org/insights/connected-by-design/)).

**Which CAROS fields it feeds, and the double-maintenance rule.**

| ManageBac data | Import kind | CAROS target | Precedence and rule |
|---|---|---|---|
| Classes, memberships with HL/SL level | `roster` (IB view) | `sis.section.level`, `ib.subject.sis_subject_id`, and the *level* on `ib.selection_pick` once a selection is approved | ManageBac is 1st for **level**; Veracross is 1st for the roster itself. A disagreement on membership is a conflict row |
| Year-group CAS/EE/TOK advisors | `staff` | `auth.membership` capabilities are **not** set from this (pass 4); recorded as `core.staff_profile.subject_area` hints only | informational |
| Coursework tasks and per-task grades; term gradebook grades | `grades` | `sis.assessment`, `sis.grade(achieved)` | 2nd after the SIS gradebook; 1st if the school's teachers grade in ManageBac and not in Veracross (question 77) |
| Term reports (term grades ZIP) | `term_grades` | `sis.grade(working)`, and `predicted` where the report carries predictions | 1st for IB working and predicted grades if the school reports from ManageBac (question 75) |
| Class and homeroom attendance, excusals | `attendance` | `sis.attendance_event`; an excusal becomes `authorised = true` with `reason_label = comment` for the days it covers | 2nd after Veracross; the *excusal* is unique to ManageBac and is merged as a reason onto Veracross's rows for the same days |
| Behaviour notes | `behaviour` | `sis.behaviour_event` | 2nd after Veracross; conflict if both hold the same incident |
| CAS hours, reflections; EE proposal, supervisor, reflections | none via API | | **Cannot be read.** See below |

**CAS and the Extended Essay.** Because the API does not expose them, "read from ManageBac so nobody enters CAS twice" is not available as an integration today. Three honest options, to be chosen per school at onboarding:

1. **ManageBac stays the system of record for CAS and EE; CAROS does not model them for that school.** `core.school_module` `cas` and `extended_essay` off. CAROS's coordinator views for CAS and EE are not offered. Nothing is entered twice because CAROS holds nothing. This is the default for a school that already runs CAS and EE in ManageBac and is happy with it.
2. **CAROS becomes the system of record for the IB module, and ManageBac's history is imported once.** The coordinator exports CAS totals per strand (ManageBac's CAS worksheets show hours and reflections in the UI; a CSV export exists in the coordinator's CAS review screens according to the help centre's feature descriptions, but no export format is documented publicly) and CAROS imports one `imported_balance` row per strand per student (pass 1) plus the EE supervisor and research question as an `ee_record`. From then on entries are made in CAROS only. This is what the prototype's IB module assumes, and it is a workflow decision for Mr Diaz and the coordinator, not an integration.
3. **Both, with a termly reconciliation file.** Rejected: that is the double maintenance the decision forbids.

The IB **subject selection** is a different case: ManageBac holds the *outcome* (memberships with levels in the next year's classes), not the choosing process, and ACS's process today is paper (CONTEXT.md §1, Mr Diaz). CAROS runs the round; when the school builds next year's classes in ManageBac or Veracross, the roster import confirms the approved picks (a mismatch between an approved selection and the imported membership is a conflict row the coordinator sees).

**Adapter plan.** `ManageBacConnector` with resources `students`, `parents`, `teachers`, `year_groups`, `classes`, `memberships`, `attendance:class`, `attendance:homeroom`, `excusals`, `behavior_notes`, `tasks`, `task_grades`, `term_grades` (via the report download when the school opts in), `academic_years`, `calendar`, `term_grade_scales`; cursor `modified_since` per resource; page size 200; the school's region base URL and programme codes in `SourceConfig`; `verify` calls `/v2p2/auth/permissions` and fails if any write-capable resource is listed for our token. Attendance endpoints may need enabling by the school in its integration settings (a restricted help-centre page states this per a search snippet; question 78).

### 7.5 iSAMS (second synthetic tenant, and a likely second school)

Not at ACS; included because the second seed tenant is iSAMS-shaped (pass 1 DR-8) and because British-curriculum schools in the UAE commonly run it.

- *Batch API.* Enabled by a school administrator in Control Panel → **API Services Manager** → Manage Batch API Keys; each key is created through an iSAMS support ticket and then configured with the "Batch Methods" (datasets) it may return; an IP allow-list is prompted for in the same screen, and the key's cache expiry defaults to 24 hours ([Wonde, iSAMS Batch API Integration Guide, 2021 and 2022 editions](https://www.wonde.com/wp-content/uploads/iSAMS-Batch-API-Integration-Guide-1.pdf); [Meet the Teacher, iSAMS setup](https://support.meettheteacher.com/article/978-isams-how-to-set-up-integration); [Zeidman, iSAMS API settings](https://www.zeidman.info/configure-isams-api-settings-for-importacular/)). The datasets an integrator ticks, per the Wonde guides: **Pupil Manager** (Current Students, Contacts, Siblings, Custom Groups), **HR Manager** (Current Staff), **School Manager** (Academic/Boarding/Pastoral Houses, School Divisions, School Forms, School Terms, Year Groups), **Teaching Manager** (Departments & Subjects, Teaching Sets, Teaching Set Lists, Teaching Forms), **Timetable Manager** (Published Timetable Schedule, Student Timetables, Timetable Week Allocations, Weeks/Days/Periods), **Calendar Manager**, **Registration Manager** (Registration Codes, Registration Present Codes, Registration Dates & Times, Registration Out of School, Registration status), which "needs to be on a separate key due to date filters", **Rewards and Conduct** (Module Types, Fields, Records) and **Discipline Manager** (Detentions). The response is XML. Integrators sync it on a schedule; one vendor documents "every 6 hours" ([Orah, iSAMS integration](https://success.orah.com/en/articles/5587407-how-to-enable-and-use-the-isams-integration)).
- *REST API.* OAuth 2.0 client credentials at `{domain}/auth/connect/token` with scopes `restapi` (REST) and `apiv1` (Batch), base `{domain}/api`, with client id and secret issued by iSAMS support on the school's request ([iSAMS REST API example app, Program.cs](https://raw.githubusercontent.com/iSAMS/REST-API-Example-App/master/VS2017/iSAMS-RestApi/Program.cs); Wonde guide). The developer portal itself (developer.isams.com) redirects to a login and could not be read, so the REST endpoint list for pupils, registration and gradebook, and any rate limit, are **unverified**. Gradebook and assessment datasets are not in the Wonde lists and are an assumption for the fixture.
- *Attendance codes.* iSAMS "Registration Codes" are the school's own set, which at English-curriculum schools follows the DfE list (§5.2, family 1).

**Fields fed:** identity and enrolment (Current Students with the school id, forms and year groups), contacts and siblings, staff, subjects and teaching sets (rosters), timetable, registration (per session, AM/PM or per period), rewards and conduct, terms and calendar. The adapter is `ISAMSBatchConnector` (XML → envelopes) and is second-school work, not pilot work; the fixture in §8.2 exercises the CSV path with the same shapes.

### 7.6 Google Classroom (engagement, coursework)

**What is documented** ([Classroom API reference](https://developers.google.com/classroom/reference/rest)).

- *Resources.* `courses`, `courses.students`, `courses.teachers`, `courses.courseWork` (with rubrics), `courses.courseWork.studentSubmissions`, `courses.announcements`, `courses.topics`, `userProfiles`, `invitations`, `registrations`. **No attendance and no gradebook beyond per-coursework grades.** A `StudentSubmission` carries `state` (`CREATED`, `TURNED_IN`, `RETURNED`, `RECLAIMED_BY_STUDENT`, plus edits after turn-in), a read-only `late` boolean, `draftGrade` and `assignedGrade`, `creationTime`, `updateTime` and a `submissionHistory` of state and grade changes ([StudentSubmission](https://developers.google.com/classroom/reference/rest/v1/courses.courseWork.studentSubmissions)); `list` filters by `userId`, `states` and `late` ([studentSubmissions.list](https://developers.google.com/classroom/reference/rest/v1/courses.courseWork.studentSubmissions/list)).
- *Scopes.* Read-only scopes exist for every resource CAROS needs: `classroom.courses.readonly`, `classroom.rosters.readonly`, `classroom.coursework.students.readonly` (submissions and grades for the teacher's classes), `classroom.profile.emails` to see addresses ([Classroom scopes](https://developers.google.com/classroom/guides/auth); [courses.students.list](https://developers.google.com/classroom/reference/rest/v1/courses.students/list)).
- *Authentication for a school-wide read.* A service account with **domain-wide delegation**: "a Workspace administrator of the organization can authorize an application to access Workspace user data on behalf of users", the super administrator enters the client id and the exact scopes in the Admin console, and the service account then acts as a named user with that user's permissions ([Google, service accounts and domain-wide delegation](https://developers.google.com/identity/protocols/oauth2/service-account)). CAROS would impersonate one **service identity the school creates** (a "caros-classroom-reader@" account given the Classroom admin or verified-teacher role the school chooses), not counselors or students.
- *Quotas.* 4,000,000 queries a day per client, 3,000 a minute per client, 1,200 a minute per user, measured on a 60-second moving average, with a note that "the permitted QPS may be increased or decreased depending on a number of operational factors" ([Classroom usage limits](https://developers.google.com/classroom/limits)). A nightly pull for 380 students in perhaps 60 courses is a few thousand requests.
- *Push.* Registrations for course roster changes and course work changes deliver to a Cloud Pub/Sub topic, last a week unless renewed, and "domain-wide delegation of authority is not supported for this purpose" ([push notifications](https://developers.google.com/classroom/guides/push-notifications)). Pub/Sub would also place a message stream on Google Cloud, which has no UAE region (pass 1 DR-1). So: nightly polling only.
- *Identity.* Students and teachers are "identified by the unique ID or email address of the user, as returned by the Directory API" ([manage users](https://developers.google.com/workspace/classroom/guides/manage-users)); §4.1 for how that meets SSO.

**Which CAROS fields it feeds.**

| Classroom data | Import kind | CAROS target | Rule |
|---|---|---|---|
| Course work with `dueDate`, `maxPoints`, `workType` | `grades` (assessment half) | `sis.assessment` with `kind` from `workType` and `external_ref = courseWork.id` | 3rd after SIS and ManageBac for the same assessment; a Classroom course is matched to a `sis.section` through `ingest.external_ref` by the course's `section`/name mapping in `SourceConfig`, never by guess |
| Submission `state`, `late`, `assignedGrade`, `updateTime` | `grades` (grade half), `activity` | `sis.grade(achieved)` when `assignedGrade` exists; `sis.grade.missing = true` when past due with state not `TURNED_IN`; `engagement.activity_event(source='google_classroom', kind='submission'|'late_submission'|'task_created')` | this is what makes the "coursework submitted (rolling %)" series and "two deadlines missed" real |
| Course rosters | `roster` (informational) | not written to `sis.section_membership` (Veracross is the roster of record); used only to match courses to sections and flagged as a conflict if a student is in a Classroom course but not the SIS section | rosters are permissions, and a Classroom course is not the SIS |

**Consent and minimisation.** Reading a minor's coursework activity to infer wellbeing is CONTEXT.md §11.8, and pass 4 must rule on it before this adapter is enabled for a real tenant. The adapter reads no attachments, no comments and no announcement text, only states, timestamps and grades; `engagement.activity_event` retention is 180 days (pass 1). ACS-IT-QUESTIONS.md question 14 already asks whether the school is comfortable with this.

### 7.7 Maia Learning (university applications at ACS)

**What is documented.** A search on 2026-09-23 found **no public developer API documentation** for MaiaLearning (the vendor's site, help material and press describe features, not endpoints). What is documented about its integrations:

- Inbound SIS data reaches Maia through **Edlink** ("detailed demographics, courses, and enrollments"; Maia had earlier "implemented OneRoster" and "relied on manual CSV uploads to supplement incomplete data") ([Edlink, MaiaLearning announcement](https://ed.link/community/new-client-announcement-maialearning/)) and through Clever Secure Sync rostering.
- Outbound: counselors send documents "through Common App and Parchment" in bulk, track receipts, and manage college lists, essays and applications ([MaiaLearning, Applying to College](https://www.maialearning.com/what-we-do/applying-to-college)); a partnership with the Common App from the 2019-20 season lets students and counselors "track applications, receipts, and results from inside" Maia ([press release](https://www.einpresswire.com/article/463197160/maialearning-partners-with-the-common-app)); colleges using Slate receive "application documents uploaded by high school counselors" as files plus a prospects CSV, matched on a MaiaLearning ID ([Slate, MaiaLearning integration](https://knowledge.technolutions.net/docs/maialearning-integration)).
- Counselor-side export: a third party's instructions say a counselor exports an "Applications by Colleges" report as CSV from the Applications Master List ([College Kickstart, exporting reports from Maia](https://support.collegekickstart.com/hc/en-us/articles/360039299451-Exporting-Reports-from-CIALFO-MAIA-LEARNING-NAVIANCE-or-SCOIR-for-use-in-College-Kickstart); the article itself returned 403 and this is from its search snippet).
- Data location: Maia's website privacy policy excludes "student, teacher, counselor or guardian information", which is governed by an Educational User Privacy Policy that was not retrieved; no hosting region is stated ([MaiaLearning privacy policy](https://www.maialearning.com/privacy-policy)). Question 79.

**Design consequence.** Maia is integrated as a **counselor-run CSV export on a cadence**, through the ordinary CSV adapter with a `maia` mapping profile, until Maia offers an API or a scheduled export (question 80). Fields fed:

| Maia export (inferred from the counselor UI; unverified) | Import kind | CAROS target | Rule |
|---|---|---|---|
| Student, college, programme, application type/round, deadline, status (planning, applied, submitted, decision), decision and date | `university` | `uni.student_target` (`added_by='import'`, `external_ref` = Maia list item id), `uni.application`, `uni.offer` | **Maia is the list of record while connected.** In CAROS the student's targets page shows the list read-only with "managed in Maia" and a link; the student adds and removes colleges in Maia; CAROS's own add-target mutation is disabled for that tenant (`core.school_module.config.university.list_of_record = 'maia'`). What CAROS adds on top is what Maia does not do: the reach/match/safety classification against sourced requirements, the list-balance rule, the deadline radar and the evidence chain |
| Document requests and receipts (transcript, counselor recommendation, teacher recommendations, school forms) with dates | `documents` | `uni.document_request` status and `received_at`/`sent_at` | Maia is 1st; CAROS chases (the reference SLA rule) from Maia's statuses and never re-keys them |
| Test scores, if exported | not imported in v1 | | pass 5 and the classification rule decide whether they are needed |

The student sees one list, in Maia, mirrored in CAROS; the counselor keeps one document tracker, in Maia, read by CAROS. If ACS decides to stop using a Maia feature (question 12 in ACS-IT-QUESTIONS.md), the tenant flag flips and CAROS's own mutations turn on, with Maia's last import as the opening state. Reference letters (`uni.reference_letter`) are authored in CAROS and uploaded to Maia by the counselor as a file; there is no documented path to push them, and CAROS never writes to Maia.

### 7.8 OneRoster as a shared dialect, and its limits

OneRoster 1.2.1's CSV binding defines a file set of which only `manifest.csv` is mandatory; the rostering files are `users`, `enrollments`, `classes`, `courses`, `orgs`, `academicSessions`, `roles` and `userProfiles`, the gradebook files are `lineItems`, `results`, `categories` and `scoreScales`, with `demographics` and resource files besides; required columns include, for `users.csv`, `sourcedId`, `enabledUser`, `username`, `givenName`, `familyName`, for `enrollments.csv` `sourcedId`, `classSourcedId`, `schoolSourcedId`, `userSourcedId`, `role`, and for `lineItems.csv` `sourcedId`, `title`, `assignDate`, `dueDate`, `classSourcedId`, `categorySourcedId`, `academicSessionSourcedId`, `schoolSourcedId`; processing is "bulk" (the file set is the reference) or "delta" (rows carry `status` active or tobedeleted and `dateLastModified`); **attendance is not part of OneRoster** ([1EdTech OneRoster 1.2.1 CSV binding](https://www.imsglobal.org/spec/oneroster/v1p2/bind/csv)).

CAROS therefore ships **one built-in OneRoster CSV profile family** (`oneroster_zip` file format, §3.1) covering enrolment, staff, roster, calendar (academic sessions) and grades (line items and results), which any OneRoster-exporting system can feed with at most a lookup table's worth of school configuration (grade-level mapping, class type to programme). ManageBac's dialect (§7.4) and Veracross API Plus (§7.3) both fit it. It never covers attendance, behaviour, contacts beyond what `users.csv` agents carry, or anything IB-specific, so it is a floor, not the connector.

### 7.9 Source-of-truth rules

`ingest.precedence` platform defaults (a school row overrides):

| `field_key` | Systems, first wins | Note |
|---|---|---|
| `person.student` (identity, names, DOB, enrolment) | SIS (`veracross` / `isams`), `managebac`, `google_classroom` | the SIS is the register |
| `person.guardian`, `family.guardian_link` | SIS, `managebac` | |
| `person.staff` | SIS, `managebac`, `google_classroom` | memberships and capabilities are never imported |
| `section`, `section_membership`, `section_teacher` | SIS, `managebac` | rosters are permissions; Classroom courses are informational |
| `section.level` (HL/SL) | `managebac`, SIS | ManageBac knows the level |
| `assessment`, `grade.achieved` | SIS gradebook, `managebac`, `google_classroom` | per school: whichever the teachers grade in (question 77) |
| `grade.working`, `grade.predicted` | the reporting system: SIS or `managebac` (question 75) | |
| `grade.final` | the exam board result as the school records it (SIS) | |
| `attendance` | SIS, `managebac` | ManageBac excusals merge as reasons |
| `behaviour` | SIS, `managebac` | |
| `calendar` | SIS, `managebac`, manual | exam periods manual |
| `university.target`, `application`, `offer`, `document` | `maia`, CAROS | Maia while connected |
| `cas`, `ee` | CAROS, or ManageBac by one-time import | §7.4 |
| `activity` | `google_classroom`, CAROS | additive, not competing |

**When two systems disagree on one natural key** inside the same window: the fact from each is stored with its `import_id`; the read view (`sis.v_current_grade`, `sis.v_current_attendance`, generated per table by the same helper) returns the row from the highest-precedence *active* source, falling back to the next when the first has no row; an `ingest.conflict` row is written and shown in the preview and in the Studio's conflicts list; the counselor's evidence chain prints which system the shown value came from. Silent merging of values (averaging, latest-wins across systems) is forbidden. A repeated conflict on the same key is one row updated, not a pile.

**Never maintained twice.** The rule that closes the loop: for every table with an import source, the domain layer's mutations check `core.school_module.config.<module>.record_system`; when it names an external system that is connected and active, user mutations on the imported rows are refused with a message that names the system ("This list is managed in Maia Learning; changes made there appear here after the next import"), and CAROS-native rows may only be added where the design says they are additive (a counselor's note on a target, an evidence item, a classification). A student in an IB module run in CAROS never re-enters a CAS hour that came from ManageBac; it sits in the ledger as `imported_balance` with the date range it covers.

---

## 8. Test fixtures

Both fixtures are **synthetic and inferred from public documentation**. No file from ACS, from any Veracross school, or from any iSAMS school has been seen, and none is represented. Column names are plausible names for a query designer or batch export to produce; they exist so that the mapping profiles, the identity ladder, the normaliser and the security checks are exercised from day one (pass 1 DR-8), and they will be replaced by the real layouts in the profiles, not in the code, when the real exports are seen. Each fixture is generated by a deterministic generator in `packages/seed/src/fixtures/<tenant>/` from the tenant's seed (so re-generation is byte-identical), written to `packages/seed/fixtures/<tenant>/<pack>/`, and shipped with an `expected.json` that records the counts and codes the pipeline must produce, which is the test oracle.

### 8.1 Veracross-shaped termly and weekly export (ACS tenant)

**Label in every file's first line (a comment row the profile skips):** `# SYNTHETIC FIXTURE · CAROS · inferred from public documentation of Veracross Axiom exports · no real school data`.

**Packs.** `2026-08-term-start/` (enrolment, contacts, staff, subjects, timetable, roster, calendar) then twelve weekly packs `2026-W36/` … `2026-W47/` (assignment_grades, attendance, behaviour, roster snapshot) and one reporting pack `2026-11-reporting/` (term_grades_and_predictions). The weekly packs are constructed so that the authored series in `STUDENTS[].baselines` (for example Ahmed's Mathematics 91, 93, 89, 92, 90, 88, 74, 41 and his punctuality 100, 100, 98, 100, 96, 88, 76, 70) fall out of the assignments and lessons they contain (pass 1 DR-8).

| File | Columns (header row) | Rows | Notes |
|---|---|---|---|
| `students.csv` | `Person ID, Student ID, First Name, Last Name, Preferred Name, Date of Birth, Gender, Grade Level, Program, Homeroom, Advisor Person ID, Counselor Person ID, Enrollment Status, Enrollment Date, Withdrawal Date, School Email, Citizenship` | 87 caseload + 201 Diploma cohort overlap-aware = ~330 | Dates in `M/d/yyyy` (US locale). `Grade Level` values `9`..`12`. `Program` in `IB Diploma`, `AP`, `ACS High School`, blank |
| `households.csv` | `Household ID, Household Name, Address City, Country` | ~300 | |
| `relationships.csv` | `Person ID, Related Person ID, Relationship, Is Guardian, Is Primary, Lives With, Household ID` | ~620 | guardian side |
| `parents.csv` | `Person ID, First Name, Last Name, Email, Mobile Phone, Preferred Language, Contact Preference` | ~560 | |
| `staff.csv` | `Person ID, First Name, Last Name, Title, Department, Role, School Email, Status` | ~90 | |
| `courses.csv` | `Course ID, Course Code, Course Name, Department, Subject, Level, Program` | ~110 | |
| `classes.csv` | `Class ID, Class Code, Course ID, School Year, Block, Rotation Days, Room, Grade Level` | ~180 | `Block` is `P1`..`P6`; `Rotation Days` a list |
| `class_teachers.csv` | `Class ID, Teacher Person ID, Role, Start Date, End Date` | ~200 | |
| `class_rosters.csv` | `Class ID, Student Person ID, Start Date, End Date` | ~2,200 | full snapshot weekly |
| `assignments.csv` | `Assignment ID, Class ID, Assignment Name, Category, Date Assigned, Date Due, Max Points, Weight` | ~1,400 per term | |
| `assignment_grades.csv` | `Assignment ID, Student Person ID, Score, Missing, Late, Date Graded, Comment` | ~9,000 per term; ~700 per weekly pack | `Missing` is `Y`/`N` |
| `grading_periods.csv` | `Grading Period ID, School Year, Name, Start Date, End Date` | 4 | |
| `term_grades.csv` | `Student Person ID, Class ID, Grading Period ID, Numeric Grade, Letter Grade, Predicted Grade, Scale, Teacher Comment` | ~2,000 per reporting pack | `Scale` in `IB 1-7`, `Percent`, `AP Percent` |
| `master_attendance.csv` | `Student Person ID, Date, Status, Excused, Reason, Notes, Minutes Late` | ~330 × school days | `Status` in `Present`, `Absent`, `Tardy`, `Early Dismissal` |
| `class_attendance.csv` | `Student Person ID, Class ID, Date, Block, Status, Excused, Notes` | ~330 × 6 × days | first-period punctuality lives here |
| `behavior.csv` | `Behavior ID, Student Person ID, Date, Category, Points, Reported By Person ID, Description` | ~120 per term | mixed polarity |
| `calendar.csv` | `School Year, Type, Name, Start Date, End Date, Grade Levels` | ~40 | holidays, exam windows, reporting windows |

**Deliberate defects** (each with its expected code in `expected.json`):

1. `students.csv` row with a UTF-8 BOM and one row with trailing spaces in every cell (`trim_cells`).
2. One student whose `Date of Birth` is `13/11/2009` in a `M/d/yyyy` file → `date_unparseable` (the classic locale trap).
3. One `Student ID` exported as `4412` where earlier packs had `004412` → resolved by rung 1 (Person ID), and the profile's `pad_start` documents the fix.
4. A name change in week 40 (surname changes, same Person ID) → name history row, no new person.
5. A mid-year transfer in (week 38) and a withdrawal (week 41, absent from the roster snapshot and marked `Withdrawn`) → `transferred_in`, then `withdrawn` with C22 closure.
6. Two siblings sharing a guardian; one guardian pair sharing an email address → §4.7 rule (b).
7. A cover teacher `J. Davies (cover)` in `class_teachers.csv` with a Person ID that is not in `staff.csv` → `unknown_teacher`, section imported without them.
8. One section with no teacher at all → listed in the security section.
9. A roster snapshot that moves three students between mathematics sets in week 42 → security section shows gains and losses; the old teacher's roster scope loses them.
10. Duplicate rows in `assignment_grades.csv` (identical) and a conflicting duplicate (same key, different score) → `unchanged` and `duplicate_in_file`.
11. An attendance status `EX` (unmapped) → `lookup_unmapped`, kept raw.
12. A grade for a student not on the class roster on that date → `grade_without_membership` warning.
13. A weekly pack whose `as_of` is 15 days old → `stale_as_of` warning (expectation `as_of_within_days: 10`).
14. A truncated weekly roster (55% of rows) → `max_end_ratio` fails the batch; nothing commits.
15. A corrected re-upload of week 44 with two scores changed → exactly two `supersede`s.
16. A `Citizenship` column present in one pack although the profile lists it under `forbidden_columns` → the batch fails before staging.
17. Assignment scores that reproduce the authored series, including `Missing = Y` rows in weeks 45 to 47 for Daniel (`s15`) so the coursework-submission series falls from 94% to 33%.
18. Exam-period rows in `calendar.csv` for Grade 12 in week 46, so that a Grade 12 dip inside the window is suppressed while a Grade 11 dip is not (pass 3 test).

### 8.2 iSAMS-shaped termly export (Wellesmere tenant)

**Label:** `# SYNTHETIC FIXTURE · CAROS · inferred from public descriptions of iSAMS Batch API datasets · no real school data`. iSAMS's Batch API returns XML; the fixture is CSV "as a school's data manager would flatten the datasets", because the CSV adapter is the pilot path and the XML adapter is second-school work (§7.5). Field names follow the dataset names in §7.5; the columns inside each are inferred.

**Packs.** `2026-09-michaelmas/` (whole term, delivered once, termly cadence) and `2027-01-lent/`, plus `2026-11-correction/` (a corrected registration file for three weeks).

| File | Columns | Rows | Notes |
|---|---|---|---|
| `pupils.csv` | `SchoolId, PupilId, Forename, Surname, PreferredName, DOB, Gender, NCYear, Form, House, Boarder, EnrolmentDate, LeavingDate, Status, EmailAddress, Nationality, UPN` | ~120 | `NCYear` 10..13; `Boarder` Y/N; `UPN` present so `forbidden_columns` is tested |
| `contacts.csv` | `ContactId, PupilId, Title, Forename, Surname, Relationship, ContactType, Priority, Email, Mobile, ParentalResponsibility, LivesWith` | ~230 | |
| `siblings.csv` | `PupilId, SiblingPupilId` | ~30 | |
| `staff.csv` | `StaffId, Title, Forename, Surname, Initials, Department, Role, Email, Status` | ~14 | |
| `terms.csv` | `SchoolYear, TermName, StartDate, EndDate, HalfTermStart, HalfTermEnd` | 3 | |
| `year_groups.csv`, `forms.csv` | `NCYear, Name, HeadOfYear StaffId` / `FormCode, NCYear, TutorStaffId` | 4 / 12 | |
| `departments_subjects.csv` | `DepartmentCode, DepartmentName, SubjectCode, SubjectName` | ~25 | |
| `teaching_sets.csv` | `SetId, SetCode, SubjectCode, NCYear, Level, TeacherStaffId, SchoolYear` | ~60 | `Level` in `GCSE`, `A Level` |
| `set_lists.csv` | `SetId, PupilId, StartDate, EndDate` | ~700 | |
| `timetable_periods.csv` | `Week, Day, PeriodCode, StartTime, EndTime` | 2 weeks × 5 days × 6 | two-week timetable |
| `set_timetable.csv` | `SetId, Week, Day, PeriodCode, Room` | ~400 | feeds `sis.section_meeting` |
| `registration.csv` | `PupilId, Date, Session, Code, Minutes Late, Comment` | 120 × 2 × school days | `Session` AM/PM; `Code` from the DfE list, including `N` later re-coded to `I`, and `#` on closure days |
| `rewards_conduct.csv` | `RecordId, PupilId, Date, ModuleType, Category, Points, StaffId, Comment` | ~150 per term | merits and sanctions |
| `gradebook.csv` | `PupilId, SetId, AssessmentName, AssessmentDate, Grade, Scale, Predicted, Term` | ~1,500 per term | `Scale` in `9-1`, `A*-E`, `%`; termly delivery |
| `calendar_events.csv` | `Category, Subcategory, Title, StartDate, EndDate, NCYears` | ~30 | mocks, study leave, INSET |

**Deliberate defects:** a registration `N` code superseded three weeks later by `I` in the correction pack (supersession of attendance rows and the suppression that follows); a pupil whose `LeavingDate` is set but who still appears in `set_lists.csv` (membership outside enrolment → rejected); a DSL who also teaches (one person, two memberships, only one from import); a contact with `ContactType = Emergency` and no `ParentalResponsibility` (not imported); a Windows-1252 file with `é` in a surname declared correctly in the profile, and the same file declared as UTF-8 in a second profile version to show `encoding_undetectable`; GCSE grade `9` for a Year 11 and A-level `A*` for a Year 13 to prove `normalised_pct` is scale-aware; a `UPN` column present (fails `forbidden_columns`); a two-week timetable so the clash check sees week B.

### 8.3 What the fixtures prove

`packages/ingest/test/fixtures.spec.ts` imports each pack in order through the real pipeline against an ephemeral database and asserts `expected.json` exactly: counts per status and code, the people summary, the security section, the rows superseded by the correction, and, after `after_commit`, the `sis.v_current_*` views. `engine-reproduces-seed` (pass 1) then runs on the result. A change in either fixture is a reviewed change to `expected.json`.

---

## 9. Onboarding a new school

From a signed agreement to the first successful nightly sweep. **H** marks a step that needs a human from CAROS; **S** a step the school performs; **A** an automated step. The runbook lives at `docs/runbooks/tenant-onboarding.md` and each step has a checklist item and an owner in the tenant's onboarding record (`core.school.status = 'onboarding'` until step 20).

| # | Step | Who | Output |
|---|---|---|---|
| 1 | Agreement signed, including the data-processing agreement (pass 4) and the **data delivery schedule** (which import kinds, at what cadence, by whom; §6.4) | H + S | signed documents; the delivery schedule becomes `ingest.expected_cadence` |
| 2 | Discovery call with IT, the registrar and the counseling lead: which systems, which exports are possible, who will run them, timetable structure, weekend, calendar, grade scales per programme, attendance codes, safeguarding role title, counselor titles (ACS-IT-QUESTIONS.md §1, pass 1 §8, this pass §14) | H | filled questionnaire, stored with the tenant |
| 3 | Create the tenant: `core.school` (slug, names, regulator, timezone, weekend, `sis_name`, labels, brand, **`data_classification = 'real'`**, `branding_mode`), `core.school_module` flags, `ingest.source_system` rows | H (Terraform-free: a CLI in `tooling/tenant`, audited) | tenant id |
| 4 | Google Workspace SSO: the school's super admin registers the CAROS OAuth client, confirms the domains, and (if Classroom is in scope) authorises domain-wide delegation for the read scopes on a school-created reader account | S, guided by H | `auth` configuration; a test sign-in by one staff member |
| 5 | Grant `school_admin` to the school's named upload person(s) and `caseload_lead` to the counseling lead; nothing else yet | H | memberships |
| 6 | Calendar: academic year, terms, holidays, exam and mock periods, reporting windows entered or imported in the Studio; `sis.school_day` materialised | S (school_admin) with H | calendar rows; a printed school-day calendar the school confirms |
| 7 | **Pseudonymised sample export.** The school runs each planned export once on a small slice with names, emails and dates of birth replaced (a script CAROS provides, run at the school) and uploads it to a `sample` source | S | sample files |
| 8 | Mapping profiles authored in the Studio against the samples, one per import kind; lookups filled (attendance codes, behaviour categories, subject aliases, year-group aliases, programme to scale); expectations set; dry runs pass on the samples | H | profile versions in `draft` |
| 9 | Delivery mechanism set up: manual upload by the school_admin, or a scheduled export to a per-tenant SFTP endpoint CAROS hosts in UAE North (SFTP is chosen because the school's export tools can write to it unattended; each tenant has its own key, chrooted path and a watcher job that creates the import); or a live connector's credentials placed in Key Vault and `verify` run | S + H | working path; `verify` green |
| 10 | **Full historical backfill**, oldest first: enrolment, contacts, staff, subjects, timetable, roster, then grades, attendance, behaviour for at least the previous full academic year where the school has it (this is what builds baselines and what answers question 46) | S uploads, H reviews the previews with the school_admin; approvals by the school | committed imports; identity decisions resolved |
| 11 | Data quality review with the registrar: rejection report, unmapped lookups, conflicts, security section, students with no sections, sections with no teacher | H + S | profile version 2 where needed; re-imports |
| 12 | Identity checks: SSO sign-in by three staff and two students; the person the SSO lands on is the person the import created (email rung); Classroom `userId` versus OIDC `sub` compared for one account (§4.1) | H + S | pass/fail recorded |
| 13 | Counselor memberships and caseload assignments loaded (a `caseload` CSV from the counseling lead, or entered), cover policy set (pass 4) | S with H | `auth.caseload_assignment` |
| 14 | Thresholds and suppression configured with the counselors (ACS-IT-QUESTIONS.md §5) as `config.rule_set_version` v1 for the school; shadow mode on | H with counselors | rule set versions |
| 15 | First manual sweep on the backfilled history (`sweep.run` with trigger `backfill`), reviewed with the counseling lead: what would have been flagged, when | H + counselors | the retrospective validation report (pass 3 defines its form) |
| 16 | Weekly deliveries begin; cadence panel shows on time; each preview approved by the school_admin for the first four weeks, then auto-approval per policy for the kinds the school agrees | S, H watching | four green weeks |
| 17 | Security review items the school's IT asked for (pass 4): RLS suite run against the tenant with a second tenant present, audit export, penetration test evidence | H | evidence pack |
| 18 | Teacher and student rollout: memberships created from the staff and enrolment imports (`sso_jit` for sign-in; no capability grants), the parent magic-link path enabled once guardian links are verified | A + S | first sign-ins |
| 19 | Shadow period ends: counselors compare the engine's queue with their own judgement; thresholds adjusted as a new rule-set version; the demonstration marker rule is checked (`data_classification = 'real'` so the marker is off) | H + counselors | sign-off |
| 20 | **First live nightly sweep**: `core.school.status = 'active'`; the 02:00 run succeeds; the 06:00 watchdog reports; the counselor sees "what changed overnight" at 07:00 | A, H watching | `signal.sweep_run` succeeded; onboarding closed |

Steps that need a CAROS human today: 1, 2, 3, 5, 8, 9 (partly), 10 (review), 11, 12, 13 (partly), 14, 15, 17, 19. The second school should need a human at 1, 2, 8, 11, 14, 15 and 19 only, because 3 to 7, 9, 10, 12, 13, 16, 18 and 20 are the Studio, the CLI and the runbook doing the same thing again. The measure of "cheap to onboard" is the number of profile versions authored before four green weeks; the target is under three per import kind.

---

## 10. Schema deltas to pass 1

Every change this pass needs from the pass 1 DDL, so pass 6 can sequence them and so nobody edits the pass 1 file by hand. Each follows pass 1's conventions (§2.1 there) and is registered in `privacy.table_registry`.

| # | Delta | Where | Why |
|---|---|---|---|
| D1 | `ingest.import.status` CHECK becomes `received, parsed, staged, validated, previewed, approved, committed, superseded, rolled_back, failed, discarded` | `ingest.import` | §2.1 |
| D2 | New tables `ingest.import_batch`, `ingest.staged_row`, `ingest.identity_candidate`, `ingest.identity_merge`, `ingest.external_ref`, `ingest.connector_run`, `ingest.source_cursor`, `ingest.precedence`, `ingest.conflict`, `ingest.expected_cadence` | `ingest` | §2.3 |
| D3 | Columns on `ingest.import`: `batch_id`, `connector_run_id`, `as_of`, `profile_schema_version`, `row_count`, `header_columns`, `approved_by`, `approved_at` | `ingest.import` | §2.3 |
| D4 | `sis.attendance_event` gains `session_key text`, `source_status_raw text`; `sis.grade` gains `missing boolean NOT NULL DEFAULT false`; `sis.enrolment` gains `ended_reason text CHECK (ended_reason IN ('explicit','snapshot','merge'))` | `sis` | §5.2, §5.1, §4.4 |
| D5 | New table `sis.section_meeting (school_id, section_id, day_of_cycle smallint, timetable_period_id, room text)` with the composite foreign keys; `sis.timetable_period` gains `cycle_days smallint` on the tenant (`core.school.timetable_cycle_days`) | `sis`, `core.school` | §5.4 |
| D6 | New table `core.person_name_history` (§2.3); new generated column `core.person.match_key text GENERATED ALWAYS AS (…) STORED` holding the normalised `family_name ‖ given_name ‖ date_of_birth` (the normalisation function `core.match_normalise(text)` is IMMUTABLE SQL, §4.5), with an index | `core` | §4.2, §4.3 |
| D7 | `config.vocabulary.vocabulary` CHECK gains `subject_canonical`, `year_group_alias`, `attendance_status`, `enrolment_status`, `relationship` | `config` | §5 |
| D8 | New table `config.grade_scale` mirroring `ref.grade_scale` with `school_id NOT NULL` for school-declared scales (`school:<slug>:<key>`), consulted before `ref.grade_scale` by the normaliser | `config` | §5.1 |
| D9 | `audit.action` gains `IMPORT_RECEIVED`, `IMPORT_APPROVED`, `IMPORT_DISCARDED`, `IDENTITY_DECIDED`, `IDENTITY_MERGED`, `IDENTITY_MERGE_REVERSED`, `CONNECTOR_VERIFIED`, `CREDENTIAL_ROTATED`, `PROFILE_ACTIVATED`, `PROFILE_RETIRED`, and an access action `PREVIEW_ACCESS`; `events.name` gains `import.received`, `import.rolled_back`, `import.late` (cadence missed), `connector.run` | `audit`, `events` | §2 |
| D10 | `core.school_module.config` documented keys: `university.list_of_record ∈ {caros, maia}`, `cas.record_system ∈ {caros, managebac_readonly_import, off}`, `extended_essay.record_system` likewise, `ingest.mass_change_threshold` (default 40) | `core.school_module` | §7.9 |
| D11 | `uni.document_request` gains `external_ref text` (Maia document id); `uni.offer` gains `external_ref text` | `uni` | §7.7 |
| D12 | Views `sis.v_current_grade`, `sis.v_current_attendance`, `sis.v_current_behaviour` selecting the highest-precedence active row per natural key (`ingest.precedence`), used by the engine's input DTO and every screen | `sis` | §7.9 |
| D13 | `doc.file.kind` gains `connector_snapshot` (JSON Lines from a live pull) and `sample_export` (pseudonymised onboarding sample), both in retention class `raw_import` | `doc` | §2.2, §9 |
| D14 | `privacy.retention_class` gains `staged_row` (14 days after `failed`/`discarded`, 90 after `committed`, `delete`) | `privacy` | §2.2 |
| D15 | `auth.role_permission`: the two existing `ingest` rows stand; add `('counselor','config','configure','school','school_admin')` for profiles and vocabularies, distinct from `caseload_lead`'s rule-set configuration | `auth` | §2.11 |
| D16 | Registry entries and RLS for every table above; the "no second copies" list (pass 1 DR-6) gains `attendance_pct`, `late_count`, `hours_total` | `privacy`, tests | pass 1 conventions |

---

## 11. Challenges

Each names the decision, states the alternative, what it costs and buys, and then plans on the decision unless the text says otherwise.

**11.1 "Termly CSV first" is the right transport and the wrong cadence.** *Decision challenged: data ingest.* A termly file cannot feed the morning ritual for three of the six domains (§6.2). The alternative is not "live integration first" (which section 3 rightly defers); it is the same CSV path at **weekly** cadence, which costs the school one person fifteen minutes on a Monday (six saved queries) or one scheduled export, and buys the product's differentiator on real data. Recommendation: make the weekly pack a condition of the pilot agreement (§6.4, question 70) and write the retrospective mode into the agreement as the fallback so nobody discovers the gap in week 12. Planned on: the pipeline accepts termly, and §6.3 defines what the engine does under each cadence.

**11.2 "Read from the incumbents so nobody maintains anything twice" cannot be fully honoured through APIs.** *Decision challenged: incumbent systems.* ManageBac's public API exposes no CAS or Extended Essay data, and Maia has no public API at all (§7.4, §7.7). The alternatives are a workflow decision (ManageBac or CAROS as the record for CAS and EE, one-time import in the second case) and a counselor-run CSV cadence for Maia. Both cost a conversation with the coordinator and the counselors and buy a truthful integration story; the alternative of building screen-scrapers or asking students to re-enter is either brittle or exactly the double maintenance the decision forbids. Planned on the decision's *intent*: read where reading is possible, choose a single record system where it is not, and never write to either.

**11.3 The residency decision has a second edge: the incumbents are abroad.** *Decision touched: data residency.* ACS's IB records already sit in AWS Canada, the US or China depending on ManageBac's assignment (§7.4), Veracross's hosting was not verified, and Maia's is unstated (§7.7). CAROS reading from them into UAE North does not move data out of the country, but the data-processing agreement must describe each source, and any export a school runs through a third-party tool (Edlink, Wonde) would; DR-16 rejects those. Nothing to change; pass 4 should name the sources in the DPA.

**11.4 Google identity for students rests on an unverified equivalence.** *Decision touched: identity.* The plan assumes the Directory id Classroom returns and the OIDC `sub` SSO returns are the same number (§4.1). Google documents each identifier's stability but not their equality on the pages retrieved. The alternative is to key Classroom users by email only, which Google itself warns is not stable. Planned on: verify at onboarding step 12; if they differ, the adapter stores both as separate external identities and links them through the email rung once, under a human decision.

**11.5 The frozen demo says something the backend will never do.** *Decision touched: frontend (index.html frozen).* The `arch` page's "gradebook webhook fired" and "never in a nightly batch" describe a system that does not exist and that no vendor in scope supports. The demo stays frozen; the demo *script* should not read those lines aloud, and the Next.js rebuild of that page describes the pull pipeline and the sweep. No plan change.

**11.6 "Each school's differences are data" needs a discipline, not just a schema.** *Decision touched: data ingest.* The one place code can grow per school is the transform set (§3.3). The alternative, an expression language in profiles, would let a profile hang a worker, leak data through a clever expression, and turn profiles into code nobody reviews. Planned on the closed set, with the rule that a new transform is a reviewed change with tests and a schema version bump, and a test that fails the build if any adapter or profile references a tenant slug.

**11.7 Auto-approval and permissions.** *Decision touched: tenancy and roles.* A live connector that commits rosters unattended changes what teachers can see without a human looking. The alternative of approving every connector batch by hand is what schools stop doing after a month. Planned on the middle: auto-approve facts (grades, attendance, behaviour), hold anything that changes people or access when its security section is non-empty beyond the school's tolerance (§7.2, §5.4).

**11.8 The normalised percentage is a convention and must never look like a mark.** *Decision touched: the trust spine.* No board publishes a percentage equivalent for an ordinal grade. The alternative is to have no cross-scale value at all, which would leave screens unable to sort mixed cohorts. Planned on: the convention exists, is labelled unsourced in `ref.source`, is never printed as a mark, and the engine works within one scale per series (§5.1, for pass 3).

---

## 12. Open decisions

| # | Decision | Options | Recommendation | Who decides |
|---|---|---|---|---|
| 1 | Delivery cadence ACS commits to for grades, attendance, behaviour | (a) weekly pack; (b) read-only Data API nightly; (c) fortnightly; (d) termly, retrospective mode | (a) for the pilot, (b) when ACS is comfortable; never sign for (d) without naming the mode | ACS IT and registrar, Davide |
| 2 | Delivery mechanism | (a) manual upload in the Studio; (b) per-tenant SFTP in UAE North with a watcher; (c) connector | (b) from week five; (a) for the first four weeks so the school sees every preview | Davide, ACS IT |
| 3 | Auto-approve defaults for connectors and SFTP drops | facts only; facts and rosters when the security section is empty; everything | facts and empty-security-section rosters | Davide, ACS school_admin |
| 4 | Two guardians sharing one email address | (a) one person, both contacts attached; (b) reject the second; (c) partial uniqueness and a two-account login | (a), as §4.7 | pass 4, ACS |
| 5 | CAS and Extended Essay record system at ACS | (1) ManageBac stays, modules off; (2) CAROS with a one-time import | ask Mr Diaz; the prototype was built for (2) | ACS coordinator, counselors |
| 6 | University list of record | Maia mirrored read-only; CAROS | Maia mirrored while ACS uses Maia | ACS counselors |
| 7 | Google Classroom as a coursework and engagement source | on with read scopes and a reader account; off | on, if pass 4 and ACS accept the disclosure | pass 4, ACS |
| 8 | Ordinal-scale normalisation convention | midpoint bands labelled unsourced; none | midpoint bands, never displayed | pass 3, Davide |
| 9 | Retention of staged rows and raw files | 90 days (pass 1); 30 days | 90 for raw files (disputes), 30 for staged rows | pass 4, counsel |
| 10 | Who may author and activate profiles after onboarding | CAROS only; school_admin too | school_admin may edit and dry-run; activation of a new *import kind* needs CAROS review for the first year | Davide |
| 11 | Who may roll back | school_admin; CAROS support only | school_admin, with the 20-character reason and the blocking-imports check | pass 4 |
| 12 | Whether a commit may trigger daytime evaluation | never; for flagged students; always | per school policy, default off during the pilot's shadow period | pass 3, ACS counselors |
| 13 | XLSX at pilot | accept, read as text; CSV only | accept | Davide |
| 14 | Grace period before a withdrawn person's status becomes `left` | 0, 14, 30 days | 14 | Davide |
| 15 | OneRoster profile family in the thin slice | yes; after the pilot | after the pilot; the CSV profiles come first | pass 6 |
| 16 | Veracross path if and when a connector is built | Data API v3; API Plus (OneRoster 1.1) | Data API (attendance and behaviour are not in OneRoster); API Plus only if ACS already licenses it and only for rosters and grades | Davide, ACS |
| 17 | SFTP endpoint implementation | Azure Blob SFTP feature (if offered in UAE North; unverified); a small SFTP container in the Container Apps environment | verify Blob SFTP availability in UAE North first; otherwise the container | Davide, pass 6 |

---

## 13. For other passes

**Pass 3 (engine).** The backfill evaluation for weekly and termly deliveries (§6.3): evaluating each week as of that week, opening cases only from the final state, and recording would-have-fired signals for shadow comparison. The fortnightly persistence question. The retrospective tier cap per domain and its `engine.tiering` parameter. What happens to a signal whose underlying fact was superseded by a corrected import (annotate, re-evaluate, or close). Series in ordinal scales are analysed as ordinal, never through `normalised_pct`. `sis.grade.missing` feeds a submission series, not the attainment series. Days with `counts_as = 'excluded'` leave the attendance denominator. First-period punctuality exists only where `timetable_period_id` or `session_key = 'AM'` is present; otherwise the dimension must say "daily register only". `as_of` per domain is an input, and the sweep prints it. `absence_reason.attributes.suppresses` is the vocabulary side of `engine.suppression`. Cold start reads `sis.student.joined_on` and `enrolment.status = 'transferred_in'`. Reads go through `sis.v_current_*` so conflicts resolve consistently.

**Pass 4 (security, privacy, compliance).** The Mapping Studio's audit action for previews (`PREVIEW_ACCESS`) and which reads of staged rows count as access to a student's record. The support-grant path our onboarding engineer uses, and the pseudonymised-sample script the school runs (step 7). The shared-guardian-email rule (open decision 4) and what `consent_status = 'unknown'` permits. Consent and disclosure for Google Classroom reading (open decision 7) and the reader account's role. The tenant-wide nature of a ManageBac read-only token and the Veracross OAuth application: storage, rotation, revocation on offboarding. Naming Veracross, ManageBac, Maia and Google as data sources in the DPA, with their hosting locations (§11.3). The SFTP endpoint's hardening and key management. `forbidden_columns` as a minimisation control the school can audit. Retention of staged rows and raw files, and the interaction between an **immutable** raw-import container and an erasure request (the raw file cannot be edited; either the retention is short enough that erasure waits for expiry, or raw files are stored per tenant under a key that can be destroyed). Rollback authority. Whether emergency contacts should be imported after all for the escalation path (this pass says no). IP allow-listing for iSAMS keys and the egress IP of the worker.

**Pass 5 (AI).** Evidence text must name the source system and the as-of date ("Gradebook, Veracross, as of 14 Nov"). Unmapped subjects (`canonical_key IS NULL`) cannot be matched to offer conditions and the co-pilot must say so rather than guess. The letter engine's "predicted versus achieved" reads `grade.kind` `predicted` and `final`, never `working`. The pseudonymisation map (pass 1) should reuse `core.person.id`, not any external id.

**Pass 6 (build sequence).** The Studio's Sources, Profiles, Imports and Identity screens belong in the thin slice, because the seed and the first real data both pass through them. The fixture packs (§8) are week-one tests. Migration deltas D1 to D16 in the order: D2 tables and D3 columns, D1 status list, D4 and D5, D6, D7 and D8, D9, D10 and D11, D12 views, D13 and D14, D15, D16 tests. The SFTP endpoint in Terraform (open decision 17). Connector adapters (Veracross, ManageBac, Classroom) after the pilot's first four green weeks, in the order ACS's answers to questions 77 and 81 dictate. The "four green weeks" gate before auto-approval. The `expected_cadence` panel on the caseload sheet, which is the frontend's only new element from this pass.

---

## 14. Questions for ACS

In the style of `ACS-IT-QUESTIONS.md`, numbered after pass 1's last question (69). Each says who at the school is most likely to answer.

**Data delivery · IT, registrar**

70. Can the school run a small set of saved Veracross queries **every week** (assignment grades, attendance, behaviour for the last three weeks, plus a roster snapshot), and who would own that? If weekly is impossible, is fortnightly? CAROS's overnight signals for grades, attendance and behaviour only work as often as the data arrives; with a termly file those three domains are reviewed at term end rather than overnight, and we would write the pilot on that basis.
71. In Veracross at ACS, is attendance taken per lesson (class attendance) as well as per day (master attendance)? Is the reason for an absence a coded field or free text in the notes? Is early dismissal recorded? Is lateness recorded in minutes?
72. Can we have the school's current attendance policy text and the code list used for ADEK's eSIS uploads, so our absence-reason table matches the school's rather than a press summary?
73. Can Axiom exports be scheduled to run unattended and delivered to a secure file drop we host in the UAE, or will a person export and upload each week? Who is the backup person during holidays?
74. Is the `student_id` field in ManageBac set to the Veracross student number, and do students use the same school Google address in Veracross, ManageBac and Google Classroom?
75. Where are IB working grades and predicted grades recorded and reported from: Veracross, ManageBac, or both? At which points in the year are predictions issued (to universities, to the IB)?
76. Which ManageBac region hosts ACS (Canada, US or China), for the data-processing agreement?
77. Where do teachers keep their gradebooks for each programme: the Veracross gradebook, ManageBac tasks, or Google Classroom? Do assignments carry due dates and a "missing" flag there?
78. Would ACS create a **read-only** ManageBac API token for CAROS, and enable the attendance endpoints in the public API settings if they are not already on? Who administers ManageBac?
79. Can we have Maia Learning's Educational User Privacy Policy and confirmation of where Maia hosts ACS's data, for the data-processing agreement?
80. Can a counselor export the applications and college lists from Maia as a CSV each week, and has Maia ever offered ACS a scheduled export or an API? Would ACS ask them?
81. Does anyone at ACS hold the Veracross `OAuth_App_Admin` security role, and would ACS create an OAuth application for CAROS limited to **list and read** scopes if we move from files to the API? Does ACS license Veracross API Plus for Academics?
82. Are Veracross Person IDs stable for a student's whole time at the school, and are IDs ever reused? If a student leaves and returns, do they get the same record?
83. How far back can the school export assignment grades, attendance and behaviour with dates? Two full academic years of history is what lets CAROS build a personal baseline for Grades 10 to 12 on day one.

**Google Classroom · IT**

84. If the school agrees to a Google Classroom read (question 14), would IT create a dedicated reader account and authorise domain-wide delegation for read-only Classroom scopes on it? Which High School courses use Classroom for assignments today?

**Safeguarding and data protection · CPO, data protection lead**

85. An import preview shows the registrar names, grades and attendance for every student in the file. Is the registrar (or whoever uploads) an appropriate person to see that, and should the counseling lead approve previews instead?

---

## Sources

All retrieved 2026-09-23. Pages marked *JS* rendered only client-side and were read through their search-result excerpts; pages marked *gated* required a login and were not read; both are labelled where cited.

**Veracross**
- Veracross API documentation home: https://api-docs.veracross.com/ (JS)
- Access Tokens: https://api-docs.veracross.com/docs/docs/097f6c769cafb-access-tokens (JS; scopes `students:list`, `students:read`, one-hour tokens, pre-approved scopes, from excerpts)
- Authorization API: https://api-docs.veracross.com/docs/docs/8fb052b29c8da-authorization-api (JS)
- Read Classes: https://api-docs.veracross.com/docs/docs/dbdb475f46cea-read-classes; Read Relationships: https://api-docs.veracross.com/docs/docs/56ec0b06079ff-read-relationships; List Events: https://api-docs.veracross.com/docs/docs/1e238d1b394d6-list-events; List Academics: Student Alerts: https://api-docs.veracross.com/docs/docs/d925f0ea0fad1-list-academics-student-alerts (JS; existence and filter names from excerpts)
- Using the OneRoster API (API Plus for Academics): https://api-docs.veracross.com/docs/api-plus-for-academics/bd08d5lpygdl1-using-the-one-roster-api (JS)
- API Plus for Academics: Overview: https://community.veracross.com/s/article/API-Plus-for-Academics-Overview; Self Start Guide: https://community.veracross.com/s/article/API-Plus-for-Academics-Configuration (JS)
- Creating an OAuth Application: School Workflow: https://community.veracross.com/s/article/Creating-an-OAuth-Application-School-Workflow; OAuth Applications and Veracross Overview: https://community.veracross.com/s/article/OAuth-Applications-and-Veracross-Overview (JS)
- Exporting Data to Excel or CSV File: https://community.veracross.com/s/article/Exporting-Data-to-Excel-or-CSV-File; Guide: Axiom: https://community.veracross.com/s/article/Guide-Axiom; Tracking Daily or Class Attendance: https://community.veracross.com/s/article/Tracking-Daily-or-Class-Attendance; Attendance Overview: https://community.veracross.com/s/article/Attendance-Overview (JS)
- 1EdTech certification listing: https://site.imsglobal.org/certifications/veracross
- Edlink, What Data Can the Veracross API Access: https://ed.link/community/what-data-can-the-veracross-api-access/
- Edlink, Veracross Integration Challenges: https://ed.link/community/veracross-integration-challenges/ (source of the 300 requests per 3 minutes figure)
- Edlink, Connecting Veracross: https://ed.link/docs/providers/veracross/connecting (OAuth_App_Admin, scope names)
- Orah, How to enable and use the Veracross integration: https://success.orah.com/en/articles/5597576-how-to-enable-and-use-the-veracross-integration
- Riverdale Country School, Enter Student Attendance (a school's Veracross guide): https://howdoi.riverdale.edu/wiki/Enter_Student_Attendance

**ManageBac and Faria**
- API v2.2 authentication: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/authentication.md
- Students: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/students.md; Parents: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/parents.md; Classes: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/classes; Memberships: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/memberships.md; Year groups: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/year-groups.md; Attendance: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/attendance.md; Behavior notes: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/behavior-notes.md; Coursework: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/coursework.md; Academics: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/academics.md; Extended APIs: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/v2p2/extended-apis.md; Overview: https://guide.fariaedu.com/integrations-portal/managebac/public-rest-apis/overview; documentation index: https://guide.fariaedu.com/llms.txt
- Rate limitations and throttling: https://guide.fariaedu.com/integrations-portal/faria-suite/integrating-with-faria-suite-apis/rate-limitations-and-throttling.md; Pagination, delta updates and filtering: https://guide.fariaedu.com/integrations-portal/faria-suite/integrating-with-faria-suite-apis/pagination-delta-filters.md; Security: https://guide.fariaedu.com/integrations-portal/faria-suite/integrating-with-faria-suite-apis/security.md
- OneRoster 1.2 CSV custom specification: https://guide.fariaedu.com/managebac-oneroster-custom-specification; classes.csv: https://guide.fariaedu.com/managebac-oneroster-custom-specification/csv_files/classes; CSV bindings: https://guide.fariaedu.com/integrations-portal/managebac/oneroster-1.2/csv-bindings.md; REST bindings (roadmap): https://guide.fariaedu.com/integrations-portal/managebac/oneroster-1.2/rest-api-bindings.md
- ManageBac Public API Developer Portal and v2 API Authentication help articles: https://schoolstech.faria.org/hc/en-us/articles/18442798523417-ManageBac-Public-API-Developer-Portal and https://schoolstech.faria.org/hc/en-us/articles/4830529031705-ManageBac-v2-API-Authentication (gated)
- Kognity, How to get the ManageBac API token: https://intercom.help/kognity/en/articles/5316174-how-to-get-the-managebac-api-token-to-set-up-classes-in-kognity (API Manager, read-only option)
- ManageBac FAQs (hosting regions): https://help.managebac.com/hc/en-us/articles/360031510571-ManageBac-FAQs
- Faria, Connected by Design: http://www.faria.org/insights/connected-by-design/
- IB DP Coordinator's Guide, April (predicted grades on IBIS): https://guide.fariaedu.com/monthly-ib-diploma-programme-coordinator-guide/april

**Maia Learning**
- Applying to College: https://www.maialearning.com/what-we-do/applying-to-college
- Privacy policy (website; excludes educational users): https://www.maialearning.com/privacy-policy
- Edlink, MaiaLearning announcement: https://ed.link/community/new-client-announcement-maialearning/
- Slate Knowledge Base, MaiaLearning Integration: https://knowledge.technolutions.net/docs/maialearning-integration
- EIN Presswire, MaiaLearning Partners with The Common App: https://www.einpresswire.com/article/463197160/maialearning-partners-with-the-common-app
- College Kickstart, Exporting Reports from Cialfo, Maia Learning, Naviance or Scoir: https://support.collegekickstart.com/hc/en-us/articles/360039299451-Exporting-Reports-from-CIALFO-MAIA-LEARNING-NAVIANCE-or-SCOIR-for-use-in-College-Kickstart (returned 403; excerpt only)

**Google**
- Classroom API reference: https://developers.google.com/classroom/reference/rest; StudentSubmission: https://developers.google.com/classroom/reference/rest/v1/courses.courseWork.studentSubmissions; studentSubmissions.list: https://developers.google.com/classroom/reference/rest/v1/courses.courseWork.studentSubmissions/list; courses.students: https://developers.google.com/classroom/reference/rest/v1/courses.students and list: https://developers.google.com/classroom/reference/rest/v1/courses.students/list; UserProfile: https://developers.google.com/classroom/reference/rest/v1/userProfiles
- Classroom scopes: https://developers.google.com/classroom/guides/auth; usage limits: https://developers.google.com/classroom/limits; push notifications: https://developers.google.com/classroom/guides/push-notifications; manage users: https://developers.google.com/workspace/classroom/guides/manage-users
- Service accounts and domain-wide delegation: https://developers.google.com/identity/protocols/oauth2/service-account
- OpenID Connect (`sub` stability): https://developers.google.com/identity/openid-connect/openid-connect

**iSAMS**
- Developer portal (gated): https://developer.isams.com/
- REST API example app, Program.cs (token endpoint, scopes, endpoints): https://raw.githubusercontent.com/iSAMS/REST-API-Example-App/master/VS2017/iSAMS-RestApi/Program.cs; Batch API example app: https://github.com/iSAMS/Batch-API-Example-App
- Wonde, iSAMS Batch API Integration Guide (2021): https://www.wonde.com/wp-content/uploads/iSAMS-Batch-API-Integration-Guide-1.pdf and (December 2021 edition): https://wp.wonde.com/wp-content/uploads/2022/02/iSAMS-integration-guide.pdf (dataset lists)
- Orah, How to enable and use the iSAMS integration: https://success.orah.com/en/articles/5587407-how-to-enable-and-use-the-isams-integration
- Meet the Teacher, iSAMS: How to set up integration: https://support.meettheteacher.com/article/978-isams-how-to-set-up-integration
- Zeidman Development, Configure iSAMS API Settings for Importacular: https://www.zeidman.info/configure-isams-api-settings-for-importacular/

**Standards, regulators, boards**
- 1EdTech OneRoster 1.2.1 CSV Binding: https://www.imsglobal.org/spec/oneroster/v1p2/bind/csv
- RFC 4180, Common Format and MIME Type for CSV Files: https://www.rfc-editor.org/rfc/rfc4180
- DfE, Working together to improve school attendance (August 2024; register codes and statistical classes): https://assets.publishing.service.gov.uk/media/66bf300da44f1c4c23e5bd1b/Working_together_to_improve_school_attendance_-_August_2024.pdf
- ADEK attendance policy, press reports (September 2025): The National: https://www.thenationalnews.com/news/uae/2025/09/22/abu-dhabi-updates-rules-on-pupil-absences-for-private-schools/; Khaleej Times: https://www.khaleejtimes.com/uae/education/school-attendance-rules-abu-dhabi
- IB, DP passing criteria: https://ibo.org/about-the-ib/what-it-means-to-be-an-ib-student/recognizing-student-achievement/about-assessment/dp-passing-criteria/ and Understanding DP assessment: https://ibo.org/programmes/diploma-programme/assessment-and-exams/understanding-ib-assessment/ (both returned 403); secondary: https://www.structural-learning.com/post/ib-scoring-and-grades-explained, https://www.revisiondojo.com/blog/how-is-the-ib-scored
- College Board, About AP Scores: https://apstudents.collegeboard.org/about-ap-scores; 2026 release timing (secondary): https://scholarly.so/blog/when-do-ap-scores-come-out-2026

**Middleware residency**
- Edlink privacy policy: https://ed.link/docs/legal/privacy
- Wonde UK security FAQ: https://www.wonde.com/about/security/faqs/uk/

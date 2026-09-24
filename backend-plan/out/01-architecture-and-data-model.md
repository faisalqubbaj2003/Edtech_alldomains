# CAROS backend · Pass 1 · Architecture and data model

Written 2026-09-22 against `index.html` at commit `fb28217` (10,048 lines), `backend-plan/CONTEXT.md`, `PRODUCT.md`, and the prototype's own code wherever the two disagreed. Every cloud, pricing and tooling claim below was checked against a vendor page on 2026-09-22; the page is cited where the claim is made and listed again under Sources. Claims that could not be checked are labelled as assumptions.

**Revised 2026-09-24 (pass 8, session 1)** to apply Davide's decisions on the pass 7 review (`out/07-review.md`). §0.3 lists what changed; `out/08-changelog.md` records every change against the finding that caused it. Where the text below and the pass 7 review disagree, this revision is the one to build from.

## 0. Read this first

### 0.1 Departures from section 3 of CONTEXT.md

**None.** Every decision in section 3 is planned on. Three of them are challenged in §5 (Challenges), and one of them, UAE data residency, now carries a risk that did not exist when the decision was taken: the AWS UAE region was physically damaged in March 2026 and one of its availability zones has been declared unrecoverable, with customer data hosted only there lost for good (§1, DR-1). The plan still keeps student data at rest inside the UAE. It does so on Azure UAE North (Dubai) with in-country redundancy in Azure UAE Central (Abu Dhabi), and it asks Davide, ACS and counsel to take an explicit position on whether an encrypted out-of-country cold copy is permitted, because "residency" and "durability" now pull against each other in a way the section 3 table did not anticipate. That is a question, not a departure. The pass 8 revision adds that any such copy needs key material held outside the UAE to be restorable at all, and ADEK's explicit consent under its Digital Policy 7.1.3.a before it exists (DR-9, §5.1).

Two additions the pass 8 revision makes are declared here so that no later pass mistakes them for silent changes:

1. **Two staff roles join the five** (F16, F10). `school_admin` becomes its own role with no caseload path, and a `staff` role with no data access of its own exists only to carry capabilities (`safeguarding_lead`, `safeguarding_oversight`) for a Principal or CPO who is neither a counselor nor a teacher. Section 3 says "more roles later if needed"; these are rows in `auth.role`, not a departure. The five product roles and their surfaces are unchanged.
2. **Outbound email follows Davide's 2026-09-24 decisions C2 and C3**: content-free transactional email to parents, and a declared set of reference-only safety emails to staff, with everything else in-app. The full inventory lives in pass 4 §5.8; §5.3 below is rewritten to match. CONTEXT §3's "Outbound notifications" row has not yet been updated to say so (handoff in `08-changelog.md`).

### 0.2 Where the code and CONTEXT.md disagree

The code wins in each case; the schema and state machines follow it.

| Topic | CONTEXT.md says | `index.html` does | Consequence |
|---|---|---|---|
| Selection statuses (§7) | "not started, submitted, signed, returned, approved" | `SELREC.status ∈ {none, draft, submitted, signed, changes, approved}` (`index.html:4523` and the handlers at `:9200–9295`) | `draft` exists and is the working state; `changes` is renamed `changes_requested`; `none` is the absence of a row |
| Case stages (§7) | `detect | explain | triage | act | follow | measure | learn` | the case file lists those seven (`vCase`, `:2326`) but the data carries `stage:"monitor"` on six cases, which the pipeline never displays | The backend has no `monitor` stage: a monitor-tier case sits at `triage` with an auto-review date (DR-7) |
| Pathway approval (§7, PRODUCT.md) | counselor "approves, amends, or sends back with reasons" | `data-approve-path` and `data-decline-path` only; no amendment, no reason captured (`:9647–9655`) | The schema requires reasons on send-back and amendment, because pass 5 regenerates candidates under them |
| Dimension statuses (§7) | "ten derived per-student dimension statuses… computed at render time" | punctuality and engagement are hard-wired to student ids (`dimPunctuality`: `c.id==="s1"?3:c.id==="s6"?1:0`; `dimEngagement`: `c.id==="s2"`) and behaviour is a constant | Those three are not specifications of a rule; pass 3 defines them from the attendance and engagement series |
| Audit on access (§9) | "`FILE_ACCESS` (seeded only)" | confirmed: no handler writes it | The audit table records access; the domain layer's file-open function writes `FILE_ACCESS` in the same transaction as the read |
| Teacher flag routing (§7) | `routed` "what happened to it" | written only for the two seeded flags; a new flag gets `routed:""` and `status:"new"` and nothing ever updates it | `routed_key`, `routed_at`, `routed_by_person_id` are set by the counselor's attach or dismiss (C13); the teacher sees only the routed label, which never reveals a case (F58) |
| CAS `outcomes` (§7) | "seven learning outcomes" | `CASREC.outcomes` is a count, not which outcomes | `ib.cas_entry.outcomes smallint[]` records which of the seven each entry evidences |
| Parent weekend (PRODUCT.md, "UAE school week (Sun–Thu)") | not mentioned | `buildNovemberCalendar` marks Friday and Saturday as the weekend (`:3762`) | The school's weekend is a tenant field (`core.school.weekend_days`), and it is a question for ACS: UAE public and most private schools moved to a Monday-to-Friday week in 2022 (assumption from general knowledge, not verified here) |
| Mentor `path` string (§7) | | `PARENT_MENTOR.path:"${SCHOOL.short} → LSE…"` is a plain string, not a template literal, so the school name never interpolates (`:3780`) | Cosmetic; noted so nobody ports the bug |
| EE `EE_WAIT_DAYS` (§7) | 7 | 7 (`:5066`) | Agrees; stored per round as `ib.ee_round.wait_days` |
| Escalation reason (§4 invariant 5) | "requires a reason" | minimum 12 characters (`reason.length<12` at `:9505`) | `CHECK (char_length(reason) >= 12)`; whether 12 is right is an open decision (pass 4 replaced it with a structured form, D46) |

### 0.3 What the pass 8 revision changed (2026-09-24)

Finding numbers are pass 7's (`07-review.md`); the changelog in `08-changelog.md` gives every edit. The larger changes, by where they land:

- **Database roles and the policy function** (F01, §12.2, F36, F44, F75). One login role per deployable (`caros_web`, `caros_worker`, `caros_support`, `caros_migrator`, `caros_jobs`), all `NOINHERIT`; the tier is evaluated in the policy expression and passed to `auth.allowed()`; a separate teacher tier; the AI tier `caros_t_ai` listed with the others. DR-4, §2.2, §2.4, §2.22.
- **Pass 4's matrix, made storable** (F02, F15, F16, F33, F58, F59). New scopes (`esc`, `addressee`, `lead_cover`, `own_pairing`, `year_group`, `tutor_group`), scope and row kind in the unique key, a per-row data class, derived subjects for child tables, projection views for the qualifiers the matrix prints, policies that accept a table's verb, and `notify.enqueue()`. §2.4 and the new §2.4a, which maps every qualifier in pass 4 §3.6 to its mechanism.
- **Escalation** (F07, F10). The engine may raise but never lower or auto-close a case with an open escalation; one open escalation per case plus an idempotency key per submission; information added to an open referral; a teacher's safeguarding referral; merge restricted to one student. DR-7.1, §2.9.
- **Gates that were only a non-null id** (F17, F58). The selection approval trigger, `review_meeting_version`, definer transition functions and column-level update grants. DR-7.3, §2.10, §2.22.
- **Tenant status, purpose and marker** (F36, F42, F67). One status model (`onboarding`, `shadow`, `live`, `suspended`, `offboarding`, `offboarded`), an immutable `purpose`, and a letterhead that cannot be separated from the marker. §2.3, DR-9.
- **Second school and school-shaped data** (F31, F33, F65). `ref.regulator_profile`, pastoral assignments and tutor groups, programme families and destination systems as vocabularies, per-school portal rules and retention overrides. DR-8, §2.5, §2.7, §2.21.
- **University artefacts** (F32). Sectioned statements, UCAS-format references, a centre statement, a predicted-grade snapshot and per-school internal deadlines. §2.11.
- **Shadow runs the live engine** (F24). Shadow cases are `signal.case` rows with `shadow = true`, readable only as `signal_shadow`. §2.9.
- **Smaller corrections**: the AWS facts (F73), the cost table (F71), the migrator and `CONCURRENTLY` (F40), the sweep job names (§12.1), DDL loose ends (§12.3), reporting aggregates under RLS (F34), vocabulary history (F48), the headline rephrase removed (F52), the seed's real-person name and unsourced figures (F29, F30), the Extended Essay guide (F62), XP as its own class (F77), and the lighter process for one builder (C8).

## 1. Decision records

### DR-1 · Cloud provider and UAE region

**Context.** Section 3 requires student data at rest in a UAE data centre from day one. Four providers operate in the UAE. The facts, checked 2026-09-22:

- **AWS Middle East (UAE), `me-central-1`**, opened 29 August 2022 with three availability zones ([AWS launch post](https://aws.amazon.com/blogs/aws/now-open-aws-region-in-the-united-arab-emirates-uae/)). AWS's own Health Dashboard feed states that the region "has suffered damage as a result of the conflict in the Middle East and is currently unable to reliably support customer applications", that AWS "strongly recommend[s] customers migrate all accessible resources to other Regions", that "relevant" billing operations are suspended, and, in a 15 September 2026 update, that AWS is "unable to restore access to the resources and data hosted exclusively in the mec1-az2 Availability Zone" ([AWS status feed](https://status.aws.amazon.com/rss/all.rss), items dated 30 Apr 2026 and 15 Sep 2026; the disruption began 1 March 2026, the date of the feed's first item and of TechPolicy.Press's account). For the UAE region the declared loss is limited to data held only in that one zone. The Bahrain region `me-south-1` is worse: AWS declared data held anywhere in that region unrecoverable, which makes Bahrain, not the UAE, the country-level precedent for the cold-copy question in §5.1. Every service the plan would have used is in the AWS catalogue for the region (RDS PostgreSQL 17 and 18, Aurora, S3, EventBridge Scheduler, SES API, Secrets Manager, KMS, CloudWatch, ECS on Fargate, Lambda, SQS, Step Functions, ECR, WAF; App Runner is not), and the on-demand prices were retrieved (RDS `db.m7g.large` Multi-AZ $0.410/h, Fargate $0.0526 per vCPU-hour, S3 $0.025/GB-month, SES $0.10 per 1,000) from the [AWS Price List API](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonRDS/current/me-central-1/index.json). None of it can be relied on for provisioning today, and no restoration date is published.
- **Microsoft Azure UAE North (Dubai, availability zones) and UAE Central (Abu Dhabi, no zones, access-restricted)** form a region pair ([Azure paired regions](https://learn.microsoft.com/en-us/azure/reliability/regions-paired); [regions list](https://learn.microsoft.com/en-us/azure/reliability/regions-list)). Microsoft's Learn regions list and its datacenter map give the cities; the map's UAE North entry says "Stored at rest in the United Arab Emirates" ([regions.json](https://datacenters.microsoft.com/globe/data/geo/regions.json)). No Microsoft incident record for either region was found for 2026; a Microsoft Q&A thread on 2 April 2026 asking exactly this question was answered "there are no current outages or service impacts in UAE North or UAE Central" ([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/5848347/inquiry-the-status-of-azure-cloud-services-in-the), answerer not identifiable as Microsoft staff), and secondary reporting says Microsoft denied any hits on its facilities ([TechPolicy.Press, 12 Mar 2026](https://www.techpolicy.press/the-legal-and-policy-fallout-from-data-center-strikes-in-the-middle-east-war/)). No primary Microsoft statement about the strikes was found; that is an assumption to keep checking.
- **Oracle Cloud** has two UAE regions, Abu Dhabi `me-abudhabi-1` and Dubai `me-dubai-1`, one availability domain each ([OCI regions](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm)); OCI Database with PostgreSQL is shown deployed in both in Oracle's own DR tutorial ([Oracle tutorial](https://docs.oracle.com/en/learn/full-stack-dr-pgsql-cold-dr/index.html)), but the official service-availability matrix returned HTTP 403, so that is partly unverified.
- **Alibaba Cloud** has Dubai `me-east-1` with two zones ([Alibaba regions](https://www.alibabacloud.com/help/en/doc-detail/40654.htm)) and lists UAE (Dubai) for ApsaraDB RDS for PostgreSQL in a storage-type notice ([Alibaba notice](https://www.alibabacloud.com/help/en/rds/apsaradb-rds-for-postgresql/new-function-specification-rds-postgresql-new-storage-type-from-june-20-2024-universal-cloud-disk)).
- **Google Cloud** has no UAE region: its Middle East regions are Tel Aviv, Doha and Dammam ([Cloud Run locations](https://docs.cloud.google.com/run/docs/locations)). Neither do Neon, Supabase, PlanetScale, Railway, Render, Fly.io or Upstash (each provider's regions page, cited under Sources). Vercel has no Dubai region; its nearest compute regions are Mumbai and Frankfurt, its logs cannot be pinned to a region, and its builds run in the US ([Vercel regions](https://vercel.com/docs/regions), [Vercel compliance](https://vercel.com/docs/security/compliance)). Cloudflare's Data Localization Suite lists the UAE for regional traffic processing, but D1 "do[es] not run in" the Middle East and R2 has no UAE jurisdiction ([Cloudflare DLS regions](https://developers.cloudflare.com/data-localization/region-support/), [D1 data location](https://developers.cloudflare.com/d1/configuration/data-location/)).

**Options considered.**

1. *AWS me-central-1, as the earlier plan assumed.* Rejected for now: AWS itself says the region cannot reliably support customer applications and has told customers to leave. Re-evaluate if and when AWS announces restoration and resumes billing; the infrastructure module is written so that this is a re-deployment, not a rewrite.
2. *Azure UAE North primary, UAE Central for in-country disaster recovery.* Chosen. Two regions in the country, availability zones in the primary, every managed service the plan needs is offered and priced there, and the paired region is the documented target for geo-redundant PostgreSQL backups and geo-redundant storage.
3. *Oracle Cloud, Abu Dhabi and Dubai.* Kept as the named fallback if Azure UAE North becomes unavailable: two in-country regions, managed PostgreSQL. Not chosen first because the managed-service availability could not be fully verified, the team has no OCI experience, and the container and email services are thinner.
4. *A UAE sovereign or local host (Core42, Khazna) with self-managed Postgres.* Not chosen: it trades managed backups, point-in-time restore and zone redundancy for a compliance story the plan can get from Azure's UAE geography, and it puts database operations on a one-person team.

**Decision.** Azure, region **UAE North** (Dubai) for every service that holds or processes student data, with **UAE Central** (Abu Dhabi) requested at the start of the build as the in-country disaster-recovery target. The specific managed services, each verified as offered in UAE North:

| Need | Service | Verified by | Notes |
|---|---|---|---|
| PostgreSQL | **Azure Database for PostgreSQL Flexible Server**, PostgreSQL 17, General Purpose `D2ds_v5` at pilot, zone-redundant HA, geo-redundant backup enabled at creation | [PostgreSQL overview, region table](https://learn.microsoft.com/en-us/azure/postgresql/overview#azure-regions): UAE North ✅ zone-redundant HA, ✅ geo-redundant backup; [supported versions](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-supported-versions): 18, 17, 16, 15, 14 | PITR retention 7 to 35 days; geo-redundant backup "can only be configured when you create the server" and restores into the paired region ([backup concepts](https://learn.microsoft.com/en-us/azure/postgresql/backup-restore/concepts-backup-restore)). `pgaudit`, `pg_cron` and `pg_partman` are on the extension list ([extensions](https://learn.microsoft.com/en-us/azure/postgresql/extensions/concepts-extensions-versions)). PostgreSQL 17 rather than 18 because Azure notes some extensions are unsupported on 18; revisit at year 1. |
| Object storage | **Azure Blob Storage**, zone-redundant (ZRS) for documents, an immutable (WORM, time-based retention) container for raw SIS exports | ZRS and GRS meters priced in UAE North (Retail Prices API); [immutable storage](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview) "all redundancy configurations support immutable storage" | GRS/GZRS replicate only to the paired region, which is Abu Dhabi ([storage redundancy](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy)); used for backup copies, so nothing leaves the country |
| Containers | **Azure Container Apps**, zone-redundant environment in a VNet; one app for the web tier, one for the worker; **Container Apps Jobs** for migrations and the sweep watchdog | Meters priced in UAE North (Retail Prices API); [zone redundancy](https://learn.microsoft.com/en-us/azure/reliability/reliability-container-apps) "available in all regions that support Container Apps and availability zones"; [jobs](https://learn.microsoft.com/en-us/azure/container-apps/jobs) with cron schedules | The products-by-region page is script-rendered and could not be read; the price meters are the evidence. Cron schedules are evaluated in UTC, so the sweep is scheduled by the worker in the school's timezone (DR-2) |
| Scheduled jobs | **pg-boss** inside the worker (DR-2), with a Container Apps Job as the external watchdog | | Inngest Cloud stores all data in the United States and Trigger.dev Cloud does not pin stored run data to a region ([Inngest security](https://www.inngest.com/security), [Trigger.dev docs](https://trigger.dev/docs/triggering)), so hosted job runners are out |
| Transactional email | **Azure Communication Services Email**, resource created with data location **United Arab Emirates**, custom domain with SPF, DKIM and a DMARC policy | [ACS privacy](https://learn.microsoft.com/en-us/azure/communication-services/concepts/privacy): UAE is a selectable geography; "email message content [is processed] in real-time, using the resource's Data Location"; [custom domains](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/add-custom-verified-domains) | The same page says data "may transit or be processed in other geographies", and new custom domains are limited to 30 emails a minute and 100 an hour until a quota increase ([service limits](https://learn.microsoft.com/en-us/azure/communication-services/concepts/service-limits#email)). Amazon SES has a UAE endpoint but is on AWS; Resend, Postmark, SendGrid and Mailgun offer at most EU residency |
| Secrets | **Azure Key Vault** plus managed identities for the container apps | Meters priced in UAE North | No connection string in an environment variable; the worker and web app read secrets by identity |
| Logs and alerts | **Azure Monitor / Log Analytics**, Basic Logs for application logs, Analytics Logs for the sweep and audit-of-ops signals, alerts on the sweep watchdog | Meters priced in UAE North | Logs contain no personal data by rule (pass 4); 5 GB a month free on Analytics Logs ([Monitor pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/)) |
| Edge, TLS, WAF | **Application Gateway WAF v2**, regional, in UAE North | Meters priced in UAE North | Not Azure Front Door: it "operates globally", "can't force client traffic to a specific POP" and terminates TLS at the edge ([Front Door FAQ](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-faq), [end-to-end TLS](https://learn.microsoft.com/en-us/azure/frontdoor/end-to-end-tls)), so a student's request would be decrypted wherever they happen to be routed |
| Registry | **Azure Container Registry**, Basic | Meters priced in UAE North | |
| AI inference | Not in the UAE on any provider. Bedrock serves no Anthropic model in-region for `me-central-1` (global cross-region profiles only), and Foundry offers Claude in US regions and Sweden Central with no UAE deployment type ([Bedrock model regions](https://docs.aws.amazon.com/bedrock/latest/userguide/models-region-compatibility.html); [Foundry Claude models](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/claude-models); [Foundry partner regions](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-from-partners#region-availability-by-deployment-type)) | | Pass 4 sets the rule and pass 5 the mechanism. This pass only records that the cloud choice does not change the answer |

The frozen demo (`index.html`, synthetic data) stays on Vercel. Nothing else runs outside UAE North.

**Consequences.**

- The subscription must request UAE Central access in week one ([region access request process](https://learn.microsoft.com/en-us/troubleshoot/azure/general/region-access-request-process)); until it is granted, geo-redundant backups cannot be restored and the restore drill in DR-9 cannot be run end to end.
- Geo-redundant backup must be switched on when the production server is created, or it is unavailable for that server's life.
- The domain layer, migrations and infrastructure module are provider-neutral (PostgreSQL, S3-style blob access behind one interface, containers, an email adapter). Moving to AWS if it is restored, or to OCI if Azure fails, is an infrastructure change and a data migration, not an application change. That neutrality is worth its small cost given what happened in March.
- Residency is still not durability. A single-country event can destroy both Dubai and Abu Dhabi copies. §5 (Challenges) argues for putting the out-of-country cold-copy question to ACS and counsel now, as a real choice: a copy abroad is restorable only if key material is also held abroad, and it needs ADEK's consent first (§5.1, DR-9).

**Monthly cost.** USD list prices, pay-as-you-go, UAE North, retrieved 2026-09-22 from the Azure Retail Prices API (`prices.azure.com/api/retail/prices`, filters given in Sources); 730 hours a month; no reservations, no Defender for Cloud plan beyond Defender for Storage, no DDoS Network Protection. The Azure Backup vaulted long-term-retention fee for PostgreSQL was not retrieved and is an assumption. The scales are the ones in CONTEXT.md §5. Revised 2026-09-24 (F71): zone-redundant HA bills storage twice, and seven lines the first version left out are added below the original total; the Defender for Storage and Key Vault HSM prices were re-read from the Retail Prices API on 2026-09-24, and the lines marked "assumption" were not.

| Line | Pilot: 1 school, ~1,300 students | Year 1: 3 schools, <5,000 students | Year 3: 30 schools, 30,000 to 50,000 students |
|---|---|---|---|
| PostgreSQL compute, zone-redundant HA (standby billed at the primary's rate) | `D2ds_v5` $0.217/h × 730 × 2 = **$316.82** | `D4ds_v5` $0.434/h × 730 × 2 = **$633.64** | `E4ds_v5` $0.60/h × 730 × 2 = **$876.00** |
| PostgreSQL read replica (reporting) | none | none | `E4ds_v5` $0.60/h × 730 = **$438.00** |
| PostgreSQL storage, $0.138/GB-month; zone-redundant HA bills the standby's storage too (F71) | 128 GB × 2 = **$35.33** | 256 GB × 2 = **$70.66** | 1,024 GB × 2 (HA pair) + 1,024 GB (replica) = **$423.94** |
| PostgreSQL backup storage, geo-redundant, $0.105/GB-month on ((2 × backup) − provisioned) | (256 − 128) × 0.105 = **$13.44** | (512 − 256) × 0.105 ≈ **$30** with WAL | (2,048 − 1,024) × 0.105 ≈ **$120** with WAL |
| Container Apps, consumption, active rates $0.000024 per vCPU-second and $0.000003 per GiB-second | web 2 × (0.5 vCPU, 1 GiB) = $78.84; worker 1 × (0.5, 1) = $39.42 → **$118.26** | web 2 × (1, 2) = $157.68; worker 1 × (1, 2) = $78.84 → **$236.52** | web 4 × (1, 2) = $315.36; worker 2 × (2, 4) = $315.36 → **$630.72** |
| Application Gateway WAF v2, $0.475/h fixed + $0.019 per capacity-unit-hour | 346.75 + 10 CU = **$485.45** | 346.75 + 15 CU = **$554.80** | 346.75 + 30 CU = **$762.85** |
| Blob storage (Hot ZRS $0.025344, LRS $0.020275, GRS $0.04055 per GB-month) | 50 GB ZRS + 20 GB LRS imports + 100 GB GRS backup copies = **$5.74** | 200 + 50 + 400 GB = **$22.30** | 2,048 + 500 + 4,096 GB = **$228.13** |
| Key Vault ($0.0396 per 10k operations) | **$1** | **$2** | **$5** |
| Log Analytics (Basic $0.66/GB, Analytics $3.29/GB after 5 GB free, retention $0.132/GB-month) | 5 GB Basic + retention = **$4.62** | 20 GB Basic + 10 GB Analytics + retention = **$33.61** | 100 GB Basic + 30 GB Analytics + retention = **$174.65** |
| Container Registry (Basic $0.1666/day; Standard $0.6666/day) | **$5.00** | **$5.00** | **$20.00** |
| Communication Services Email ($0.00025 per email + $0.00012/MB) | 3,000 emails = **$1.11** | 20,000 = **$7.40** | 300,000 = **$111.00** |
| Internet egress (first 100 GB free, then $0.181/GB) | under 100 GB = **$0** | 250 GB = **$27.15** | 2,048 GB = **$352.59** |
| Azure Backup vaulted long-term retention (assumption, not retrieved) | **~$20** | **~$40** | **~$150** |
| **Production total, first version** (storage counted once) | **≈ $989** (≈ $504 without the WAF) | **≈ $1,628** | **≈ $4,152** |
| *Lines added 2026-09-24 (F71, F61)* | | | |
| HA storage correction (the row above) | **+$17.66** | **+$35.33** | **+$141.32** |
| Blob SFTP, $0.30 per hour per SFTP-enabled account, only if the weekly pack arrives by SFTP (pass 2 open decision 17; price as verified by pass 7) | 1 account = **$219.00** | **$219.00** | **$219.00** |
| Defender for Storage malware scanning (required by pass 4 T6), $0.0134 per account-hour plus $0.15 per GB scanned | 2 accounts + 10 GB = **$21.06** | 2 accounts + 40 GB = **$25.56** | 2 accounts + 300 GB = **$64.56** |
| Key Vault Premium HSM keys, $1.32 per RSA 2048 key-month, including the second vault in UAE Central (pass 4 §9.2) | 8 keys = **$10.56** | 10 keys = **$13.20** | 70 keys = **$92.40** |
| Entra ID P2 licences for Privileged Identity Management (pass 4 §3.7); assumption, price not retrieved | 2 operators ≈ **$20** | ≈ **$20** | 4 operators ≈ **$40** |
| NAT gateway for the connectors' static egress IP, from B9 (pass 4 §9.10); assumption, meter not found in the API | ≈ **$35** once connectors run | ≈ **$40** | ≈ **$60** |
| Microsoft support plan, the minimum tier that enables Customer Lockbox (pass 4 §3.7, F61); assumption, price not retrieved | ≈ **$29** | ≈ **$29** | ≈ **$100** |
| **Production total, revised** | **≈ $1,341** (≈ $1,122 without SFTP) | **≈ $2,010** | **≈ $4,869** |
| Staging (no HA, `B2ms` $0.158/h, one replica each, no WAF) | **≈ $206** | **≈ $206** | **≈ $300** |
| **Total per month** | **≈ $1,547** | **≈ $2,216** | **≈ $5,169** (≈ $172 per school at 30) |

Three things about the numbers. The WAF is the largest single line at every scale and is a school-IT-review requirement rather than a load requirement; pass 4 decides when it must be on, and the pilot can run its synthetic-data months without it. Container Apps idle rates ($0.000003 per vCPU-second) would roughly halve the web tier's compute at pilot traffic; the table uses active rates as an upper bound. Reserved capacity for the database (one year) is not priced here and would cut the largest recurring line; it is worth buying only after the pilot proves the shape.
### DR-2 · The backend's shape

**Context.** The frontend is Next.js and TypeScript. One builder writes most of the code with a coding agent; three teammates work in parallel; the load is a nightly batch and a morning burst (§5). The failure the repository has already suffered is silent overwrite and documentation that drifted from the build, so the shape has to make contracts explicit and enforcement single-pathed. Verified tooling facts (all retrieved 2026-09-22): Next.js 16 is current (16.3.6; App Router, route handlers and Server Actions stable) and requires Node 20.9 or later ([Next.js 16](https://nextjs.org/blog/next-16), [installation](https://nextjs.org/docs/app/getting-started/installation)); Node 24 is the Active LTS line and Node 20 reached end of life on 30 April 2026 ([Node release schedule](https://raw.githubusercontent.com/nodejs/Release/main/schedule.json)); Drizzle ORM is at 0.45.3 with a 1.0 release candidate, supports Postgres row-level security in its schema and generates SQL migration files ([Drizzle RLS](https://orm.drizzle.team/docs/rls), [drizzle-kit generate](https://orm.drizzle.team/docs/drizzle-kit-generate)); Prisma is mid-transition, with `@prisma/client` stable at 7.10 while the CLI's `latest` tag is an 8.0 release candidate whose migrations are no longer SQL files ([Prisma 8 migrations](https://www.prisma.io/docs/orm/migrations/how-migrations-work)); tRPC v11 is current and maintained ([tRPC v11](https://trpc.io/blog/announcing-trpc-v11)); oRPC is at 1.15 with a v2 beta; ts-rest has had no stable release since March 2025; pg-boss 12 supports cron scheduling on Postgres `SKIP LOCKED` ([pg-boss](https://github.com/timgit/pg-boss)); Zod 4 is stable ([Zod 4](https://zod.dev/v4)); Vitest 5 shipped on 3 September 2026 ([Vitest 5](https://vitest.dev/blog/vitest-5)); Turborepo 2.11 and pnpm 12 are current.

**Options considered.**

1. *Everything in Next.js: route handlers plus Server Actions, no worker.* Rejected. The nightly sweep, imports and email delivery are long-running background work; running them inside a request-serving process on a platform that scales to zero is the wrong shape, and Server Actions are a second, less visible enforcement path for mutations.
2. *A separate API service (Fastify or Hono) with Next.js as a pure client.* Rejected for v1. It doubles the deploy surface and contract maintenance for four people to buy independent scaling and non-TypeScript clients that nobody needs yet. The domain layer is kept independent of Next.js so that this service can be added later without a rewrite.
3. *A modular monolith in one repository with two deployables: the Next.js app and a worker, both consuming one domain package, with a typed RPC layer between browser and server.* Chosen.

**Decision.**

- **Runtime:** Node 24 LTS, TypeScript strict, ES modules. Next.js 16 App Router for `apps/web`, built with `output: 'standalone'` into a container. A plain Node process for `apps/worker`.
- **Domain layer:** `packages/domain` holds every rule and every mutation as a function with a typed input, running inside `withTenant()` (DR-4). It imports the database package and the engine package; it does not import Next.js or tRPC. Both deployables call it.
- **API contract:** tRPC v11 routers in `packages/api`, one router per module, procedures that validate input with Zod 4 schemas from `packages/contracts` and call one domain function each. Mounted in a single route handler at `/api/trpc`. Server Components call procedures through the server-side caller, so reads do not pay an HTTP hop. **Server Actions are not used for data mutations**; a lint rule forbids `'use server'` outside a small allow-list of UI-only helpers. Reason: one enforcement path, testable without a browser, and callable by the worker and by tests. The inferred router type is the frontend's contract; there is no hand-written client type. An OpenAPI surface for connectors and webhooks (pass 2) is added later as `apps/api` with Hono and `@hono/zod-openapi` over the same domain package, when a non-TypeScript caller exists.
- **Query layer:** Drizzle ORM 0.45 pinned (upgrade to 1.0 after it has been GA for two minor releases), driver `postgres` (postgres.js). Schema in `packages/db/src/schema/*.ts`, one file per Postgres schema. `jsonb` columns are typed with Zod schemas from `packages/contracts` via `.$type<>()`, and validated on write in the domain layer.
- **Migrations:** `drizzle-kit generate` produces SQL files under `packages/db/migrations/`; policies, functions and triggers are hand-written SQL in the same sequence (`drizzle-kit generate --custom`). Migrations are applied by `drizzle-orm/migrator` running as a Container Apps Job in the deploy pipeline before the new revision receives traffic, connected as `caros_migrator` (DR-4). That migrator runs every pending migration inside one transaction (pass 7 read the package source, F40), and PostgreSQL refuses `CREATE INDEX CONCURRENTLY` inside a transaction block. So the job has two steps: the Drizzle migrator for ordinary files, then a small non-transactional runner for files whose first line is `-- no-transaction`, each holding exactly one statement, recorded in its own journal table. At pilot and year-1 scale no table is large enough to need `CONCURRENTLY`; indexes are created plainly inside the transaction, and the second step exists for year 3. `drizzle-kit push` is forbidden everywhere except a developer's own database. Every migration is reviewed as SQL in the pull request. A nightly job diffs the production schema against the migration snapshot and alerts on drift. Atlas was considered and not chosen: row-level-security objects and `schema plan` are in its paid tier ([Atlas community edition](https://atlasgo.io/community-edition)).
- **Nightly sweep and all background work:** pg-boss 12 in `apps/worker`, backed by a `pgboss` schema in the same database (so job state has the same residency and the same backups). Job names and hours follow pass 3 §13.2 (§12.1 of the pass 7 review): a `sweep.schedule` cron runs every fifteen minutes and, for each school that holds data (`core.school.status IN ('shadow','live')`, §2.3; never "active", which excluded the pilot school while it was in shadow, F36), enqueues `sweep.run` with singleton key `sweep:<school>:<local date>` once the school's local time has passed its `sweep_hour` (default 02:00) and no nightly run exists for that date. The list of schools comes from `core.schools_due_for_sweep()`, a definer function that returns school ids and nothing else (§2.4); the worker then opens one `withTenant()` per school. The job calls `engine.evaluateSchool()` and writes `signal.sweep_run` and its children. Retries with backoff; a failed run is `failed` and the next tick retries until 05:30 local. A `sweep.watchdog` job at 05:45 local checks that today's nightly run exists and succeeded or was partial, emits `sweep.missed` if not, and raises an alert through Azure Monitor; the alert reaches Davide before 07:00. A Container Apps Job on a cron is the second, independent watchdog so the failure of the worker itself is also noticed. Imports, outbox delivery, AI generations and partition maintenance are further pg-boss queues in the same worker.
- **pg-boss has its own login and no tenant privileges** (F36). The `pgboss` schema is owned by `caros_jobs`, a login role with no tier role and no privilege on any tenant table. The web app never touches the queue tables: it enqueues through `jobs.enqueue(queue, school_id, record_ids)`, a definer function owned by `caros_jobs` that validates the payload against the queue's schema (a school id plus record ids, never names or text) and refuses anything else. The worker's pg-boss client connects as `caros_jobs` to fetch and complete jobs, then does the job's work in a tenant transaction as `caros_worker` with the job's school id. A job for school A that carries school B's record ids writes nothing, because every read in that transaction is bound to A (test in `packages/db/test/jobs`). Completed jobs are deleted after seven days and archiving is off; the queue is registered in the privacy registry's list of non-tenant stores (§2.21) so erasure and retention reach it.
- **Tests:** Vitest 5 for unit and contract tests, Playwright for browser tests, an ephemeral PostgreSQL in CI for every database test (RLS tests run against both seed tenants, DR-8). Biome for lint and format; `dependency-cruiser` enforces module boundaries (which package may import which).

**Consequences.** The web tier is stateless and scales to zero in staging. Every mutation has exactly one code path: tRPC procedure → domain function → `withTenant()` transaction → audit and event rows in the same transaction. Adding a mobile client or a connector API later costs a router or an OpenAPI layer, not a new domain. Drizzle's own RLS helpers are not used to define policies, because the policy set is generated by `auth.protect()` in SQL; Drizzle's snapshot therefore does not know about them, and `generate` (which diffs snapshots, not the live database) will not try to drop them. That is one reason `push` is forbidden.

### DR-3 · Repository layout and module ownership

**Context.** Four people, one repository, a coding agent working across many sessions, and a history of silent overwrites. The signal engine must be a pure package testable without a database.

**Decision.** One pnpm 12 workspace with Turborepo 2.11 for task orchestration and remote caching:

```
caros/
├── apps/
│   ├── web/                 Next.js 16. Screens, tRPC route handler, auth callbacks. Owner: frontend pair.
│   └── worker/              pg-boss process: sweep, imports, outbox, AI jobs, partitions. Owner: backend.
├── packages/
│   ├── contracts/           Zod 4 schemas: API inputs/outputs, jsonb shapes, event and audit payloads,
│   │                        rule-set parameter schemas. The only package every other package may import.
│   ├── db/                  Drizzle schema, SQL migrations, withTenant(), the RLS/registry test harness.
│   ├── engine/              The signal engine. Pure: (series, config, calendar) → evaluation. No I/O, no
│   │                        database import. Owner: pass 3's builder.
│   ├── domain/              Rules and mutations per module (see module map). Imports db, engine, contracts.
│   ├── api/                 tRPC routers, one per module, over domain. Imports domain, contracts.
│   ├── ingest/              Connector interface, CSV adapter, mapping-profile validation (pass 2).
│   ├── ai/                  Model gateway, prompt templates (versioned files), pseudonymisation (pass 5).
│   ├── notify/              Outbox delivery adapters (Azure Communication Services Email, in-app).
│   ├── seed/                The two synthetic tenants and the fixture generators (DR-8).
│   ├── ui/                  Shared React components and the design tokens ported from DESIGN.md.
│   └── config/              Shared tsconfig, Biome, dependency-cruiser rules.
├── infra/                   Terraform for Azure: one module, instantiated per environment and per
│                            isolated deployment.
├── docs/
│   ├── PLAN.md              The living plan: phase status, what each session should read first.
│   ├── decisions/           One file per decision record, starting with this pass's DR-1 to DR-9.
│   └── runbooks/            Sweep failed, restore drill, tenant onboarding, erasure.
├── CLAUDE.md                What every session reads first (pass 6 writes it).
├── CODEOWNERS
├── turbo.json  pnpm-workspace.yaml  biome.json  .dependency-cruiser.cjs
└── .github/workflows/       ci.yml (typecheck, lint, boundaries, unit, db, e2e), deploy.yml
```

**Module ownership and the rules that keep four people out of each other's files.**

| Package or path | Owner | Others may | Contract |
|---|---|---|---|
| `packages/contracts` | shared; a second person's review once a second regular builder exists (C8) | propose | Zod schemas are the API between all modules; a breaking change bumps the schema version |
| `packages/db` | backend lead | add a migration in their module's schema, reviewed by the owner | Every table registered in `privacy.table_registry`; every tenant table protected (test) |
| `packages/engine` | engine builder | read; submit fixtures | `evaluateStudent(input): Evaluation` pure; property tests over the adversarial set (pass 3) |
| `packages/domain/<module>` | module owner (module map, §4) | call through the module's `index.ts` only | `dependency-cruiser` forbids importing another module's internals |
| `packages/api/<module>` | same as the domain module | | One procedure per domain function; no logic |
| `apps/web/app/(role)/<module>` | frontend pair | | Screens import from `packages/api` types and `packages/ui` only |
| `packages/ingest`, `packages/ai` | passes 2 and 5 name them | | Adapter interfaces defined in `contracts` |
| `infra/` | Davide | propose | Terraform plan posted on every PR; apply only from `main` |

Branch and review discipline (pass 6 details it): short-lived branches, squash merges, a required CI run that includes the RLS suite and the boundary check, and branch protection on `main` that rejects force pushes. **While Davide is the only builder** (decision C8, 2026-09-24), every automated check stays required (CI, tests, immutable migrations, the anti-overwrite hooks), human review is asynchronous with a service level and never blocks a merge, and a different-model review is required only on the reserved list pass 6 keeps; the ownership column above and `CODEOWNERS` review switch on when a second regular builder joins (F46: with one code owner per path, GitHub would otherwise let nothing merge). The overwrite that destroyed Phases 1 to 4 was a merge that replaced a file wholesale; in a repository of many small files with required checks and a test suite, the same mistake fails CI instead of landing.

### DR-4 · Tenancy

**Context.** Multi-tenant from the first migration (section 3). The database, not only the application, must enforce isolation, and the same code must run as an isolated single-school deployment on demand. PostgreSQL row-level security is the mechanism, and its documented limits shape the design: superusers and roles with `BYPASSRLS` bypass every policy; table owners bypass unless `FORCE ROW LEVEL SECURITY` is set; a table with RLS enabled and no policy denies everything ([PostgreSQL row security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html), [ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html), [CREATE ROLE](https://www.postgresql.org/docs/current/sql-createrole.html)). `set_config(name, value, true)` sets a value "only … during the current transaction" ([set_config](https://www.postgresql.org/docs/current/functions-admin.html)).

**Decision.** Four layers, each of which would hold alone.

1. **Structure.** Every tenant table carries `school_id`, and every foreign key between tenant tables is composite on `(school_id, id)` (§2.1). A row cannot point at another school's row even if the application passes the wrong identifier.
2. **Roles** (revised by pass 8 for F01 and §12.2 of the pass 7 review). `caros_owner` owns every object and cannot log in. Each deployable has **its own login role and its own managed identity**, and is granted only the tier roles it may assume:

   | Login role | Deployable | May `SET ROLE` to | Never holds |
   |---|---|---|---|
   | `caros_web` | `apps/web` | `caros_t_staff`, `caros_t_teacher`, `caros_t_student`, `caros_t_guardian`, `caros_t_mentor`, `caros_t_ai` | system, support, owner |
   | `caros_worker` | `apps/worker` | `caros_t_system`; `caros_t_ai` for AI jobs run as the case owner (F44) | any user tier, support, owner |
   | `caros_support` | the support console, a separate small app (pass 4 §3.7) | `caros_t_support` | everything else |
   | `caros_migrator` | the migrations job | `caros_owner` (`SET ROLE`) | every tier role |
   | `caros_jobs` | pg-boss in web and worker (DR-2) | nothing; privileges on the `pgboss` and `jobs` schemas only | every tier role |

   Every login role is created `NOINHERIT`, so a connection that sets the tenant context but skips `SET LOCAL ROLE` holds no table privilege at all, rather than the union of its tiers' privileges. Eight `NOLOGIN` tier roles carry column privileges: `caros_t_staff` (counselors, school administrators, and staff who hold only capabilities), `caros_t_teacher` (a separate tier because a teacher's column rules differ from a counselor's, F75), `caros_t_student`, `caros_t_guardian`, `caros_t_mentor`, `caros_t_ai` (pass 4 D55; its grants are generated from an allowlist, F44), `caros_t_system` and `caros_t_support`. One further role, `caros_policy`, has `BYPASSRLS` and no login; it owns only the `SECURITY DEFINER` helpers the policies call and the trigger and transition functions that write history, audit and event rows, each of which restricts itself to the current school explicitly and none of which is executable by `PUBLIC`. Every table with `school_id` has `ENABLE` and `FORCE ROW LEVEL SECURITY`, so even the owner is bound.
3. **Transaction context.** All database access goes through one function in `packages/db`:

   ```ts
   withTenant(ctx: { schoolId; personId?; role?; actorKind; requestId }, fn: (tx) => Promise<T>): Promise<T>
   ```

   It opens a transaction and, before anything else, runs one statement: `SELECT set_config('app.school_id', $1, true), set_config('app.person_id', $2, true), set_config('app.role', $3, true), set_config('app.actor_kind', $4, true), set_config('app.request_id', $5, true), set_config('app.session_id', $6, true)` (plus `app.actor_label` for support and ingest actors, who are not `core.person` rows), followed by `SET LOCAL ROLE caros_t_<tier>`. `actor_kind` is one of `user`, `system`, `support`, `ingest`; the migration runner alone sets `migration`. **The tier is evaluated in the policy expression, which runs as the caller, and passed into `auth.allowed()` as its first argument** (F01). Inside a `SECURITY DEFINER` function `current_user` is the function's owner, which is why the first version's check could never succeed; a policy expression is evaluated as the querying role, so `current_user` there is the tier the transaction assumed. `auth.allowed()` honours `system` only when that argument is `caros_t_system`, `support` only when it is `caros_t_support`, and a user claim only when the tier matches the tier of the acting role's membership. Because `caros_web` is not granted `caros_t_system` or `caros_t_support`, a request handler cannot assume either, whatever context it sets: "a request handler cannot claim to be the worker" is now true at the database. Both settings and role are transaction-scoped: when the transaction ends, the connection returns to the pool with no context, and the next transaction must set its own. The pool object is not exported; there is no way to run a query outside `withTenant()`. A query issued with no context sees no rows, because `auth.current_school()` returns `NULL` and `school_id = NULL` is never true: the system fails closed.
4. **Policies.** `auth.protect()` (§2.4) installs on every tenant table a `RESTRICTIVE` tenant policy (`school_id = auth.current_school()`, both `USING` and `WITH CHECK`) and `PERMISSIVE` role policies that call `auth.allowed(current_user, table, data_class, action, subject columns…, row kind)`. The tenant policy is restrictive, so no permissive policy can widen it. `auth.allowed()` reads `auth.role_permission`, which is data: a new role is rows in `auth.role` and `auth.role_permission` and a `tier` assignment, not a migration. Since pass 8 (F02, F15) the class may be a per-row expression (a document carries its own class; a shadow case is `signal_shadow`), the insert and update policies accept either `write` or the verb the table carries (`escalate`, `approve`, `configure`), and every qualifier in pass 4's matrix has a named mechanism in §2.4a.

**Connection handling.** Each Container Apps replica keeps its own small pool (ten connections) directly to the Flexible Server; at pilot and year-1 scale that is under a hundred connections and needs no external pooler. Azure's built-in PgBouncer defaults to transaction pooling and its documentation defers to PgBouncer's own feature map, which lists session `SET`/`RESET` as unsupported in that mode and says nothing about `SET LOCAL` ([Azure PgBouncer](https://learn.microsoft.com/en-us/azure/postgresql/connectivity/concepts-pgbouncer), [PgBouncer features](https://www.pgbouncer.org/features.html)). Transaction-scoped `set_config` and `SET LOCAL ROLE` inside an explicit transaction are, by PostgreSQL's semantics, contained in the transaction that the pooler hands to one server connection, so they should be safe under transaction pooling; that is an inference, not a documented guarantee, and it is tested explicitly in the RLS suite before the pooler is ever enabled (year 3, open decision).

**Tests that must exist before any real data.** In `packages/db/test/rls/`: for each tier role and each tenant table, run as tenant A with tenant B's data present and assert zero rows visible and zero rows writable; run with no context and assert zero rows; run as `caros_owner` with `FORCE` and assert the same; run every `auth.perm_scope` against both synthetic schools with a student who is in the caseload, in the roster, self, a linked child, a paired mentee, in a led year group and tutor group, reachable through an open escalation, and none of those. Added by pass 8: connected as `caros_web`, `SET ROLE caros_t_system`, `SET ROLE caros_t_support` and `SET ROLE caros_owner` each fail (F01); a `caros_web` connection that sets `app.actor_kind = 'system'` under a user tier sees exactly what that user sees; a connection that sets context but skips `SET ROLE` reads nothing (the `NOINHERIT` test); every verb (`escalate`, `approve`, `configure`) succeeds end to end through RLS for a role that holds it and fails for one that does not (F02); and every qualifier in §2.4a has a negative fixture. The suite runs on every pull request.

**Single-school isolated deployment.** The same container images and the same migrations, deployed by the same Terraform module into a separate Azure subscription and resource group with `deployment_mode = "single"`. In that mode: the tenant table holds one school that is not `offboarded` and the application refuses to start if it finds more; `packages/seed` installs no second tenant; backups, Key Vault, storage and the WAF are per deployment; RLS stays on unchanged, because the code path is identical and a "single-tenant" branch would be exactly the drift this plan is trying to avoid. The cost of an isolated deployment is the pilot production column of DR-1, per school, which is the number to quote when a school asks for it.

### DR-5 · Schema conventions

The full DDL is §2. The conventions are listed at §2.1 so that they sit next to the code they govern; the decision here is only that they are binding, that they are enforced by tests in `packages/db` rather than by review alone (every tenant table registered, protected, composite-keyed, timestamped; no forbidden derived columns; no display strings), and that the DDL in §2 is the source from which the first Drizzle schema files and migrations are written, in the order pass 6 sets.
### DR-6 · Derived versus stored

**Context.** The prototype computes the run, course demand, supervision load, CAS totals and the ten dimension statuses at render time, and its own comments record why: every stored second copy it ever had drifted from the table under it (the 67% tally over 87 rows, nineteen at-risk courses where there were five, five CAS hours under an eighteen-month heading). At the same time the engine's outputs must be stored, versioned and frozen, because a past alert has to stay explainable (invariant 4). The line between the two has to be drawn precisely.

**Decision.** Three classes of value.

**Never stored as a second copy of the truth.** These are views or pure functions over the tables above, computed at read time or in the domain layer, and any pull request that adds a column for one of them is rejected.

| Value | Prototype | Backend | Why derived |
|---|---|---|---|
| The run (kept / soft / break / none per week) | `weekRun` from series and band; `weeks[]` stored for roster students | `signal.week_run()` over `signal.feature_snapshot` | The sheet and the file must read the same cells |
| Breaks count | `runBreaks` | `cardinality(array_positions(week_run, 'break'))` | Same |
| Subject demand and viability | `demandFor`, `subjectViable`, `demandRows` | `ib.v_subject_demand`, `ib.v_subject_viability` | Counted from the cohort's own picks; viability is per subject |
| Supervision load and queue | `eeLoad`, `eeQueue`, `eeSupervising` | `ib.v_supervision_load`, indexed queries on `ib.ee_essay` | Stored load disagrees with the list under it |
| EE next milestone, stalled, waiting, nudge | `eeNext`, `eeStalled`, `eeWaiting`, `eeNudge` | domain functions over `ee_milestone_due`, `ee_milestone_completion`, `proposed_at` | Dates against today |
| CAS totals, thin strands, gap, monthly run | `casSum`, `casStalled`, `casNote` | `ib.v_cas_totals` plus domain functions | Ledger is the truth; imported history is a ledger row |
| The ten dimension statuses | `DIMS` functions | domain functions over `uni.v_application_pack`, snapshots and `config.rule_set_version 'dimensions'` | Thresholds are versioned; a stored status would freeze one version |
| Application pack completeness, list balance, days to deadline, flags | `APP`, `dimListBalance`, `uni.flags[]` | `uni.v_application_pack` and rule functions | Rule outputs over live tables |
| Caseload and cohort counts, `needToday`, `prioCounts` | `prioCounts()` | aggregate queries over `signal.case` and `auth.caseload_assignment` | Two populations, never a stored total (invariant 7) |
| Last contact | `lastContact` string | `signal.v_last_contact` | Max of dated records |
| Age of a proposal, days to a deadline, "6 weeks ago" | strings | interval arithmetic against `core.school_today()` | Display strings drift |
| Admission probability | `t.p` | not stored, not computed (§11.3; pass 5 decides what replaces it) | No source |

**Stored because they are the record, not a copy.** These are outputs of a versioned rule at a moment in time. Storing them is what makes the past explainable; recomputing them later with current data or current rules would be a different fact.

| Value | Table | What makes it correct |
|---|---|---|
| Baselines: series, band, features | `signal.feature_snapshot` | Content-addressed, immutable, carries `engine_version` and the source row ids |
| The engine's conclusion per student per run | `signal.evaluation` | Immutable, references the three rule-set versions through `sweep_run` |
| Signals and their frozen inputs | `signal.signal.inputs` | Immutable; a later run supersedes rather than edits |
| Evidence items | `signal.evidence_item.snapshot` | Append-only trigger |
| Tier and stage history | `signal.case_tier_history`, `signal.case_stage_history` | Append-only; written by trigger from the case row |
| Supervision load at assignment | `ib.ee_essay.supervisor_load_at_assignment` | Stamped by trigger at the moment of confirmation |
| Selection version answered by a sign-off | `ib.selection_signoff.selection_version` | Stamped at insert; a changed pick deletes the sign-off |
| The roadmap a student was approved on | `discovery.approved_pathway.roadmap` | Snapshot at approval |
| Classification of a target (reach / match / safety) | `uni.student_target.classification` | Carries the rule version and inputs; recomputed, never edited |

**Materialised for convenience, with a single writer and a nightly check.** These exist so the caseload sheet is one query, and each has exactly one writer.

| Value | Column | Writer | Kept correct by |
|---|---|---|---|
| Current tier and stage | `signal.case.tier`, `.stage` | domain layer and engine, through the trigger that writes history | The trigger: a change without a history row is impossible |
| Yesterday's tier | `signal.case.tier_yesterday`, `.moved_why` | the sweep only (actor_kind `system`) | A nightly assertion recomputes it from `case_tier_history` and alerts on any mismatch |
| Target classification | `uni.student_target.classification` | the sweep, and an event-triggered recompute when predicted grades or requirements change | Rule version stored; the assertion recomputes a sample nightly |
| Normalised grade percentage | `sis.grade.normalised_pct` | the import, from `ref.grade_scale` | Raw value kept; a scale change triggers a recompute job |
| Reporting aggregates | `reporting.agg_*` tables, one row per school, period and measure (pass 6 names them) | the worker's refresh job after the sweep, one `withTenant()` per school | Recomputed, never edited; the events stream is the truth. **Not materialised views** (F34): a materialised view has no row-level security and no `security_invoker` option, and `REFRESH` runs as its owner, so it would hold every tenant or, refreshed inside one school's context, only that school. Aggregate tables carry `school_id`, are protected like every tenant table, and have exactly one writer |

**Consequences.** The domain package exposes derived values through named functions, and the frontend never recomputes a rule from raw rows. The `packages/db` test suite carries a "no second copies" test: a list of forbidden column names (`run`, `weeks`, `demand`, `load`, `total_hours`, `days_left`, `probability`, `signal_strength_cached`) that fails the build if any appears on a tenant table. The convention test also fails the build if any materialised view exists in a schema the tiers can read (F34).

### DR-7 · State machines

Every transition below is a named function in `packages/domain`, guarded by `auth.allowed(<class>, <action>, …)` for the acting role, executed in one transaction that also writes the audit entry and the product event. "Counselor" means the owner of the case or a counselor holding a current cover assignment for the student; "coordinator" means a counselor whose membership carries `ib_coordinator`.

#### 7.1 The concern case

The case has three dimensions. **Status** is open or closed. **Stage** is the seven-step pipeline the case file prints (`detect → explain → triage → act → follow → measure → learn`). **Tier** is one of the five (invariant 1). The prototype's data uses `monitor` as a stage value that its own pipeline does not display (`index.html` at `vCase` lists seven stages; six seeded cases carry `stage:"monitor"`); the backend does not have a `monitor` stage. A monitor-tier case sits at stage `triage` with an `auto_review_on` date.

| # | Transition | From | To | Who | Guard | Writes |
|---|---|---|---|---|---|---|
| C1 | Open from rules | no open case | status open, stage `explain` then `triage`, tier as evaluated | engine (sweep or event evaluation) | no open case for the student (unique index); tier ≠ null | case, evidence items, signals attached, tier/stage history, `case.opened`, `PRIORITY_SET` |
| C2 | Open manually | no open case | open, `triage`, tier chosen | counselor | reason required | as C1, `opened_by = person` |
| C3 | Attach new signals | open | open (tier may move) | engine | case open | `case_signal`, evidence, `case.tier_changed` if moved |
| C4 | Re-tier by rules | open | open, new tier | engine | hysteresis rules (pass 3); never lowers a tier a person raised within N days (`case.lifecycle`); **never lowers or closes a case that carries an unreleased escalation** (F07): while an escalation on the case is open, and after its outcome until a person sets the tier (C10), the engine may raise the tier and never lower it; the trigger `signal.case_escalation_pin` enforces it | tier history with `evaluation_id`, `tier_yesterday` at the sweep |
| C5 | Mark as seen (single or bulk) | open | unchanged | counselor | | `seen_at`, `CASE_ACKNOWLEDGED`, `case.seen` |
| C6 | View case file | any | unchanged | staff with `signal read` on the student | | `CASE_ACCESS`, `case.viewed` (first one feeds time-to-aware) |
| C7 | Accept | open, `triage` | open, `act` | counselor | | intervention opened from `suggested_action`, `CASE_ACCEPTED`, `intervention.opened` |
| C8 | Schedule a meeting | open, `triage`/`act` | open, `act` | counselor | | meeting slot or calendar ref, `MEETING_SCHEDULED` |
| C9 | Add context | open | open; re-evaluation queued | counselor | context kind from vocabulary | `case_context`, `CONTEXT_ADDED`; the engine's re-evaluation may lower the tier (C4), which is how the prototype's "recalculated to 38%" becomes explainable |
| C10 | Change tier manually | open | open, tier ±1 or to urgent | counselor | reason required; a downgrade sets `feeds_tuning`; on a case whose escalation has an outcome, this act releases the pin (`escalation.tier_released_at`) and is the only way the tier comes down | tier history `changed_by = person`, `PRIORITY_CHANGE`, `case.downgraded` |
| C11 | Dismiss | open, tier ≠ good, no unreleased escalation | closed, stage `learn`, tier `monitor`, outcome `not_a_concern` | counselor | reason required | `CASE_DISMISSED`, `case.dismissed` (feeds tuning) |
| C12 | Merge | open | closed, `merged_into_case_id` set; signals and evidence re-attached to the target | counselor | **both cases belong to the same student** (F07); a trigger refuses a merge across students, whose cases are linked instead (C25) | `CASE_MERGED` |
| C13 | Attach a teacher flag | open | open | counselor | flag status `new` | flag `linked`, `routed_key` set to a teacher-facing label that never says a case exists (F58), evidence item, `FLAG_ATTACHED`, `flag.routed` |
| C14 | Reassign owner | open | open | counselor with `caseload_lead`, or owner | target holds counselor role | `CASE_REASSIGNED`; caseload assignment may change separately |
| C15 | Escalate | open, no open escalation on the case | open, `act`, tier `urgent` | counselor | the structured referral of pass 4 §5.3 (D46); **at most one open escalation per case** (partial unique index) and **one idempotency key per submission**, so one act is never recorded twice (F07); when an earlier escalation on the case is closed, the new one is allowed and carries `previous_escalation_id` | `escalation`, outbox rows through `notify.enqueue()` to the route, `ESCALATED_SAFEGUARDING`, `case.escalated` |
| C16 | Acknowledge escalation | escalation unacknowledged | acknowledged | staff holding the `safeguarding_lead` capability on any staff membership (F10) | | `ESCALATION_ACKNOWLEDGED`, `escalation.acknowledged` |
| C17 | Intervention resolved | open, `act`/`follow` | open, `measure` | counselor | outcome required (I3) | `intervention.resolved`; monitoring continues |
| C18 | Close with outcome | open | closed, `learn`, `monitoring_until = closed_at + window` | counselor | outcome and note required; open interventions must be resolved or abandoned first | `CASE_CLOSED`, `case.closed` |
| C19 | Relapse inside the window | closed, within `monitoring_until` | a new open case with `relapse_of_case_id` | engine | relapse rule (pass 3) | as C1, `relapse.detected` |
| C20 | Recovery detected | open, `measure` | open, tier `good` | engine | recovery rule (pass 3) | `recovery.detected`, tier history |
| C21 | Auto-review | open, tier `monitor`, `auto_review_on` reached | open (re-evaluated) | engine | never closes a case with an unreleased escalation or inside an escalation's 90-day `esc` window (F07) | evaluation; may close as `not_a_concern` if nothing has crossed a threshold for the review period (pass 3 decides) |
| C22 | Student leaves the school | open | closed, outcome `left_school` | engine, on enrolment change | | `case.closed` |
| C23 | A teacher's safeguarding referral (F10) | any | open (a case is opened if none is, `opened_by = 'person'`, the teacher as opener, the student's primary counselor as owner), `act`, tier `urgent`; an escalation with `raised_via = 'teacher_flag'` | teacher, for a student on their roster, in their IB subject or whose Extended Essay they supervise | a `signal.teacher_flag` of kind `safeguarding` with the referral fields of pass 4 §5.3; one idempotency key per submission; executed by the definer function `signal.raise_teacher_referral()`, so the teacher gains no `signal` access and never sees the case | flag, case (if new), escalation, outbox rows through `notify.enqueue()` to the route, an in-app notice to the owning counselor, `TEACHER_REFERRAL`, `ESCALATED_SAFEGUARDING`, `case.escalated` |
| C24 | Add information to an open escalation (F07) | escalation open | unchanged | the raising counselor, the owning counselor, or a teacher who raised it | text ≥ 20 chars | `signal.escalation_update` (append-only, `safeguarding` class), the escalation reminder email to the current route (pass 4 §5.8), `ESCALATION_UPDATED` |
| C25 | Link cases across students (F07) | open or closed | unchanged | counselor | both cases readable by the actor; a reason | `signal.case_link` row; nothing is moved between the students' files; `CASE_LINKED` |

Stage moves: C1 sets `explain` and immediately `triage` (the two are one transaction; both history rows are written so the pipeline is honest). C7, C8, C15 and C23 move to `act`. The first intervention step completed moves to `follow`. C17 moves to `measure`. C11 and C18 move to `learn`. Nothing moves backwards except a reopen, which is a new case.

#### 7.2 The intervention

| # | Transition | From | To | Who | Guard |
|---|---|---|---|---|---|
| I1 | Open | none | `open`, `follow_up_on` set from `case.lifecycle` | counselor (C7) or manually on an open case | case open |
| I2 | Complete a step | open | open | owner or cover | |
| I3 | Resolve | open | `resolved` | owner or cover | `outcome` text and `outcome_kind` required |
| I4 | Abandon | open | `abandoned` | owner or cover | reason required |
| I5 | Follow-up done | open or resolved, `follow_up_on` reached | `follow_up_done_at` set | owner or cover | |
| I6 | Follow-up overdue | `follow_up_on` passed, not done | unchanged; event only | engine | feeds follow-up completion metric |

`resolvedIn` is `resolved_at - opened_at`, computed.

#### 7.3 The IB subject selection

Statuses: `draft → submitted → signed → approved`, with `changes_requested` as the return path and `withdrawn` as the exit. The code's vocabulary is `none, draft, submitted, signed, changes, approved` (`SELREC`); CONTEXT.md §7 lists "not started, submitted, signed, returned, approved" and omits `draft`. The backend follows the code, with `none` represented by the absence of a row and `changes` renamed `changes_requested`.

| # | Transition | From | To | Who | Guard |
|---|---|---|---|---|---|
| S1 | Start | no row | `draft` | student (self) | round open; student in the choosing year group |
| S2 | Edit picks and reasons | `draft`, `changes_requested` | same | student | round open |
| S3 | Submit | `draft`, `changes_requested` | `submitted`, `version + 1` | student | `selCheck` blockers empty: six groups filled, 3 or 4 HL, no period clash, a reason on every pick; `ask` findings do not block. Sign-offs whose pick changed are deleted. |
| S4 | Request a review slot | `submitted`+ | same, `review_slot_requested_at` | student | |
| S5 | Sign off a level question | `submitted` | `submitted`, or `signed` when every HL pick has a sign-off | teacher of that subject (`subject_teacher` scope), HL picks only, round `open` | through `ib.sign_off(pick_id, verdict, note)` only (F58): the function writes `teacher_person_id = auth.current_person()`, refuses a pick that is not HL or not in an open round, and cannot change the pick; the teacher sees the pick through `ib.v_signoff_card` (student name, the prerequisite mark, the student's reason), never the student's grades or any engine band; verdict `hl` needs no note; `sl` and `concern` need a note ≥ 8 chars |
| S6 | Record the review conversation | `submitted`, `signed` | same, `review_meeting_id` and `review_meeting_version` set | coordinator | a `core.meeting` of kind `selection_review` with notes ≥ 10 chars, dated and attributed, held after the current version was submitted; `review_meeting_version = version` |
| S7 | Approve | `signed` | `approved` | coordinator | the trigger `ib.check_approval` (F17): the meeting belongs to this student, is of kind `selection_review`, was held after `submitted_at`, has notes ≥ 10 chars, and `review_meeting_version = version`, so version 2 cannot be approved on version 1's conversation; round not archived |
| S8 | Return with a note | `submitted`, `signed` | `changes_requested` | coordinator | note ≥ 10 chars |
| S9 | Withdraw | any non-approved | `withdrawn` | student or coordinator | reason |
| S10 | Round closes | `draft` | `draft` (frozen); coordinator sees them as "not submitted" | engine | |

Whether a coordinator may approve from `submitted` when no pick is at HL (so nothing needs a sign-off) is a rule detail: the domain function treats "no HL sign-offs outstanding" as `signed`, matching the code.

Every status change above runs through a `SECURITY DEFINER` transition function (`ib.submit_selection`, `ib.sign_off`, `ib.record_review`, `ib.approve_selection`, `ib.return_selection`, `ib.withdraw_selection`) that checks the actor and the from-state; the student tier holds column-level `UPDATE` only on `goal_note`, `selection_pick.subject_id`, `level` and `reason` while the selection is `draft` or `changes_requested`, and no tier can write `status`, `review_meeting_id`, `review_meeting_version`, `approved_at` or `approved_by_person_id` directly (F17). An import never writes a pick: a ManageBac or SIS level that differs from an approved pick becomes a conflict row for the coordinator (pass 2, handoff).

**A known limitation, stated rather than hidden** (F65): the subject-choice engine is IB-shaped (six groups, three or four HL). A British school choosing A levels has the same shape of problem and cannot use it as built. It is generalised when a British school signs; until then the module is disabled for any school whose programme families do not include the IB Diploma, and the interface says why.

#### 7.4 The Extended Essay

Statuses: `draft → proposed → confirmed`, with `refine_requested` as the teacher's return path, "pass to a colleague" as a `proposed → proposed` transition that changes `target_person_id`, and `withdrawn`.

Two conditions from the pass 8 revision govern this table:

- **Which guide a round follows** (F62, §12.12). Each `ib.ee_round` names its guide (`ee_guide_key`, pass 5 D70), and the guide's `reflection_model` decides the reflection milestones: `rpf_single_statement` (the guide for first assessment 2027: one reflective statement of at most 500 words on the RPF) or `rppf_three_sessions` (the 2018 guide). Both ACS cohorts now in the programme sit their exams under the 2027 guide (this year's Grade 12 in May 2027, this year's Grade 11 in May 2028), so ACS's rounds default to `ee_2027`, and `ee_2018` is kept for resits only. The milestone rows are data per round, generated from the guide; E7 and E9 read their guard from it.
- **Who holds the record** (C10, 2026-09-24). ManageBac stays the record for CAS and the Extended Essay at a school that keeps it; CAROS reads it through the v2p3 API as a read-only mirror and adds the counselor views ManageBac lacks (pass 2 §7.4 and §7.9 design the mirror, handoff). When `core.school_module.config.extended_essay.record_system = 'managebac_readonly'` (pass 2 D10, gaining that value), E1 to E10 are disabled in CAROS and mirror rows arrive with `source = 'managebac_mirror'`; E11 (overdue, a derived nudge) still runs. Subject selection and its conversation gate stay CAROS-owned at every school.

| # | Transition | From | To | Who | Guard |
|---|---|---|---|---|---|
| E1 | Draft | no row | `draft` | student | in the Diploma cohort, programme year 1 |
| E2 | Propose or resend | `draft`, `refine_requested` | `proposed`, `target` = a teacher of the subject, `proposed_at` reset | student | subject, question and rationale all present; target is in `eeCandidates` (teaches the subject's group) |
| E3 | Accept | `proposed` | `confirmed`, `supervisor = target`, capacity stamped | the target teacher | trigger records load and over-capacity; never blocks |
| E4 | Ask for a sharper question | `proposed` | `refine_requested`, `refine_note` | the target teacher | note ≥ 10 chars |
| E5 | Pass to a colleague | `proposed` | `proposed`, new target | the target teacher | colleague in `eeCandidates`; note ≥ 10 chars |
| E6 | Assign a supervisor | `proposed`, `refine_requested`, `confirmed` | `confirmed`, `confirmed_by = coordinator` | coordinator | over the guide is allowed and recorded (invariant 8) |
| E7 | Record a reflection | `confirmed` | same; milestone completed | the supervisor (a session under `rppf_three_sessions`), or the student's statement recorded with the supervisor (under `rpf_single_statement`) | note ≥ 10 chars; milestone `rppf = true`; one per milestone; under the 2027 guide the statement is at most the guide's `reflection_word_limit` |
| E8 | Submit a draft or the final version | `confirmed` | same; milestone completed | student | file or word count present |
| E9 | Upload for assessment | `confirmed`, final submitted, the guide's reflections recorded | same; `submit` milestone completed | coordinator | every reflection milestone the round's guide requires has its row (three sessions under the 2018 guide, one statement under the 2027 guide) |
| E10 | Withdraw | any | `withdrawn` | student or coordinator | reason |
| E11 | Milestone overdue | any, due date passed, not completed | unchanged; event and nudge only | engine | `ee.milestone_overdue`; nudge to the owner of the milestone |

"Drift is not pending": E11 and the coordinator's list only count a `proposed` essay as stalled when `now - proposed_at > wait_days`.

#### 7.5 The pathway approval

| # | Transition | From | To | Who | Guard |
|---|---|---|---|---|---|
| P1 | Submit | session at `proposals` | proposal `pending`; session `submitted` | student | 1 to 3 archetypes; no other pending proposal (unique index) |
| P2 | Approve | `pending` | `approved`; an `approved_pathway` per archetype with the roadmap snapshot | counselor | |
| P3 | Amend and approve | `pending` | `amended`; approved pathways carry the amended steps | counselor | `decision_reasons` and `amendments` required |
| P4 | Send back | `pending` | `sent_back`; session reopened at `chat` with the reasons as constraints | counselor | `decision_reasons` required (the prototype captures none; the backend must, because pass 5 regenerates candidates under them) |
| P5 | Resubmit | `sent_back` | a new `pending` proposal; the old one `superseded` | student | |
| P6 | Replace an approved pathway | `approved`/`amended` | old approved pathways `active = false`, `superseded_by_id` | counselor, on a later approval | |
| P7 | Complete or uncomplete a roadmap step | approved pathway active | progress row; XP ledger row on first completion | student | XP awarded once per step (unique index) |
### DR-8 · Seed data

**Context.** Both synthetic schools are used in tests from the first week, because a second school that is unlike ACS is the only reliable way to catch ACS-shaped assumptions. The prototype's data is authored at full fidelity and must be ported, not re-invented; but its shapes (display strings, grade-keyed families, a stored run for roster students, `hrs` versus `entries`) are the ones this schema replaces.

**Decision.** `packages/seed` installs two tenants, each in two layers, through the same code paths real data will use.

**The two layers.**

1. **Facts.** SIS-shaped rows delivered through `packages/ingest` as a *fixture* source (`ingest.source_system.kind = 'fixture'`, which the classification trigger in §2.16 allows only into synthetic tenants). ACS's facts arrive as a Veracross-shaped export and Wellesmere's as an iSAMS-shaped export, so the two mapping profiles, the identity resolver and the normaliser (pass 2) are exercised from day one. The facts are generated by a deterministic pseudo-random generator seeded per tenant, so a re-seed produces the same rows, and they are *constructed to produce the prototype's authored series*: Ahmed's Mathematics assessments are generated so that the eight weekly working-grade points come out as 91, 93, 89, 92, 90, 88, 74, 41 with a personal band of 82 to 95.
2. **Narrative.** The engine's tables written directly for the authored cases: a `signal.sweep_run` with `engine_version = 'seed'`, `feature_snapshot` rows built from each authored `baselines{}` object, `evaluation` and `signal` rows for each `evidence[]` item, the case with its tier, stage, `headline`, `plain_explanation`, `suggested_action`, window, `tier_yesterday` and `moved_why`, evidence items, interventions, the two seeded audit entries that are not writes (`FILE_ACCESS`), and the seeded teacher flags with their `routed_note`. This layer exists so the frontend can be built and demonstrated before the engine exists, and it is written against the engine's schema as pass 3 D17 leaves it, so `strength` never exists in any seed (§12.11 of the pass 7 review). A test, `engine-reproduces-seed`, runs the real engine over **both tenants'** facts layers and diffs its tiers and rule hits against an expected-result list per tenant, generated by running the rules rather than written by hand (F06, F31); the list for Wellesmere's eight authored cases exists from the start, so they do not vanish when the narrative layer is retired. The narrative layer for signals is retired per tenant only when that tenant's list passes.

**Anchoring time.** The prototype's today is Monday 24 November with a 07:04 sweep, and its Extended Essay dates are offsets from that day. The seed takes an anchor date (default: the most recent Monday on or before the run date) and expresses every seeded instant as an offset from it, in the tenant's timezone, so a demo tenant re-seeded in March is fresh in March. Academic years, terms, exam periods and Extended Essay milestone dates are generated around the anchor.

**Tenant 1: ACS, ported from the prototype.** `core.school`: `slug 'acs'`, `data_classification 'synthetic'`, `branding_mode 'real_institution'` (so `demonstration_marker` is `true`), `purpose 'demo'` (§2.3; never deployed to production, DR-9), regulator `adek` (so the ADEK regulator profile applies, §2.7), timezone `Asia/Dubai`, `sis_name 'Veracross'`, `safeguarding_role_label 'Child Protection Officer'`, `counselor_title 'HS Counselor'`, brand from `SCHOOLS.acs.brand`. Every module enabled. Applying ACS's name to synthetic data, and showing that tenant to other schools in sales demos, both rest on ACS's written consent (pass 6 G2, extended to third-party sales demos by F29 and F43). The port, structure by structure:

| Prototype | Seed target |
|---|---|
| `SCHOOLS.acs` | `core.school`, `core.school_module` |
| `STAFF`, `TEACHER`, `SEL_ROUND.coordinator`, `EE_SUPERVISORS`, the teachers named in `IB_SUBJECTS.t` and `COURSES_BY_GRADE` | `core.person` (kind staff), `core.staff_profile`, `auth.membership` (counselor or teacher; a **fictional** IB coordinator, seeded as "Mr. K. Brennan", as counselor with `ib_coordinator`; Mr. Okonkwo with `safeguarding_lead` on a `staff` membership; Ms. Haddad with `caseload_lead`). The prototype's coordinator, "Mr. A. Diaz", carries the surname of the real ACS staff member PRODUCT.md names, so it is not ported (F29): no real person's name may appear as a demo persona approving fabricated records, and every real person's name in PRODUCT.md and the prototype is on the seed blocklist (pass 4 §9.11). The replacement name is checked against ACS's published staff directory before use |
| `STUDENTS` (15 authored + 72 generated) | `core.person` (student), `sis.student`, `sis.enrolment` (year group from `yr`, programme from `track`, `undecided` where absent), `auth.caseload_assignment` (all 87 to Ms. Haddad, as the prototype has it; see Q-ACS on the real split) |
| `DPC` (201) | as above, programme `ib_dp_candidate` for Grade 10, `ib_dp` for 11 and 12; `mathSet`/`mark` become a Grade 10 mathematics section with `feeder_set_key` and a term grade |
| `baselines{}`, `evidence[]`, `prio`, `prev`, `movedWhy`, `headline`, `plain`, `signal`, `window`, `context[]`, `stage`, `openedBy`, `opened`, `action{}` | narrative layer: `signal.feature_snapshot`, `signal.signal`, `signal.case` (+ histories via trigger), `signal.evidence_item`, `signal.evaluation.suppressions` from `context[]`; the prototype's `signal` (0 to 100) is **not ported**: the authored case's word maps to pass 3's `level` (D17), and no strength column exists in any seed (§12.11) |
| `weeks[]` on roster students | not stored; the facts layer generates eight in-band weeks (one soft week for the eleven `watch` students) so `signal.week_run()` reproduces them |
| `INTERVENTIONS` | `signal.intervention`, `intervention_step` from `plan[]` |
| `AUDIT` | `audit.entry` (the six seeded entries, with `detail` reduced to identifiers). Two prototype keys are mapped or dropped (F72): the seeded `CONCERN_SUBMIT` becomes `TEACHER_FLAG`, and the seeded `AI_DRAFT` "Letter draft generated" entry is dropped, because letter generation is deferred and the entry would record something the product does not do |
| `TFLAGS`, `FLAG_KINDS` | `signal.teacher_flag`; `config.vocabulary 'flag_tag'` global defaults; `routed_note` values mapped to the teacher-facing vocabulary of §2.9 (`received`, `reviewed`), which never says that a case exists (F58) |
| `S.thresh` | `config.rule_set_version 'engine.thresholds'` version 1 for ACS (`acad 2, att 3, eng 14, persist 3`) and the platform defaults |
| `APP`/`EXTRA_APP`, `STMAP`, `OFFERS`, `uni.targets[]`, `uni.flags[]` | `uni.student_target` (no probability), `uni.application`, `uni.offer`, `uni.document_request` (transcript, counselor reference, each `trefs[]` teacher reference, forms), `uni.statement` + versions (`stmt` % becomes a sectioned version under the destination's `ref.statement_format` for the seeded entry year, with sections filled so that the derived completeness matches the prototype's percentage, F32); flags are not seeded, they are derived |
| `UNI_COSTS`, `UNI_REQS`, `REQ_CHANGES`, `UNI_COURSE_REQUIREMENTS`, the `unis` list in the roster generator | `ref.institution`, `ref.course`, `ref.entry_requirement`, `ref.cost`, `ref.requirement_change`, each with a `ref.source` row whose `url` is `seed://prototype` and whose `title` says *demonstration content, unsourced*. **A `seed://` number never renders** (F30): the UI shows "not on file" wherever the only source is `seed://`, `seed://` sources are loaded in local, CI and staging only, and a production deploy check fails if any `ref.source` row there has a `seed://` URL. `ref.*` is global, so a seeded tuition figure would otherwise reach real parents |
| `COURSE_CATALOG` (ACS's own subject list for the Grade 9 guide) | per-school rows: `sis.subject` for the synthetic ACS tenant plus the guide text in `config.vocabulary 'guide_course'` (F65); never global `ref.*`, where it would appear in every school's university data |
| `PARENTS`, `PMSGS_BY_GRADE`, `PARENT_MEETINGS_BY_GRADE`, `MEETING_TOPICS`, `MEETING_SLOTS` | `core.person` (guardian), `family.guardian_link` (verified, `sis_import`), `family.message`, `core.meeting` (kind `parent_meeting`), `family.meeting_slot`, `config.vocabulary 'meeting_topic'` |
| `MEETINGS`, `AGENDA`, `TASKS` | `core.meeting`; the agenda and task list are derived views in the domain layer and are not seeded |
| `TRANSCRIPTS`, `SUBJECTS`, `IB_CORE`, `G12_IB_TIMETABLE`, `COURSES_BY_GRADE`, `getStudentClasses` | `sis.transcript`, `sis.subject`, `sis.section`, `sis.section_teacher`, `sis.section_membership`, `sis.assessment` + `sis.grade` (working and predicted, IB scale 1 to 7), `sis.timetable_period` P1 to P6 |
| `IB_GROUPS`, `IB_SUBJECTS`, `GOAL_NEEDS` | `ib.subject`, `ib.subject_level_period`, `ib.subject_teacher`, `ib.prerequisite` (MAA HL from the extended set at 85%), `config.rule_set_version 'ib.goal_alignment'` |
| `SEL_ROUND`, `SELREC` | `ib.selection_round` (opens 10 Nov, closes 5 Dec relative to the anchor), `ib.selection`, `selection_pick`, `selection_signoff`, `selection_event`; approved records get a `core.meeting` of kind `selection_review` from `talk` |
| `CAS_STRANDS`, `CAS_OUTCOMES`, `CAS_OPPS`, `CAS_TAGS`, `CAS_INTERESTS`, `CASREC` | `ib.cas_activity`, `config.vocabulary 'cas_tag'`, `ib.cas_interest`, `ib.cas_entry`: the `entries[]` become entries and reflections; `hrs` minus the entries' hours becomes one `imported_balance` row per strand covering the programme start to the earliest entry, so the ledger totals equal the prototype's `hrs` and the recent log equals its `entries` |
| `EE_MILESTONES`, `EE_ROUND`, `EEREC`, `EE_WAIT_DAYS` | `ib.ee_round` (guide `ee_2027` for both current cohorts, F62), `ib.ee_milestone` (generated from the guide: one reflective statement, where the prototype's three RPPF sessions follow the 2018 guide and are seeded only on a resit round), `ib.ee_milestone_due` (dates from the day offsets), `ib.ee_essay`, `ee_milestone_completion`, `ee_reflection`, `ee_draft`, `ee_event`. Word limit, hours and marks come from the guide row, which the coordinator confirms (F77), not from the prototype's figures |
| `ONBOARD_Q`, `ARCHETYPES`, `SUBPATH_DETAIL`, `DISCOVERY_FOLLOWUPS`, `DISCOVERY_NARROW`, `TAG_KEYWORDS` | `ref.onboarding_question`, `ref.archetype` (version 1, with `steps`, `subpaths`, `narrowing`); each step carries the programme families it applies to, so IB and AP advice reaches only students in those programmes and an approved roadmap snapshots only the steps for the student's programme (F65); the factual claims in steps go into `ref.archetype_claim` with a `seed://prototype` source and are therefore hidden by the rule that unsourced claims do not render (pass 5) |
| `SURVEY_COMPLETE`, `PENDING_APPROVALS`, `APPROVED_PATHS`, `S.roadmapProgress` | `discovery.session` (completed for s3, s9, s10, s11, s12, s17), one pending proposal, one approved pathway with a few steps done and the matching `xp_ledger` rows |
| `PS_SYSTEMS`, `PS_SUBMISSIONS`, `S.psStatements` | `uni.statement` per destination system, sectioned versions under `ref.statement_format`, one submitted review. The prototype's guidance in `PS_SYSTEMS` describes UCAS's single-essay format, which UCAS replaced with three questions from 2026 entry, so it is not ported as guidance (F32); the prototype's "AI read" score is not ported (F66, pass 6 §6.3) |
| `MENTOR_REQS`, `PARENT_MENTOR`, `NETWORK`, `PATH_ALUMNI`, `ALUMNI_OUTCOMES` | `mentor.profile` (Hassan Al Rashid, Lina Khoury; verified), `mentor.pairing`, `mentor.session_request`, `discovery.network_contact`; `PATH_ALUMNI` and `ALUMNI_OUTCOMES` are demonstration content and are seeded as a reporting fixture only, labelled synthetic |
| `AP_EXAMS` | `ref.exam_session` (board `ap`, session 2026) and `uni.ap_exam_registration` for Fahad |
| `SREFLECT` | `signal.student_reflection` |
| `METRICS` | not seeded: every figure is a target, and the reporting views compute from `events.event` |
| Demo apparatus: role switcher, grade preview, `FAMILY_STUDENT_ID`, `PARENT_ME` | not seeded; real users have memberships |

**Tenant 2: Wellesmere British School, Dubai.** A fictional British-curriculum school regulated by the KHDA. The name returned no matches for an existing school in a web search on 2026-09-22; it must be checked against the KHDA school directory and re-chosen if it collides. `core.school`: `slug 'wellesmere'`, `data_classification 'synthetic'`, `branding_mode 'unbranded'` (marker off, which is the other branch the marker rule must be seen to take), `purpose 'demo'`, regulator `khda` (with the explicit empty KHDA profile until a KHDA analysis exists, so no Abu Dhabi authority, contact, clock or citation can render, F31), timezone `Asia/Dubai`, weekend Saturday and Sunday, `sis_name 'iSAMS'`, `safeguarding_role_label 'Designated Safeguarding Lead'`, `counselor_title 'Sixth Form Pastoral Lead'`. Modules `ib_selection`, `cas`, `extended_essay` and `ap_exams` **disabled**. Year groups Year 10 to Year 13 (ordinals 10 to 13, stages `entry`, `pathway_choice`, `programme_1`, `programme_2`), programmes GCSE (Years 10 and 11, scale `gcse_9_1`) and A Level (Years 12 and 13, scale `a_level`, predicted grades like `A*AA`), three terms with half terms, six timetable periods, a school-year that begins in September, destination systems UCAS with two US Common App targets. Two counselors, twelve teachers, ~120 students on the counseling surface split ~60/60, 220 guardians (several with two children, one with children in Year 10 and Year 13, one guardian pair sharing an email address so the linkage rule is tested, and one contact carrying an imported restriction flag, F57), one DSL who also teaches (a `teacher` membership with `safeguarding_lead`). The iSAMS fixture's `TutorStaffId` and `HeadOfYear StaffId` columns are imported, not ignored (F33): they become tutor groups and pastoral assignments (`auth.pastoral_assignment` of kinds `tutor` and `year_lead`, §2.4), a Head of Sixth Form holds `ucas_adviser` for Years 12 and 13, and case ownership stays single. Eight authored cases, each teaching something ACS's cannot: a Year 11 GCSE mock dip inside a declared exam period (suppression), a mid-year transfer with no history (cold start), a Year 13 with an authorised medical absence of three weeks, a student whose only signal is a teacher concern, an EAL student with rising grades and falling attendance, a relapse inside a closed case's window, a conditional offer at risk, and a student with nothing wrong whose file must stay quiet. The facts layer is an iSAMS-shaped export.

**What the second school catches.** A checklist the UI and domain tests assert against Wellesmere: no "Grade" literal (year-group labels come from `sis.year_group`); no assumption that ordinals run 9 to 12 or that `programme_2` is ordinal 12; portal sections come from the school's `portal` rule set, so a Year 10 family does not get the near-empty Grade 9 portal and Years 10 and 11 see GCSE grades (F65); no IB navigation, coordinator queue or CAS page when the modules are off; the safeguarding label and counselor title read from the tenant; grade scales convert through `ref.grade_scale` (a `9` on GCSE is not 9%); percentages are not assumed; the weekend and school-day calendar come from the tenant; deadlines are handled per destination system, UCAS and Common App both (the seed gives Wellesmere two Common App targets, so the first version's "UCAS-only" assertion was wrong, F31); **the string "ADEK" appears on no Wellesmere screen, template or email** (F31); regulator-specific text comes only from the tenant's regulator profile; no Arabic-name or ACS-staff strings anywhere in code; the demonstration marker is off.

**A third, CI-only tenant catches the clock.** Both synthetic schools sit in `Asia/Dubai` with the same weekend, so neither can catch a hard-coded timezone or weekend (F31). CI therefore also seeds `wellesmere-shifted`: the Wellesmere fixture under `timezone = 'Europe/London'` (daylight saving, which no Gulf timezone has, and a different UTC offset, so a date computed in the wrong zone disagrees between the two tenants' expected results) and `weekend_days = '{5,6}'` (Friday and Saturday), with its own expected-result list. It is labelled a test variant, exists only in CI, and asserts that every date, school day and SLA clock comes from the tenant.

**Consequences.** The seed is the first consumer of `packages/ingest`, `packages/db` and the domain layer, which forces those interfaces to exist before any screen. Re-seeding is idempotent per tenant (`pnpm seed --tenant acs --anchor 2026-11-23`). The seed never runs against a `real` tenant: the classification trigger refuses fixture imports, and the seed command refuses a tenant whose classification is `real`.

### DR-9 · Environments, backups, point-in-time restore, restore drills

**Environments.**

| Environment | Where | Data | Topology | Deploy |
|---|---|---|---|---|
| Local | Docker Compose: PostgreSQL 17, Azurite (blob), Mailpit (email) | both synthetic tenants | web + worker as processes | `pnpm dev` |
| CI | GitHub Actions with a PostgreSQL 17 service container | migrations from zero, then both tenants | migrations, seed, unit, RLS suite, contract tests, Playwright | every pull request |
| Staging | Azure subscription `caros-staging`, UAE North | synthetic only, both tenants; never real data; maps only CAROS test domains, never a school's Google domain (F43) | Flexible Server `B2ms` without HA, one Container Apps replica per app, no WAF, same Key Vault and Monitor wiring as production. It is also the sales demo (pass 6 decision C4): a **pinned demo revision** (a Container Apps revision label) serves a demo tenant that no drill, load test or retest touches, with a deploy freeze during booked demos; a separate demo environment is split out only if demos become frequent (F43) | on merge to `main`, migrations job then revision swap on the unpinned revision |
| Drills | its own subscription, `caros-drills`, UAE North | synthetic only | scratch servers for the restore and offboarding drills, created and destroyed per drill (F43) | per drill |
| Production | Azure subscription `caros-prod`, UAE North (+ UAE Central access granted) | real tenants (`purpose = 'customer'`) and **only one kind of synthetic tenant: the unbranded canary pair** (`purpose = 'canary'`, `branding_mode 'unbranded'`, AI off, no deliverable email address), which exists to test isolation (pass 6 decision C6, F42). No branded synthetic tenant and no demo or training tenant under a school's name runs in production; counselors train on staging | DR-1 topology | on a release tag; migrations job must succeed before the new revision receives traffic; previous revision kept for instant rollback |
| Isolated single-school | its own subscription, from the same Terraform module with `deployment_mode = "single"` | one real tenant | DR-1 topology | as production |

Infrastructure is Terraform (or OpenTofu) with the `azurerm` provider, state in a UAE North storage account with versioning; `terraform plan` output is posted on every infrastructure pull request and `apply` runs only from `main`. Developers have no standing access to the production database; a support grant (§2.4) is the only path, and every read under it is audited. No machine that runs a coding agent holds a production credential or a signed-in production browser profile (F23).

**The canary** (F42) is a Container Apps job in UAE North, not a CI step on GitHub-hosted runners. It calls domain functions through `withTenant()` as a canary membership, refuses to run against any tenant whose `purpose` is not `canary`, and asserts that every row it reads carries its own school id. Because it runs in production with production identity, its output is aggregates and pass or fail only.

**Migrations in production.** Expand-and-contract: a release may add tables, columns, indexes (created `CONCURRENTLY` through the migration job's non-transactional step, DR-2, and only where a table is large enough to need it) and policies; a release never drops or renames anything the previous revision still reads, and the drop lands two releases later. `lock_timeout` is set to five seconds in the migration job so a blocked DDL fails fast instead of queueing behind traffic. Rollback is redeploying the previous revision; the schema is forward-compatible by construction.

**Backups.** All inside the UAE.

| Layer | Mechanism | Setting | Source |
|---|---|---|---|
| Point-in-time restore | Flexible Server automated backups | retention **35 days** (the maximum); restore to any second within it into a new server in UAE North | "The default backup retention period is seven days, but you can extend the period to a maximum of 35 days" ([backup concepts](https://learn.microsoft.com/en-us/azure/postgresql/backup-restore/concepts-backup-restore)) |
| In-country geo-redundancy | geo-redundant backup, enabled at server creation | copies to the paired region, UAE Central; geo-restore creates a new server there from the latest available backup (no point-in-time on the geo copy; RPO up to one hour) | same page: "the service replicates the data to a geo-paired region"; "PITR of geo-redundant backups isn't available"; "up to one hour of RPO" |
| Long-term retention | Azure Backup vaulted backups for PostgreSQL flexible server | weekly full, retained one year rolling plus a yearly copy for the number of years counsel sets; restore is *to files*, into a scratch server; supported up to 1 TB per server, which year 3 approaches | "retains backups for up to 10 years"; "Vaulted backup restores are only available as Restore to Files"; "supported for server size <= 1 TB" ([overview](https://learn.microsoft.com/en-us/azure/backup/backup-azure-database-postgresql-flex-overview), [support matrix](https://learn.microsoft.com/en-us/azure/backup/backup-azure-database-postgresql-flex-support-matrix)) |
| Documents and letters | Blob ZRS with soft delete and versioning; nightly copy to a GRS container (secondary in UAE Central) | 30-day soft delete; object versions kept per retention class | [storage redundancy](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy) |
| Raw SIS exports | immutable container with a time-based retention policy equal to the `raw_import` retention class | proposed 90 days; then deleted by policy | [immutable storage](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview) |
| Audit integrity | weekly job recomputes the hash chain per school and alerts on a break | | §2.19 |

What this does not cover: the loss of both Dubai and Abu Dhabi. An encrypted cold copy in an EU region would cover it and would move student data out of the country. It is the first item in §5 and is not decided here, and pass 8 corrects how it was framed (F22): a copy encrypted under a key that exists only in the UAE cannot be decrypted in the disaster it exists for, because the key is lost with the country, and Key Vault backups restore only inside the same Azure geography. The real choice for ACS and counsel is therefore (a) EU ciphertext with key material held outside the UAE (a Managed HSM replica in an EU region, or security-domain shares held abroad by named people), a named restore region and trigger, and a restore drill in that region on synthetic data; or (b) in-country only, with the country-level risk stated in the DPA. Either way ADEK's explicit consent under its Digital Policy 7.1.3.a comes first (F04; pass 4 §9.7).

**Restore drills.** Quarterly, scripted in `docs/runbooks/restore-drill.md` and `tooling/restore-drill/`, the first one before any real data arrives, each one recorded with the date, the operator, the recovery time and point achieved, and every surprise. Drills on synthetic data run in the `caros-drills` subscription, never on staging, which is also the sales demo (F43); drills of production backups restore into isolated scratch servers inside the production subscription. Every check that reads restored data runs as a job in UAE North, so only aggregates and pass or fail leave the region (F23):

1. **Point-in-time** to one hour ago, into a new UAE North server. Checks: row counts per tenant table against the registry; the latest `signal.sweep_run` present; `audit.entry` chain verifies; the RLS suite passes against the restored server; the worker starts against it in a read-only mode and completes a dry sweep.
2. **Geo-restore** into UAE Central from the geo-redundant backup, same checks. Requires the region access grant; until it is granted this drill cannot run, which is why the request goes in during week one.
3. **Long-term** restore-to-files of the most recent weekly vaulted backup, loaded into a scratch server, same checks.
4. **Single-tenant extraction**: from the point-in-time server, copy one school's rows into an empty database, table by table in foreign-key order using `privacy.table_registry`, and prove the copy passes the RLS suite as that tenant. This is the procedure for "restore school X to yesterday without touching school Y", and it must be practised, because the first time it is needed will not be a drill.
5. **Blob restore** of a deleted document version and of the raw-import archive from the GRS copy.

Any drill that fails its checks opens a blocking issue; a drill that has not been run in the last quarter blocks the next production deploy (a CI check reads the drill log).
## 2. The schema, as DDL

### 2.1 Conventions that every table follows

The DDL below is written for PostgreSQL 17 and is the source the first migrations are generated from. It is long because it is complete; it is not meant to be applied in one migration (see DR-2 and pass 6 for the phasing).

1. **Every tenant table carries `school_id`** as its first column, `NOT NULL`, referencing `core.school(id)`. Tables without `school_id` exist only in the `ref` schema (global reference data) and in `auth` for global role definitions.
2. **Composite foreign keys.** Every tenant table has `UNIQUE (school_id, id)`. A foreign key from one tenant table to another always includes the school: `FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)`. A row therefore cannot reference a row in another school even if application code passes the wrong id. This is the structural half of tenancy; row-level security (2.22) is the runtime half.
3. **Identifiers** are `uuid` generated by `gen_random_uuid()`. SIS identifiers are stored separately (`sis.external_identity`) and never used as primary keys.
4. **Time.** `timestamptz` for instants, `date` for school-calendar facts (a school day, a due date), and the school's `timezone` (IANA) for rendering. No display strings are stored: "13 Nov, 07:04" becomes `opened_at timestamptz`; "6 weeks ago" is computed from `held_at`; "in 18 days" is computed from `due_on` against `core.school_today(school_id)`.
5. **Append-only tables** (`audit.entry`, `events.event`, `signal.case_tier_history`, `signal.case_note`, every `*_event` log) have a trigger that raises on `UPDATE` or `DELETE`, and the application role holds no `UPDATE`/`DELETE` privilege on them.
6. **Vocabularies.** Vocabularies that are product invariants are `ENUM` types (`signal.tier`, `signal.domain`, `signal.run_cell`, `signal.case_stage`). Vocabularies a school may extend (flag tags, intervention types, meeting topics, context kinds, behaviour categories) are tables with `school_id NULL` meaning "global default" and a per-school row meaning an override or addition.
7. **Versioned configuration** lives in `config.rule_set_version` (engine thresholds, list-balance policy, reference SLA policy, CAS expectations, EE capacity, goal-alignment rules) and `ingest.mapping_profile`. Signals reference the exact version they were produced under.
8. **Derived values are not columns.** Anything listed in DR-6 as "never stored" is a `VIEW` or a function. Materialised values carry the version of the rule that produced them and `computed_at`.
9. **Soft deletion** is `deleted_at timestamptz NULL` on user-authored, correctable records only (drafts, targets, catalogue rows). Facts imported from the SIS are superseded, never deleted (`superseded_by_import_id`). Personal data is erased through `privacy.erasure_request`, which tombstones `core.person` and scrubs the columns listed in `privacy.table_registry`.
10. **Every table is registered** in `privacy.table_registry` with its data class, its subject column, its PII columns and its retention class. A test fails the build if a tenant table is missing from the registry or lacks RLS.
11. **Writes are column-level** (pass 8, F15, F17). No user tier holds table-wide `UPDATE`. Each tier's writable columns per table are listed in `privacy.table_registry.writable_columns`, and the grants in §2.22 are generated from that list. Columns that carry a state or an authority (`status`, `approved_*`, `review_meeting_*`, `verified_at`, `activation_status`, `storage_key`, `share_scope`, any `*_by_person_id`) are written only by `SECURITY DEFINER` transition functions that check the actor and the from-state.
12. **Every `SECURITY DEFINER` function** is owned by `caros_policy` (or `caros_jobs` for the queue), pins `search_path`, restricts itself to `auth.current_school()`, and has `EXECUTE` revoked from `PUBLIC` and granted to named tiers only (F75). A convention test lists every definer function and fails on one executable by `PUBLIC`.
13. **No materialised view** in a schema a tier can read (F34, DR-6); every view is `security_invoker` unless it is a named projection view (§2.4a), which is a definer view with its own role check.
14. **`updated_at` is maintained by trigger** (§12.3 of the pass 7 review): §2.22 attaches `core.touch_updated_at()` to every table that has the column, and the convention test fails on one without it.
15. **Vocabularies, not CHECK lists, for anything a school may differ on** (F65): source systems, engagement sources, programme families and destination systems are reference or vocabulary tables. CHECK lists remain only for vocabularies that are product logic.

```sql
-- ============================================================================
-- 2.2 Extensions, schemas, roles
-- ============================================================================
-- The DDL is ordered by schema for reading, so helper functions reference tables
-- that are created later. SQL-language function bodies are validated at
-- creation time unless this is off; the migration runner sets it, then
-- validates every function with a smoke call at the end.
SET check_function_bodies = off;

CREATE EXTENSION IF NOT EXISTS citext;      -- case-insensitive email
CREATE EXTENSION IF NOT EXISTS pgcrypto;    -- digest() for the audit hash chain
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- exclusion constraints on date ranges

CREATE SCHEMA core;       -- tenant, people, calendar-independent identity
CREATE SCHEMA auth;       -- roles, permissions, memberships, RLS helpers
CREATE SCHEMA sis;        -- the academic record as imported from the school
CREATE SCHEMA engagement; -- platform and LMS activity (privacy-sensitive, short retention)
CREATE SCHEMA ref;        -- global reference data, every row sourced
CREATE SCHEMA config;     -- versioned rule tables and vocabularies
CREATE SCHEMA signal;     -- the engine's outputs, cases, evidence, interventions
CREATE SCHEMA ib;         -- subject selection, CAS, Extended Essay
CREATE SCHEMA uni;        -- university journey, documents, statements, letters
CREATE SCHEMA discovery;  -- pathway discovery, approvals, roadmap, XP
CREATE SCHEMA family;     -- guardians, messages, meeting requests
CREATE SCHEMA mentor;     -- alumni mentors, requests, sessions
CREATE SCHEMA doc;        -- file metadata (bytes live in object storage)
CREATE SCHEMA ingest;     -- imports, mapping profiles, rejections
CREATE SCHEMA ai;         -- model configuration and generations
CREATE SCHEMA notify;     -- transactional outbox
CREATE SCHEMA audit;      -- append-only audit log (changes and access)
CREATE SCHEMA events;     -- append-only product event stream (reporting)
CREATE SCHEMA privacy;    -- table registry, retention classes, erasure
CREATE SCHEMA reporting;  -- per-tenant aggregate tables under RLS, one writer (DR-6, F34)
CREATE SCHEMA jobs;       -- jobs.enqueue(): the only way a tier puts work on the queue (DR-2, F36)
-- pg-boss creates and owns its own `pgboss` schema, as caros_jobs.

-- Ownership and privilege tiers (revised by pass 8: F01, §12.2, F36, F44, F75).
-- caros_owner owns every object and cannot log in; the migrations job logs in
-- as caros_migrator and runs SET ROLE caros_owner. Each deployable has its own
-- LOGIN role and managed identity, granted only the tiers it may assume
-- (DR-4 table). Every login role is NOINHERIT, so a connection that skips
-- SET LOCAL ROLE holds no table privilege. A new product role is a row in
-- auth.role mapped onto one of these tiers, not a new database role.
CREATE ROLE caros_owner    NOLOGIN;
CREATE ROLE caros_migrator LOGIN NOINHERIT NOBYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE caros_web      LOGIN NOINHERIT NOBYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE caros_worker   LOGIN NOINHERIT NOBYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE caros_support  LOGIN NOINHERIT NOBYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE caros_jobs     LOGIN NOINHERIT NOBYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE caros_t_staff    NOLOGIN NOBYPASSRLS;  -- counselors, school administrators, capability-only staff
CREATE ROLE caros_t_teacher  NOLOGIN NOBYPASSRLS;  -- teachers: own column rules (F75)
CREATE ROLE caros_t_student  NOLOGIN NOBYPASSRLS;
CREATE ROLE caros_t_guardian NOLOGIN NOBYPASSRLS;
CREATE ROLE caros_t_mentor   NOLOGIN NOBYPASSRLS;
CREATE ROLE caros_t_ai       NOLOGIN NOBYPASSRLS;  -- AI retrieval; grants generated from an allowlist (pass 4 D55, F44)
CREATE ROLE caros_t_system   NOLOGIN NOBYPASSRLS;  -- the worker (sweep, imports, notifications)
CREATE ROLE caros_t_support  NOLOGIN NOBYPASSRLS;  -- CAROS staff under a school-approved grant, always audited
GRANT caros_owner TO caros_migrator;
GRANT caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_ai
  TO caros_web;
GRANT caros_t_system, caros_t_ai TO caros_worker;   -- ai only for AI jobs run as the case owner (F44)
GRANT caros_t_support TO caros_support;
-- caros_jobs is granted no tier. It owns the pgboss and jobs schemas and nothing else.
-- The one role that bypasses RLS. It owns the SECURITY DEFINER helpers that the
-- policies call (they must read membership tables without being filtered by
-- the very policies they implement, or Postgres reports infinite recursion)
-- and the trigger functions that write history and audit rows on a user's
-- behalf. Nothing logs in as it, and every helper it owns restricts itself to
-- auth.current_school() explicitly.
CREATE ROLE caros_policy NOLOGIN BYPASSRLS;

-- ============================================================================
-- 2.3 core: the tenant and the people in it
-- ============================================================================
CREATE TYPE core.data_classification AS ENUM ('synthetic', 'real');
CREATE TYPE core.branding_mode       AS ENUM ('unbranded', 'real_institution');
CREATE TYPE core.regulator           AS ENUM ('adek', 'khda', 'spea', 'moe_uae', 'other');
CREATE TYPE core.person_kind         AS ENUM ('staff', 'student', 'guardian', 'mentor', 'system');
CREATE TYPE core.person_status       AS ENUM ('active', 'inactive', 'left', 'erased');

CREATE TABLE core.school (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug                   text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9-]{2,40}$'),
  legal_name             text NOT NULL,
  display_name           text NOT NULL,           -- "American Community School of Abu Dhabi"
  short_name             text NOT NULL,           -- "ACS Abu Dhabi"
  initials               text NOT NULL,           -- "ACS"
  country_iso            char(2) NOT NULL,        -- 'AE'
  region_label           text,                    -- "Abu Dhabi"
  regulator              core.regulator NOT NULL, -- read through ref.regulator_profile (§2.7, F31); nothing hard-codes a regulator
  timezone               text NOT NULL,           -- 'Asia/Dubai'
  locale                 text NOT NULL DEFAULT 'en-GB',
  weekend_days           smallint[] NOT NULL DEFAULT '{6,7}', -- ISO weekday numbers; UAE schools: Sat=6, Sun=7 (assumption, see Q-ACS); never read from anywhere but here (F31's CI variant tests it)
  curriculum_note        text,
  sis_name               text NOT NULL,           -- "Veracross", "iSAMS": the word the UI prints
  safeguarding_role_label text NOT NULL,          -- "Child Protection Officer" | "Designated Safeguarding Lead"
  counselor_title        text NOT NULL DEFAULT 'Counselor',
  brand                  jsonb NOT NULL DEFAULT '{}'::jsonb, -- {primary, primaryDeep, accent}; letterhead only, never data
  mark_file_id           uuid,                    -- FK added after doc.file exists
  data_classification    core.data_classification NOT NULL,
  branding_mode          core.branding_mode NOT NULL DEFAULT 'unbranded',
  -- The demonstration-data marker is a rule, not a flag anyone can switch off:
  -- it is on whenever a real institution's name sits over synthetic data.
  demonstration_marker   boolean GENERATED ALWAYS AS
                         (data_classification = 'synthetic' AND branding_mode = 'real_institution') STORED,
  -- What the tenant is for (F42). Reports, indicators, cost boards and alerts
  -- key on this, never on a name or a flag that could hide a real school.
  purpose                text NOT NULL CHECK (purpose IN ('customer','canary','demo')),
  -- One status model for every pass (F36). Scheduling and alerting key on
  -- "holds data": status IN ('shadow','live'). onboarding: no real data yet;
  -- shadow: real data, engine in shadow mode (from G-REAL); live: from G-LIVE;
  -- offboarding: the 30-day read-only exit window; offboarded is terminal, and
  -- the row is never deleted, because audit and events keep its id.
  status                 text NOT NULL DEFAULT 'onboarding'
                         CHECK (status IN ('onboarding','shadow','live','suspended','offboarding','offboarded')),
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  CHECK (purpose <> 'customer' OR data_classification = 'real'),
  CHECK (purpose = 'customer' OR data_classification = 'synthetic'),
  CHECK (purpose <> 'canary' OR branding_mode = 'unbranded')
);

-- A tenant's classification, purpose and branding never change (F42, F67). A
-- demo that becomes a customer is a new tenant with a fresh id, an import, and
-- no synthetic rows to forget. For a synthetic tenant the letterhead (names,
-- initials, brand, mark) is also CAROS-only, written by a migration and never
-- by the school's own configuration, so a real institution's name and crest
-- cannot be put over synthetic data with the marker off, and the marker cannot
-- be switched off by relabelling the tenant.
CREATE FUNCTION core.forbid_reclassification() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.data_classification <> OLD.data_classification
     OR NEW.purpose <> OLD.purpose
     OR NEW.branding_mode <> OLD.branding_mode THEN
    RAISE EXCEPTION 'core.school classification, purpose and branding_mode are immutable (school %)', OLD.id;
  END IF;
  IF OLD.data_classification = 'synthetic' AND auth.actor_kind() <> 'migration'
     AND (NEW.legal_name, NEW.display_name, NEW.short_name, NEW.initials, NEW.brand, NEW.mark_file_id)
         IS DISTINCT FROM (OLD.legal_name, OLD.display_name, OLD.short_name, OLD.initials, OLD.brand, OLD.mark_file_id) THEN
    RAISE EXCEPTION 'a synthetic tenant''s letterhead is changed only by a CAROS migration (school %)', OLD.id;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER school_classification_immutable BEFORE UPDATE ON core.school
  FOR EACH ROW EXECUTE FUNCTION core.forbid_reclassification();

-- Status moves forward only along the model above; entering shadow on a real
-- tenant needs the legal-basis attestation (pass 4 D45 adds the column and the
-- check); entering live needs the recorded G-LIVE sign-off (pass 6).
CREATE FUNCTION core.check_status_move() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
       (OLD.status, NEW.status) IN (('onboarding','shadow'), ('shadow','live'), ('live','suspended'),
                                    ('shadow','suspended'), ('suspended','live'), ('suspended','shadow'),
                                    ('onboarding','offboarding'), ('shadow','offboarding'), ('live','offboarding'),
                                    ('suspended','offboarding'), ('offboarding','offboarded'))) THEN
    RAISE EXCEPTION 'core.school.status cannot move from % to %', OLD.status, NEW.status;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER school_status_move BEFORE UPDATE OF status ON core.school
  FOR EACH ROW EXECUTE FUNCTION core.check_status_move();

CREATE TABLE core.school_module (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  module_key  text NOT NULL CHECK (module_key IN (
                'signals','cases','teacher_flags','university','ib_selection','cas','extended_essay',
                'ap_exams','discovery','personal_statement','letters','mentors','family_portal','copilot')),
  enabled     boolean NOT NULL DEFAULT false,
  config      jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (school_id, module_key)
);

CREATE TABLE core.person (
  school_id        uuid NOT NULL REFERENCES core.school (id),
  id               uuid NOT NULL DEFAULT gen_random_uuid(),
  kind             core.person_kind NOT NULL,
  given_name       text NOT NULL,
  family_name      text NOT NULL,
  preferred_name   text,
  title            text,                          -- "Ms.", "Dr." (staff)
  email            citext,                        -- Google identity for staff/students; magic-link address for guardians
  google_subject   text,                          -- the stable Google `sub`, never the email
  phone            text,
  language_pref    text,                          -- "ar", "en"
  status           core.person_status NOT NULL DEFAULT 'active',
  erased_at        timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (school_id, id),
  UNIQUE (school_id, google_subject)
);
-- An email identifies one person, except for guardians: two SIS contacts who
-- share an address stay two persons (F57), so a restriction on one parent can
-- be applied without cutting off the other (pass 4 §2.2).
CREATE UNIQUE INDEX person_email_unique ON core.person (school_id, email) WHERE kind <> 'guardian';
CREATE INDEX person_school_kind ON core.person (school_id, kind);

CREATE TABLE core.staff_profile (
  school_id     uuid NOT NULL,
  person_id     uuid NOT NULL,
  job_title     text,                             -- "HS Counselor", "Mathematics teacher"
  department    text,                             -- "High School Counseling"
  subject_area  text,
  initials      text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (person_id),
  UNIQUE (school_id, person_id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);

-- "Today" for a school is a date in its own timezone, not the server's.
CREATE FUNCTION core.school_today(p_school uuid) RETURNS date LANGUAGE sql STABLE AS $$
  SELECT (now() AT TIME ZONE s.timezone)::date FROM core.school s WHERE s.id = p_school
$$;

-- Attached in §2.22 to every table with an updated_at column (§12.3 of the pass 7 review).
CREATE FUNCTION core.touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END $$;

CREATE FUNCTION core.forbid_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION '% is append-only', TG_TABLE_NAME; END $$;

-- ============================================================================
-- 2.4 auth: roles, permissions, memberships, scopes. Permissions are data.
-- ============================================================================
CREATE TYPE auth.privilege_tier AS ENUM ('staff','teacher','student','guardian','mentor','ai','system','support');
CREATE TYPE auth.perm_action    AS ENUM ('read','write','approve','escalate','configure');  -- pass 4 D34 adds 'export'
CREATE TYPE auth.perm_scope     AS ENUM (
  'school',            -- every row in the school
  'caseload',          -- students assigned to the acting counselor (primary or cover)
  'roster',            -- students in a section the acting teacher teaches
  'own_section',       -- rows belonging to a section the acting teacher teaches
  'subject_teacher',   -- rows for an IB subject the acting teacher is a listed teacher of
  'ee_party',          -- Extended Essays where the acting teacher is target or supervisor
  'self',              -- the acting student's own rows
  'linked_children',   -- students the acting guardian is verifiedly and actively linked to
  'paired',            -- students the acting mentor has an accepted pairing with
  'author',            -- rows the acting person authored
  'ib_cohort',         -- the Diploma cohort; requires the ib_coordinator capability
  -- Added by pass 8 (F02, F33, F59). Pass 4's matrix names these and the first
  -- version had no way to store them.
  'esc',               -- students with an escalation the acting person is a route recipient of, while it is open and for its esc window
  'addressee',         -- rows addressed to the acting person (a recipient column)
  'lead_cover',        -- the caseload lead, only while a cover or a recent reassignment for that student is active
  'own_pairing',       -- rows of a pairing in which the acting person is the mentor
  'year_group',        -- students enrolled in a year group the acting person holds a year_lead or ucas_adviser assignment for
  'tutor_group'        -- students in a tutor group the acting person tutors
);

-- The order the narrowing trigger (pass 4 D36) uses to decide what "wider"
-- means (F47). Scopes are not totally ordered, so they are ranked: a school
-- row may keep a default's scope or replace it with one of lower rank, never
-- one of the same rank that is different, and never one of higher rank.
CREATE FUNCTION auth.scope_rank(p auth.perm_scope) RETURNS smallint LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE p
    WHEN 'self' THEN 1 WHEN 'author' THEN 1 WHEN 'addressee' THEN 1 WHEN 'own_pairing' THEN 1
    WHEN 'paired' THEN 1 WHEN 'linked_children' THEN 1
    WHEN 'roster' THEN 2 WHEN 'own_section' THEN 2 WHEN 'subject_teacher' THEN 2 WHEN 'ee_party' THEN 2
    WHEN 'esc' THEN 2 WHEN 'tutor_group' THEN 2 WHEN 'lead_cover' THEN 2
    WHEN 'caseload' THEN 3 WHEN 'ib_cohort' THEN 3 WHEN 'year_group' THEN 3
    WHEN 'school' THEN 4 END $$;

CREATE TABLE auth.data_class (
  key         text PRIMARY KEY,
  description text NOT NULL
);
-- pass 4 D33 adds `sensitivity`; pass 3 D30 and pass 4 D33 add signal_shadow,
-- counselor_log and fairness_label. The pass 8 revision splits `config` and
-- `family` and adds three classes, because a class bound to a whole table let
-- families and students read staff material (F15, F16, F13, F77).
INSERT INTO auth.data_class VALUES
 ('reference','Vocabularies, templates, module flags: readable by every role'),
 ('directory','Names, year group, section membership, contact details'),
 ('academic','Grades, assessments, predicted grades, transcripts'),
 ('attendance','Attendance and punctuality events with reasons'),
 ('behaviour','Behaviour incidents and conduct points'),
 ('engagement','Platform and LMS activity'),
 ('signal','Signals, tiers, evidence, feature snapshots, live case state'),
 ('case_note','Counselor notes on a case'),
 ('contact_record','Recorded meetings and the counselor''s contact log: staff-only notes about conversations (F15)'),
 ('safeguarding','Escalations to the safeguarding lead, their updates and outcomes'),
 ('safety_alert','Alerts raised by the safety screen on a student''s words: staff-only (F13)'),
 ('teacher_flag','Concerns, positive notes, context and safeguarding referrals logged by teachers'),
 ('student_voice','Free text a student writes to staff (reflections, chat)'),
 ('family','Messages between guardians and staff, meeting requests'),
 ('guardian_link','Who is linked to which student, and the activation of that link (F15)'),
 ('ib','Subject selections, sign-offs, CAS, Extended Essay'),
 ('university','Targets, applications, offers, documents, statements, letters'),
 ('discovery','Survey, chat, pathway proposals, roadmap progress'),
 ('xp','Points and milestones the student earns: student-only gamification (F77, invariant 10)'),
 ('mentor','Mentor profiles, requests, sessions, messages, notes'),
 ('documents','File metadata; each row also carries its own subject class (F15)'),
 ('config','School configuration, rule sets and vocabularies'),
 ('membership','Memberships, capabilities, caseload, cover and pastoral assignments (F16)'),
 ('session','Sessions, magic links, activation codes (F16)'),
 ('notification','Outbox rows, in-app notices and preferences: the addressee''s only (F16)'),
 ('support_grant','CAROS support grants (F35)'),
 ('privacy_request','Erasure, subject-access and restriction requests'),
 ('ingest','Imports, mapping profiles, rejections'),
 ('ai','AI generations and model configuration'),
 ('audit','Audit entries'),
 ('reporting','Aggregate reporting');

CREATE TABLE auth.role (
  key            text PRIMARY KEY,                -- the five product roles, plus school_admin and staff (§0.1)
  label          text NOT NULL,
  tier           auth.privilege_tier NOT NULL,
  is_staff       boolean NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);
INSERT INTO auth.role (key, label, tier, is_staff) VALUES
 ('counselor','Counselor','staff',true),
 ('teacher','Teacher','teacher',true),
 ('student','Student','student',false),
 ('parent','Parent or guardian','guardian',false),
 ('mentor','Alumni mentor','mentor',false),
 -- pass 8 (F16): the school's IT or registrar administrator, with no caseload path
 ('school_admin','School administrator','staff',true),
 -- pass 8 (F10, F16): staff who are neither counselors nor teachers (a Principal,
 -- a CPO in the leadership team); no data access of its own, it only carries capabilities
 ('staff','Staff member','staff',true);

-- Capabilities are refinements held by a specific membership, not roles of
-- their own: the IB coordinator is a counselor with `ib_coordinator`; the Child
-- Protection Officer is any staff member with `safeguarding_lead` (F10).
CREATE TABLE auth.capability (
  key                text PRIMARY KEY,
  allowed_role_keys  text[] NOT NULL,             -- the roles whose memberships may carry it
  description        text NOT NULL
);
INSERT INTO auth.capability VALUES
 ('ib_coordinator','{counselor}','Sees and decides the whole Diploma cohort''s selections, CAS and Extended Essays'),
 ('caseload_lead','{counselor}','Reassigns cases, grants planned cover, edits engine thresholds and the case lifecycle'),
 ('safeguarding_lead','{counselor,teacher,school_admin,staff}','Receives and acknowledges safeguarding escalations: the CPO and the deputies in the route'),
 ('safeguarding_oversight','{counselor,teacher,school_admin,staff}','Told when a referral is unacknowledged; no data grant of any kind (F16)'),
 ('year_lead','{counselor,teacher,staff}','Pastoral responsibility for a year group (Head of Year); F33'),
 ('tutor','{teacher}','Responsibility for a tutor group (form tutor); F33'),
 ('ucas_adviser','{counselor,teacher,staff}','University applications for the year groups assigned (Head of Sixth Form, UCAS adviser); F33');
-- pass 4 D35 adds mentor_coordinator ('{counselor}').

-- The permission matrix. school_id NULL is the global default; a school row
-- with the same (role_key, data_class, action, capability, row_kind) replaces
-- the default rows for that key, and may only narrow them (pass 4 D36, F47).
-- Pass 4 §3.6 owns the content, compiled into rows through §2.4a and seeded by
-- B0.7. The first version's inline default rows are withdrawn: pass 4 D36
-- deleted them anyway, and several contradicted decisions taken since (F15, F16).
CREATE TABLE auth.role_permission (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   uuid REFERENCES core.school (id),   -- NULL = default for every school
  role_key    text NOT NULL REFERENCES auth.role (key),
  data_class  text NOT NULL REFERENCES auth.data_class (key),
  action      auth.perm_action NOT NULL,
  scope       auth.perm_scope NOT NULL,
  capability  text REFERENCES auth.capability (key), -- NULL = any membership with the role
  row_kind    text,                               -- NULL = every row; otherwise only rows whose kind expression equals it (F02)
  -- scope and row kind are part of the key (F02): pass 4's matrix gives one
  -- role two scopes for the same class and action, which the first key refused
  UNIQUE NULLS NOT DISTINCT (school_id, role_key, data_class, action, scope, capability, row_kind)
);

CREATE TABLE auth.membership (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id     uuid NOT NULL,
  role_key      text NOT NULL REFERENCES auth.role (key),
  capabilities  text[] NOT NULL DEFAULT '{}',     -- written only by auth.confirm_capability() (below)
  status        text NOT NULL DEFAULT 'active' CHECK (status IN ('invited','active','suspended','ended')),
  started_at    timestamptz NOT NULL DEFAULT now(),
  ended_at      timestamptz,
  source        text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','import','sso_jit')),  -- pass 4 D38 removes sso_jit
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (school_id, id),
  UNIQUE (school_id, person_id, role_key),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);
CREATE INDEX membership_lookup ON auth.membership (school_id, person_id, role_key) WHERE status = 'active';

-- Four eyes for every capability grant (F16). A school_admin requests; a
-- different school_admin confirms; nobody confirms a grant to themselves. Only
-- auth.confirm_capability() (definer) writes membership.capabilities, and a
-- trigger checks the capability's allowed_role_keys.
CREATE TABLE auth.capability_grant (
  school_id               uuid NOT NULL REFERENCES core.school (id),
  id                      uuid NOT NULL DEFAULT gen_random_uuid(),
  membership_id           uuid NOT NULL,
  capability              text NOT NULL REFERENCES auth.capability (key),
  requested_by_person_id  uuid NOT NULL,
  requested_at            timestamptz NOT NULL DEFAULT now(),
  confirmed_by_person_id  uuid,
  confirmed_at            timestamptz,
  ended_by_person_id      uuid,
  ended_at                timestamptz,
  reason                  text NOT NULL CHECK (char_length(reason) >= 10),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, membership_id) REFERENCES auth.membership (school_id, id),
  CHECK (confirmed_by_person_id IS NULL OR confirmed_by_person_id <> requested_by_person_id)
);

-- Who counsels whom. Cover is an assignment of kind 'cover' with an end and a
-- reason; it is what makes handover visible rather than informal (pass 4 §3.3
-- owns the approval path). Validity is in timestamps, not dates, so "24 hours"
-- means 24 hours (F16).
CREATE TABLE auth.caseload_assignment (
  school_id            uuid NOT NULL REFERENCES core.school (id),
  id                   uuid NOT NULL DEFAULT gen_random_uuid(),
  counselor_person_id  uuid NOT NULL,
  student_id           uuid NOT NULL,
  kind                 text NOT NULL DEFAULT 'primary' CHECK (kind IN ('primary','cover')),
  valid_from           timestamptz NOT NULL,
  valid_to             timestamptz,               -- NULL = open-ended (primary only; pass 4 D43)
  reason               text,                      -- required for cover
  assigned_by          uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (school_id, id),
  FOREIGN KEY (school_id, counselor_person_id) REFERENCES core.person (school_id, id),
  -- FK to sis.student added in 2.5 after the table exists
  CHECK (valid_to IS NULL OR valid_to >= valid_from),
  CHECK (kind = 'primary' OR reason IS NOT NULL)
);
-- one primary counselor per student at a time: case ownership stays single even
-- where tutors, year leads and advisers share pastoral responsibility (F33)
CREATE UNIQUE INDEX caseload_one_primary ON auth.caseload_assignment (school_id, student_id)
  WHERE kind = 'primary' AND valid_to IS NULL;
CREATE INDEX caseload_by_counselor ON auth.caseload_assignment (school_id, counselor_person_id, student_id);

-- Concurrent pastoral responsibility, for schools whose structure is not one
-- counselor per student (F33): form tutors, Heads of Year, a Head of Sixth Form
-- or UCAS adviser. Imported where the SIS carries it (iSAMS TutorStaffId,
-- HeadOfYear StaffId), or granted by a school_admin. It gives read scopes
-- (`year_group`, `tutor_group`), never case ownership.
CREATE TABLE auth.pastoral_assignment (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id             uuid NOT NULL,
  kind                  text NOT NULL CHECK (kind IN ('year_lead','tutor','ucas_adviser')),
  year_group_id         uuid,
  tutor_group_id        uuid,
  valid_from            timestamptz NOT NULL,
  valid_to              timestamptz,
  source                text NOT NULL CHECK (source IN ('import','manual')),
  import_id             uuid,
  assigned_by_person_id uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id),
  -- FKs to sis.year_group and sis.tutor_group added in 2.5
  CHECK ((kind = 'tutor') = (tutor_group_id IS NOT NULL)),
  CHECK (kind = 'tutor' OR year_group_id IS NOT NULL)
);

-- CAROS support grants. Never a product role; always time-boxed, reasoned,
-- approved by the school, and audited on every read (pass 4 §3.7). Pass 4 D44
-- adds the approval, masking, table list and safeguarding flag, and pass 8
-- adds the operator's location and write grants to D44 (F35, F61); D44 must
-- land in the same migration as auth.allowed(), which reads those columns.
CREATE TABLE auth.support_grant (
  school_id    uuid NOT NULL REFERENCES core.school (id),
  id           uuid NOT NULL DEFAULT gen_random_uuid(),
  operator     text NOT NULL,                     -- CAROS staff identity (not a core.person); checked against app.actor_label
  reason       text NOT NULL CHECK (char_length(reason) >= 20),
  ticket_ref   text,
  granted_by   text NOT NULL,
  granted_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  revoked_at   timestamptz,
  PRIMARY KEY (id),
  CHECK (expires_at <= granted_at + interval '8 hours')
);

CREATE TABLE auth.session (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id      uuid NOT NULL REFERENCES core.school (id),
  person_id      uuid NOT NULL,
  acting_role    text NOT NULL REFERENCES auth.role (key),
  issued_at      timestamptz NOT NULL DEFAULT now(),
  expires_at     timestamptz NOT NULL,
  last_seen_at   timestamptz,
  revoked_at     timestamptz,
  auth_method    text NOT NULL CHECK (auth_method IN ('google','magic_link','mentor_password','support')),  -- pass 4 D39 replaces the list
  step_up_at     timestamptz,                     -- re-authentication for sensitive actions (pass 4 §2.4)
  user_agent_hash text,
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);
CREATE INDEX session_person ON auth.session (person_id) WHERE revoked_at IS NULL;

CREATE TABLE auth.magic_link (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id      uuid NOT NULL REFERENCES core.school (id),
  person_id      uuid NOT NULL,
  token_hash     bytea NOT NULL UNIQUE,           -- never the token itself
  sent_to        citext NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  expires_at     timestamptz NOT NULL,
  consumed_at    timestamptz,
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);

-- ---- transaction context --------------------------------------------------
-- withTenant() sets six settings at the start of every transaction
-- (app.school_id, app.person_id, app.role, app.actor_kind, app.request_id,
-- app.session_id), plus app.actor_label for support and ingest actors, and then
-- SET LOCAL ROLE to the tier (DR-4; §12.3 of the pass 7 review corrected the
-- count). Reading an unset setting returns NULL, and NULL never equals a school
-- id, so a query with no context sees no rows: fail closed.
CREATE FUNCTION auth.current_school() RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.school_id', true), '')::uuid $$;
CREATE FUNCTION auth.current_person() RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.person_id', true), '')::uuid $$;
CREATE FUNCTION auth.current_role_key() RETURNS text LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.role', true), '') $$;
CREATE FUNCTION auth.actor_kind() RETURNS text LANGUAGE sql STABLE AS $$
  SELECT COALESCE(NULLIF(current_setting('app.actor_kind', true), ''), 'user') $$;
CREATE FUNCTION auth.actor_label() RETURNS text LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.actor_label', true), '') $$;

-- ---- pre-tenant lookups (F36) ----------------------------------------------
-- The few reads that must happen before a tenant is known: which school a
-- Google domain belongs to, which school a magic link belongs to, and which
-- schools the worker should visit. Each is a definer function that returns
-- identifiers only, each is executable only by the login that needs it, and
-- none gives a cross-tenant query path to anything else.
CREATE FUNCTION auth.school_for_domain(p_domain citext) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT d.school_id FROM auth.school_domain d          -- pass 4 D37; verified domains only (F35)
  WHERE d.domain = p_domain AND d.verified_at IS NOT NULL $$;
CREATE FUNCTION auth.school_for_magic_link(p_token_hash bytea) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT l.school_id FROM auth.magic_link l
  WHERE l.token_hash = p_token_hash AND l.consumed_at IS NULL AND l.expires_at > now() $$;
CREATE FUNCTION core.schools_due_for_sweep(p_now timestamptz) RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = core, pg_temp AS $$
  SELECT s.id FROM core.school s
  WHERE s.status IN ('shadow','live')                   -- "holds data", never "active" (F36)
    AND extract(hour FROM p_now AT TIME ZONE s.timezone) >= s.sweep_hour $$;   -- sweep_hour: pass 3 D29
CREATE FUNCTION core.schools_holding_data() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = core, pg_temp AS $$
  SELECT s.id FROM core.school s WHERE s.status IN ('shadow','live','suspended','offboarding') $$;
CREATE FUNCTION notify.schools_with_due_outbox() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = notify, pg_temp AS $$
  SELECT DISTINCT o.school_id FROM notify.outbox o
  WHERE o.status = 'queued' AND (o.not_before IS NULL OR o.not_before <= now()) $$;

-- ---- scope predicates -------------------------------------------------------
-- Each is SECURITY DEFINER so it can read the membership tables regardless of
-- the caller's own row access, and each pins search_path. They are STABLE and
-- cheap: every one is an indexed existence check. None is executable by PUBLIC
-- or by any tier: only auth.allowed() and the projection views call them (F75),
-- so they cannot be used as yes-or-no lookups.
CREATE FUNCTION auth.in_caseload(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM auth.caseload_assignment a
                 WHERE a.school_id = auth.current_school() AND a.counselor_person_id = p_person
                   AND a.student_id = p_student
                   AND a.valid_from <= now() AND (a.valid_to IS NULL OR a.valid_to > now())) $$;

CREATE FUNCTION auth.in_roster(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = sis, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM sis.section_teacher t
                 JOIN sis.section_membership m ON m.school_id = t.school_id AND m.section_id = t.section_id
                 WHERE t.school_id = auth.current_school() AND t.teacher_person_id = p_person
                   AND m.student_id = p_student AND t.ended_on IS NULL AND m.ended_on IS NULL) $$;

CREATE FUNCTION auth.teaches_section(p_person uuid, p_section uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = sis, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM sis.section_teacher t
                 WHERE t.school_id = auth.current_school() AND t.teacher_person_id = p_person
                   AND t.section_id = p_section AND t.ended_on IS NULL) $$;

-- A link counts only while it is active, verified, activated for that contact,
-- and carries no restriction (F57). activation_status and restriction are added
-- by pass 4 D42, which lands with this function.
CREATE FUNCTION auth.is_guardian_of(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = family, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM family.guardian_link g
                 WHERE g.school_id = auth.current_school() AND g.guardian_person_id = p_person
                   AND g.student_id = p_student AND g.status = 'active' AND g.verified_at IS NOT NULL
                   AND g.activation_status = 'active' AND g.restriction IS NULL) $$;

CREATE FUNCTION auth.is_paired_mentor(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = mentor, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM mentor.pairing p JOIN mentor.profile mp ON mp.id = p.mentor_profile_id
                 WHERE p.school_id = auth.current_school() AND mp.person_id = p_person
                   AND p.student_id = p_student AND p.status = 'active') $$;

-- One pairing, not one student: a mentor never reads another mentor's thread
-- with the same student (F59).
CREATE FUNCTION auth.is_pairing_mentor(p_person uuid, p_pairing uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = mentor, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM mentor.pairing p JOIN mentor.profile mp ON mp.id = p.mentor_profile_id
                 WHERE p.school_id = auth.current_school() AND p.id = p_pairing
                   AND mp.person_id = p_person AND p.status = 'active') $$;

CREATE FUNCTION auth.is_self(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = sis, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM sis.student s WHERE s.school_id = auth.current_school()
                 AND s.id = p_student AND s.person_id = p_person) $$;

CREATE FUNCTION auth.in_diploma_cohort(p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = sis, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM sis.enrolment e
                 JOIN sis.programme p ON p.id = e.programme_id
                 JOIN ref.programme_family f ON f.key = p.family
                 WHERE e.school_id = auth.current_school() AND e.student_id = p_student
                   AND e.status = 'active' AND f.diploma_cohort) $$;

CREATE FUNCTION auth.is_ib_subject_teacher(p_person uuid, p_subject uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ib, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM ib.subject_teacher st WHERE st.school_id = auth.current_school()
                 AND st.person_id = p_person AND st.subject_id = p_subject AND st.ended_on IS NULL) $$;

CREATE FUNCTION auth.is_ee_party(p_person uuid, p_essay uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ib, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM ib.ee_essay e WHERE e.school_id = auth.current_school() AND e.id = p_essay
                 AND (e.target_person_id = p_person OR e.supervisor_person_id = p_person)) $$;

-- Through an escalation (F02): the person is a recipient of an escalation about
-- this student, while it is open and until its esc window ends. status,
-- esc_scope_until and routed_to_person_ids are added by pass 4 D46.
CREATE FUNCTION auth.esc_covers(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = signal, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM signal.escalation e
                 WHERE e.school_id = auth.current_school() AND e.student_id = p_student
                   AND (e.status <> 'closed' OR e.esc_scope_until > now())
                   AND (e.to_person_id = p_person OR p_person = ANY (e.routed_to_person_ids))) $$;

-- The caseload lead's conditional access (F02): only while a cover row for the
-- student is active, whoever holds it, or within 14 days of a reassignment.
CREATE FUNCTION auth.lead_cover_active(p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM auth.caseload_assignment a
                 WHERE a.school_id = auth.current_school() AND a.student_id = p_student
                   AND ((a.kind = 'cover' AND a.valid_from <= now() AND (a.valid_to IS NULL OR a.valid_to > now()))
                     OR (a.kind = 'primary' AND a.valid_from > now() - interval '14 days'
                         AND EXISTS (SELECT 1 FROM auth.caseload_assignment b
                                     WHERE b.school_id = a.school_id AND b.student_id = a.student_id
                                       AND b.kind = 'primary' AND b.id <> a.id)))) $$;

CREATE FUNCTION auth.in_led_year_group(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM auth.pastoral_assignment pa
                 JOIN sis.enrolment e ON e.school_id = pa.school_id AND e.year_group_id = pa.year_group_id
                 WHERE pa.school_id = auth.current_school() AND pa.person_id = p_person
                   AND pa.kind IN ('year_lead','ucas_adviser')
                   AND pa.valid_from <= now() AND (pa.valid_to IS NULL OR pa.valid_to > now())
                   AND e.student_id = p_student AND e.status = 'active') $$;

CREATE FUNCTION auth.in_tutor_group(p_person uuid, p_student uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM auth.pastoral_assignment pa
                 JOIN sis.tutor_group_member m ON m.school_id = pa.school_id AND m.tutor_group_id = pa.tutor_group_id
                 WHERE pa.school_id = auth.current_school() AND pa.person_id = p_person AND pa.kind = 'tutor'
                   AND pa.valid_from <= now() AND (pa.valid_to IS NULL OR pa.valid_to > now())
                   AND m.student_id = p_student AND m.ended_on IS NULL) $$;

-- A support read is honoured only for the operator the grant names, for a table
-- the grant lists, never for the raw exports or the outbox, and for
-- safeguarding only with the school's separate flag (F35). The columns are
-- pass 4 D44's.
CREATE FUNCTION auth.support_grant_covers(p_table text, p_class text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  -- raw export files are also excluded: support.v_doc_file never projects the
  -- kinds sis_export, sample_export or connector_snapshot
  SELECT p_table NOT IN ('ingest.staged_row','ingest.import_rejection','notify.outbox','notify.in_app')
     AND EXISTS (SELECT 1 FROM auth.support_grant g
                 WHERE g.school_id = auth.current_school() AND g.operator = auth.actor_label()
                   AND g.approved_at IS NOT NULL AND g.revoked_at IS NULL AND g.expires_at > now()
                   AND g.mode = 'read' AND p_table = ANY (g.tables)
                   AND (p_class <> 'safeguarding' OR g.safeguarding_flag)) $$;

-- ---- the decision ----------------------------------------------------------
-- allowed(tier, table, class, action, subjects..., kind): does the acting
-- person, in the acting role, at the current school, hold a permission for
-- this class, action and row kind whose scope covers this row? p_tier is the
-- role the transaction assumed, evaluated in the policy expression as the
-- caller (current_user), because inside this definer function current_user is
-- its owner (F01). Rows with no student subject (school configuration) require
-- a 'school'-scoped permission.
CREATE FUNCTION auth.allowed(
  p_tier name, p_table text, p_class text, p_action auth.perm_action,
  p_student uuid DEFAULT NULL, p_section uuid DEFAULT NULL, p_subject uuid DEFAULT NULL,
  p_essay uuid DEFAULT NULL, p_author uuid DEFAULT NULL, p_addressee uuid DEFAULT NULL,
  p_pairing uuid DEFAULT NULL, p_kind text DEFAULT NULL
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = auth, pg_temp AS $$
  SELECT CASE
    -- the worker, inside its tenant transaction, only when it really assumed the system tier
    WHEN p_tier = 'caros_t_system'  THEN auth.actor_kind() = 'system'
    -- CAROS support, read-only, only under a grant that names this operator and this table
    WHEN p_tier = 'caros_t_support' THEN auth.actor_kind() = 'support' AND p_action = 'read'
                                         AND auth.support_grant_covers(p_table, p_class)
    -- a user tier with a non-user claim is refused, whatever else is set
    WHEN auth.actor_kind() <> 'user' THEN false
    ELSE EXISTS (
      SELECT 1
      FROM auth.membership m
      JOIN auth.role r ON r.key = m.role_key
      JOIN auth.role_permission rp
        ON rp.role_key = m.role_key AND rp.data_class = p_class AND rp.action = p_action
       AND (rp.school_id IS NULL OR rp.school_id = m.school_id)
       AND (rp.capability IS NULL OR rp.capability = ANY (m.capabilities))
       AND (rp.row_kind IS NULL OR rp.row_kind = p_kind)
      WHERE m.school_id = auth.current_school()
        AND m.person_id = auth.current_person()
        AND m.role_key  = auth.current_role_key()
        AND m.status = 'active'
        -- the tier the transaction assumed must be the acting role's own tier;
        -- the AI tier acts for the requesting person and may only read (F44)
        AND (p_tier = ('caros_t_' || r.tier::text)::name OR (p_tier = 'caros_t_ai' AND p_action = 'read'))
        -- a school row replaces the default rows for the same key, whatever their scope
        AND NOT EXISTS (SELECT 1 FROM auth.role_permission o
                        WHERE o.school_id = m.school_id AND rp.school_id IS NULL
                          AND o.role_key = rp.role_key AND o.data_class = rp.data_class
                          AND o.action = rp.action AND o.capability IS NOT DISTINCT FROM rp.capability
                          AND o.row_kind IS NOT DISTINCT FROM rp.row_kind)
        AND (
             rp.scope = 'school'
          OR (p_student  IS NOT NULL AND rp.scope = 'caseload'        AND auth.in_caseload(m.person_id, p_student))
          OR (p_student  IS NOT NULL AND rp.scope = 'roster'          AND auth.in_roster(m.person_id, p_student))
          OR (p_section  IS NOT NULL AND rp.scope = 'own_section'     AND auth.teaches_section(m.person_id, p_section))
          OR (p_subject  IS NOT NULL AND rp.scope = 'subject_teacher' AND auth.is_ib_subject_teacher(m.person_id, p_subject))
          OR (p_essay    IS NOT NULL AND rp.scope = 'ee_party'        AND auth.is_ee_party(m.person_id, p_essay))
          OR (p_student  IS NOT NULL AND rp.scope = 'self'            AND auth.is_self(m.person_id, p_student))
          OR (p_student  IS NOT NULL AND rp.scope = 'linked_children' AND auth.is_guardian_of(m.person_id, p_student))
          OR (p_student  IS NOT NULL AND rp.scope = 'paired'          AND auth.is_paired_mentor(m.person_id, p_student))
          OR (p_author   IS NOT NULL AND rp.scope = 'author'          AND p_author = m.person_id)
          OR (p_student  IS NOT NULL AND rp.scope = 'ib_cohort'       AND auth.in_diploma_cohort(p_student))
          OR (p_student  IS NOT NULL AND rp.scope = 'esc'             AND auth.esc_covers(m.person_id, p_student))
          OR (p_addressee IS NOT NULL AND rp.scope = 'addressee'      AND p_addressee = m.person_id)
          OR (p_student  IS NOT NULL AND rp.scope = 'lead_cover'      AND auth.lead_cover_active(p_student))
          OR (p_pairing  IS NOT NULL AND rp.scope = 'own_pairing'     AND auth.is_pairing_mentor(m.person_id, p_pairing))
          OR (p_student  IS NOT NULL AND rp.scope = 'year_group'      AND auth.in_led_year_group(m.person_id, p_student))
          OR (p_student  IS NOT NULL AND rp.scope = 'tutor_group'     AND auth.in_tutor_group(m.person_id, p_student))
        )
    )
  END $$;

-- ---- applying policies -------------------------------------------------------
-- protect(table, class, subject expressions...) installs, on one table:
--   * a RESTRICTIVE tenant policy (school_id must equal the transaction's school),
--   * PERMISSIVE role policies that call auth.allowed with the caller's tier,
--     the row's subjects and the row's kind,
--   * ENABLE + FORCE ROW LEVEL SECURITY, so even the owner is bound.
-- Pass 8 (F02, F15) adds: a per-row class expression, a row-kind expression,
-- an addressee and a pairing subject, and the verbs the table carries, which
-- the insert and update policies accept in place of `write`.
-- `shared_defaults` lets vocabulary tables expose their school_id IS NULL rows.
CREATE FUNCTION auth.protect(
  p_table regclass, p_class text,
  p_student text DEFAULT NULL, p_section text DEFAULT NULL, p_subject text DEFAULT NULL,
  p_essay text DEFAULT NULL, p_author text DEFAULT NULL, p_shared_defaults boolean DEFAULT false,
  p_addressee text DEFAULT NULL, p_pairing text DEFAULT NULL, p_kind text DEFAULT NULL,
  p_class_expr text DEFAULT NULL,                 -- overrides p_class with a per-row expression
  p_verbs auth.perm_action[] DEFAULT '{}'         -- e.g. '{escalate}' on signal.escalation
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  tenant_pred text := CASE WHEN p_shared_defaults
                        THEN '(school_id IS NULL OR school_id = auth.current_school())'
                        ELSE 'school_id = auth.current_school()' END;
  cls  text := COALESCE(p_class_expr, quote_literal(p_class));
  -- %s is replaced by the action literal
  args text := format('current_user, %L, %s, %%s, %s, %s, %s, %s, %s, %s, %s, %s',
                 p_table::text, cls,
                 COALESCE(p_student, 'NULL'), COALESCE(p_section, 'NULL'), COALESCE(p_subject, 'NULL'),
                 COALESCE(p_essay, 'NULL'), COALESCE(p_author, 'NULL'), COALESCE(p_addressee, 'NULL'),
                 COALESCE(p_pairing, 'NULL'), COALESCE(p_kind, 'NULL'));
  write_pred text := format('auth.allowed(%s)', format(args, '''write''::auth.perm_action'));
  v auth.perm_action;
BEGIN
  FOREACH v IN ARRAY p_verbs LOOP
    write_pred := write_pred || format(' OR auth.allowed(%s)', format(args, quote_literal(v) || '::auth.perm_action'));
  END LOOP;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', p_table);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', p_table);
  EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %s', p_table);
  EXECUTE format('CREATE POLICY tenant_isolation ON %s AS RESTRICTIVE FOR ALL USING (%s) WITH CHECK (%s)',
                 p_table, tenant_pred,
                 CASE WHEN p_shared_defaults
                   -- platform-default rows (school_id NULL) are written only by migrations
                   THEN '(school_id = auth.current_school() OR (school_id IS NULL AND auth.actor_kind() = ''migration'' AND current_user = ''caros_owner''))'
                   ELSE 'school_id = auth.current_school()' END);
  EXECUTE format('DROP POLICY IF EXISTS role_read ON %s', p_table);
  EXECUTE format('CREATE POLICY role_read ON %s AS PERMISSIVE FOR SELECT USING (auth.allowed(%s))',
                 p_table, format(args, '''read''::auth.perm_action'));
  EXECUTE format('DROP POLICY IF EXISTS role_write ON %s', p_table);
  EXECUTE format('CREATE POLICY role_write ON %s AS PERMISSIVE FOR INSERT WITH CHECK (%s)', p_table, write_pred);
  EXECUTE format('DROP POLICY IF EXISTS role_update ON %s', p_table);
  EXECUTE format('CREATE POLICY role_update ON %s AS PERMISSIVE FOR UPDATE USING (%s) WITH CHECK (%s)',
                 p_table, write_pred, write_pred);
  EXECUTE format('DROP POLICY IF EXISTS role_delete ON %s', p_table);
  EXECUTE format('CREATE POLICY role_delete ON %s AS PERMISSIVE FOR DELETE USING (auth.allowed(%s))',
                 p_table, format(args, '''write''::auth.perm_action'));
END $$;

-- The one way a tier writes to the outbox (F02, F16). Validates the template,
-- the recipient and the variables against the template's allowlist, never
-- stores a credential (an invitation or magic-link token is minted by the
-- worker at send time, never persisted in a payload), and writes the row as
-- the bypass role, because the outbox belongs to its addressee, not its sender.
CREATE FUNCTION notify.enqueue(
  p_template_key text, p_recipient_person_id uuid, p_payload jsonb, p_dedupe_key text,
  p_related_table text DEFAULT NULL, p_related_id uuid DEFAULT NULL, p_not_before timestamptz DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = notify, auth, pg_temp AS $$
DECLARE v_tpl notify.template; v_addr citext; v_id uuid;
BEGIN
  IF auth.current_school() IS NULL THEN RAISE EXCEPTION 'notify.enqueue called with no tenant context'; END IF;
  SELECT * INTO v_tpl FROM notify.template WHERE key = p_template_key AND active ORDER BY version DESC LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'unknown or inactive template %', p_template_key; END IF;
  -- the acting role must be one the template allows to send it (pass 4 §5.8)
  IF auth.actor_kind() = 'user' AND NOT (auth.current_role_key() = ANY (v_tpl.sender_roles)) THEN
    RAISE EXCEPTION 'role % may not send template %', auth.current_role_key(), p_template_key;
  END IF;
  -- every payload key must be declared by the template, and none may carry a credential
  IF EXISTS (SELECT 1 FROM jsonb_object_keys(p_payload) k
             WHERE NOT (v_tpl.variables ? k) OR k ~* '(token|secret|password|code)$') THEN
    RAISE EXCEPTION 'payload key outside the template allowlist, or naming a credential';
  END IF;
  SELECT email INTO v_addr FROM core.person WHERE school_id = auth.current_school() AND id = p_recipient_person_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'recipient is not in this school'; END IF;
  INSERT INTO notify.outbox (school_id, channel, recipient_person_id, recipient_address, template_key, template_version,
                             payload, dedupe_key, not_before, related_table, related_id)
  VALUES (auth.current_school(), v_tpl.channel, p_recipient_person_id,
          CASE WHEN v_tpl.channel = 'email' THEN v_addr END,
          v_tpl.key, v_tpl.version, p_payload, p_dedupe_key, p_not_before, p_related_table, p_related_id)
  ON CONFLICT (school_id, dedupe_key) DO NOTHING
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;
```

```sql
-- The helpers run as the bypass role; each restricts itself to the current
-- school. None is executable by PUBLIC (F75). Only auth.allowed() is granted
-- to the tiers, because every policy expression calls it as the caller.
ALTER FUNCTION auth.scope_rank(auth.perm_scope) OWNER TO caros_policy;
DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname IN ('auth','core','notify') AND p.prosecdef LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO caros_policy', f);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
  END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION auth.allowed(name, text, text, auth.perm_action, uuid, uuid, uuid, uuid, uuid, uuid, uuid, text)
  TO caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_ai,
     caros_t_system, caros_t_support, caros_owner;
GRANT EXECUTE ON FUNCTION auth.school_for_domain(citext), auth.school_for_magic_link(bytea) TO caros_web;
GRANT EXECUTE ON FUNCTION core.schools_due_for_sweep(timestamptz), core.schools_holding_data(), notify.schools_with_due_outbox()
  TO caros_worker;
GRANT EXECUTE ON FUNCTION notify.enqueue(text, uuid, jsonb, text, text, uuid, timestamptz)
  TO caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_system;
```

Approvals, escalations and configuration are enforced twice: in the domain layer by `assertAllowed(<class>, 'approve' | 'escalate' | 'configure', …)` before the write, and now also by the database, because `auth.protect()` gives the insert and update policies of a table that carries a verb `write OR <verb>` (F02). In the first version a counselor who held `escalate` but not `write` on `safeguarding` could not insert the escalation at all, and the quick repair under pressure would have been a broad `write` grant. A test in `packages/db` asserts that every table with a `school_id` column has both `tenant_isolation` and `role_read` policies and `relforcerowsecurity = true`, and a second test runs every verb end to end through RLS, positively and negatively.

### 2.4a From pass 4's matrix to rows (pass 8, F02)

Pass 4 §3.6 is the content of the permission matrix. This table is the step between it and the seed B0.7 loads: every qualifier the matrix prints, the mechanism that enforces it, and the negative test that proves it. **No qualifier ships without its mechanism and its negative test.** Where the mechanism is a projection view, the role in question holds no row permission on the base table; the view is owned by `caros_policy`, filters on `auth.current_school()`, checks the role and scope itself, and projects only the columns named.

| Qualifier in pass 4 §3.6 | Mechanism | Negative test |
|---|---|---|
| **C** caseload; **R** roster; **OS**; **ST**; **EP**; **SELF**; **LC**; **P**; **A**; **IB** | the scopes of the first version, with `is_guardian_of` now requiring an activated, unrestricted link (F57) | a student out of each scope sees nothing |
| **ESC** through an escalation | scope `esc`, `auth.esc_covers()`: the person is a recipient of an escalation about the student, open or inside `esc_scope_until` | a recipient of a closed escalation after its window; a safeguarding lead with no escalation for that student |
| **AD** addressee | scope `addressee`; `protect()`'s `p_addressee` names the recipient column (`notify.outbox.recipient_person_id`, `notify.in_app.person_id`, `family.message.recipient_person_id`, `uni.document_request.requested_from_person_id`; for `signal.safety_alert`, pass 5 D68, an expression over `routed_to_person_ids` that yields the current person when they are among them) | a parent reads the other guardian's message thread; a teacher reads a reference request addressed to a colleague |
| **LCV** the lead "only while a cover or reassignment is active" | scope `lead_cover`, `auth.lead_cover_active()`, on rows carrying `capability = 'caseload_lead'` | the lead reads a note on a student with no cover and no reassignment in 14 days |
| **OP** own pairing | scope `own_pairing`, `auth.is_pairing_mentor()`; `protect()`'s `p_pairing` on `mentor.message`, `mentee_note`, `session_request`, `session` (F59) | mentor A reads mentor B's thread with the same student |
| **YG**, **TG** year and tutor group | scopes `year_group` and `tutor_group` over `auth.pastoral_assignment` (F33) | a tutor reads a student outside the tutor group; a year lead after the assignment ends |
| **G** support grant | not a scope: the support branch of `auth.allowed()` and `auth.support_grant_covers()`, which check the operator named on the grant, the table list, the mode and the safeguarding flag; the support tier holds no base-table grant and reads through masked views in the `support` schema (F35) | a second operator reading under the first operator's grant; a table not on the grant; `doc.file` rows of kind `sis_export`; the outbox |
| "names, year, section; contact columns r:C" (counselor, directory) | staff and teacher tiers have `SELECT` on `core.person` without `email` and `phone`; contact details only through `core.v_person_contact`, which checks caseload | a counselor selects `email` of a student outside the caseload |
| "(name, year, goal only)" (mentor, directory) | `mentor.v_mentee`, honouring `pairing.share_scope` | a mentor selects `date_of_birth` or `student_number` |
| "existence and status only" (lead on safeguarding; the raising counselor or teacher on their own referral) | `signal.v_escalation_status`: reference, student, status, raised, acknowledged, outcome kind; no reason, no fields, no outcome text | the lead selects `observed`, `who_else_knows` or `outcome_note` |
| "aggregates only" (reporting; the lead on the counselor log) | `reporting.agg_*` tables (DR-6); `signal.counselor_log_aggregate()` definer function | the lead selects a single counselor-log row |
| "per-teacher rate report" | a `reporting.agg_teacher_flag_rate` table whose permission row carries `capability = 'caseload_lead'` | a counselor without the capability reads it |
| "`transcript` only" (parent, documents); "`sis_export` only" (school admin); "EE drafts" (coordinator) | `row_kind` on the permission row; `protect('doc.file', …, p_kind => 'kind', p_class_expr => 'data_class')`, so a document is read under its own class and kind (F15) | a parent reads a `reference_letter` file; a student reads a file whose `data_class` is `case_note`; support reads a `sis_export` |
| "own discovery and EE feedback" (student, ai) | `row_kind` on `ai.generation.feature` (`discovery_chat`, `pathway_analysis`, `ee_feedback`) | a student reads a meeting brief or a co-pilot answer about themselves |
| "approved pathways only" (parent, discovery) | `protect()` passes a constant kind per table (`'approved_pathway'`, `'proposal'`, `'session'`, `'message'`); the parent's row has `row_kind = 'approved_pathway'` | a parent reads a chat message |
| "no statement drafts" (parent, university) | parent rows per kind: `target`, `application`, `offer`, `document_request`; none for `statement` or `statement_version` | a parent reads a statement version |
| "status and totals" (parent, ib) | `ib.v_family_ib_status` | a parent reads a sign-off note or a CAS reflection |
| "codes only" (teacher, attendance) | `caros_t_teacher` has no `SELECT` on `reason_code`, `reason_label`, `minutes_late`; `sis.attendance_event` is protected with `section_id` as its section subject, so `own_section` can match (F75) | a teacher selects `reason_label` |
| "sign-off card" (teacher, ST) | `ib.v_signoff_card` (student name, the prerequisite mark, the student's reason) and `ib.sign_off()`; teachers hold no `academic` row permission through ST and no write on `ib.selection*` (F58) | a teacher reads the student's other grades; signs as a colleague; changes a level |
| "the routed note only" (teacher, own flags) | `caros_t_teacher` has no `SELECT` on `signal.teacher_flag.case_id` or `status`; `signal.v_teacher_flag_mine` shows `routed_label` from a vocabulary that never says a case exists (F58) | a teacher selects `case_id` |
| "own guardian links only" (student, parent) | class `guardian_link`: student `SELF`, parent `author` on `guardian_person_id`; no tier writes it except through `family.*` definer functions run by a school admin or the import (F15) | a parent ends or unverifies the other parent's link |
| "own messages and requests" (parent, family) | parent rows with scopes `author` (sender) and `addressee` (recipient) on `family.message`, and `author` on `family.meeting_request.guardian_person_id` | as above |
| "pairing exists, mentor headline" (parent, mentor) | `mentor.v_family_pairing`; no parent row on any `mentor.*` table (F59) | a parent reads a mentee note or a session request message |
| "metadata only" (lead and support, ai) | `ai.v_generation_meta` (feature, requester role, date, status) | the lead reads `output_text` |
| "at reveal sessions only" (signal_shadow) | shadow rows carry the class `signal_shadow` by `p_class_expr` (§2.9); the counselor's permission row is honoured only while pass 3's `shadow_reveal_open` holds for the school, checked by `signal.v_shadow_reveal` | a counselor reads a shadow case outside a reveal |
| "no welfare access" (school admin role; `staff` role; `safeguarding_oversight`) | the absence of rows; oversight members receive only in-app notices addressed to them (class `notification`, scope `addressee`) | a school admin or an oversight member reads a signal, a note or an escalation |
| verbs `es`, `ap`, `cf` | `protect(…, p_verbs => '{escalate}')` on `signal.escalation` and `signal.teacher_flag`; `'{approve}'` on `ib.selection`, `discovery.pathway_proposal`, `uni.statement_review`; `'{configure}'` on `config.*`, `auth.membership`, `auth.caseload_assignment`, `auth.pastoral_assignment`, `ai.feature_policy` | every verb positively and negatively, end to end through RLS |
| "never self-assigned" (cover, capabilities) | pass 4 D43's CHECK on planned cover (`granted_by_person_id <> counselor_person_id` unless break-glass, whose lead confirmation must come from someone else) and `auth.capability_grant`'s four-eyes CHECK (F16) | a lead grants cover to themselves; a school admin confirms their own capability |

The matrix itself is regenerated into rows by a script in `packages/db/seed/matrix.ts` that reads pass 4 §3.6's cells as data (`packages/contracts/authz/matrix.json`); the generated suite in pass 4 §3.8 reads the same file, so the matrix, the rows and the tests cannot drift apart.

```sql
-- ============================================================================
-- 2.5 sis: the academic record, as the school holds it
-- ============================================================================
-- Everything here is imported (pass 2) and carries import_id for provenance and
-- rollback. Nothing here is edited by hand in CAROS; a correction is a new
-- import that supersedes rows.
-- Programme families are a reference table, not an ENUM (pass 8, F65): the
-- first list lacked IGCSE, BTEC and the IB Career-related Programme, and a new
-- family should be a row, not a migration. It is global (no school_id) and
-- lives in `ref`; it is created here because sis.programme refers to it.
CREATE TABLE ref.programme_family (
  key             text PRIMARY KEY,
  label           text NOT NULL,
  diploma_cohort  boolean NOT NULL DEFAULT false,   -- counts toward the Diploma cohort (invariant 7)
  default_scale   text                             -- ref.grade_scale key
);
INSERT INTO ref.programme_family (key, label, diploma_cohort, default_scale) VALUES
 ('ib_dp','IB Diploma Programme',true,'ib_1_7'),
 ('ib_dp_candidate','Choosing the IB Diploma (in the cohort, not yet in the programme)',true,NULL),
 ('ib_cp','IB Career-related Programme',false,'ib_1_7'),
 ('ib_courses','IB courses without the Diploma',false,'ib_1_7'),
 ('ap','Advanced Placement',false,'ap_1_5'),
 ('a_level','A Level',false,'a_level'),
 ('gcse','GCSE',false,'gcse_9_1'),
 ('igcse','IGCSE',false,'igcse_9_1'),
 ('btec','BTEC',false,NULL),
 ('school_own','The school''s own courses (e.g. "ACS High School courses")',false,NULL),
 ('undecided','Undecided',false,NULL);
-- A coarse label for the year's place in the senior school. It no longer
-- decides what a family's or student's portal shows: that is each school's
-- versioned `portal` rule set (config.rule_set_version, §2.8), because four
-- fixed stages put a British Year 10 family on the near-empty Grade 9 portal
-- and hid GCSE grades that go into UCAS applications (F65).
CREATE TYPE sis.stage_key AS ENUM (
  'entry',            -- first year of the senior school (Grade 9 / Year 10)
  'pathway_choice',   -- the year the programme is chosen (Grade 10 / Year 11)
  'programme_1',      -- first year of the programme (Grade 11 / Year 12)
  'programme_2');     -- application year (Grade 12 / Year 13)
CREATE TYPE sis.enrolment_status AS ENUM ('active','withdrawn','transferred_in','transferred_out','graduated','deferred');
CREATE TYPE sis.attendance_code  AS ENUM ('present','absent','late','left_early','remote','unknown');
CREATE TYPE sis.grade_kind       AS ENUM ('achieved','working','predicted','final');
CREATE TYPE sis.assessment_kind  AS ENUM ('assessment','coursework','homework','mock','exam','term_grade','predicted_grade','report');
CREATE TYPE sis.calendar_kind    AS ENUM ('term','half_term','holiday','exam_period','mock_period','reporting_window','inset','event','other');

CREATE TABLE sis.academic_year (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  label       text NOT NULL,                          -- "2025/26"
  starts_on   date NOT NULL,
  ends_on     date NOT NULL,
  is_current  boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, label),
  CHECK (ends_on > starts_on)
);
CREATE UNIQUE INDEX academic_year_one_current ON sis.academic_year (school_id) WHERE is_current;

CREATE TABLE sis.term (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  academic_year_id  uuid NOT NULL,
  label             text NOT NULL,                    -- "Semester 1", "Autumn term"
  seq               smallint NOT NULL,
  starts_on         date NOT NULL,
  ends_on           date NOT NULL,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, academic_year_id, seq),
  FOREIGN KEY (school_id, academic_year_id) REFERENCES sis.academic_year (school_id, id)
);

-- Exam periods, holidays and reporting windows feed contextual suppression
-- (pass 3) and the SLA clock. `affects_domains` says which signal domains a
-- period suppresses; NULL means none (it is informational).
CREATE TABLE sis.calendar_period (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  academic_year_id  uuid NOT NULL,
  kind              sis.calendar_kind NOT NULL,
  label             text NOT NULL,
  starts_on         date NOT NULL,
  ends_on           date NOT NULL,
  year_group_ids    uuid[],                           -- NULL = whole school
  affects_domains   text[],                           -- e.g. '{academic,engagement}' for an exam period
  source            text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','import')),
  import_id         uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, academic_year_id) REFERENCES sis.academic_year (school_id, id),
  CHECK (ends_on >= starts_on)
);

-- The school-day calendar, materialised once per academic year from the
-- weekend pattern and the holiday periods, because "within 2 school days" has
-- to be computed the same way everywhere.
CREATE TABLE sis.school_day (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  day           date NOT NULL,
  is_school_day boolean NOT NULL,
  note          text,
  PRIMARY KEY (school_id, day)
);
CREATE FUNCTION sis.add_school_days(p_school uuid, p_from date, p_days int) RETURNS date
LANGUAGE sql STABLE AS $$
  SELECT day FROM sis.school_day WHERE school_id = p_school AND day > p_from AND is_school_day
  ORDER BY day OFFSET GREATEST(p_days - 1, 0) LIMIT 1 $$;

CREATE TABLE sis.year_group (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  ordinal       smallint NOT NULL,                    -- 9..12 at ACS, 10..13 at a British school
  label         text NOT NULL,                        -- "Grade 9", "Year 10"
  stage         sis.stage_key NOT NULL,
  on_counseling_surface boolean NOT NULL DEFAULT true,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, ordinal), UNIQUE (school_id, label)
);

CREATE TABLE sis.programme (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  family            text NOT NULL REFERENCES ref.programme_family (key),
  name              text NOT NULL,                    -- "IB Diploma Programme", "Advanced Placement", "A Level"
  grade_scale_key   text NOT NULL,                    -- references ref.grade_scale(key)
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, name)
);

CREATE TABLE sis.student (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id         uuid NOT NULL,
  student_number    text,                             -- the SIS's own id, for humans
  date_of_birth     date,                             -- sensitive; guardian-visible, mentor-hidden
  nationality_iso   char(2),                          -- sensitive demographic: fee status and fairness testing only (pass 3, pass 4)
  fee_status_home_country char(2),                    -- passport country used for domestic/international tuition
  joined_on         date,
  left_on           date,
  declared_goal     text,                             -- "Mechanical Engineering"; the student's own words
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, person_id), UNIQUE (school_id, student_number),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);
ALTER TABLE auth.caseload_assignment ADD FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id);

CREATE TABLE sis.enrolment (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  academic_year_id  uuid NOT NULL,
  year_group_id     uuid NOT NULL,
  programme_id      uuid NOT NULL,
  status            sis.enrolment_status NOT NULL DEFAULT 'active',
  valid_from        date NOT NULL,
  valid_to          date,
  import_id         uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, academic_year_id) REFERENCES sis.academic_year (school_id, id),
  FOREIGN KEY (school_id, year_group_id) REFERENCES sis.year_group (school_id, id),
  FOREIGN KEY (school_id, programme_id) REFERENCES sis.programme (school_id, id),
  -- one active enrolment per student per academic year
  EXCLUDE USING gist (school_id WITH =, student_id WITH =, academic_year_id WITH =,
                      daterange(valid_from, COALESCE(valid_to, 'infinity'::date), '[]') WITH &&)
);
CREATE INDEX enrolment_student ON sis.enrolment (school_id, student_id) WHERE status = 'active';
-- `programme_id` above is the student's primary programme. A student may also
-- follow others at once (IB courses alongside the school's own, an AP course
-- beside A Levels), so they are rows here, not a second column (F65).
CREATE TABLE sis.enrolment_programme (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  enrolment_id  uuid NOT NULL,
  programme_id  uuid NOT NULL,
  import_id     uuid,
  PRIMARY KEY (enrolment_id, programme_id),
  FOREIGN KEY (school_id, enrolment_id) REFERENCES sis.enrolment (school_id, id),
  FOREIGN KEY (school_id, programme_id) REFERENCES sis.programme (school_id, id)
);

-- Stable keys across systems and terms: the SIS id, the ManageBac id, the Maia
-- id, the Google subject. Identity resolution (pass 2) writes here.
CREATE TABLE sis.external_identity (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id     uuid NOT NULL,
  system        text NOT NULL,                        -- 'veracross','isams','managebac','maia','google_classroom'
  external_id   text NOT NULL,
  first_seen_import_id uuid,
  last_seen_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, system, external_id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);

CREATE TABLE sis.subject (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  code          text NOT NULL,                        -- "MATH"
  name          text NOT NULL,                        -- "Mathematics"
  department    text,
  canonical_key text,                                 -- global mapping key, e.g. 'mathematics' (pass 2 normalisation)
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, code)
);

CREATE TABLE sis.timetable_period (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  code          text NOT NULL,                        -- "P1"
  seq           smallint NOT NULL,
  starts_at     time,
  ends_at       time,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, code)
);

-- A class: one subject, one level, one timetable slot, one or more teachers.
-- Rosters decide what a teacher may see, so they are imported, never typed in.
CREATE TABLE sis.section (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  academic_year_id  uuid NOT NULL,
  subject_id        uuid NOT NULL,
  programme_id      uuid,
  code              text NOT NULL,                    -- "12A/Ma1"
  label             text NOT NULL,                    -- "Grade 12 Mathematics: Analysis & Approaches HL"
  level             text,                             -- 'HL','SL','AP','A2', NULL
  timetable_period_id uuid,
  feeder_set_key    text,                             -- 'extended mathematics' | 'foundation' (IB prerequisite check)
  import_id         uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, academic_year_id, code),
  FOREIGN KEY (school_id, academic_year_id) REFERENCES sis.academic_year (school_id, id),
  FOREIGN KEY (school_id, subject_id) REFERENCES sis.subject (school_id, id),
  FOREIGN KEY (school_id, programme_id) REFERENCES sis.programme (school_id, id),
  FOREIGN KEY (school_id, timetable_period_id) REFERENCES sis.timetable_period (school_id, id)
);

CREATE TABLE sis.section_teacher (
  school_id          uuid NOT NULL REFERENCES core.school (id),
  id                 uuid NOT NULL DEFAULT gen_random_uuid(),
  section_id         uuid NOT NULL,
  teacher_person_id  uuid NOT NULL,
  role               text NOT NULL DEFAULT 'lead' CHECK (role IN ('lead','co','cover')),
  started_on         date NOT NULL,
  ended_on           date,
  import_id          uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, section_id, teacher_person_id, started_on),
  FOREIGN KEY (school_id, section_id) REFERENCES sis.section (school_id, id),
  FOREIGN KEY (school_id, teacher_person_id) REFERENCES core.person (school_id, id)
);
CREATE INDEX section_teacher_by_teacher ON sis.section_teacher (school_id, teacher_person_id) WHERE ended_on IS NULL;

CREATE TABLE sis.section_membership (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  section_id    uuid NOT NULL,
  student_id    uuid NOT NULL,
  started_on    date NOT NULL,
  ended_on      date,
  import_id     uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, section_id, student_id, started_on),
  FOREIGN KEY (school_id, section_id) REFERENCES sis.section (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
CREATE INDEX section_membership_by_student ON sis.section_membership (school_id, student_id) WHERE ended_on IS NULL;
CREATE INDEX section_membership_by_section ON sis.section_membership (school_id, section_id) WHERE ended_on IS NULL;

-- Tutor (registration) groups, where the school has them (pass 8, F33). A
-- British school's form tutor and Head of Year share responsibility for a
-- student; the SIS exports it (iSAMS TutorStaffId, HeadOfYear StaffId), and
-- auth.pastoral_assignment turns it into read scopes. ACS may never fill these.
CREATE TABLE sis.tutor_group (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  academic_year_id  uuid NOT NULL,
  year_group_id     uuid,
  code              text NOT NULL,                    -- "11W"
  label             text NOT NULL,
  import_id         uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, academic_year_id, code),
  FOREIGN KEY (school_id, academic_year_id) REFERENCES sis.academic_year (school_id, id),
  FOREIGN KEY (school_id, year_group_id) REFERENCES sis.year_group (school_id, id)
);
CREATE TABLE sis.tutor_group_member (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  tutor_group_id  uuid NOT NULL,
  student_id      uuid NOT NULL,
  started_on      date NOT NULL,
  ended_on        date,
  import_id       uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, tutor_group_id, student_id, started_on),
  FOREIGN KEY (school_id, tutor_group_id) REFERENCES sis.tutor_group (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
ALTER TABLE auth.pastoral_assignment
  ADD FOREIGN KEY (school_id, year_group_id) REFERENCES sis.year_group (school_id, id),
  ADD FOREIGN KEY (school_id, tutor_group_id) REFERENCES sis.tutor_group (school_id, id);

CREATE TABLE sis.assessment (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  section_id    uuid NOT NULL,
  kind          sis.assessment_kind NOT NULL,
  title         text NOT NULL,
  occurred_on   date NOT NULL,
  max_score     numeric(8,2),
  weight        numeric(6,3),
  term_id       uuid,
  external_ref  text,                                 -- "ASM-4471"
  import_id     uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, section_id) REFERENCES sis.section (school_id, id),
  FOREIGN KEY (school_id, term_id) REFERENCES sis.term (school_id, id)
);

-- One row per student per assessment. `normalised_pct` is the cross-scale value
-- the engine reads (0..100), produced by ref.grade_scale at import time and
-- recomputed if the scale table changes (the raw value is the truth).
CREATE TABLE sis.grade (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id      uuid NOT NULL,
  assessment_id   uuid NOT NULL,
  section_id      uuid NOT NULL,
  kind            sis.grade_kind NOT NULL DEFAULT 'achieved',
  value_raw       text NOT NULL,                      -- "41", "6", "A*", "4"
  scale_key       text NOT NULL,                      -- 'pct','ib_1_7','ap_1_5','a_level','gcse_9_1','gpa_4'
  value_numeric   numeric(8,3),
  normalised_pct  numeric(6,3),
  recorded_on     date NOT NULL,
  import_id       uuid,
  superseded_by_import_id uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  UNIQUE (school_id, student_id, assessment_id, kind, import_id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, assessment_id) REFERENCES sis.assessment (school_id, id),
  FOREIGN KEY (school_id, section_id) REFERENCES sis.section (school_id, id)
);
CREATE INDEX grade_student_time ON sis.grade (school_id, student_id, recorded_on) WHERE superseded_by_import_id IS NULL;

-- Per session where the SIS gives it, per day where it does not. `authorised`
-- and `reason_code` are what contextual suppression needs; a NULL reason is an
-- honest "the export did not say".
CREATE TABLE sis.attendance_event (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  day                 date NOT NULL,
  timetable_period_id uuid,                           -- NULL = whole-day record
  section_id          uuid,
  code                sis.attendance_code NOT NULL,
  authorised          boolean,
  reason_code         text,                           -- the SIS's code, e.g. "M" (medical)
  reason_label        text,
  minutes_late        smallint,
  import_id           uuid,
  superseded_by_import_id uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, timetable_period_id) REFERENCES sis.timetable_period (school_id, id),
  FOREIGN KEY (school_id, section_id) REFERENCES sis.section (school_id, id)
);
CREATE INDEX attendance_student_day ON sis.attendance_event (school_id, student_id, day) WHERE superseded_by_import_id IS NULL;

CREATE TABLE sis.behaviour_event (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id      uuid NOT NULL,
  occurred_at     timestamptz NOT NULL,
  category_key    text NOT NULL,                      -- config.behaviour_category
  points          smallint,
  severity        smallint,
  description     text,                               -- sensitive; staff only
  reported_by_person_id uuid,
  import_id       uuid,
  superseded_by_import_id uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, reported_by_person_id) REFERENCES core.person (school_id, id)
);
CREATE INDEX behaviour_student_time ON sis.behaviour_event (school_id, student_id, occurred_at);

-- Transcript summaries as the school issues them (the parent portal's
-- "Grades & transcripts" page). Files live in doc.file.
CREATE TABLE sis.transcript (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id    uuid NOT NULL,
  term_id       uuid,
  label         text NOT NULL,                        -- "Semester 1 · 2025/26"
  issued_on     date,
  expected_on   date,
  status        text NOT NULL CHECK (status IN ('pending','ready','superseded')),
  summary       jsonb NOT NULL DEFAULT '{}'::jsonb,   -- {gpa:"3.9 / 4.0", ib_points:"39 predicted"} as issued
  file_id       uuid,
  note          text,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, term_id) REFERENCES sis.term (school_id, id)
);

-- ============================================================================
-- 2.6 engagement: platform and LMS activity. Privacy-sensitive; short retention.
-- ============================================================================
-- Whether measuring a minor's platform activity is justified is pass 4's
-- question (CONTEXT.md §11.8). The table exists so the answer can be "yes,
-- with these limits", and its retention class is the shortest in the system.
CREATE TABLE engagement.activity_event (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id    uuid NOT NULL,
  occurred_at   timestamptz NOT NULL,
  source        text NOT NULL,                        -- config.vocabulary 'engagement_source' (validated in the domain layer); was a CHECK naming ACS's incumbents (F65)
  kind          text NOT NULL,                        -- 'session','task_completed','task_abandoned','submission','login'
  ref           text,                                 -- opaque id in the source system
  import_id     uuid,
  -- a partitioned table's key must include the partition column
  PRIMARY KEY (occurred_at, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
) PARTITION BY RANGE (occurred_at);
CREATE INDEX activity_student_time ON engagement.activity_event (school_id, student_id, occurred_at);

-- ============================================================================
-- 2.7 ref: global reference data. No school_id. Every row cites its source.
-- ============================================================================
-- Readable by every tenant; writable only through the curated import run by
-- the CAROS team as a reviewed job (tier system). Nothing here may be typed in
-- without a source URL and a retrieval date: that is the trust spine as a
-- constraint. A row whose only source is `seed://` never renders a number and
-- never exists in production (F30, DR-8).
-- Destination systems are a reference table, not an ENUM (F65): the first list
-- had no University of California application, and a new system is a row.
-- Columns below written as `destination_system text` reference it.
CREATE TABLE ref.destination_system (
  key     text PRIMARY KEY,                           -- 'ucas','common_app','uc','direct','ouac','uae_direct','other'
  label   text NOT NULL
);
INSERT INTO ref.destination_system VALUES
 ('ucas','UCAS (United Kingdom)'), ('common_app','Common App (United States)'),
 ('uc','University of California application'), ('direct','Direct application'),
 ('ouac','OUAC (Ontario)'), ('uae_direct','Direct application (UAE)'), ('other','Other');
CREATE TYPE ref.fee_status         AS ENUM ('home','international','eu','domestic','province','scholarship');
CREATE TYPE ref.rms                AS ENUM ('reach','match','safety');

CREATE TABLE ref.source (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  url           text NOT NULL,
  title         text,
  publisher     text,
  retrieved_at  timestamptz NOT NULL,
  retrieved_by  text NOT NULL,                        -- operator or job name
  snapshot_file_id uuid,                              -- archived copy of the page, if kept
  UNIQUE (url, retrieved_at)
);

CREATE TABLE ref.grade_scale (
  key           text PRIMARY KEY,                     -- 'ib_1_7','ap_1_5','a_level','gcse_9_1','igcse_9_1','igcse_a_g','pct','gpa_4','ib_points_45'
  label         text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('numeric','ordinal')),
  -- ordered steps for ordinal scales, with the normalised percentage the engine uses
  steps         jsonb NOT NULL,                       -- [{"value":"A*","normalised":97},...] or {"min":0,"max":100}
  source_id     uuid REFERENCES ref.source (id),
  note          text
);

CREATE TABLE ref.institution (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  country_iso   char(2) NOT NULL,
  city          text,
  aliases       text[] NOT NULL DEFAULT '{}',        -- "Warwick", "University of Warwick"
  website       text,
  destination_system text NOT NULL REFERENCES ref.destination_system (key),
  source_id     uuid NOT NULL REFERENCES ref.source (id),
  valid_from    date NOT NULL,
  valid_to      date,
  UNIQUE (name, country_iso)
);

CREATE TABLE ref.course (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id  uuid NOT NULL REFERENCES ref.institution (id),
  name            text NOT NULL,                      -- "BSc Economics"
  code            text,                               -- UCAS code
  degree          text,
  duration_years  smallint,
  source_id       uuid NOT NULL REFERENCES ref.source (id),
  valid_from      date NOT NULL,
  valid_to        date,
  UNIQUE (institution_id, name, valid_from)
);

-- The typical offer for a course under a programme family, for one entry cycle.
-- `structured` is what the reach/match/safety rule reads; `summary` is what the
-- UI prints. Both come from the same source row.
CREATE TABLE ref.entry_requirement (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id         uuid NOT NULL REFERENCES ref.course (id),
  programme_family  text NOT NULL REFERENCES ref.programme_family (key),
  entry_year        smallint NOT NULL,
  summary           text NOT NULL,                    -- "38 points overall, 7 6 6 at HL"
  structured        jsonb NOT NULL,                   -- {"points":38,"hl":[7,6,6],"subjects":[{"key":"mathematics_aa","level":"HL","min":7}]}
  admissions_test   text,                             -- "UCAT", "SAT optional"
  source_id         uuid NOT NULL REFERENCES ref.source (id),
  valid_from        date NOT NULL,
  valid_to          date,
  UNIQUE (course_id, programme_family, entry_year)
);

CREATE TABLE ref.requirement_change (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id         uuid NOT NULL REFERENCES ref.course (id),
  changed_for_year  smallint NOT NULL,
  was               text NOT NULL,
  now               text NOT NULL,
  note              text,
  source_id         uuid NOT NULL REFERENCES ref.source (id)
);

CREATE TABLE ref.cost (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id  uuid NOT NULL REFERENCES ref.institution (id),
  course_id       uuid REFERENCES ref.course (id),
  fee_status      ref.fee_status NOT NULL,
  academic_year   text NOT NULL,                      -- "2027/28"
  currency        char(3) NOT NULL,
  tuition_amount  numeric(12,2),
  accommodation_amount numeric(12,2),
  living_amount   numeric(12,2),
  note            text,
  source_id       uuid NOT NULL REFERENCES ref.source (id),
  UNIQUE (institution_id, course_id, fee_status, academic_year)
);

-- Which passport gets which fee status where. This is the Canada demonstration
-- made honest: a table with a source, not a paragraph.
CREATE TABLE ref.fee_status_rule (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id     uuid REFERENCES ref.institution (id),   -- NULL = country-wide rule
  country_iso        char(2) NOT NULL,
  passport_iso       char(2),                                -- NULL = "any other"
  residency_condition text,
  fee_status         ref.fee_status NOT NULL,
  source_id          uuid NOT NULL REFERENCES ref.source (id),
  valid_from         date NOT NULL,
  valid_to           date
);

CREATE TABLE ref.deadline (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_system  text NOT NULL REFERENCES ref.destination_system (key),
  institution_id      uuid REFERENCES ref.institution (id),  -- NULL = system-wide
  cycle_year          smallint NOT NULL,                     -- entry year
  kind                text NOT NULL,                         -- 'ucas_early','ucas_main','early_decision','regular','test_registration'
  label               text NOT NULL,
  due_at              timestamptz NOT NULL,
  source_id           uuid NOT NULL REFERENCES ref.source (id),
  UNIQUE (destination_system, institution_id, cycle_year, kind)
);

-- What a personal statement is, per destination system and entry year (F32).
-- From 2026 entry UCAS asks three questions, each with a minimum length, all
-- three sharing 4,000 characters; a single-essay system is one section. A
-- version is complete when every section is at or above its minimum and the
-- total is within the limit, never "characters over the ceiling".
CREATE TABLE ref.statement_format (
  destination_system text NOT NULL REFERENCES ref.destination_system (key),
  entry_year         smallint NOT NULL,
  sections           jsonb NOT NULL,                  -- [{"key":"q1","prompt":"…","min_chars":350}, …]
  total_max_chars    integer,
  total_max_words    integer,
  source_id          uuid NOT NULL REFERENCES ref.source (id),
  PRIMARY KEY (destination_system, entry_year)
);
-- What a reference is, per format (F32). A UCAS reference (since 2024 entry)
-- is one per applicant in three sections: a centre statement advisers reuse,
-- extenuating circumstances, and supporting information, with predicted grades
-- entered alongside. A section that draws on welfare facts is flagged
-- generation_forbidden and is never model-drafted, whatever the letter engine does.
CREATE TABLE ref.reference_format (
  key                text PRIMARY KEY,                -- 'ucas_reference_2024','us_counselor_letter','us_teacher_letter'
  destination_system text NOT NULL REFERENCES ref.destination_system (key),
  sections           jsonb NOT NULL,                  -- [{"key":"extenuating","label":"…","max_chars":…,"generation_forbidden":true}, …]
  one_per_applicant  boolean NOT NULL,
  captures_predicted_grades boolean NOT NULL DEFAULT false,
  source_id          uuid NOT NULL REFERENCES ref.source (id)
);

-- What a regulator means for a tenant (F31). The first version stored
-- core.school.regulator and never read it, so every tenant got ADEK's banner,
-- clock, contacts, outcome codes and review pack. Everything regulator-shaped is
-- read from here, by the tenant's regulator. A regulator with no analysis yet
-- (KHDA today) has an explicit empty profile: no regulator-specific text at
-- all, which is what a Dubai tenant must see rather than Abu Dhabi's authorities.
-- Clause numbers live here and in the school's configuration, never in UI copy (F55).
CREATE TABLE ref.regulator_profile (
  regulator               core.regulator NOT NULL,
  version                 smallint NOT NULL,
  label                   text NOT NULL,              -- "ADEK (Abu Dhabi)"; '' for an empty profile
  is_empty                boolean NOT NULL DEFAULT false,
  reporting_contacts      jsonb NOT NULL DEFAULT '[]', -- [{label, number, kind: 'talk_now'|'report_harm'|'emergency', hours, verified_at, source_id}]
  reporting_window        jsonb,                      -- {hours: 24, owner: 'each_staff_member', from: 'suspicion'} (F09)
  category_routes_default jsonb,                      -- {suicidal_ideation: ['counselor','leadership'], maltreatment: ['cpo'], …}; the school confirms its own (F09)
  citations               jsonb NOT NULL DEFAULT '[]', -- [{policy, version, clause, source_id}]
  outcome_vocabulary      text[] NOT NULL DEFAULT '{}',
  indicators              jsonb NOT NULL DEFAULT '[]', -- the reporting indicators the regulator asks for, each over one named population (F77)
  retention_minimums      jsonb NOT NULL DEFAULT '{}', -- per retention class
  attendance_reason_family text,                      -- which absence-reason vocabulary applies
  review_pack_checklist   jsonb NOT NULL DEFAULT '[]', -- the vendor assessment the school must run (ADEK Digital Policy 5.5.1 for ADEK)
  source_ids              uuid[] NOT NULL DEFAULT '{}',
  valid_from              date NOT NULL,
  valid_to                date,
  PRIMARY KEY (regulator, version),
  CHECK (is_empty = (label = ''))
);

CREATE TABLE ref.exam_session (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  board         text NOT NULL,                        -- 'ap','ib','ucat','sat'
  subject       text,
  session_year  smallint NOT NULL,
  register_by   date,
  exam_at       timestamptz,
  results_by    date,
  source_id     uuid NOT NULL REFERENCES ref.source (id)
);

-- Career archetypes and their milestones. Every factual claim in a step (a
-- median test score, a preparation time) is a separate row with a source, and
-- a step with an unsourced claim is not shown (pass 5).
CREATE TABLE ref.archetype (
  key           text NOT NULL,
  version       smallint NOT NULL,
  title         text NOT NULL,
  tagline       text,
  blurb         text,
  score_weights jsonb NOT NULL,                       -- {"analyzing":2,"money":3,...}
  courses       text[] NOT NULL DEFAULT '{}',
  clubs         text[] NOT NULL DEFAULT '{}',
  employers     text[] NOT NULL DEFAULT '{}',
  steps         jsonb NOT NULL,                       -- [{"key":"...","title":"...","detail":"...","timeframe":"...","programme_families":["ib_dp","ap"] or null for all}] (F65)
  subpaths      jsonb NOT NULL DEFAULT '{}'::jsonb,   -- SUBPATH_DETAIL, keyed by subpath key
  narrowing     jsonb,                                -- DISCOVERY_NARROW for this archetype
  active        boolean NOT NULL DEFAULT true,
  PRIMARY KEY (key, version)
);
CREATE TABLE ref.archetype_claim (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  archetype_key text NOT NULL,
  archetype_version smallint NOT NULL,
  step_key      text NOT NULL,
  claim         text NOT NULL,
  source_id     uuid NOT NULL REFERENCES ref.source (id),
  FOREIGN KEY (archetype_key, archetype_version) REFERENCES ref.archetype (key, version)
);

CREATE TABLE ref.onboarding_question (
  key       text NOT NULL,
  version   smallint NOT NULL,
  seq       smallint NOT NULL,
  kind      text NOT NULL CHECK (kind IN ('multi','pick','single','text')),
  text      text NOT NULL,
  options   jsonb NOT NULL,                           -- [["finance","Markets, investing, business"],...]
  PRIMARY KEY (key, version)
);

-- ============================================================================
-- 2.8 config: versioned rule tables and extensible vocabularies
-- ============================================================================
-- One table holds every versioned rule set. `key` names the rule set, `params`
-- is validated against the JSON schema the engine or domain package publishes
-- for that key at `schema_version`. A signal records the id of the version it
-- was produced under, so it stays explainable after the next save.
CREATE TABLE config.rule_set_version (
  school_id       uuid REFERENCES core.school (id),   -- NULL = platform default
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  key             text NOT NULL CHECK (key IN (
                    'engine.thresholds',      -- acad σ, lates/10 days, silence days, persistence weeks, plus pass 3's parameters
                    'engine.suppression',     -- which calendar kinds and absence reasons suppress which domains
                    'engine.tiering',         -- tier mapping and hysteresis (pass 3)
                    'uni.list_balance',       -- "minimum 1 safety by T-21"
                    'uni.reference_sla',      -- "references filed by T-14", chase cadence
                    'uni.nudges',             -- T-21, T-14, T-7, T-2
                    'ib.selection',           -- HL min/max, groups, viability minimums by group
                    'ib.goal_alignment',      -- GOAL_NEEDS
                    'ib.cas',                 -- hours expectation per strand, thin floor by year, gap months
                    'ib.ee',                  -- capacity guide, wait days, milestone offsets
                    'case.lifecycle',         -- monitoring window days, auto-review days, escalation reason length
                    'dimensions',             -- thresholds behind the ten dimension statuses
                    'portal')),               -- per year group and programme: which portal sections a family and a student see, and why a section is empty (F65)
  version         integer NOT NULL,
  schema_version  text NOT NULL,                      -- the engine/domain package version whose schema validated params
  params          jsonb NOT NULL,
  note            text,
  created_by      uuid,                               -- core.person, NULL for platform defaults
  created_at      timestamptz NOT NULL DEFAULT now(),
  effective_from  timestamptz NOT NULL DEFAULT now(),
  effective_to    timestamptz,                        -- set when the next version is saved; never deleted
  shadow          boolean NOT NULL DEFAULT false,     -- evaluated and recorded, not shown (pilot shadow mode)
  PRIMARY KEY (id),
  UNIQUE NULLS NOT DISTINCT (school_id, key, version)
);
CREATE INDEX rule_set_current ON config.rule_set_version (school_id, key) WHERE effective_to IS NULL;

-- The current version of a rule set for a school, falling back to the platform default.
CREATE FUNCTION config.current_rule_set(p_school uuid, p_key text) RETURNS config.rule_set_version
LANGUAGE sql STABLE AS $$
  SELECT r FROM config.rule_set_version r
  WHERE r.key = p_key AND r.effective_to IS NULL AND (r.school_id = p_school OR r.school_id IS NULL)
  ORDER BY r.school_id NULLS LAST LIMIT 1 $$;

-- Extensible vocabularies. school_id NULL is the platform default set; a school
-- may add rows or deactivate defaults for itself.
CREATE TABLE config.vocabulary (
  school_id     uuid REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  vocabulary    text NOT NULL CHECK (vocabulary IN (
                  'flag_tag',            -- per FLAG_KINDS kind: "Withdrawn / quiet", ...
                  'intervention_type',   -- "Action plan + weekly check-in", ...
                  'meeting_kind',        -- check_in, follow_up, parent_meeting, escalation, selection_review
                  'meeting_topic',       -- parent meeting request topics
                  'context_kind',        -- counselor context: authorised absence, family circumstance, ...
                  'behaviour_category',  -- the SIS's categories, mapped
                  'absence_reason',      -- the SIS's reason codes, mapped to authorised/suppressing
                  'cas_tag',             -- interests
                  'document_kind',
                  'guide_course',        -- a school's own course list for its Grade 9 (or Year 10) guide (F65)
                  'engagement_source',   -- CAROS, Google Classroom, ManageBac, ...: was a CHECK (F65)
                  'source_system_kind',  -- csv, veracross, isams, powerschool, managebac, maia, google_classroom, fixture, ...: was a CHECK (F65)
                  'teacher_flag_routed')),-- what a teacher is told about their flag: 'received', 'reviewed'; never that a case exists (F58)
  group_key     text,                                 -- e.g. flag kind 'concern' | 'positive' | 'note' | 'safeguarding'
  key           text NOT NULL,
  label         text NOT NULL,
  description   text,
  attributes    jsonb NOT NULL DEFAULT '{}'::jsonb,   -- e.g. {"suppresses":["attendance"],"authorised":true}
  seq           smallint NOT NULL DEFAULT 0,
  active        boolean NOT NULL DEFAULT true,
  version       integer NOT NULL DEFAULT 1,           -- incremented on every change of label, attributes or active (F48)
  PRIMARY KEY (id),
  UNIQUE NULLS NOT DISTINCT (school_id, vocabulary, group_key, key)
);
-- A past alert must stay explainable after a vocabulary changes (invariant 4,
-- F48). The attributes that drive tiering and suppression
-- (flag_tag.safeguarding_relevant and severity, behaviour_category.urgent,
-- absence_reason.suppresses) used to be edited in place. Every change now
-- writes the previous row to this append-only history, and the engine also
-- snapshots the attribute values it used into evaluation.rule_hits and
-- evidence_item.snapshot, with a test that a rule hit carries them (pass 3).
CREATE TABLE config.vocabulary_history (
  vocabulary_id uuid NOT NULL,
  version       integer NOT NULL,
  school_id     uuid,
  vocabulary    text NOT NULL,
  key           text NOT NULL,
  label         text NOT NULL,
  attributes    jsonb NOT NULL,
  active        boolean NOT NULL,
  valid_from    timestamptz NOT NULL,
  valid_to      timestamptz NOT NULL DEFAULT now(),
  changed_by    uuid,
  PRIMARY KEY (vocabulary_id, version)
);
CREATE FUNCTION config.vocabulary_keep_history() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (NEW.label, NEW.attributes, NEW.active) IS DISTINCT FROM (OLD.label, OLD.attributes, OLD.active) THEN
    INSERT INTO config.vocabulary_history (vocabulary_id, version, school_id, vocabulary, key, label, attributes,
                                           active, valid_from, changed_by)
    VALUES (OLD.id, OLD.version, OLD.school_id, OLD.vocabulary, OLD.key, OLD.label, OLD.attributes, OLD.active,
            COALESCE((SELECT max(valid_to) FROM config.vocabulary_history h WHERE h.vocabulary_id = OLD.id), '-infinity'),
            auth.current_person());
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER vocabulary_keep_history BEFORE UPDATE ON config.vocabulary
  FOR EACH ROW EXECUTE FUNCTION config.vocabulary_keep_history();
CREATE TRIGGER vocabulary_history_append_only BEFORE UPDATE OR DELETE ON config.vocabulary_history
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();
```
```sql
-- ============================================================================
-- 2.9 signal: what the engine wrote, and what the counselor did about it
-- ============================================================================
-- The five tiers, in order. An ENUM because the order is product logic
-- (invariant 1): ORDER BY tier sorts the queue correctly without a lookup.
CREATE TYPE signal.tier       AS ENUM ('urgent','checkin','review','monitor','good');
CREATE TYPE signal.domain     AS ENUM ('academic','attendance','engagement','behaviour','teacher','university','positive');
CREATE TYPE signal.run_cell   AS ENUM ('kept','soft','break','none');
CREATE TYPE signal.case_stage AS ENUM ('detect','explain','triage','act','follow','measure','learn');
CREATE TYPE signal.case_status AS ENUM ('open','closed');
CREATE TYPE signal.close_outcome AS ENUM ('resolved','reduced','unchanged','escalated','not_a_concern','left_school');
CREATE TYPE signal.sweep_trigger AS ENUM ('nightly','manual','event','backfill');
CREATE TYPE signal.sweep_status  AS ENUM ('running','succeeded','partial','failed');
CREATE TYPE signal.flag_kind     AS ENUM ('concern','positive','note','safeguarding');  -- safeguarding: a teacher's referral to the route (F10, C23)
CREATE TYPE signal.flag_status   AS ENUM ('new','linked','reviewed','dismissed');
CREATE TYPE signal.evidence_kind AS ENUM ('signal','teacher_flag','context','case_history','document','positive','manual');
CREATE TYPE signal.actor_kind    AS ENUM ('engine','person');

-- One row per engine run per school. A run is the unit of idempotence: re-running
-- a date supersedes the earlier run of that date rather than adding to it.
CREATE TABLE signal.sweep_run (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  run_date              date NOT NULL,                -- the school-local date the run is "for"
  trigger               signal.sweep_trigger NOT NULL,
  status                signal.sweep_status NOT NULL DEFAULT 'running',
  engine_version        text NOT NULL,                -- packages/engine semver
  thresholds_version_id uuid NOT NULL,                -- config.rule_set_version (engine.thresholds)
  suppression_version_id uuid NOT NULL,
  tiering_version_id    uuid NOT NULL,
  shadow                boolean NOT NULL DEFAULT false,
  started_at            timestamptz NOT NULL DEFAULT now(),
  finished_at           timestamptz,
  students_evaluated    integer,
  students_failed       integer,
  supersedes_run_id     uuid,
  error                 jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (thresholds_version_id) REFERENCES config.rule_set_version (id),
  FOREIGN KEY (suppression_version_id) REFERENCES config.rule_set_version (id),
  FOREIGN KEY (tiering_version_id) REFERENCES config.rule_set_version (id)
);
CREATE UNIQUE INDEX sweep_run_one_live_per_date ON signal.sweep_run (school_id, run_date, shadow)
  WHERE status IN ('running','succeeded','partial') AND supersedes_run_id IS NULL;

-- The baseline record: for one student, one domain, one measured series, the
-- band the engine computed and the weekly points it computed it from. This is
-- the "evidence snapshot" invariant 4 asks for. Rows are content-addressed: a
-- run whose features for a student are unchanged references the existing row.
CREATE TABLE signal.feature_snapshot (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id      uuid NOT NULL,
  domain          signal.domain NOT NULL,
  measure_key     text NOT NULL,                      -- 'mathematics.working_grade', 'punctuality.on_time_pct', 'first_period_punctuality'
  label           text NOT NULL,                      -- printed on the chart
  unit            text,                               -- '%', 'nights/week', ''
  as_of           date NOT NULL,
  window_weeks    smallint NOT NULL,                  -- 8 in the prototype
  series          jsonb NOT NULL,                     -- [{"week_start":"2025-09-29","value":91,"n":3}, ...] nulls allowed
  band_lo         numeric(10,3),
  band_hi         numeric(10,3),
  band_method     text NOT NULL,                      -- pass 3 names it; must be a personal-history method
  history_weeks   smallint NOT NULL,                  -- how much personal history the band rests on (cold start)
  features        jsonb NOT NULL DEFAULT '{}'::jsonb, -- pass 3's feature vector, frozen
  source_row_ids  jsonb NOT NULL DEFAULT '[]'::jsonb, -- the sis.* rows this was computed from
  content_hash    bytea NOT NULL,                     -- sha256 of (student, domain, measure, as_of, series, band, features)
  engine_version  text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, content_hash),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  CHECK (band_method NOT ILIKE '%cohort%')            -- invariant 2, as a guard against the obvious mistake
);
CREATE INDEX feature_snapshot_student ON signal.feature_snapshot (school_id, student_id, domain, as_of DESC);

-- What the engine concluded for one student in one run. Every number the case
-- file prints for that morning comes from here, with the versions it was
-- computed under. `snapshot_ids` is the set of baselines it read.
CREATE TABLE signal.evaluation (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  sweep_run_id    uuid NOT NULL,
  student_id      uuid NOT NULL,
  evaluated_at    timestamptz NOT NULL DEFAULT now(),
  snapshot_ids    uuid[] NOT NULL DEFAULT '{}',
  proposed_tier   signal.tier,                        -- NULL = nothing to say (a quiet row on the sheet)
  rule_hits       jsonb NOT NULL DEFAULT '[]'::jsonb, -- [{"rule":"relapse","fired":true,"inputs":{...}}]
  suppressions    jsonb NOT NULL DEFAULT '[]'::jsonb, -- checks run and their outcome ("no exam period", ...)
  strength        numeric(5,2),                       -- dropped by pass 3 D17, which lands with this table in B2; never populated (§12.11)
  strength_definition text,                           -- dropped by pass 3 D17 with strength
  cold_start      boolean NOT NULL DEFAULT false,
  error           text,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, sweep_run_id, student_id),
  FOREIGN KEY (school_id, sweep_run_id) REFERENCES signal.sweep_run (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
-- Not partitioned: at 50,000 students that is about eighteen million rows a
-- year, which an index handles; partitioning would forbid the foreign keys
-- that point here. Revisit at year 3 with the retention job in place.
CREATE INDEX evaluation_student ON signal.evaluation (school_id, student_id, evaluated_at DESC);

-- A signal: one rule firing on one domain for one student, with the frozen
-- inputs that made it fire. Signals are attached to a case; they are never
-- shown to students or parents.
CREATE TABLE signal.signal (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  evaluation_id     uuid NOT NULL,
  sweep_run_id      uuid NOT NULL,
  rule_key          text NOT NULL,                    -- 'baseline_deviation','engagement_decay','list_balance','reference_sla','relapse','corroboration','post_offer_decay','combined_weak_signal','list_fit'
  rule_version      text NOT NULL,
  domain            signal.domain NOT NULL,
  snapshot_id       uuid,                             -- the baseline it deviated from, if any
  raised_at         timestamptz NOT NULL DEFAULT now(),
  window_start      date,
  window_end        date,
  inputs            jsonb NOT NULL,                   -- frozen: values, thresholds used, source row ids
  summary           text NOT NULL,                    -- deterministic sentence from the rule's template
  contribution      numeric(6,3),                     -- signed; pass 3 defines the semantics or removes it
  status            text NOT NULL DEFAULT 'open' CHECK (status IN ('open','superseded','withdrawn','resolved')),
  superseded_by_id  uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, evaluation_id) REFERENCES signal.evaluation (school_id, id),
  FOREIGN KEY (school_id, sweep_run_id) REFERENCES signal.sweep_run (school_id, id),
  FOREIGN KEY (school_id, snapshot_id) REFERENCES signal.feature_snapshot (school_id, id)
);
CREATE INDEX signal_student_open ON signal.signal (school_id, student_id) WHERE status = 'open';

-- The concern case. Current tier and stage are the head of their history
-- tables (below); the columns here are maintained by trigger so the sheet can
-- read one row, and cannot be edited around the history.
CREATE TABLE signal.case (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  status              signal.case_status NOT NULL DEFAULT 'open',
  stage               signal.case_stage NOT NULL DEFAULT 'explain',
  tier                signal.tier NOT NULL,
  tier_set_at         timestamptz NOT NULL DEFAULT now(),
  tier_set_by         signal.actor_kind NOT NULL DEFAULT 'engine',
  tier_yesterday      signal.tier,                    -- materialised by the sweep for "what changed overnight"; see DR-6
  moved_why           text,                           -- rule template sentence for the movement
  opened_at           timestamptz NOT NULL DEFAULT now(),
  opened_by           signal.actor_kind NOT NULL,
  opened_by_rule_key  text,
  opened_by_person_id uuid,
  opened_from_evaluation_id uuid,
  owner_person_id     uuid NOT NULL,                  -- the counselor
  headline            text,                           -- rule-generated, never model output: the headline rephrase is dropped from v1 (F52)
  plain_explanation   text,
  window_start        date,
  window_end          date,
  no_cause_inferred   boolean NOT NULL DEFAULT true,
  suggested_action    jsonb,                          -- {"what":..,"when":..,"why":..,"rule":..}
  seen_at             timestamptz,                    -- bulk "marked as seen"; changes nothing else
  seen_by_person_id   uuid,
  accepted_at         timestamptz,
  dismissed_at        timestamptz,
  closed_at           timestamptz,
  close_outcome       signal.close_outcome,
  close_note          text,
  monitoring_until    date,                           -- closed_at + case.lifecycle.monitoring_days
  relapse_of_case_id  uuid,                           -- opened by the relapse rule inside a closed case's window
  merged_into_case_id uuid,
  auto_review_on      date,                           -- monitor tier: "auto-review in 14 days"
  -- A shadow case (F24): the same engine, the same lifecycle (hysteresis,
  -- relapse, recovery, holds, auto-review) run while the school is in shadow,
  -- so what shadow measures is what goes live. Read only as class
  -- signal_shadow, at reveal sessions; never notifies, never on the sheet.
  shadow              boolean NOT NULL DEFAULT false,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, owner_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, opened_by_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, relapse_of_case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, merged_into_case_id) REFERENCES signal.case (school_id, id),
  CHECK (status = 'open' OR closed_at IS NOT NULL),
  CHECK (status = 'open' OR close_outcome IS NOT NULL),
  CHECK (opened_by = 'engine' OR opened_by_person_id IS NOT NULL),
  CHECK (opened_by = 'person' OR opened_by_rule_key IS NOT NULL)
);
-- one open live case and one open shadow case per student
CREATE UNIQUE INDEX case_one_open_per_student ON signal.case (school_id, student_id, shadow) WHERE status = 'open';
CREATE INDEX case_owner_open ON signal.case (school_id, owner_person_id, tier) WHERE status = 'open';

CREATE TABLE signal.case_tier_history (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id         uuid NOT NULL,
  from_tier       signal.tier,
  to_tier         signal.tier NOT NULL,
  changed_at      timestamptz NOT NULL DEFAULT now(),
  changed_by      signal.actor_kind NOT NULL,
  person_id       uuid,
  evaluation_id   uuid,                               -- when the engine moved it
  reason          text,                               -- required for a person's change (checked in domain layer)
  feeds_tuning    boolean NOT NULL DEFAULT false,     -- counselor downgrade/dismiss: threshold feedback
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  CHECK (changed_by = 'engine' OR person_id IS NOT NULL)
);
CREATE TRIGGER case_tier_history_append_only BEFORE UPDATE OR DELETE ON signal.case_tier_history
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

CREATE TABLE signal.case_stage_history (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id     uuid NOT NULL,
  from_stage  signal.case_stage,
  to_stage    signal.case_stage NOT NULL,
  changed_at  timestamptz NOT NULL DEFAULT now(),
  changed_by  signal.actor_kind NOT NULL,
  person_id   uuid,
  event       text NOT NULL,                          -- 'opened','accepted','meeting_scheduled','intervention_resolved','closed','dismissed', ...
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id)
);
CREATE TRIGGER case_stage_history_append_only BEFORE UPDATE OR DELETE ON signal.case_stage_history
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- Every tier or stage change on the case row must arrive with a history row:
-- the trigger writes it from the transaction context, so the two cannot drift.
-- SECURITY DEFINER under the bypass role: the history tables have no student
-- subject, so a counselor's own tier could not insert into them directly.
CREATE FUNCTION signal.case_track_changes() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO signal.case_tier_history (school_id, case_id, from_tier, to_tier, changed_by, person_id, evaluation_id, reason)
    VALUES (NEW.school_id, NEW.id, NULL, NEW.tier, NEW.tier_set_by,
            CASE WHEN NEW.tier_set_by = 'person' THEN auth.current_person() END, NEW.opened_from_evaluation_id, NEW.moved_why);
    INSERT INTO signal.case_stage_history (school_id, case_id, from_stage, to_stage, changed_by, person_id, event)
    VALUES (NEW.school_id, NEW.id, NULL, NEW.stage, NEW.opened_by,
            CASE WHEN NEW.opened_by = 'person' THEN auth.current_person() END, 'opened');
    RETURN NEW;
  END IF;
  IF NEW.tier IS DISTINCT FROM OLD.tier THEN
    NEW.tier_set_at := now();
    INSERT INTO signal.case_tier_history (school_id, case_id, from_tier, to_tier, changed_by, person_id, reason,
                                          feeds_tuning)
    VALUES (NEW.school_id, NEW.id, OLD.tier, NEW.tier, NEW.tier_set_by,
            CASE WHEN NEW.tier_set_by = 'person' THEN auth.current_person() END, NEW.moved_why,
            NEW.tier_set_by = 'person' AND NEW.tier > OLD.tier);   -- a manual downgrade is threshold feedback
  END IF;
  IF NEW.stage IS DISTINCT FROM OLD.stage THEN
    INSERT INTO signal.case_stage_history (school_id, case_id, from_stage, to_stage, changed_by, person_id, event)
    VALUES (NEW.school_id, NEW.id, OLD.stage, NEW.stage,
            CASE WHEN auth.actor_kind() = 'system' THEN 'engine' ELSE 'person' END::signal.actor_kind,
            CASE WHEN auth.actor_kind() <> 'system' THEN auth.current_person() END,
            COALESCE(current_setting('app.case_event', true), 'stage_changed'));
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END $$;
ALTER FUNCTION signal.case_track_changes() OWNER TO caros_policy;
CREATE TRIGGER case_track_changes BEFORE INSERT OR UPDATE ON signal.case
  FOR EACH ROW EXECUTE FUNCTION signal.case_track_changes();

-- An escalated case cannot slide down the queue or be auto-closed (F07). While
-- any escalation on the case is unreleased (open, or closed but with no tier
-- set by a person since its outcome: escalation.tier_released_at IS NULL,
-- pass 4 D46), the engine may raise the tier and nothing else: it may not
-- lower it, and neither the engine nor auto-review may close the case. A
-- person's tier change after the outcome (C10) releases the pin.
CREATE FUNCTION signal.case_escalation_pin() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM signal.escalation e
             WHERE e.school_id = NEW.school_id AND e.case_id = NEW.id AND e.tier_released_at IS NULL) THEN
    IF auth.actor_kind() = 'system' AND NEW.tier > OLD.tier THEN          -- enum order: a greater tier is a lower one
      RAISE EXCEPTION 'case % carries an unreleased escalation: the engine may not lower it', NEW.id;
    END IF;
    IF auth.actor_kind() = 'system' AND NEW.status = 'closed' AND OLD.status = 'open' THEN
      RAISE EXCEPTION 'case % carries an unreleased escalation: it may not be closed automatically', NEW.id;
    END IF;
  END IF;
  -- merge only within one student; across students, cases are linked (C12, C25)
  IF NEW.merged_into_case_id IS NOT NULL AND NEW.merged_into_case_id IS DISTINCT FROM OLD.merged_into_case_id
     AND NOT EXISTS (SELECT 1 FROM signal.case t WHERE t.school_id = NEW.school_id
                     AND t.id = NEW.merged_into_case_id AND t.student_id = NEW.student_id AND t.shadow = NEW.shadow) THEN
    RAISE EXCEPTION 'cases of different students are linked, never merged (case %)', NEW.id;
  END IF;
  RETURN NEW;
END $$;
ALTER FUNCTION signal.case_escalation_pin() OWNER TO caros_policy;
CREATE TRIGGER case_escalation_pin BEFORE UPDATE ON signal.case
  FOR EACH ROW EXECUTE FUNCTION signal.case_escalation_pin();

-- A relationship between two students' cases (siblings, one incident), without
-- moving either student's signals or evidence into the other's file (F07).
CREATE TABLE signal.case_link (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id             uuid NOT NULL,
  linked_case_id      uuid NOT NULL,
  reason              text NOT NULL CHECK (char_length(reason) >= 10),
  linked_by_person_id uuid NOT NULL,
  linked_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, case_id, linked_case_id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, linked_case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, linked_by_person_id) REFERENCES core.person (school_id, id),
  CHECK (case_id <> linked_case_id)
);

CREATE TABLE signal.case_signal (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  case_id       uuid NOT NULL,
  signal_id     uuid NOT NULL,
  attached_at   timestamptz NOT NULL DEFAULT now(),
  attached_by   signal.actor_kind NOT NULL,
  PRIMARY KEY (case_id, signal_id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, signal_id) REFERENCES signal.signal (school_id, id)
);

-- The evidence chain as the case file prints it: one row per item, each
-- pointing at the record it came from and carrying a frozen copy of what that
-- record said at the time. Positive evidence is a row with kind 'positive'.
CREATE TABLE signal.evidence_item (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id       uuid NOT NULL,                        -- a live case, or a shadow case (F24)
  evaluation_id uuid,                                 -- the evaluation that produced the item, for engine items (F24); FK below
  kind          signal.evidence_kind NOT NULL,
  domain        signal.domain NOT NULL,
  source_label  text NOT NULL,                        -- "Gradebook · Veracross", "Teacher concern · Mr. Davies"
  source_table  text,                                 -- 'signal.signal','signal.teacher_flag','sis.grade', ...
  source_id     uuid,
  occurred_at   timestamptz,
  occurred_label text,                                -- "Rolling 14d", "4–13 Nov": printed when a single instant is wrong
  summary       text NOT NULL,                        -- rule template output; never model output
  contribution  numeric(6,3),                         -- signed; positive evidence negative (pass 3 defines)
  snapshot      jsonb NOT NULL DEFAULT '{}'::jsonb,   -- the source record as it was
  added_at      timestamptz NOT NULL DEFAULT now(),
  added_by      signal.actor_kind NOT NULL,
  person_id     uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, evaluation_id) REFERENCES signal.evaluation (school_id, id)
);
CREATE INDEX evidence_by_case ON signal.evidence_item (school_id, case_id, occurred_at);
CREATE TRIGGER evidence_append_only BEFORE UPDATE OR DELETE ON signal.evidence_item
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- Context the counselor holds ("authorised medical absence confirmed"). It is
-- recorded, and the engine re-evaluates; the counselor does not edit the
-- number. The re-evaluation is linked so the downgrade stays explainable.
CREATE TABLE signal.case_context (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id         uuid NOT NULL,
  context_key     text NOT NULL,                      -- config.vocabulary 'context_kind'
  note            text,
  added_by_person_id uuid NOT NULL,
  added_at        timestamptz NOT NULL DEFAULT now(),
  valid_from      date,
  valid_to        date,
  reevaluation_id uuid,                               -- signal.evaluation produced in response
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, added_by_person_id) REFERENCES core.person (school_id, id)
);

CREATE TABLE signal.case_note (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id             uuid NOT NULL,
  student_id          uuid NOT NULL,
  author_person_id    uuid NOT NULL,
  body                text NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  supersedes_note_id  uuid,                           -- a correction is a new note
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, author_person_id) REFERENCES core.person (school_id, id)
);
CREATE TRIGGER case_note_append_only BEFORE UPDATE OR DELETE ON signal.case_note
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

CREATE TABLE signal.intervention (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id           uuid NOT NULL,
  student_id        uuid NOT NULL,
  type_key          text NOT NULL,                    -- config.vocabulary 'intervention_type'
  owner_person_id   uuid NOT NULL,
  opened_at         timestamptz NOT NULL DEFAULT now(),
  due_on            date,
  status            text NOT NULL DEFAULT 'open' CHECK (status IN ('open','resolved','abandoned')),
  outcome           text,
  outcome_kind      signal.close_outcome,
  resolved_at       timestamptz,
  follow_up_on      date,                             -- the review date every accepted case gets
  follow_up_done_at timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, owner_person_id) REFERENCES core.person (school_id, id),
  CHECK (status <> 'resolved' OR (outcome IS NOT NULL AND resolved_at IS NOT NULL))
);
CREATE TABLE signal.intervention_step (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  intervention_id   uuid NOT NULL,
  seq               smallint NOT NULL,
  description       text NOT NULL,
  owner_person_id   uuid,
  due_on            date,
  done_at           timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, intervention_id, seq),
  FOREIGN KEY (school_id, intervention_id) REFERENCES signal.intervention (school_id, id)
);

-- Escalation to the safeguarding lead: with a reason, routed to a named person,
-- and the email it produced. "Cannot double-fire" (invariant 5) means one act
-- is never recorded twice, not that a child can be referred once per case
-- (F07). The first version's UNIQUE (school_id, case_id) is replaced by pass 4
-- D46's partial unique index on open escalations per case and a unique
-- idempotency key per submission; a later escalation on the same case, after
-- the earlier one is closed, carries previous_escalation_id. Information added
-- while one is open goes to signal.escalation_update (C24). A teacher's
-- referral (C23) is an escalation with raised_via = 'teacher_flag'.
CREATE TABLE signal.escalation (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id               uuid NOT NULL,
  student_id            uuid NOT NULL,
  raised_by_person_id   uuid NOT NULL,
  raised_at             timestamptz NOT NULL DEFAULT now(),
  reason                text NOT NULL CHECK (char_length(reason) >= 12),   -- the prototype's minimum; see open decisions
  to_person_id          uuid NOT NULL,                -- the safeguarding lead at the time
  to_role_label         text NOT NULL,                -- the school's term at the time ("Child Protection Officer")
  notification_id       uuid,                         -- notify.outbox
  acknowledged_at       timestamptz,
  acknowledged_by_person_id uuid,
  outcome               text,
  outcome_at            timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, raised_by_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, to_person_id) REFERENCES core.person (school_id, id)
);
-- New information on an open referral, from the raising or owning counselor or
-- the teacher who raised it (F07, C24). Append-only; the route is reminded by
-- the escalation reminder email, which carries a reference only.
CREATE TABLE signal.escalation_update (
  school_id            uuid NOT NULL REFERENCES core.school (id),
  id                   uuid NOT NULL DEFAULT gen_random_uuid(),
  escalation_id        uuid NOT NULL,
  student_id           uuid NOT NULL,
  added_by_person_id   uuid NOT NULL,
  added_at             timestamptz NOT NULL DEFAULT now(),
  body                 text NOT NULL CHECK (char_length(body) >= 20),
  idempotency_key      text NOT NULL,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, idempotency_key),
  FOREIGN KEY (school_id, escalation_id) REFERENCES signal.escalation (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, added_by_person_id) REFERENCES core.person (school_id, id)
);
CREATE TRIGGER escalation_update_append_only BEFORE UPDATE OR DELETE ON signal.escalation_update
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- Teacher flags: the concern loop. `routed_key` is what the teacher is told
-- happened next, from the 'teacher_flag_routed' vocabulary ("received by the
-- counselor", "reviewed by the counselor"); it closes the loop the prototype's
-- "What I've logged" shows without ever saying a case exists (F58). The teacher
-- tier cannot select case_id or status; it reads its own flags through
-- signal.v_teacher_flag_mine. A flag of kind 'safeguarding' is a referral to
-- the route (C23, F10), raised through signal.raise_teacher_referral(); the
-- flag form tells every teacher, above the fields, that a disclosure is
-- reported to the school's Child Protection Officer now and that an ordinary
-- concern is not a safeguarding report. A teacher may flag a student they teach
-- on a roster, in their IB subject or through an Extended Essay they supervise.
-- Flag text is read by the safety screen's lexicon (pass 5, C1).
CREATE TABLE signal.teacher_flag (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  author_person_id  uuid NOT NULL,
  section_id        uuid,                             -- the lesson it was logged after
  kind              signal.flag_kind NOT NULL,
  tags              text[] NOT NULL DEFAULT '{}',    -- keys from config.vocabulary 'flag_tag' (validated in domain layer)
  body              text,
  lesson_at         timestamptz,                      -- when the lesson happened
  submitted_at      timestamptz NOT NULL DEFAULT now(),
  status            signal.flag_status NOT NULL DEFAULT 'new',
  case_id           uuid,
  routed_key        text,                             -- config.vocabulary 'teacher_flag_routed' (F58)
  routed_note       text,                             -- staff-only; never shown to the teacher
  routed_at         timestamptz,
  routed_by_person_id uuid,
  escalation_id     uuid,                             -- kind 'safeguarding': the referral it raised (C23)
  idempotency_key   text,                             -- one submission recorded once (F07)
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, author_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, section_id) REFERENCES sis.section (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id),
  FOREIGN KEY (school_id, escalation_id) REFERENCES signal.escalation (school_id, id),
  UNIQUE (school_id, idempotency_key)
);
CREATE INDEX teacher_flag_inbox ON signal.teacher_flag (school_id, status, submitted_at DESC);
CREATE INDEX teacher_flag_author ON signal.teacher_flag (school_id, author_person_id, submitted_at DESC);

-- A short note a student sends to their counselor ("Struggling to balance the
-- statement with mocks"). Student voice, staff-readable, never engine input
-- unless pass 3 and pass 4 both say so. The student reads their own words but
-- never `safety_flag` or any extraction column: whether an alert was raised
-- about a student's words is staff-only (F13, column grants in §2.22).
CREATE TABLE signal.student_reflection (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id    uuid NOT NULL,
  body          text NOT NULL,
  sent_at       timestamptz NOT NULL DEFAULT now(),
  seen_at       timestamptz,
  seen_by_person_id uuid,
  safety_flag   jsonb,                                -- pass 5's disclosure detection result
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);

-- A recorded conversation: check-ins, follow-ups, parent meetings, escalation
-- meetings, and the IB selection review (which ib.selection references, so the
-- "conversation is a gate" rule points at a real, dated, attributed record).
-- Class `contact_record`, staff-only (F15): a meeting's notes and an outcome of
-- `escalate` are notes, and parents and students never read them. A parent
-- sees their meeting request's status and slot (family.meeting_request), not
-- this row. The coordinator records the review conversation for any student in
-- the Diploma cohort through `ib.record_review()` (F02), not only for their
-- own caseload.
CREATE TABLE core.meeting (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  staff_person_id   uuid NOT NULL,
  kind_key          text NOT NULL,                    -- config.vocabulary 'meeting_kind'
  held_at           timestamptz NOT NULL,
  duration_min      smallint,
  location          text,
  notes             text,
  actions           jsonb NOT NULL DEFAULT '[]'::jsonb, -- [{"text":..,"owner_person_id":..,"due_on":..,"done_at":..}]
  outcome           text CHECK (outcome IN ('ongoing','resolved','escalate')),
  case_id           uuid,
  attendee_person_ids uuid[] NOT NULL DEFAULT '{}',   -- guardians, other staff
  brief_generation_id uuid,                           -- the AI meeting brief, if one was produced
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, staff_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id)
);
CREATE INDEX meeting_student_time ON core.meeting (school_id, student_id, held_at DESC);

-- The run (kept / soft / break / none), derived from the latest snapshots.
-- One function, used by the sheet and the case file, so they cannot disagree.
-- A point is outside only when the engine said so: pass 3 §3.3 counts a point
-- as outside when it lies beyond the band AND its distance from the median is
-- at least the measure's floor, so recomputing from band_lo and band_hi alone
-- (the first version) disagreed with the engine (F40). The engine writes
-- `outside` on every series point; this function reads it.
CREATE FUNCTION signal.week_run(p_school uuid, p_student uuid, p_as_of date, p_weeks int DEFAULT 8)
RETURNS signal.run_cell[] LANGUAGE sql STABLE AS $$
  WITH latest AS (
    SELECT DISTINCT ON (domain, measure_key) series
    FROM signal.feature_snapshot
    WHERE school_id = p_school AND student_id = p_student AND as_of <= p_as_of
    ORDER BY domain, measure_key, as_of DESC
  ),
  pts AS (
    SELECT (e.ordinality)::int AS wk, (e.value->>'value')::numeric AS v,
           COALESCE((e.value->>'outside')::boolean, false) AS outside
    FROM latest l, jsonb_array_elements(l.series) WITH ORDINALITY e
  ),
  per_week AS (
    SELECT wk,
           count(v) AS seen,
           count(v) FILTER (WHERE outside) AS outside
    FROM pts GROUP BY wk
  )
  SELECT COALESCE(array_agg(
           CASE WHEN seen = 0 THEN 'none'
                WHEN outside >= 2 THEN 'break'
                WHEN outside = 1 THEN 'soft'
                ELSE 'kept' END::signal.run_cell ORDER BY wk), '{}')
  FROM per_week $$;
```
```sql
-- ============================================================================
-- 2.10 ib: subject selection, CAS, the Extended Essay
-- ============================================================================
-- Every gate in this module is a comparison against these tables (the trust
-- spine). Demand, viability, supervision load and CAS totals are views.
-- Subject selection is IB-shaped (six groups, three or four HL), a known
-- limitation stated in DR-7.3 (F65). At a school that keeps ManageBac as the
-- record for CAS and the Extended Essay (C10), those tables hold read-only
-- mirror rows (`source = 'managebac_mirror'`, pass 2 §7.4 and §7.9).
CREATE TYPE ib.group_key        AS ENUM ('g1','g2','g3','g4','g5','g6');
CREATE TYPE ib.level            AS ENUM ('HL','SL');
CREATE TYPE ib.selection_status AS ENUM ('draft','submitted','signed','changes_requested','approved','withdrawn');
CREATE TYPE ib.signoff_verdict  AS ENUM ('hl','sl','concern');
CREATE TYPE ib.cas_strand       AS ENUM ('creativity','activity','service');
CREATE TYPE ib.cas_entry_kind   AS ENUM ('entry','reflection','imported_balance');
CREATE TYPE ib.ee_status        AS ENUM ('draft','proposed','refine_requested','confirmed','withdrawn');
CREATE TYPE ib.ee_owner         AS ENUM ('student','supervisor','coordinator');

-- The school's IB catalogue: what is offered for selection, with the school's
-- own thresholds. Distinct from sis.subject (what is taught this year).
CREATE TABLE ib.subject (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  code            text NOT NULL,                      -- 'ENL','MAA'
  group_key       ib.group_key NOT NULL,
  name            text NOT NULL,
  levels          ib.level[] NOT NULL,
  min_to_run      smallint NOT NULL,                  -- the subject, not the level (see DR-6)
  cap             smallint,
  about           text, like_text text, assess text, hard text,
  sis_subject_id  uuid,
  active          boolean NOT NULL DEFAULT true,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, code),
  FOREIGN KEY (school_id, sis_subject_id) REFERENCES sis.subject (school_id, id),
  CHECK (cardinality(levels) > 0)
);
-- The timetable period each level runs at. A clash is two chosen levels in the same period.
CREATE TABLE ib.subject_level_period (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  subject_id          uuid NOT NULL,
  level               ib.level NOT NULL,
  timetable_period_id uuid NOT NULL,
  PRIMARY KEY (subject_id, level),
  FOREIGN KEY (school_id, subject_id) REFERENCES ib.subject (school_id, id),
  FOREIGN KEY (school_id, timetable_period_id) REFERENCES sis.timetable_period (school_id, id)
);
CREATE TABLE ib.subject_teacher (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  subject_id  uuid NOT NULL,
  person_id   uuid NOT NULL,
  is_lead     boolean NOT NULL DEFAULT false,
  started_on  date NOT NULL,
  ended_on    date,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, subject_id, person_id, started_on),
  FOREIGN KEY (school_id, subject_id) REFERENCES ib.subject (school_id, id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);
-- Prerequisite as a comparison: offered from a feeder set with a mark.
CREATE TABLE ib.prerequisite (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  subject_id      uuid NOT NULL,
  level           ib.level NOT NULL,
  feeder_set_key  text NOT NULL,                      -- matches sis.section.feeder_set_key
  min_pct         numeric(5,2),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, subject_id, level),
  FOREIGN KEY (school_id, subject_id) REFERENCES ib.subject (school_id, id)
);

CREATE TABLE ib.selection_round (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  for_academic_year_label text NOT NULL,              -- "2027/28": the year the subjects will be taken
  choosing_year_group_id uuid NOT NULL,               -- Grade 10
  opens_on              date NOT NULL,
  closes_on             date NOT NULL,
  coordinator_person_id uuid NOT NULL,
  status                text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','open','closed','archived')),
  min_note              text,
  rules_version_id      uuid NOT NULL,                -- config.rule_set_version 'ib.selection'
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, choosing_year_group_id) REFERENCES sis.year_group (school_id, id),
  FOREIGN KEY (school_id, coordinator_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (rules_version_id) REFERENCES config.rule_set_version (id),
  CHECK (closes_on > opens_on)
);

CREATE TABLE ib.selection (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  round_id            uuid NOT NULL,
  student_id          uuid NOT NULL,
  status              ib.selection_status NOT NULL DEFAULT 'draft',
  version             integer NOT NULL DEFAULT 0,     -- incremented on each submission
  goal_note           text,
  submitted_at        timestamptz,
  return_note         text,
  returned_at         timestamptz,
  review_meeting_id   uuid,                           -- core.meeting of kind selection_review; the gate
  review_meeting_version integer,                     -- the version the conversation was about; must equal version at approval (F17)
  review_slot_requested_at timestamptz,
  approved_at         timestamptz,
  approved_by_person_id uuid,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, round_id, student_id),
  FOREIGN KEY (school_id, round_id) REFERENCES ib.selection_round (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, review_meeting_id) REFERENCES core.meeting (school_id, id),
  FOREIGN KEY (school_id, approved_by_person_id) REFERENCES core.person (school_id, id),
  -- invariant 6: no approval without a recorded conversation. The CHECK is the
  -- floor; ib.check_approval (below) is the guard, because a non-null id proves
  -- nothing about whose meeting it was or when (F17).
  CHECK (status <> 'approved' OR (review_meeting_id IS NOT NULL AND approved_at IS NOT NULL AND approved_by_person_id IS NOT NULL)),
  CHECK (status <> 'changes_requested' OR return_note IS NOT NULL)
);

-- The conversation gate as a database guard (F17). On the move to 'approved'
-- the review meeting must belong to this student, be of kind
-- selection_review, have been held after the current version was submitted,
-- carry notes of at least ten characters, and have been recorded against this
-- version. A resubmission (version + 1) therefore needs a new conversation.
CREATE FUNCTION ib.check_approval() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE m core.meeting;
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    SELECT * INTO m FROM core.meeting WHERE school_id = NEW.school_id AND id = NEW.review_meeting_id;
    IF NOT FOUND OR m.student_id <> NEW.student_id OR m.kind_key <> 'selection_review'
       OR m.held_at < NEW.submitted_at OR char_length(coalesce(m.notes, '')) < 10
       OR NEW.review_meeting_version IS DISTINCT FROM NEW.version THEN
      RAISE EXCEPTION 'selection % cannot be approved: no recorded review conversation for version %', NEW.id, NEW.version;
    END IF;
    IF NEW.approved_by_person_id IS DISTINCT FROM auth.current_person() THEN
      RAISE EXCEPTION 'approval must be recorded as the approving person';
    END IF;
  END IF;
  RETURN NEW;
END $$;
ALTER FUNCTION ib.check_approval() OWNER TO caros_policy;
CREATE TRIGGER selection_check_approval BEFORE UPDATE ON ib.selection
  FOR EACH ROW EXECUTE FUNCTION ib.check_approval();

CREATE TABLE ib.selection_pick (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  selection_id  uuid NOT NULL,
  group_key     ib.group_key NOT NULL,
  subject_id    uuid NOT NULL,
  level         ib.level NOT NULL,
  reason        text,                                 -- required at submission (domain check), optional in draft
  PRIMARY KEY (id), UNIQUE (school_id, id),
  UNIQUE (school_id, selection_id, group_key),
  UNIQUE (school_id, selection_id, subject_id),       -- a subject once per selection
  FOREIGN KEY (school_id, selection_id) REFERENCES ib.selection (school_id, id),
  FOREIGN KEY (school_id, subject_id) REFERENCES ib.subject (school_id, id)
);

-- The level question, answered by a teacher of that subject, per HL pick. A
-- sign-off is deleted when the pick it answered changes (domain layer), which
-- is what the prototype does on resubmission. Written only by ib.sign_off()
-- (F58): HL picks in an open round, `teacher_person_id` set to the acting
-- person, the pick itself untouched. The teacher reads the card through
-- ib.v_signoff_card (student name, prerequisite mark, the student's reason),
-- never the prototype's "Personal band", which is an engine output.
CREATE TABLE ib.selection_signoff (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  selection_id      uuid NOT NULL,
  pick_id           uuid NOT NULL,
  subject_id        uuid NOT NULL,
  teacher_person_id uuid NOT NULL,
  verdict           ib.signoff_verdict NOT NULL,
  note              text,
  signed_at         timestamptz NOT NULL DEFAULT now(),
  selection_version integer NOT NULL,                 -- the version it answered
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, pick_id),
  FOREIGN KEY (school_id, selection_id) REFERENCES ib.selection (school_id, id),
  FOREIGN KEY (school_id, pick_id) REFERENCES ib.selection_pick (school_id, id),
  FOREIGN KEY (school_id, subject_id) REFERENCES ib.subject (school_id, id),
  FOREIGN KEY (school_id, teacher_person_id) REFERENCES core.person (school_id, id),
  CHECK (verdict = 'hl' OR (note IS NOT NULL AND char_length(note) >= 8))
);

CREATE TABLE ib.selection_event (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  selection_id  uuid NOT NULL,
  at            timestamptz NOT NULL DEFAULT now(),
  actor_person_id uuid,
  event         text NOT NULL,                        -- 'submitted','resubmitted','signed_off','conversation_recorded','approved','returned','slot_requested'
  detail        jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, selection_id) REFERENCES ib.selection (school_id, id)
);
CREATE TRIGGER selection_event_append_only BEFORE UPDATE OR DELETE ON ib.selection_event
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- Demand and viability, counted, never stored. Viability is a property of the
-- subject; a level within a viable subject is a timetabling question.
CREATE VIEW ib.v_subject_demand AS
  SELECT p.school_id, s.round_id, p.subject_id, p.level,
         count(*) FILTER (WHERE s.status <> 'draft' AND s.status <> 'withdrawn') AS firm,
         count(*) FILTER (WHERE s.status = 'draft') AS draft
  FROM ib.selection_pick p JOIN ib.selection s ON s.id = p.selection_id
  GROUP BY p.school_id, s.round_id, p.subject_id, p.level;
CREATE VIEW ib.v_subject_viability AS
  SELECT d.school_id, d.round_id, d.subject_id, sub.min_to_run,
         sum(d.firm + d.draft) AS n, sum(d.firm) AS firm, sum(d.draft) AS draft,
         (sum(d.firm + d.draft) < sub.min_to_run) AS under
  FROM ib.v_subject_demand d JOIN ib.subject sub ON sub.id = d.subject_id
  GROUP BY d.school_id, d.round_id, d.subject_id, sub.min_to_run;

-- ---- CAS -------------------------------------------------------------------
CREATE TABLE ib.cas_activity (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  strand      ib.cas_strand NOT NULL,
  tags        text[] NOT NULL DEFAULT '{}',          -- config.vocabulary 'cas_tag'
  schedule    text,                                   -- "Tue and Thu, 15:30"
  lead_person_id uuid,
  lead_label  text,                                   -- "Coach Almeida" when not a CAROS person
  spots       smallint,
  about       text,
  active      boolean NOT NULL DEFAULT true,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, name),
  FOREIGN KEY (school_id, lead_person_id) REFERENCES core.person (school_id, id)
);
CREATE TABLE ib.cas_interest (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  student_id  uuid NOT NULL,
  tag         text NOT NULL,
  added_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (student_id, tag),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
-- The full CAS ledger. Totals are derived. Historical hours from ManageBac or a
-- previous system arrive as one 'imported_balance' row per strand with the
-- period it covers, so the ledger is complete without pretending to have the
-- entries behind it (the prototype's hrs-versus-entries warning, resolved).
CREATE TABLE ib.cas_entry (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id    uuid NOT NULL,
  kind          ib.cas_entry_kind NOT NULL DEFAULT 'entry',
  strand        ib.cas_strand NOT NULL,
  activity_id   uuid,
  activity_label text,                                -- free text when not a catalogue activity
  occurred_on   date NOT NULL,
  covers_from   date,                                 -- imported_balance only
  covers_to     date,
  hours         numeric(6,2) NOT NULL DEFAULT 0 CHECK (hours >= 0),
  reflection    text,
  outcomes      smallint[] NOT NULL DEFAULT '{}',    -- which of the seven learning outcomes (1..7) this evidences
  reviewed_at   timestamptz,                          -- coordinator has read the reflection (`ref` in the prototype)
  reviewed_by_person_id uuid,
  source        text NOT NULL DEFAULT 'student' CHECK (source IN ('student','import','coordinator','managebac_mirror')),  -- mirror rows are read-only in CAROS (C10)
  import_id     uuid,
  created_at    timestamptz NOT NULL DEFAULT now(),
  deleted_at    timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, activity_id) REFERENCES ib.cas_activity (school_id, id),
  CHECK (kind <> 'imported_balance' OR (covers_from IS NOT NULL AND covers_to IS NOT NULL AND source = 'import')),
  CHECK (outcomes <@ ARRAY[1,2,3,4,5,6,7]::smallint[])
);
CREATE INDEX cas_entry_student ON ib.cas_entry (school_id, student_id, occurred_on DESC) WHERE deleted_at IS NULL;
CREATE VIEW ib.v_cas_totals AS
  SELECT school_id, student_id,
         sum(hours) FILTER (WHERE strand = 'creativity') AS creativity_hours,
         sum(hours) FILTER (WHERE strand = 'activity')   AS activity_hours,
         sum(hours) FILTER (WHERE strand = 'service')    AS service_hours,
         sum(hours) AS total_hours,
         count(*) FILTER (WHERE kind = 'reflection' AND reviewed_at IS NULL) AS reflections_pending,
         max(occurred_on) FILTER (WHERE kind <> 'imported_balance') AS last_entry_on,
         (SELECT count(DISTINCT o) FROM ib.cas_entry e2, unnest(e2.outcomes) o
           WHERE e2.school_id = e.school_id AND e2.student_id = e.student_id AND e2.deleted_at IS NULL) AS outcomes_evidenced
  FROM ib.cas_entry e WHERE deleted_at IS NULL
  GROUP BY school_id, student_id;

-- ---- Extended Essay --------------------------------------------------------
CREATE TABLE ib.ee_round (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  submission_year       smallint NOT NULL,            -- "2027"
  coordinator_person_id uuid NOT NULL,
  word_limit            smallint NOT NULL DEFAULT 4000,  -- copied from the round's guide (pass 5 D70) and confirmed by the coordinator (F77)
  hours_guide           smallint NOT NULL DEFAULT 40,
  capacity_guide        smallint NOT NULL DEFAULT 5,  -- warns, never blocks (invariant 8)
  wait_days             smallint NOT NULL DEFAULT 7,  -- EE_WAIT_DAYS
  rules_version_id      uuid NOT NULL,                -- config.rule_set_version 'ib.ee'
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, submission_year),
  FOREIGN KEY (school_id, coordinator_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (rules_version_id) REFERENCES config.rule_set_version (id)
);
CREATE TABLE ib.ee_milestone (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  round_id    uuid NOT NULL,
  key         text NOT NULL,                          -- 'propose','supervisor','r1','draft','r2','final','viva','submit'
  seq         smallint NOT NULL,
  label       text NOT NULL,
  owner       ib.ee_owner NOT NULL,
  rppf        boolean NOT NULL DEFAULT false,         -- a mandatory reflection: three sessions under the 2018 guide, one statement under the 2027 guide (F62)
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, round_id, key),
  FOREIGN KEY (school_id, round_id) REFERENCES ib.ee_round (school_id, id)
);
-- Real dates per year group, not day offsets from a demo "today".
CREATE TABLE ib.ee_milestone_due (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  milestone_id  uuid NOT NULL,
  year_group_id uuid NOT NULL,
  due_on        date NOT NULL,
  PRIMARY KEY (milestone_id, year_group_id),
  FOREIGN KEY (school_id, milestone_id) REFERENCES ib.ee_milestone (school_id, id),
  FOREIGN KEY (school_id, year_group_id) REFERENCES sis.year_group (school_id, id)
);

CREATE TABLE ib.ee_essay (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id            uuid NOT NULL,
  round_id              uuid NOT NULL,
  subject_id            uuid,
  research_question     text,
  rationale             text,
  status                ib.ee_status NOT NULL DEFAULT 'draft',
  target_person_id      uuid,                         -- the teacher it is currently with (proposed / refine_requested)
  supervisor_person_id  uuid,                         -- set on confirmation
  refine_note           text,
  proposed_at           timestamptz,                  -- (re)set on each send; eeWaiting reads this
  confirmed_at          timestamptz,
  confirmed_by          text CHECK (confirmed_by IN ('teacher','coordinator')),
  over_capacity_at_assignment boolean,                -- recorded, not blocked (invariant 8)
  supervisor_load_at_assignment smallint,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, round_id, student_id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, round_id) REFERENCES ib.ee_round (school_id, id),
  FOREIGN KEY (school_id, subject_id) REFERENCES ib.subject (school_id, id),
  FOREIGN KEY (school_id, target_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, supervisor_person_id) REFERENCES core.person (school_id, id),
  CHECK (status <> 'proposed' OR (subject_id IS NOT NULL AND research_question IS NOT NULL AND rationale IS NOT NULL AND target_person_id IS NOT NULL)),
  CHECK (status <> 'refine_requested' OR refine_note IS NOT NULL),
  CHECK (status <> 'confirmed' OR (supervisor_person_id IS NOT NULL AND confirmed_at IS NOT NULL))
);
CREATE INDEX ee_essay_target ON ib.ee_essay (school_id, target_person_id) WHERE status IN ('proposed','refine_requested');
CREATE INDEX ee_essay_supervisor ON ib.ee_essay (school_id, supervisor_person_id) WHERE status = 'confirmed';

-- Supervision load, counted. The trigger below stamps the load at the moment
-- of assignment so "it was over the guide" is a fact, not a recomputation.
CREATE VIEW ib.v_supervision_load AS
  SELECT school_id, round_id, supervisor_person_id, count(*) AS confirmed_essays
  FROM ib.ee_essay WHERE status = 'confirmed' GROUP BY school_id, round_id, supervisor_person_id;

-- SECURITY DEFINER under the bypass role: the accepting teacher may not be
-- able to see every essay the supervisor holds, but the count must be whole.
CREATE FUNCTION ib.ee_stamp_capacity() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_load int; v_cap int;
BEGIN
  IF NEW.status = 'confirmed' AND (OLD.status IS DISTINCT FROM 'confirmed' OR NEW.supervisor_person_id IS DISTINCT FROM OLD.supervisor_person_id) THEN
    SELECT count(*) INTO v_load FROM ib.ee_essay e
      WHERE e.school_id = NEW.school_id AND e.round_id = NEW.round_id AND e.status = 'confirmed'
        AND e.supervisor_person_id = NEW.supervisor_person_id AND e.id <> NEW.id;
    SELECT capacity_guide INTO v_cap FROM ib.ee_round WHERE id = NEW.round_id;
    NEW.supervisor_load_at_assignment := v_load;
    NEW.over_capacity_at_assignment := (v_load >= v_cap);
    NEW.confirmed_at := COALESCE(NEW.confirmed_at, now());
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END $$;
ALTER FUNCTION ib.ee_stamp_capacity() OWNER TO caros_policy;
CREATE TRIGGER ee_stamp_capacity BEFORE INSERT OR UPDATE ON ib.ee_essay
  FOR EACH ROW EXECUTE FUNCTION ib.ee_stamp_capacity();

CREATE TABLE ib.ee_milestone_completion (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  essay_id      uuid NOT NULL,
  milestone_id  uuid NOT NULL,
  completed_on  date NOT NULL,
  recorded_by_person_id uuid NOT NULL,
  recorded_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (essay_id, milestone_id),
  FOREIGN KEY (school_id, essay_id) REFERENCES ib.ee_essay (school_id, id),
  FOREIGN KEY (school_id, milestone_id) REFERENCES ib.ee_milestone (school_id, id)
);
-- The mandatory reflections, recorded when they happen, dated and attributed:
-- the RPPF's three sessions under the 2018 guide, or the RPF's single
-- reflective statement (at most the guide's reflection_word_limit, 500 words)
-- under the guide for first assessment 2027, which both current ACS cohorts
-- follow (F62, pass 5 D70).
CREATE TABLE ib.ee_reflection (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  essay_id              uuid NOT NULL,
  milestone_id          uuid NOT NULL,
  held_on               date NOT NULL,
  supervisor_person_id  uuid NOT NULL,
  note                  text NOT NULL CHECK (char_length(note) >= 10),
  student_reflection    text,                         -- the student's own RPPF text, if captured
  recorded_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, essay_id, milestone_id),
  FOREIGN KEY (school_id, essay_id) REFERENCES ib.ee_essay (school_id, id),
  FOREIGN KEY (school_id, milestone_id) REFERENCES ib.ee_milestone (school_id, id),
  FOREIGN KEY (school_id, supervisor_person_id) REFERENCES core.person (school_id, id)
);
CREATE TABLE ib.ee_draft (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  essay_id      uuid NOT NULL,
  version_no    smallint NOT NULL,
  file_id       uuid,                                 -- doc.file
  word_count    integer,
  excerpt       text,                                 -- first paragraph, for the readable-in-place card
  submitted_at  timestamptz NOT NULL DEFAULT now(),
  is_final      boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, essay_id, version_no),
  FOREIGN KEY (school_id, essay_id) REFERENCES ib.ee_essay (school_id, id)
);
CREATE TABLE ib.ee_event (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  essay_id    uuid NOT NULL,
  at          timestamptz NOT NULL DEFAULT now(),
  actor_person_id uuid,
  event       text NOT NULL,                          -- 'proposed','resent','refine_requested','passed','accepted','assigned','reflection_recorded','draft_submitted','final_submitted','uploaded','withdrawn'
  detail      jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, essay_id) REFERENCES ib.ee_essay (school_id, id)
);
CREATE TRIGGER ee_event_append_only BEFORE UPDATE OR DELETE ON ib.ee_event
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- The Diploma cohort is a query, not a table (invariant 7). The caseload is
-- auth.caseload_assignment. They are never joined into one count.
CREATE VIEW ib.v_diploma_cohort AS
  SELECT e.school_id, e.student_id, yg.ordinal AS year_ordinal, yg.label AS year_label, p.family
  FROM sis.enrolment e
  JOIN sis.programme p ON p.id = e.programme_id
  JOIN ref.programme_family f ON f.key = p.family
  JOIN sis.year_group yg ON yg.id = e.year_group_id
  WHERE e.status = 'active' AND f.diploma_cohort;
```
```sql
-- ============================================================================
-- 2.11 uni: the university journey, documents, statements, letters
-- ============================================================================
CREATE TYPE uni.application_status AS ENUM ('planned','in_progress','submitted','withdrawn','decided');
CREATE TYPE uni.offer_status       AS ENUM ('none','pending','interview','conditional','unconditional','waitlisted','rejected');
CREATE TYPE uni.offer_response     AS ENUM ('undecided','firm','insurance','accepted','declined');
CREATE TYPE uni.document_kind      AS ENUM ('transcript','counselor_reference','teacher_reference','school_form','portfolio','test_score','other');
CREATE TYPE uni.document_status    AS ENUM ('not_requested','pending','chased','received','sent','final','complete','missing');
CREATE TYPE uni.statement_status   AS ENUM ('not_started','draft','submitted_for_review','changes_requested','approved','final');
CREATE TYPE uni.letter_status      AS ENUM ('requested','drafting','draft_ready','in_review','final','sent');
CREATE TYPE uni.exam_reg_status    AS ENUM ('not_registered','registration_open','registered','sat','scored');

-- A university target. The classification (reach / match / safety) is a rule
-- output over ref.entry_requirement and the student's predicted grades. It is
-- materialised with the rule version and its inputs, and recomputed by the
-- nightly sweep and whenever an input changes (DR-6). There is no probability
-- column: the prototype's `p` traces to nothing and does not ship (§11.3).
CREATE TABLE uni.student_target (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  institution_id    uuid NOT NULL REFERENCES ref.institution (id),
  course_id         uuid REFERENCES ref.course (id),
  entry_year        smallint NOT NULL,
  destination_system text NOT NULL REFERENCES ref.destination_system (key),
  classification    ref.rms,                          -- NULL until the rule has run or when no requirement is on file
  classification_rule_version_id uuid REFERENCES config.rule_set_version (id),
  classification_inputs jsonb,                        -- {"requirement_id":..,"predicted":..,"gap":..}
  classified_at     timestamptz,
  added_by          text NOT NULL CHECK (added_by IN ('student','counselor','import')),
  added_at          timestamptz NOT NULL DEFAULT now(),
  removed_at        timestamptz,
  note              text,
  external_ref      text,                             -- Maia list item id, when read from Maia (pass 2)
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
CREATE INDEX target_student ON uni.student_target (school_id, student_id) WHERE removed_at IS NULL;

CREATE TABLE uni.application (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  target_id       uuid NOT NULL,
  student_id      uuid NOT NULL,
  status          uni.application_status NOT NULL DEFAULT 'planned',
  deadline_id     uuid REFERENCES ref.deadline (id),  -- the deadline that governs it
  submitted_at    timestamptz,
  external_ref    text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, target_id),
  FOREIGN KEY (school_id, target_id) REFERENCES uni.student_target (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);

CREATE TABLE uni.offer (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id        uuid NOT NULL,
  student_id            uuid NOT NULL,
  status                uni.offer_status NOT NULL,
  conditions_text       text,                         -- "AAB including Mathematics"
  conditions_structured jsonb,                        -- {"grades":"AAB","required_subjects":[{"key":"mathematics","min":"A"}]}
  received_at           timestamptz,
  response              uni.offer_response NOT NULL DEFAULT 'undecided',
  responded_at          timestamptz,
  note                  text,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, application_id) REFERENCES uni.application (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);

-- Transcripts, references and forms tracked per student, so nobody chases by
-- memory. `chase_count` and `last_chased_at` are what the reference SLA rule
-- reads; the chase itself is a notify.outbox row.
CREATE TABLE uni.document_request (
  school_id                 uuid NOT NULL REFERENCES core.school (id),
  id                        uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id                uuid NOT NULL,
  application_id            uuid,                     -- NULL = for the whole cycle
  kind                      uni.document_kind NOT NULL,
  requested_from_person_id  uuid,                     -- the teacher or counselor writing it
  requested_at              timestamptz,
  due_on                    date,
  status                    uni.document_status NOT NULL DEFAULT 'not_requested',
  last_chased_at            timestamptz,
  chase_count               smallint NOT NULL DEFAULT 0,
  received_at               timestamptz,
  sent_at                   timestamptz,
  file_id                   uuid,
  note                      text,
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, application_id) REFERENCES uni.application (school_id, id),
  FOREIGN KEY (school_id, requested_from_person_id) REFERENCES core.person (school_id, id)
);
CREATE INDEX docreq_student ON uni.document_request (school_id, student_id, kind);
CREATE INDEX docreq_owner ON uni.document_request (school_id, requested_from_person_id) WHERE status IN ('pending','chased');

-- One statement per destination system and entry year, versioned, in the
-- sections that system asks for (F32): from 2026 entry a UCAS statement is
-- three answers sharing 4,000 characters, each with a minimum, not one essay.
-- The model's read of a version is an ai.generation; it advises, it never
-- decides (pass 5).
CREATE TABLE uni.statement (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  destination_system  text NOT NULL REFERENCES ref.destination_system (key),
  entry_year          smallint NOT NULL,              -- selects the ref.statement_format
  status              uni.statement_status NOT NULL DEFAULT 'not_started',
  current_version_id  uuid,
  submitted_for_review_at timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, student_id, destination_system, entry_year),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (destination_system, entry_year) REFERENCES ref.statement_format (destination_system, entry_year)
);
CREATE TABLE uni.statement_version (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  statement_id    uuid NOT NULL,
  version_no      integer NOT NULL,
  sections        jsonb NOT NULL,                     -- {"q1":"…","q2":"…","q3":"…"}; one key for a single-essay format
  word_count      integer NOT NULL,                   -- totals over the sections
  char_count      integer NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  analysis_generation_id uuid,                        -- ai.generation
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, statement_id, version_no),
  FOREIGN KEY (school_id, statement_id) REFERENCES uni.statement (school_id, id)
);
ALTER TABLE uni.statement ADD FOREIGN KEY (school_id, current_version_id) REFERENCES uni.statement_version (school_id, id);
-- Complete means every section at or above its minimum and the total within
-- the limit (F32). Derived, never stored.
CREATE FUNCTION uni.statement_complete(p_version uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT bool_and(char_length(coalesce(v.sections ->> (sec ->> 'key'), '')) >= coalesce((sec ->> 'min_chars')::int, 1))
         AND (f.total_max_chars IS NULL OR max(v.char_count) <= f.total_max_chars)
  FROM uni.statement_version v
  JOIN uni.statement st ON st.school_id = v.school_id AND st.id = v.statement_id
  JOIN ref.statement_format f ON f.destination_system = st.destination_system AND f.entry_year = st.entry_year
  CROSS JOIN LATERAL jsonb_array_elements(f.sections) sec
  WHERE v.id = p_version
  GROUP BY f.total_max_chars $$;
CREATE TABLE uni.statement_review (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  statement_id        uuid NOT NULL,
  version_id          uuid NOT NULL,
  reviewer_person_id  uuid NOT NULL,
  decision            text NOT NULL CHECK (decision IN ('approved','changes_requested')),
  note                text,
  decided_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, statement_id) REFERENCES uni.statement (school_id, id),
  FOREIGN KEY (school_id, version_id) REFERENCES uni.statement_version (school_id, id),
  FOREIGN KEY (school_id, reviewer_person_id) REFERENCES core.person (school_id, id),
  CHECK (decision = 'approved' OR note IS NOT NULL)
);

-- The letter engine's data. Generation is deferred (section 3), so in v1 the
-- versions are human-written or empty; the columns the generator will need
-- (evidence citations, voice sample, generation id) exist now. A reference has
-- a format (F32): a UCAS reference is one per applicant, in three sections,
-- with the school's centre statement and a snapshot of the predicted grades
-- submitted with it; a US letter is one per writer. A section the format flags
-- generation_forbidden (UCAS's extenuating circumstances, which draw on welfare
-- facts) is never model-drafted, and the letter engine's generation path
-- refuses it by construction.
CREATE TABLE uni.reference_letter (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  author_person_id    uuid NOT NULL,
  kind                text NOT NULL CHECK (kind IN ('counselor','teacher','ucas_reference')),
  format_key          text NOT NULL REFERENCES ref.reference_format (key),
  centre_statement_id uuid,                           -- uni.centre_statement version used (UCAS)
  predicted_grades_snapshot jsonb,                    -- the predicted grades as submitted, frozen at submission (UCAS)
  submitted_at        timestamptz,
  destination_system  text REFERENCES ref.destination_system (key),
  target_id           uuid,                           -- a specific application, or NULL for a system-wide letter
  document_request_id uuid,                           -- the request it fulfils
  status              uni.letter_status NOT NULL DEFAULT 'requested',
  current_version_id  uuid,
  requested_at        timestamptz NOT NULL DEFAULT now(),
  due_on              date,
  sent_at             timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, author_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, target_id) REFERENCES uni.student_target (school_id, id),
  FOREIGN KEY (school_id, document_request_id) REFERENCES uni.document_request (school_id, id)
);
CREATE TABLE uni.reference_letter_version (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  letter_id           uuid NOT NULL,
  version_no          integer NOT NULL,
  sections            jsonb NOT NULL,                 -- keyed by the format's sections; validated against ref.reference_format (F32)
  produced_by         text NOT NULL CHECK (produced_by IN ('human','model')),
  generation_id       uuid,                           -- ai.generation when produced_by = 'model'
  evidence_citations  jsonb NOT NULL DEFAULT '[]'::jsonb, -- [{"claim":"...","source_table":"core.meeting","source_id":"...","dated":"2025-10-12"}]
  edited_from_version_id uuid,
  created_by_person_id uuid,
  created_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, letter_id, version_no),
  FOREIGN KEY (school_id, letter_id) REFERENCES uni.reference_letter (school_id, id),
  CHECK (produced_by = 'human' OR generation_id IS NOT NULL)
);
ALTER TABLE uni.reference_letter ADD FOREIGN KEY (school_id, current_version_id) REFERENCES uni.reference_letter_version (school_id, id);
-- The school's centre statement, which a UCAS adviser writes once per cycle and
-- reuses in every reference (F32). Versioned; a reference records the version it used.
CREATE TABLE uni.centre_statement (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  cycle_year          smallint NOT NULL,
  version_no          integer NOT NULL,
  body                text NOT NULL,
  written_by_person_id uuid NOT NULL,
  written_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, cycle_year, version_no),
  FOREIGN KEY (school_id, written_by_person_id) REFERENCES core.person (school_id, id)
);
ALTER TABLE uni.reference_letter ADD FOREIGN KEY (school_id, centre_statement_id) REFERENCES uni.centre_statement (school_id, id);
-- The school's own internal deadlines (a reference or statement due to the
-- counselor before the external one), per cycle and destination system (F32).
CREATE TABLE uni.school_deadline (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  cycle_year          smallint NOT NULL,
  destination_system  text NOT NULL REFERENCES ref.destination_system (key),
  kind                text NOT NULL CHECK (kind IN ('internal_reference','internal_statement','internal_application')),
  due_on              date NOT NULL,
  note                text,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, cycle_year, destination_system, kind)
);
-- Past letters a counselor uploads for voice matching, with explicit consent
-- and a retention class of their own (they may name other students).
CREATE TABLE uni.author_voice_sample (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  author_person_id  uuid NOT NULL,
  file_id           uuid NOT NULL,
  consented_at      timestamptz NOT NULL,
  contains_third_party_names boolean NOT NULL DEFAULT true,
  pseudonymised_file_id uuid,                         -- the version the model may read (pass 5)
  uploaded_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, author_person_id) REFERENCES core.person (school_id, id)
);

CREATE TABLE uni.ap_exam_registration (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id      uuid NOT NULL,
  exam_session_id uuid NOT NULL REFERENCES ref.exam_session (id),
  status          uni.exam_reg_status NOT NULL DEFAULT 'not_registered',
  registered_at   timestamptz,
  score           smallint CHECK (score BETWEEN 1 AND 5),
  scored_at       timestamptz,
  import_id       uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, student_id, exam_session_id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);

-- The application pack (the prototype's APP row), derived. The ten dimension
-- statuses are computed in packages/domain from this view plus the thresholds
-- in config.rule_set_version 'dimensions'.
CREATE VIEW uni.v_application_pack AS
  SELECT s.school_id, s.id AS student_id,
         (SELECT count(*) FROM uni.student_target t WHERE t.school_id = s.school_id AND t.student_id = s.id AND t.removed_at IS NULL) AS targets,
         (SELECT count(*) FROM uni.application a WHERE a.school_id = s.school_id AND a.student_id = s.id AND a.status = 'submitted') AS submitted,
         (SELECT count(*) FROM uni.offer o WHERE o.school_id = s.school_id AND o.student_id = s.id AND o.status IN ('conditional','unconditional')) AS offers,
         (SELECT min(d.due_at) FROM uni.application a JOIN ref.deadline d ON d.id = a.deadline_id
            WHERE a.school_id = s.school_id AND a.student_id = s.id AND a.status IN ('planned','in_progress')) AS next_deadline_at,
         (SELECT bool_and(uni.statement_complete(st.current_version_id)) FROM uni.statement st
            WHERE st.school_id = s.school_id AND st.student_id = s.id AND st.current_version_id IS NOT NULL) AS statements_complete,  -- F32: sections against their minimums, not characters against a ceiling
         (SELECT min(st.status) FROM uni.statement st WHERE st.school_id = s.school_id AND st.student_id = s.id) AS statement_status,
         (SELECT status FROM uni.document_request d WHERE d.school_id = s.school_id AND d.student_id = s.id AND d.kind = 'transcript' ORDER BY updated_at DESC LIMIT 1) AS transcript_status,
         (SELECT status FROM uni.document_request d WHERE d.school_id = s.school_id AND d.student_id = s.id AND d.kind = 'counselor_reference' ORDER BY updated_at DESC LIMIT 1) AS counselor_reference_status,
         (SELECT count(*) FROM uni.document_request d WHERE d.school_id = s.school_id AND d.student_id = s.id AND d.kind = 'teacher_reference' AND d.status NOT IN ('received','sent','final','complete')) AS teacher_references_outstanding,
         (SELECT status FROM uni.document_request d WHERE d.school_id = s.school_id AND d.student_id = s.id AND d.kind = 'school_form' ORDER BY updated_at DESC LIMIT 1) AS forms_status
  FROM sis.student s;

-- ============================================================================
-- 2.12 discovery: pathway discovery, approvals, the roadmap, XP
-- ============================================================================
CREATE TYPE discovery.session_stage AS ENUM ('survey','chat','narrowing','proposals','submitted','closed');
CREATE TYPE discovery.proposal_status AS ENUM ('pending','approved','amended','sent_back','superseded');

CREATE TABLE discovery.session (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  stage             discovery.session_stage NOT NULL DEFAULT 'survey',
  survey_key        text, survey_version smallint,
  survey_answers    jsonb NOT NULL DEFAULT '{}'::jsonb,
  survey_skipped    boolean NOT NULL DEFAULT false,
  chat_answers      jsonb NOT NULL DEFAULT '{}'::jsonb, -- f1..f3 and narrowing answers, keyed
  goal_focus        jsonb,                            -- {"focus":"university"|"industry"|"both","university":...}
  ranked_archetypes text[],                           -- rule output of the scorer (deterministic); model never ranks
  scorer_version    text,
  started_at        timestamptz NOT NULL DEFAULT now(),
  completed_at      timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
CREATE INDEX discovery_session_student ON discovery.session (school_id, student_id, started_at DESC);

CREATE TABLE discovery.message (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id    uuid NOT NULL,
  seq           integer NOT NULL,
  from_kind     text NOT NULL CHECK (from_kind IN ('student','assistant','system')),
  body          text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  generation_id uuid,                                 -- ai.generation for assistant turns
  safety_flag   jsonb,                                -- disclosure detection result (pass 5); routed to a human if set
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, session_id, seq),
  FOREIGN KEY (school_id, session_id) REFERENCES discovery.session (school_id, id)
);
CREATE TRIGGER discovery_message_append_only BEFORE UPDATE OR DELETE ON discovery.message
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- What the student submits and what the counselor decides. Reasons are
-- required on send-back and amendment: they become constraints for the next
-- generation (pass 5). The prototype captures no reason; the backend must.
CREATE TABLE discovery.pathway_proposal (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id            uuid NOT NULL,
  session_id            uuid NOT NULL,
  archetype_keys        text[] NOT NULL CHECK (cardinality(archetype_keys) BETWEEN 1 AND 3),
  archetype_version     smallint NOT NULL,
  subpaths              jsonb NOT NULL DEFAULT '{}'::jsonb, -- {"finance":"ib"}
  own_words             text,
  goal_focus            jsonb,
  status                discovery.proposal_status NOT NULL DEFAULT 'pending',
  submitted_at          timestamptz NOT NULL DEFAULT now(),
  decided_by_person_id  uuid,
  decided_at            timestamptz,
  decision_reasons      text,
  amendments            jsonb,                        -- inline edits to steps, applied to the approved roadmap
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, session_id) REFERENCES discovery.session (school_id, id),
  FOREIGN KEY (school_id, decided_by_person_id) REFERENCES core.person (school_id, id),
  CHECK (status NOT IN ('sent_back','amended') OR decision_reasons IS NOT NULL),
  CHECK (status = 'pending' OR (decided_by_person_id IS NOT NULL AND decided_at IS NOT NULL))
);
CREATE UNIQUE INDEX proposal_one_pending ON discovery.pathway_proposal (school_id, student_id) WHERE status = 'pending';

-- The roadmap the student actually sees: a snapshot of the archetype's steps
-- at approval, after amendments, so a later catalogue change does not silently
-- move the goalposts.
CREATE TABLE discovery.approved_pathway (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id            uuid NOT NULL,
  proposal_id           uuid NOT NULL,
  archetype_key         text NOT NULL,
  archetype_version     smallint NOT NULL,
  subpath_key           text,
  roadmap               jsonb NOT NULL,               -- [{"key":..,"title":..,"detail":..,"timeframe":..}]
  approved_by_person_id uuid NOT NULL,
  approved_at           timestamptz NOT NULL DEFAULT now(),
  active                boolean NOT NULL DEFAULT true,
  superseded_by_id      uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, proposal_id) REFERENCES discovery.pathway_proposal (school_id, id),
  FOREIGN KEY (archetype_key, archetype_version) REFERENCES ref.archetype (key, version)
);
CREATE TABLE discovery.roadmap_progress (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  approved_pathway_id uuid NOT NULL,
  step_key            text NOT NULL,
  done_at             timestamptz NOT NULL DEFAULT now(),
  undone_at           timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, approved_pathway_id) REFERENCES discovery.approved_pathway (school_id, id)
);
CREATE UNIQUE INDEX roadmap_step_done_once ON discovery.roadmap_progress (approved_pathway_id, step_key) WHERE undone_at IS NULL;

-- Gamification lives here and only here (invariant 10): the only tables that
-- can award points reference a student. The ledger is its own data class, `xp`,
-- which only the student reads (F77): as part of `discovery` it was readable by
-- parents, so invariant 10 held only on the writer.
CREATE TABLE discovery.xp_ledger (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id    uuid NOT NULL,
  points        integer NOT NULL,
  reason_kind   text NOT NULL,                        -- 'roadmap_step','cas_entry','statement_version', ...
  ref_table     text NOT NULL,
  ref_id        uuid NOT NULL,
  occurred_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  UNIQUE (school_id, reason_kind, ref_table, ref_id),  -- a milestone is worth points once
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
CREATE TRIGGER xp_ledger_append_only BEFORE UPDATE OR DELETE ON discovery.xp_ledger
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- "My network": the student's own list of warm contacts.
CREATE TABLE discovery.network_contact (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id        uuid NOT NULL,
  label             text NOT NULL,                    -- "My uncle"
  relation          text,                             -- "Family · Emirates NBD"
  is_warm           boolean NOT NULL DEFAULT true,
  mentor_pairing_id uuid,                             -- when the contact is a CAROS mentor
  created_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
```
```sql
-- ============================================================================
-- 2.13 family: guardians, messages, meeting requests, contact log
-- ============================================================================
-- Guardians are core.person rows of kind 'guardian'. The link is the security
-- object: a magic link signs a person in, but what they may see is decided by
-- verified links, and a link is verified from the SIS contacts import, not
-- from whoever holds the email address (§11.12). Revised by pass 8 (F57): one
-- person per SIS contact, never merged, even when two contacts share an email
-- address; activation is per contact and is required inside
-- auth.is_guardian_of(); a restriction imported from the SIS (a court order, a
-- "no contact" flag) suspends that contact's links and nobody else's. Pass 4
-- D42 adds activation_status and restriction. Guardians read their own link
-- rows and never write any (class guardian_link, F15).
CREATE TABLE family.guardian_link (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  guardian_person_id  uuid NOT NULL,
  student_id          uuid NOT NULL,
  relationship        text NOT NULL,                  -- "Mother", "Father", "Guardian"
  is_primary          boolean NOT NULL DEFAULT false,
  contact_pref        text,                           -- "WhatsApp", "Email", "Phone call" (recorded, not a channel CAROS uses in v1)
  consent_status      text NOT NULL DEFAULT 'unknown' CHECK (consent_status IN ('unknown','given','withdrawn')),
  consent_recorded_at timestamptz,
  verified_source     text CHECK (verified_source IN ('sis_import','school_admin')),
  verified_at         timestamptz,
  import_id           uuid,
  status              text NOT NULL DEFAULT 'active' CHECK (status IN ('active','ended')),
  ended_at            timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, guardian_person_id, student_id),
  FOREIGN KEY (school_id, guardian_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
CREATE INDEX guardian_link_by_guardian ON family.guardian_link (school_id, guardian_person_id) WHERE status = 'active';

CREATE TABLE family.message (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id            uuid NOT NULL,                -- the child the thread is about
  sender_person_id      uuid NOT NULL,
  recipient_person_id   uuid NOT NULL,
  body                  text NOT NULL,
  sent_at               timestamptz NOT NULL DEFAULT now(),
  read_at               timestamptz,
  channel               text NOT NULL DEFAULT 'in_app' CHECK (channel IN ('in_app')),  -- message bodies never go by email; a content-free email may say a message is waiting (§5.3, pass 4 §5.8)
  draft_generation_id   uuid,                         -- the AI draft it was edited from, if any
  in_reply_to_id        uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, sender_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, recipient_person_id) REFERENCES core.person (school_id, id)
);
CREATE INDEX family_message_thread ON family.message (school_id, student_id, sent_at);

CREATE TABLE family.meeting_slot (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  staff_person_id uuid NOT NULL,
  starts_at       timestamptz NOT NULL,
  ends_at         timestamptz NOT NULL,
  status          text NOT NULL DEFAULT 'open' CHECK (status IN ('open','requested','booked','cancelled')),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, staff_person_id) REFERENCES core.person (school_id, id),
  CHECK (ends_at > starts_at)
);
CREATE TABLE family.meeting_request (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  guardian_person_id  uuid NOT NULL,
  topic_key           text NOT NULL,                  -- config.vocabulary 'meeting_topic'
  slot_id             uuid,
  note                text,
  status              text NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','confirmed','declined','held','cancelled')),
  requested_at        timestamptz NOT NULL DEFAULT now(),
  decided_at          timestamptz,
  meeting_id          uuid,                           -- core.meeting once held
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, guardian_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, slot_id) REFERENCES family.meeting_slot (school_id, id),
  FOREIGN KEY (school_id, meeting_id) REFERENCES core.meeting (school_id, id)
);
CREATE TABLE family.contact_log (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id          uuid NOT NULL,
  guardian_person_id  uuid,
  by_person_id        uuid NOT NULL,
  channel             text NOT NULL CHECK (channel IN ('phone','email','in_person','message','other')),
  occurred_at         timestamptz NOT NULL DEFAULT now(),
  summary             text NOT NULL,
  case_id             uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, guardian_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, by_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, case_id) REFERENCES signal.case (school_id, id)
);

-- "Last contact" is derived: the latest of meetings and logged contacts.
CREATE VIEW signal.v_last_contact AS
  SELECT school_id, student_id, max(at) AS last_contact_at FROM (
    SELECT school_id, student_id, held_at AS at FROM core.meeting
    UNION ALL SELECT school_id, student_id, occurred_at FROM family.contact_log
  ) x GROUP BY school_id, student_id;

-- ============================================================================
-- 2.14 mentor: alumni volunteers, pairings, sessions, in-platform messages
-- ============================================================================
-- No email or phone columns anywhere in this schema: contact is in-platform
-- only (invariant 11). The word "match" does not appear; it is "pairing".
-- Revised by pass 8 (F59, C6). Every table's student subject is derived through
-- its pairing, and mentors read only their own pairing's rows (scope
-- own_pairing), never another mentor's thread with the same student. Parents
-- see only that a pairing exists and the mentor's headline
-- (mentor.v_family_pairing). A pairing is created only by the mentor
-- coordinator, and pairings and share_scope change only through the
-- coordinator's and the student's definer functions. v1 mentor contact is CAROS
-- messaging (holds and screening) and in-person sessions on school premises;
-- video on the school's platform is deferred until ADEK Digital Policy 6.4
-- consent and approval are in place (decision C6).
CREATE TABLE mentor.profile (
  school_id               uuid NOT NULL REFERENCES core.school (id),
  id                      uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id               uuid NOT NULL,
  headline                text,                       -- "Analyst, Investment Banking Division"
  employer                text,
  role_title              text,
  university              text,
  graduation_year         smallint,
  path_summary            text,                       -- "ACS → LSE Economics → Goldman Sachs IBD"
  expertise_tags          text[] NOT NULL DEFAULT '{}',
  verification_status     text NOT NULL DEFAULT 'unverified' CHECK (verification_status IN ('unverified','verified','suspended')),
  verified_by_person_id   uuid,
  verified_at             timestamptz,
  safeguarding_training_at timestamptz,
  agreement_signed_at     timestamptz,
  active                  boolean NOT NULL DEFAULT false,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, person_id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (school_id, verified_by_person_id) REFERENCES core.person (school_id, id),
  CHECK (active = false OR verification_status = 'verified')
);
CREATE TABLE mentor.pairing (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  mentor_profile_id   uuid NOT NULL,
  student_id          uuid NOT NULL,
  status              text NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','active','declined','ended')),
  arranged_by_person_id uuid,                         -- the school arranges introductions
  share_scope         jsonb NOT NULL DEFAULT '{"goal":true,"network":false}'::jsonb, -- what the student chose to share
  started_at          timestamptz,
  ended_at            timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, mentor_profile_id, student_id),
  FOREIGN KEY (school_id, mentor_profile_id) REFERENCES mentor.profile (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);
CREATE TABLE mentor.session_request (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  pairing_id          uuid NOT NULL,
  student_id          uuid NOT NULL,
  mentor_profile_id   uuid NOT NULL,
  goal                text,
  message             text,
  status              text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','alternative_proposed','declined','cancelled')),
  requested_at        timestamptz NOT NULL DEFAULT now(),
  decided_at          timestamptz,
  proposed_times      jsonb,
  decline_reason      text,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, pairing_id) REFERENCES mentor.pairing (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id),
  FOREIGN KEY (school_id, mentor_profile_id) REFERENCES mentor.profile (school_id, id)
);
CREATE TABLE mentor.session (
  school_id       uuid NOT NULL REFERENCES core.school (id),
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id      uuid NOT NULL,
  pairing_id      uuid NOT NULL,
  scheduled_at    timestamptz,
  held_at         timestamptz,
  duration_min    smallint,
  status          text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','held','missed','cancelled')),
  mode            text NOT NULL DEFAULT 'in_person_on_premises' CHECK (mode IN ('in_person_on_premises')),  -- v1 only (C6); video joins when ADEK 6.4 consent exists
  school_visible  boolean NOT NULL DEFAULT true,      -- the school is in the loop, by design
  recording_file_id uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, request_id) REFERENCES mentor.session_request (school_id, id),
  FOREIGN KEY (school_id, pairing_id) REFERENCES mentor.pairing (school_id, id)
);
CREATE TABLE mentor.message (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  pairing_id        uuid NOT NULL,
  sender_person_id  uuid NOT NULL,
  body              text NOT NULL,
  sent_at           timestamptz NOT NULL DEFAULT now(),
  read_at           timestamptz,
  safety_flag       jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, pairing_id) REFERENCES mentor.pairing (school_id, id),
  FOREIGN KEY (school_id, sender_person_id) REFERENCES core.person (school_id, id)
);
CREATE TRIGGER mentor_message_append_only BEFORE UPDATE OR DELETE ON mentor.message
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();
CREATE TABLE mentor.mentee_note (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  pairing_id        uuid NOT NULL,
  mentor_profile_id uuid NOT NULL,
  student_id        uuid NOT NULL,
  body              text NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  school_visible    boolean NOT NULL DEFAULT true,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, pairing_id) REFERENCES mentor.pairing (school_id, id),
  FOREIGN KEY (school_id, mentor_profile_id) REFERENCES mentor.profile (school_id, id),
  FOREIGN KEY (school_id, student_id) REFERENCES sis.student (school_id, id)
);

-- ============================================================================
-- 2.15 doc: files. Bytes live in object storage under a key that carries the
-- tenant; this table is the index, the classification and the retention.
-- ============================================================================
-- The policy reads each row's own data_class and kind (F15): a student or
-- parent never reads a reference letter, or a file classed case_note,
-- safeguarding or signal, because the table's class is no longer the file's.
-- Raw SIS exports (kind sis_export, sample_export, connector_snapshot) are
-- readable by the school_admin role only, under step-up, and never by support.
-- No user tier can update storage_key or any column but a draft's filename.
CREATE TABLE doc.file (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  kind                  text NOT NULL CHECK (kind IN ('sis_export','transcript','ee_draft','portfolio','reference_letter','voice_sample','statement_attachment','school_mark','mentor_recording','other')),
  storage_container     text NOT NULL,                -- bucket / container name
  storage_key           text NOT NULL,                -- '<school_id>/<kind>/<id>' : the tenant is in the path
  sha256                bytea NOT NULL,
  byte_size             bigint NOT NULL,
  content_type          text NOT NULL,
  original_filename     text,
  uploaded_by_person_id uuid,
  uploaded_at           timestamptz NOT NULL DEFAULT now(),
  subject_student_id    uuid,
  data_class            text NOT NULL REFERENCES auth.data_class (key),
  scan_status           text NOT NULL DEFAULT 'pending' CHECK (scan_status IN ('pending','clean','infected','failed')),
  retention_class       text NOT NULL,                -- privacy.retention_class
  deleted_at            timestamptz,                  -- soft; the object is removed by the retention job
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (storage_container, storage_key),
  FOREIGN KEY (school_id, subject_student_id) REFERENCES sis.student (school_id, id)
);
ALTER TABLE core.school ADD FOREIGN KEY (mark_file_id) REFERENCES doc.file (id);

-- ============================================================================
-- 2.16 ingest: sources, mapping profiles, imports. Pass 2 owns the pipeline;
-- these are the tables it writes to and every sis.* row points back to.
-- ============================================================================
CREATE TABLE ingest.source_system (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  kind        text NOT NULL,                          -- config.vocabulary 'source_system_kind'; was a CHECK naming ACS's incumbents (F65)
  name        text NOT NULL,
  config      jsonb NOT NULL DEFAULT '{}'::jsonb,     -- never secrets; those live in the key vault by reference
  active      boolean NOT NULL DEFAULT true,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, name)
);
-- A school's column mapping, as data, versioned. The shape of `mapping` is
-- pass 2's; whatever it is, it is validated against a published JSON schema.
CREATE TABLE ingest.mapping_profile (
  school_id         uuid NOT NULL REFERENCES core.school (id),
  id                uuid NOT NULL DEFAULT gen_random_uuid(),
  source_system_id  uuid NOT NULL,
  import_kind       text NOT NULL,                    -- 'grades','attendance','behaviour','roster','timetable','contacts','calendar','enrolment'
  version           integer NOT NULL,
  mapping           jsonb NOT NULL,
  schema_version    text NOT NULL,
  status            text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','retired')),
  created_by        text NOT NULL,                    -- a person id or a CAROS operator
  created_at        timestamptz NOT NULL DEFAULT now(),
  note              text,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, source_system_id, import_kind, version),
  FOREIGN KEY (school_id, source_system_id) REFERENCES ingest.source_system (school_id, id)
);
CREATE TABLE ingest.import (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  source_system_id    uuid NOT NULL,
  mapping_profile_id  uuid,
  file_id             uuid,                           -- the raw export, retained under its retention class
  import_kind         text NOT NULL,
  idempotency_key     text NOT NULL,                  -- sha256 of file + profile version: a re-upload is the same import
  status              text NOT NULL DEFAULT 'uploaded' CHECK (status IN ('uploaded','validating','validated','dry_run','committing','committed','failed','rolled_back')),
  uploaded_by         text NOT NULL,                  -- for roster, staff, contacts and caseload imports, the approver (pass 2 D3's approved_by) must be a different person, and these never auto-approve (F57)
  uploaded_at         timestamptz NOT NULL DEFAULT now(),
  validated_at        timestamptz,
  committed_at        timestamptz,
  rolled_back_at      timestamptz,
  supersedes_import_id uuid,
  summary             jsonb NOT NULL DEFAULT '{}'::jsonb, -- counts: inserted, superseded, rejected, unchanged
  error               jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, idempotency_key),
  FOREIGN KEY (school_id, source_system_id) REFERENCES ingest.source_system (school_id, id),
  FOREIGN KEY (school_id, mapping_profile_id) REFERENCES ingest.mapping_profile (school_id, id),
  FOREIGN KEY (school_id, file_id) REFERENCES doc.file (school_id, id)
);
-- A synthetic tenant may only import fixtures; a real tenant may not import fixtures.
CREATE FUNCTION ingest.check_classification() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_class core.data_classification; v_kind text;
BEGIN
  SELECT data_classification INTO v_class FROM core.school WHERE id = NEW.school_id;
  SELECT kind INTO v_kind FROM ingest.source_system WHERE id = NEW.source_system_id;
  IF v_class = 'synthetic' AND v_kind <> 'fixture' THEN
    RAISE EXCEPTION 'synthetic tenant % may only import fixtures', NEW.school_id;
  ELSIF v_class = 'real' AND v_kind = 'fixture' THEN
    RAISE EXCEPTION 'real tenant % may not import fixtures', NEW.school_id;
  END IF;
  RETURN NEW;
END $$;
ALTER FUNCTION ingest.check_classification() OWNER TO caros_policy;
CREATE TRIGGER import_classification BEFORE INSERT ON ingest.import
  FOR EACH ROW EXECUTE FUNCTION ingest.check_classification();

CREATE TABLE ingest.import_rejection (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  import_id   uuid NOT NULL,
  row_no      integer NOT NULL,
  reason_code text NOT NULL,
  reason      text NOT NULL,
  raw_row     jsonb,                                  -- personal data; shortest retention class
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, import_id) REFERENCES ingest.import (school_id, id)
);
-- What an import touched, so it can be rolled back row by row.
CREATE TABLE ingest.import_change (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  import_id   uuid NOT NULL,
  table_name  text NOT NULL,
  row_id      uuid NOT NULL,
  op          text NOT NULL CHECK (op IN ('insert','supersede','update')),
  previous    jsonb,
  PRIMARY KEY (import_id, table_name, row_id),
  FOREIGN KEY (school_id, import_id) REFERENCES ingest.import (school_id, id)
);

-- ============================================================================
-- 2.17 ai: model configuration and every generation. Pass 5 owns the content.
-- ============================================================================
-- Feature keys follow pass 5 D74 (§12.8 of the pass 7 review), less the two
-- features Davide removed from v1: headline_rephrase (F52) and safety_screen,
-- which runs as a lexicon with no model (decision C1). letter_draft is added
-- when the letter engine is built. covered_model and zdr_eligible live on
-- pass 5's ai.model registry (D62), not here (§12.9).
CREATE TABLE ai.model_config (
  school_id       uuid REFERENCES core.school (id),   -- NULL = platform default
  id              uuid NOT NULL DEFAULT gen_random_uuid(),
  feature         text NOT NULL CHECK (feature IN ('copilot','discovery_chat','pathway_analysis','meeting_brief','parent_email_draft','ee_feedback','statement_read','quarantined_reader')),
  provider        text NOT NULL,                      -- 'anthropic','bedrock','foundry'
  model_id        text NOT NULL,                      -- never in code
  params          jsonb NOT NULL DEFAULT '{}'::jsonb, -- effort, max tokens, temperature
  prompt_version  text NOT NULL,                      -- git tag of the template in packages/ai/prompts
  active_from     timestamptz NOT NULL DEFAULT now(),
  active_to       timestamptz,
  created_by      text NOT NULL,
  eval_run_ref    text,                               -- the evaluation this configuration passed (pass 5)
  PRIMARY KEY (id),
  UNIQUE NULLS NOT DISTINCT (school_id, feature, active_from)
);
CREATE TABLE ai.generation (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  feature               text NOT NULL,
  model_config_id       uuid NOT NULL REFERENCES ai.model_config (id),
  model_id              text NOT NULL,                -- copied, so the row is self-describing after config changes
  prompt_version        text NOT NULL,
  requested_by_person_id uuid,
  subject_student_id    uuid,
  input_refs            jsonb NOT NULL DEFAULT '[]'::jsonb, -- record ids the prompt was built from, never the text
  pseudonym_map_id      uuid,
  output_text           text,
  output_json           jsonb,
  status                text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','succeeded','failed','refused','timed_out')),
  review_status         text NOT NULL DEFAULT 'unreviewed' CHECK (review_status IN ('unreviewed','approved','edited','rejected','not_applicable')),
  reviewed_by_person_id uuid,
  reviewed_at           timestamptz,
  input_tokens          integer, output_tokens integer, cached_tokens integer,
  cost_usd              numeric(10,6),
  latency_ms            integer,
  safety_flags          jsonb,
  created_at            timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, subject_student_id) REFERENCES sis.student (school_id, id)
);
CREATE INDEX generation_student ON ai.generation (school_id, subject_student_id, created_at DESC);
-- Reversible pseudonymisation for what leaves the region (pass 4 rule, pass 5
-- mechanism). No tier reads it: re-identification is ai.reidentify(generation),
-- a definer function that checks the requester is the generation's requester,
-- or holds read on its subject, in the current school (F44).
CREATE TABLE ai.pseudonym_map (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  generation_id uuid,
  mapping_enc   bytea NOT NULL,                       -- encrypted with the tenant key; {token: real value}
  created_at    timestamptz NOT NULL DEFAULT now(),
  expires_at    timestamptz NOT NULL,
  PRIMARY KEY (id), UNIQUE (school_id, id)
);

-- ============================================================================
-- 2.18 notify: the transactional outbox. Nothing is sent from a request
-- handler; a row is written in the same transaction as the action, through
-- notify.enqueue() (§2.4), and the worker delivers it. Payloads carry no
-- welfare detail (pass 4 owns the rule). Every outbound message kind is listed
-- in pass 4 §5.8, with its recipient, channel and content allowlist, following
-- decisions C2 and C3; a template not on that list does not exist (F28).
-- ============================================================================
CREATE TABLE notify.template (
  key         text NOT NULL,                          -- the email keys of pass 4 §5.8: 'magic_link','parent_update_waiting','student_deadline_nudge','safeguarding_escalation','escalation_reminder','safety_alert_notice','alert_unopened_notice','grooming_alert'; every other kind is in_app
  version     integer NOT NULL,
  channel     text NOT NULL CHECK (channel IN ('email','in_app')),
  subject     text,
  body        text NOT NULL,                          -- handlebars-style; variables validated against `variables`
  variables   jsonb NOT NULL,                         -- the allowlist; pass 4 D47 adds the CHECK
  sender_roles text[] NOT NULL DEFAULT '{}',          -- acting roles that may cause it; system-sent templates list none (F02)
  active      boolean NOT NULL DEFAULT true,
  PRIMARY KEY (key, version)
);
CREATE TABLE notify.outbox (
  school_id             uuid NOT NULL REFERENCES core.school (id),
  id                    uuid NOT NULL DEFAULT gen_random_uuid(),
  channel               text NOT NULL CHECK (channel IN ('email','in_app')),
  recipient_person_id   uuid NOT NULL,
  recipient_address     citext,                       -- snapshot at enqueue time
  template_key          text NOT NULL,
  template_version      integer NOT NULL,
  payload               jsonb NOT NULL,
  dedupe_key            text NOT NULL,                -- e.g. 'nudge:<application_id>:T-7'; deduplicates at enqueue
  -- Deduplication at send (F77): the worker passes the outbox id to the email
  -- provider as the request's idempotency key and keeps provider_message_id, so
  -- a retry after an unclear response cannot send an escalation email twice.
  -- No payload ever holds a credential: invitation and magic-link tokens are
  -- minted by the worker at send time and exist only as hashes (F16).
  status                text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','sending','sent','delivered','bounced','failed','suppressed')),
  provider              text,
  provider_message_id   text,
  attempts              smallint NOT NULL DEFAULT 0,
  queued_at             timestamptz NOT NULL DEFAULT now(),
  not_before            timestamptz,
  sent_at               timestamptz,
  last_error            text,
  related_table         text, related_id uuid,
  PRIMARY KEY (id), UNIQUE (school_id, id), UNIQUE (school_id, dedupe_key),
  FOREIGN KEY (school_id, recipient_person_id) REFERENCES core.person (school_id, id),
  FOREIGN KEY (template_key, template_version) REFERENCES notify.template (key, version)
);
CREATE INDEX outbox_queue ON notify.outbox (school_id, status, not_before) WHERE status = 'queued';
-- The worker finds which schools have due rows through notify.schools_with_due_outbox(),
-- a definer function returning school ids only (F36), then delivers inside each school's transaction.
ALTER TABLE signal.escalation ADD FOREIGN KEY (school_id, notification_id) REFERENCES notify.outbox (school_id, id);
CREATE TABLE notify.preference (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  person_id   uuid NOT NULL,
  kind        text NOT NULL,                          -- 'deadline_nudge','checkpoint_nudge'
  channel     text NOT NULL,
  enabled     boolean NOT NULL DEFAULT true,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (person_id, kind, channel),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);
CREATE TABLE notify.in_app (
  school_id   uuid NOT NULL REFERENCES core.school (id),
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id   uuid NOT NULL,
  kind        text NOT NULL,
  payload     jsonb NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  read_at     timestamptz,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, person_id) REFERENCES core.person (school_id, id)
);

-- ============================================================================
-- 2.19 audit: append-only, records access as well as change
-- ============================================================================
-- `detail` holds identifiers and enumerations only. Names, note text, reasons
-- and message bodies are never written here: the entry points at the record,
-- and the record can be erased without breaking the log.
--
-- The taxonomy is one list (§12.16 of the pass 7 review): the keys below, pass 2
-- D9, pass 4 D48 (which carries pass 8's additions) and pass 5 D71 are seeded
-- together in B0 from packages/contracts/audit/actions.json. Each key appears
-- once: PREVIEW_ACCESS belongs to pass 2 D9 and not to D48; the event
-- sweep.completed belongs to §2.20 and not to pass 3 D28.
CREATE TYPE audit.actor_kind AS ENUM ('user','system','support','ingest');

CREATE TABLE audit.action (
  key           text PRIMARY KEY,
  category      text NOT NULL CHECK (category IN ('access','change','auth','config','ai','system')),
  description   text NOT NULL,
  -- which tiers may write this action through audit.record() (F75). Empty
  -- means none: the seed sets each key's list from actions.json, so a key
  -- nobody has placed is refused rather than open to every tier.
  allowed_tiers auth.privilege_tier[] NOT NULL DEFAULT '{}'
);
INSERT INTO audit.action VALUES
 -- access (new: the prototype seeded FILE_ACCESS but never wrote it)
 ('FILE_ACCESS','access','A staff member opened a student''s file'),
 ('CASE_ACCESS','access','A case file was opened'),
 ('NOTE_ACCESS','access','Counselor notes were read'),
 ('SAFEGUARDING_ACCESS','access','An escalation record was read'),
 ('DOCUMENT_ACCESS','access','A file was downloaded'),
 ('AUDIT_ACCESS','access','The audit log was read'),
 ('EXPORT','access','A report or list was exported'),
 -- engine
 ('SWEEP_COMPLETED','system','A nightly sweep finished'),
 ('CASE_OPENED','change','A case was opened'),
 ('PRIORITY_SET','change','The engine set or changed a tier'),
 ('SIGNAL_RAISED','system','A rule fired'),
 -- counselor
 ('CASE_ACCEPTED','change',''), ('CASE_ACKNOWLEDGED','change','Marked as seen'), ('CASE_DISMISSED','change',''),
 ('PRIORITY_CHANGE','change','A person changed a tier'), ('CONTEXT_ADDED','change',''), ('CASE_NOTE','change',''),
 ('CASE_MERGED','change',''), ('FLAG_ATTACHED','change',''), ('CASE_REASSIGNED','change',''), ('CASE_CLOSED','change',''),
 ('ESCALATED_SAFEGUARDING','change',''), ('ESCALATION_ACKNOWLEDGED','change',''),
 ('PARENT_CONTACT','change',''), ('MEETING_SCHEDULED','change',''), ('MEETING_RECORDED','change',''),
 ('BULK_ACKNOWLEDGED','change','Bulk mark-as-seen'), ('BULK_REASSIGNED','change',''),
 ('THRESHOLD_SAVED','config','A rule set version was saved'), ('RULE_SET_SAVED','config',''),
 ('COPILOT_QUERY','ai',''), ('AI_DRAFT','ai','A generation was produced'), ('AI_REVIEWED','ai','A generation was approved, edited or rejected'),
 ('SUBJECT_REVIEW','change',''), ('SUBJECTS_APPROVED','change',''), ('SUBJECTS_RETURNED','change',''),
 ('CAS_NUDGE','change',''), ('CAS_REVIEWED','change',''), ('EE_ASSIGNED','change',''),
 ('PATHWAY_APPROVED','change',''), ('PATHWAY_AMENDED','change',''), ('PATHWAY_SENT_BACK','change',''),
 ('PS_REVIEWED','change',''), ('LETTER_VERSION','change',''), ('DOCUMENT_CHASED','change',''),
 -- teacher
 ('TEACHER_FLAG','change',''), ('SUBJECT_SIGNOFF','change',''),
 ('EE_SUPERVISOR','change',''), ('EE_REFINE','change',''), ('EE_PASSED','change',''), ('EE_REFLECTION','change',''),
 -- student
 ('DISCOVERY_SUBMITTED','change',''), ('SUBJECTS_SENT','change',''), ('SELECTION_SLOT_REQUESTED','change',''),
 ('CAS_ENTRY','change',''), ('CAS_REFLECTION','change',''), ('EE_PROPOSED','change',''), ('PS_SUBMITTED','change',''),
 ('ROADMAP_STEP','change',''), ('MENTOR_REQUESTED','change',''), ('STUDENT_REFLECTION','change',''),
 -- parent
 ('PARENT_MESSAGE','change',''), ('MEETING_REQUEST','change',''),
 -- mentor
 ('MENTOR_ACCEPTED','change',''), ('MENTOR_DECLINED','change',''), ('MENTOR_NOTE','change',''), ('MENTOR_MESSAGE','change',''),
 -- auth & admin
 ('SIGN_IN','auth',''), ('SIGN_OUT','auth',''), ('MAGIC_LINK_SENT','auth',''), ('MAGIC_LINK_CONSUMED','auth',''),
 ('STEP_UP','auth',''), ('SESSION_REVOKED','auth',''),
 ('MEMBERSHIP_CHANGED','config',''), ('CASELOAD_ASSIGNED','config',''), ('COVER_GRANTED','config',''),
 ('SUPPORT_GRANT','config','Break-glass granted'), ('SUPPORT_ACCESS','access','Break-glass read'),
 ('IMPORT_COMMITTED','change',''), ('IMPORT_ROLLED_BACK','change',''), ('MAPPING_PROFILE_SAVED','config',''),
 ('ERASURE_REQUESTED','change',''), ('ERASURE_EXECUTED','change',''), ('RETENTION_PURGE','system','');

CREATE TABLE audit.entry (
  school_id           uuid NOT NULL REFERENCES core.school (id),   -- a school row is never deleted (§2.3), so the log keeps its FK (§12.3)
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  occurred_at         timestamptz NOT NULL DEFAULT now(),
  actor_kind          audit.actor_kind NOT NULL,
  actor_person_id     uuid,
  actor_label         text,                           -- operator id for support/ingest actors
  acting_role         text,
  action              text NOT NULL REFERENCES audit.action (key),
  object_table        text,
  object_id           uuid,
  subject_student_id  uuid,
  purpose             text,                           -- for access entries: 'case_review','meeting_prep','support_ticket:1234'
  detail              jsonb NOT NULL DEFAULT '{}'::jsonb,
  request_id          uuid,
  session_id          uuid,
  prev_hash           bytea,
  entry_hash          bytea,
  PRIMARY KEY (school_id, occurred_at, id)
) PARTITION BY RANGE (occurred_at);
CREATE INDEX audit_subject ON audit.entry (school_id, subject_student_id, occurred_at DESC);
CREATE INDEX audit_actor ON audit.entry (school_id, actor_person_id, occurred_at DESC);
CREATE INDEX audit_action ON audit.entry (school_id, action, occurred_at DESC);

-- Per-school hash chain. Whether tamper evidence is warranted is pass 4's
-- call; the cost of computing it is a digest per row, so it is on by default.
CREATE FUNCTION audit.chain() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_prev bytea;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(NEW.school_id::text));
  SELECT entry_hash INTO v_prev FROM audit.entry
   WHERE school_id = NEW.school_id ORDER BY occurred_at DESC, id DESC LIMIT 1;
  NEW.prev_hash  := v_prev;
  NEW.entry_hash := digest(COALESCE(encode(v_prev, 'hex'), '') || NEW.id::text || NEW.occurred_at::text ||
                           NEW.action || COALESCE(NEW.actor_person_id::text, NEW.actor_label, '') ||
                           COALESCE(NEW.object_table, '') || COALESCE(NEW.object_id::text, '') ||
                           COALESCE(NEW.subject_student_id::text, '') || NEW.detail::text, 'sha256');
  RETURN NEW;
END $$;
ALTER FUNCTION audit.chain() OWNER TO caros_policy;
CREATE TRIGGER audit_chain BEFORE INSERT ON audit.entry FOR EACH ROW EXECUTE FUNCTION audit.chain();
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON audit.entry
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- The only way to write an audit entry. The school, the actor and the session
-- come from the transaction context, never from the caller, so an entry cannot
-- be written against another school or under another name. Every tier may
-- call it; no tier may INSERT into audit.entry directly. Pass 8 (F75): the
-- action must list the caller's tier in audit.action.allowed_tiers, so a
-- student session cannot write ESCALATED_SAFEGUARDING about anyone; the tier
-- is the acting role's, read from the membership, because inside this
-- function current_user is its owner.
CREATE FUNCTION audit.record(
  p_action text, p_object_table text DEFAULT NULL, p_object_id uuid DEFAULT NULL,
  p_subject_student uuid DEFAULT NULL, p_purpose text DEFAULT NULL, p_detail jsonb DEFAULT '{}'::jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = audit, auth, pg_temp AS $$
DECLARE v_id uuid; v_tier auth.privilege_tier;
BEGIN
  IF auth.current_school() IS NULL THEN RAISE EXCEPTION 'audit.record called with no tenant context'; END IF;
  v_tier := CASE auth.actor_kind() WHEN 'system' THEN 'system' WHEN 'support' THEN 'support' WHEN 'ingest' THEN 'system'
              ELSE (SELECT r.tier FROM auth.role r WHERE r.key = auth.current_role_key()) END;
  IF NOT EXISTS (SELECT 1 FROM audit.action a WHERE a.key = p_action AND v_tier = ANY (a.allowed_tiers)) THEN
    RAISE EXCEPTION 'tier % may not write audit action %', v_tier, p_action;
  END IF;
  INSERT INTO audit.entry (school_id, actor_kind, actor_person_id, actor_label, acting_role, action,
                           object_table, object_id, subject_student_id, purpose, detail, request_id, session_id)
  VALUES (auth.current_school(),
          CASE auth.actor_kind() WHEN 'system' THEN 'system' WHEN 'support' THEN 'support' WHEN 'ingest' THEN 'ingest' ELSE 'user' END::audit.actor_kind,
          auth.current_person(),
          NULLIF(current_setting('app.actor_label', true), ''),
          auth.current_role_key(), p_action, p_object_table, p_object_id, p_subject_student, p_purpose, p_detail,
          NULLIF(current_setting('app.request_id', true), '')::uuid,
          NULLIF(current_setting('app.session_id', true), '')::uuid)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;
ALTER FUNCTION audit.record(text, text, uuid, uuid, text, jsonb) OWNER TO caros_policy;

-- ============================================================================
-- 2.20 events: the product event stream the reporting metrics are computed from
-- ============================================================================
-- Distinct from audit: events are about the product's own state changes and
-- are what CONTEXT.md §11.2 needs to turn targets into measurements. Written
-- in the same transaction as the change, through one domain function, so an
-- action cannot happen without its event.
CREATE TABLE events.name (
  key           text PRIMARY KEY,
  description   text NOT NULL,
  metric        text,                                 -- which reporting metric it feeds
  allowed_tiers auth.privilege_tier[] NOT NULL DEFAULT '{}'   -- set by the seed, as for audit.action (F75)
);
INSERT INTO events.name VALUES
 ('sweep.completed','A sweep finished for a school','sweep_reliability'),
 ('signal.raised','A rule fired on a student','detection'),
 ('case.opened','A case was opened','detection'),
 ('case.tier_changed','Tier moved (engine or person)','detection'),
 ('case.viewed','A counselor opened the case file','time_to_aware'),
 ('case.seen','Marked as seen on the sheet','time_to_aware'),
 ('case.accepted','Counselor accepted the case','accept_rate'),
 ('case.dismissed','Counselor dismissed the case','dismiss_rate'),
 ('case.downgraded','Counselor lowered the tier','accept_rate'),
 ('case.context_added','Counselor added context','accept_rate'),
 ('case.escalated','Escalated to the safeguarding lead','safeguarding'),
 ('escalation.acknowledged','The safeguarding lead acknowledged','safeguarding'),
 ('case.closed','Case closed with an outcome','intervention'),
 ('intervention.opened','An intervention was opened','time_to_first_review'),
 ('intervention.step_done','A plan step was completed','follow_up'),
 ('intervention.follow_up_due','Follow-up date reached','follow_up'),
 ('intervention.follow_up_done','Follow-up completed','follow_up'),
 ('intervention.resolved','Intervention resolved with an outcome','intervention'),
 ('recovery.detected','Signals returned inside the band after an intervention','recovery'),
 ('relapse.detected','A closed case relapsed inside its window','recovery'),
 ('flag.submitted','A teacher logged a flag','teacher_loop'),
 ('flag.routed','A counselor acted on a flag and the teacher was told','teacher_loop'),
 ('meeting.recorded','A meeting was recorded','efficiency'),
 ('brief.generated','A meeting brief was generated','efficiency'),
 ('brief.used','A brief was opened before the meeting','efficiency'),
 ('letter.drafted','A letter draft was produced','efficiency'),
 ('letter.finalised','A letter was finalised','efficiency'),
 ('selection.submitted','','ib'), ('selection.signed','','ib'), ('selection.approved','','ib'), ('selection.returned','','ib'),
 ('ee.proposed','','ib'), ('ee.confirmed','','ib'), ('ee.reflection_recorded','','ib'), ('ee.milestone_overdue','','ib'),
 ('application.deadline_nudge_sent','','university'), ('application.submitted','','university'), ('offer.received','','university'),
 ('document.chased','','university'), ('document.received','','university'),
 ('list.balanced','A list gained its first safety','university'),
 ('pathway.submitted','','discovery'), ('pathway.approved','','discovery'), ('pathway.sent_back','','discovery'),
 ('roadmap.step_done','','discovery'),
 ('statement.submitted','','university'), ('statement.reviewed','','university'),
 ('portal.session','A student or parent opened the portal','engagement'),
 ('import.committed','','ingest'),
 ('ai.generation','','ai'), ('ai.reviewed','','ai'), ('ai.safety_flag','','safeguarding');

CREATE TABLE events.event (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  occurred_at         timestamptz NOT NULL DEFAULT now(),
  name                text NOT NULL REFERENCES events.name (key),
  actor_kind          audit.actor_kind NOT NULL,
  actor_person_id     uuid,
  subject_student_id  uuid,
  case_id             uuid,
  signal_id           uuid,
  intervention_id     uuid,
  object_table        text, object_id uuid,
  payload             jsonb NOT NULL DEFAULT '{}'::jsonb,   -- identifiers and enumerations only
  request_id          uuid,
  PRIMARY KEY (school_id, occurred_at, id)
) PARTITION BY RANGE (occurred_at);
CREATE INDEX event_case ON events.event (school_id, case_id, occurred_at);
CREATE INDEX event_name_time ON events.event (school_id, name, occurred_at);
CREATE TRIGGER event_append_only BEFORE UPDATE OR DELETE ON events.event
  FOR EACH ROW EXECUTE FUNCTION core.forbid_change();

-- The only way to emit an event; same contract as audit.record(), including
-- the per-tier allowlist (events.name.allowed_tiers, F75).
CREATE FUNCTION events.emit(
  p_name text, p_subject_student uuid DEFAULT NULL, p_case_id uuid DEFAULT NULL, p_signal_id uuid DEFAULT NULL,
  p_intervention_id uuid DEFAULT NULL, p_object_table text DEFAULT NULL, p_object_id uuid DEFAULT NULL,
  p_payload jsonb DEFAULT '{}'::jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = events, auth, pg_temp AS $$
DECLARE v_id uuid; v_tier auth.privilege_tier;
BEGIN
  IF auth.current_school() IS NULL THEN RAISE EXCEPTION 'events.emit called with no tenant context'; END IF;
  v_tier := CASE auth.actor_kind() WHEN 'system' THEN 'system' WHEN 'support' THEN 'support' WHEN 'ingest' THEN 'system'
              ELSE (SELECT r.tier FROM auth.role r WHERE r.key = auth.current_role_key()) END;
  IF NOT EXISTS (SELECT 1 FROM events.name n WHERE n.key = p_name AND v_tier = ANY (n.allowed_tiers)) THEN
    RAISE EXCEPTION 'tier % may not emit event %', v_tier, p_name;
  END IF;
  INSERT INTO events.event (school_id, name, actor_kind, actor_person_id, subject_student_id, case_id, signal_id,
                            intervention_id, object_table, object_id, payload, request_id)
  VALUES (auth.current_school(), p_name,
          CASE auth.actor_kind() WHEN 'system' THEN 'system' WHEN 'support' THEN 'support' WHEN 'ingest' THEN 'ingest' ELSE 'user' END::audit.actor_kind,
          auth.current_person(), p_subject_student, p_case_id, p_signal_id, p_intervention_id, p_object_table, p_object_id,
          p_payload, NULLIF(current_setting('app.request_id', true), '')::uuid)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;
ALTER FUNCTION events.emit(text, uuid, uuid, uuid, uuid, text, uuid, jsonb) OWNER TO caros_policy;

-- The four metric families in CONTEXT.md §11.2, as queries over the stream.
-- Each returns per-case rows; reporting aggregates them per school and period.
CREATE VIEW events.v_case_timeline AS
  SELECT school_id, case_id,
         min(occurred_at) FILTER (WHERE name = 'case.opened')                          AS opened_at,
         min(occurred_at) FILTER (WHERE name IN ('case.viewed','case.seen'))           AS first_aware_at,
         min(occurred_at) FILTER (WHERE name IN ('case.accepted','case.dismissed','case.downgraded')) AS first_decision_at,
         min(occurred_at) FILTER (WHERE name = 'intervention.opened')                  AS first_intervention_at,
         bool_or(name = 'case.accepted')                                               AS accepted,
         bool_or(name = 'case.dismissed')                                              AS dismissed,
         bool_or(name = 'intervention.follow_up_done')                                 AS follow_up_completed,
         bool_or(name = 'recovery.detected')                                           AS recovered,
         bool_or(name = 'relapse.detected')                                            AS relapsed,
         min(occurred_at) FILTER (WHERE name = 'case.closed')                          AS closed_at
  FROM events.event WHERE case_id IS NOT NULL GROUP BY school_id, case_id;
-- Median time from change to counselor aware = percentile_cont(0.5) over
-- (first_aware_at - opened_at); accept rate = accepted / (accepted + dismissed);
-- follow-up completion = follow_up_completed over cases with an intervention;
-- recovery after intervention = recovered over cases with an intervention.

-- ============================================================================
-- 2.21 privacy: the registry, retention classes, erasure
-- ============================================================================
CREATE TABLE privacy.retention_class (
  key             text PRIMARY KEY,
  description     text NOT NULL,
  proposed_days   integer,                            -- NULL = until counsel sets it; see pass 4
  after_expiry    text NOT NULL CHECK (after_expiry IN ('delete','anonymise','archive')),
  legal_note      text
);
INSERT INTO privacy.retention_class VALUES
 ('raw_import','Raw SIS export files and rejected rows',90,'delete','Needed only to re-run or dispute an import'),
 ('engagement','Platform and LMS activity events',180,'delete','Shortest class: minor''s behavioural telemetry'),
 ('academic','Grades, attendance, behaviour, enrolment',NULL,'anonymise','Counsel to set; ADEK/KHDA retention rules unknown'),
 ('welfare','Cases, signals, notes, evidence, interventions, meetings',NULL,'anonymise','Counsel to set; safeguarding records often carry long statutory minimums'),
 ('safeguarding','Escalations',NULL,'archive','Counsel to set; expect the longest minimum'),
 ('application','University targets, applications, documents, statements, letters',NULL,'anonymise','Counsel to set'),
 ('ai_generation','Model inputs and outputs',365,'delete','Pass 5 may shorten'),
 ('audit','Audit entries',NULL,'archive','Kept beyond erasure by design; identifiers only'),
 ('events','Product events',NULL,'anonymise','Aggregate reporting survives anonymisation'),
 ('session','Sessions, magic links',30,'delete',''),
 ('voice_sample','Counselors'' past letters',NULL,'delete','Deleted when the author leaves the school');

-- Every tenant table, its data class, its subject column, its PII columns and
-- its retention class. The build fails if a table is missing here.
CREATE TABLE privacy.table_registry (
  schema_name     text NOT NULL,
  table_name      text NOT NULL,
  data_class      text NOT NULL REFERENCES auth.data_class (key),
  subject_column  text,                               -- the student column, if any
  person_column   text,                               -- the person column, if the row is about a person who is not a student
  pii_columns     text[] NOT NULL DEFAULT '{}',       -- scrubbed on erasure
  retention_class text NOT NULL REFERENCES privacy.retention_class (key),
  timestamp_column text,                              -- the column retention is measured from
  -- per tier, the columns it may UPDATE (and INSERT); §2.22 generates the
  -- column-level grants from this and a test compares them (F15, F17)
  writable_columns jsonb NOT NULL DEFAULT '{}',       -- {"student": ["goal_note"], "staff": [...]}
  PRIMARY KEY (schema_name, table_name)
);

-- A school may keep a class longer or shorter than the platform schedule, within
-- its regulator's minimums (F65): one global schedule reasoned from ADEK meant a
-- KHDA school could not differ. The retention job reads the override first.
CREATE TABLE privacy.retention_override (
  school_id        uuid NOT NULL REFERENCES core.school (id),
  retention_class  text NOT NULL REFERENCES privacy.retention_class (key),
  proposed_days    integer,
  proposed_rule    text,                              -- e.g. 'until_25th_birthday_or_10y_after_leaving'
  reason           text NOT NULL,
  set_by_person_id uuid NOT NULL,
  set_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (school_id, retention_class),
  FOREIGN KEY (school_id, set_by_person_id) REFERENCES core.person (school_id, id)
);

-- Stores that hold personal data outside the tenant tables (F36), so erasure
-- and retention reach them: the pg-boss queue (payloads are ids only; completed
-- jobs deleted after 7 days; archiving off), the email provider's delivery
-- status (polled, not pushed through Event Grid, pass 4 §5.5), and any other
-- store a later pass adds. The registry test fails if one is missing.
CREATE TABLE privacy.non_tenant_store (
  key             text PRIMARY KEY,                   -- 'pgboss.job','acs_email.delivery_status'
  description     text NOT NULL,
  holds           text NOT NULL,                      -- what personal data, in words
  retention       text NOT NULL,
  erasure_method  text NOT NULL
);

CREATE TABLE privacy.erasure_request (
  school_id           uuid NOT NULL REFERENCES core.school (id),
  id                  uuid NOT NULL DEFAULT gen_random_uuid(),
  subject_person_id   uuid NOT NULL,
  requested_by        text NOT NULL,                  -- person id or operator
  requested_at        timestamptz NOT NULL DEFAULT now(),
  legal_basis         text NOT NULL,
  status              text NOT NULL DEFAULT 'received' CHECK (status IN ('received','verified','scheduled','executed','refused')),
  scheduled_for       timestamptz,
  executed_at         timestamptz,
  executed_by         text,
  refusal_reason      text,
  scope               jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (id), UNIQUE (school_id, id),
  FOREIGN KEY (school_id, subject_person_id) REFERENCES core.person (school_id, id)
);
CREATE TABLE privacy.erasure_log (
  school_id     uuid NOT NULL REFERENCES core.school (id),
  id            uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id    uuid NOT NULL,
  schema_name   text NOT NULL, table_name text NOT NULL,
  rows_affected integer NOT NULL,
  columns       text[] NOT NULL,
  executed_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (school_id, request_id) REFERENCES privacy.erasure_request (school_id, id)
);

-- ============================================================================
-- 2.22 Partitions, grants, and applying RLS to every tenant table
-- ============================================================================
-- Monthly partitions for the append-only streams, created a quarter ahead by
-- the worker. Each new partition gets the parent's policies and grants.
CREATE FUNCTION core.ensure_month_partitions(p_parent regclass, p_months_ahead int DEFAULT 3) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE d date := date_trunc('month', now())::date; i int; nm text;
BEGIN
  FOR i IN 0..p_months_ahead LOOP
    nm := format('%s_%s', replace(p_parent::text, '.', '_'), to_char(d + (i || ' months')::interval, 'YYYYMM'));
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.%I PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                   split_part(p_parent::text, '.', 1), nm, p_parent,
                   d + (i || ' months')::interval, d + ((i + 1) || ' months')::interval);
    -- No direct privileges on partitions: every access goes through the parent,
    -- whose policies apply to the rows of every partition.
    EXECUTE format('REVOKE ALL ON %I.%I FROM PUBLIC, caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_ai, caros_t_system, caros_t_support',
                   split_part(p_parent::text, '.', 1), nm);
  END LOOP;
END $$;

-- Schema usage for the tiers. Table privileges, revised by pass 8 (F13, F15,
-- F17, F35, F44, F75):
--   every user tier: SELECT on the schemas it has rows in, rows still gated by RLS;
--   no user tier holds table-wide INSERT or UPDATE: both are column-level,
--   generated from privacy.table_registry.writable_columns into one migration
--   by tooling/grants/generate.ts, and a test compares the catalogue with the
--   registry; state and authority columns are written only by definer
--   transition functions (§2.1 rule 11);
--   no DELETE anywhere except soft-delete columns; no UPDATE/DELETE on append-only tables;
--   caros_t_ai: SELECT on exactly the union of ai.feature_policy.allowed_fields,
--   an allowlist generated the same way, with a CI test that it can select
--   nothing else (pass 4 D55 as revised, F44);
--   system: everything the worker needs;
--   support: no base table at all; SELECT on the masked views in the
--   `support` schema, each of which applies auth.support_grant_covers() (F35).
GRANT USAGE ON SCHEMA core, auth, sis, engagement, ref, config, signal, ib, uni, discovery, family, mentor,
                     doc, ingest, ai, notify, audit, events, privacy, reporting
  TO caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_ai, caros_t_system;
GRANT USAGE ON SCHEMA ref, support TO caros_t_support;
GRANT SELECT ON ALL TABLES IN SCHEMA ref
  TO caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_ai, caros_t_system, caros_t_support;
GRANT INSERT, UPDATE ON ALL TABLES IN SCHEMA ref TO caros_t_system;
GRANT SELECT ON ALL TABLES IN SCHEMA core, auth, sis, config, signal, ib, uni, discovery, family, mentor, doc, notify, reporting, ingest
  TO caros_t_staff;
GRANT SELECT ON ALL TABLES IN SCHEMA core, sis, config, signal, ib, uni, doc, notify TO caros_t_teacher;
-- No grant on the signal schema for students (F13): the one signal table a
-- student reads is their own reflections, granted by column below.
GRANT SELECT ON ALL TABLES IN SCHEMA core, sis, ib, uni, discovery, mentor, doc, notify TO caros_t_student;
GRANT SELECT ON ALL TABLES IN SCHEMA core, sis, uni, family, discovery, doc, notify TO caros_t_guardian;
GRANT SELECT ON ALL TABLES IN SCHEMA core, mentor, notify TO caros_t_mentor;
-- Column-level INSERT and UPDATE for the user tiers: generated (see above).
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core, auth, sis, engagement, config, signal, ib, uni, discovery,
                                                      family, mentor, doc, ingest, ai, notify, privacy, reporting TO caros_t_system;
-- Audit and event rows are written only through audit.record() and events.emit().
REVOKE INSERT ON audit.entry, events.event FROM PUBLIC, caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian,
                                                caros_t_mentor, caros_t_ai, caros_t_system, caros_t_support;
GRANT EXECUTE ON FUNCTION audit.record(text, text, uuid, uuid, text, jsonb),
                          events.emit(text, uuid, uuid, uuid, uuid, text, uuid, jsonb)
  TO caros_t_staff, caros_t_teacher, caros_t_student, caros_t_guardian, caros_t_mentor, caros_t_ai, caros_t_system;
GRANT SELECT ON audit.entry, events.event TO caros_t_staff, caros_t_system;
REVOKE UPDATE, DELETE ON audit.entry, events.event, signal.case_tier_history, signal.case_stage_history,
                        signal.evidence_item, signal.case_note, signal.escalation_update, ib.selection_event, ib.ee_event,
                        discovery.message, discovery.xp_ledger, mentor.message, config.vocabulary_history
  FROM PUBLIC, caros_t_system;
-- Column-level limits where the row is visible but a field is not.
REVOKE SELECT (email, google_subject, phone) ON core.person FROM caros_t_mentor, caros_t_staff, caros_t_teacher;  -- staff read contact columns through core.v_person_contact (§2.4a)
REVOKE SELECT (date_of_birth, nationality_iso, fee_status_home_country, student_number) ON sis.student FROM caros_t_mentor;
REVOKE SELECT (nationality_iso, fee_status_home_country) ON sis.student FROM caros_t_guardian, caros_t_student;
REVOKE SELECT (reason_code, reason_label, minutes_late) ON sis.attendance_event FROM caros_t_teacher;       -- codes only (F75)
REVOKE SELECT (case_id, status, routed_note, escalation_id) ON signal.teacher_flag FROM caros_t_teacher;    -- the routed label only (F58)
GRANT SELECT (school_id, id, student_id, body, sent_at, seen_at) ON signal.student_reflection TO caros_t_student;  -- never safety_flag (F13)
REVOKE SELECT (safety_flag) ON discovery.message FROM caros_t_student, caros_t_guardian;                    -- F13
REVOKE SELECT (safety_flag) ON mentor.message FROM caros_t_student, caros_t_mentor;                         -- F13; pass 5 D69's extraction columns are revoked from the same tiers when they are added

-- The tenant row itself has no school_id column: it is the school. Every tier
-- may read its own school's row. A school admin or caseload lead changes the
-- school's own configuration through the domain layer; classification, purpose,
-- branding and a synthetic tenant's letterhead are guarded by trigger (§2.3).
ALTER TABLE core.school ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.school FORCE ROW LEVEL SECURITY;
CREATE POLICY school_self ON core.school FOR SELECT USING (id = auth.current_school());
CREATE POLICY school_write ON core.school FOR UPDATE
  USING (id = auth.current_school() AND auth.allowed(current_user, 'core.school', 'config', 'configure'))
  WITH CHECK (id = auth.current_school());
CREATE POLICY school_create ON core.school FOR INSERT WITH CHECK (auth.actor_kind() = 'migration' AND current_user = 'caros_owner');

-- Views evaluate the caller's row access, not the owner's, so a view can never
-- widen what a role may see. The exceptions are the named projection views of
-- §2.4a (core.v_person_contact, mentor.v_mentee, mentor.v_family_pairing,
-- signal.v_escalation_status, signal.v_teacher_flag_mine, signal.v_shadow_reveal,
-- ib.v_signoff_card, ib.v_family_ib_status, ai.v_generation_meta and the
-- `support` schema's masked views): each is owned by caros_policy, filters on
-- auth.current_school(), checks role and scope itself, and projects only the
-- columns its qualifier names. Pass 2 D12's and pass 3 D25's views are
-- security_invoker too (F75; handoff).
ALTER VIEW ib.v_subject_demand SET (security_invoker = on);
ALTER VIEW ib.v_subject_viability SET (security_invoker = on);
ALTER VIEW ib.v_cas_totals SET (security_invoker = on);
ALTER VIEW ib.v_supervision_load SET (security_invoker = on);
ALTER VIEW ib.v_diploma_cohort SET (security_invoker = on);
ALTER VIEW uni.v_application_pack SET (security_invoker = on);
ALTER VIEW signal.v_last_contact SET (security_invoker = on);
ALTER VIEW events.v_case_timeline SET (security_invoker = on);

-- Apply tenant + role policies. One line per tenant table; the test suite
-- checks that no table with a school_id column is missing from this list.
-- A person row's student subject is the student it belongs to, if any, so a
-- student reads their own row through 'self', a guardian through
-- 'linked_children', a teacher through 'roster'; every role reads its own row
-- through 'author'.
--
-- Revised by pass 8 (F02, F13, F15, F16, F59, F75). Child tables with no
-- student column derive their subject through their parent (the first version
-- left them with no subject, so only a school-scoped row could ever read them),
-- and live and shadow rows carry different classes. The derivations are small
-- STABLE definer helpers, owned by caros_policy, executable by no tier:
--   signal.case_student(school, case)  signal.case_class(school, case)  -- 'signal' or 'signal_shadow'
--   signal.run_class(school, run)      ib.selection_student(school, selection)
--   mentor.pairing_student(school, pairing)  discovery.session_student(school, session)
--   uni.statement_student(school, statement) uni.letter_student(school, letter)
--   signal.intervention_student(school, intervention)  ai.generation_student(school, generation)
--   signal.escalation_student(school, escalation)
SELECT auth.protect('core.person', 'directory',
  '(SELECT s.id FROM sis.student s WHERE s.school_id = core.person.school_id AND s.person_id = core.person.id)',
  NULL, NULL, NULL, 'id');
SELECT auth.protect('core.staff_profile', 'directory');
SELECT auth.protect('core.school_module', 'reference');
SELECT auth.protect('core.meeting', 'contact_record', 'student_id', p_author => 'staff_person_id',
                    p_kind => 'kind_key');                                                        -- staff-only (F15); the coordinator's row carries row_kind 'selection_review'
SELECT auth.protect('auth.membership', 'membership', NULL, NULL, NULL, NULL, 'person_id', p_verbs => '{configure}');
SELECT auth.protect('auth.capability_grant', 'membership', p_verbs => '{configure}');
SELECT auth.protect('auth.caseload_assignment', 'membership', 'student_id', p_author => 'counselor_person_id', p_verbs => '{configure}');
SELECT auth.protect('auth.pastoral_assignment', 'membership', NULL, NULL, NULL, NULL, 'person_id', p_verbs => '{configure}');
SELECT auth.protect('auth.support_grant', 'support_grant', p_verbs => '{approve}');
SELECT auth.protect('auth.session', 'session', NULL, NULL, NULL, NULL, 'person_id');
SELECT auth.protect('auth.magic_link', 'session', NULL, NULL, NULL, NULL, 'person_id');
SELECT auth.protect('auth.role_permission', 'config', NULL, NULL, NULL, NULL, NULL, true, p_verbs => '{configure}');
SELECT auth.protect('sis.academic_year', 'directory');
SELECT auth.protect('sis.term', 'directory');
SELECT auth.protect('sis.calendar_period', 'directory');
SELECT auth.protect('sis.school_day', 'directory');
SELECT auth.protect('sis.year_group', 'directory');
SELECT auth.protect('sis.programme', 'directory');
SELECT auth.protect('sis.student', 'directory', 'id');
SELECT auth.protect('sis.enrolment', 'directory', 'student_id');
SELECT auth.protect('sis.enrolment_programme', 'directory',
  '(SELECT e.student_id FROM sis.enrolment e WHERE e.school_id = sis.enrolment_programme.school_id AND e.id = sis.enrolment_programme.enrolment_id)');
SELECT auth.protect('sis.external_identity', 'ingest');
SELECT auth.protect('sis.subject', 'directory');
SELECT auth.protect('sis.timetable_period', 'directory');
SELECT auth.protect('sis.section', 'directory');
SELECT auth.protect('sis.section_teacher', 'directory');
SELECT auth.protect('sis.section_membership', 'directory', 'student_id', 'section_id');
SELECT auth.protect('sis.tutor_group', 'directory');
SELECT auth.protect('sis.tutor_group_member', 'directory', 'student_id');
SELECT auth.protect('sis.assessment', 'academic', NULL, 'section_id');
SELECT auth.protect('sis.grade', 'academic', 'student_id', 'section_id');
SELECT auth.protect('sis.attendance_event', 'attendance', 'student_id', 'section_id');          -- the section subject lets own_section match (F75)
SELECT auth.protect('sis.behaviour_event', 'behaviour', 'student_id');
SELECT auth.protect('sis.transcript', 'academic', 'student_id');
SELECT auth.protect('engagement.activity_event', 'engagement', 'student_id');
SELECT auth.protect('config.rule_set_version', 'config', NULL, NULL, NULL, NULL, NULL, true, p_verbs => '{configure}');
SELECT auth.protect('config.vocabulary', 'reference', NULL, NULL, NULL, NULL, NULL, true, p_verbs => '{configure}');
SELECT auth.protect('config.vocabulary_history', 'reference', NULL, NULL, NULL, NULL, NULL, true);
SELECT auth.protect('signal.sweep_run', 'signal', p_class_expr => 'CASE WHEN shadow THEN ''signal_shadow'' ELSE ''signal'' END');
SELECT auth.protect('signal.feature_snapshot', 'signal', 'student_id');
SELECT auth.protect('signal.evaluation', 'signal', 'student_id', p_class_expr => 'signal.run_class(school_id, sweep_run_id)');
SELECT auth.protect('signal.signal', 'signal', 'student_id', p_class_expr => 'signal.run_class(school_id, sweep_run_id)');
SELECT auth.protect('signal.case', 'signal', 'student_id', p_class_expr => 'CASE WHEN shadow THEN ''signal_shadow'' ELSE ''signal'' END');
SELECT auth.protect('signal.case_tier_history', 'signal', 'signal.case_student(school_id, case_id)',
                    p_class_expr => 'signal.case_class(school_id, case_id)');
SELECT auth.protect('signal.case_stage_history', 'signal', 'signal.case_student(school_id, case_id)',
                    p_class_expr => 'signal.case_class(school_id, case_id)');
SELECT auth.protect('signal.case_signal', 'signal', 'signal.case_student(school_id, case_id)',
                    p_class_expr => 'signal.case_class(school_id, case_id)');
SELECT auth.protect('signal.evidence_item', 'signal', 'signal.case_student(school_id, case_id)',
                    p_class_expr => 'signal.case_class(school_id, case_id)');
SELECT auth.protect('signal.case_context', 'signal', 'signal.case_student(school_id, case_id)');
SELECT auth.protect('signal.case_link', 'signal', 'signal.case_student(school_id, case_id)');
SELECT auth.protect('signal.case_note', 'case_note', 'student_id');
SELECT auth.protect('signal.intervention', 'signal', 'student_id');
SELECT auth.protect('signal.intervention_step', 'signal', 'signal.intervention_student(school_id, intervention_id)');
SELECT auth.protect('signal.escalation', 'safeguarding', 'student_id', p_author => 'raised_by_person_id',
                    p_verbs => '{escalate}');
SELECT auth.protect('signal.escalation_update', 'safeguarding', 'student_id', p_author => 'added_by_person_id',
                    p_verbs => '{escalate}');
SELECT auth.protect('signal.teacher_flag', 'teacher_flag', 'student_id', 'section_id', NULL, NULL, 'author_person_id',
                    p_verbs => '{escalate}');
SELECT auth.protect('signal.student_reflection', 'student_voice', 'student_id');
SELECT auth.protect('ib.subject', 'ib');
SELECT auth.protect('ib.subject_level_period', 'ib');
SELECT auth.protect('ib.subject_teacher', 'ib');
SELECT auth.protect('ib.prerequisite', 'ib');
SELECT auth.protect('ib.selection_round', 'ib', p_verbs => '{configure}');
SELECT auth.protect('ib.selection', 'ib', 'student_id', p_verbs => '{approve}');
SELECT auth.protect('ib.selection_pick', 'ib', 'ib.selection_student(school_id, selection_id)', NULL, 'subject_id');
SELECT auth.protect('ib.selection_signoff', 'ib', 'ib.selection_student(school_id, selection_id)', NULL, 'subject_id');
SELECT auth.protect('ib.selection_event', 'ib', 'ib.selection_student(school_id, selection_id)');
SELECT auth.protect('ib.cas_activity', 'ib');
SELECT auth.protect('ib.cas_interest', 'ib', 'student_id');
SELECT auth.protect('ib.cas_entry', 'ib', 'student_id');
SELECT auth.protect('ib.ee_round', 'ib', p_verbs => '{configure}');
SELECT auth.protect('ib.ee_milestone', 'ib');
SELECT auth.protect('ib.ee_milestone_due', 'ib');
SELECT auth.protect('ib.ee_essay', 'ib', 'student_id', NULL, NULL, 'id');
SELECT auth.protect('ib.ee_milestone_completion', 'ib', NULL, NULL, NULL, 'essay_id');
SELECT auth.protect('ib.ee_reflection', 'ib', NULL, NULL, NULL, 'essay_id');
SELECT auth.protect('ib.ee_draft', 'ib', NULL, NULL, NULL, 'essay_id');
SELECT auth.protect('ib.ee_event', 'ib', NULL, NULL, NULL, 'essay_id');
SELECT auth.protect('uni.student_target', 'university', 'student_id', p_kind => '''target''');
SELECT auth.protect('uni.application', 'university', 'student_id', p_kind => '''application''');
SELECT auth.protect('uni.offer', 'university', 'student_id', p_kind => '''offer''');
SELECT auth.protect('uni.document_request', 'university', 'student_id', p_addressee => 'requested_from_person_id',
                    p_kind => '''document_request''');
SELECT auth.protect('uni.statement', 'university', 'student_id', p_kind => '''statement''');
SELECT auth.protect('uni.statement_version', 'university', 'uni.statement_student(school_id, statement_id)', p_kind => '''statement''');
SELECT auth.protect('uni.statement_review', 'university', 'uni.statement_student(school_id, statement_id)',
                    p_kind => '''statement''', p_verbs => '{approve}');
SELECT auth.protect('uni.reference_letter', 'university', 'student_id', NULL, NULL, NULL, 'author_person_id', p_kind => '''letter''');
SELECT auth.protect('uni.reference_letter_version', 'university', 'uni.letter_student(school_id, letter_id)', p_kind => '''letter''');
SELECT auth.protect('uni.centre_statement', 'university', NULL, NULL, NULL, NULL, 'written_by_person_id', p_kind => '''centre_statement''');
SELECT auth.protect('uni.school_deadline', 'university', p_kind => '''school_deadline''');
SELECT auth.protect('uni.author_voice_sample', 'university', NULL, NULL, NULL, NULL, 'author_person_id', p_kind => '''voice_sample''');
SELECT auth.protect('uni.ap_exam_registration', 'university', 'student_id', p_kind => '''exam''');
SELECT auth.protect('discovery.session', 'discovery', 'student_id', p_kind => '''session''');
SELECT auth.protect('discovery.message', 'discovery', 'discovery.session_student(school_id, session_id)', p_kind => '''message''');
SELECT auth.protect('discovery.pathway_proposal', 'discovery', 'student_id', p_kind => '''proposal''', p_verbs => '{approve}');
SELECT auth.protect('discovery.approved_pathway', 'discovery', 'student_id', p_kind => '''approved_pathway''');
SELECT auth.protect('discovery.roadmap_progress', 'discovery', 'student_id', p_kind => '''approved_pathway''');
SELECT auth.protect('discovery.xp_ledger', 'xp', 'student_id');                                   -- its own class (F77)
SELECT auth.protect('discovery.network_contact', 'discovery', 'student_id', p_kind => '''network''');
SELECT auth.protect('family.guardian_link', 'guardian_link', 'student_id', NULL, NULL, NULL, 'guardian_person_id');   -- F15
SELECT auth.protect('family.message', 'family', 'student_id', NULL, NULL, NULL, 'sender_person_id',
                    p_addressee => 'recipient_person_id');                                        -- by sender and recipient (F15)
SELECT auth.protect('family.meeting_slot', 'family', NULL, NULL, NULL, NULL, 'staff_person_id');
SELECT auth.protect('family.meeting_request', 'family', 'student_id', NULL, NULL, NULL, 'guardian_person_id');
SELECT auth.protect('family.contact_log', 'contact_record', 'student_id', NULL, NULL, NULL, 'by_person_id');          -- staff-only (F15)
SELECT auth.protect('mentor.profile', 'mentor', NULL, NULL, NULL, NULL, 'person_id', p_kind => '''profile''');
SELECT auth.protect('mentor.pairing', 'mentor', 'student_id', p_pairing => 'id', p_kind => '''pairing''', p_verbs => '{approve}');
SELECT auth.protect('mentor.session_request', 'mentor', 'mentor.pairing_student(school_id, pairing_id)', p_pairing => 'pairing_id', p_kind => '''thread''');
SELECT auth.protect('mentor.session', 'mentor', 'mentor.pairing_student(school_id, pairing_id)', p_pairing => 'pairing_id', p_kind => '''thread''');
SELECT auth.protect('mentor.message', 'mentor', 'mentor.pairing_student(school_id, pairing_id)', NULL, NULL, NULL, 'sender_person_id',
                    p_pairing => 'pairing_id', p_kind => '''thread''');                           -- subject through the pairing (F59)
SELECT auth.protect('mentor.mentee_note', 'mentor', 'student_id', p_pairing => 'pairing_id', p_kind => '''thread''');
SELECT auth.protect('doc.file', 'documents', 'subject_student_id', NULL, NULL, NULL, 'uploaded_by_person_id',
                    p_kind => 'kind', p_class_expr => 'data_class');                              -- the file's own class and kind (F15)
SELECT auth.protect('ingest.source_system', 'ingest', p_verbs => '{configure}');
SELECT auth.protect('ingest.mapping_profile', 'ingest', p_verbs => '{configure}');
SELECT auth.protect('ingest.import', 'ingest', p_verbs => '{approve}');
SELECT auth.protect('ingest.import_rejection', 'ingest');
SELECT auth.protect('ingest.import_change', 'ingest');
SELECT auth.protect('ai.model_config', 'config', NULL, NULL, NULL, NULL, NULL, true);
SELECT auth.protect('ai.generation', 'ai', 'subject_student_id', NULL, NULL, NULL, 'requested_by_person_id',
                    p_kind => 'feature');                                                         -- students read only their own discovery and EE feedback (F15)
SELECT auth.protect('ai.pseudonym_map', 'ai', 'ai.generation_student(school_id, generation_id)');  -- no tier row; read through ai.reidentify() (F44)
SELECT auth.protect('notify.outbox', 'notification', p_addressee => 'recipient_person_id');     -- written only by notify.enqueue(); excluded from support grants (F16, F35)
SELECT auth.protect('notify.preference', 'notification', NULL, NULL, NULL, NULL, 'person_id');
SELECT auth.protect('notify.in_app', 'notification', p_addressee => 'person_id');
SELECT auth.protect('audit.entry', 'audit', 'subject_student_id');
SELECT auth.protect('events.event', 'reporting', 'subject_student_id');
SELECT auth.protect('privacy.erasure_request', 'privacy_request', p_verbs => '{approve}');
SELECT auth.protect('privacy.erasure_log', 'privacy_request');
SELECT auth.protect('privacy.retention_override', 'config', p_verbs => '{configure}');
-- reporting.agg_* tables (pass 6) are protected when they are created, each as
-- class 'reporting' with the row kind of its report (F34).

-- updated_at is maintained everywhere it exists (§12.3 of the pass 7 review).
DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT c.table_schema, c.table_name FROM information_schema.columns c
           JOIN information_schema.tables tb ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name
           WHERE c.column_name = 'updated_at' AND tb.table_type = 'BASE TABLE'
             AND c.table_schema NOT IN ('pg_catalog','information_schema','pgboss') LOOP
    EXECUTE format('CREATE TRIGGER touch_updated_at BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at()',
                   t.table_schema, t.table_name);
  END LOOP;
END $$;

-- Every definer function in every CAROS schema: owned by caros_policy (or
-- caros_jobs in `jobs`), and never executable by PUBLIC (F75). Grants to named
-- tiers are listed with each function above; the convention test fails on any
-- definer function without them.
DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE p.prosecdef AND n.nspname IN ('core','auth','sis','signal','ib','uni','discovery','family','mentor',
                                               'doc','ingest','ai','notify','audit','events','privacy','reporting','support') LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
  END LOOP;
END $$;

-- Tables whose rows are visible to a person about themselves but that carry no
-- student subject (memberships, sessions, notifications) use the 'author' or
-- 'addressee' scope with the person column. Pass 4's matrix grants every role
-- `session` and `notification` read on its own rows (F16), and nothing else:
-- an outbox payload, a session or a cover reason is never school-readable.
```

Two defaults deserve a sentence each. The counselor's `signal` and `case_note` rows are scoped to the caseload, so a counselor who is not the owner and holds no cover assignment cannot open another counselor's case file; pass 4 §3.3 decided caseload plus explicit, logged cover, and until ACS answers question 65 a school may only narrow the defaults (F47, pass 4 D36). The teacher's `teacher_flag` rows are `write` on roster, subject-teacher and Extended Essay scopes and `read` on `author`, which is the prototype's "What I've logged" page: a teacher sees every flag they wrote, through a view that never says whether a case exists, and no flag anyone else wrote.
## 3. Entity relationship summary

The school is the root of everything. A **school** has **people** (staff, students, guardians, mentors), and a person's rights come from **memberships** (a role, optional capabilities, each capability confirmed by a second administrator) and from relationship tables: **caseload assignments** for counselors, **pastoral assignments** and **tutor groups** where a school shares pastoral responsibility, **section teachers** and **section memberships** for teachers, **guardian links** for parents (one per SIS contact, activated per contact), **pairings** for mentors. A **student** is a person with an academic identity: **enrolments** per academic year in a **year group** and a **programme**; **section memberships**; **grades** on **assessments** in **sections**; **attendance events**; **behaviour events**. The **calendar** (academic years, terms, calendar periods, school days) is per school.

The engine reads those facts and writes **feature snapshots** (the baseline: a series and a band per student, domain and measure), **evaluations** (one per student per **sweep run**, which fixes the three rule-set versions used) and **signals** (a rule firing, with frozen inputs). Signals attach to a **case** (one open live case per student, and while the school is in shadow one open shadow case), which carries **evidence items**, **tier and stage history**, **counselor context**, **notes**, **interventions** with steps, and **escalations** to the safeguarding lead (at most one open at a time, each with its **updates**, a later one linked to the one before). Cases of different students are **linked**, never merged. **Teacher flags** enter the case through attachment, and a teacher's safeguarding flag raises an escalation itself. **Meetings** record conversations and are referenced by cases and, for the review conversation, by IB **selections**.

The IB module hangs off the tenant **IB subject catalogue** (with level periods, teachers, prerequisites): a **selection round** has **selections** with **picks**, **sign-offs** and an event log; **CAS entries** form a ledger per student against a **CAS activity** catalogue; an **Extended Essay** per student per **EE round** has milestones, completions, reflections and drafts. The university module hangs off **global reference data** (institutions, courses, entry requirements, costs, fee-status rules, deadlines, exam sessions), all sourced: a student's **targets** carry a rule-classified reach/match/safety, an **application** and **offers**; **document requests** track transcripts, references and forms; **statements** are versioned in the sections their destination's **statement format** asks for, and **references** in their **reference format**, with the school's **centre statement** and its **internal deadlines**. Discovery holds a **session** with **messages**, **pathway proposals** decided by a counselor, **approved pathways** with a roadmap snapshot, **roadmap progress** and an **XP ledger** only the student reads. Family holds **messages**, **meeting slots and requests** and a **contact log**. Mentors hold **profiles**, **pairings**, **session requests**, **sessions**, **messages** and **notes**.

Underneath: **files** (metadata, each with its own class and kind; bytes in blob storage), **imports** with **mapping profiles**, **rejections** and **changes** (every fact row points at its import), **AI generations** with model configuration and pseudonym maps, a **notification outbox** written only through one function, an append-only **audit** log with a hash chain, an append-only **event** stream, per-tenant **reporting aggregates**, **regulator profiles** that hold everything regulator-shaped, and the **privacy** registry that maps every table to a data class, subject, PII columns, writable columns and retention class, with per-school retention overrides and the stores outside the tenant tables.

## 4. Module map

Each module is a folder in `packages/domain`, a router in `packages/api`, a screen group in `apps/web`, and the tables it owns. Cross-module reads go through the other module's public functions; cross-module writes go through its mutations.

| Module | Owns (schemas / tables) | Serves (prototype screens, CONTEXT.md §8) | Depends on | Suggested owner |
|---|---|---|---|---|
| **tenant** | `core.school`, `school_module`, `sis.academic_year`, `term`, `calendar_period`, `school_day`, `year_group`, `programme`, `timetable_period`, `config.*`, `notify.template` | letterhead, thresholds, pilot and rollout, module gating | | Davide |
| **identity** | `core.person`, `staff_profile`, `auth.*` (including `pastoral_assignment` and `capability_grant`), `sis.external_identity` | sign-in, role and capability admin, cover, pastoral assignments, support grants | tenant | Davide (pass 4 design) |
| **record** | `sis.student`, `enrolment`, `enrolment_programme`, `subject`, `section*`, `tutor_group*`, `assessment`, `grade`, `attendance_event`, `behaviour_event`, `transcript`, `engagement.*` | 360° file (record tabs), parent grades and transcripts, teacher class register roster | identity, ingest | teammate A |
| **ingest** | `ingest.*`, `doc.file` for exports | import upload, dry run, commit, rollback, mapping profiles | record | teammate A (pass 2) |
| **engine** (pure package) | none; reads through an input DTO | | | teammate B (pass 3) |
| **signals** | `signal.sweep_run`, `feature_snapshot`, `evaluation`, `signal`, `case*` (including `case_link`), `evidence_item`, `intervention*`, `escalation`, `escalation_update`, `case_note`, `case_context`, `teacher_flag`, `student_reflection`, `core.meeting` | caseload sheet, command centre, priority queue, signal intelligence, flags inbox, meetings, the ten dimension pages, case file, interventions, escalation; teacher register and "what I've logged" | record, identity, engine, notify | Davide + teammate B |
| **ib** | `ib.*` | IB selections queue, demand sheet, CAS cohort, EE coordinator; teacher sign-off and EE queue; student subjects, Diploma core | record, identity | teammate C |
| **university** | `uni.*`, `ref.institution`, `course`, `entry_requirement`, `cost`, `fee_status_rule`, `deadline`, `exam_session`, `requirement_change`, `destination_system`, `statement_format`, `reference_format` | application season and flow, list balance, deadlines, documents and references, personal statements, letter engine, student targets, AP exams, parent university requirements | record, identity | teammate C |
| **discovery** | `discovery.*`, `ref.archetype*`, `ref.onboarding_question` | my pathway, pathway approvals, roadmap, XP | identity, ai | frontend pair (pass 5 for the chat) |
| **family** | `family.*` | parent overview, messages, meet the counselor, meeting requests | record, identity, notify | frontend pair |
| **mentor** | `mentor.*`, `discovery.network_contact` | find a mentor, my network, session requests, my mentees | identity | frontend pair |
| **ai** | `ai.*` | co-pilot, briefs, drafts, EE feedback, statement read | every module's read functions | pass 5's builder |
| **notify** | `notify.outbox`, `preference`, `in_app` | nudges, escalation email, magic links | tenant | Davide |
| **audit and reporting** | `audit.*`, `events.*`, `reporting.agg_*` tables (never materialised views, F34) | reporting, audit trail on the case file | all | Davide |
| **privacy** | `privacy.*`, `ref.regulator_profile` | erasure, retention jobs, retention overrides, subject access export | all | Davide (pass 4) |

Two invariants are enforced at the module boundary rather than in a table: the caseload (identity → `caseload_assignment`) and the Diploma cohort (ib → `v_diploma_cohort`) are exposed by different modules and there is no function anywhere that returns their union (invariant 7); and only the discovery module may write `xp_ledger`, which only the student reads (invariant 10). The module owners in the table apply once a second regular builder exists; until then every module is Davide's (decision C8).

## 5. Challenges

Each challenge names the section 3 decision, states the alternative, what it costs and buys, and then continues to plan on the decision as given.

**5.1 UAE residency now has a durability price that the decision did not price in.** *Decision challenged: data residency.* The disruption to the AWS UAE and Bahrain regions began on 1 March 2026; on 15 September AWS declared the data hosted exclusively in one UAE-region zone unrecoverable, and in Bahrain declared data held anywhere in the region unrecoverable (DR-1 sources, as corrected by pass 8, F73). Bahrain is the country-level precedent: customers whose backups were in-country only lost them. This plan keeps everything in the UAE and adds in-country redundancy across two Azure regions 140 kilometres apart, which covers a data-centre loss and not a country-level event. The alternative is an encrypted cold copy of the nightly backup in an EU region, restorable only by a deliberate act. **Pass 8 corrects the first version's framing** (F22): a copy whose key exists only in the UAE cannot be decrypted after the loss it exists for, so the copy works only if key material is also held outside the UAE (a Managed HSM replica in an EU region, or security-domain shares held abroad by named people), with a named restore region and trigger and a restore drill there on synthetic data. It costs a legal position (a copy of student data, and the means to read it, would sit outside the UAE), a data-processing-agreement clause, ADEK's explicit consent under its Digital Policy 7.1.3.a (F04), and about the price of the storage and an HSM; it buys survival of the one scenario the region just demonstrated. Recommendation: put the real choice, (a) EU copy with keys abroad or (b) in-country only with the risk stated, to ACS's leadership and to counsel now, in writing; plan on residency as decided until they answer. The schema and backups are unchanged either way.

**5.2 Overnight batch should be the ritual, not the only trigger.** *Decision challenged: signal engine timing.* The morning sweep is right for the baselines: they change when data arrives, which is termly or nightly. But three inputs arrive live and change what a counselor should do *today*: a teacher concern (three independent staff inside seven days is Tariq's safeguarding pattern, and waiting for 02:00 delays a referral by a school day), counselor context (which the prototype recalculates immediately, and which a counselor expects to see take effect while the modal is still open), and a safeguarding escalation. The alternative is a hybrid: the nightly sweep as designed, plus an event-triggered incremental evaluation of one student when a flag, a context note or an enrolment change lands. It costs one more code path in the worker and one more `sweep_trigger` value (already in the schema as `event`); it buys same-day corroboration and explainable context downgrades. Pass 3 is asked to argue it in full (CONTEXT.md §11.1); the schema supports both.

**5.3 "Parents receive no email in v1" cannot mean no email.** *Decision challenged: outbound notifications.* Parents authenticate by magic link, which is an email. A meeting request needs a confirmation, which is an email or it is a request into silence. **Settled by Davide on 2026-09-24 (decision C2):** parents receive content-free transactional email: magic links, and role-only notices such as "a counselor at the school has sent you an update in CAROS; sign in to read it", which name the sender's role from a fixed list and never a person, the student or the topic (F60). The AI parent-email drafts land as counselor-approved in-app messages (`family.message`, `channel = 'in_app'`), which the parent is told of by that notice and reads after signing in. Pass 4 §5.8 lists every outbound message; CONTEXT §3 still needs its "Outbound notifications" row updated to match (handoff).

**5.4 Five roles hold, but the coordinator, the safeguarding lead and the school's IT administrator need a place to stand.** *Decision challenged: roles.* The IB coordinator sees students outside any counselor's caseload; the Child Protection Officer must be able to acknowledge an escalation, which needs an account; someone at the school uploads exports and manages mapping profiles. The coordinator and the caseload lead are **capabilities on a counselor's membership**, stored as data, granted per school. **Revised by pass 8** (F16, F10): the first version also put `school_admin` and `safeguarding_lead` on a counselor membership, which gave an IT administrator or a Principal a counselor's break-glass path to welfare data. So `school_admin` is now a role with no caseload path, `safeguarding_lead` and the new `safeguarding_oversight` may sit on any staff membership, and a `staff` role with no data access carries them for someone who is neither counselor nor teacher. "More roles later" stays a row insert (§0.1).

**5.5 A twelve-character escalation reason is a UI minimum, not a safeguarding one.** *Decision touched: invariant 5 ("requires a reason").* The prototype accepts twelve characters. A referral to a safeguarding lead is a document that may be read in a review a year later. The alternative is a structured reason (what was observed, why now, who else knows) with a forty-character minimum on the free text. Cost: thirty seconds of a counselor's time at the most serious moment in the product. Pass 4 adopted the structured form (§5.3, D46); the minimums remain ACS's to adjust (question 60).

**5.6 The complete schema is designed now and applied in phases.** *Decision: scope.* Agreed and planned on. The one thing to add: the migrations for a module land in the phase that first serves it (pass 6), from this design, so that no table exists in production with no code reading it and no test covering it. Designing everything now is what makes the phases cheap; migrating everything now is what makes the first restore drill slow.

**5.7 The production frontend cannot be hosted on Vercel.** *Decision touched: frontend.* A consequence, not a challenge: Vercel has no UAE region, cannot pin logs, and builds in the US (DR-1). The Next.js app runs on Container Apps in UAE North; the frozen demo stays on Vercel because it holds only synthetic data. Framework-level caching in Next.js keys on arguments, not on the tenant context, so no authenticated route uses it (F75).

**5.8 Known limitations, stated rather than hidden** (pass 8, F65). The subject-choice engine is IB-shaped and cannot serve a British school choosing A levels until it is generalised, which happens when such a school signs (DR-7.3). The Wellesmere tenant proves the second-school mechanisms, not a KHDA analysis: its regulator profile is empty until one is done (§2.7).

## 6. Open decisions

| # | Decision | Options | Recommendation | Who decides |
|---|---|---|---|---|
| 1 | Out-of-country encrypted cold copy of backups | (a) none: in-country only, risk documented; (b) EU cold copy **with key material held outside the UAE** by named people, a named restore region and trigger, an EU restore drill on synthetic data, and a DPA clause (corrected by pass 8, F22: a UAE-only key cannot decrypt the copy after a country-level loss) | (b) if ACS and counsel accept it in writing and ADEK consents under Digital Policy 7.1.3.a (F04); otherwise (a) with the risk stated in the DPA | Davide, ACS leadership, counsel, ADEK |
| 2 | When to re-evaluate AWS `me-central-1` | (a) never; (b) when AWS resumes billing and publishes a restoration statement | (b); the infrastructure module keeps the option cheap | Davide |
| 3 | When the WAF must be on | (a) from the first deploy; (b) from the first real data; (c) after the IT review asks | (b) | pass 4, Davide |
| 4 | RPC layer | (a) tRPC 11; (b) oRPC 1.x (OpenAPI built in, v2 in beta) | (a); add Hono + zod-openapi for the connector API later | Davide |
| 5 | Infrastructure tool | (a) Terraform/OpenTofu with `azurerm`; (b) Bicep | (a): provider-neutral skill, and DR-1 makes provider moves plausible | Davide |
| 6 | PostgreSQL major | (a) 17; (b) 18 | (a) at pilot; 18 at year 1 once the extension list is clean | Davide |
| 7 | Session privilege model | (a) acting role per session (one tier, column privileges enforced in the database); (b) union of memberships (simpler, no DB column enforcement) | (a); decided by pass 4 §2.4, and the tier is now checked in the policy expression (F01) | closed |
| 8 | Counselor visibility across the HS team | (a) caseload-scoped; (b) school-scoped signals for all counselors; (c) caseload plus explicit cover | (c), decided by pass 4 §3.3; narrow-only until ACS answers question 65, with widening of `signal` and `case_note` (never `safeguarding`) kept ready as an option (decision on F47) | ACS counselors |
| 9 | Escalation reason minimum and structure | 12 characters (prototype); 40 with a structured form | 40 and structured, adopted by pass 4 (D46); the numbers are ACS's | ACS counselors and CPO |
| 10 | Engagement domain: which sources, and retention | CAROS logins only; plus Google Classroom; 180 days proposed | decide after ACS answers Q14 in ACS-IT-QUESTIONS.md | pass 3, pass 4, ACS |
| 11 | Case lifecycle defaults | monitoring window 90 days, auto-review 14 days (prototype), sweep hour 02:00 | keep the prototype's numbers as version 1 | ACS counselors |
| 12 | Built-in PgBouncer at scale | (a) never; (b) at year 3 after the RLS suite passes under transaction pooling | (b) | Davide |
| 13 | Audit hash chain | on (default in §2.19) or off | on, decided by pass 4 §4.2 | closed |
| 14 | Second synthetic school's name and regulator | "Wellesmere British School, Dubai" (KHDA) pending a directory check; or a Sharjah (SPEA) school for a third regulator | keep Wellesmere, check the KHDA directory | Davide |
| 15 | Who is in the Diploma cohort in the choosing year | (a) every Grade 10 student (`ib_dp_candidate`); (b) only those who have declared IB | (a) at ACS, per the coordinator's description recorded in PRODUCT.md; confirm | ACS (Q below) |
| 16 | Retention numbers per class | proposals in `privacy.retention_class` | as proposed until counsel sets them | counsel (pass 4) |
| 17 | Whether `strength` and `contribution` exist at all | define or remove | removed by pass 3 (D17, D18); no seed ever writes them (§12.11) | closed |
| 18 | Test runner | Vitest 5 (19 days old) or Vitest 4.1 (maintained) | 5; a fresh repository should not start on a superseded major | Davide |

## 7. For other passes

These were pass 1's requests to the passes that followed it. Where they conflict with the pass 8 revision, the handoff list at the end of `08-changelog.md` is the current one.

**Pass 2 (ingest).** The tables in §2.16 and every `import_id` column; the fixture source kind and the classification trigger; the two seed exports (Veracross-shaped, iSAMS-shaped) as its first fixtures; `sis.external_identity` for identity resolution; `sis.section.feeder_set_key` and `sis.calendar_period.affects_domains` as normalisation targets; `ref.grade_scale` for normalisation; the requirement that rosters are imported and never typed; whether termly exports can populate `sis.grade` per assessment and `sis.attendance_event` per session, and what the weekly run looks like if they cannot.

**Pass 3 (engine).** `feature_snapshot.band_method`, `history_weeks`, `features`; `evaluation.rule_hits`, `suppressions`, `strength`, `strength_definition`; `signal.contribution`; the rule keys named in `openedBy` (`baseline_deviation`, `engagement_decay`, `list_balance`, `list_fit`, `reference_sla`, `relapse`, `corroboration`, `post_offer_decay`, `combined_weak_signal`); the three rule sets `engine.thresholds`, `engine.suppression`, `engine.tiering` and their JSON schemas; hysteresis and the rule that the engine never lowers a person-raised tier within N days; the hybrid trigger argument (5.2); the `dimensions` rule set that replaces the three hard-wired dimension functions; cold start expressed through `history_weeks`; the seed reproduction test.

**Pass 4 (security).** The permission matrix in `auth.role_permission` is a default to be replaced by its matrix; the acting-role model; the support grant and break-glass; the audit action taxonomy and which reads must write access entries; whether the hash chain is warranted; retention numbers; erasure against the audit log and backups (the design: tombstone plus registry scrub, audit keeps identifiers, backups expire in 35 days, vaulted copies are the open question); the residency-versus-durability position (5.1); the WAF timing; what the escalation email may contain (the outbox payload carries identifiers only); guardian linkage rules; mentor identity and `auth_method = 'mentor_password'` as a placeholder.

**Pass 5 (AI).** `ai.model_config`, `ai.generation`, `ai.pseudonym_map`; `ref.archetype_claim` and the rule that unsourced claims do not render; the removal of admission probability and what replaces it over `ref.entry_requirement`; the `safety_flag` columns on `discovery.message`, `signal.student_reflection` and `mentor.message` and the routing they need; `family.message.draft_generation_id` for parent drafts; `uni.reference_letter_version.evidence_citations` for the deferred letter engine; `signal.case.headline_generation_id` for rephrasing rule text; the pseudonymisation boundary that DR-1 confirms is necessary for every model on every provider.

**Pass 6 (build sequence).** The order in which §2's schemas are migrated; the thin slice (tenant, identity, ingest, engine, signals, audit, notify) and which tables it needs; the RLS suite and the second-school checklist as week-one tests; the restore drill before real data; the Container Apps Job for migrations; `docs/PLAN.md` and `CLAUDE.md` content; the UAE Central access request as a week-one task.

## 8. Questions for ACS

In the style of `ACS-IT-QUESTIONS.md`; numbered to continue that file's list. Each says who is likely to answer.

**Systems and data · IT, registrar**

50. What is the school's timetable structure: how many periods a day, and do they differ by day? CAROS needs the period grid to check subject clashes.
51. Which weekdays are school days, and are there half days? (The prototype assumed a Sunday-to-Thursday week; the tenant record needs the real pattern.)
52. Can term dates, exam and mock periods, and reporting windows be exported each year, and in what form?
53. For each programme the school runs (IB Diploma, AP, ACS High School courses), which grade scale appears in the export: IB 1 to 7, AP 1 to 5, percentages, letters, a GPA? Do predicted grades appear separately from working grades?
54. Which mathematics sets exist in Grade 10 (for example extended and foundation), and are they identifiable in the export? The IB prerequisite check compares against them.
55. Does ManageBac hold CAS hours from previous years that would need to be imported as an opening balance?
56. Who at the school would upload exports and maintain the column mapping: a registrar, IT, or a counselor? That person needs a `school_admin` membership, which since pass 8 is a role of its own with no access to welfare data (F16).

**Identity and accounts · IT**

57. Does the Child Protection Officer want a CAROS account to acknowledge escalations, or should acknowledgement happen by another route?
58. Do teachers sign in with the same Google Workspace domain as counselors?
59. Do some guardians share one email address, or have several children at different grades? The parent link must be verified per child.

**Safeguarding · Lead Child Protection Officer, HS Principal**

60. What must a referral to the CPO contain at minimum? The prototype accepts a twelve-character reason; is a structured form (what was observed, why now, who else knows) closer to your policy?
61. Within what time should an escalation be acknowledged, and what should happen if it is not?

**Data protection, hosting and legal · Data protection lead, leadership, legal**

62. Cloud data centres in the UAE and Bahrain were physically damaged in March 2026 and some customer data was permanently lost. CAROS will keep all student data in the UAE across two Azure regions. Would ACS permit an encrypted backup copy to be stored in the EU as protection against a country-level loss? For that copy to be restorable after such a loss, the means to decrypt it would also have to be held outside the UAE, by named people, and ADEK's consent would be needed first under its Digital Policy 7.1.3.a. If not, is ACS content to accept the country-level risk in writing? (Revised by pass 8, F22.)
63. Does ACS have a business-continuity expectation for CAROS (how long it may be unavailable, how much data may be lost) that should shape the backup design?
64. Does ADEK or ACS policy set a minimum retention period for counseling and safeguarding records after a student leaves? The schema needs a number per record class.

**For the counselors · the HS counseling team**

65. How is the Grade 9 to 12 caseload split between the four counselors, and should a counselor be able to see another counselor's cases by default, only when covering, or never?
66. When a counselor is away, who covers, and should cover be time-boxed and recorded?
67. When you add context to a case (an authorised absence, a known family situation), do you expect the priority to change immediately or overnight?
68. Is every Grade 10 student part of the IB subject-selection round, or only those who have already declared the Diploma?

**The pilot · leadership, counseling team**

69. May CAROS name a fictional second school in its test data (it will never appear in your demo), and is there any real school name we should avoid confusing it with?

## Sources

All retrieved 2026-09-22, except where marked as re-checked on 2026-09-24 by the pass 8 revision.

- AWS Health Dashboard feed: https://status.aws.amazon.com/rss/all.rss (items dated 1 Mar, 30 Apr and 15 Sep 2026 on `me-central-1` and `me-south-1`; the first item's date corrected by pass 8, F73)
- AWS UAE region launch: https://aws.amazon.com/blogs/aws/now-open-aws-region-in-the-united-arab-emirates-uae/
- AWS General Reference endpoint tables (RDS, S3, SES, EventBridge Scheduler, Secrets Manager, KMS, CloudWatch Logs, Lambda, SQS, Step Functions, ECR, WAF, ACM, CloudTrail, App Runner, Bedrock): https://docs.aws.amazon.com/general/latest/gr/
- AWS Fargate regions: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate-Regions.html
- AWS Price List API, `me-central-1`: https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonRDS/current/me-central-1/index.json and the corresponding AmazonS3, AmazonECS, AmazonSES, AWSSecretsManager, AmazonCloudWatch, AWSDataTransfer, AWSELB, AmazonEC2 files
- Bedrock model region compatibility: https://docs.aws.amazon.com/bedrock/latest/userguide/models-region-compatibility.html; inference profiles: https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html
- Azure paired regions: https://learn.microsoft.com/en-us/azure/reliability/regions-paired; regions list: https://learn.microsoft.com/en-us/azure/reliability/regions-list; region access request: https://learn.microsoft.com/en-us/troubleshoot/azure/general/region-access-request-process; datacenter map data: https://datacenters.microsoft.com/globe/data/geo/regions.json
- Azure Database for PostgreSQL: overview and region table https://learn.microsoft.com/en-us/azure/postgresql/overview; supported versions https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-supported-versions; backup and restore https://learn.microsoft.com/en-us/azure/postgresql/backup-restore/concepts-backup-restore; reliability https://learn.microsoft.com/en-us/azure/reliability/reliability-database-postgresql; extensions https://learn.microsoft.com/en-us/azure/postgresql/extensions/concepts-extensions-versions; PgBouncer https://learn.microsoft.com/en-us/azure/postgresql/connectivity/concepts-pgbouncer; storage autogrow https://learn.microsoft.com/en-us/azure/postgresql/scale/how-to-auto-grow-storage; read replicas https://learn.microsoft.com/en-us/azure/postgresql/read-replica/concepts-read-replicas
- Azure Backup for PostgreSQL flexible server: https://learn.microsoft.com/en-us/azure/backup/backup-azure-database-postgresql-flex-overview and https://learn.microsoft.com/en-us/azure/backup/backup-azure-database-postgresql-flex-support-matrix
- Azure Storage redundancy: https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy; immutable storage: https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview
- Azure Container Apps: jobs https://learn.microsoft.com/en-us/azure/container-apps/jobs; billing https://learn.microsoft.com/en-us/azure/container-apps/billing; containers and allocations https://learn.microsoft.com/en-us/azure/container-apps/containers; zone redundancy https://learn.microsoft.com/en-us/azure/reliability/reliability-container-apps
- Azure Application Gateway pricing notes: https://learn.microsoft.com/en-us/azure/application-gateway/understanding-pricing; Front Door FAQ https://learn.microsoft.com/en-us/azure/frontdoor/front-door-faq; end-to-end TLS https://learn.microsoft.com/en-us/azure/frontdoor/end-to-end-tls
- Azure Communication Services: privacy and data location https://learn.microsoft.com/en-us/azure/communication-services/concepts/privacy; email pricing https://learn.microsoft.com/en-us/azure/communication-services/concepts/email-pricing; service limits https://learn.microsoft.com/en-us/azure/communication-services/concepts/service-limits#email; custom domains https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/add-custom-verified-domains
- Azure Monitor pricing: https://azure.microsoft.com/en-us/pricing/details/monitor/; bandwidth pricing: https://azure.microsoft.com/en-us/pricing/details/bandwidth/
- Azure Retail Prices API (all UAE North figures): https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview with `$filter=armRegionName eq 'uaenorth' and serviceName eq '<Azure Database for PostgreSQL | Storage | Azure Container Apps | Application Gateway | Key Vault | Log Analytics | Azure Monitor | Container Registry | Email | Bandwidth>'`; documented at https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
- Azure AI Foundry Claude models: https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/claude-models; partner model regions: https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-from-partners#region-availability-by-deployment-type; deployment types: https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types
- Microsoft Q&A on UAE region status (2 Apr 2026): https://learn.microsoft.com/en-us/answers/questions/5848347/inquiry-the-status-of-azure-cloud-services-in-the
- Secondary reporting on the March 2026 strikes: https://www.techpolicy.press/the-legal-and-policy-fallout-from-data-center-strikes-in-the-middle-east-war/; https://www.theregister.com/2026/04/08/microsoft_armored_datacenters/; https://www.theregister.com/off-prem/2026/09/16/aws-says-wartime-damage-means-some-middle-east-cloud-resources-are-gone-for-good/5296830 (the path without the trailing id returns 404; corrected by pass 8, F73)
- Oracle Cloud regions: https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm; OCI PostgreSQL DR tutorial: https://docs.oracle.com/en/learn/full-stack-dr-pgsql-cold-dr/index.html
- Alibaba Cloud regions: https://www.alibabacloud.com/help/en/doc-detail/40654.htm
- Google Cloud Run locations: https://docs.cloud.google.com/run/docs/locations
- Vercel regions: https://vercel.com/docs/regions; compliance: https://vercel.com/docs/security/compliance; secure compute: https://vercel.com/docs/networking/secure-compute
- Managed database and platform regions: Neon https://neon.com/docs/introduction/regions; Supabase https://supabase.com/docs/guides/platform/regions; PlanetScale https://planetscale.com/docs/plans/regions; Railway https://docs.railway.com/reference/regions; Render https://render.com/docs/regions; Fly.io https://fly.io/docs/reference/regions/; Upstash https://upstash.com/docs/redis/features/globaldatabase; Cloudflare DLS https://developers.cloudflare.com/data-localization/region-support/; D1 https://developers.cloudflare.com/d1/configuration/data-location/; R2 https://developers.cloudflare.com/r2/reference/data-location/
- Email providers: Resend https://resend.com/docs/dashboard/domains/regions; Postmark https://postmarkapp.com/eu-privacy; SendGrid https://www.twilio.com/docs/sendgrid/data-residency; Mailgun https://www.mailgun.com/about/regions/; SES endpoints https://docs.aws.amazon.com/general/latest/gr/ses.html
- Inngest security: https://www.inngest.com/security; Trigger.dev triggering docs: https://trigger.dev/docs/triggering
- Next.js 16: https://nextjs.org/blog/next-16; installation: https://nextjs.org/docs/app/getting-started/installation; Node release schedule: https://raw.githubusercontent.com/nodejs/Release/main/schedule.json
- Drizzle RLS: https://orm.drizzle.team/docs/rls; drizzle-kit generate: https://orm.drizzle.team/docs/drizzle-kit-generate; Prisma 8 migrations: https://www.prisma.io/docs/orm/migrations/how-migrations-work; Prisma 7 announcement: https://www.prisma.io/blog/announcing-prisma-orm-7-0-0; Atlas community edition: https://atlasgo.io/community-edition
- tRPC v11: https://trpc.io/blog/announcing-trpc-v11; oRPC: https://orpc.dev/; pg-boss: https://github.com/timgit/pg-boss; Graphile Worker cron: https://worker.graphile.org/docs/cron; Zod 4: https://zod.dev/v4; Vitest 5: https://vitest.dev/blog/vitest-5
- PostgreSQL: row security https://www.postgresql.org/docs/current/ddl-rowsecurity.html; CREATE POLICY https://www.postgresql.org/docs/current/sql-createpolicy.html; ALTER TABLE https://www.postgresql.org/docs/current/sql-altertable.html; CREATE ROLE https://www.postgresql.org/docs/current/sql-createrole.html; set_config https://www.postgresql.org/docs/current/functions-admin.html; SET https://www.postgresql.org/docs/current/sql-set.html; PostgreSQL 17 and 18 releases https://www.postgresql.org/about/news/postgresql-17-released-2936/ and https://www.postgresql.org/about/news/postgresql-18-released-3142/
- PgBouncer features: https://www.pgbouncer.org/features.html
- Re-checked 2026-09-24 (F71): Azure Retail Prices API, UAE North, `serviceName eq 'Microsoft Defender for Cloud'` (Defender for Storage: $0.0134 per account-hour, malware scanning $0.15 per GB) and `serviceName eq 'Key Vault'` (Premium HSM-protected RSA 2048-bit key, $1.32 per key-month). Blob SFTP at $0.30 per hour per account is as verified by the pass 7 review; the NAT gateway, Entra ID P2 and support-plan lines are assumptions, not retrieved.
- `drizzle-orm/migrator` runs all pending migrations in one transaction: as read in the package source by the pass 7 review (F40); PostgreSQL refuses `CREATE INDEX CONCURRENTLY` inside a transaction block (https://www.postgresql.org/docs/current/sql-createindex.html)

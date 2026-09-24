# Phase B0: setting up the repository

Read this when the backend repository does not exist yet, or when `CLAUDE.md`, `docs/PLAN.md`, `.claude/rules/` or the hooks are missing. Everything the rest of this skill relies on is created here, mostly in task B0.14.

## Where the source material is

Until the backend repository has its own `docs/spec/`, the plan lives in the prototype repository (`faisalqubbaj2003/Edtech_alldomains`), under `backend-plan/`:

| File | Use it for |
|---|---|
| `CONTEXT.md` | the product, the decisions, the eleven invariants (quote these verbatim; never paraphrase them) |
| `out/01-architecture-and-data-model.md` | DR-3 repository layout, DR-4 tenancy, the schema, the seed (ACS and Wellesmere) |
| `out/06-build-sequence.md` §1.1 | the B0 task table and its acceptance criteria |
| `out/06-build-sequence.md` §2.4 | branch rules, the ruleset on `main`, the PR template fields, the wholesale-replacement check |
| `out/06-build-sequence.md` §3.1 to §3.6 | the brief format, the `docs/PLAN.md` skeleton, the draft `CLAUDE.md`, the `.claude/rules/` table and the hooks table, the documentation checks |
| `out/07-review.md` and `out/08-changelog.md` | why things are the way they are; the decisions of 2026-09-24 |
| `out/README.md` | the index and the open decisions O1 to O106 |

## Order

1. **Make the B0 decisions first** (06 §13, O1 to O14, plus O97, O103 to O105). The scaffold depends on them: the infrastructure tool, the RPC layer, the Postgres major version, the test runner, the GitHub plan. Do not pick these inside a coding session; they are Davide's.
2. **Create the repository and branch protection** per 06 §2.4: `main` only, pull requests required, CI required, linear history, force pushes blocked, bypass list empty, no required approvals while Davide builds alone. Add `CODEOWNERS` naming Davide on every path.
3. **Copy the specification into `docs/spec/`**: `CONTEXT.md`, `PRODUCT.md`, passes 01 to 08 and the README, each with a header giving the source commit and the sentence "This describes a design, not a build. Where it and the code disagree, the code wins."
4. **Install the hooks before writing any application code** (06 §3.4 hooks table). They are the part that is enforced; everything else is guidance. Write each script, then prove it: run the command it must refuse and check it exits with status 2. At minimum: force pushes and merges into `main`; `drizzle-kit push` against anything but localhost; `az`, `psql` and `pg_dump` against anything but localhost or the CI container; reads outside the repository; edits to merged migrations, to `docs/generated/`, and any write containing a name on the real-names blocklist.
5. **Write `CLAUDE.md` from 06 §3.3**, but only claim what exists. The draft describes the finished B0; anything not built yet is marked `(planned)`, because `pnpm docs:verify` will fail on identifiers that do not resolve. Keep it under 200 lines with no line numbers. Quote the eleven invariants verbatim from `CONTEXT.md` §4.
6. **Write `.claude/rules/*.md`** from the 06 §3.4 table (`db`, `engine`, `domain`, `ingest`, `ai`, `web`, `notify`, `copy`), each with its `paths` frontmatter so it loads only for the files it governs.
7. **Write `docs/PLAN.md`** from the 06 §3.2 skeleton: phases B0 to B9 with their task tables (model, effort, reviewer column), the gates, the external-gate back-schedule from 06 §2.3, the week-one checklist (B0.15), and the briefs for B1 in the §3.1 format.
8. **Write the PR template** with the fields from 06 §2.4: task id, model and effort used, reviewer model and verdict, tests added, the acceptance line it satisfies, docs touched with the `PLAN.md` line.
9. **Copy this skill into the repository** at `.claude/skills/caros-backend/`, so every session and every teammate gets it with the code. From then on, that copy is the one to maintain; the copy in the prototype repository becomes history.
10. **Run the bake-off (B0.16)** once `auth.allowed()` has its acceptance tests: the same brief to Opus 5.5 under the zero-data-retention organisation and to Fable 5.1 outside it, on synthetic data, each reviewing the other blind. The verdict is a decision record naming, per category of work, which model writes it from now on.

## Done when

B0's own acceptance criteria in 06 §1.1 hold, and in addition: each hook has been shown to refuse its command; `CLAUDE.md` passes `pnpm docs:verify`; `docs/PLAN.md` lists B1's briefs in the §3.1 format; this skill is present under `.claude/skills/caros-backend/`.

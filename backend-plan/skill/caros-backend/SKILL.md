---
name: caros-backend
description: The working procedure for every build session on the CAROS backend (the Next.js + Postgres build of CAROS Counselor OS on Azure UAE). Use it whenever a session starts, continues or finishes a task from docs/PLAN.md, writes or fixes a task brief, reviews a diff as the second model, closes a phase, or sets up the repository in phase B0. Also use it for any change touching migrations, row-level security, auth.allowed(), the signal engine, safeguarding escalation, the AI gateway, tenant seeds or the documentation, even if the user only says "next task", "pick up B1.6", "wrap up", "review this PR" or "keep going".
---

# CAROS backend: how a build session works

CAROS holds child welfare and safeguarding records about minors, under a real school's name, in a multi-tenant database. The build is done mostly by a coding agent across hundreds of short sessions, by one person, with teammates joining later. This skill is the procedure those sessions follow so that each one leaves the repository in a state the next one can trust.

It exists because this project has already lost work twice to the same two failures: a merge that silently replaced a whole file with an old copy, and documentation that described a build that no longer existed. Almost everything below is aimed at one of those two, or at the third risk that matters most here: real student data ending up somewhere it must never be.

## What lives where

This skill carries **procedure**. The **rules** live in the repository, and they win if anything here disagrees with them:

- `CLAUDE.md`: the shape of the code, the eleven invariants with the mechanism that enforces each, tenancy, commands. Loaded into every session automatically.
- `.claude/rules/*.md`: path-scoped detail for `db`, `engine`, `domain`, `ingest`, `ai`, `web`, `notify` and `copy`. Read the one for the package you are touching.
- `.claude/settings.json` hooks: the things that are actually blocked (force pushes, merges, production access, reads outside the repository, edits to merged migrations and generated files, real names).
- `docs/PLAN.md`: the live task list, every brief, the session notes.
- `docs/spec/`: frozen copies of the eight planning passes. The design. The code is the truth; where they differ, say so in the PR and the decisions log.

Do not copy rules from those files into your reasoning as if this skill were the source. If a rule you need is not in them, that is a documentation gap to note in the PR, not something to invent.

If the repository does not exist yet, or `CLAUDE.md` and `docs/PLAN.md` are missing, you are in phase B0: read `references/bootstrap.md`.

## Pick the mode

| The session is asked to... | Mode |
|---|---|
| start, continue or pick up a task | 1 Start, then 2 Work, then 3 Finish |
| end, wrap up, or it is running out of time | 3 Finish (always, even on failure) |
| write, split or fix a brief | 4 Brief |
| review another model's diff | 5 Review: read `references/review-checklist.md` |
| close a phase, or the task is the phase's documentation task | 6 Phase end |
| set up the repository, or `CLAUDE.md` / `docs/PLAN.md` are missing | 7 Bootstrap: read `references/bootstrap.md` |

## 1 · Start

1. **Check where you are.** One task per session, in its own git worktree, on a branch named `<stream>/<phase>.<task>-<slug>` (for example `a/b1.6-commit-chunks`). If you are on `main`, or in a worktree another session is using, stop and say so. Two sessions sharing a working copy is how a file gets overwritten.
2. **Read the "Now" block of `docs/PLAN.md`** (the SessionStart hook prints it) and find the task. "Now" never holds more than two tasks; if it holds more, a review has been skipped, so point that out before starting.
3. **Read the task's brief.** It must answer, in order: the header line (stream, model and effort, reviewer, attempts, status), *Reads first*, *Produces*, *Done when*, *Out of scope*, *Updates last*. If a part is missing, vague ("works well", "is robust"), or the task plainly cannot fit one session, stop and fix the brief (mode 4) instead of guessing the scope. A session that finds the brief wrong rewrites the brief, never the scope.
4. **Check the attempt counter.**
   - `Attempts: 0` or `1`: continue. At `1`, read the previous session's note in "Session notes" first; it is the hand-off.
   - `Attempts: 2`: this task gets re-planned before anyone codes it. Read both failed sessions' notes, narrow or split the task, and run it on Opus 5.5 at max effort with both notes attached and a Fable 5.1 review of the two failed diffs in the brief.
   - `Attempts: 4` or more: stop. The problem is almost certainly the specification, and it goes to a person for a day without an agent.
5. **Read what the brief names, and only that**: the spec sections under `docs/spec/`, the module's `README.md` under `packages/domain/<module>/`, the rule ledger `docs/screens/<screen>.md` if you are porting a screen, and the `.claude/rules/` file for each package you will touch. Read code as you need it, not up front.
6. **Say back the plan in a few lines**: what you will produce, which "done when" checks prove it, what you are leaving out. This is cheap, and it is where a misread brief gets caught.

## 2 · Work

- **Write the test the brief names before the code it tests.** The "done when" list is the definition of done, and every item on it should end up as a check that runs in CI. No adjectives survive into code.
- **Use the spec's names** for tables, columns, jobs, audit actions, events and state transitions. Parallel vocabulary is how the documentation starts describing a different build. If the spec is wrong, say so in the PR and add a decision record; do not silently diverge.
- **Stay inside the task.** Anything outside it you notice goes into the session note as a new task, not into this diff.

These mistakes are easy to make and do not announce themselves. CI and the hooks catch most of them, but finding them yourself is much cheaper:

- **An ACS-shaped assumption written as a literal.** "Grade", a year number, "Child Protection Officer", "ADEK", a regulator's clause number, an ACS person's name, Sunday-to-Thursday or Monday-to-Friday. Read these from the tenant and its regulator profile. The second synthetic school (Wellesmere: British, Years 10 to 13, a Designated Safeguarding Lead, no IB) exists to catch exactly this, and a screen is not done until it passes on both tenants.
- **A query outside `withTenant()`**, or a domain function whose first line is not `assertAllowed(...)`.
- **An audit entry or event written outside the transaction** that made the change. They commit together or not at all.
- **Anything impure in `packages/engine`**: I/O, the database, `Date.now()`, `new Date()`, `Math.random()`. The engine must give the same answer for the same input forever, because a past alert has to stay explainable.
- **A derived value stored as a column** (the run, course demand, supervision load, dimension statuses). A second copy of the truth drifts.
- **An edit to a migration that is already on `main`.** A correction is a new migration.
- **Personal data leaving the UAE** except through `packages/ai`'s gateway, pseudonymised, to a registry model with `covered_model = false` and `zdr_eligible = true`. Safeguarding, health, nationality and fairness data never go at all.
- **Welfare detail in an email or a log line.** Emails carry references and roles, never anything about a child. Logs carry identifiers only.
- **Resolving a merge conflict by taking one side of a file.** That is the exact failure that cost this project four phases of work. A conflicting branch is rebased in its own session with the conflict list in its brief.

**If you see a real name where a synthetic one should be, or anything that looks like real student data, stop immediately.** Do not copy it, quote it, or "fix" it in place. Say what you saw and where, in the session and in the PR, and end the session. The same applies if a task would require a production credential, a support grant, or a file outside the repository: you never hold these, and the hooks will refuse them anyway.

## 3 · Finish

Run this at the end of every session, including one that failed or ran out of time. A failed session with a good note is worth more than a successful one with no note, because the next attempt starts from the note.

1. **Run the checks.** `pnpm ci` if there is time; at minimum the filters for what you touched (`pnpm test --filter engine`, `pnpm test --filter db`, the package's own tests) and `pnpm docs:verify`. Then run the fast local check from this skill:
   ```bash
   bash <skill-dir>/scripts/precheck.sh
   ```
   It reads your branch's diff against `main` and reports the problems in the list above that a text search can see. It is a quick mirror of CI, not a replacement: anything it flags, fix or explain in the PR.
2. **Report each "done when" check as pass or fail, with the evidence** (the test name, the command output). Do not report the task as done if any check is red, and do not soften a red check into "mostly working".
3. **Update `docs/PLAN.md` in the same PR:** the task line (status, attempts, PR number; add one to `Attempts` if the task is not done), and one line under "Session notes": date, task, outcome, and what the next session must know. Write the note even if nothing else was achieved.
4. **Update the documents your change made stale**, in the same PR: a `docs/decisions/` record if you decided something; the module `README.md` if a public function was added or changed; the rule ledger if you implemented a screen rule. Never hand-edit `docs/generated/`.
5. **Fill the PR template:** the task id, the model and effort actually used (if it differs from the task line, say so), the reviewer model and verdict (or "pending"), the tests added, the acceptance line it satisfies, and "docs touched" including the `PLAN.md` line.
6. **Open the PR and stop.** Never merge, never force-push, never add the `wholesale-rewrite` label. If the task line marks a Fable review (`F`), the PR waits for that review.

## 4 · Brief

A brief is written before the session that does the work, by whoever owns the stream. It answers five questions, in this order, because the next session reads it before anything else:

```
### B3.4 · Escalation: raise, route, reference, outbox rows
Stream: D · Model: Opus 5.5, max (ZDR organisation) · Reviewer: Fable 5.1 (diff only) · Attempts: 0 · Status: ready
Reads first: the spec sections and decision records it implements, the contracts it touches, the module README
Produces:    each file it creates or changes, including the migration and the test file
Done when:   a list of checks, each one something a test or a command can prove
Out of scope: the neighbouring tasks, named, so the session does not drift into them
Updates last: PLAN.md status and attempts; docs/decisions if a decision was made; the PR template fields
```

- A task that cannot be described in this shape is two tasks. Split it.
- "Done when" lists checks, never adjectives. "Handles errors well" is not a check; "a repeated idempotency key is a no-op (test)" is.
- Every task names the spec sections it implements, so the planning passes stay the specification and the code stays the truth.
- A task is two to four hours of one session. If it needs more, it is two tasks.
- Take the model, effort and reviewer from the phase's task table in `docs/PLAN.md`. Opus 5.5 under the zero-data-retention organisation writes; Fable 5.1 reviews diffs only, unless the B0 bake-off record moved that category of work back to Fable.

## 5 · Review

When the session is the second model reviewing another model's diff, read `references/review-checklist.md` and follow it. The short version: you review the diff and the synthetic test data only, you look hardest at the places where a mistake is silent (authorization, row-level security, safeguarding routing, the engine's statistics, irreversible migrations, the AI gateway), and you end with a written verdict on the PR.

## 6 · Phase end

The last task of each phase is a documentation session. Its brief is: describe the build as it stands, and delete every sentence that describes intention.

1. Rewrite `CLAUDE.md` from the code, not from the plan. Keep it under 200 lines, with no line numbers. Anything not yet built is either removed or marked `(planned)`.
2. Run `pnpm docs:verify`. Every backticked identifier in `CLAUDE.md`, `docs/PLAN.md`, `.claude/rules/`, `docs/decisions/` and the package READMEs must resolve. A `(planned)` marker older than one phase fails.
3. Regenerate `docs/generated/` and check that CI shows no diff.
4. Update the `.claude/rules/` files for anything the phase changed about how a package works.
5. Mark the phase complete in `docs/PLAN.md` with the commit, and check the phase's acceptance criteria one by one, with evidence, the same way as mode 3.
6. Check that this skill still matches the repository. If a step here refers to something that no longer exists, fix the skill in the same PR.

## 7 · Bootstrap

Phase B0 creates the repository and the files this skill relies on. Read `references/bootstrap.md`.

## Stop and ask instead of proceeding

- Real data, a real person's name, a production credential, or a support grant appears or would be needed.
- The task would weaken one of the eleven invariants in `CLAUDE.md`, or needs a school-specific exception to one. Invariants are product, not configuration.
- The brief and the spec disagree in a way the brief does not resolve.
- A test in the "done when" list cannot pass with the data or history available. The review has already found one of these once; flag it rather than weakening the test.
- The change would need a model's output to gate, rank or decide something.

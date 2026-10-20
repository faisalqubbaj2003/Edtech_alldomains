# Outstanding items from `$impeccable critique`

Source: critique run against live production (`main`, https://ed-tech-orpin-ten.vercel.app/) on 2026-09-01. Full report, heuristic scores, and persona findings aren't duplicated here — this is just the action list, so it survives in git regardless of who's continuing the work or in which chat.

Four of the six original recommended actions are now shipped:
- `$impeccable layout` — triage action rail tiering (commit `0572efc`)
- `$impeccable audit` — Teacher portal "Mentor Hub" mislabel fix (commit `0572efc`)
- `$impeccable harden` — safeguarding escalation now opens a modal requiring a written reason of 12+ characters, writes the reason into the audit line, and locks after one use (was item 1 below)
- `$impeccable optimize` — multi-select plus bulk "Mark as seen" and bulk reassign now exist on the caseload ledger (was item 2 below)

The two below are still open, in priority order. Items 1 and 2 are kept for the record with their resolution noted.

## 1. ~~`$impeccable harden` — Escalate to DSL needs a confirmation step~~ · RESOLVED 2026-10

**Shipped.** The action now opens `escalateModal`, which shows the full referral, requires a reason of at least 12 characters, and cannot fire twice. Note the field named below is `SCHOOL.safeLead`, not `SCHOOL.dsl`.

<details><summary>Original finding</summary>

**[P1]** "Escalate to DSL" (case-detail page, `index.html`, in the "Triage this case" panel) fires immediately on a single click. It notifies a real, named safeguarding lead (`SCHOOL.dsl`) and writes to the permanent audit log about a specific student. A misclick has consequences nothing can undo after the fact.

**Fix:** require a one-tap confirm or a short reason field before the action actually fires.
</details>

## 2. ~~`$impeccable optimize` — no bulk actions across the caseload~~ · RESOLVED 2026-10

**Shipped on the ledger** rather than on the priority-cases list the critique named. `vCommand` still has no multi-select.

<details><summary>Original finding</summary>

**[P2]** A counselor's real caseload runs 5 urgent / 16 review / 87 students total, and every case — including routine "Review" ones — has to be opened and triaged individually. No multi-select, no bulk action.

**Fix:** add multi-select plus bulk "Acknowledge" / "Assign" on the priority-cases list.
</details>

## 3. `$impeccable distill` — case-detail page has no progressive disclosure by severity

**[P3]** Case pages render the full evidence-chain / context / university-flags layout in full even for Monitor or Recovered-tier cases, where there's nothing urgent to act on.

**Fix:** collapse secondary sections by default for non-urgent tiers; expand on demand.

## 4. `$impeccable polish` — final pass

Once the three above land, run a final polish pass over the touched areas before considering this critique's findings closed.

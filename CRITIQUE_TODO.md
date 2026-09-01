# Outstanding items from `$impeccable critique`

Source: critique run against live production (`main`, https://ed-tech-orpin-ten.vercel.app/) on 2026-09-01. Full report, heuristic scores, and persona findings aren't duplicated here — this is just the action list, so it survives in git regardless of who's continuing the work or in which chat.

Two of the six original recommended actions are already shipped on `main`:
- `$impeccable layout` — triage action rail tiering (commit `0572efc`)
- `$impeccable audit` — Teacher portal "Mentor Hub" mislabel fix (commit `0572efc`)

The four below are still open, in priority order.

## 1. `$impeccable harden` — Escalate to DSL needs a confirmation step

**[P1]** "Escalate to DSL" (case-detail page, `index.html`, in the "Triage this case" panel) fires immediately on a single click. It notifies a real, named safeguarding lead (`SCHOOL.dsl`) and writes to the permanent audit log about a specific student. A misclick has consequences nothing can undo after the fact.

**Fix:** require a one-tap confirm or a short reason field before the action actually fires.

## 2. `$impeccable optimize` — no bulk actions across the caseload

**[P2]** A counselor's real caseload runs 5 urgent / 16 review / 87 students total, and every case — including routine "Review" ones — has to be opened and triaged individually. No multi-select, no bulk action.

**Fix:** add multi-select plus bulk "Acknowledge" / "Assign" on the priority-cases list.

## 3. `$impeccable distill` — case-detail page has no progressive disclosure by severity

**[P3]** Case pages render the full evidence-chain / context / university-flags layout in full even for Monitor or Recovered-tier cases, where there's nothing urgent to act on.

**Fix:** collapse secondary sections by default for non-urgent tiers; expand on demand.

## 4. `$impeccable polish` — final pass

Once the three above land, run a final polish pass over the touched areas before considering this critique's findings closed.

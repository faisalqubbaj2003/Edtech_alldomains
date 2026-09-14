# CAROS screenshots for the Astra design pass

Captured 14 September 2026 from `main` at commit `fb28217`, the current build.
Headless Chrome, 2x device pixel ratio, ACS Abu Dhabi rendition (`?school=acs`).
The debug UX Audit panel was removed before capture, so these are clean.

| File | Surface | Viewport |
|---|---|---|
| 01-counselor-caseload | Caseload, 87 students, the morning view. The hero screen. | 1440x1000 |
| 02-counselor-priority-cases | Priority cases, overnight tier movements | 1440x1000 |
| 03-counselor-case-detail | Case detail: evidence chain, baseline, intervention loop | 1440x1200 |
| 04-counselor-how-detection-works | How a signal was derived | 1440x1200 |
| 05-counselor-copilot | AI co-pilot with automation boundaries | 1440x1000 |
| 06-counselor-student-file | 360 student file | 1440x1200 |
| 07-student-pathway | Student pathway, IB against AP | 1440x1000 |
| 08-student-progress | Student progress | 1440x1000 |
| 09-parent-overview-mobile | Parent overview, the real device | 390x844 |
| 10-parent-messages-mobile | Parent messages to the counselor | 390x844 |
| 11-parent-overview-desktop | Same screen at desktop, for comparison | 1440x1000 |
| 12-student-progress-mobile | Student progress at phone width | 390x844 |
| 13-student-progress-DARK | Dark mode, student surface | 1440x1000 |
| 14-student-pathway-DARK | Dark mode, student surface | 1440x1000 |
| 15-counselor-escalation-modal | Safeguarding referral to the Child Protection Officer, the gravest moment in the product | 1440x1000 |
| 16-counselor-command-palette | Command palette, the keyboard path | 1440x1000 |
| 17-counselor-caseload-monitor-block | Caseload scrolled into the 77-row Monitor block, the density case | 1440x1000 |
| 18-counselor-bulk-selection | Four students selected, bulk action bar | 1440x1000 |
| 19-parent-grade9-empty-by-design | Grade 9 family portal, sparse because it is correct, not broken | 390x844 |
| 20-parent-grade9-desktop | Same, at desktop | 1440x1000 |

## Two findings worth knowing before you design

**Dark mode exists only on the student surface.** It is gated to
`html[data-role="student"]` at index.html:149. The counselor, parent, teacher
and mentor surfaces have no dark palette at all. The dark tokens are written
and contrast-checked; widening them was left as a product decision.


**A live defect is visible in 15.** The escalation modal renders the literal
text `The ${SAFE} reads this first` because a placeholder at index.html:8553
sits inside a single-quoted string nested in a template literal and never
interpolates. It should read "The Child Protection Officer reads this first."
It is a bug awaiting a fix, not a design decision. Do not carry it forward.

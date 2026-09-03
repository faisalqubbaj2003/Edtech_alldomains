# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

**Primary: the school counselor.** At the demo school she is Head of University Counseling, carrying a caseload of 87 students across Grades 9–12. Her situation is structural triage under scarcity: she cannot give 87 students equal attention, so her real job every morning is deciding *who needs her today* and defending that decision later. She works in bursts between meetings, on a laptop, often with a student or parent already sitting in front of her.

Four secondary audiences, each with a genuinely different job — not the same dashboard relabeled:

- **Parents** — anxious, non-expert, want to know their child is on track and what it will cost. Read on phones.
- **Students (Grades 9–12)** — deciding IB vs AP (Grade 10), building a record (11), mid-application (12). A Grade 12 applying to university is a serious audience, not a gamification target.
- **Teachers** — 90 seconds between lessons. Their only job is logging a concern about a student they just taught. This is the school's earliest and cheapest signal.
- **Alumni mentors** — verified, volunteer, contact strictly in-platform for safeguarding.

## Product Purpose

CAROS helps a counseling team notice which students need support *before those students ask*, absorbs the administrative weight of the university application cycle, and gives every stakeholder in a student's journey exactly the view they need and nothing more.

Success is the counselor ending the day confident that nobody fell through a gap, and able to prove to school leadership that the intervention happened and worked.

## Positioning

The mechanism a neighboring product cannot truthfully copy is **deviation from a student's own baseline**, not from a cohort average. CAROS learns each student's personal normal band across academics, attendance, engagement, behaviour, teacher sentiment and university progress, and raises a signal when *that student* moves against *their own* history. A cohort-average tool cannot see a strong student quietly declining, or a struggling student genuinely recovering.

The second differentiator is that the counselor's caseload is a **triaged queue with real SLA states**, not a list — five severity tiers (urgent → check-in → review → monitor → good) that order the day.

Competitive frame: Naviance is the incumbent schools complain about; Scoir is the challenger winning on interface quality. UI quality is a proven switching driver in this category.

## Operating Context

- The morning ritual: an overnight engine sweep runs before the counselor arrives; her first question is literally *what changed overnight*. Priority-tier movements between yesterday and today are the highest-value information in the product.
- The application cycle is deadline-shaped and unforgiving; letters, transcripts, and offers all have dates that cannot slip.
- Safeguarding escalation to a named Designated Safeguarding Lead is a real, consequential, logged act — not a UI state.
- Evidence chains matter: every signal must show what fed it, because the counselor has to justify her attention to parents and leadership.
- Academic data at pilot arrives as a termly CSV exported from the school's SIS (iSAMS / PowerSchool / Veracross shaped). No live SIS integration.
- Four destination systems are modelled: UK, US, UAE, Canada. Canada is deliberate — domestic-vs-international tuition by passport is the clearest demonstration of the fee-status logic.

## Capabilities and Constraints

**Confirmed functionality:** caseload triage and case detail; signal intelligence against personal baselines; 360° student files; recommendation-letter engine; AI co-pilot over the caseload; reporting to leadership; parent portal (transcripts, university requirements, cost of attendance, offer tracking, counselor messaging and meeting requests); student portal (pathway discovery, IB/AP choice, progress, university targets, personal statement lab); teacher concern logging; mentor session requests.

**Technical constraints:** one self-contained `index.html`. Vanilla JS, no framework, no build step, no backend, no package manager, no test suite. All data in memory; refresh resets the demo. Must run offline from a double-clicked file. `draw()` rebuilds the whole tree on every state change — this is the governing performance and motion constraint.

**Terminology that must not drift:** *match* already means reach/match/safety in university data, so it can never be reused for mentor pairing. The five triage tiers and their order are product logic. IB and AP are tracks, not themes.

**Resolved 2026-09-03 (P5):** the Mentor role survives, unpriced. The $120/session marketplace stays cut — no view charges for a session, mentor introductions are arranged by the school at no cost, and every mentor conversation is described as safeguarded and in-platform rather than transactional.

**Explicitly undecided:** whether Teacher and Mentor roles get their own persona accent.

## Brand Commitments

- The name is **CAROS — Counselor OS**. "Career OS" is the student-facing name for the student portal.
- **The trust spine: rules decide, the model writes.** Deterministic tables own entry requirements, prerequisites, fee status, tuition, deadlines and reach/match/safety classification. The model only interprets, names, phrases and converses. Every number a student sees must trace to a source. This is a binding product principle and any interface must make provenance visible rather than implying machine omniscience.
- **Gamification on the student side is permitted, and is a deliberate reversal.** The earlier position ("no streaks, no confetti, no characters, no points — a Grade 12 applying to university is a serious audience") was overturned by the team on 2026-09-02 in favour of retention. The build already reflects the new position: a milestone roadmap awards XP and fires a confetti burst on completion. Future work should design this properly as a first-class part of the student register rather than treating it as a bolt-on, and must not reintroduce the old prohibition. The counselor, parent, teacher and mentor surfaces remain ungamified.
- Mentor contact is in-platform only, for safeguarding.

## Evidence on Hand

Real assets: `index.html` (the full working prototype), `README.md`, `CLAUDE.md` (the incumbent design system, written from the built code).

**Absences future work must not fabricate — this section is load-bearing:**

- **There is no real partner school's data in the product.** Every student, family, grade, message and meeting in the prototype is synthetic demo content, and "Ms. Reem Haddad" is fictional.
- **From 2026-09-02 the demo is branded as the American Community School of Abu Dhabi** for the pilot with one of their counselors, replacing the invented "Al Bateen Academy" (which had to go regardless — ACS occupied the Al Bateen campus for fifty years before moving to Saadiyat Island, so the old name reads as their former campus). **Branding the demo with a real school's name makes the synthetic-data label a hard requirement, not a nicety:** these are fabricated student welfare and safeguarding records under a real institution's identity, and a screenshot can travel. A persistent, visible "demonstration data" marker must be present on any surface showing student records while a real school's name is applied — it is not to be hidden for a cleaner demo screenshot. No real ACS student, staff member or outcome may be represented.
- There are no real testimonials, customers, outcomes, benchmarks, pricing, or press. None may be invented or implied anywhere in the interface.
- Alumni outcome data backing the IB-vs-AP explainer is synthetic.
- The current probability figure in the student pathway view is fabricated in code (a hardcoded start plus fixed increments per checkbox). It is not a model output and must not be presented as one.

Synthetic demonstration content is legitimate design material and should be authored at full fidelity — but it is labeled as demo content, and no commercial or factual claim rides on it.

## Product Principles

1. **Attention is the scarce resource.** Every screen either helps the counselor decide who to see next, or defends a decision she already made. A number nobody acts on does not belong in the interface.
2. **Signals are personal, never comparative.** Deviation is measured against the student's own baseline band. Never rank students against each other.
3. **Provenance over authority.** Show the evidence chain and the source. The product never asks to be believed; it shows its work.
4. **Register follows audience.** A parent's portal and a counselor's console are different emotional instruments. Differentiation between roles is a feature, not inconsistency to be normalized away. The student surface may motivate; the counselor surface may not.
5. **Absence is information.** A Grade 9 family's near-empty portal is correct, not broken — and the interface must say *why* it is empty, or the family stops opening it.

## Accessibility & Inclusion

Target WCAG 2.1 AA. Established needs: full keyboard operation including the ⌘K command palette; visible focus throughout; severity must never be conveyed by color alone, since the five triage tiers read as a red→green gradient; `prefers-reduced-motion` must zero both duration *and* delay, because staggered entry animations use `backwards` fill and a surviving delay leaves content blank; parent and student portals are used on phones and must hold at 375px.

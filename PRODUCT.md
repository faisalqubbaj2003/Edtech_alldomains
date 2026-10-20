# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

**Primary: the school counselor.** At the demo school she is a High School Counselor carrying a caseload of 87 students across Grades 9–12, one of a team of four who split the high school between them. Her situation is structural triage under scarcity: she cannot give 87 students equal attention, so her real job every morning is deciding *who needs her today* and defending that decision later. She works in bursts between meetings, on a laptop, often with a student or parent already sitting in front of her.

Four secondary audiences, each with a genuinely different job — not the same dashboard relabeled:

- **Parents** — anxious, non-expert, want to know their child is on track and what it will cost. Read on phones.
- **Students (Grades 9–12)** — deciding IB vs AP (Grade 10), building a record (11), mid-application (12). A Grade 12 applying to university is a serious audience, not a gamification target.
- **Teachers** — 90 seconds between lessons. Their only job is logging a concern about a student they just taught. This is the school's earliest and cheapest signal.
- **Alumni mentors** — verified, volunteer, contact strictly in-platform for safeguarding.

## Product Purpose

CLAROS helps a counseling team notice which students need support *before those students ask*, absorbs the administrative weight of the university application cycle, and gives every stakeholder in a student's journey exactly the view they need and nothing more.

Success is the counselor ending the day confident that nobody fell through a gap, and able to prove to school leadership that the intervention happened and worked.

## Positioning

The mechanism a neighboring product cannot truthfully copy is **deviation from a student's own baseline**, not from a cohort average. CLAROS learns each student's personal normal band across academics, attendance, engagement, behaviour, teacher sentiment and university progress, and raises a signal when *that student* moves against *their own* history. A cohort-average tool cannot see a strong student quietly declining, or a struggling student genuinely recovering.

The second differentiator is that the counselor's caseload is a **triaged queue with real SLA states**, not a list — five severity tiers (urgent → check-in → review → monitor → good) that order the day.

Competitive frame: Naviance is the incumbent schools complain about; Scoir is the challenger winning on interface quality. UI quality is a proven switching driver in this category.

## Operating Context

- The morning ritual: an overnight engine sweep runs before the counselor arrives; her first question is literally *what changed overnight*. Priority-tier movements between yesterday and today are the highest-value information in the product.
- The application cycle is deadline-shaped and unforgiving; letters, transcripts, and offers all have dates that cannot slip.
- Safeguarding escalation to a named Designated Safeguarding Lead is a real, consequential, logged act — not a UI state.
- Evidence chains matter: every signal must show what fed it, because the counselor has to justify her attention to parents and leadership.
- Academic data at pilot arrives as a termly CSV exported from the school's SIS (iSAMS / PowerSchool / Veracross shaped). No live SIS integration. The SIS name is a school-record field (`sis`), never a hardcoded string.

### Structural findings from the 2026-09-04 reference school

**The build is no longer branded to any school** (see Brand Commitments). These findings came from one real international school's published sources and still shape the product, so they are kept; the school's name is not. Re-verify against whichever school a pilot actually lands with.

- **An international school of roughly 1,200 to 1,315 students, KG1 through Grade 12**, drawing from 80+ countries. Useful as the order of magnitude a pilot should assume.
- **Counselors are titled simply "Counselor" or "HS Counselor".** There is commonly **no Head of University Counseling and no separate university counseling department** — the high school counseling team does that work alongside everything else. The persona title was corrected accordingly.
- At a senior cohort of roughly 80 to 95, Grades 9–12 is about 320 to 380 students across four counselors, so **the demo's caseload of 87 is close to a real per-counselor load.** That figure should stay.
- **The safeguarding role may be Child Protection Officer rather than Designated Safeguarding Lead.** DSL is British-school vocabulary; a US-curriculum international school is likelier to use Child Protection Officer. Both live in the school record (`safeguarding`), never hardcoded, so a pilot takes its own term.
- **A school may offer the IB Diploma Programme, Advanced Placement and its own high school courses.** The IB-versus-AP surface is therefore well matched, but the real choice can be three ways, not two. The product still models it as a binary plus "undecided".
- Published outcome claims (university attendance, top-choice acceptance) belong to the school that published them. **Never restate a school's claims as CLAROS outcomes.**

No real student, family or staff member is represented anywhere in the build. The counselor, the safeguarding lead and every family are fictional, and stay fictional.
- Four destination systems are modelled: UK, US, UAE, Canada. Canada is deliberate — domestic-vs-international tuition by passport is the clearest demonstration of the fee-status logic.

## Capabilities and Constraints

**Confirmed functionality:** caseload triage and case detail; signal intelligence against personal baselines; 360° student files; recommendation-letter engine; AI co-pilot over the caseload; reporting to leadership; parent portal (transcripts, university requirements, cost of attendance, offer tracking, counselor messaging and meeting requests); student portal (pathway discovery, IB/AP choice, progress, university targets, personal statement lab); teacher concern logging; mentor session requests; **IB subject selection and CAS** (see below).

### The IB module, added 2026-09-10

Driven by a meeting with the reference school's IB coordinator, and the first part of the product shaped by a named user's own workflow rather than by a design review. His process today is verbal choices written into a notebook, carried to the counselors, then worked up by hand into whether a course can run. He wants to keep the conversation and hand back the clerical half.

- **Subject selection** runs as a round with an open and close date. A Grade 10 student fills six group slots, chooses a level, and writes a reason against each choice. The reason is required, because it is what turns the counselor's meeting from collection into guidance.
- **The rules are deterministic tables**, per the trust spine: group coverage, HL count, period clashes, prerequisites, stated-goal alignment and whether the course will run. Nothing that gates a submission is model output.
- **Sign-off is subject teacher, then coordinator.** A teacher answers only the level question and only for subjects they teach. The coordinator decides the whole selection.
- **The conversation is a gate.** A selection cannot be approved until a dated, attributed record of the review meeting exists. This is a product rule, not a UI state, and it is the point of the module.
- **The coordinator is a counselor view, not a sixth role**, matching the verified counseling-team structure.
- **CAS** covers the three strands, the seven learning outcomes, hours as a school-level expectation (the IB itself no longer specifies 150), reflections, and a coordinator view of who has stopped and in which strand. Interests are captured where they are used rather than in the three-tap sign-in gate, and matched to browsable school activities with the match's reason shown.

### The Extended Essay, added 2026-09-10

The second half of the Diploma-core module, from Davide's brief.

- **Students propose**: a subject, a working research question, and a short rationale, sent to a teacher who teaches that subject. They then see the state of it, the schedule, and a nudge when a checkpoint is near or has passed.
- **Teachers answer from a queue**, scoped to their own subjects, with the student's rationale and their own supervision load on every card. They accept, ask for a sharper question, or pass it to a colleague. The draft is readable in place.
- **Capacity warns and never blocks.** Five essays is the school's guide, not a rule; the coordinator can see when a teacher is over it, and an assignment made over it records that it was.
- **The reflective statement** is recorded when it is written, dated and attributed, rather than reconstructed before submission. Under the IB's Extended Essay guide for first assessment in 2027, the three mandatory reflection sessions of the 2018 guide (the Reflections on Planning and Progress Form) are replaced by one reflective statement of at most 500 words. Both of ACS's current Diploma cohorts are assessed under the 2027 guide. The prototype's screens still show the 2018 guide's three sessions; the backend follows the 2027 guide.
- **Coordinators get the aggregate that does not exist today**: who has a supervisor, who is drifting toward a deadline without one, whose reflective statement is done, and where supervision has landed across the staff.

Theory of knowledge is **described and not tracked**, and the interface says so rather than implying coverage it does not have.

Every research question in the build is authored, and none repeats. The Diploma cohort's upper years are sized to that writing rather than the other way round.

**A second population exists, and must stay separate.** The caseload is 87 students across Grades 9–12 belonging to one counselor. The Diploma cohort is the school's IB population across three year groups (Grade 10 choosing, Grades 11 and 12 in the programme). They answer different questions and no screen may total them together.

The IB subject catalogue, its descriptions, the school activities behind CAS, every Extended Essay research question and both cohorts are synthetic demonstration content. No real school's course list, programme, co-curricular offering or student essay is represented.

**Technical constraints:** one self-contained `index.html`. Vanilla JS, no framework, no build step, no backend, no package manager, no test suite. All data in memory; refresh resets the demo. Must run offline from a double-clicked file. `draw()` rebuilds the whole tree on every state change — this is the governing performance and motion constraint.

**Terminology that must not drift:** *match* already means reach/match/safety in university data, so it can never be reused for mentor pairing. The five triage tiers and their order are product logic. IB and AP are tracks, not themes.

**Resolved 2026-09-03 (P5):** the Mentor role survives, unpriced. The $120/session marketplace stays cut — no view charges for a session, mentor introductions are arranged by the school at no cost, and every mentor conversation is described as safeguarded and in-platform rather than transactional.

**Explicitly undecided:** whether Teacher and Mentor roles get their own persona accent.

## Brand Commitments

- The name is **CLAROS — Counselor OS**. "Career OS" is the student-facing name for the student portal.
- **The trust spine: rules decide, the model writes.** Deterministic tables own entry requirements, prerequisites, fee status, tuition, deadlines and reach/match/safety classification. The model only interprets, names, phrases and converses. Every number a student sees must trace to a source. This is a binding product principle and any interface must make provenance visible rather than implying machine omniscience.
- **Gamification on the student side is permitted, and is a deliberate reversal.** The earlier position ("no streaks, no confetti, no characters, no points — a Grade 12 applying to university is a serious audience") was overturned by the team on 2026-09-02 in favour of retention. The build already reflects the new position: a milestone roadmap awards XP and fires a confetti burst on completion. Future work should design this properly as a first-class part of the student register rather than treating it as a bolt-on, and must not reintroduce the old prohibition. The counselor, parent, teacher and mentor surfaces remain ungamified.
- Mentor contact is in-platform only, for safeguarding.

## Evidence on Hand

Real assets: `index.html` (the full working prototype), `README.md`, `CLAUDE.md` (the incumbent design system, written from the built code).

**Absences future work must not fabricate — this section is load-bearing:**

- **There is no real partner school's data in the product.** Every student, family, grade, message and meeting in the prototype is synthetic demo content, and "Ms. Reem Haddad" is fictional.
- **From 2026-10-20 the demo carries no school identity at all.** It was briefly branded to a real international school for a pilot; that branding, its crest and its name were removed, and the seeded school record now ships with an empty name, short form and initials so the letterhead reads as CLAROS alone. **The synthetic-data marker stays regardless.** The original reason was that a real institution's identity sat over fabricated welfare records; the records are still fabricated, a screenshot still travels, and a demo showing student welfare data owes the viewer that label. It is gated on the school record, not on a debug flag, so it cannot be switched off for a cleaner screenshot. If a partner school's name is ever applied again, the marker becomes non-negotiable and no real student, staff member or outcome may be represented.
- There are no real testimonials, customers, outcomes, benchmarks, pricing, or press. None may be invented or implied anywhere in the interface.
- Alumni outcome data backing the IB-vs-AP explainer is synthetic.
- ~~The current probability figure in the student pathway view is fabricated in code.~~ **Removed 2026-10.** The hardcoded probability and the view it drove are gone from the build. The per-university "Chance" column on the student targets table survives and is hand-authored roster data, not a model output; it must not be presented as one.

Synthetic demonstration content is legitimate design material and should be authored at full fidelity — but it is labeled as demo content, and no commercial or factual claim rides on it.

## Product Principles

1. **Attention is the scarce resource.** Every screen either helps the counselor decide who to see next, or defends a decision she already made. A number nobody acts on does not belong in the interface.
2. **Signals are personal, never comparative.** Deviation is measured against the student's own baseline band. Never rank students against each other.
3. **Provenance over authority.** Show the evidence chain and the source. The product never asks to be believed; it shows its work.
4. **One register, formal, across every role.** *Reversed 2026-10-20.* This principle previously read "Register follows audience" and held that a parent's portal and a counselor's console were different emotional instruments. The team overturned it: CLAROS is a startup selling to schools, and a product holding safeguarding records should not change voice depending on who is reading. Interface copy is formal, precise and consistent on all five surfaces — headings are noun phrases, not questions; idiom ("needs a nudge", "chase", "take a look") is replaced by the term a school would use in writing. Do not restore the old differentiation.

   **The exception, and it is not a loophole: people in the product still sound like people.** Parent and counselor message threads, quoted parent questions in the IB/AP explainer, co-pilot queries typed in natural language, student statement drafts and Extended Essay research questions are *content*, not interface. A message thread written in corporate register reads as fabricated and damages the demo. Formalise the chrome; leave the humans alone.
5. **Absence is information.** A Grade 9 family's near-empty portal is correct, not broken — and the interface must say *why* it is empty, or the family stops opening it.

## Accessibility & Inclusion

Target WCAG 2.1 AA. Established needs: full keyboard operation including the ⌘K command palette; visible focus throughout; severity must never be conveyed by color alone, since the five triage tiers read as a red→green gradient; `prefers-reduced-motion` must zero both duration *and* delay, because staggered entry animations use `backwards` fill and a surviving delay leaves content blank; parent and student portals are used on phones and must hold at 375px.

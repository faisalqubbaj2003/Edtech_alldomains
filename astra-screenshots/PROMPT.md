# Filled prompt for GPT Astra

Paste everything below the line as one message. Everything it needs is in the repo, including the screenshots; section 1 says exactly where. If your Astra session also lets you attach images directly, attach the twenty PNGs as well, because attached images are read more reliably than images fetched from a branch.

---

You are acting as a senior product designer and front-end engineer. I want a real design pass, not a restyle. Read everything below before you produce anything.

## 1. What this is

**Product:** CAROS, an operating system for school counseling teams. It tells a counselor who needs her today, absorbs the administrative weight of the university application cycle, and gives every other stakeholder in a student's journey exactly the view they need and nothing more.

**Platform and constraints, all non-negotiable:**
- One self-contained `index.html`, currently about 10,000 lines.
- Vanilla JS. No framework, no build step, no package manager, no backend, no test suite.
- All data in memory. A refresh resets the demo.
- Must run offline from a double-clicked file. That rules out anything needing a server, a bundler, or a runtime fetch. Fonts and assets are either embedded or have a system fallback that actually holds.
- A single global `draw()` rebuilds the entire DOM tree on every state change. This is the governing performance and motion constraint: no design may depend on persisted DOM, on CSS transitions surviving a re-render, or on animation state that lives outside the state object.
- Dark mode exists on the student surface only and must keep working there. See the note below on why that is unfinished rather than deliberate.

**Current state:** the prototype is complete in function across six roles and roughly seventy views. It already has a deliberate visual system, described in section 8 below. What it does not have is a coherent, defensible design across the three surfaces that matter, and the density is uneven: some screens are thin, some are overloaded, and the relationship between them is not stated anywhere.

**You have the repository connected.** The product is the single file `EdTech-folder/index.html` on `main`. Read it, and read these three alongside it, because they are the authorities this brief is condensed from and they carry detail I have had to cut here:

- `EdTech-folder/PRODUCT.md`, the product truth: users, positioning, constraints, and the list of things that must never be fabricated.
- `EdTech-folder/DESIGN.md`, the built visual system as it currently stands, written from the running code.
- `EdTech-folder/.impeccable/surfaces/index-html.md`, the direction contract, and `EdTech-folder/.impeccable/critique/`, an existing audit snapshot with findings at file and line. Read the audit after you have written your own critique, not before, and then tell me where you disagree with it.

Two things about the repo you need to know. **The documentation in it has a standing habit of describing a build that no longer exists.** Verify any named function, token, class or CSS variable against `index.html` before you rely on it, including anything you read in the files I just listed. And **ignore `EdTech-folder-2.4/`**, which is a stale checkout pinned to an earlier phase.

**Do not commit, do not open a pull request, and do not edit `index.html`.** These three versions are explorations that I will choose between. Deliver them as three new standalone files that do not touch the product.

### Where the screenshots are, and why they matter more than the source

**Twenty screenshots are in the repo, on a separate branch.** Look here:

```
branch:  design/astra-screenshots
folder:  astra-screenshots/
```

Read `astra-screenshots/README.md` first. It is the manifest: every file, the surface it shows, the viewport, and two findings you would otherwise misread.

**Treat the screenshots as primary and the source as secondary.** The interface only exists at runtime. A single global `draw()` builds the whole DOM from state, so the design is spread across template literals and reading it is not seeing it. Where the source and the screenshots disagree, the screenshots are what the user actually sees.

| File | What it shows |
|---|---|
| `01-counselor-caseload.png` | The caseload, 87 students, the morning view. **The screen the product lives or dies on, and the one I would nominate as your hero screen.** |
| `02-counselor-priority-cases.png` | Priority cases, the overnight tier movements |
| `03-counselor-case-detail.png` | Case detail: evidence chain, baseline deviation, intervention loop |
| `04-counselor-how-detection-works.png` | How a signal was derived and what fed it |
| `05-counselor-copilot.png` | The AI co-pilot, with its stated automation boundaries |
| `06-counselor-student-file.png` | The 360 student file |
| `07-student-pathway.png` | Student pathway, the IB against AP decision |
| `08-student-progress.png` | Student progress |
| `09-parent-overview-mobile.png` | Parent overview at 390px, the real device |
| `10-parent-messages-mobile.png` | Parent messages to the counselor, 390px |
| `11-parent-overview-desktop.png` | The same parent screen at desktop, for comparison |
| `12-student-progress-mobile.png` | Student progress at 390px |
| `13-student-progress-DARK.png` | Dark mode, student surface |
| `14-student-pathway-DARK.png` | Dark mode, student surface |
| `15-counselor-escalation-modal.png` | The safeguarding referral to the Child Protection Officer. **The gravest moment in the product, and the test of section 4.** |
| `16-counselor-command-palette.png` | The command palette, the keyboard path |
| `17-counselor-caseload-monitor-block.png` | The caseload scrolled into the 77-row Monitor block. **This is the density case, and the one that breaks layouts.** |
| `18-counselor-bulk-selection.png` | Four students selected, bulk action bar |
| `19-parent-grade9-empty-by-design.png` | The Grade 9 family portal. **Sparse because sparse is correct, not because it is broken.** |
| `20-parent-grade9-desktop.png` | The same, at desktop |

These are deliberately the crowded and awkward screens rather than the flattering ones.

**Two things you would otherwise misread, both also recorded in the manifest.**

**First, dark mode exists only on the student surface.** It is gated to `html[data-role="student"]` in the CSS. The counselor, parent, teacher and mentor surfaces have no dark palette at all, and the dark tokens that do exist are written and contrast-checked but never widened. That is an unfinished decision, not a design position. Tell me what each of your three versions does about it.

**Second, screenshot 15 contains a live bug, not a copy decision.** The escalation modal renders the literal text `The ${SAFE} reads this first` because a placeholder at `index.html:8553` sits inside a single-quoted string nested in a template literal and never interpolates. It should read "The Child Protection Officer reads this first." A fix is pending. Do not carry it forward into any version, and do not treat it as evidence about the product's copy standards.

## 2. The one job

**Help a counselor carrying 87 students decide who to see today, and defend that decision afterwards to a parent or to school leadership.**

Everything else in the product exists to feed that sentence or to reduce the admin that stops her doing it. If a screen serves neither, say so in your critique rather than styling it.

## 3. Who uses it

| Audience | State of mind | Device | Session | Came to do |
|---|---|---|---|---|
| **School counselor** (primary, the whole product hangs off her) | Structural triage under scarcity. She cannot give 87 students equal attention, and she knows it. Often has a student or a parent physically sitting in front of her while she uses it. | Laptop | Bursts of 2 to 10 minutes between meetings, plus one longer morning session | Find out what changed overnight, decide who to see, and pull up the evidence for a case in the seconds before a conversation starts |
| **Parent** | Anxious, non-expert, wants reassurance and a number. Will not read an interface twice to find something. | Phone | 60 seconds, sporadic, often in the evening | Confirm their child is on track, see what university will cost, message the counselor |
| **Student, Grades 9 to 12** | Grade 10 is choosing IB against AP. Grade 11 is building a record. Grade 12 is mid-application and stressed. A Grade 12 applying to university is a serious audience. | Phone and laptop both | 3 to 15 minutes, self-directed | See where they stand, work on the next concrete thing, and understand a decision that feels irreversible |

These three are supposed to feel like different instruments. The counselor's console is a working tool, the parent's portal is reassurance, the student's is momentum. Do not normalize them into one tone for the sake of consistency. Differentiation between roles is a feature here, not an inconsistency to be fixed.

One nuance on the student surface: gamification is permitted there, and only there. A milestone roadmap with XP and a completion moment already exists. It was a deliberate reversal of an earlier no-gamification position, taken for retention, and I do not want it argued back. I want it designed properly as a first-class part of the student surface instead of sitting on top as a bolt-on. The counselor and parent surfaces stay completely ungamified.

## 4. Emotional register, which I am treating as a requirement and not as polish

The product carries difficult material. A counselor opens it to find out which of her students is deteriorating. A parent opens it because they are worried. A student opens it at the point they think one choice will determine their life. If the interface has no emotional position, it takes one anyway, and the default position is indifference.

So for each surface, design to a stated feeling, and tell me in writing what you designed to.

- **Counselor: composure.** She should feel that the day is surveyable, that the tool is on her side, and that nothing is being hidden from her. Calm competence, not urgency theatre. The urgent tier must read as serious without the screen shouting, because if everything shouts she stops hearing any of it, and because she is often reading it with the student's parent sitting beside her. First three seconds: I know where to start. After sixty seconds: I have a plan and I can defend it.
- **Parent: reassurance, honestly given.** They should feel informed rather than managed, and they should feel that a competent adult is paying attention to their child. Never chirpy, never corporate, never a progress bar standing in for an answer. Where the news is not good, the interface must be able to say so without frightening them. First three seconds: my child is fine, or my child is being looked after. After sixty seconds: I know what happens next and who to ask.
- **Student: momentum, and being taken seriously.** A Grade 12 mid-application is under real pressure and knows when they are being condescended to. The permitted gamification has to read as progress they earned, not as a reward loop aimed at a child. Warmth here is allowed to be more overt than anywhere else in the product. First three seconds: I am further along than I felt. After sixty seconds: I know the next concrete thing to do.

**Tone under gravity is the hard problem, and I want it solved rather than avoided.** How does a screen tell a counselor that a fifteen-year-old is falling, with the evidence, in a way that is neither clinical to the point of callousness nor emotionally decorated? Colour, weight, spacing and copy all take a position on this whether you choose one or not. A red badge on a child's name is a design decision about a child. Show me you have thought about it. The safeguarding escalation in particular is a real, consequential, logged act, and the moment of committing to it should feel weighty in the interface rather than looking like any other button.

## 5. Each surface must feel built for the person using it

A different mood per audience is not enough. The test is recognition: a counselor should look at her console and think *someone who has sat in a counseling office built this*, and a student should look at theirs and think *this was built for me, not handed down to me from the adults' version*. The failure I am naming in advance is one dashboard, relabeled three times, with a different accent colour per role. That is what usually happens and I will recognise it immediately.

Recognition comes from the interface reflecting the person's actual working life:

- **Their vocabulary, used correctly and without translation.** A counselor says caseload, tier, referral, check-in, escalation, evidence. A student says my subjects, my choices, deadline, offer, personal statement. A parent says my child, the cost, who do I speak to. Each surface should read as though written by someone fluent in that vocabulary, not as one set of labels softened for two of the three.
- **The objects they already handle.** The counselor's world is people-in-a-queue, so her primitive is probably a row about a person. The student's world is a decision with a deadline attached, so their primitive is probably a step or a choice. The parent's world is a child and a small number of facts about them, so their primitive is probably a single subject. Get the primitive right per surface and the rest follows. Get it wrong and no amount of tone fixes it.
- **The shape of their session.** The counselor arrives in the morning and comes back in two-minute bursts between meetings, so her surface must be resumable and must answer "what changed" instantly. The parent opens it for sixty seconds in the evening on a phone. The student sits with it. These three facts should be visible in the layouts without anyone explaining them.
- **Their relationship to the information.** The counselor is accountable for it and needs to defend it. The parent is the subject of it and did not ask to become an expert. The student is being measured by it. The same fact carries different weight in each case and should not be presented identically in all three.

**Each version must state its role-differentiation policy explicitly**, as a short list: what stays constant across all three surfaces, so that this remains one product with one maker, and what is allowed to change per surface, so that each feels bespoke. Be specific about which levers you are using and how far: density, type scale, colour temperature, amount of motion, navigation shape, copy voice, the primitive unit of content. A policy of "same system, different accent colour" is a non-answer and I will read it as one.

Two limits on the divergence:

- **One product, not three.** A parent who sees their child's counselor's screen over a desk should recognise it as the same thing they use at home. The seam between the surfaces should look deliberate rather than like two teams who did not talk.
- **The three views of one student must stay reconcilable.** A counselor, a parent and a student looking at the same fact must be able to have a conversation about it. The presentation differs, the fact does not, and no surface may imply something the other two contradict.

I will judge this by putting one counselor screen, one student screen and one parent screen side by side. Show me that comparison yourself, in each version, with a sentence on what makes each unmistakably its own audience's and what nonetheless marks all three as the same product.

## 6. Premium, and where it is allowed to come from

I want this to feel expensive. Not decorated, expensive. The cheap signals of premium are banned in section 9, so here is the vocabulary that is open to you, and I will judge the work on how much of it is actually present:

- **Restraint in the colour count.** A palette that mostly refuses colour, so that the colour which does appear is unmistakably carrying meaning. Expensive things are quiet.
- **Spacing derived rather than chosen.** A rhythm that comes out of the line height and the row, so the vertical measure is consistent across every screen without anyone having to enforce it.
- **Optical correction, visible in the details.** Alignment that is optically right rather than mathematically right. Figures that line up in a column because they are tabular. Punctuation and units set at a weight that does not fight the number.
- **Type doing the hierarchy.** Weight, size, tracking and case, not boxes, not colour, not lines. If you removed every rule and every fill from the screen, the hierarchy should still be legible.
- **The quality of the small things.** The focus ring. The hover state. The 1px rule and whether it is the right 1px. The empty state's sentence. These are where craft is actually perceived, and they are the first things a thin pass skips.
- **Motion as tone, not as feature.** Short, confident, few. Nothing bounces. Nothing announces itself. Speed reads as expensive and easing reads as considered. The one permitted exception is the student completion moment, which is allowed to be generous.
- **Copy that sounds like a competent person wrote it.** Specific verbs, no filler, no exclamation, no reassurance the product cannot back. Premium collapses on bad copy faster than on bad type.

Two counterweights to the references in section 11, because that list is deliberately cold and warmth still has to come from somewhere: think of the care taken in a well-made printed annual report, and the tone of a good doctor who tells you the truth kindly. The warmth in this product comes through craft and language, not through decoration. That distinction is the brief.

## 7. What must not change

Load-bearing. Treat these as physics, not preference.

1. **The five triage tiers are product logic, not decoration.** Urgent, check-in, review, monitor, good, in that order, each with a real SLA state. Never collapse them to three, never re-theme them per school, never reorder them. They are the spine of the whole counselor surface.
2. **Signals are personal, never comparative.** The differentiator is deviation from a student's own historical baseline band, not from a cohort average. Nothing may rank students against each other. A design that implies a leaderboard breaks the product's core claim.
3. **Provenance over authority.** Rules decide, the model writes. Deterministic tables own entry requirements, prerequisites, fee status, tuition, deadlines and reach/match/safety classification. The model only interprets and phrases. Every number a student or parent sees must be traceable to a source on screen. The interface must show its work rather than implying machine omniscience.
4. **The school colour is letterhead, never data.** A school's own colour may brand the chrome. It may never appear inside a severity, track or domain definition, because then the meaning of a colour would change per customer.
5. **A visible "demonstration data" marker stays on every screen showing student records.** The demo is branded as a real school, the American Community School of Abu Dhabi, and every student in it is synthetic. These are fabricated welfare and safeguarding records under a real institution's name, and a screenshot travels. The marker is a shipping requirement. Do not hide it for a cleaner screenshot, and do not let a version's aesthetic argue it away. Designing it to be handsome instead of apologetic is welcome.
6. **WCAG 2.1 AA, and severity is never carried by colour alone.** The five tiers read as a red to green gradient, so each tier needs a second channel: a letter, a mark, a shape, a position. Full keyboard operation including a command palette. Visible focus everywhere. `prefers-reduced-motion` must zero duration *and* delay, because staggered entry animations use a `backwards` fill and a surviving delay leaves content blank.
7. **Parent and student surfaces must hold at 375px.** They are used on phones in practice, not in theory.
8. **Vocabulary that must not drift:** *match* already means reach/match/safety in university data and can never be reused for anything else. IB and AP are academic tracks, not visual themes.

## 8. The current visual system, which Version A must respect

The build today is a deliberate direction I will describe as the Register: the product as the pastoral mark book the school already keeps. Ruled paper rather than dashboard. Its actual tokens:

- **Palette:** a stock of `#FAFBF7`, banded rows in `#DCE8DA` and `#CFDECC`, rules in `#C4D3C2` and `#AFC3AE`, ink at `#131D26` with three lighter grades, a margin red at `#B0271C`. Tiers: urgent `#A81E12`, check-in `#96490F`, review `#7A6113`, monitor `#4A5A62`, good `#1C6B45`, each with a tinted background. Six domain colours for academic, attendance, engagement, behaviour, teacher sentiment and university. School primary `#004D43`.
- **Type, six named roles, not h1 to h6:** display and headline and label in Archivo Narrow, title and body in Libre Franklin, figure in Spline Sans Mono. Body sits at 12.5px, figures at 17px monospace with tight tracking. The narrow display face against the wide body face is the system's signature.
- **Shape:** radii of 1 to 3px. Effectively square. No soft cards, no floating panels, no shadows doing the work a rule should do.
- **Density:** a 30px row, a 60px topbar, spacing of 6, 9, 14 and 22px.

**This section binds Version A only.** Versions B and C may discard every token, every typeface and the metaphor itself. Section 7 binds all three, because it is product logic rather than visual preference, and so does the ban below.

The ban: no serif typefaces, and no cream-and-serif rendition of the ledger idea, in any version. That is the obvious rendition of the metaphor, it reads as a wedding invitation rather than a working document, and it has already been ruled out once.

## 9. The ban list

Not in any of the three versions:

- Purple-to-blue SaaS gradients, or any gradient doing the job of hierarchy.
- Glassmorphism, frosted panels, blur as decoration.
- Large rounded cards floating on a grey field. This is the default shape of every competitor and it is exactly what I am trying not to look like.
- A row of four identical KPI tiles showing numbers nobody acts on. Attention is the scarce resource here. A number that does not change what the counselor does next does not belong on screen.
- Emoji used as icons, or stock illustration of any kind.
- "Welcome back, Sarah 👋" and every copy move in that family.
- A centred 56px hero headline. This is a working tool, not a landing page.
- Any layout that only survives with three items in a list that in practice holds eighty.

And the current generation of defaults, which are harder to see because they are tasteful. These are banned as a set, not individually:

- Inter, Geist, or any neutral grotesk used everywhere because it is safe.
- A grey ramp lifted from a utility framework, slate-50 through slate-900 and its relatives.
- One icon set at 1.5px stroke, rounded caps, applied uniformly with no thought about weight against the type.
- Pill-shaped badges, 999px radius, as the answer to every piece of status.
- Bento grids, and the general habit of making tiles different sizes to create interest that the content does not have.
- A left sidebar of icon-plus-label rows, and an IA of Overview / Analytics / Settings.
- Sparklines used as texture rather than because someone reads the trend.
- Everything on an 8px grid because 8 is a nice number, rather than because the row height was derived from the line height of the type.

If your first instinct on a decision is one of these, that is the signal to work harder on that decision, not to find a near neighbour of it.

Also banned, without exception: fabricating testimonials, customers, outcomes, benchmarks, pricing, press, or any real person's data. The school publishes its own university acceptance statistics and they are the school's claims, not the product's. Do not restate them as CAROS outcomes anywhere in the interface.

## 10. Critique first, and be specific

Before you design anything, give me a numbered critique of the current interface as it stands in the screenshots. For each finding: what is wrong, what it costs the user, and how confident you are. Rank by damage done, not by ease of fixing.

State the three that hurt most bluntly, including anything suggesting the information architecture is wrong rather than the styling. If the counselor's morning question, what changed overnight, is not answerable in the first three seconds of the caseload screen, that is a finding and I want it named as one.

Do not proceed to the designs until the critique is written out.

## 11. Altitude, and what I mean by good

Reference points, for calibration only. I am not asking you to imitate any of them, and pastiche of them is its own failure:

- **Tools that respect an expert's time:** Linear, the Bloomberg terminal, a flight ops board, an anaesthetist's monitor. Dense, unapologetic, legible under pressure, no hand-holding.
- **Information design that survives being printed:** the Economist and the FT data pages, a Swiss railway timetable, a hospital chart, an audit ledger. Hierarchy from type and rule alone, almost no colour, colour meaning something when it appears.
- **Things that are clearly one product and not a template:** the work has a position on how a figure is set, what a row is, and where the eye goes first, and that position holds on every screen.

The failure I am trying to avoid is not ugliness. It is the competent, neutral, slightly rounded product interface that looks like it was assembled from a component library by someone with no opinion about what the product is for. That output is easy to produce and I can get it anywhere. It reads as machine-made, and a counselor being asked to change the tool she uses every morning will read it as such.

**One signature move per version.** Each direction must contain a single decision specific enough that I could describe it to someone over the phone and they would understand what the product looks like. A way of drawing the tier that nobody else draws. A structural idea about what a row is. A type decision that carries the whole system. Name it explicitly, under the heading "the signature move", and say what it costs. A version without one is not a direction, it is a theme.

**Permission to be divisive, and where it applies.** Version C should be a position, not a consensus. I would rather see something I reject outright than something I shrug at, so do not pre-moderate it toward what you think I will accept. That permission is aesthetic and structural only. It does not extend to section 7, which is product logic and safety, and a version that is bold by breaking one of those is not bold, it is unusable.

## 12. Three directions, deliberately far apart

Three complete, internally coherent directions. They must differ on a real axis, not on accent colour.

- **Version A, the Register refined.** Keep the thesis and the tokens in section 8 and make them right. This is the version I could ship as an increment next week. Fix the density inconsistency, make the six type roles actually carry hierarchy, resolve what the six domain colours are doing against the five tier colours, and make the marker in section 4 point 5 look deliberate. Evolution, executed to a higher standard than the current build.
- **Version B, a changed metaphor.** Drop the ledger. Propose a different governing metaphor for what this product is, argue it in two sentences, and build the whole system from it. The test of a good answer here is that the metaphor tells you what to do on a screen I did not send you. Do not pick the metaphor because it is easy to render.
- **Version C, the ambitious one.** The version that would get talked about. Treat the counselor's information density as a feature rather than a problem to be hidden behind progressive disclosure: she is an expert user doing triage, and hiding information from her costs her the decision. Commit fully. This should be the version you would defend in a portfolio, not a hedged middle.

Rules for all three:
- Each version opens with a written thesis in two sentences. Every decision inside it must be traceable to that thesis. If a choice does not follow from the thesis, cut it.
- No version may be a tinted copy of another. **If I could get from A to C with a find-and-replace on hex values, you have failed the brief.**
- Each version must name what it is deliberately bad at. Every direction trades something away.

## 13. What each version must contain

1. **Thesis**, two sentences, plus the trade it makes.
1b. **The feeling**, one paragraph: what a counselor, a parent and a student each feel in this version, how the version produces that, and specifically how it holds its tone on the worst screen in the product, the one showing a child in difficulty.
1c. **The role-differentiation policy** required by section 5: what holds constant across the three surfaces, what changes, which levers and how far, plus the three-screen side-by-side comparison.
2. **A design system as real tokens:** the full colour ramp with the reasoning behind it, the five tier colours and their non-colour second channel, the six domain colours and how they coexist with the tiers, a type scale with named roles rather than h1 to h6, a spacing scale, radii, border and rule treatment, elevation rules, motion durations and easings. Give hex values and CSS custom properties, not adjectives.
3. **Typography with a point of view.** Name the typefaces and say why. Remember the offline constraint: either embed, or choose faces with a system fallback stack that genuinely holds. System-font-only is an acceptable answer if you argue it.
4. **The named rules of the system.** The four or five sentences a new person would need to build a screen I did not send you and have it fit. For example: how density is decided, when colour is allowed to mean something, what is never allowed a border, how a figure is set against its label.
5. **Working code**, standalone HTML per version, vanilla JS and CSS only, no build step, opens from a double-click. One file per version containing all eight screens below, navigable, so I can open the three files side by side. Screens in priority order:
   1. Counselor caseload, 87 students, triaged, the morning view. This is the screen the product lives or dies on.
   2. Counselor priority cases, the overnight tier movements.
   3. Counselor case detail, the 360 student file: signals against personal baseline, the evidence chain, intervention history.
   4. Counselor signal explanation, how a signal was derived and what fed it.
   5. Student pathway, the IB against AP decision, with the milestone and XP mechanic designed properly.
   6. Student progress.
   7. Parent overview.
   8. Parent messages to the counselor.

   **Nominate one of the eight as that version's hero screen and build it at obsessive fidelity**, down to how a single row behaves on hover, how a figure is set against its label, what happens at the point the list stops fitting. Eight screens at even, medium fidelity is the shape of work nobody remembers. I would rather have one screen that proves the system and seven that are consistent with it.
6. **Responsive behaviour down to 375px** for the student and parent screens, with the reflow described rather than assumed. The counselor console may assume a laptop.
7. **States:** loading, empty, error, first-run, and the dense worst case. The empty state must explain *why* it is empty: a Grade 9 family's near-empty portal is correct, not broken, and if it does not say so the family stops opening it.
8. **Motion**, named, with durations and easings, honouring the full-rebuild constraint, with a `prefers-reduced-motion` path that zeroes duration and delay both. Say what each piece of motion is for emotionally, not just what it does. Motion is most of how an interface feels, and it is the part most often specified as a number and left to mean nothing.
9. **Accessibility:** contrast ratios stated as numbers, focus visible throughout, full keyboard operation, no meaning carried by colour alone.
10. **Copy.** Rewrite the interface text: labels, empty states, errors, button verbs, the tier names if you can do better. Bad copy reads as bad design. No em dashes anywhere in the copy.

## 14. Real content only

Use real data shapes, real labels, and real volume. No lorem ipsum, no "Card title", no three-item list standing in for a list that holds eighty. Show the crowded case, because that is the one that breaks. Every student, family and record you write is synthetic demonstration content and must read as plausible without naming any real person.

## 15. How to give it to me

In this order:
1. The critique.
2. One paragraph on each of the three directions, so I can read the shape of all three before any detail.
3. Each version in full, one at a time.
4. A closing comparison: what each wins at, what it costs, which one you would ship and why. Take a position. Include which one you would want looking at your own child's record, and say why, because that is the question underneath this whole product.

Before you send any of it, run one pass over your own output and answer in writing: **which three decisions in here are the most generic?** The ones you made because they are what is usually done rather than because this product needs them. Name them, say what the safe choice was, and either replace it with a specific one or state plainly why the safe choice is correct here. Include that pass in what you send me, after the critique. It is the part I will read most carefully, because a designer who cannot find the weak decisions in their own work has not finished looking.

Then stop. I will pick a direction or ask for a hybrid, and we will iterate from there. Do not start refining before I choose.

## 16. Quality bar

I am showing this to a counselor at the American Community School of Abu Dhabi, who is piloting the product. The question she will ask is: **would I actually use this every morning instead of what I have now?** She has four colleagues splitting the high school between them, she works in bursts between meetings, and her current alternative is the incumbent system schools complain about plus her own notebook. Design so the answer is obvious from the screen rather than from an explanation I have to give over it.

Aim for work distinctive enough to be recognisable without the logo. If a version could belong to any other product in this category, it is not finished.

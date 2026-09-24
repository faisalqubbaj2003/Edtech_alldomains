# Questions for ACS

Everything the backend plan has to assume because we do not know it yet. Take this into the ACS meeting. Planning passes add to it as they go (pass 8 merges their questions in under these headings, marked with the pass they came from).

Each question says who at the school is most likely to answer it. Answers change the plan, so write them down here and date them.

**What we already know** (from Davide, 2026-09-22): ACS runs **Veracross** as its SIS, **ManageBac** for the IB Diploma, **Maia Learning** for university work, and **Google Workspace** with **Google Classroom**. Everything else below is open.

---

## 1. Systems and data · IT, registrar

### Veracross
1. Can you export grades, attendance and behaviour from Veracross as a file? Which reports, and how often could you run them?
2. Do grades come out per assessment, or only as term grades? Per-assessment data is what lets CAROS notice a change within weeks rather than at the end of a term.
2a. Could the school run a **weekly** export (per-assessment grades and per-lesson attendance), ideally scheduled rather than by hand? This is what CAROS needs to work as designed. With termly data only, it still runs, but grades and attendance signals arrive a term late. (Added 2026-09-23 after pass 2.)
3. Does attendance come out per lesson or per day, and does it include lateness and the **reason** for an absence (authorised, medical, school trip)?
4. Where are behaviour incidents recorded: in Veracross, or somewhere else?
5. Can you export the timetable and class lists (which teacher teaches which student in which class)? This decides what each teacher can see in CAROS, so it has to be right.
6. Can you export parent and guardian contacts with their relationship to each student, including families with more than one child at the school?
7. Would ACS consider giving CAROS read-only access to the Veracross API later? Who approves that?

### ManageBac
8. What do you use ManageBac for today: CAS, the Extended Essay, subject selection, all of them?
9. Would you want CAROS to read from ManageBac so nobody enters things twice, or to take over some of that work, or neither?
10. Does ManageBac hold anything about subject choices for Grade 10 students, or does that still happen on paper as Mr. Diaz described?

### Maia Learning
11. What do counselors and students do in Maia today: university lists, applications, sending transcripts, recommendation letters, career exploration?
12. What would make you stop using a feature in Maia in favour of CAROS, and what would never move?
13. Can data come out of Maia (export or API), for example a student's university list, so CAROS does not ask students to keep a second one?

### Google Classroom and anything else
14. Is Google Classroom used across the high school, and would the school be comfortable with CAROS reading assignment activity as an engagement signal?
15. What other systems hold student information we should know about: a wellbeing or survey tool, a separate behaviour system, a safeguarding system (such as CPOMS or MyConcern), a learning support register?
16. Are there exam periods, reporting windows and term dates we can get as a calendar each year?

---

## 2. Identity and accounts · IT

17. Which Google Workspace domain or domains do staff and students use?
18. Do all Grade 9 to 12 students have Google accounts they sign into regularly?
19. What is your process for approving a third-party app that uses Google sign-in, and how long does it usually take?
20. When staff or students leave, how are their Google accounts removed? CAROS should follow the same thing automatically.
21. Are parents' email addresses in Veracross reliable enough to send them a sign-in link?
22. Alumni mentors are not school account holders. Is there an existing process for vetting adults who have contact with students (for example alumni or volunteers)?

---

## 3. Safeguarding · Lead Child Protection Officer, HS Principal

23. When a counselor escalates a concern today, who receives it, how, and how quickly are they expected to respond?
24. Who should receive CAROS escalations: the Lead Child Protection Officer only, or also the HS Principal, and who covers when they are away?
25. What may an escalation email contain? Our default is that it contains no detail about the student's welfare, only a secure link and who raised it.
26. Do you already use a safeguarding system? If so, should CAROS escalations go into it rather than to email?
27. If a student writes something worrying in a CAROS chat or a personal statement (a disclosure of harm, for example), how should that reach a human, and who?
28. What do you consider staff-only? For example: counselor notes, teacher concerns, the student's priority. Our default is that students and parents never see any of these.

---

## 4. Data protection, hosting and legal · Data protection lead, leadership, legal

29. Does ADEK require student data to be stored inside the UAE? We are planning to do that from day one either way, but we want to know the exact requirement.
30. Does ACS have its own data processing agreement template for suppliers, and who signs it?
31. Who is ACS's data protection lead?
32. How does ACS handle consent for student data: at enrolment, per system, or not at all? Does anything need parents' explicit consent?
33. How long does ACS keep student welfare and counseling records after a student leaves, and does ADEK set a minimum?
34. How do you handle a parent asking for everything the school holds on their child?
35. The AI features (for example a counselor's assistant, or a student's pathway conversation) send some information to an AI model. Is it acceptable for that processing to happen outside the UAE if names are removed first, or is that ruled out? Is there anything that must never go to an AI model at all?
36. What will your IT security review ask us for: a questionnaire, a penetration test, a certification such as ISO 27001 or SOC 2?

---

## 5. For the counselors · the HS counseling team

These shape the signal engine. The plan is to ask them before the engine is configured, so it reflects what they already know matters.

37. When you look at a student and think "I need to see them this week", what are you usually reacting to?
38. Which changes worry you most: grades, attendance, lateness, behaviour, something a teacher mentions, going quiet on university applications?
39. How big a drop is "a change" for a strong student versus a student who already struggles?
40. How long does something have to persist before it is worth your time?
41. How many new names each morning would feel useful, and how many would you start to ignore?
42. When is a signal expected and not worrying: exam weeks, the start of term, Ramadan, after a known family event?
43. How is the caseload split between the four HS counselors, and what happens when one of you is away?
44. Would you be willing to run CAROS in "shadow mode" for a few weeks, where it records who it would have flagged without showing you, so we can compare its judgement against yours?

---

## 6. The pilot · leadership, counseling team

45. Which counselor, and which year groups, would pilot it first?
46. Would ACS provide pseudonymised historical exports (names removed) so we can check whether the engine would have noticed students you actually supported, earlier than you did? This needs a signed data processing agreement first.
47. What would the counselor, the Child Protection Officer and IT each need to see before they are comfortable using it with real students?
48. What would make leadership consider the pilot a success?

---

## 7. Our own outstanding item

49. **Written consent to use the ACS name and crest in the demo.** The demonstration currently shows synthetic student welfare records under ACS's name. We need their written permission for that, or we switch the demo to the unbranded school. This is a liability until it is resolved.

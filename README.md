CAROS — Counselor OS
The Student Career Operating System. An AI-native platform that helps school counseling teams notice which students need support before they ask for it, automates the administrative weight of the university application cycle, and gives every stakeholder in a student's journey — the counselor, the family, the teacher, the mentor — exactly the view they need and nothing they don't.
This repository contains a single, self-contained, fully interactive prototype: index.html. No build step, no backend, no dependencies. Open it in a browser and the whole platform runs.

Quick start
Option 1 — just open it. Download index.html and double-click it. It works completely offline.
Option 2 — run it locally with a server (recommended for testing on mobile devices on the same network):
bash
python3 -m http.server 8000
Then visit http://localhost:8000/index.html.
Option 3 — the live demo: [add your Vercel URL here once deployed]

What's inside
The prototype has five role-based experiences, switchable from the top navigation bar:

Role	What it does
Counselor OS	The core product. A command centre that triages a caseload by urgency, a signal-intelligence engine that detects meaningful change against each student's own baseline (not a cohort average), 360° student files, a recommendation letter engine, an AI co-pilot for plain-language queries across the caseload, and a reporting layer that proves outcomes to leadership.
Parent portal	Transcripts and predicted grades, exactly which courses each target university requires (with multiple valid paths shown side by side), a plain-language IB vs AP explainer backed by real alumni outcomes, estimated cost of attendance per university, live offer and conditional-offer tracking, and a direct line to the counselor — including a meeting-request flow that assembles a full context brief automatically, so the counselor never starts a conversation cold.
Student portal	A probability-weighted pathway view, university targets, a mentor marketplace connecting students to verified alumni, and a progress view that adapts its grading display to whichever system the student is actually on — IB's 1–7 scale, AP's per-exam scoring, or neither yet, for students still deciding.
Teacher portal	A lightweight way to flag a concern or leave a comment about a student straight after a lesson — the fastest, earliest signal a school has, routed directly into the counselor's intelligence layer.
Mentor portal	Session requests and mentee tracking for verified alumni mentors, wrapped in a safeguarded, in-platform-only contact model.

The grade-aware demo
Every student in the system is genuinely different — not a relabeled copy of one student. The Parent and Student portals include a family switcher at the top of the screen that moves between four real, independent students and their real families:
Grade 9 — orientation stage, no path chosen yet
Grade 10 — actively deciding between IB and AP
Grade 11 — AP track, building a record, with an optional early-start mode for students who want a head start on applications before senior year
Grade 12 — full IB Diploma, mid-application-cycle, the flagship experience
Each family has its own name, attendance record, subjects, message history with the counselor, and meeting history. Switching grades never just relabels Sara — it loads a different student's real data.

How it's built
Single HTML file. All markup, styles, and logic live in one file. No framework, no build tooling, no package manager.
Vanilla JavaScript, hand-written render functions and a simple draw() loop — no virtual DOM, no reactive framework.
No backend. All data is in-memory, seeded with realistic demo content. Nothing persists between page loads; refreshing resets the demo to its starting state.
Fully responsive. A collapsible off-canvas drawer and bottom tab bar on mobile, a persistent sidebar on desktop, tested from 360px phones up through wide desktop monitors.
Offline-capable. Everything needed to run is embedded in the file — open it with no internet connection and it works identically.
This is a demo-grade architecture by design: it's built to be shown to schools, investors, and design partners quickly and convincingly, not to run a real school's data. A production version would separate this into a real frontend framework talking to a backend with an actual database, authentication, and integrations into a school's SIS/MIS.

Project status
Active prototype, under continuous iteration. Recently added: cost-of-attendance and offer-tracking for parents, an AP exam tracker, grade-9-through-12 differentiated experiences, and an early-preparation option for motivated Grade 11 students.

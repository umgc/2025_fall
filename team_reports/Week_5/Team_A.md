# CareConnect — Team A  
**Weekly Narrative Report (Milestone 3 – Week 5)**  
**Period:** Sept 11–17, 2025  
**Prepared by:** Project Lead – Sadina Phan-Wagner

---

## 1) Summary of Work Completed
- Stabilized dev branch and confirmed local builds across Team A.
- Finalized M2 handoff (TDD/STP updates + demo slides) and kicked off M3 decomposition.
- Scoped **Calendar Assistant** MVP (assigned: Mitchell) and UI/UX task breakdown (owner: Mickey).
- API design reviews + architecture alignment (owner: Matt).  
- QA expanded STP sections and RTM links; spun up Postman collections (owner: Lidia).

> _Note:_ Tevin did not submit a narrative this week.

**Merged to `main`:**
- M2 slide/Doc refinements and TDD/STP errata (Docs PRs).  
- Dev environment scripts and README tweaks (Tooling PRs).

**In feature branches (pending PRs):**
- Calendar Assistant backend scaffolding (API branch).  
- UI/UX wireframes & components (UI branch).  
- QA Postman collections and RTM updates (QA branch).

---

## 2) Milestones & Deliverables
- **Milestone 3:** On track.  
  - Backend endpoints: design complete; implementation underway.  
  - UI scaffolding: in progress.  
  - QA artifacts (STP sections & RTM): in progress.

---

## 3) Metrics Snapshot - none

---

## 4) Issues / Blockers
- Awaiting cross-team endpoint exposure for integration testing.  
- UI/UX → ensure no overlap with shared components.  
- Dev branch rebase/cleanup timing may briefly gate QA runs.

---

## 5) Next Week’s Plan
- Backend: Implement Calendar Assistant core endpoints _(create/read/update reminders, notifications)_ **[Issues: #CA-API-1, #CA-API-2]**  
- Frontend: Build Calendar views & reminder workflow **[Issues: #CA-UI-1, #CA-UI-2]**  
- QA: Expand STP §8.12.4.4/.5, link RTM, run Postman smoke suite **[Issues: #QA-STP-3, #QA-POST-1]**  
- Docs: Update TDD diagrams & Programmer’s Guide snippets **[Issues: #DOC-TDD-2]**

---

## 6) Cross-Team Coordination
- **Team B/C/D:** Need new/updated endpoints surfaced for Calendar Assistant integration testing.  
- **Design Sync:** Coordinate with **Yara** on shared UI components to avoid overlap.  
- **Ops:** Confirm Deployment & Ops guide steps for QA environment parity.

---

## Individual Notes 

**Mitchell Lord (BA/Scheduler)**
- Reassigned tasks per team feedback; added M3 items to Team A schedule.  
- Calendar Assistant owner; dev branch working locally.  
- Next: ramp on codebase post-rebase; begin Calendar Assistant MVP.

**Mickey Maloney (UI/UX Lead)**
- Edited/added to TDD/STP; created M2 slide content.  
- Further decomposed UI/UX tasks from initial plan; dev branch running.  
- Next: implement UI for Team A features; sync with backend owners & Yara.

**Matthew Pingel (Lead Architect)**
- Delivered TDD/STP contributions (new API endpoints, architecture diagrams, data models, test suites).  
- Supported local env setup; covered M2 TDD technical presentation; helped generate M3 tasking.  
- Next: guide API implementation & code reviews for Calendar Assistant.

**Lidia Rocha (QA/Test Lead)**
- Completed local Android/Flutter setup; validated QA env & repo hygiene.  
- Drafted STP sections; expanded RTM; created QA folder/defect log.  
- In progress: STP test design/suites, RTM links, Postman collections; schedule QA checkpoints.

**Tevin (DevOps Lead)**
- _No narrative submitted this week._

# CareConnect – Team A
**Weekly Narrative Report (Milestone 2 – Week 4)**
**Prepared by:** Team A (Lead: Sadina Phan-Wagner)

---

## 1. Summary of Work Completed
- Features/issues closed with GitHub references.
- Highlighted what was merged into `main` vs. still in feature branches.
- Individual narratives below (note: **Alex and Tevin did not submit narratives for this week**).

---

### Matthew
- Performed research for viability of USPS Informed Delivery integration.
- Performed research for viability of AI Voice Diarization implementation.
- Performed research for viability of Medical Notetaker implementation.
- Created estimate reports and PPT slides for all the above for 9/6 checking presentation.
- Completed [Issue #50](https://github.com/umgc/2025_fall/issues/50) for TDD M2 deliverable.
- Completed [Issue #51](https://github.com/umgc/2025_fall/issues/51) for TDD M2 deliverable.
- Added Team A’s contributions to Section 6 of the TDD.
- Ensured all TDD sections contained necessary information for Mail Delivered Assistant, AI Voice Diarization, and Medical Notetaker.
- Worked with teammates to design new data structures necessary for requirements.

---

### Sadina (Project Lead)
**Executive Summary:**
As Project Lead, aligned **SRS, PMP, and TDD deliverables**, integrated QA governance into **STP v2.0**, and ensured **traceability and UAT coverage**. Testing covers authentication, dashboards, billing, gamification, telehealth assistants, and Mail Delivered Assistant, with focus on compliance and accessibility.

**Business Need Statement:**
Team A features include **CareConnect Telemedicine, Medical Visit Notetaker, Calendar Assistant, and USPS Mail Delivered Assistant**, supporting accessibility, compliance, and caregiver awareness.

**Technical Design:**
Key decisions included **ASL integration, secure transcript storage, calendar and mail assistant implementation, and security measures** (encryption, RBAC, consent prompts).

**QA & Test Plan:**
STP v2.0 covered **RTM mapping, device/browser testing, accessibility, and key test cases** for Team A features.

**Project Management:**
Ensured **RACI updates, timely milestone delivery, risk management, and tracked hours** for each Team A feature.

---

### Mitchell
**Summary of Work Completed:**
- Created slides for M2 presentation.
- Researched Reminder and Calendar BNS.
- Completed first draft of Reminder and Calendar estimate.
- Reassigned tasks from team feedback (including Alondra).
- Participated in Team Lead Syncs.
- Worked on weekly report submission.
- Progressed on majority of TDD and STP assigned sections; aiming to finalize by Thursday deadline.

**Milestones & Deliverables:**
- M2 Estimates are on track.
- Completing TDD and STP after M2 presentation prep.

**Next Week’s Plan:**
- Work on development environment setup and begin coding prep for M3.

---

### Mickey
- Attempted to get local build working; app emulated on Android Studio phone but backend issues persisted.
- Utilized Alondra’s backend documentation to troubleshoot blockers.
- Reviewed and edited slides for M2 presentation.
- Drafted outline for Saturday’s presentation and delivered.
- Began reviewing/editing TDD sections; added screenshots and content for Business Needs.
- Started STP review and edits; planning submission by Thursday.

**Next Week’s Plan:**
- Retry local build with updated backend steps.
- Research best UI implementation approaches for new features.
- Begin coding contributions.

---

### Lidia (QA Lead) – Week 4 Contributions
**Calendar Assistant Estimate:**
- Reviewed estimate for alignment with **SRS v5.0 and PMP v4.0**.
- Updated introduction with **accessibility considerations** (large text, high contrast, multilingual support) and caregiver confirmations for AI-generated events.
- Expanded **effort & cost estimates**: added frontend accessibility refinements, backend compliance services, testing, and DevOps tasks.
- Added assumptions and risks for **HIPAA/GDPR compliance**.
- Aligned rollout with Milestones 2–3.

**Milestone 2 Presentation:**
- Created **QA & Testing Approach** slide with process flow diagram (SRS → RTM → STP → Test Cases → Defect Log → Verified Features).
- Designed **QA Risks & Mitigation** slide with risk–solution mapping.
- Integrated QA perspective into presentation content.
- Simplified technical language for clarity and professionalism.

**RTM Verification & QA Deliverables:**
- Verified RTM links between **SRS v5.1 and TDD sections**.
- Added sample entries, flagged gaps/issues (e.g., REQ-5.8.2.3.7 missing in SRS).
- Drafted QA KPIs/Metrics (coverage, defect density, test execution rate).
- Added sample defect log and change log entries.

**TDD Contributions:**
- Drafted Section 12: Testing Strategy.
- Completed Section 5.4: Health Data Tracking.
- Rewrote Section 6.1: Key Design Principles.
- Performed final QA review of TDD.

**SRS Contributions:**
- Drafted Telemedicine/Notetaker functional requirements (FR-DIA-1 through FR-DIA-5).
- Ensured privacy compliance (editable transcripts only, no continuous storage).

**Team Meetings & Collaboration:**
- Participated in Mail/Calendar/Notetaker integration discussions.
- Evaluated workload distribution and feasibility.
- Offered QA perspective in BNS reviews.
- Cross-team discussions on AWS setup and QA/DevOps alignment.

**STP Drafting (In Progress):**
- Drafted Introduction, Testing Environment/Tools, Assumptions & Constraints.
- Started Test Suites (Authentication, Billing, AI features).
- Drafted Glossary for Appendix.
- Conclusions & Suggested Actions pending.

---

### Alex
**No narrative submitted for this week.**

### Tevin
**No narrative submitted for this week.**

---

## 2. Milestones & Deliverables
- Milestone 2 deliverables (**TDD v3.0, STP v2.0**) are on track for professor/client submission.
- Presentation slides prepared and delivered.
- Next checkpoint: prepare for **Milestone 3 – Code & Deployment Guides**.

---

## 3. Metrics Snapshot
- GitHub Issues Closed: #50, #51 (Matthew), Reminder/Calendar estimate draft (Mitchell).
- GitHub PRs merged: Feature branch updates from QA and TDD edits (in progress).
- Earned Value (EV) vs. Planned Value (PV): **On track with baseline PMP schedule**.

---

## 4. Issues / Blockers
- Local build and backend configuration caused delays (Mickey, Dev side).
- Dependencies on Team B/C/D for endpoint exposure and API schemas.
- Missing individual narratives from **Alex and Tevin** (risk for peer grading transparency).

---

## 5. Next Week’s Plan
- Finalize TDD and STP submissions.
- Begin development environment stabilization for Milestone 3.
- Implement password reset workflow (GitHub Issue #32).
- Write API integration tests (GitHub Issue #28).

---

## 6. Cross-Team Coordination
- Need Team B to expose endpoints for integration testing.
- Need Team C’s database schema updates for testing.
- Coordinate with Team D on audit logging compliance.

---

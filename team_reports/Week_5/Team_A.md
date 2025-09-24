# Weekly Narrative Report – Team A 
**Milestone 3, Week 6** 
_Assignee: Sadina Wagner (Project Lead)_ 

---

## 1. Summary of Work Completed 

### Sadina (Project Lead) 
**Week 5–6 Contributions** 
- Led planning and coordination for Demo 1 deliverables. 
- Removed Node/Express demo (out-of-scope per stack requirements) and moved all demo proof-of-concept work into a **standalone Spring Boot module** under `careconnect2025/backend/demo-slice/`. 
- Implemented demo controllers: 
  - `/health` → service status 
  - `/notes` → add/query notes (in-memory) 
  - `/triggers/propose` → keyword-detection generating follow-up event proposals 
- Verified functionality using `curl`; captured proofs into `/careconnect2025/proofs/Sadina/`:
  - `health.json`, `notes_add.json`, `notes_list_query.json`, `notes_unauthorized.txt`, `trigger_proposal.json`. 
- Created **frontend ASL stubs** under `frontend/lib/features/asl/`:
  - `asl_demo_screen.dart` 
  - `asl_service.dart` (mock render pipeline). 
- Authored and updated documentation in `/careconnect2025/docs/`:
  - `README_runbook.md` (run instructions) 
  - `ARCH_env.md` (environment setup) 
  - `SEC_auth_domains.md`, `SEC_session_policy.md`, `SEC_rbac.md`, `SEC_piiconsent.md` 
  - `TDR.md` (technical decision rationale) 
  - `UX_asl_prototype.md` 
- Configured Java 17 + Maven environment in Codespaces. Ensured repeatable builds using `mvnw` and demo-slice isolated profile. 
- Coordinated feature alignment with Team A, ensuring **no changes leaked into `team_a/core`** until team consensus. 
- Drafted narrative/status updates for weekly report and ensured GitHub Projects board issues tied to deliverables. 

---

### Other Team Members (Week 6 snapshot)

**Mitchell Lord** 
- Completed initial Calendar Assistant (CRUD tasks, UI, recurring task support, filtering). 
- Delivered versioned endpoint `v2/task` for CareConnect backend. 
- Reported Milestone deliverable “Calendar Assistant ready for Demo” (without notifications). 

**Mickey Maloney** 
- Configured Notetaker settings page with patient/caregiver role views. 
- Added backend integration for saving/pulling settings. 
- Began implementation of voice sample recording (mobile only). 
- Raised PR for Notetaker demo integration. 

**Matthew Pingel** 
- Supported multiple teammates with backend setup/troubleshooting. 
- Implemented backend for Notetaker configuration screen (merged into Team A). 
- Began coding ingestion pipeline (note processing, keyword detection, event generation). 
- Reviewed and advised on multiple PRs. 
- Provided scope/progress updates to leadership. 

**Tevin** 
- ⚠️ Did not submit Week 6 narrative. 

---

## 2. Milestones & Deliverables 

- **Milestone 3 (Demo 1):** On track 
  - Calendar Assistant v1 (delivered by Mitchell). 
  - Notetaker config + ingestion pipeline (delivered by Mickey & Matthew). 
  - ASL stubs + Proof-of-concept endpoints (delivered by phans09). 
- All deliverables demo-ready; full integration pending. 
- Team remains slightly staggered (not all narratives submitted), but overall milestone target met. 

---

## 3. Metrics Snapshot 

- **Commits (Week 5–6):** ~40+ commits pushed to `SadinaTeamA`. 
- **PRs:** 
  - PR #382 (Auth/RBAC, PII sanitize, ASL prototype, docs) — closed as out-of-scope (Node/Express removed). 
  - Multiple commits added directly to `SadinaTeamA` branch for demo-slice and docs. 
- **Proofs Generated:** 5 JSON/TXT outputs captured under `/proofs/Sadina`. 
- **Docs Authored/Updated:** 7 major files. 

---

## 4. Issues / Blockers 

- Stack alignment: Node/Express prototype had to be abandoned; reimplemented as Spring Boot demo-slice. 
- Port conflicts (Tomcat already bound to `:8000`) required process cleanup (`fuser -k 8000/tcp`). 
- Proof files initially empty due to server misconfig (fixed by running Spring with Java 17). 
- Tevin did not provide Week 6 narrative, limiting visibility into task completion. 

---

## 5. Next Week’s Plan 

- **Sadina**: 
  - Port `/notes` and `/triggers/propose` endpoints into `careconnect/backend/core/src/main/java/com/careconnect/controller`, wired into existing `AuthController`. 
  - Finalize documentation for Demo 1 handoff. 
  - Sync with Team A to merge demo-slice proofs into core deliverables where appropriate. 

- **Team A overall**: 
  - Calendar Assistant: integrate notifications. 
  - Notetaker: finalize voice-to-text with diarization. 
  - ASL pipeline: prepare early prototype for UI integration. 

---

## 6. Cross-Team Coordination 

- Will need **Team B** support for Calendar integration testing (notifications/events). 
- Will need **Team C** confirmation on database schema stability before porting demo endpoints to core. 
- QA coordination required to validate Postman collections and regression test suites across teams. 

---

## Week 6 Timesheet (phasn09) 

- Verified Java 17 + Maven environment setup; resolved mismatches with Codespaces defaults. 
- Built/runs `demo-slice` Spring Boot app (`mvn spring-boot:run`). 
- Generated curl-based proofs for health/notes/triggers endpoints. 
- Authored runbook and environment setup docs. 
- Added ASL frontend stubs (Flutter/Dart). 
- Updated STP test sections 8.12.4.4 & 8.12.4.5 with QA test cases, suites, and checklist. 
- Expanded RTM sheet with requirement/test case links. 
- Created Postman collection + GitHub Action YAML draft for Newman CI integration. 
- Attended weekly syncs, prepared Team A slides, and drafted this narrative report. 

---

✅ **Status:** Milestone 3 deliverables met. Demo endpoints, proofs, ASL stubs, and documentation completed. On track for Demo 1. 
⚠️ Note: Tevin did not provide Week 6 narrative. 

---

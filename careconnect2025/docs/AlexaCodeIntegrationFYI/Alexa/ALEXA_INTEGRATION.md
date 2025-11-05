# 🗣️ Alexa Integration Feature for CareConnect

## 1. Introduction: Why This Exists
The **Alexa Integration** is the first big step toward bringing **smart-home technology** into the CareConnect platform. CareConnect is designed to help caregivers provide the best possible care to patients by making daily life safer and simpler — especially for patients who may have difficulty managing tasks independently.

The idea behind integrating Alexa is simple: **make CareConnect accessible without even picking up a phone**. Through Alexa, a patient can say:

> “Hey Alexa, ask CareConnect what’s on my schedule this week,”  
> or  
> “Hey Alexa, tell CareConnect to add a doctor’s appointment for tomorrow.”

That one sentence travels from their voice, through Amazon’s systems, into our app, and back — like magic.

The long-term vision is to keep expanding beyond Alexa listening devices like echo, eventually connecting CareConnect to other Alexa enabled smart-home devices like **lightbulbs, thermostats, and speakers** to further enhance independence and comfort. Eventually, the Google Action equivalent should be configured as well. But this document focuses on **Phase 1** — linking Alexa to the CareConnect account and enabling calendar interactions.

Right now, the Alexa integration supports:
- ✅ **Account Linking** between Alexa and CareConnect  
- 🗓️ **Calendar Integration** — reading the week’s tasks and adding new ones  
*(currently limited to Patient accounts only)*

---

## 2. How It Works (System Flow)

### 🧩 High-Level Overview
The Alexa feature connects Amazon’s Alexa ecosystem with the CareConnect backend through a secure account-linking and token-exchange process.  

At a glance:

Patient→ CareConnect Frontend (Smart Devices Page)→ Alexa App
→ Amazon Skill Authorization Flow (see below for flow breakdown)
→ Alexa App Skill Confirmation → Done

Once linked, the flow for voice commands: 

User speaks → Alexa Skill → CareConnect Backend (Alexa Controller)
→ Database → Alexa Skill → Spoken Response

Amazon Skill Authorization Flow: 
Your Web Authorization URI* (Configured in Developer Console)
→ User types in Credentials 
→ CareConnect Backend (EnhancedAuth Controller provides JWT)
→ Your Web Authorization URI* 
→ CareConnect Backend (AuthController exchanges JWT for Authorization Code) 
→ Your Web Authorization URI* 
→ Alexa Redirect URLs (configured by Amazon, viewed in Console)
→ Access Token URI (Configured in Developer Console should also be a Careconnect Backend API Call)
→ Database
→ Alexa App Skill Confirmation


### 🌐 System Context

The connection relies on three major components:
1. **Alexa Developer Console Skill**  
   - Configured with Account Linking using OAuth 2.0  
   - Points to CareConnect’s frontend and backend URLs for authorization and token exchange
   - Code points to CareConnect's backend for Alexa Controller that handles voice-activated requests  

2. **CareConnect Backend (Spring Boot)**  
   - Hosts two special endpoints for Alexa account linking:
     - `/sso/alexa/code` → Exchanges a JWT for an authorization code  
     - `/sso/alexa/token` → Exchanges authorization or refresh tokens for new JWTs  
   - Also handles all Alexa-related attributes in the Patient entity (e.g., `alexaLinked`, `refreshToken`)
    - Hosts two special endpoints for Alexa request handling:
      -  `v1/api/alexa/calendarTasks/get`  → Read Calendar Tasks within the last week
      -  `v1/api/alexa/calendarTasks/add`  → Creates a new Calendar Task

3. **CareConnect Frontend (Flutter)**  
   - Hosts the “**Smart Devices**” page under the main menu  
   - Allows users to enable or disable Alexa integration  
   - Shows whether the Alexa account is currently linked
   - Hosts the “**Alexa Login**” page (should only be used when Amazon Amplify is running in Production and should match Your Web Authorization URI* in the Developer Console -> Build -> Account Linking)
        NOTE: In the past for local testing I have configured a GitHub page to test functionality and link accounts during development. Here is the link to that page: 
              [text](https://isabel-santiagolewis.github.io/MockAuthFrontend/MockLogin.html)

        You can use this page or you can copy the code from it and host it on your own git hub by copying the code located here: 
            [text](https://github.com/isabel-santiagolewis/MockAuthFrontend)

### 🧭 Flow Summary

#### Account Linking (Step-by-Step)
1. **User opens** the **Smart-Devices** page in CareConnect.  
   - For patients, the Alexa column is active; for caregivers, it’s greyed out (future work).  
2. **Page checks** the `alexaLinked` Boolean in the patient entity.  
   - Displays “Alexa is not linked yet” or “Your Alexa Account is linked!”  
3. **User clicks “Enable Alexa.”**  
   - Opens the Alexa Skill Enablement link.  
   - During Beta, this points to the **Beta Tester Link** (since the skill isn’t published yet).  
4. **User enables the skill** in the **Alexa App (iPhone required)**.  
   - Android app currently needs further looking into (does not foward users to the Web Authorization URI?). Windows Alexa app do not currently support developer skills.  
        NOTE: In case this changes in the future here is the link to install the Windows Alexa App as it was a little hard to find (cannot search it in the App Store?)
            [text](https://apps.microsoft.com/store/detail/alexa/9N12Z3CCTCNZ?hl=en-us&gl=us&rtc=1)
5. **Alexa navigates to the Authorization URI** (configured in the Alexa Developer Console).  
   - This triggers CareConnect’s login page (`alexaLogin.dart`) or a GitHub mock login page for local testing.  
6. **User logs in**, gets a valid JWT token from the backend, triggering the backend `/sso/alexa/code` API to exchange the JWT for a short-lived authorization code (expires in 2 minutes).  
7. **Frontend redirects** the authorization code back to Alexa using parameters (`redirect_uri`, `state`) provided in the URL.  
8. **Alexa exchanges** the code for a valid JWT by calling `/sso/alexa/token`.  
9. **Backend sets** `alexaLinked = true`, stores a hashed refresh token, and sends the JWT token and refresh token to Alexa.  
10. **Alexa reports success**, and CareConnect’s frontend updates the status to “Linked.”

#### Regular Voice Commands
1. User activates the skill via voice:  
   > “Alexa, ask CareConnect to add a new medicine.”  
2. Alexa routes the request to the CareConnect backend endpoint defined in the skill’s Code currently (there may be a better way to handle this by instead using Lambda/HTTPS configurations.)  
3. Backend handles the intent (e.g., Add Task or Get Tasks).  
4. Backend queries or updates the database.  
5. Alexa responds to the user with confirmation or the requested data.

---

## 3. Setting Up Your Development Environment

### 🧰 What You’ll Need
Before testing or modifying the Alexa integration, make sure you have:

| Tool / Service | Purpose |
|----------------|----------|
| **Amazon Developer Console** | To access the Alexa Skill configuration (Account Linking, endpoints, Beta tester list). |
| **Public Backend Endpoint** | Alexa cannot reach `localhost`. Use **ngrok** or a hosted backend (e.g., AWS Lambda). |
| **Public Frontend Endpoint** | For the Web Authorization login page (hosted Amplify link or temporary GitHub page). |
| **Java Backend (Spring Boot)** | Must be running locally or hosted. |
| **Frontend (Flutter)** | Needed for Smart-Devices page and Alexa login flow. |
| **Valid Beta Tester Account** | Only Beta testers can enable the unpublished skill (up to 500 testers) with a valid Amazon email. |
| **Amazon Alexa App (iPhone)** | Used to enable the skill and complete account linking. Android currently fails during the linking step. 
        NOTE: The smart-devices page is configured to take users to the Amazon Skill 
        Enablement Page. Here is the link if you just want to link your account without worrying about the formal user flow: 

        [text](https://skills-store.amazon.com/deeplink/tvt/1cc43d50136bee48a3039cf55775ec0a64a967d5685df997fae9a2fe719a20a7d8e108ed6f4d7bfedb9ce283ddbdf81ed9f6289f17e311266b534cbb311f0bf69ee09a1c8d5d376364359852b0ba8ba7edecc29327df49ac547b52edb016973e1c7b73c96251be9c74dc48e68ba321e6)

        This is the Beta Testing URL and must be lanched from an iPhone.

|

---

### ⚙️ Development Tips

- When testing locally, use **ngrok** to expose your backend:  
  ```bash
  ngrok http 8080

  Then update all backend references in:
        Alexa Developer Console → Account Linking → Access Token URI
        Alexa Developer Console → Skill Code

        MockLogin Page (if using github dummy login page)

            NOTE: If you’re using a GitHub mock login page, make sure your GitHub domain is added to the list of allowed CORS origins in WebSecurityConfig.

            Example: search for "https://isabel-santiagolewis.github.io" in the code and add your own URL wherever you see mine added.

    Whenever the backend URL or Amplify domain changes, make sure you are always changing all backend references above.

Don’t forget: each configuration level change in Alexa requires clicking Save and Build in the Developer Console to take effect. Each code change requires saving and redeploying to take effect.

NOTE: If your Account is already linked and you change the backend token Access Token URI* you should disable  (to unlink) and reenable (to link again) because linked users will keep the old value of the URI until it is relinked. If it is using the old value it will fail to refresh their JWT token and unlink your accounts. 

Common Setup Pitfalls
Issue --> Cause --> Fix

CORS errors when testing via GitHub page 
    --> Missing GitHub domain in backend CORS config	
        --> Add your GitHub origin to WebSecurityConfig

Beta tester link not working	
    --> Tester’s email not added or not using same Amazon account	
        --> Add correct email under in Developer Console under Distribution →   Availability → Beta Testers

AlexaLogin page not recognizing redirect parameters	
    --> Skill not sending state and redirect_uri correctly	
        --> Use console logs on AlexaLogin page to verify parameters

Changes not taking effect	
    --> Skill not rebuilt after configuration edits	
        --> Save → Build → Re-enable the Skill

Skill still showing “Linked” after unlinking	
    --> JWT not immediately invalidated	
        --> Currently unlink only resets alexaLinked; consider adding JWT blacklisting in future

## 4. Account Linking Deep Dive

### 🔐 Overview
Account linking is what allows Alexa to “know” which CareConnect user is speaking.  
It uses an **OAuth 2.0-style** handshake between the Alexa skill and CareConnect’s authentication system to exchange secure tokens.  

In plain terms:  
> The user logs into CareConnect once → Alexa gets temporary permission to act on their behalf using a valid CareConnect JWT.

Once linked, Alexa can call protected backend APIs (like getting or adding calendar tasks) without the user having to log in again.

---

### 🔁 The Flow (Expanded)
1. **User clicks “Enable Alexa.”**  
   From the Smart-Devices page, the button opens the skill’s Beta-tester enablement URL.  

2. **Alexa App launches** and sends the user to the **Authorization URI** configured in the Developer Console → *Build → Account Linking*.  
   - This URI points to CareConnect’s frontend login page (`alexaLogin.dart`) when running in production.  
   - During local testing, a GitHub-hosted mock login page can be used instead.  

3. **User enters credentials.**  
   The frontend calls the backend’s enhanced auth service and receives a regular JWT.  

4. **Frontend trades the JWT for a short-lived Authorization Code**  
   by calling the backend endpoint `/sso/alexa/code`.  
   - The code expires after **2 minutes**.  
   - The backend stores a mapping of the JWT → code via the `AlexaCodeStoreService`.

5. **Frontend redirects back to Alexa** with that authorization code, using the `redirect_uri` and `state` parameters that Alexa originally sent.

6. **Alexa calls `/sso/alexa/token`** to exchange the authorization code for tokens.  
   - When `grant_type=authorization_code` → backend validates the code, issues a new JWT and creates a **refresh token** (valid 30 days).  
   - When `grant_type=refresh_token` → backend finds the patient with the matching refresh token, verifies expiration, and issues a new JWT + refresh token pair.  

7. **Backend updates the patient record**  
   - Sets `alexaLinked = true`  
   - Saves the hashed refresh token in the database  

8. **Alexa reports success.**  
   The CareConnect Smart-Devices page will now display “Your Alexa Account is linked!”

---

### 🧠 Data Exchange Summary

| Stage | Alexa Sends | CareConnect Returns | Purpose |
|-------|--------------|--------------------|----------|
| **Authorization URI** | `redirect_uri`, `state` | Auth code | Begin OAuth flow |
| **/sso/alexa/token (authorization_code)** | Auth code | JWT + refresh token | Establish link |
| **/sso/alexa/token (refresh_token)** | Refresh token | New JWT + New refresh token | Maintain link |

---

### 🧩 Backend Components
| File / Class | Responsibility |
|---------------|----------------|
| **`AuthController.java`** | Hosts `/sso/alexa/code` and `/sso/alexa/token` endpoints |
| **`AlexaCodeStoreService.java`** | Generates, stores, and validates temporary auth codes and refreshTokens |
| **`PatientEntity.java`** | Holds `alexaLinked` flag and hashed refresh token |
| **`WebSecurityConfig.java`** | Controls allowed CORS origins (add GitHub/AWS Amplify here) |

---

### ⚙️ Database Attributes Involved
- `alexaLinked` → Boolean (flag showing if account is linked)  
- `refreshToken` → Hashed string, expires after 30 days  
- `jwtExpiration` → Timestamp for current JWT  

---

### 🧭 Local vs Production Testing
| Mode | Authorization URI | Notes |
|-------|------------------|-------|
| **Local** | GitHub MockLogin page | Must whitelist GitHub origin in CORS |
| **Production** | Amplify `alexaLogin.dart` page | Uses public Amplify URL; recommended once deployed |

---

### ⚠️ Gotchas
- Auth codes expire fast — if login takes longer than 2 min, linking fails.  
- Alexa requires HTTPS endpoints — use ngrok locally for public backend in development.  
- Android Alexa App currently doesn’t redirect to the web auth page.  
- If you change the **Access Token URI** after linking, you must unlink and relink or Alexa will keep the old URI.  

---

### 🧩 Flow Diagram
sequenceDiagram
  participant Alexa
  participant Frontend
  participant Backend
  participant DB

  Alexa->>Frontend: Open Authorization URI
  Frontend->>Backend: /login → JWT
  Backend-->>Frontend: JWT
  Frontend->>Backend: /sso/alexa/code
  Backend-->>Frontend: Auth Code
  Frontend->>Alexa: Redirect with Auth Code
  Alexa->>Backend: /sso/alexa/token
  Backend->>DB: Save Refresh Token & set alexaLinked = true
  Backend-->>Alexa: JWT + Refresh Token

5. Alexa Intents & Command Behavior
🎯 Current Skill Intents (Phase 1)

Right now the CareConnect Alexa Skill supports the Calendar Feature only.
Each intent corresponds to an endpoint in the backend’s AlexaController.

## 5. Alexa Intents & Command Behavior

### 🧠 Overview
Each intent defined in the Alexa Developer Console maps directly to backend endpoints in the **AlexaController.java** class.  
The Alexa Skill communicates via HTTPS (using the `ask-sdk-core` library) to the CareConnect backend, authenticating each request with the CareConnect **JWT token** obtained during account linking.

Current skill version supports **two primary intents**:  
- `ReadCalendarTasksIntent` — Retrieves all calendar tasks for the upcoming week.  
- `AddCalendarTaskIntent` — Adds a new task with rich dialog slot filling (type, date, time, recurrence, etc.).  

All API calls use the following base URL during development:  
`https://<ngrok-or-lambda-endpoint>/v1/api/alexa/...`
and include the header:
```http
Authorization: Bearer <JWT>

🗓️ 1️⃣ ReadCalendarTasksIntent

Purpose
Fetches all CareConnect calendar tasks (for the next week) for the currently linked patient account and reads them aloud.

Alexa Model Mapping
Component --> Definition
Intent Name --> ReadCalendarTasksIntent
Sample Utterances --> “What’s on my calendar”, “What do I have scheduled”, “Read my calendar”, “List my tasks”
Slots (think of these like variables) --> None
Backend Endpoint --> GET /v1/api/alexa/calendarTasks/get
Auth --> Bearer JWT in header
Filter Parameter --> limits results to the next 7 days

Backend Flow

1. Alexa sends HTTPS GET request with the JWT.
2. Backend validates token with JwtTokenProvider.
3. resolvePatientIdFromToken() retrieves patient ID via UserRepository and PatientRepository.
4. TaskServiceV2.getTasksByPatient(patientId) returns all tasks.
5. Controller filters to the next 7 days.
6. Response is sent as JSON array of TaskDtoV2 objects.

Example Response
[
  {
    "name": "Doctor Appointment - Annual Checkup",
    "description": "Primary care visit",
    "date": "2025-11-04T00:00:00",
    "timeOfDay": "14:00",
    "taskType": "appointment",
    "completed": false
  },
  {
    "name": "Medication reminder for today",
    "date": "2025-11-02T00:00:00",
    "taskType": "medication"
  }
]

Alexa Output Example

“You have two tasks coming up — Doctor Appointment – Annual Checkup, and Medication reminder for today.”

➕ 2️⃣ AddCalendarTaskIntent
Purpose
Creates a new task in the CareConnect calendar based on user voice input.

Alexa Model Mapping
Component --> Definition
Intent Name --> AddCalendarTaskIntent
Sample Utterances --> “Add a {taskType} for {taskDate} at {taskTime}”, “Remind me to {taskDescription}”, “Schedule a {taskType}”, “Create a repeating {taskType}”
Dialog Management --> Delegation strategy: SKILL_RESPONSE (the skill code elicits slots manually)
Backend Endpoint --> POST /v1/api/alexa/calendarTasks/add
Auth --> Bearer JWT in header
Payload --> JSON body built from slot values

Slot-to-Backend Mapping
Slot Name --> Alexa Type --> Backend Field --> Example --> Notes
taskType → TaskType → taskType → “appointment”, “exercise”, “medication” → Determines category
taskDate → AMAZON.DATE → date → “2025-11-03” → ISO date validated in controller
taskTime → AMAZON.TIME → timeOfDay → “14:00” → Optional
taskDescription → AMAZON.SearchQuery → description → “annual checkup” → Free-form notes
reminderTime → ReminderTime → reminderMinutes → “15” → Mapped by formatReminderMinutes()
isRecurring → YesNoType → isRecurring → “yes” → Controls recurrence
recurrenceType → RecurrenceType → frequency → “weekly” → Optional
recurrenceDays → AMAZON.SearchQuery → daysOfWeek → “Monday, Wednesday, Friday” → Parsed via parseRecurrenceDays()
endDate → AMAZON.DATE → endDate → “2025-12-31” → Optional stop date

Backend Flow
1. Alexa Skill collects slot data interactively using prompts (e.g., “What day works for you?”, “Should this repeat?”).
2. When dialog = COMPLETED, Alexa Skill builds a JSON payload:

{
  "name": "Appointment at 2 PM",
  "description": "Doctor visit",
  "date": "2025-11-03",
  "timeOfDay": "14:00",
  "taskType": "appointment",
  "frequency": "weekly",
  "daysOfWeek": [1,3,5],
  "reminderMinutes": 30
}

3. Backend authenticates JWT, resolves patientId.
4. Controller normalizes data via normalizeAlexaTaskData().
5. TaskServiceV2.createTask(patientId, taskDto) persists it.
6. Backend returns HTTP 201 Created + TaskDtoV2.
7. Alexa Skill confirms with natural speech:

“Perfect! I’ve got your appointment scheduled for Monday at 2 PM, repeating weekly. I’ll remind you thirty minutes before. All set!”

🔁 Validation & Error Handling
Invalid Token → HTTP 401 → Alexa says “Please link your CareConnect account first.”
Missing Required Fields → HTTP 400 → Alexa says “Hmm, I couldn’t add that task, could you try again?”
Forbidden (Caregiver mismatch) → Unlinks Alexa via unlinkAlexaAccount() to prevent stale connections.
Server Error → HTTP 500 with details logged on backend.

🧩 Example End-to-End Flow
sequenceDiagram
  participant User
  participant AlexaSkill
  participant Backend
  participant DB

  User->>AlexaSkill: “Hey Alexa, ask CareConnect to add a doctor appointment for tomorrow at 2 PM”
  AlexaSkill->>Backend: POST /calendarTasks/add (JWT + JSON body)
  Backend->>Backend: Validate token → resolve patient → normalize DTO
  Backend->>DB: Save new task (TaskServiceV2.createTask)
  DB-->>Backend: TaskDtoV2
  Backend-->>AlexaSkill: 201 Created + TaskDtoV2
  AlexaSkill-->>User: “Perfect! Appointment scheduled for tomorrow at 2 PM.”

💡 Developer Notes
The Alexa skill code (index.js) currently hard-codes API_BASE; update it whenever backend deployment changes.
Both endpoints are protected by JWT auth — test using a linked account only.

| Intent                    | Purpose                  | Endpoint                  | Auth  | Returns           |
| ------------------------- | ------------------------ | ------------------------- | ----- | ----------------- |
| `ReadCalendarTasksIntent` | Reads week’s tasks       | `GET /calendarTasks/get`  | ✅ JWT | List of TaskDtoV2 |
| `AddCalendarTaskIntent`   | Adds new task via dialog | `POST /calendarTasks/add` | ✅ JWT | Created TaskDtoV2 |

## 6. Testing & Debugging the Alexa Integration

### 🧪 Overview
Before testing, confirm that:
- The **Lambda / Developer Console code** is deployed and enabled in **Test mode**.  
- The **backend** is running and reachable via **ngrok** or a hosted URL.  
- The **Alexa account** is linked through the CareConnect Smart-Devices page.  

Each scenario below validates a different part of the voice → backend → database loop.

---

### ✅ Functional Test Cases

---

#### **TC-ALX-01 — One-Time Medication**
**Voice Input:**  
> “Alexa, ask CareConnect to schedule a medication.”

**Expected Result:**  
Prompts for date and time → user says “No” to repeat →  
creates single medication task, asks for reminder & notes, confirms with reminder time.

---

#### **TC-ALX-02 — Daily Medication (No Reminder)**
**Voice Input:**  
> “Alexa, schedule a medication.”

**Expected Result:**  
Repeats daily with no reminderMinutes field; confirmation omits reminder line.

---

#### **TC-ALX-03 — Weekly Exercise (Custom Reminder)**
**Voice Input:**  
> “Alexa, create an exercise task.”  
User says weekly on Mon/Wed/Fri → “30 minutes before.”

**Expected Result:**  
TaskType = exercise, daysOfWeek = [1, 3, 5], reminderMinutes = 30.  
Confirmation mentions weekly recurrence and custom reminder.

---

#### **TC-ALX-04 — Auto-Detect Exercise (Bike Ride)**
**Voice Input:**  
> “Alexa, schedule bike ride Saturday 9 AM.”

**Expected Result:**  
Alexa maps *bike ride → exercise*; confirmation says “workout.”

---

#### **TC-ALX-05 — Auto-Detect General (Lunch)**
**Voice Input:**  
> “Alexa, schedule lunch for 12 PM daily.”

**Expected Result:**  
Alexa maps *lunch → general*; frequency = daily; optional reminder = 10 min;  
confirmation says “task.”

---

#### **TC-ALX-06 — Auto-Detect Lab (Blood Work)**
**Voice Input:**  
> “Alexa, schedule blood work Friday 8 AM.”

**Expected Result:**  
Alexa maps *blood work → lab*; one-time task; confirmation says “lab appointment.”

---

#### **TC-ALX-07 — One-Shot Appointment**
**Voice Input:**  
> “Alexa, schedule an appointment for tomorrow at 3 PM.”

**Expected Result:**  
Parses date/time; asks for reminder & notes; confirmation includes both.

---

#### **TC-ALX-08 — Pharmacy Pickup**
**Voice Input:**  
> “Alexa, schedule a pharmacy pickup for 3 PM.”

**Expected Result:**  
TaskType = pharmacy; no recurrence; confirmation says “pharmacy stop.”

---

#### **TC-ALX-09 — General Weekdays Recurrence**
**Voice Input:**  
> “Alexa, add a general task for 10 AM weekdays.”

**Expected Result:**  
daysOfWeek = [1-5]; no reminder; confirmation says “repeating weekly.”

---

#### **TC-ALX-10 — Read Tasks (Multiple)**
**Voice Input:**  
> “Alexa, ask CareConnect what’s on my calendar.”

**Expected Result:**  
Lists up to 5 upcoming tasks with friendly summary:  
> “You have 9 tasks coming up…”

---

#### **TC-ALX-11 — Read Tasks (Empty Calendar)**
**Voice Input:**  
> “Alexa, what tasks do I have?” *(no tasks exist)*

**Expected Result:**  
Responds:  
> “You’re all caught up with no scheduled tasks.”

---

#### **TC-ALX-12 — Read Tasks (Not Linked)**
**Voice Input:**  
> “Alexa, show me my tasks.” *(without linked account)*

**Expected Result:**  
Responds:  
> “It looks like your CareConnect account isn’t linked yet.”  
Displays Link Account card.

---

### 🧰 Debugging Tips

**Alexa says “Account linked” but API calls fail**  
→ Token expired or backend URI changed  
→ Unlink + relink to refresh tokens.

---

**Skill skips reminder question**  
→ Dialog state logic bug in `AddCalendarTaskIntentHandler`  
→ Verify `dialogState !== 'COMPLETED'` branch executes.

---

**Wrong task type detected**  
→ Missing synonym in interaction model  
→ Add synonym under `TaskType` → rebuild model.

---

**Tasks not saving to DB**  
→ Backend JWT invalid or endpoint URL wrong  
→ Check ngrok URL in Developer Console (Account Linking + Skill Code).

---

**“Linked” status stuck after unlinking**  
→ `alexaLinked` flag cached in frontend  
→ Reload Smart-Devices page → force API refresh.
---

### 📊 Success Criteria
- All seven dialog questions asked in order (date → time → recurrence → frequency → days → reminder → description).  
- Synonym resolution works (“bike ride” → exercise, “blood work” → lab, etc.).  
- Confirmation phrasing is natural and contextual.  
- Backend JSON matches intent and slots exactly.  
- Tasks visible in CareConnect Calendar GUI.
---

## 7. 🚀 Future Improvements

---

### 🔐 Alexa Voice Linking for Extra Security
**Description:**  
Add a layer of voice authentication so only verified users (e.g., the patient) can access CareConnect data.  
This prevents anyone else in the household from asking Alexa for private information.

---

### 🗣️ Google Actions Support
**Description:**  
Create a Google Assistant version of the Alexa Skill using the same CareConnect backend.  
This allows patients or caregivers with Google devices to use identical commands across platforms.

---

### 🏠 Smart-Home Integration Expansion
**Description:**  
Extend Alexa integration beyond Echo devices to other Alexa-enabled products—smart displays, light bulbs, speakers, etc.  
Use reminders and notifications that trigger lights, sounds, or visual alerts for medication and appointments.

---

### 👥 Caregiver Authentication Plan
**Description:**  
Define how caregivers will authenticate and manage linked patient accounts through Alexa.  
Decide whether caregivers have limited commands (“check patient schedule”) or full access, and update token logic to reflect that.

---

## 8. 🧾 Author Notes & Handoff

---

### 🧪 Current Skill Status: **Beta Mode**
The CareConnect Alexa Skill is currently published under **Beta Testing** in the Amazon Developer Console.  
It **should remain in Beta** until the CareConnect application itself is ready for public release.

**Reasoning:**
- Amazon reviewers must be able to fully test the skill.  
- If our backend or frontend isn’t publicly hosted, the review will fail automatically.  
- Beta mode allows internal testing with up to **500 testers** using private invite links.

---

### 🔐 Privacy Policy Requirement
The current Privacy Policy is a **temporary placeholder** generated online.  
Before public release, CareConnect must have a **proper Privacy Policy** that clearly defines:

1. What user data is collected (e.g., patient name, task info, reminder times).  
2. How that data is stored, protected, and shared.  
3. Who can access it (e.g., caregivers vs. patients).  
4. How users can revoke consent or delete their data.  

Until this is written and approved, **do not submit the skill for production review** to avoid compliance or legal issues.

---

### 🧭 Handoff Notes
This project was a major learning curve — Alexa integration touches so many systems at once.  
Hopefully, this document makes it easier for whoever picks it up next to understand how it all fits together.  

All Alexa-related **source code**, **interaction model JSON**, and **configuration screenshots** can be found in the  
📁 **`/references`** folder.  

If you have trouble getting the Alexa integration set up or linked, reach out! I’m glad to help troubleshoot or explain how the current implementation works

Here is my personal email address: isabel.santiagolewis@gmail.com

---


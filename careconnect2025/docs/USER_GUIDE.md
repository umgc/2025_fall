# Fall CareConnect 2025 User Guide

University of Maryland Global Campus  
SWEN 670 – Software Engineering Capstone  
Dr. Mir Assadullah  
November 4, 2025

---

## Document Control

### Revision History

| Date       | Version | Description      | Author           |
|------------|---------|------------------|------------------|
| 11/04/2025 | 1.0     | Initial release  | CareConnect Team |

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Account Setup and Registration](#account-setup-and-registration)
4. [Dashboard Overview](#dashboard-overview)
5. [Patient Features](#patient-features)
6. [Caregiver Features](#caregiver-features)
7. [Family Member Features](#family-member-features)
8. [Communication and Social Features](#communication-and-social-features)
9. [Health Monitoring and Analytics](#health-monitoring-and-analytics)
10. [AI and Voice Commands](#ai-and-voice-commands)
11. [Video Calling and Telehealth](#video-calling-and-telehealth)
12. [Task Management](#task-management)
13. [Notetaking](#notetaking)
14. [Gamification and Achievements](#gamification-and-achievements)
15. [Payment and Subscriptions](#payment-and-subscriptions)
16. [File Management](#file-management)
17. [Device Integration](#device-integration)
18. [Notifications and Alerts](#notifications-and-alerts)
19. [Emergency Features](#emergency-features)
20. [Electronic Visit Verification](#electronic-visit-verification)
21. [Invoice Assistant](#invoice-assistant)
22. [Privacy and Security](#privacy-and-security)
23. [Troubleshooting](#troubleshooting)
24. [Support and Contact](#support-and-contact)

## Introduction

Welcome to CareConnect 2025, a comprehensive healthcare management platform designed to connect patients, caregivers, and family members in a seamless digital healthcare ecosystem. Our application provides real-time communication, health monitoring, task management, and AI-powered assistance to enhance care coordination and improve health outcomes.

### What is CareConnect?

CareConnect is a multi-platform healthcare application that bridges the gap between patients, professional caregivers, and family members. The platform offers:

- **Real-time Communication**: Video calls, messaging, and notifications
- **Health Monitoring**: Vital signs tracking, mood logging, and analytics
- **AI Integration**: Voice commands, chat assistance, and smart recommendations
- **Task Management**: Care plan coordination and progress tracking
- **Device Integration**: Wearables, smart home devices, and medical equipment
- **Emergency Response**: SOS features and escalation protocols

### Supported Platforms

CareConnect is available on:
- **Web browsers** (Chrome, Firefox, Safari, Edge)
- **Mobile devices** (iOS and Android)
- **Desktop applications** (Windows, macOS, Linux)

## 1. Introduction

### 1.1 Purpose
The Fall CareConnect 2025 User Guide offers in-depth instructions for every capability available in the CareConnect ecosystem—from initial onboarding through advanced clinical documentation, electronic visit verification, and invoice automation. The guide blends narrative explanations with procedural steps so that patients, caregivers, administrators, and support staff can confidently navigate the latest feature set documented in SRS v5.3, TDD v4.1, PMP v4.2, and STP v2.1.

### 1.2 Intended Audience
- **Patients and care recipients** who use CareConnect to monitor health, review schedules, and stay connected to their support network.
- **Professional and family caregivers** responsible for executing care plans, documenting visits, and responding to safety events.
- **Clinical administrators and coordinators** who manage billing, EVV compliance, staffing, and analytics.
- **IT support specialists and developers** who maintain integrations, troubleshoot issues, and roll out configuration changes.

### 1.3 Project Documents
Table 1 lists the controlling project documents. Each provides deeper background for topics summarized in this guide.

| Document                     | Version | Date       | Description                                      |
|------------------------------|---------|------------|--------------------------------------------------|
| Project Plan                 | 4.2     | 11/04/2025 | Project charter, scope, milestones               |
| Software Requirements Specification | 5.3 | 11/04/2025 | Functional and non-functional requirements       |
| Technical Design Document    | 4.1     | 11/04/2025 | Architecture diagrams and component designs      |
| Software Test Plan           | 2.1     | 11/04/2025 | Test strategy, test cases, acceptance criteria    |
| Programmer's Guide           | 1.0     | 11/04/2025 | Code structure, development standards             |
| Deployment & Operations Guide| 1.0     | 11/04/2025 | Release process, infrastructure management        |
| User Guide                   | 1.0     | 11/04/2025 | Platform instructions for end users               |

### 1.4 Acronyms, Terms, and Definitions
- **AI** – Artificial Intelligence
- **ASR** – Automatic Speech Recognition
- **EDI** – Electronic Data Interchange
- **EVV** – Electronic Visit Verification
- **HIPAA** – Health Insurance Portability and Accountability Act
- **MFA** – Multi-Factor Authentication
- **OCR** – Optical Character Recognition
- **SOS** – Emergency distress signal
- **USPS** – United States Postal Service

---

**Web Browser:**
- Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- Stable internet connection
- Microphone and camera (for video calls)

**Mobile Devices:**
- iOS 13+ or Android 7.0+
- 3GB RAM minimum, 4GB recommended
- Camera and microphone permissions
- Location services (optional)

**Desktop:**
- Windows 10+, macOS 10.15+, Ubuntu 18.04+
- 4GB RAM minimum, 8GB recommended
- Camera and microphone (for video calls)

### Accessing CareConnect

1. **Web Access**: Navigate to your CareConnect URL provided by your organization
2. **Mobile App**: Download from App Store (iOS) or Google Play Store (Android)
3. **Desktop App**: Download from your organization's software portal

## Account Setup and Registration

### Creating Your Account

CareConnect supports three types of user accounts:

#### Patient Registration

1. **Initial Setup**:
   - Click "Register as Patient"
   - Enter personal information (name, email, phone)
   - Create a secure password
   - Verify email address

2. **Medical Information**:
   - Complete health profile
   - Add emergency contacts
   - List current medications
   - Document allergies and medical conditions
   - Upload insurance information

3. **Privacy Settings**:
   - Set data sharing preferences
   - Configure notification settings
   - Choose communication preferences

#### Caregiver Registration

1. **Professional Details**:
   - Enter professional credentials
   - Upload certifications and licenses
   - Specify areas of expertise
   - Set availability schedule

2. **Background Verification**:
   - Complete background check process
   - Provide professional references
   - Upload required documentation

3. **Service Settings**:
   - Define service areas
   - Set hourly rates (if applicable)
   - Configure notification preferences

#### Family Member Registration

1. **Invitation Process**:
   - Receive invitation from patient or primary caregiver
   - Click invitation link
   - Complete basic information

2. **Relationship Setup**:
   - Specify relationship to patient
   - Set permission levels
   - Configure notification preferences

3. **Privacy Settings**:
   - Choose data access levels
   - Set communication boundaries

### Account Verification

After registration, complete these verification steps:

1. **Email Verification**: Click the link sent to your email
2. **Phone Verification**: Enter the SMS code sent to your phone
3. **Identity Verification**: Upload ID documents (for caregivers)
4. **Professional Verification**: Upload licenses (for professional caregivers)

## Dashboard Overview

The CareConnect dashboard is your central hub for all activities and information.

### Patient Dashboard

**Main Sections:**
- **Health Overview**: Recent vitals, mood scores, medication reminders
- **Care Team**: Connected caregivers and family members
- **Upcoming Appointments**: Scheduled calls and visits
- **Tasks**: Daily care tasks and health goals
- **Messages**: Recent communications
- **Emergency Button**: Quick access to SOS features

**Quick Actions:**
- Log health data (vitals, mood, symptoms)
- Start video call with care team
- Send messages or alerts
- View medication schedule
- Access AI assistant

### Caregiver Dashboard

**Main Sections:**
- **Patient Overview**: All assigned patients and their status
- **Today's Schedule**: Appointments, visits, and tasks
- **Alerts and Notifications**: Patient emergencies and updates
- **Analytics**: Patient progress and health trends
- **Communication Hub**: Messages and video calls

**Quick Actions:**
- Review patient status
- Document care notes
- Schedule appointments
- Send updates to family
- Generate reports

### Family Member Dashboard

**Main Sections:**
- **Patient Status**: Health updates and recent activities
- **Care Team Communication**: Messages with caregivers
- **Health Trends**: Analytics and progress reports
- **Shared Calendar**: Appointments and care schedule
- **Notifications**: Important updates and alerts

## Patient Features

### Health Monitoring

#### Vital Signs Tracking
1. **Manual Entry**:
   - Navigate to "Health Data" → "Vitals"
   - Select measurement type (blood pressure, heart rate, temperature, etc.)
   - Enter values and add notes
   - Save entry with timestamp

2. **Device Integration**:
   - Connect wearable devices (Fitbit, Apple Watch, etc.)
   - Automatic sync of steps, heart rate, sleep data
   - Configure sync frequency and data preferences
   - Alexa Integration configuration to calendar

#### Mood and Wellness Check-ins
1. **Daily Mood Logging**:
   - Rate mood on 1-10 scale
   - Select emotional state indicators
   - Add context notes
   - Track patterns over time

2. **Pain Management**:
   - Log pain levels and locations
   - Track pain triggers and relief methods
   - Monitor medication effectiveness

3. **Symptom Tracking**:
   - Record symptoms and severity
   - Add photos for visual documentation
   - Track symptom patterns
   
4. **Video Check-In**
   - Activated from the Check-In Screen
   - Captures a short video using the user's camera
   - Includes pause functionality
   - Allows for submission and discarding of videos
   - Videos are submitted to an AI service for mood analysis

5. **Virtual Check-In**
   - Patients receive scheduled check-ins configured by their caregivers
   - Each check-in includes simple questions (e.g., pain level, medication taken, mood)
   - Patients can answer directly through the app and submit responses for review

### Medication Management

#### Medication Schedule
1. **Adding Medications**:
   - Go to "Medications" section
   - Click "Add Medication"
   - Enter medication details (name, dosage, frequency)
   - Set reminder times
   - Add special instructions

2. **Taking Medications**:
   - Receive push notifications for medication times
   - Mark medications as taken or missed
   - Add notes about side effects
   - Request refill reminders

#### Medication Adherence
- View adherence statistics
- Share adherence data with care team
- Receive motivational messages
- Track improvements over time

### Symptoms and Allergies Tracker

### Symptom Tracker
1. **Recording Symptoms**:
- Tap Symptoms from the bottom menu
- Select the Mental Health Symptoms tab
- Enter the symptom, for example: Anxiety, Panic Attack, Sleep Problems
- Choose severity level: Mild, Moderate, or Severe
- Add short clinical notes (onset, duration, and triggers)
- (Optional) Tap Use AI Service to record by voice. The app will transcribe your voice and fill in the fields automatically. Review before saving
- Tap Record Symptom to save

2. **After Recording**:
- The new symptom appears under Recent Mental Health Symptoms
- Each card displays the symptom name, time, severity color, and notes
- Severe symptoms show a Caregiver Alert tag and “Requires immediate attention” message
- Entries can be removed using the × button

### Allergy Tracker
1. **Recording Allergies**:
- Tap Symptoms from the bottom menu
- Select the Drug Allergies tab
- Enter the drug or medication name (e.g., Aspirin, Penicillin)
- Describe the reaction (e.g., hives, swelling, shortness of breath)
- Choose severity: Mild, Moderate, or Severe (Life-threatening)
- (Optional) Tap Use AI Service to record by voice. The app transcribes your input and fills in the fields automatically. Review before saving
- Tap Add Drug Allergy to save
  
2. **After Recording**:
- The new allergy appears under Known Drug Allergies
- Each entry displays the medication name, reaction details, and color-coded severity label
- Severe allergies appear in red with a warning icon
- Entries can be removed using the × button

### AI Voice Service
- The AI Voice Service allows users to fill out forms using speech
- Tap Use AI Service to open voice recording
- Speak naturally about your symptom or allergy reaction
- The system converts your voice into text and fills in the related fields
- Review and edit all entries before saving. The AI transcription may not be fully accurate
- The data is only saved when you tap Record Symptom or Add Drug Allergy

### Personal Health Records

#### Medical History
- Upload medical documents
- Scan and store prescriptions
- Add physician notes and reports
- Organize by categories and dates

#### Appointment History
- View past appointments
- Access visit summaries
- Download reports and documents
- Share with new providers

### Emergency Features

#### SOS Functionality
1. **Emergency Button**:
   - Large red button on main dashboard
   - Press and hold for 3 seconds to activate
   - Automatically notifies emergency contacts

2. **Automated Alerts**:
   - GPS location sharing
   - Medical information sharing
   - Emergency contact notification
   - Integration with local emergency services
     
3. **Vial of Life**:
   - Patients can create, update, and share an emergency profile which shows important health information.
   - The profile can be shared through a QR code or link with the patient’s consent.
     
## Caregiver Features

### Patient Management

#### Patient Overview
1. **Patient List**:
   - View all assigned patients
   - See current health status
   - Check recent activities
   - Access patient profiles

2. **Health Monitoring**:
   - Review patient vital signs
   - Monitor medication adherence
   - Track mood and symptoms
   - Analyze health trends

 ### Symptoms Tracker
 1.**Viewing Patient recent Symptoms**:
   - Tap Patients → open the patient profile → Health → Recent Symptoms
   - Entries are sorted newest first
   - Each entry shows the date, symptom name, and severity badge (Mild, Moderate, Severe)
   - “No symptoms reported” appears with a green check icon
   - Color codes: Mild = green, Moderate = orange, Severe = red
   - Caregivers cannot add, edit, or delete symptoms

 ### Allergies Tracker
 1.**Accessing Allergies**:
    - From the Patient Dashboard, tap a patient’s View Details button
    - This opens the Patient Profile screen
    - In the header section (top of the profile), find Allergies displayed below Primary Diagnoses
  2.**Viewing Patient Allergies**:
    - Each allergy appears as a solid red chip with white text, for example: Penicillin, Aspirin
    - The list shows only allergy names with no severity levels or reaction details
    - The section is read-only. Caregivers cannot add, edit, or remove allergies
    - Use this section as a quick reference when reviewing medications or patient history

#### Care Documentation
1. **Clinical Notes**:
   - Document patient interactions
   - Record observations and assessments
   - Add treatment recommendations
   - Include photos and attachments

2. **Care Plans**:
   - Create personalized care plans
   - Set goals and milestones
   - Assign tasks and activities
   - Monitor progress

### Communication Tools

#### Patient Communication
1. **Video Calls**:
   - Schedule and initiate video calls
   - Screen sharing for education
   - Recording capabilities (with consent)
   - Multi-participant calls with family

2. **Messaging**:
   - Send secure messages
   - Share photos and documents
   - Voice message recording
   - Group conversations

3. **Virtual Check-Ins**
    - Caregivers can create and manage virtual check-ins for their assigned patients. 
    - These check-ins allow for regular updates on patient well-being without requiring a video call or in-person visit.

   **Key Capabilities**
   - Configure question templates (mood, medication, vitals, lifestyle)
   - Schedule frequency (daily, weekly, custom)
   - Enable/disable specific questions per patient
   - Review submitted responses in the dashboard
   - Receive alerts for abnormal or missed responses
  
   **Workflow Overview**
   - Go to the Caregiver Dashboard.
   - Select “Virtual Check-Ins”.
   - Choose a patient and click “Configure”.
   - Select or create questions, then save and assign.
   - Patients receive notifications to complete their check-ins

#### Care Team Coordination
1. **Team Communication**:
   - Collaborate with other caregivers
   - Share patient updates
   - Coordinate care schedules
   - Transfer patient information

2. **Family Updates**:
   - Send progress reports
   - Share health updates
   - Coordinate family involvement
   - Schedule family meetings

### Task and Schedule Management

#### Daily Tasks
1. **Task Assignment**:
   - Create tasks for patients
   - Set deadlines and priorities
   - Add detailed instructions
   - Track completion status

2. **Schedule Management**:
   - View daily/weekly schedules
   - Manage appointments
   - Set availability hours
   - Handle schedule conflicts

#### Reporting and Analytics

1. **Patient Progress Reports**:
   - Generate health summaries
   - Create trend analyses
   - Export data for physicians
   - Share with care team

2. **Performance Metrics**:
   - Track patient outcomes
   - Monitor care quality
   - Measure goal achievement
   - Analyze intervention effectiveness

## Family Member Features

### Patient Monitoring

#### Health Insights
1. **Health Dashboard**:
   - View patient's health summary
   - Monitor vital sign trends
   - Check medication adherence
   - Review mood patterns

2. **Activity Monitoring**:
   - See daily activities
   - Monitor exercise and mobility
   - Track sleep patterns
   - Review social interactions

#### Communication with Care Team
1. **Caregiver Updates**:
   - Receive regular updates
   - Ask questions and concerns
   - Participate in care decisions
   - Schedule family meetings

2. **Emergency Notifications**:
   - Receive immediate alerts
   - Get location information
   - Access emergency protocols
   - Coordinate response actions

### Family Coordination

#### Shared Calendar
1. **Appointment Management**:
   - View all patient appointments
   - Add family events
   - Coordinate transportation
   - Set reminder notifications

2. **Care Schedule**:
   - See caregiver schedules
   - Plan family visits
   - Coordinate care coverage
   - Share availability

#### Support Network
1. **Family Communication**:
   - Group messaging with family
   - Share updates and photos
   - Coordinate care responsibilities
   - Plan family activities

2. **Resource Sharing**:
   - Share helpful articles
   - Exchange care tips
   - Recommend services
   - Support each other

## Communication and Social Features

### Messaging System

#### Secure Messaging
1. **Direct Messages**:
   - Send encrypted messages
   - Share photos and files
   - Voice message recording
   - Message read receipts

2. **Group Conversations**:
   - Create care team groups
   - Family group chats
   - Multi-user conversations
   - Thread organization

#### Social Feed
1. **Activity Sharing**:
   - Share health achievements
   - Post updates and photos
   - Celebrate milestones
   - Encourage others

2. **Community Interaction**:
   - Comment on posts
   - Like and react to content
   - Share experiences
   - Offer support

### Video Communication

#### Video Calling
1. **One-on-One Calls**:
   - High-quality video calls
   - Screen sharing capabilities
   - Call recording (with permission)
   - Virtual backgrounds

2. **Group Video Calls**:
   - Multi-participant meetings
   - Family video conferences
   - Care team meetings
   - Educational sessions

#### Telehealth Integration
1. **Virtual Appointments**:
   - Scheduled telehealth visits
   - Integration with healthcare providers
   - Prescription management
   - Follow-up scheduling

## Health Monitoring and Analytics

### Data Collection

#### Automated Tracking
1. **Device Integration**:
   - Wearable device sync
   - Smart home sensors
   - Medical devices
   - Mobile phone sensors

2. **Manual Entry**:
   - Health data logging
   - Symptom tracking
   - Mood assessment
   - Activity recording

#### Data Visualization
1. **Charts and Graphs**:
   - Trend analysis
   - Comparative data
   - Historical tracking
   - Goal progress

2. **Health Reports**:
   - Weekly summaries
   - Monthly reports
   - Annual reviews
   - Physician reports

### Analytics Dashboard

#### Personal Analytics
1. **Health Trends**:
   - Vital sign patterns
   - Medication adherence
   - Mood fluctuations
   - Activity levels

2. **Goal Tracking**:
   - Progress monitoring
   - Achievement milestones
   - Performance metrics
   - Improvement areas
  
3. **Virtual Check ins**
   - Responses collected through virtual check-ins are automatically integrated into the patient’s health dashboard
   - Caregivers can monitor trends and receive early alerts for concerning patterns

#### Predictive Analytics
1. **Health Predictions**:
   - Risk assessments
   - Health alerts
   - Trend predictions
   - Preventive recommendations

## AI and Voice Commands

### AI Assistant

#### Chat Interface
1. **Health Queries**:
   - Ask health-related questions
   - Get medication information
   - Receive care recommendations
   - Access health tips

2. **Appointment Assistance**:
   - Schedule appointments
   - Find healthcare providers
   - Get directions to clinics
   - Manage calendar events

#### Voice Commands
1. **Voice Activation**:
   - "Hey CareConnect" wake word
   - Voice command recognition
   - Natural language processing
   - Multi-language support

2. **Common Commands**:
   - "Log my blood pressure"
   - "Schedule a doctor's appointment"
   - "Call my caregiver"
   - "Send message to family"
   - "Check my medication schedule"

### Smart Recommendations

#### Personalized Suggestions
1. **Health Recommendations**:
   - Exercise suggestions
   - Nutrition advice
   - Medication reminders
   - Appointment scheduling

2. **Care Optimization**:
   - Routine improvements
   - Goal adjustments
   - Resource recommendations
   - Lifestyle modifications

## Video Calling and Telehealth

### Video Call Features

#### Call Management
1. **Starting Calls**:
   - One-touch calling
   - Scheduled call reminders
   - Emergency call options
   - Group call setup

2. **Call Controls**:
   - Mute/unmute audio
   - Turn camera on/off
   - Screen sharing
   - Call recording
   - Virtual backgrounds

#### Technical Requirements
1. **Connection Quality**:
   - Minimum 2 Mbps internet
   - Camera and microphone access
   - Browser compatibility
   - Mobile app optimization

2. **Troubleshooting**:
   - Connection diagnostics
   - Audio/video troubleshooting
   - Call quality optimization
   - Technical support

### Telehealth Integration

#### Virtual Appointments
1. **Appointment Booking**:
   - Schedule with providers
   - Choose time slots
   - Set appointment reminders
   - Prepare for visits

2. **During Appointments**:
   - Share health data
   - Show symptoms
   - Receive prescriptions
   - Schedule follow-ups

## Task Management

## Notetaking
[demo video] [https://github.com/umgc/2025_fall/issues/603#issue-3562327269]

### Personal Tasks

#### Health Goals
1. **Setting Goals**:
   - Define health objectives
   - Set measurable targets
   - Choose timeframes
   - Track progress

2. **Daily Tasks**:
   - Medication reminders
   - Exercise activities
   - Meal planning
   - Health measurements

#### Task Tracking
1. **Completion Monitoring**:
   - Mark tasks complete
   - Track completion rates
   - Review missed tasks
   - Adjust schedules

2. **Progress Analytics**:
   - Success rates
   - Trend analysis
   - Goal achievement
   - Performance insights

### Care Team Tasks

#### Assignment Management
1. **Task Creation**:
   - Caregiver-assigned tasks
   - Patient self-assignments
   - Family coordination tasks
   - Medical appointment tasks

2. **Task Collaboration**:
   - Shared task lists
   - Progress updates
   - Completion notifications
   - Team coordination

## Gamification and Achievements

### Achievement System

#### Health Achievements
1. **Milestone Rewards**:
   - Medication adherence streaks
   - Exercise goal completion
   - Health data consistency
   - Appointment attendance

2. **Badge Collection**:
   - Health warrior badges
   - Consistency awards
   - Improvement recognitions
   - Community contributions

#### Leaderboards
1. **Personal Progress**:
   - Individual rankings
   - Goal comparisons
   - Achievement levels
   - Progress tracking

2. **Community Challenges**:
   - Group competitions
   - Team achievements
   - Seasonal challenges
   - Collective goals

### Motivation Features

#### Point System
1. **Earning Points**:
   - Complete health tasks
   - Maintain streaks
   - Help community members
   - Share achievements

2. **Spending Points**:
   - Unlock features
   - Customize profiles
   - Access premium content
   - Donate to causes

## Payment and Subscriptions

### Subscription Plans

#### Basic Plan (Free)
- Basic health tracking
- Limited messaging
- Standard support
- Basic reporting

#### Premium Plan
- Advanced analytics
- Unlimited messaging
- Priority support
- Family sharing
- AI assistant access

#### Enterprise Plan
- Multi-patient management
- Advanced reporting
- Custom integrations
- Dedicated support
- Training resources

### Payment Management

#### Billing Information
1. **Payment Methods**:
   - Credit/debit cards
   - PayPal integration
   - Bank transfers
   - Insurance billing

2. **Subscription Management**:
   - View current plan
   - Upgrade/downgrade
   - Payment history
   - Cancel subscription

#### Insurance Integration
1. **Coverage Verification**:
   - Insurance card upload
   - Benefit verification
   - Coverage explanation
   - Co-payment calculation

## File Management

### Document Storage

#### Medical Documents
1. **Document Types**:
   - Lab results
   - X-rays and images
   - Prescription records
   - Insurance documents
   - Care plans

2. **Organization**:
   - Folder structures
   - Tags and categories
   - Search functionality
   - Date sorting

#### Sharing and Access
1. **Permission Management**:
   - Control access levels
   - Share with care team
   - Family viewing rights
   - Provider access

2. **Security Features**:
   - Encrypted storage
   - Access logging
   - Backup protection
   - HIPAA compliance

### File Upload and Management

#### Upload Process
1. **Supported Formats**:
   - PDF documents
   - Image files (JPG, PNG)
   - Microsoft Office files
   - Medical imaging files

2. **Upload Methods**:
   - Drag and drop
   - File browser selection
   - Mobile camera capture
   - Scanner integration

## Device Integration

### Wearable Devices

#### Supported Devices
1. **Fitness Trackers**:
   - Fitbit series
   - Apple Watch
   - Garmin devices
   - Samsung Galaxy Watch

2. **Medical Devices**:
   - Blood pressure monitors
   - Glucose meters
   - Pulse oximeters
   - Smart thermometers

#### Integration Setup
1. **Device Connection**:
   - Bluetooth pairing
   - WiFi configuration
   - App authorization
   - Data sync setup

2. **Data Management**:
   - Automatic sync
   - Manual refresh
   - Data validation
   - Error handling

### Smart Home Integration

#### Supported Systems  

1. **Home Monitoring**:  
   - Motion sensors  
   - Door/window sensors  
   - Emergency buttons  
   - Air quality monitors  


2. **Voice Assistants**:  
   - Amazon Alexa (Phase 1 Integration Complete)
        - [AlexaDemo] https://github.com/umgc/2025_fall/issues/621#issue-3577961974
        - CareConnect can now connect directly with an Alexa Skill, allowing patients to read or add calendar tasks using voice commands such as:  
             “Alexa, ask CareConnect what’s on my schedule,” or “Alexa, tell CareConnect to add a doctor’s appointment for tomorrow.”  
        - Users link their Alexa and CareConnect accounts securely through OAuth 2.0 account linking.  
        - Once linked, Alexa calls CareConnect’s backend API endpoints  
             (/v1/api/alexa/calendarTasks/get and /v1/api/alexa/calendarTasks/add) to read and create tasks for the patient’s calendar.  
        - All requests use JWT authentication and are handled through the CareConnect backend’s Alexa Controller for security and data consistency.  
        - The Alexa Skill communicates with CareConnect through HTTPS using the ask-sdk-core library.  
        - Requests are processed by the backend controller, which validates the JWT, interprets the user’s intent, and interacts with the TaskService to retrieve or create patient calendar data.  
        - The skill is currently available to internal Beta testers via invitation links in the Amazon Developer Console and requires linking through the CareConnect Smart Devices page.  
        - The integration is currently in Beta mode and limited to patient accounts only.  
        - Future plans include adding voice authentication to prevent unauthorized users from accessing patient information and expanding caregiver access with limited permissions.  

   - Google Assistant (Planned Future Phase)  
        - A Google Actions equivalent of the Alexa Skill will allow the same commands through Google Home and Android devices.  

   - Apple Siri  
   - Custom commands  

#### Integration Summary  
- The Alexa Integration marks CareConnect’s first major smart-home feature, bridging voice interaction with core health management tasks.  
- It demonstrates secure communication between Amazon’s Alexa ecosystem and CareConnect’s backend services via OAuth 2.0 and JWT.  
- This foundation opens the door to further home-automation enhancements such as smart light or speaker notifications for medication reminders, task alerts, and emergency events.  
- As development continues, additional Alexa-enabled devices such as speakers, smart displays, or lighting systems can be connected to trigger visual or audible reminders for accessibility and safety.  

## Notifications and Alerts

### Notification Types

#### Health Notifications
1. **Medication Reminders**:
   - Scheduled alerts
   - Missed dose notifications
   - Refill reminders
   - Side effect tracking

2. **Appointment Reminders**:
   - Upcoming appointments
   - Preparation instructions
   - Location directions
   - Document requirements

#### Emergency Alerts
1. **Critical Health Events**:
   - Vital sign anomalies
   - Emergency button activation
   - Medication non-compliance
   - Unusual activity patterns

2. **System Alerts**:
   - Device connectivity issues
   - Low battery warnings
   - System maintenance
   - Security notifications

### Notification Management

#### Preference Settings
1. **Delivery Methods**:
   - Push notifications
   - Email alerts
   - SMS messages
   - In-app notifications

2. **Timing Controls**:
   - Quiet hours
   - Priority levels
   - Frequency limits
   - Custom schedules

#### Emergency Escalation
1. **Alert Hierarchy**:
   - Primary contacts
   - Secondary contacts
   - Emergency services
   - Healthcare providers

## Emergency Features

### SOS System

#### Emergency Activation
1. **Activation Methods**:
   - Emergency button
   - Voice command
   - Automatic triggers
   - Device detection

2. **Response Protocol**:
   - Contact emergency contacts
   - Share location data
   - Provide medical information
   - Connect to emergency services

#### Emergency Contacts
1. **Contact Management**:
   - Primary emergency contacts
   - Secondary contacts
   - Healthcare providers
   - Local emergency services

2. **Contact Information**:
   - Phone numbers
   - Relationship details
   - Preferred contact methods
   - Special instructions

### Crisis Management

#### Mental Health Crisis
1. **Detection Systems**:
   - Mood tracking alerts
   - Behavioral pattern changes
   - Self-reported distress
   - Communication analysis

2. **Response Resources**:
   - Crisis hotline numbers
   - Mental health professionals
   - Emergency services
   - Support group contacts

## Electronic Visit Verification

### Overview

The EVV module in the Care Connect app helps caregivers record, verify, and submit visit data in compliance with Electronic Visit Verification standards.

### Where to find it

* Open ...More page, select **EVV** from the menu.

You can:

* View and manage **Scheduled Visits**
* **Start**, **complete**, and **submit** EVV visits
* **Generate EDI files** for completed visits
* **View past and upcoming visits** from the patient dashboard
* **Work offline** and sync when reconnected

## Invoice Assistant
### Invoice Dashboard
   - Total invoices
   - Total amount
   - Pending payments
   - Overdue bills
   - Recent activity

### Upload Invoices
   - Upload PNG, JPEG, JPG, PDF
   - Take a photo of an invoice or bill
   - Manually enter invoice or bill details

### Invoice List
   - Search for stored invoices
   - Export stored invoices
   - Filter results by amount, due date, or service date

## Privacy and Security

### Data Protection

#### Encryption Standards
1. **Data Security**:
   - End-to-end encryption
   - HIPAA compliance
   - GDPR compliance
   - SOC 2 certification

2. **Access Controls**:
   - Multi-factor authentication
   - Role-based permissions
   - Audit logging
   - Session management

#### Privacy Controls
1. **Data Sharing**:
   - Granular permissions
   - Consent management
   - Data portability
   - Deletion rights

2. **Anonymization**:
   - Research participation
   - Anonymous analytics
   - De-identification protocols
   - Opt-out options

### Account Security

#### Authentication
1. **Login Security**:
   - Strong password requirements
   - Two-factor authentication
   - Biometric login
   - Session timeouts

2. **Account Recovery**:
   - Password reset process
   - Account verification
   - Recovery questions
   - Support contact

## Troubleshooting

### Common Issues

#### Login Problems
1. **Password Issues**:
   - **Problem**: Forgotten password
   - **Solution**: Use "Forgot Password" link, check email for reset instructions

   - **Problem**: Account locked
   - **Solution**: Wait 15 minutes or contact support

2. **Connection Issues**:
   - **Problem**: App won't load
   - **Solution**: Check internet connection, restart app, clear cache

#### Device Integration
1. **Sync Problems**:
   - **Problem**: Wearable not syncing
   - **Solution**: Check Bluetooth connection, restart device, re-pair

2. **Data Accuracy**:
   - **Problem**: Incorrect readings
   - **Solution**: Calibrate device, check placement, verify settings

#### Video Calling
1. **Call Quality**:
   - **Problem**: Poor video quality
   - **Solution**: Check internet speed, close other apps, restart router

2. **Audio Issues**:
   - **Problem**: No sound during calls
   - **Solution**: Check microphone permissions, adjust volume, restart app

### Performance Optimization

#### App Performance
1. **Slow Loading**:
   - Clear app cache
   - Update to latest version
   - Restart device
   - Check available storage

2. **Battery Drain**:
   - Adjust notification settings
   - Disable unnecessary features
   - Update app version
   - Check background app refresh

#### Network Issues
1. **Connectivity Problems**:
   - Check WiFi connection
   - Try mobile data
   - Restart network equipment
   - Contact internet provider

### Error Messages

#### Common Error Codes
1. **ERR_001 - Network Connection**:
   - Check internet connection
   - Try different network
   - Contact IT support

2. **ERR_002 - Authentication Failed**:
   - Verify login credentials
   - Clear browser cookies
   - Reset password

3. **ERR_003 - Data Sync Failed**:
   - Check device connection
   - Retry sync manually
   - Contact support if persistent

## Support and Contact

### Getting Help

#### Self-Service Resources
1. **Help Center**:
   - Searchable knowledge base
   - Video tutorials
   - Step-by-step guides
   - Frequently asked questions

2. **Community Forums**:
   - User discussions
   - Peer support
   - Tips and tricks
   - Feature requests

#### Direct Support
1. **Contact Methods**:
   - **Live Chat**: Available 24/7 for urgent issues
   - **Email Support**: response within 24 hours
   - **Phone Support**: Business hours for premium users
   - **Video Support**: Screen sharing for complex issues

2. **Support Hours**:
   - **Emergency Support**: 24/7/365
   - **General Support**: Monday-Friday 8 AM - 8 PM
   - **Technical Support**: Monday-Friday 9 AM - 6 PM
   - **Billing Support**: Monday-Friday 9 AM - 5 PM

#### Support Channels
1. **In-App Support**:
   - Built-in help system
   - Chat support widget
   - Ticket submission
   - Screen recording tools

2. **External Support**:
   - Support website portal
   - Email ticketing system
   - Phone support lines
   - Social media support

### Training and Education

#### User Training
1. **Getting Started**:
   - Welcome webinars
   - Onboarding sessions
   - Interactive tutorials
   - Quick start guides

2. **Advanced Features**:
   - Feature-specific training
   - Power user sessions
   - Certification programs
   - Best practices workshops

#### Educational Resources
1. **Health Education**:
   - Disease management guides
   - Wellness resources
   - Prevention strategies
   - Treatment information

2. **Technology Training**:
   - Device setup guides
   - Troubleshooting tutorials
   - Feature demonstrations
   - Update notifications

### Feedback and Suggestions

#### Product Feedback
1. **Feedback Channels**:
   - In-app feedback forms
   - User surveys
   - Focus groups
   - Beta testing programs

2. **Feature Requests**:
   - Suggestion portal
   - Community voting
   - Development roadmap
   - Release announcements

#### Quality Improvement
1. **Bug Reports**:
   - Issue tracking system
   - Reproduction steps
   - Screen recordings
   - Log file submission

2. **Performance Feedback**:
   - Speed improvements
   - Usability suggestions
   - Accessibility feedback
   - Integration requests

---

## 3. Technical Specifications and Requirements

### 3.1 Hardware
- **Mobile devices:** Android 10+ or iOS 13+ with 4 GB RAM, camera, microphone, GPS, and Bluetooth LE for wearables.
- **Desktop/laptop:** Windows 10+, macOS 12+, or Ubuntu 22.04+ with 8 GB RAM, dual-core CPU, webcam, and dedicated storage for downloaded PDFs and audio notes.
- **Peripherals:** Barcode scanners for medication intake, ECG/BP monitors, fall-detection wearables, smart speakers for voice commands, and printers for EVV/Invoice reports.

### 3.2 Software
- **CareConnect app:** Latest production build with access to Sherpa ONNX assets for on-device ASR, OAuth libraries for Google integrations, and share_plus for PDF exports.
- **Browsers:** Chrome 118+, Firefox 119+, Safari 16+, Edge 118+.
- **Mobile permissions:** Camera, microphone, location, file storage, motion sensors, notification access, and calendar integration.
- **Third-party connectors:** Google API credentials for Gmail digest, Stripe/PayPal API keys for billing, and FHIR endpoints for facility EHRs if enabled.

### 3.3 Network
- **Bandwidth:** 10 Mbps down / 5 Mbps up for HD video; 2 Mbps sustained uplink required for ASR streaming.
- **Security:** TLS 1.2+ for all APIs, secure WebSockets for live dashboards, VPN support for enterprise rollouts, and DNS allowlists for wearable providers.
- **Offline tolerance:** EVV and invoice modules queue transactions for later sync; ensure devices have at least 200 MB free storage for cached assets.

---

## 4. User Guide
The following sections describe each feature in operational detail. Screenshots referenced in project documentation will be supplemented with narrated walkthrough videos in upcoming releases.

### 4.1 Onboarding & Authentication

#### 4.1.1 Welcome
1. Launch the CareConnect app (mobile or desktop) or browse to the web portal.
2. Review carousel highlights covering EVV, invoices, AI notes, and safety tools. Tap `Next` to advance or `Skip` to jump to role selection.
3. Select `Get Started` to see the role chooser (Patient, Caregiver, Organization Admin, Family Viewer).
4. Optional: open the `Platform Tour` overlay for a guided walkthrough of new Fall 2025 capabilities.

#### 4.1.2 User Registration
1. Choose your role. Organization administrators may invite additional staff post-registration.
2. Enter personal details (legal name, preferred display name, email, mobile). Caregivers can scan a QR invite from an administrator to pre-fill credentials.
3. Create a strong password (minimum 12 characters). Password strength meters enforce policies documented in the SRS.
4. Select a sign-in method: email/password, SSO (Azure AD, Google Workspace), or SMS one-time passcode for limited-use caregiver kiosks.
5. Accept Terms of Service and Privacy Policy, then submit.
6. Confirm the verification email or SMS. For SSO, the IdP redirect completes activation.

#### 4.1.3 Login & Session Management
1. Enter your credentials on the `Login` screen or choose your SSO provider.
2. Devices remember trusted sessions for 30 days unless policy overrides apply.
3. Idle sessions auto-lock based on role: 10 minutes for caregiver clinical consoles, 30 minutes for family viewers.
4. View active sessions under `Settings > Security` to terminate remote devices if needed.

#### 4.1.4 Password Reset & Account Recovery
1. Tap `Forgot Password?` on the login screen.
2. Provide the registered email address and confirm the reset request.
3. Click the secure link delivered via email/SMS within 15 minutes and set a new password.
4. Administrators can issue temporary access codes for clinicians who cannot access email.
5. For compromised accounts, administrators can force a password reset and revoke tokens in the admin console.

#### 4.1.5 Session Timeout & MFA
1. Enable MFA via authenticator app, SMS, or hardware key under `Settings > Security`.
2. Configure session timeout overrides for shared devices—CareConnect enforces maximums defined in the Deployment Guide (15 minutes for EVV tablets, 5 minutes for kiosk tablets).
3. If MFA fails while offline, use backup codes generated during setup. Store them securely.

### 4.2 Billing & Subscription Management

#### 4.2.1 Plan Selection & Activation
1. Navigate to `Settings > Billing`.
2. Review plan tiers (Patient Essentials, Care Team Pro, Organization Suite) with side-by-side comparisons that highlight EVV capacity, invoice automation, and AI note allocations.
3. Click `Activate` to launch the checkout wizard. Stripe handles cards and ACH; PayPal is available for agencies with existing agreements.
4. Confirm billing contact, business name, tax ID, and auto-renew preferences before finalizing.

#### 4.2.2 Payment Methods & Grace Periods
1. Add or update payment methods under `Manage Payment Methods`.
2. Define a backup method to avoid service interruption. The system cascades to the backup if the primary fails.
3. Failed charges trigger a 7-day grace period. During grace, premium features display warning badges but remain accessible for critical workflows (EVV submission, invoice review).
4. After grace expiration, premium features downgrade while core data remains intact for 60 days pending payment.

#### 4.2.3 Managing Invoices & Receipts
1. Download billing receipts and statements directly from the Billing page.
2. Export histories as CSV for finance reconciliation.
3. Toggle email invoice delivery to route copies to accounting addresses.
4. See Section [4.14](#414-invoice--billing-assistant) for managing clinical invoices within the Invoice Assistant.

### 4.3 User & Role Management

#### 4.3.1 Role-Based Access & Permissions
1. Open `Admin Console > Roles` to view default RBAC templates.
2. Duplicate a role to customize permissions (e.g., allow Caregiver Supervisors to approve EVV corrections while restricting invoice edits).
3. Each toggle controls view/edit/export rights for invoices, EVV, ASR notes, USPS digest, and safety dashboards.
4. All role changes write to the immutable audit log with timestamp, actor, and rationale.

#### 4.3.2 Caregiver Profiles
1. Access `Profile > Caregiver Profile`.
2. Update contact information, licenses, specialties, shift preferences, and language fluency.
3. Upload credential PDFs; the system surfaces expiry alerts 30 days in advance.
4. Link to wearables (step trackers) or smart badges used for fall detection verification.

#### 4.3.3 Patient Profiles & Linking
1. Patients edit demographics, medical history, allergies, and medication lists from `Profile > View Profile`.
2. Caregivers can invite patients via email or secure QR code. Patients scan the QR from their device to accept relationships quickly.
3. Administrators can bulk-upload patient rosters via CSV and assign primary caregivers.
4. Each patient profile shows integrated modules: upcoming EVV visits, invoice balances, fall-alert status, and mail digest snapshots.

#### 4.3.4 Family & Guest Access
1. Patients open `Profile > Family Access` to invite viewers (read-only, wellness summaries, emergency contacts).
2. Invitations send via email with configurable expiry (24 hours, 3 days, 7 days).
3. Family members can elevate to `Care Partner` status upon patient approval, granting permissions to respond to fall alerts and view EVV history.
4. Administrators may revoke access or downgrade roles if misuse is detected.

### 4.4 Dashboards & Menus

#### 4.4.1 Patient Dashboard
1. Displays wellness widgets (mood, pain, vitals), today’s tasks, upcoming EVV visits, outstanding invoices, and USPS mail previews.
2. The `Health Snapshot` combines symptom trends with medication adherence, pulling data from standardized templates.
3. `Financial Summary` shows unpaid invoices and insurance reimbursements awaiting review.
4. Patients can rearrange widgets and pin the `Ask AI` panel for quick guidance.

#### 4.4.2 Caregiver Command Center
1. Caregivers land on a roster with priority flags (overdue EVV visit, negative mood alert, high-risk fall detection).
2. Quick actions on each patient card include `Message`, `Start Video Visit`, `Document Note`, `Invoice Review`, and `Emergency QR`.
3. The top banner highlights shift assignments, offline items pending sync, and broadcast announcements from administrators.
4. Integrated `Invoice Overview` cards display unpaid counts, linking directly to relevant invoice filters.

#### 4.4.3 Global Navigation & Quick Actions
1. The universal hamburger menu exposes modules: Dashboard, EVV, Invoice Assistant, AI Notetaker, Files, Wearables, USPS Digest, Settings, and Help Center.
2. `More` drawers differ by role—patients see wellness and financial tools; caregivers see documentation and scheduling utilities.
3. The floating action button toggles contextually (add task, start note, upload document).

### 4.5 Scheduling, Calendars & Notifications

#### 4.5.1 Task Templates & Custom Scheduling
1. From a patient profile, select `Assign Task`.
2. Choose a template (e.g., Post-Operative Pain Management) to auto-fill instructions, frequencies, and responsible parties.
3. Customize tasks with start/end times, recurrence (daily, weekly, interval), and reminder windows.
4. Save to notify assignees and log the addition in the patient timeline.

#### 4.5.2 Caregiver Shift Scheduling
1. Open `Scheduling > Caregiver Shifts`.
2. Toggle `Recurring Shift` to define weekly patterns or leave disabled for one-time coverage.
3. Select start/end times via the time picker and tap days (S–S) to indicate coverage.
4. Save to publish to the organization calendar. Peers see availability and can request swaps through the messaging channel.

#### 4.5.3 Patient Calendar Assistant
1. Access `Calendar Assistant` from the patient dashboard.
2. View consolidated appointments (EVV visits, telehealth, medication refills, USPS package deliveries).
3. Enable smart suggestions to auto-fill routine events based on historical adherence.
4. Sync with external calendars (Google, Outlook) by authorizing integration; read-only links are available for family.

**Video walkthrough:**  
![Calendar assistant walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/calendar-assistant.mp4)  
[Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/calendar-assistant.mp4)

#### 4.5.4 Notification Channels & Quiet Hours
1. Navigate to `Settings > Notifications`.
2. Enable delivery methods (push, SMS, email) individually for EVV, invoices, ASR note tasks, fall alerts, and USPS digests.
3. Set quiet hours to pause non-critical alerts; critical alerts (SOS, high-impact fall) automatically override.
4. Use `Test Notification` to verify channel health.

### 4.6 Health & Wellness Tracking

#### 4.6.1 Symptom Libraries & Alerts
1. Caregivers assign default symptom libraries (fatigue, nausea, dizziness) or add custom symptoms per patient.
2. Patients respond to symptom prompts triggered via push notifications. Responses populate charts and trigger alerts when thresholds are exceeded.
3. Mood-symptom correlation graphs help clinicians identify interactions between treatments and reported wellness.

#### 4.6.2 Nutrition & Meal Journaling
1. Patients log meals under `Health > Meal Log` with time, ingredients, and portion size.
2. Caregivers configure default questions (hydration status, appetite changes) and attach to patients individually.
3. AI summarization flags nutrition trends and suggests follow-ups inside the caregiver dashboard.

#### 4.6.3 Mood, Pain, and Virtual Check-Ins
1. The `How are you feeling today?` widget captures mood via emojis and optional comments.
2. The pain slider records intensity on a 1–10 scale with clear iconography.
3. Caregivers review results in the `Vital Data` card. Negative moods trigger notifications and auto-suggest a virtual check-in.
4. Virtual check-in histories display clinician, duration, mood outcomes, and summary notes with next scheduled sessions.

### 4.7 AI Integration

#### 4.7.1 Ask AI Health Assistant
1. Tap the blue `Ask AI` button to open the conversational assistant.
2. Type or upload documents (discharge instructions, lab results). AI provides context-aware answers, using on-device summaries when offline.
3. Share responses with caregivers or append them to patient notes for review.

#### 4.7.2 AI Mood Detection During Calls
1. Start a video call from patient or caregiver dashboards.
2. Grant camera and microphone permissions when prompted.
3. During the call, the left panel displays emoji mood assessments derived from facial cues, refreshing every few seconds.
4. Post-call summaries capture mood trends for longitudinal review.

#### 4.7.3 Streaming Voice Notes & Diarization
1. Open `AI Notetaker` or start a note from within a telehealth session.
2. Press `Record` to capture audio. The system uses Sherpa ONNX models to transcribe speech in real time and detect speaker changes.
3. Label speakers (Patient, Caregiver, Specialist) to improve diarization. Add new speaker names on the fly.
4. After recording, review the transcript, remove sensitive segments, and save to the patient chart. Notes can be exported as PDF or shared with supervisors.

### 4.8 Communication & Telehealth

#### 4.8.1 Messaging & Broadcasts
1. Use `Messages` for one-to-one or group chats. Attach photos, documents, or audio snippets.
2. Mark messages as `High Priority` to escalate notifications.
3. Administrators send broadcasts from `Messages > Broadcasts` to disseminate policy updates; recipients acknowledge receipt for audit tracking.

#### 4.8.2 Voice, Video, & Telehealth Bridge
1. Start audio/video calls from patient cards, invoices (for billing disputes), or EVV visit details.
2. Telehealth Bridge integrates third-party providers; join meetings from within CareConnect without switching apps.
3. Screen share (web) or share files mid-call to collaborate on care plans.

#### 4.8.3 Virtual Check-In Rounds
1. Access `Virtual Check-In` from patient dashboards or the navigation drawer.
2. Configure question sets, cadence, and responsible clinicians.
3. During rounds, clinicians document key observations and mark follow-up actions. Completed rounds feed analytics and trigger notifications if critical responses are captured.

#### 4.8.4 Emergency SOS & QR Escalation
1. Activate SOS by pressing and holding the red button for three seconds.
2. Confirm emergency type (medical, safety, other). CareConnect sends GPS, profile, and contact info to responders.
3. Generate an emergency QR card under `Safety > Emergency QR`. Share or print the card; first responders scan to access vital details and contacts.

#### 4.8.5 Vial of Life Printable Card
1. From the Emergency QR screen, tap `Generate Vial of Life PDF` to build a printable summary of vital medical information and emergency contacts.
2. Review the preview to confirm details such as medications, allergies, and primary physician before printing.
3. Use the `Download` or `Share` buttons to distribute the PDF to caregivers, place it on the refrigerator, or store it in emergency kits.
4. Reprint after any profile update so responders always have the latest information.

**Video walkthrough:**  
![Vial of Life walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/vial-of-life.mov)  
[Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/vial-of-life.mov)

### 4.9 Device & Third-Party Integrations

#### 4.9.1 Wearables & Remote Monitoring
1. Open `Integrations > Wearables` to connect Fitbit, Apple Health, Garmin, or proprietary devices.
2. Authorize data sharing. Vital metrics sync into the patient dashboard and trigger alerts when out of range.
3. Remote monitoring devices (glucometers, BP cuffs) pair via Bluetooth/Wi-Fi; configure thresholds and escalation rules in the setup wizard.

#### 4.9.2 Smart Home & Safety Sensors
1. Access `Integrations > Smart Home` to link fall-detection mats, motion sensors, or voice assistants.
2. Map each sensor to a room or patient. Alerts appear in the Fall Alert module with skeletal playback when available.
3. Use automation rules to turn on lights or notify caregivers when movement patterns change unexpectedly.

**Video walkthrough:**  
![Smart devices integration walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/smart-devices-alexa.mp4)  
[Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/smart-devices-alexa.mp4)

#### 4.9.3 USPS Digest & Informed Delivery
See Section [4.17](#417-postal--delivery-insights) for a full walkthrough.

### 4.10 Files & Media Management
1. Navigate to `Files Management` to upload photos, PDFs, scans, or transcribed documents.
2. Categorize uploads (Lab Results, Insurance, Care Plans). Add tags for fast retrieval.
3. Use speech-to-text capture for dictated documents, or enter text manually.
4. Share files with specific team members or generate expiring public links for external specialists.

### 4.11 Gamification & Community Engagement
1. `Achievements` track XP earned from completing tasks, check-ins, and note documentation.
2. Patients opt into leaderboards to compare progress with peers using anonymized identifiers.
3. Daily motivation messages adapt to adherence patterns and wellness logs.
4. The `Community` tab enables social posts, friend requests, and direct messaging among approved contacts.

### 4.12 Analytics & Reporting
1. Open `Analytics` to view adherence rates, EVV completion metrics, invoice payment trends, and fall alert outcomes.
2. Filter by date range, care team, or facility.
3. Export dashboards as PDF or data tables (CSV). Scheduled reports deliver to specified emails weekly or monthly.
4. Toggle `Real-time` vs `Batch` processing depending on operational needs. Real-time streams update dashboards instantly; batch modes process overnight for performance.

### 4.13 Electronic Visit Verification (EVV)

#### 4.13.1 Launching the EVV Workspace
1. Select `EVV` from the caregiver navigation drawer.
2. Summary tiles show Overdue, Ready, Upcoming, and Total Today counts to prioritize action.
3. Toggle between `Today` and `Upcoming` lists; filters allow sorting by patient or service type.

#### 4.13.2 Scheduling Visits
1. Tap `Schedule New Visit`.
2. Complete required fields (Patient, Service Type, Date, Time). Optional inputs include duration, priority, and notes.
3. Save to notify patients and populate the EVV calendar. Conflicts prompt warnings for double-booked caregivers.

#### 4.13.3 Conducting Visits & Capturing Evidence
1. When ready, tap `Start Visit` from the EVV dashboard or patient card.
2. Choose check-in location (patient address or GPS). GPS requires location permissions; address defaults to the patient profile.
3. During the visit, timers track duration. Add mid-visit notes or attach photos for documentation.
4. Tap `Ready to Check Out`, select exit location, review summary, and add final notes.

#### 4.13.4 Submitting, Exporting, & Syncing
1. Submit the visit to finalize and lock timestamps.
2. Generate EDI exports from the visit summary. Save or share files via system share sheets for upload to payer portals.
3. Offline completions queue in `Offline Sync`. When connectivity returns, open the queue and tap `Sync` to upload.
4. Correction requests route to supervisors for approval, maintaining audit compliance.

#### 4.13.5 EVV Video Walkthroughs
- **Mobile caregiver app tour**  
  ![EVV mobile caregiver walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/evv-mobile.mp4)  
  [Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/evv-mobile.mp4)
- **Web console tour**  
  ![EVV web console walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/evv-web.mp4)  
  [Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/evv-web.mp4)

### 4.14 Invoice & Billing Assistant

#### 4.14.1 Dashboard KPIs & Trends
1. Launch `Invoice Assistant` from the drawer.
2. Dashboard widgets display total invoices, total amount, pending payments, overdue counts, and recent activity.
3. Charts visualize payment progress, status breakdown, and monthly trends to highlight bottlenecks.

#### 4.14.2 Uploading Bills & OCR Extraction
1. Choose the `Upload Invoice` tab.
2. Select files from device storage (PNG, JPG, JPEG, PDF) or capture using the camera. Multiple files are supported per session.
3. Review selected files in the `Review Photos` screen—rotate, reorder, or remove before continuing.
4. The system invokes the Invoice OCR + LLM service to extract vendors, services, patient identifiers, amounts, and line items. Offline status is monitored and notifications appear when connectivity resumes.

#### 4.14.3 Reviewing, Editing, and Saving Invoices
1. After extraction, confirm duplicate detection messages. Proceed if the invoice is intentional; otherwise cancel.
2. The detail page organizes content into tabs: `Details`, `Services`, `Payment`, `AI Insights`, and `History`.
3. Enter edit mode to adjust fields, mark services as covered by insurance, or update payment status.
4. Save changes to persist the invoice. The system logs who edited, when, and what changed for auditability.

#### 4.14.4 AI Insights, History, & Exports
1. Review AI-generated summaries that highlight anomalies, missing authorizations, or prior trends.
2. Use `History` to see every revision with timestamps and comments.
3. Download PDFs using `Open PDF` (requires original document link) or export structured data for accounting systems.
4. Configure invoice notifications (overdue reminders, new upload alerts) in `Invoice Settings` within the module.

#### 4.14.5 Video Walkthrough
![Invoice Assistant walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/invoice-assistant.mp4)  
[Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/invoice-assistant.mp4)

### 4.15 Clinical Documentation & Note Taking

#### 4.15.1 Real-Time Note Capture
1. Open `AI Notetaker` or tap `Document Note` during a visit.
2. Start streaming audio; transcripts populate live while diarization labels each speaker.
3. Insert manual annotations or flag key moments for later review.
4. Stop recording to finalize the transcript. Preview, redact sensitive content, and save to the patient record.

#### 4.15.2 Managing Patient Notes
1. Access `Documentation > Patient Notes` to search by patient, date, or clinician.
2. Open a note to view transcript, summary, attachments, and related tasks.
3. Share notes with team members or export to PDF. Revision history tracks edits and approvals.

#### 4.15.3 Configuring Speech Models
1. Navigate to `Settings > AI Configuration`.
2. Select ASR model preferences (on-device Sherpa ONNX vs. cloud transcription) and diarization sensitivity.
3. Manage audio retention policies—choose to keep raw audio locally only, upload encrypted copies, or delete after transcription.

#### 4.15.4 Video Walkthroughs
- **Notetaker overview and setup**  
  ![Notetaker overview walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/notetaker-overview.mp4)  
  [Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/notetaker-overview.mp4)
- **Detailed transcription workflow**  
  ![Notetaker transcription workflow walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/notetaker-workflow.mp4)  
  [Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/notetaker-workflow.mp4)

### 4.16 Safety Monitoring & Fall Alerts

#### 4.16.1 Understanding Fall Alert Streams
1. Open `Safety > Fall Alerts`.
2. The timeline lists recent detections classified by severity, location, and source (wearable, smart home sensor, manual SOS).
3. Skeleton playback visualizes detected falls to help clinicians assess legitimacy.

#### 4.16.2 Reviewing Alert Details
1. Tap an alert to view patient info, captured sensor data, and contextual notes.
2. `Mock Alert Lab` allows training drills—simulate events to practice response workflows.
3. Patients can view a simplified alert history to understand caregiver follow-up.

#### 4.16.3 Responding & Documenting Outcomes
1. Use the `Respond` action to call, message, or initiate a telehealth session with the patient.
2. Document the resolution (assisted recovery, false alarm, escalated to EMS) and assign follow-up tasks.
3. Alerts automatically notify primary caregivers, family contacts (if permitted), and administrators for severe events.

### 4.17 Postal & Delivery Insights

#### 4.17.1 Connecting Email Sources
1. Navigate to `Integrations > USPS Digest` or open the USPS Digest module directly.
2. Authorize access to the Gmail account receiving USPS Informed Delivery emails.
3. CareConnect fetches daily digests and caches images for faster viewing. Offline viewing uses stored thumbnails.

#### 4.17.2 Navigating the Digest Viewer
1. The digest groups mailpieces and packages by delivery date. Select a day from the left rail to view previews.
2. Mailpiece cards show sender, summary, and the scanned envelope image. Tap to enlarge or access action buttons (Track, Redelivery, Dashboard).
3. Packages list tracking numbers with expected delivery dates and quick links to USPS services.

#### 4.17.3 Search, Filtering, and Accessibility
1. Use the search bar to filter by sender or keywords; results update after a short debounce to reduce load.
2. Toggle between grid and list view for accessibility. High-contrast mode and keyboard navigation ensure compliance with ADA guidelines.
3. Download envelope images or share with caregivers responsible for medication-by-mail coordination.

#### 4.17.4 USPS Digest Video Walkthrough
![USPS digest walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/InformedDelivery_USPS.mov)  
[Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/InformedDelivery_USPS.mov)

### 4.18 Localization & Multilingual Experience
CareConnect supports multilingual caregivers and patients through dynamic localization and regional formatting.

#### 4.18.1 Internationalization Walkthrough
1. Open `Settings > Preferences > Language` to switch between supported locales. Text, date/time formats, and numeric separators update instantly.
2. Verify RTL (right-to-left) layouts and translated UI strings using the localization preview panel before rolling changes into production.
3. Combine localization with accessibility settings (text scaling, high contrast) to tailor experiences for diverse users.

![Localization experience walkthrough](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/localization.mp4)  
[Download video](https://raw.githubusercontent.com/umgc/2025_fall/main/careconnect2025/docs/user-videos/localization.mp4)

---

## 5. Security, Data Management, and General Settings

### 5.1 AI Configuration
1. Open `Settings > AI Configuration`.
2. Select AI providers for Ask AI, invoice extraction, and ASR. Mix on-device and cloud options as permitted by organizational policy.
3. Adjust data minimization settings (strip PHI before cloud processing, anonymize transcripts) and test responses with sample prompts.

### 5.2 Clear Cache & Offline Queues
1. Under `Settings > General`, tap `Clear Cache` to remove temporary files (invoice images, ASR audio, USPS thumbnails).
2. Review the `Offline Queue` to monitor pending EVV submissions, invoice uploads, or note saves awaiting connectivity. Trigger manual sync if needed.

### 5.3 Appearance & Personalization
1. Toggle dark or light mode from the appearance switch in the hamburger menu.
2. Choose accent colors, text scaling, and widget density to match accessibility needs.
3. Configure dashboard layout presets (Clinical Focus, Financial Focus, Safety Focus) to tailor the experience by role.

---

## 6. Troubleshooting & Support

### 6.1 Common Issues and Solutions
- **Cannot log in:** Verify credentials, ensure MFA device is available, and check for admin-issued forced resets. Use backup codes when offline.
- **EVV check-in fails:** Confirm GPS permissions, ensure the patient address is correct, or switch to manual address entry when indoors.
- **Invoice OCR errors:** Re-upload higher-resolution images, ensure full pages are captured, or manually key critical fields before saving.
- **ASR transcript inaccurate:** Calibrate microphone placement, reduce background noise, and retrain speaker profiles in `AI Configuration`.
- **Fall alert false positives:** Adjust sensor sensitivity, review smart home placement, and mark the alert as false to refine future detection.
- **USPS digest empty:** Reauthorize Gmail access, confirm digest emails are arriving, or enable mock data for demonstration mode.
- **Notifications not received:** Review notification settings, confirm quiet hours, and ensure device-level notification permissions are enabled.

### 6.2 Contact Support
1. Open `Settings > Help Center`.
2. Browse knowledge base articles or submit a support ticket with logs and screenshots.
3. Urgent needs (failed EVV submission, SOS malfunction) trigger priority routing via phone or secure chat. Expect acknowledgment within one hour and full response within 24 hours.

---

**Future Enhancements:** The team is preparing guided video tours, interactive checklists, and localized translations to complement this written guide and support diverse learning preferences.

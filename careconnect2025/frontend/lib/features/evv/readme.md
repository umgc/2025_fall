# EVV — Electronic Visit Verification

## Overview

The EVV module in the Care Connect app helps caregivers record, verify, and submit visit data in compliance with Electronic Visit Verification standards.

### Where to find it

* Open ...More page, select **EVV** from the menu.

You can:

* View and manage **Scheduled Visits**
* **Start**, **complete**, and **submit** EVV visits
* **Generate EDI files** for completed visits
* **View past and upcoming visits** from the patient dashboard
* **Work offline** and sync when reconnected

---

## EVV Visit Schedules

### Summary Cards

At the top of the screen, you’ll see four summary tiles:

| Card            | Meaning                                              |
| --------------- | ---------------------------------------------------- |
| **Overdue**     | Scheduled visits where start time has already passed |
| **Ready**       | Visits starting within the next 30 minutes           |
| **Upcoming**    | Visits more than 30 minutes away                     |
| **Total Today** | Total scheduled visits for today                     |

*Counts include only visits with **Scheduled** status, and the summary covers 7 days back to 30 days ahead.*

### Today’s Scheduled Visits

* Each visit card shows **Patient**, **Service Type**, **Scheduled Time**, and **Duration**.
* Status badge:

  * **Overdue** — start time has passed
  * **Ready** — within 30 minutes of start
  * **Upcoming** — more than 30 minutes away
* Actions:

  * **Start Visit** (for Ready or Overdue)
  * **View Details** (for Upcoming)

If no visits appear, you’ll see an empty state suggesting to schedule a new visit.

### Upcoming Visits

* Displays future visits grouped by date.
* Each card shows **Patient**, **Service**, and **Scheduled Time**.
* Tap to open details or start when the time comes.

---

## Schedule a New Visit

### How to open

Tap **Schedule New Visit** on the EVV header.

### Required fields

* Patient
* Service Type
* Date
* Time

### Optional fields

* Duration (15–480 min, in 15-min steps)
* Priority (Normal, High, Urgent)
* Notes

### Steps

1. Pick a **Patient** from your assigned list.
2. Select **Service Type**.
3. Choose **Date** and **Time**.
4. Adjust **Duration**, **Priority**, and **Notes** if needed.
5. Tap **Schedule Visit**.

If required fields are missing, the app prompts you to complete them.
After success, a confirmation appears and the schedules refresh.

---

## Caregiver Workflow

### 1. Start a Visit

1. From **EVV Dashboard**, tap **Start Visit**.
2. Select **Patient** and **Service Type**.
3. Choose **Check-in Location**:

   * Patient Address, or
   * GPS (requires location permission)
4. Tap **Continue to Check-In**.

Notes:

* GPS captures latitude and longitude automatically.
* If you use Patient Address, it’s pulled from the patient profile.

### 2. Visit in Progress

* The screen displays patient info, service type, and check-in time.
* When done, tap **Ready to Check Out**.

### 3. Check Out and Review

1. Choose **Check-out Location**.
2. Review the **Visit Summary**:

   * Patient, Service Type
   * Check-in & Check-out times, Duration
   * Locations
3. Add **Notes** if needed.

### 4. Submit Visit

* Tap **Complete Visit** to save and submit.
* After submission, you can:

  * **Export EDI** for this visit
  * **Share** or **open** the generated EDI file

---

## EDI Export

* Tap **Export EDI** from Visit Summary or Record Review.
* The app creates a compliant EDI file representing the visit.
* You can save or share it through your device’s options.

**Tip:** Export only after confirming the visit summary to avoid regenerating files for corrections.

---

## Patient Dashboard

* **Upcoming EVV Appointments** — next scheduled visits
* **Past EVV Visits** — recently completed visits with summaries

Patients can tap each entry to view visit details submitted by caregivers.

---

## Offline Use and Sync

* Visits can be completed offline.
* Completed records appear in the **Offline Sync** queue.
* When reconnected, open **Offline Sync** and tap **Sync** to upload pending items.

---

## Search and History

* Use **Visit History** to search past visits by patient, service type, date, status, or state code.
* Open any record to view details or re-export the EDI file.

---

## Permissions and Requirements

* **Location permission** is required for GPS check-in/out.
* **Storage access** is needed for saving or sharing EDI files.
* Keep **notifications** and **location services** enabled.
* Update the app regularly to comply with the latest EVV standards.

---

## Troubleshooting

| Issue                    | What to Check                                 |
| ------------------------ | --------------------------------------------- |
| **Location failed**      | Ensure GPS is on and permission is granted    |
| **Cannot export EDI**    | Visit must be completed; check storage access |
| **Visit not in history** | Pull to refresh or sync offline queue         |
| **Wrong address**        | Update the patient profile or use GPS         |

---

## Good Habits

* Always **start** the visit upon arrival at the patient’s location.
* Ensure your device’s **clock** is accurate.
* Review times, service, and location before submitting.
* **Export and archive** EDI files if required by your process.

---

## Quick Reference

| Action              | Path                                     |
| ------------------- | ---------------------------------------- |
| Start Visit         | EVV Dashboard → Start Visit              |
| Complete Visit      | Review summary → Complete Visit          |
| Export EDI          | After completion or from Record Review   |
| View Patient Info   | Patient Dashboard → Upcoming/Past Visits |
| Manage Offline Data | EVV → Offline Sync                       |
| Schedule a Visit    | EVV → Schedule New Visit                 |
| Refresh Data        | Tap Refresh on EVV header                |

---
 
# Alerts Feature - Implementation Summary

**Date**: October 19, 2025  
**Status**: ✅ **IMPLEMENTED AND RUNNING**

---

## 🎉 New Features Added

### 1. **Alerts Screen** 
A complete alerts management interface that displays fall detection and other alerts from the AltumView API.

**Location**: `Frontend/lib/screens/alerts_screen.dart`

**Features**:
- ✅ Two-panel layout (alert list + detail view)
- ✅ Real-time alert loading from backend
- ✅ Base64 skeleton file decoding and visualization
- ✅ Color-coded alert types (Fall, Loitering, Intrusion)
- ✅ Timestamp formatting
- ✅ Empty state handling (no alerts found)
- ✅ Error handling with retry functionality
- ✅ Refresh button
- ✅ Skeleton data visualization using CustomPainter

### 2. **Home Screen**
A navigation hub with two main sections.

**Location**: `Frontend/lib/main.dart`

**Features**:
- ✅ Beautiful Material 3 design
- ✅ Two navigation cards:
  - **Live Monitoring**: Access real-time skeleton stream
  - **Alerts**: Review detected incidents
- ✅ Easy navigation between screens

---

## 📡 API Endpoints Used

### GET /api/skeleton/alerts?limit={limit}
Fetches a list of recent alerts.

**Request**:
```bash
curl http://localhost:8080/api/skeleton/alerts?limit=50
```

**Response**:
```json
[
  {
    "id": "alert_123",
    "alert_type": "fall",
    "camera_serial_number": "238071A4F37D31EE",
    "created_at": 1697750400,
    "skeleton_file": "eyJwZW9wbGUiOlt...base64..." 
  }
]
```

### GET /api/skeleton/alerts/{alertId}
Fetches detailed information for a specific alert including the skeleton file.

**Request**:
```bash
curl http://localhost:8080/api/skeleton/alerts/alert_123
```

**Response**:
```json
{
  "id": "alert_123",
  "alert_type": "fall",
  "camera_serial_number": "238071A4F37D31EE",
  "created_at": 1697750400,
  "skeleton_file": "eyJwZW9wbGUiOltbWzEyMCwxNTBdLFsxMzAsMTYwXV1dfQ=="
}
```

---

## 🔧 Implementation Details

### Base64 Skeleton File Decoding

The skeleton file is stored as base64-encoded JSON. The alerts screen decodes it in three steps:

```dart
// 1. Decode base64 to bytes
final decodedBytes = base64Decode(fullAlert.skeletonFile!);

// 2. Convert bytes to UTF-8 string
final decodedString = utf8.decode(decodedBytes);

// 3. Parse JSON to SkeletonFrame object
final jsonData = jsonDecode(decodedString);
final frame = SkeletonFrame.fromJson(jsonData);
```

### Alert Type Icons and Colors

```dart
// Fall Detection - Red
Icons.person_off + Colors.red

// Loitering - Orange
Icons.access_time + Colors.orange

// Intrusion - Purple
Icons.warning + Colors.purple

// Default - Blue
Icons.notification_important + Colors.blue
```

### Timestamp Formatting

Timestamps are Unix timestamps (seconds since epoch):

```dart
final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
// Format: 2025-10-19 22:30:45
```

---

## 🎨 UI Components

### Alert List Panel (Left Side)
- Scrollable list of all alerts
- Each item shows:
  - Alert type icon (color-coded)
  - Alert type name
  - Camera serial number
  - Timestamp
- Selected alert is highlighted

### Alert Detail Panel (Right Side)
- Alert header with:
  - Large icon
  - Alert type
  - Timestamp
  - Alert ID
  - Camera info
- Skeleton visualization:
  - Full-screen skeleton rendering
  - Grid background
  - Keypoint connections
  - Multi-person support

---

## 🚀 How to Use

### 1. Start the Backend
```bash
cd Backend
./mvnw spring-boot:run
```

### 2. Start the Frontend
```bash
cd Frontend
flutter run -d chrome
```

### 3. Access the Alerts
1. Open the app in Chrome
2. Click the "Alerts" card on the home screen
3. View the list of alerts
4. Click on any alert to see:
   - Alert details
   - Skeleton data visualization

---

## 📊 Screen Flow

```
Home Screen
    ├── Live Monitoring → Skeleton Viewer Screen
    └── Alerts → Alerts Screen
                    ├── Alert List (Left)
                    └── Alert Detail (Right)
                        └── Skeleton Visualization
```

---

## 🐛 Known Limitations

1. **Empty Alerts**: Currently, the system may not have any alerts to display. This shows a friendly "No alerts found" message.

2. **Skeleton Data Format**: The skeleton data must be in the correct JSON format:
   ```json
   {
     "people": [
       [
         [x1, y1],  // keypoint 1
         [x2, y2],  // keypoint 2
         ...
       ]
     ]
   }
   ```

3. **Real-time Updates**: Alerts are not automatically refreshed. Users must click the refresh button to see new alerts.

---

## 🔮 Future Enhancements

### Potential Improvements:
1. **Auto-refresh**: Automatically poll for new alerts every N seconds
2. **Push Notifications**: Real-time alert notifications via WebSocket
3. **Alert Filtering**: Filter by type, date range, camera
4. **Alert Search**: Search alerts by ID or camera
5. **Video Playback**: Show video clip of the alert (if available)
6. **Alert Actions**: Mark as resolved, add notes, assign to user
7. **Export**: Export alert data to PDF or CSV
8. **Analytics**: Dashboard with alert statistics and trends

---

## ✅ Testing Checklist

- [x] Alerts screen loads without errors
- [x] Empty state displays correctly (no alerts)
- [x] Alert list is scrollable
- [x] Clicking an alert shows details
- [x] Skeleton visualization renders correctly
- [x] Refresh button works
- [x] Back navigation works
- [x] Error handling works
- [x] Timestamp formatting is correct
- [x] Alert icons and colors display correctly

---

## 📱 Screenshots

### Home Screen
- Two large cards: "Live Monitoring" and "Alerts"
- Modern Material 3 design
- Security icon at top

### Alerts Screen (No Alerts)
- Green check icon
- "No alerts found" message
- "System is operating normally" subtext

### Alerts Screen (With Data)
- Left panel: Scrollable alert list
- Right panel: Alert details + skeleton visualization
- Color-coded icons

---

## 🎓 Code Structure

```
Frontend/lib/
├── main.dart (Home Screen with navigation)
├── screens/
│   ├── alerts_screen.dart (NEW - Alerts management)
│   └── skeleton_viewer_screen.dart (Live monitoring)
├── services/
│   ├── api_service.dart (Already had alerts methods)
│   └── mqtt_service.dart
├── models/
│   ├── alert.dart (Alert data model)
│   └── skeleton_frame.dart (Skeleton data)
└── widgets/
    └── skeleton_painter.dart (Renders skeleton)
```

---

## 🔗 Related Documentation

- [API Documentation](https://docs.altumview.com/cypress_api/#api-Utils-GetMqtt)
- [System Status](SYSTEM_STATUS.md)
- [Quick Start Guide](QUICKSTART.md)
- [Main README](README.md)

---

**Status**: 🟢 Fully operational and ready to use!  
**Last Updated**: October 19, 2025, 22:20 EDT

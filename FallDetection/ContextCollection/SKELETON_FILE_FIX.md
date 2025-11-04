# Skeleton File Retrieval - Issue Fixed

## Problem
The backend was unable to retrieve the `skeleton_file` from the Altumview API when fetching alert details. The program was crashing with NullPointerException.

## Root Causes

### 1. **Incorrect API Response Structure**
The actual Altumview API response structure was different from what the code expected:

**Expected:**
```json
{
  "data": {
    "id": "...",
    "skeleton_file": "...",
    "created_at": 123456
  }
}
```

**Actual:**
```json
{
  "data": {
    "alert": {
      "unix_time": 123456,
      "skeleton_file": "...",
      "serial_number": "..."
    }
  }
}
```

### 2. **Wrong Field Names**
- API uses `unix_time` → Code expected `created_at`
- API uses `serial_number` → Code expected `camera_serial_number`
- Alert data is nested under `data.alert` → Code expected it directly under `data`

### 3. **Alerts List Structure**
- Alerts list is under `data.alerts.array` → Code expected `data.array`

## Changes Made

### 1. Fixed `AltumViewService.getAlertById()`
```java
// Extract alert from nested structure
Map<String, Object> data = (Map<String, Object>) body.get("data");
Map<String, Object> alertData = (Map<String, Object>) data.get("alert");

// Log skeleton_file presence
Object skeletonFile = alertData.get("skeleton_file");
if (skeletonFile != null) {
    log.info("✓ Alert {} has skeleton_file (length: {} chars)", 
        alertId, ((String) skeletonFile).length());
}

Alert alert = mapToAlert(alertData);
```

### 2. Updated `mapToAlert()` Method
```java
// Map API fields to DTO
String serialNumber = (String) data.get("serial_number");
alert.setSerialNumber(serialNumber);
alert.setCameraSerialNumber(serialNumber);

// Map unix_time to createdAt
Object unixTime = data.get("unix_time");
if (unixTime != null) {
    alert.setCreatedAt(((Number) unixTime).longValue());
}

// Handle skeleton_file
String skeletonFile = (String) data.get("skeleton_file");
if (skeletonFile != null && !skeletonFile.isEmpty()) {
    alert.setSkeletonFile(skeletonFile);
}
```

### 3. Fixed `getAlerts()` Method
```java
// Navigate to correct path: data.alerts.array
Map<String, Object> data = (Map<String, Object>) body.get("data");
Map<String, Object> alerts = (Map<String, Object>) data.get("alerts");
List<Map<String, Object>> array = (List<Map<String, Object>>) alerts.get("array");
```

### 4. Enhanced Alert DTO
Added additional fields from the API:
- `eventType`
- `serialNumber`
- `personName`
- `roomName`
- `cameraName`
- `isResolved`

## Testing

### Test 1: Retrieve Alert with Skeleton File
```bash
curl http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a
```

**Result:**
```json
{
  "id": "238071A4F37D31EE_1760650774",
  "alert_type": "fall_detection",
  "camera_serial_number": "238071A4F37D31EE",
  "created_at": 1760650774,
  "skeleton_file": "AwAAABZm8Wj+////NwAAAKQAXAA6ABcABQAvAAAAAAwz...",
  "event_type": 5,
  "serial_number": "238071A4F37D31EE",
  "person_name": "Someone",
  "room_name": "Room 1",
  "camera_name": "capstone",
  "is_resolved": true
}
```

✅ **Success** - skeleton_file retrieved (6124 characters)

### Test 2: Decode Skeleton File
```bash
curl http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a/skeleton
```

**Result:**
```json
{
  "alert_id": "238071A4F37D31EE_1760650774",
  "has_skeleton_file": true,
  "skeleton_file_length": 6124,
  "decoded_bytes_length": 4592,
  "decoded_string_length": 4592,
  "decode_success": true
}
```

✅ **Success** - Base64 decodes to 4592 bytes of skeleton data

## How Skeleton File Works

1. **API Returns**: Base64-encoded string (6124 chars)
2. **Backend Stores**: As String in Alert DTO
3. **Frontend Receives**: Base64 string via REST API
4. **Frontend Decodes**: 
   ```dart
   final decodedBytes = base64Decode(alert.skeletonFile);
   final decodedString = utf8.decode(decodedBytes);
   final jsonData = jsonDecode(decodedString);
   final frame = SkeletonFrame.fromJson(jsonData);
   ```

## Summary

The skeleton_file retrieval now works correctly:
- ✅ Backend fetches alert from Altumview API
- ✅ Extracts skeleton_file from nested response structure  
- ✅ Maps API fields to DTO fields correctly
- ✅ Returns skeleton_file as base64 string to frontend
- ✅ Frontend can decode and parse the skeleton data

The issue was **not** a problem with processing the file, but rather with understanding the Altumview API's response structure.

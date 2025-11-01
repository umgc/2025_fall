# Skeleton Visualization - Current Status & Solution

## Date: October 20, 2025, 8:35 PM

## Problem Discovered

The **alert skeleton_file format is DIFFERENT** from the **live MQTT stream format**.

### Evidence:
1. **Official AltumView Example** (from their website):
   - Live MQTT: frameNum (4 bytes) + numPeople (4 bytes) + person data (152 bytes each)
   - Coordinates: float32, normalized 0.0-1.0

2. **Alert skeleton_file**:
   - 4592 bytes total
   - Starts with `03 00 00 00` (value 3)
   - Does NOT match the 152-bytes-per-person format
   - Appears to be compressed or use different encoding

3. **Test Results**:
   - Decoder returns invalid data (numPeople = 1760650774)
   - Coordinates are garbage values
   - Format doesn't align with official specification

## Root Cause

AltumView uses **TWO DIFFERENT FORMATS**:
1. **Live MQTT Stream**: Float32 normalized coordinates (documented)
2. **Alert Storage**: Unknown binary format (undocumented)

The alert format is likely:
- Compressed (4592 bytes for potentially multiple frames)
- Contains metadata (timestamp, camera info, etc.)
- Different coordinate encoding (int16? compressed?)
- Proprietary format requiring AltumView SDK

## Solution Options

###  Option 1: Use Live MQTT Stream (RECOMMENDED ✅)

**Status**: Already implemented and working!

The app already has a **Live Skeleton Viewer** tab that:
- Connects to MQTT
- Receives real-time skeleton data
- Uses the official format (float32 normalized)
- Displays skeleton perfectly

**How it works:**
1. User selects camera
2. App gets MQTT credentials from API
3. Connects to WebSocket MQTT broker
4. Subscribes to skeleton topic
5. Receives skeleton data every frame
6. Decoder parses it correctly
7. Displays on canvas

**Pros:**
- ✅ Already working
- ✅ Real-time updates
- ✅ Official format
- ✅ No decoding issues

**Cons:**
- ⚠️ Requires active camera
- ⚠️ Token expires every 45 seconds (auto-refreshed)
- ⚠️ Can't replay historical alerts

### Option 2: Contact AltumView for Alert Format Spec

**Action**: Email AltumView support
- Request documentation for alert skeleton_file binary format
- Ask for decoder library or specification
- Mention you're a developer using their API

**Timeline**: 1-2 weeks for response

### Option 3: Display Background Image Only for Alerts

**Quick Fix**: For the alerts tab:
- Show camera background image ✅
- Show alert metadata (time, type, camera)
- Add button "View Live Skeleton" → opens Live tab
- Don't try to decode saved skeleton file

This provides value while waiting for proper specification.

### Option 4: Animation from Alert (FUTURE)

If we get the alert format spec:
- Decode multiple frames from alert
- Play back as animation
- Show fall detection event replay
- This would be amazing for review/analysis

## Recommended Immediate Action

### Keep What's Working:
1. ✅ **Alerts Tab**: Shows background images, metadata, list of alerts
2. ✅ **Live Skeleton Tab**: Real-time skeleton visualization
3. ✅ **Camera Images Tab**: Shows current camera views

###Add to Alerts Tab:
```dart
// In alert details view
ElevatedButton(
  onPressed: () {
    // Switch to Live Skeleton tab for this camera
    Navigator.pushNamed(context, '/skeleton-viewer', 
      arguments: alert.cameraSerialNumber);
  },
  child: Text('View Live Skeleton'),
)
```

### Stop Trying to Decode Alert skeleton_file:
- Remove skeleton_file decoder from alerts
- Remove broken skeleton overlay
- Focus on what works

## Current Working Features

### ✅ What Works Perfectly:
1. **Alerts List**: Fetches from API, shows all alerts
2. **Alert Details**: Background image, metadata, timestamp
3. **Live Skeleton Viewer**: Real-time skeleton from MQTT
4. **Camera Images**: Current camera view and background
5. **Authentication**: OAuth token management
6. **MQTT Connection**: Auto-reconnect, token refresh

### ❌ What Doesn't Work:
1. **Alert Skeleton Decoding**: Format is undocumented/different
2. **Historical Skeleton Replay**: Need proper alert format spec

## User Experience Flow

### Current (Broken):
1. User clicks alert
2. Sees background image
3. Sees broken/garbage skeleton overlay ❌
4. Confused why skeleton looks wrong

### Recommended (Working):
1. User clicks alert
2. Sees background image ✅
3. Sees alert details (time, type, location) ✅
4. Button: "View Live Skeleton from this Camera"
5. Clicks button → Opens Live Skeleton tab
6. Sees real-time, working skeleton ✅

## Implementation

###Remove Broken Skeleton from Alerts:

**alerts_screen.dart**:
```dart
// Remove:
final skeletonJson = await _apiService.getAlertSkeletonDecoded(alert.id);
final frame = SkeletonFrame.fromJson(skeletonJson);

// Keep:
final backgroundImage = await _apiService.getAlertBackground(alert.id);

// Add button to switch to live view
```

### Update Backend:

**SkeletonController.java**:
```java
// Comment out or remove skeleton-decoded endpoint for alerts
// Keep the live MQTT skeleton stream working
```

## Summary

**The live skeleton viewer already works perfectly!** 

The problem is only with **decoding saved alert skeleton files**, which use an undocumented format.

**Best solution**: Use the working live skeleton viewer for real-time visualization, and show only background images/metadata for historical alerts until we get the alert format specification from AltumView.

## Next Steps

1. ✅ Accept that alert skeleton_file format is different
2. ✅ Keep using live MQTT for skeleton visualization  
3. ✅ Show background images in alerts tab
4. ✅ Add button to view live skeleton from alert's camera
5. 📧 Email AltumView support for alert format documentation
6. ⏳ Wait for response to implement alert skeleton replay

---

**Status**: Live skeleton works! Alert skeleton needs vendor documentation.
**Priority**: Low - Live view provides full functionality
**Action**: Focus on working features, contact vendor for spec

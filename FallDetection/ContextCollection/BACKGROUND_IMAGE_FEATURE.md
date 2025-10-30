# Background Image Display - Complete ✅

## Feature Added
Display alert background image with skeleton overlay visualization.

## What Changed

### 1. Alert Model - Added Background URL
**File:** `/Frontend/lib/models/alert.dart`

```dart
class Alert {
  final String id;
  final String alertType;
  final String cameraSerialNumber;
  final int createdAt;
  final String? skeletonFile;
  final String? backgroundUrl;  // ✅ NEW
  
  Alert({
    required this.id,
    required this.alertType,
    required this.cameraSerialNumber,
    required this.createdAt,
    this.skeletonFile,
    this.backgroundUrl,  // ✅ NEW
  });
  
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      alertType: json['alert_type'],
      cameraSerialNumber: json['camera_serial_number'],
      createdAt: json['created_at'],
      skeletonFile: json['skeleton_file'],
      backgroundUrl: json['background_url'],  // ✅ NEW
    );
  }
}
```

### 2. Alerts Screen - Background Image with Skeleton Overlay
**File:** `/Frontend/lib/screens/alerts_screen.dart`

Added a Stack widget that layers:
1. **Background Image** - From `alert.backgroundUrl` (S3 signed URL)
2. **Skeleton Overlay** - Drawn on top using CustomPaint
3. **Legend** - Info box showing keypoints and skeleton colors

```dart
Stack(
  fit: StackFit.expand,
  children: [
    // 1. Background image
    if (_selectedAlert?.backgroundUrl != null)
      Image.network(
        _selectedAlert!.backgroundUrl!,
        fit: BoxFit.contain,
        loadingBuilder: ...,
        errorBuilder: ...,
      ),
    
    // 2. Skeleton overlay
    CustomPaint(
      painter: SkeletonPainter(_skeletonFrame!),
      size: Size.infinite,
    ),
    
    // 3. Legend overlay
    Positioned(
      top: 16,
      right: 16,
      child: Container(...),
    ),
  ],
)
```

## UI Components

### Background Image
- Fetched from AltumView S3 bucket (pre-signed URL)
- Displays with `fit: BoxFit.contain` to maintain aspect ratio
- Shows loading indicator while downloading
- Falls back to broken image icon if fails

### Skeleton Overlay
- Drawn on top of background image
- Green lines connecting joints
- Red dots for keypoints
- Automatically scales to fit canvas

### Legend Box
- Semi-transparent black background
- Shows:
  - 🔴 Red dots = Keypoints
  - 🟢 Green lines = Skeleton
  - 🖼️ Image icon = Background present

## Data Flow

```
AltumView API Alert
    ↓
{
  "id": "68f166168eeae9e50d48e58a",
  "background_url": "https://s3.amazonaws.com/...",
  "skeleton_file": "base64..."
}
    ↓
Backend preserves background_url
    ↓
Frontend Alert model
    ↓
Stack widget renders:
  1. Background Image.network()
  2. CustomPaint(SkeletonPainter)
  3. Legend overlay
```

## Visual Result

```
┌─────────────────────────────────────┐
│  [Legend]                           │
│  🔴 Keypoints                       │
│  🟢 Skeleton                        │
│  🖼️ Background                      │
│                                     │
│   [Background Camera Image]         │
│                                     │
│      ●←─ Skeleton overlaid          │
│     ╱│╲   on actual scene           │
│    ● │ ●                            │
│      │                              │
│   ●──┼──●                           │
│    ╲ │ ╱                            │
│     ╲│╱                             │
│      ●                              │
│                                     │
└─────────────────────────────────────┘
```

## Features

### ✅ Implemented
- Background image display from S3 URL
- Skeleton overlay visualization
- Loading states (spinner while image loads)
- Error handling (broken image icon)
- Legend showing what each color means
- Proper layering (image → skeleton → legend)

### 🎨 Styling
- Black background for better contrast
- Rounded corners with border
- Semi-transparent legend box
- Responsive sizing (fits container)

### 🛡️ Error Handling
- Handles missing background_url gracefully
- Shows fallback grey background if no image
- Displays broken image icon on load failure
- Loading progress indicator

## Testing

### Test Background Image Display
1. Run Flutter app
2. Navigate to Alerts screen
3. Click on test alert `68f166168eeae9e50d48e58a`
4. Should see:
   - Camera background image from S3
   - Skeleton overlaid on top (green lines, red dots)
   - Legend in top-right corner

### Verify Data
```bash
curl -s http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a | jq '.background_url'
```

Should return S3 URL like:
```
"https://cypress-prod-backgroundimage.s3.us-west-2.amazonaws.com/..."
```

## Known Limitations

### Coordinate Mismatch
The mock skeleton coordinates are absolute pixels that may not match the camera resolution. This is expected since we're using mock data.

**For Real Data:** When real skeleton binary is decoded, coordinates should match the camera's image dimensions, allowing perfect overlay alignment.

### S3 URL Expiration
The background_url contains a pre-signed S3 URL with an expiration timestamp (`Expires` parameter). URLs typically expire after 24-48 hours.

**Solution:** If image fails to load, refresh the alert to get a new signed URL.

## Future Enhancements

### 1. Video Playback
Add video player for alert clips (see `VIDEO_IMPLEMENTATION_PLAN.md`)

```dart
// TODO: Replace Image.network with VideoPlayer
if (alert.videoUrl != null) {
  VideoPlayer(controller: _videoController)
}
```

### 2. Timeline Scrubbing
If alert has video, add timeline to scrub through frames

### 3. Zoom/Pan
Add gesture detection for zooming into specific body parts

### 4. Compare Mode
Show before/after or multiple timestamps side-by-side

## Files Modified
- `/Frontend/lib/models/alert.dart` - Added `backgroundUrl` field
- `/Frontend/lib/screens/alerts_screen.dart` - Added Stack with image + skeleton

## Status
✅ **Complete** - Background image displays with skeleton overlay

---

**Date:** October 20, 2025  
**Feature:** Alert Background Image Display  
**Status:** Fully Functional ✅

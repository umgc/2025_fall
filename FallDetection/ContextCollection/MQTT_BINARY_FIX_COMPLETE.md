# MQTT Binary Format Fix - COMPLETE ✅

## Problem
The live skeleton viewer was failing to parse binary data from the MQTT stream, resulting in invalid skeleton coordinates and errors.

## Root Cause
The Flutter `mqtt_service.dart` was using the **wrong binary format** for parsing skeleton data:

### ❌ **OLD (Incorrect) Format**:
```dart
// Read number of people (1 byte) - WRONG!
final numPeople = byteData.getUint8(offset);
offset += 1;

// Read keypoints directly - WRONG!
for (int j = 0; j < 18; j++) {
  final x = byteData.getFloat32(offset, Endian.little);
  final y = byteData.getFloat32(offset, Endian.little);
}
```

**Problems**:
- Missing frame number (4 bytes)
- `numPeople` read as 1 byte instead of 4 bytes (int32)
- Missing person ID field
- X and Y coordinates not separated properly
- Missing padding bytes

### ✅ **NEW (Correct) Format**:
```dart
// Read frame number (4 bytes, int32)
final frameNum = byteData.getInt32(offset, Endian.little);
offset += 4;

// Read number of people (4 bytes, int32)
final numPeople = byteData.getInt32(offset, Endian.little);
offset += 4;

// For each person (152 bytes):
for (int i = 0; i < numPeople; i++) {
  // Person ID (4 bytes)
  final personId = byteData.getInt32(offset, Endian.little);
  offset += 4;
  
  // X coordinates (18 × float32 = 72 bytes)
  List<double> xCoords = [];
  for (int j = 0; j < 18; j++) {
    xCoords.add(byteData.getFloat32(offset, Endian.little));
    offset += 4;
  }
  
  // Y coordinates (18 × float32 = 72 bytes)
  List<double> yCoords = [];
  for (int j = 0; j < 18; j++) {
    yCoords.add(byteData.getFloat32(offset, Endian.little));
    offset += 4;
  }
  
  // Skip padding (4 bytes)
  offset += 4;
}
```

## Official AltumView MQTT Binary Format

### Stream Structure:
```
Header (8 bytes):
├─ Frame Number: int32 (4 bytes)
└─ Number of People: int32 (4 bytes)

For each person (152 bytes):
├─ Person ID: int32 (4 bytes)
├─ X Coordinates: 18 × float32 (72 bytes)
├─ Y Coordinates: 18 × float32 (72 bytes)
└─ Padding: 4 bytes
```

### Total Size Formula:
```
Total = 8 + (numPeople × 152) bytes
```

**Examples**:
- 0 people: 8 bytes
- 1 person: 8 + 152 = 160 bytes
- 2 people: 8 + 304 = 312 bytes

## Changes Made

### File: `/Frontend/lib/services/mqtt_service.dart`

**Updated `_parseSkeletonData()` method**:

1. ✅ Added frame number parsing (int32, 4 bytes)
2. ✅ Fixed numPeople to int32 (was uint8)
3. ✅ Added person ID parsing (int32, 4 bytes)
4. ✅ Separated X and Y coordinate arrays
5. ✅ Added 4-byte padding after each person
6. ✅ Added data validation (size checks, sanity checks)
7. ✅ Enhanced logging with frame numbers and person IDs
8. ✅ Added error handling with stack traces

### Key Improvements:

#### 1. Data Validation
```dart
// Minimum size check
if (bytes.length < 8) {
  print('⚠️ Skeleton data too small: ${bytes.length} bytes');
  return;
}

// Sanity check for suspicious data
if (numPeople > 10) {
  print('⚠️ Suspicious numPeople: $numPeople (ignoring frame)');
  return;
}

// Expected size validation
final expectedSize = 8 + (numPeople * 152);
if (bytes.length < expectedSize) {
  print('⚠️ Data too small: ${bytes.length} bytes, expected $expectedSize');
  return;
}
```

#### 2. Enhanced Logging
```dart
print('📦 Frame $frameNum: $numPeople person(s), ${bytes.length} bytes');
print('  Person $personId: ${keypointsVisible}/18 keypoints visible');
```

#### 3. Proper Error Handling
```dart
catch (e, stackTrace) {
  print('❌ Error parsing skeleton data: $e');
  print('Stack trace: $stackTrace');
}
```

## About the JavaScript Code

The JavaScript Paho MQTT code you provided is **for web browsers** using the Eclipse Paho JavaScript library. It's not directly applicable to Flutter because:

1. **Different Language**: JavaScript vs. Dart
2. **Different MQTT Library**: Paho MQTT (JS) vs. mqtt_client (Dart)
3. **Different API**: JS uses property setters (`client.onMessageArrived = function`), Dart uses streams
4. **Different Platform**: Browser WebSocket vs. Flutter WebSocket

However, the **binary parsing functions** in that JavaScript code (`_deframeMessages`, `_parseSkeletonData`) confirm the format we're now using!

### JavaScript Binary Parsing (for reference):
```javascript
// From the Paho MQTT code:
var frameNum = int32 at offset 0
var numPeople = int32 at offset 4

// For each person:
var personId = int32
var xCoords = 18 × float32
var yCoords = 18 × float32
var padding = 4 bytes
```

This matches exactly what we implemented in Dart! ✅

## Testing the Fix

### Expected Console Output:
```
🔄 Connecting to MQTT broker...
✓ MQTT connection successful!
✓ Connected to MQTT
✓ Subscribed to skeleton/camera/SERIALNUM
→ Published stream token
📦 Frame 1234: 1 person(s), 160 bytes
  Person 42: 15/18 keypoints visible
📦 Frame 1235: 1 person(s), 160 bytes
  Person 42: 16/18 keypoints visible
```

### What to Look For:
1. ✅ Frame numbers incrementing
2. ✅ Reasonable numPeople (0-10)
3. ✅ Correct byte sizes (160, 312, 464, etc.)
4. ✅ Person IDs consistent
5. ✅ Keypoint counts make sense (0-18)
6. ✅ No parsing errors

### Common Issues (Now Fixed):
- ❌ `numPeople = 1760650774` → Now validates as suspicious
- ❌ `coordinates = 8.449e-39` → Now properly parsed as normalized 0-1
- ❌ `RangeError: Index out of bounds` → Now checks buffer size

## How to Test

1. **Run the Flutter app**:
   ```bash
   cd Frontend
   flutter run -d macos
   ```

2. **Navigate to Live Skeleton Viewer**

3. **Select a camera and click "Connect"**

4. **Watch the console output**:
   - Should see frame numbers
   - Should see person detections
   - Should see skeleton rendering

5. **Check the display**:
   - Stick figure should appear
   - Should update in real-time
   - Coordinates should be 0.0-1.0 (normalized)

## Architecture

### Data Flow:
```
MQTT Broker (AltumView)
    ↓
WebSocket Binary Stream
    ↓
mqtt_client package (Flutter)
    ↓
MqttService._parseSkeletonData()
    ↓
Parse binary format:
  - frameNum (int32)
  - numPeople (int32)
  - For each person:
    - personId (int32)
    - xCoords[] (18 × float32)
    - yCoords[] (18 × float32)
    - padding (4 bytes)
    ↓
SkeletonFrame object
    ↓
Stream to UI
    ↓
SkeletonPainter
    ↓
Animated stick figure display
```

## Files Modified

1. **Frontend/lib/services/mqtt_service.dart**
   - Fixed `_parseSkeletonData()` method
   - Added proper binary format parsing
   - Added validation and logging

## Status: ✅ READY TO TEST

The MQTT binary parsing is now fixed and matches the official AltumView format. The live skeleton viewer should now work correctly.

## Next Steps

1. ✅ Code fixed and compiled
2. 🔄 **USER TO TEST**: Run app and verify live skeleton works
3. ⏳ If still issues, check MQTT credentials/tokens
4. ⏳ If skeleton doesn't render, check SkeletonPainter

## Related Files
- `Frontend/lib/services/mqtt_service.dart` - MQTT parsing (FIXED)
- `Frontend/lib/widgets/skeleton_painter.dart` - Rendering (already correct)
- `Frontend/lib/screens/skeleton_viewer_screen.dart` - UI (no changes needed)
- `SKELETON_FORMAT_ANALYSIS.md` - Format documentation

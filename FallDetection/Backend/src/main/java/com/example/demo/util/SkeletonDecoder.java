package com.example.demo.util;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;

/**
 * Decoder for AltumView MQTT skeleton binary format
 * Based on the MQTT protocol specification from the Flutter MQTT service
 */
public class SkeletonDecoder {
    
    /**
     * Decode binary skeleton data with MULTIPLE FRAMES to JSON format
     * 
     * Alert skeleton files contain multiple consecutive frames (e.g., 54 frames = ~2 seconds of video).
     * Each frame has the same binary format:
     * - frameNum (int32, 4 bytes at offset 0)
     * - numPeople (int32, 4 bytes at offset 4)
     * - For each person (152 bytes):
     *   - personId (int32, 4 bytes)
     *   - 18 X coordinates (float32, 72 bytes) - NORMALIZED 0.0-1.0
     *   - 18 Y coordinates (float32, 72 bytes) - NORMALIZED 0.0-1.0
     *   - padding (4 bytes)
     * 
     * @param base64Data Base64-encoded binary skeleton data (may contain multiple frames)
     * @return Map with "frames" array, each containing "frameNum", "people", etc.
     */
    public static Map<String, Object> decode(String base64Data) {
        try {
            // Decode base64
            byte[] binaryData = Base64.getDecoder().decode(base64Data);
            
            System.out.println("🔍 SkeletonDecoder: Decoding " + binaryData.length + " bytes");
            
            // Print first 32 bytes for debugging
            System.out.print("First 32 bytes (hex): ");
            for (int i = 0; i < Math.min(32, binaryData.length); i++) {
                System.out.printf("%02x ", binaryData[i] & 0xFF);
            }
            System.out.println();
            
            // Try to detect format by reading first 12 bytes as different types
            ByteBuffer testBuffer = ByteBuffer.wrap(binaryData);
            testBuffer.order(ByteOrder.LITTLE_ENDIAN);
            System.out.println("Byte 0-3 as int32: " + testBuffer.getInt(0));
            System.out.println("Byte 4-7 as int32: " + testBuffer.getInt(4));
            System.out.println("Byte 8-11 as int32: " + testBuffer.getInt(8));
            System.out.println("Byte 16-17 as int16: " + testBuffer.getShort(16));
            System.out.println("Byte 18-19 as int16: " + testBuffer.getShort(18));
            
            List<Map<String, Object>> frames = new ArrayList<>();
            int offset = 0;
            int frameCount = 0;
            
            // Parse all frames in the data
            while (offset + 8 <= binaryData.length) {
                System.out.println("📦 Attempting to decode frame " + (frameCount + 1) + " at offset " + offset);
                
                Map<String, Object> frame = decodeSingleFrame(binaryData, offset);
                if (frame == null) {
                    System.out.println("❌ Frame " + (frameCount + 1) + " returned null, stopping");
                    break; // Invalid frame, stop parsing
                }
                
                frames.add(frame);
                frameCount++;
                
                // Calculate next frame offset
                int numPeople = (int) frame.get("numPeople");
                int frameSize = 8 + (numPeople * 152);
                System.out.println("✅ Frame " + frameCount + ": " + numPeople + " people, size " + frameSize + " bytes");
                offset += frameSize;
            }
            
            System.out.println("🎬 Total frames decoded: " + frames.size());
            
            Map<String, Object> result = new HashMap<>();
            result.put("totalFrames", frames.size());
            result.put("frames", frames);
            
            // For backward compatibility, also return the first frame's data at the root level
            if (!frames.isEmpty()) {
                Map<String, Object> firstFrame = frames.get(0);
                result.put("frameNum", firstFrame.get("frameNum"));
                result.put("numPeople", firstFrame.get("numPeople"));
                result.put("people", firstFrame.get("people"));
            } else {
                result.put("frameNum", 0);
                result.put("numPeople", 0);
                result.put("people", new ArrayList<>());
            }
            
            return result;
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to decode skeleton data: " + e.getMessage(), e);
        }
    }
    
    /**
     * Decode a single frame from binary data at a specific offset
     * 
     * @param binaryData The complete binary data
     * @param offset Starting offset for this frame
     * @return Map with frame data, or null if invalid
     */
    private static Map<String, Object> decodeSingleFrame(byte[] binaryData, int offset) {
        try {
            // Check if we have enough data for header
            if (offset + 8 > binaryData.length) {
                System.out.println("⚠️ Not enough data for header at offset " + offset);
                return null;
            }
            
            ByteBuffer buffer = ByteBuffer.wrap(binaryData);
            buffer.order(ByteOrder.LITTLE_ENDIAN);
            
            // Read frame number (at offset)
            buffer.position(offset);
            int frameNum = buffer.getInt();
            
            // Read number of people (at offset + 4)
            int numPeople = buffer.getInt();
            
            System.out.println("   Frame #" + frameNum + " claims " + numPeople + " people");
            
            // Sanity check
            if (numPeople < 0 || numPeople > 20) {
                System.out.println("⚠️ Invalid numPeople: " + numPeople + " (must be 0-20)");
                return null; // Invalid data
            }
            
            // Check if we have enough data for this frame
            int requiredSize = offset + 8 + (numPeople * 152);
            if (requiredSize > binaryData.length) {
                System.out.println("⚠️ Not enough data: need " + requiredSize + " bytes, have " + binaryData.length);
                return null;
            }
            
            List<List<List<Double>>> people = new ArrayList<>();
            List<Integer> personIds = new ArrayList<>();
            
            if (numPeople == 0) {
                Map<String, Object> result = new HashMap<>();
                result.put("frameNum", frameNum);
                result.put("numPeople", 0);
                result.put("personIds", personIds);
                result.put("people", people);
                return result;
            }
            
            // Parse each person (152 bytes each, starting at offset + 8)
            for (int i = 0; i < numPeople; i++) {
                int personPos = offset + 8 + (152 * i);
                
                // Check if we have enough data
                if (personPos + 152 > binaryData.length) {
                    break;
                }
                
                // Read person ID
                buffer.position(personPos);
                int personId = buffer.getInt();
                personIds.add(personId);
                
                // Read X coordinates (18 floats starting at personPos + 4)
                float[] xCoords = new float[18];
                buffer.position(personPos + 4);
                for (int j = 0; j < 18; j++) {
                    xCoords[j] = buffer.getFloat();
                }
                
                // Read Y coordinates (18 floats starting at personPos + 76)
                // 76 = 4 (personId) + 72 (18 floats * 4 bytes)
                float[] yCoords = new float[18];
                buffer.position(personPos + 76);
                for (int j = 0; j < 18; j++) {
                    yCoords[j] = buffer.getFloat();
                }
                
                // Create keypoints array
                List<List<Double>> keypoints = new ArrayList<>();
                for (int j = 0; j < 18; j++) {
                    // Coordinates are already normalized 0.0-1.0
                    // Include all keypoints, even if zero (frontend will handle)
                    keypoints.add(Arrays.asList((double) xCoords[j], (double) yCoords[j]));
                }
                
                people.add(keypoints);
            }
            
            Map<String, Object> result = new HashMap<>();
            result.put("frameNum", frameNum);
            result.put("numPeople", numPeople);
            result.put("personIds", personIds);
            result.put("people", people);
            
            return result;
            
        } catch (Exception e) {
            return null; // Return null on error instead of throwing
        }
    }
    
    /**
     * Get keypoint names for OpenPose 18-point format
     */
    public static List<String> getKeypointNames() {
        return Arrays.asList(
            "Nose",           // 0
            "Neck",           // 1
            "RShoulder",      // 2
            "RElbow",         // 3
            "RWrist",         // 4
            "LShoulder",      // 5
            "LElbow",         // 6
            "LWrist",         // 7
            "RHip",           // 8
            "RKnee",          // 9
            "RAnkle",         // 10
            "LHip",           // 11
            "LKnee",          // 12
            "LAnkle",         // 13
            "REye",           // 14
            "LEye",           // 15
            "REar",           // 16
            "LEar"            // 17
        );
    }
}

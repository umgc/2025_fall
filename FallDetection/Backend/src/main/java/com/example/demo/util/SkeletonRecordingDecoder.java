package com.example.demo.util;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;

public class SkeletonRecordingDecoder {
    
    public static Map<String, Object> decode(String base64Data) {
        try {
            byte[] binaryData = Base64.getDecoder().decode(base64Data);
            System.out.println("🎬 Decoding " + binaryData.length + " bytes");
            
            ByteBuffer buffer = ByteBuffer.wrap(binaryData);
            buffer.order(ByteOrder.LITTLE_ENDIAN);
            
            // Read version from first 4 bytes
            int version = buffer.getInt();
            System.out.println("📋 Version: " + version);
            
            if (version != 3) {
                System.out.println("⚠️ Unsupported version: " + version);
                return createEmptyResult();
            }
            
            // Skip to byte 16 to read frame dimensions
            buffer.position(16);
            int width = buffer.getShort() & 0xFFFF;
            int height = buffer.getShort() & 0xFFFF;
            System.out.println("📐 Dimensions: " + width + "x" + height);
            
            // Skip to byte 26 to read number of frames
            buffer.position(26);
            int numFrames = buffer.getShort() & 0xFFFF;
            System.out.println("📹 Total frames: " + numFrames);
            
            if (numFrames <= 0) {
                System.out.println("⚠️ No frames to decode");
                return createEmptyResult();
            }
            
            // Start parsing frames from byte 28 (using curIndex like HTML demo)
            int curIndex = 28;
            List<Map<String, Object>> frames = new ArrayList<>();
            int epochTime = 0;
            
            // Loop through each frame and extract keypoint data
            for (int i = 0; i < numFrames; i++) {
                if (curIndex + 21 > binaryData.length) break; // Need at least 21 bytes for frame header
                
                // Frame timing and action info (following HTML demo exactly)
                buffer.position(curIndex);
                epochTime = buffer.getShort() & 0xFFFF;  // Read 2 bytes
                curIndex += 3;  // Skip 3 bytes total (like HTML: curIndex += 3)
                
                buffer.position(curIndex);
                int numParts = buffer.get() & 0xFF;      // Read numParts (1 byte)
                curIndex += 17; // Skip 17 more bytes (like HTML: curIndex += 17)
                
                System.out.println("📹 Frame " + i + ": epochTime=" + epochTime + ", numParts=" + numParts + ", curIndex=" + curIndex);
                
                if (numParts > 25) {
                    System.out.println("⚠️ Frame " + i + " claims " + numParts + " parts (too many), skipping");
                    break;
                }
                
                if (curIndex + (numParts * 6) > binaryData.length) {
                    System.out.println("⚠️ Not enough data for " + numParts + " parts, stopping");
                    break;
                }
                
                // Initialize keypoints array with null/undefined values
                Map<Integer, Map<String, Integer>> keypoints = new HashMap<>();
                
                // Read all keypoints for this frame
                for (int j = 0; j < numParts; j++) {
                    buffer.position(curIndex);
                    
                    int index = buffer.get() & 0xFF;
                    curIndex += 2; // Skip index + probability (like HTML: curIndex += 2)
                    
                    buffer.position(curIndex);
                    int xCoord = buffer.getShort() & 0xFFFF;
                    curIndex += 2;
                    
                    buffer.position(curIndex);
                    int yCoord = buffer.getShort() & 0xFFFF;
                    curIndex += 2;
                    
                    Map<String, Integer> point = new HashMap<>();
                    point.put("x", xCoord);
                    point.put("y", yCoord);
                    keypoints.put(index, point);
                }
                
                Map<String, Object> frame = new HashMap<>();
                frame.put("frameNum", i);
                frame.put("epochTime", epochTime);
                frame.put("numParts", numParts);
                frame.put("keypoints", keypoints);
                frames.add(frame);
                
                System.out.println("📍 End of frame " + i + ", curIndex=" + curIndex + ", remaining=" + (binaryData.length - curIndex));
            }
            
            System.out.println("✅ Decoded " + frames.size() + " frames");
            
            Map<String, Object> result = new HashMap<>();
            result.put("totalFrames", frames.size());
            result.put("frames", frames);
            result.put("width", width);
            result.put("height", height);
            result.put("epochTime", epochTime);
            result.put("numFrames", numFrames);
            
            // Backward compatibility: include first frame data at top level
            if (!frames.isEmpty()) {
                Map<String, Object> first = frames.get(0);
                result.put("frameNum", 0);
                result.put("numParts", first.get("numParts"));
                result.put("keypoints", first.get("keypoints"));
            } else {
                result.put("frameNum", 0);
                result.put("numParts", 0);
                result.put("keypoints", new HashMap<>());
            }
            
            return result;
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
            return createEmptyResult();
        }
    }
    
    private static Map<String, Object> createEmptyResult() {
        Map<String, Object> result = new HashMap<>();
        result.put("totalFrames", 0);
        result.put("frames", new ArrayList<>());
        result.put("frameNum", 0);
        result.put("numParts", 0);
        result.put("keypoints", new HashMap<>());
        result.put("width", 0);
        result.put("height", 0);
        result.put("epochTime", 0);
        result.put("numFrames", 0);
        return result;
    }
}

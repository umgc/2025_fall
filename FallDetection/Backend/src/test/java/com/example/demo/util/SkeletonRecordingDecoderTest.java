package com.example.demo.util;

import org.junit.jupiter.api.Test;
import java.util.Map;

public class SkeletonRecordingDecoderTest {
    
    @Test
    public void testSampleSkeletonData() {
        // Sample skeleton data from the working HTML demo
        String sampleBase64 = "<Test your actual base64-encoded skeleton data here>";
        
        System.out.println("Testing SkeletonRecordingDecoder with sample data...");
        
        Map<String, Object> result = SkeletonRecordingDecoder.decode(sampleBase64);
        
        System.out.println("Result keys: " + result.keySet());
        System.out.println("Total frames: " + result.get("totalFrames"));
        System.out.println("Width: " + result.get("width"));
        System.out.println("Height: " + result.get("height"));
        System.out.println("Epoch time: " + result.get("epochTime"));
        System.out.println("Num frames: " + result.get("numFrames"));
        
        if (result.get("frames") instanceof java.util.List) {
            java.util.List<?> frames = (java.util.List<?>) result.get("frames");
            System.out.println("Frames array length: " + frames.size());
            
            if (!frames.isEmpty()) {
                Object firstFrame = frames.get(0);
                System.out.println("First frame: " + firstFrame);
                
                if (frames.size() > 1) {
                    Object secondFrame = frames.get(1);
                    System.out.println("Second frame: " + secondFrame);
                }
            }
        }
        
        // Debug: Let's examine the raw binary data around frame boundaries
        byte[] binaryData = java.util.Base64.getDecoder().decode(sampleBase64);
        System.out.println("Binary data length: " + binaryData.length);
        System.out.println("First 50 bytes: " + java.util.Arrays.toString(java.util.Arrays.copyOfRange(binaryData, 0, Math.min(50, binaryData.length))));
        System.out.println("Bytes 28-78 (frame area): " + java.util.Arrays.toString(java.util.Arrays.copyOfRange(binaryData, 28, Math.min(78, binaryData.length))));
    }
}

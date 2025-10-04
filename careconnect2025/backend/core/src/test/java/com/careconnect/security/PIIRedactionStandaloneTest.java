package com.careconnect.security;

import com.careconnect.service.PIIRedactionService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Standalone test for PII redaction functionality that doesn't require Spring context.
 * This test verifies the core redaction logic works correctly.
 */
public class PIIRedactionStandaloneTest {

    private PIIRedactionService piiRedactionService;

    @BeforeEach
    void setUp() {
        ObjectMapper objectMapper = new ObjectMapper();
        piiRedactionService = new PIIRedactionService(objectMapper);
    }

    @Test
    void testBasicSSNRedaction() {
        String input = "Patient SSN is 123-45-6789";
        String result = piiRedactionService.redactString(input, PIIType.SSN);

        System.out.println("Input: " + input);
        System.out.println("Output: " + result);

        assertFalse(result.contains("123-45-6789"));
        assertTrue(result.contains("XXX-XX-XXXX"));
    }

    @Test
    void testEmailRedaction() {
        String input = "Contact: john.doe@hospital.com";
        String result = piiRedactionService.redactString(input, PIIType.EMAIL);

        System.out.println("Input: " + input);
        System.out.println("Output: " + result);

        assertFalse(result.contains("john.doe@hospital.com"));
        assertTrue(result.contains("[EMAIL_REDACTED]"));
    }

    @Test
    void testPhoneRedaction() {
        String input = "Call patient at (555) 123-4567";
        String result = piiRedactionService.redactString(input, PIIType.PHONE);

        System.out.println("Input: " + input);
        System.out.println("Output: " + result);

        assertFalse(result.contains("555") && result.contains("123") && result.contains("4567"));
        assertTrue(result.contains("XXX-XXX-XXXX"));
    }

    @Test
    void testMedicalDataRedaction() {
        String input = "Patient John Smith, MRN: MED123456, diagnosed with diabetes";
        String result = piiRedactionService.redactMedicalData(input);

        System.out.println("Input: " + input);
        System.out.println("Output: " + result);

        // Should redact name and medical ID
        assertFalse(result.contains("John Smith"));
        assertFalse(result.contains("MED123456"));
    }

    @Test
    void testMultiplePIITypes() {
        String input = "Patient: John Doe, SSN: 123-45-6789, Email: john@example.com, Phone: 555-123-4567";
        String result = piiRedactionService.redactString(input, PIIType.getStandardTypes());

        System.out.println("Input: " + input);
        System.out.println("Output: " + result);

        // Should redact all PII
        assertFalse(result.contains("John Doe"));
        assertFalse(result.contains("123-45-6789"));
        assertFalse(result.contains("john@example.com"));
        assertFalse(result.contains("555-123-4567"));
    }

    @Test
    void testContainsPIIDetection() {
        assertTrue(piiRedactionService.containsPII("SSN: 123-45-6789", PIIType.SSN));
        assertTrue(piiRedactionService.containsPII("Email: test@example.com", PIIType.EMAIL));
        assertFalse(piiRedactionService.containsPII("No sensitive data here"));

        System.out.println("PII Detection tests passed!");
    }

    @Test
    void testJsonRedaction() {
        String json = "{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"ssn\":\"123-45-6789\"}";
        String result = piiRedactionService.redactJsonString(json, PIIType.getStandardTypes());

        System.out.println("Input JSON: " + json);
        System.out.println("Output JSON: " + result);

        // Should not contain original sensitive data
        assertFalse(result.contains("John Doe"));
        assertFalse(result.contains("john@example.com"));
        assertFalse(result.contains("123-45-6789"));
    }

    @Test
    void testLoggingRedaction() {
        String logMessage = "Processing patient John Doe with SSN 123-45-6789 and email john@example.com";
        String result = piiRedactionService.redactForLogging(logMessage);

        System.out.println("Input Log: " + logMessage);
        System.out.println("Output Log: " + result);

        // Should be safe for logging
        assertFalse(result.contains("John Doe"));
        assertFalse(result.contains("123-45-6789"));
        assertFalse(result.contains("john@example.com"));
        assertTrue(result.contains("Processing patient")); // Non-PII should remain
    }

    @Test
    void testHealthcareScenario() {
        String medicalRecord = """
            Patient: Jane Smith
            DOB: 03/15/1975
            SSN: 987-65-4321
            Medical ID: MRN789012
            Email: jane.smith@email.com
            Phone: (555) 987-6543
            Diagnosis: Type 2 Diabetes, Hypertension
            Insurance: Policy ABC123456
            """;

        String redacted = piiRedactionService.redactMedicalData(medicalRecord);

        System.out.println("=== HEALTHCARE SCENARIO TEST ===");
        System.out.println("Original Medical Record:");
        System.out.println(medicalRecord);
        System.out.println("\nRedacted Medical Record:");
        System.out.println(redacted);

        // Verify sensitive data is removed
        assertFalse(redacted.contains("Jane Smith"));
        assertFalse(redacted.contains("03/15/1975"));
        assertFalse(redacted.contains("987-65-4321"));
        assertFalse(redacted.contains("MRN789012"));
        assertFalse(redacted.contains("jane.smith@email.com"));
        assertFalse(redacted.contains("555") && redacted.contains("987") && redacted.contains("6543"));

        // Non-PII medical info might remain (depends on patterns)
        assertTrue(redacted.contains("Patient:") || redacted.contains("["));

        System.out.println("✅ Healthcare scenario test passed!");
    }

    @Test
    void testPerformanceBasic() {
        String testData = "Patient John Doe, SSN: 123-45-6789, Email: john@test.com";

        long startTime = System.currentTimeMillis();
        for (int i = 0; i < 1000; i++) {
            piiRedactionService.redactString(testData, PIIType.getStandardTypes());
        }
        long endTime = System.currentTimeMillis();

        long duration = endTime - startTime;
        System.out.println("Performance Test: 1000 redactions took " + duration + "ms");
        System.out.println("Average: " + (duration / 1000.0) + "ms per redaction");

        // Should be reasonably fast
        assertTrue(duration < 5000, "Redaction should take less than 5 seconds for 1000 operations");
    }
}
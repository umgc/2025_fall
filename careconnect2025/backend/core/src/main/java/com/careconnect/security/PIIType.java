package com.careconnect.security;

/**
 * Enumeration of different types of Personally Identifiable Information (PII)
 * that can be redacted from logs, API responses, and data processing.
 */
public enum PIIType {

    // Personal Identifiers
    SSN("Social Security Number", "\\b\\d{3}[-\\s\\.]?\\d{2}[-\\s\\.]?\\d{4}\\b", "XXX-XX-XXXX"),
    EMAIL("Email Address", "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b", "[EMAIL_REDACTED]"),
    PHONE("Phone Number", "\\b(?:\\+1[-\\s\\.]?)?(?:\\(?\\d{3}\\)?[-\\s\\.]?)?\\d{3}[-\\s\\.]?\\d{4}\\b", "XXX-XXX-XXXX"),

    // Medical Identifiers
    MEDICAL_ID("Medical Record Number", "\\b(?:MRN|Medical ID|Patient ID)[:\\s]*([A-Z0-9-]{6,20})\\b", "MRN: [REDACTED]"),
    INSURANCE_ID("Insurance ID", "\\b(?:Insurance|Policy)[:\\s#]*([A-Z0-9-]{8,20})\\b", "Insurance: [REDACTED]"),

    // Personal Information
    FULL_NAME("Full Name", "\\b[A-ZÀ-ÿ][a-zà-ÿ]+(?:[-'][A-ZÀ-ÿ][a-zà-ÿ]+)*\\s+[A-ZÀ-ÿ][a-zà-ÿ]+(?:[-'][A-ZÀ-ÿ][a-zà-ÿ]+)*(?:\\s+[A-ZÀ-ÿ][a-zà-ÿ]+(?:[-'][A-ZÀ-ÿ][a-zà-ÿ]+)*)?\\b", "[NAME_REDACTED]"),
    SINGLE_NAME("Single Name with Apostrophe", "\\b[A-ZÀ-ÿ][a-zà-ÿ]*'[A-ZÀ-ÿ][a-zà-ÿ]+\\b", "[NAME_REDACTED]"),
    DATE_OF_BIRTH("Date of Birth", "\\b(?:DOB|Born)[:\\s]*\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}\\b", "DOB: [REDACTED]"),

    // Address Information
    ADDRESS("Street Address", "\\b\\d+\\s+[A-Za-z0-9\\s,.-]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct|Place|Pl|Way|Circle|Cir)\\b", "[ADDRESS_REDACTED]"),
    ZIP_CODE("ZIP Code", "\\b\\d{5}(?:-\\d{4})?\\b", "XXXXX"),

    // Financial Information
    CREDIT_CARD("Credit Card Number", "\\b(?:\\d{4}[-\\s]?){3}\\d{4}\\b", "XXXX-XXXX-XXXX-XXXX"),
    BANK_ACCOUNT("Bank Account Number", "\\b(?:Account|Acct)[:\\s#]*([0-9-]{8,17})\\b", "Account: [REDACTED]"),

    // Sensitive Medical Information
    DIAGNOSIS("Medical Diagnosis", "\\b(?:Diagnosis|Condition)[:\\s]*([A-Za-z0-9\\s,.-]{10,50})(?:\\s|$)", "Diagnosis: [REDACTED]"),
    MEDICATION("Medication Names", "\\b(?:Taking|Prescribed|Medication)[:\\s]*([A-Za-z0-9\\s,.-]{5,30})(?:\\s|$)", "Medication: [REDACTED]"),

    // Custom/Flexible
    CUSTOM("Custom PII Pattern", "", "[REDACTED]");

    private final String description;
    private final String regexPattern;
    private final String redactionReplacement;

    PIIType(String description, String regexPattern, String redactionReplacement) {
        this.description = description;
        this.regexPattern = regexPattern;
        this.redactionReplacement = redactionReplacement;
    }

    public String getDescription() {
        return description;
    }

    public String getRegexPattern() {
        return regexPattern;
    }

    public String getRedactionReplacement() {
        return redactionReplacement;
    }

    /**
     * Returns all standard PII types that should be redacted by default.
     */
    public static PIIType[] getStandardTypes() {
        return new PIIType[]{SSN, EMAIL, PHONE, MEDICAL_ID, FULL_NAME, SINGLE_NAME, DATE_OF_BIRTH, CREDIT_CARD};
    }

    /**
     * Returns medical-specific PII types for healthcare applications.
     */
    public static PIIType[] getMedicalTypes() {
        return new PIIType[]{SSN, EMAIL, PHONE, MEDICAL_ID, INSURANCE_ID, DIAGNOSIS, MEDICATION, DATE_OF_BIRTH, FULL_NAME};
    }

    /**
     * Returns financial PII types.
     */
    public static PIIType[] getFinancialTypes() {
        return new PIIType[]{CREDIT_CARD, BANK_ACCOUNT, SSN};
    }
}
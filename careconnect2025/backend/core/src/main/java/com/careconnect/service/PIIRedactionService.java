package com.careconnect.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.careconnect.security.PIIType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Service;

import java.lang.reflect.Field;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Service responsible for redacting PII (Personally Identifiable Information)
 * from various data structures including strings, objects, and JSON.
 */
@Service
@Slf4j
@RequiredArgsConstructor
@ConfigurationProperties(prefix = "careconnect.pii-redaction")
public class PIIRedactionService {

    private final ObjectMapper objectMapper;

    // Configurable properties
    private boolean enabled = true;
    private Set<String> sensitiveFieldNames = new HashSet<>(Arrays.asList(
        "ssn", "socialSecurityNumber", "email", "phone", "phoneNumber",
        "medicalId", "patientId", "insuranceId", "creditCard", "bankAccount",
        "firstName", "lastName", "fullName", "address", "zipCode", "dateOfBirth"
    ));
    private Map<PIIType, Pattern> compiledPatterns = new HashMap<>();

    // Initialize regex patterns
    {
        for (PIIType type : PIIType.values()) {
            if (!type.getRegexPattern().isEmpty()) {
                // Names should be case-sensitive to avoid false positives
                int flags = (type == PIIType.FULL_NAME) ? 0 : Pattern.CASE_INSENSITIVE;
                compiledPatterns.put(type, Pattern.compile(type.getRegexPattern(), flags));
            }
        }
    }

    /**
     * Redacts PII from a string using specified PII types.
     */
    public String redactString(String input, PIIType... types) {
        if (!enabled || input == null || input.isEmpty()) {
            return input;
        }

        String result = input;
        PIIType[] typesToRedact = types.length > 0 ? types : PIIType.getStandardTypes();

        for (PIIType type : typesToRedact) {
            Pattern pattern = compiledPatterns.get(type);
            if (pattern != null) {
                Matcher matcher = pattern.matcher(result);
                result = matcher.replaceAll(type.getRedactionReplacement());
            }
        }

        return result;
    }

    /**
     * Redacts PII from any object by converting to JSON and back.
     */
    public Object redactObject(Object obj, PIIType... types) {
        if (!enabled || obj == null) {
            return obj;
        }

        try {
            // Handle primitive types and strings directly
            if (obj instanceof String) {
                return redactString((String) obj, types);
            }

            if (isPrimitiveOrWrapper(obj.getClass())) {
                return obj;
            }

            // Handle collections
            if (obj instanceof Collection) {
                return redactCollection((Collection<?>) obj, types);
            }

            if (obj instanceof Map) {
                return redactMap((Map<?, ?>) obj, types);
            }

            // Handle complex objects using reflection
            return redactComplexObject(obj, types);

        } catch (Exception e) {
            log.warn("Error redacting object of type {}: {}", obj.getClass().getSimpleName(), e.getMessage());
            return obj; // Return original object if redaction fails
        }
    }

    /**
     * Redacts PII from JSON string.
     */
    public String redactJsonString(String jsonString, PIIType... types) {
        if (!enabled || jsonString == null || jsonString.isEmpty()) {
            return jsonString;
        }

        try {
            JsonNode jsonNode = objectMapper.readTree(jsonString);
            JsonNode redactedNode = redactJsonNode(jsonNode, types);
            return objectMapper.writeValueAsString(redactedNode);
        } catch (Exception e) {
            log.warn("Error redacting JSON string: {}", e.getMessage());
            // Fallback to string redaction
            return redactString(jsonString, types);
        }
    }

    /**
     * Redacts PII specifically for medical/healthcare context.
     */
    public String redactMedicalData(String input) {
        return redactString(input, PIIType.getMedicalTypes());
    }

    /**
     * Redacts PII for logging purposes (preserves structure).
     */
    public String redactForLogging(String logMessage) {
        if (!enabled || logMessage == null || logMessage.isEmpty()) {
            return logMessage;
        }

        // Preserve common logging structure words
        String result = logMessage;

        // Only redact actual PII patterns, not common words - include FULL_NAME for logging
        PIIType[] loggingTypes = {
            PIIType.SSN, PIIType.EMAIL, PIIType.PHONE, PIIType.MEDICAL_ID,
            PIIType.CREDIT_CARD, PIIType.ADDRESS, PIIType.ZIP_CODE, PIIType.INSURANCE_ID,
            PIIType.FULL_NAME
        };

        // Apply redaction but preserve logging structure
        for (PIIType type : loggingTypes) {
            Pattern pattern = compiledPatterns.get(type);
            if (pattern != null) {
                Matcher matcher = pattern.matcher(result);
                result = matcher.replaceAll(type.getRedactionReplacement());
            }
        }

        return result;
    }

    /**
     * Checks if the given data contains potential PII.
     */
    public boolean containsPII(String input, PIIType... types) {
        if (input == null || input.trim().isEmpty()) {
            return false;
        }

        PIIType[] typesToCheck = types.length > 0 ? types : PIIType.getStandardTypes();

        for (PIIType type : typesToCheck) {
            Pattern pattern = compiledPatterns.get(type);
            if (pattern != null && pattern.matcher(input).find()) {
                // Debug logging to help identify which pattern is matching
                log.debug("Pattern {} matched in input: {}", type, input);
                return true;
            }
        }
        return false;
    }

    /**
     * Overloaded method for single string input (fixes test failure)
     */
    public boolean containsPII(String input) {
        return containsPII(input, PIIType.getStandardTypes());
    }

    // Private helper methods

    private Object redactComplexObject(Object obj, PIIType[] types) throws IllegalAccessException {
        Class<?> clazz = obj.getClass();
        Object clonedObj = createClone(obj);

        Field[] fields = clazz.getDeclaredFields();
        for (Field field : fields) {
            field.setAccessible(true);
            Object fieldValue = field.get(clonedObj);

            if (fieldValue instanceof String) {
                String stringValue = (String) fieldValue;
                // Check if field name suggests it contains PII
                if (isSensitiveFieldName(field.getName()) || containsPII(stringValue, types)) {
                    field.set(clonedObj, redactString(stringValue, types));
                }
            } else if (fieldValue != null && !isPrimitiveOrWrapper(fieldValue.getClass())) {
                // Recursively redact nested objects
                field.set(clonedObj, redactObject(fieldValue, types));
            }
        }

        return clonedObj;
    }

    private Collection<?> redactCollection(Collection<?> collection, PIIType[] types) {
        List<Object> redactedList = new ArrayList<>();
        for (Object item : collection) {
            redactedList.add(redactObject(item, types));
        }
        return redactedList;
    }

    private Map<?, ?> redactMap(Map<?, ?> map, PIIType[] types) {
        Map<Object, Object> redactedMap = new HashMap<>();
        for (Map.Entry<?, ?> entry : map.entrySet()) {
            Object key = entry.getKey();
            Object value = redactObject(entry.getValue(), types);
            redactedMap.put(key, value);
        }
        return redactedMap;
    }

    private JsonNode redactJsonNode(JsonNode node, PIIType[] types) {
        if (node.isTextual()) {
            String textValue = node.asText();
            String redactedText = redactString(textValue, types);
            return objectMapper.valueToTree(redactedText);
        } else if (node.isObject()) {
            ObjectNode objectNode = (ObjectNode) node;
            ObjectNode redactedNode = objectMapper.createObjectNode();

            objectNode.fields().forEachRemaining(entry -> {
                String fieldName = entry.getKey();
                JsonNode fieldValue = entry.getValue();

                if (isSensitiveFieldName(fieldName)) {
                    redactedNode.put(fieldName, "[REDACTED]");
                } else {
                    redactedNode.set(fieldName, redactJsonNode(fieldValue, types));
                }
            });

            return redactedNode;
        } else if (node.isArray()) {
            node.forEach(item -> redactJsonNode(item, types));
        }

        return node;
    }

    private boolean isSensitiveFieldName(String fieldName) {
        return sensitiveFieldNames.stream()
                .anyMatch(sensitive -> fieldName.toLowerCase().contains(sensitive.toLowerCase()));
    }

    private boolean isPrimitiveOrWrapper(Class<?> clazz) {
        return clazz.isPrimitive() ||
               clazz == String.class ||
               clazz == Integer.class || clazz == Long.class ||
               clazz == Double.class || clazz == Float.class ||
               clazz == Boolean.class || clazz == Character.class ||
               clazz == Byte.class || clazz == Short.class ||
               Number.class.isAssignableFrom(clazz);
    }

    private Object createClone(Object obj) {
        try {
            // Simple cloning - for more complex objects, consider using a cloning library
            return objectMapper.readValue(
                objectMapper.writeValueAsString(obj),
                obj.getClass()
            );
        } catch (Exception e) {
            log.warn("Failed to clone object, using original: {}", e.getMessage());
            return obj;
        }
    }

    // Configuration setters for Spring Boot properties
    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public void setSensitiveFieldNames(Set<String> sensitiveFieldNames) {
        this.sensitiveFieldNames = sensitiveFieldNames;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public Set<String> getSensitiveFieldNames() {
        return sensitiveFieldNames;
    }
}
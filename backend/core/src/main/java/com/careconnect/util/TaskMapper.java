package com.careconnect.util;

import java.util.List;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Utility class for converting the {@code daysOfWeek} field
 * between JSON and Java objects.
 *
 * <p>
 * In the database, {@code daysOfWeek} is stored as a JSON string
 * representing a list of booleans (one for each day of the week).
 * This class provides helper methods to:
 * <ul>
 * <li>Parse the JSON string into a {@link List}&lt;{@link Boolean}&gt;</li>
 * <li>Serialize a {@link List}&lt;{@link Boolean}&gt; back into a JSON
 * string</li>
 * </ul>
 * </p>
 *
 * <p>
 * Example JSON representation of {@code daysOfWeek}:
 * </p>
 * 
 * <pre>
 * "[true, false, true, false, false, true, false]"
 * </pre>
 * 
 * → Monday, Wednesday, Saturday
 *
 * <p>
 * This utility is typically used in the {@code TaskServiceV2} layer
 * when mapping between entities and DTOs.
 * </p>
 */
public class TaskMapper {
    /** Shared Jackson object mapper for JSON serialization/deserialization. */
    private static final ObjectMapper mapper = new ObjectMapper();

    /**
     * Parses a JSON string into a list of booleans representing days of the week.
     *
     * <p>
     * Each element corresponds to a day (starting with Sunday or Monday,
     * depending on business rules). A value of {@code true} means the task
     * applies on that day.
     * </p>
     *
     * <p>
     * Example input:
     * </p>
     * 
     * <pre>
     * "[true, false, true, false, false, true, false]"
     * </pre>
     *
     * @param json JSON string representation of a list of booleans
     * @return list of booleans, or {@code null} if input is {@code null}
     * @throws RuntimeException if parsing fails
     */
    public static List<Boolean> parseDays(String json) {
        if (json == null)
            return null;
        try {
            return mapper.readValue(json, new TypeReference<List<Boolean>>() {
            });
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse daysOfWeek JSON", e);
        }
    }

    /**
     * Serializes a list of booleans into a JSON string representation.
     *
     * <p>
     * Each boolean represents whether the task occurs on a given day.
     * </p>
     *
     * <p>
     * Example input:
     * </p>
     * 
     * <pre>
     *   [true, false, true, false, false, true, false]
     * </pre>
     * 
     * → Output:
     * 
     * <pre>
     * "[true,false,true,false,false,true,false]"
     * </pre>
     *
     * @param days list of booleans, one per day of the week
     * @return JSON string representation, or {@code null} if input is {@code null}
     * @throws RuntimeException if serialization fails
     */
    public static String serializeDays(List<Boolean> days) {
        if (days == null)
            return null;
        try {
            return mapper.writeValueAsString(days);
        } catch (Exception e) {
            throw new RuntimeException("Failed to serialize daysOfWeek JSON", e);
        }
    }
}

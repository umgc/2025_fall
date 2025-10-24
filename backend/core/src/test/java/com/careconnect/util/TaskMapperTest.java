package com.careconnect.util;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Unit tests for {@link TaskMapper}.
 *
 * <p>
 * These tests validate correct JSON serialization and deserialization
 * of the {@code daysOfWeek} list used in recurring task definitions.
 * </p>
 */
class TaskMapperTest {

    // --------------------------------------------------------------------------
    // parseDays() Tests
    // --------------------------------------------------------------------------

    @Test
    @DisplayName("parseDays should correctly parse valid JSON string into List<Boolean>")
    void testParseDays_validJson() {
        String json = "[true,false,true,false,false,true,false]";

        List<Boolean> result = TaskMapper.parseDays(json);

        assertNotNull(result);
        assertEquals(7, result.size());
        assertEquals(List.of(true, false, true, false, false, true, false), result);
    }

    @Test
    @DisplayName("parseDays should return null for null input")
    void testParseDays_nullInput() {
        assertNull(TaskMapper.parseDays(null));
    }

    @Test
    @DisplayName("parseDays should throw RuntimeException for malformed JSON")
    void testParseDays_malformedJson() {
        String badJson = "[true, false, invalid, false]";

        RuntimeException ex = assertThrows(RuntimeException.class, () -> TaskMapper.parseDays(badJson));
        assertTrue(ex.getMessage().contains("Failed to parse daysOfWeek JSON"));
    }

    // --------------------------------------------------------------------------
    // serializeDays() Tests
    // --------------------------------------------------------------------------

    @Test
    @DisplayName("serializeDays should correctly convert List<Boolean> to JSON string")
    void testSerializeDays_validList() {
        List<Boolean> days = List.of(true, false, true, false, false, true, false);

        String result = TaskMapper.serializeDays(days);

        assertEquals("[true,false,true,false,false,true,false]", result);
    }

    @Test
    @DisplayName("serializeDays should return null for null input")
    void testSerializeDays_nullInput() {
        assertNull(TaskMapper.serializeDays(null));
    }

    @Test
    @DisplayName("serializeDays and parseDays should be inverses (round-trip test)")
    void testRoundTrip_serializeAndParse() {
        List<Boolean> original = List.of(true, false, true, false, true, false, false);

        String json = TaskMapper.serializeDays(original);
        List<Boolean> parsedBack = TaskMapper.parseDays(json);

        assertEquals(original, parsedBack);
    }
}

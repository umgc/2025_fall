package com.careconnect.service.v2;

import java.util.List;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

public class TaskMapper {
    private static final ObjectMapper mapper = new ObjectMapper();

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

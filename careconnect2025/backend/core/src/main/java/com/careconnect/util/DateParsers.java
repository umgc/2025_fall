package com.careconnect.util;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public final class DateParsers {
    private DateParsers() {}

    public static OffsetDateTime parseOffsetOrLocalToUtc(String s) {
        if (s == null || s.isBlank()) return OffsetDateTime.now(ZoneOffset.UTC);
        final String t = s.trim();
        try {
            // Accepts 2025-10-05T10:43:21.990895Z or with +05:00, -04:00, etc.
            return OffsetDateTime.parse(t, DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        } catch (DateTimeParseException ignore) {
            // No offset. Try local date-time then treat as UTC.
            try {
                LocalDateTime ldt = LocalDateTime.parse(t, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                return ldt.atOffset(ZoneOffset.UTC);
            } catch (DateTimeParseException ignore2) {
                // Date-only. Start of day UTC.
                LocalDate ld = LocalDate.parse(t, DateTimeFormatter.ISO_LOCAL_DATE);
                return ld.atStartOfDay().atOffset(ZoneOffset.UTC);
            }
        }
    }

    public static OffsetDateTime parseNullableOffsetOrLocalToUtc(String s) {
        if (s == null || s.isBlank()) return null;
        return parseOffsetOrLocalToUtc(s);
    }
}

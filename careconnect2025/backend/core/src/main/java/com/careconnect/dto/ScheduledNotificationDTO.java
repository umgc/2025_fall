package com.careconnect.dto;

import io.micrometer.common.lang.Nullable;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) for scheduling notifications.
 *
 * <p>
 * This DTO is used to transfer notification-related data between
 * the client and server (e.g., in REST API requests and responses).
 * It ensures only the required fields are exposed, while validation
 * annotations guarantee input integrity.
 * </p>
 *
 * <p>
 * Typical usage:
 * <ul>
 * <li>Creating a new notification request from the frontend</li>
 * <li>Validating required fields before persisting to the database</li>
 * <li>Carrying notification data between service and controller layers</li>
 * </ul>
 * </p>
 *
 * <p>
 * Note: Fields like {@code scheduledTime} are stored as strings
 * in the DTO for JSON compatibility, but should be parsed into
 * {@link java.time.LocalDateTime} in the service layer.
 * </p>
 */

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledNotificationDTO {
    /**
     * The ID of the user who will receive the notification.
     * <p>
     * <b>Required.</b>
     * </p>
     */
    @NotNull(message = "Receiver ID is required")
    private Long receiverId;

    /**
     * Title of the notification (short summary shown to the user).
     * <p>
     * <b>Required.</b>
     * </p>
     */
    @NotNull(message = "Title is required")
    private String title;

    /**
     * Body content of the notification (detailed message).
     * <p>
     * <b>Required.</b>
     * </p>
     */
    @NotNull(message = "Body is required")
    private String body;

    /**
     * Type of notification.
     * <p>
     * Examples: {@code REMINDER}, {@code ALERT}, {@code EMERGENCY}.
     * </p>
     * <p>
     * Optional.
     * </p>
     */
    @Nullable
    private String notificationType;

    /**
     * Scheduled date and time when the notification should be sent.
     *
     * <p>
     * Stored as an ISO-8601 string for compatibility with JSON payloads
     * (e.g., {@code "2025-09-26T14:30:00"}). Must be parsed into
     * {@link java.time.LocalDateTime} in the service layer before use.
     * </p>
     *
     * <p>
     * <b>Required.</b>
     * </p>
     */
    @NotNull(message = "Scheduled time is required")
    private String scheduledTime;
}
package com.careconnect.dto;

import io.micrometer.common.lang.Nullable;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledNotificationDTO {

    @NotNull(message = "Receiver ID is required")
    private Long receiverId;

    @NotNull(message = "Title is required")
    private String title;

    @NotNull(message = "Body is required")
    private String body;

    @Nullable
    private String notificationType; // e.g. REMINDER, ALERT, EMERGENCY

    @NotNull(message = "Scheduled time is required")
    private String scheduledTime; // store as string, parse in service
}
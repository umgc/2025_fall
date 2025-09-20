package com.careconnect.dto.v2;

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
public class TaskDtoV2 {
    @NotNull(message = "Task name is required")
    private String name;

    @Nullable
    private String description;

    @NotNull(message = "Date is required")
    private String date; // Stored as varchar(255) in DB

    @Nullable
    private String timeOfDay; // Stored as varchar(255) in DB

    @NotNull(message = "Completion state is required")
    private boolean isCompleted;

    @Nullable
    private String frequency;

    @Nullable
    private int interval;

    @Nullable
    private int count;

    @Nullable
    private String daysOfWeek;

    @Nullable
    private String taskType;

    // Only used in UPDATE flow (optional for reassignments)
    @Nullable
    private Long patientId;
}

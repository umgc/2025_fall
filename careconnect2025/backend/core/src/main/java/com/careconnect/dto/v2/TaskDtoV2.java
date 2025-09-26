package com.careconnect.dto.v2;

import java.util.List;

import com.careconnect.dto.ScheduledNotificationDTO;

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
    private Long id;

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
    private Integer interval;

    @Nullable
    private Integer count;

    @Nullable
    private List<Boolean> daysOfWeek;

    @Nullable
    private String taskType;

    // Only used in UPDATE flow (optional for reassignments)
    // This does flatten the patient nested object to just id.
    @Nullable
    private Long patientId;

    @Nullable
    private List<ScheduledNotificationDTO> notifications;

    // true = update all tasks in series, false/null = just this one
    private Boolean updateSeries;
}

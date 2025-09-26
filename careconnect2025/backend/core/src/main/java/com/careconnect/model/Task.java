package com.careconnect.model;

import java.util.ArrayList;
import java.util.List;

import io.micrometer.common.lang.Nullable;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "tasks")
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "patient_id")
    private Patient patient;

    private String name;
    @Nullable
    private String description;

    private String date;
    @Nullable
    private String timeOfDay;

    private boolean isCompleted;

    private String taskType;

    // FrequencyTask fields
    @Nullable
    private String frequency; // e.g. "daily", "weekly", etc.
    @Nullable
    private Integer taskInterval; // Interval for the frequency, e.g. every 2 days
    @Nullable
    private Integer doCount; // Number of occurrences

    // DayOfWeekTask fields
    @Nullable
    private String daysOfWeek; // 7 long list for each day of the week

    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<ScheduledNotification> notifications = new ArrayList<>();

    @Nullable
    private Long parentTaskId;

}
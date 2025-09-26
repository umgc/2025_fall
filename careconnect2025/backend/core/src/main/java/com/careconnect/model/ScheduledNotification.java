package com.careconnect.model;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonBackReference;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "scheduled_notification")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Receiver (user who should get the notification)
    @Column(nullable = false)
    private Long receiverId;

    // Notification content
    @Column(nullable = false, length = 255)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    private String notificationType; // e.g. REMINDER, ALERT, EMERGENCY

    // Scheduling
    @Column(nullable = false)
    private LocalDateTime scheduledTime;

    private LocalDateTime sentTime;

    // Delivery tracking
    @Builder.Default
    @Column(nullable = false)
    private String status = "PENDING"; // PENDING, SENT, FAILED, CANCELLED

    private String messageId;
    private String errorMessage;

    // Audit fields
    @Builder.Default
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Builder.Default
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void setLastUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    @JsonBackReference
    private Task task;
}

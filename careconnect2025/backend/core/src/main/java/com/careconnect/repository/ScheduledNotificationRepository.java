package com.careconnect.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.careconnect.model.ScheduledNotification;

@Repository
public interface ScheduledNotificationRepository extends JpaRepository<ScheduledNotification, Long> {

    // Find all notifications that should be sent now or earlier and are still
    // pending
    List<ScheduledNotification> findByStatusAndScheduledTimeBefore(String status, LocalDateTime before);

    // Find all notifications for a given user
    List<ScheduledNotification> findByReceiverId(Long receiverId);
}

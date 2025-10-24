package com.careconnect.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.careconnect.model.ScheduledNotification;

/**
 * Repository interface for managing {@link ScheduledNotification} entities.
 *
 * <p>
 * This interface extends {@link JpaRepository}, providing standard
 * CRUD operations (create, read, update, delete), pagination, and
 * query support out of the box.
 * </p>
 *
 * <p>
 * Additional custom query methods are declared for retrieving
 * notifications based on their status, scheduled time, or receiver.
 * </p>
 *
 * <p>
 * Spring Data JPA automatically generates the implementation of
 * these methods at runtime by parsing the method names into SQL queries.
 * </p>
 */
@Repository
public interface ScheduledNotificationRepository extends JpaRepository<ScheduledNotification, Long> {

    /**
     * Finds all notifications that match the given {@code status} and
     * are scheduled before the specified {@code before} time.
     *
     * <p>
     * Typical use case: retrieving all pending notifications
     * that are due to be sent (e.g., scheduled time is in the past
     * or current moment).
     * </p>
     *
     * @param status the status to filter by (e.g., "PENDING")
     * @param before the cutoff time; only notifications scheduled
     *               before this time will be returned
     * @return a list of matching {@link ScheduledNotification} entities
     */
    List<ScheduledNotification> findByStatusAndScheduledTimeBefore(String status, LocalDateTime before);

    /**
     * Finds all notifications that belong to a specific user, identified
     * by their {@code receiverId}.
     *
     * <p>
     * Typical use case: retrieving a user’s history of notifications
     * or filtering active notifications for display in the UI.
     * </p>
     *
     * @param receiverId the ID of the user who received the notifications
     * @return a list of matching {@link ScheduledNotification} entities
     */
    List<ScheduledNotification> findByReceiverId(Long receiverId);
}

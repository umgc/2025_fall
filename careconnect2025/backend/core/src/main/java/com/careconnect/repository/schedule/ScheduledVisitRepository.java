package com.careconnect.repository.schedule;

import com.careconnect.model.schedule.ScheduledVisit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Repository
public interface ScheduledVisitRepository extends JpaRepository<ScheduledVisit, Long> {
    
    List<ScheduledVisit> findByCaregiverId(Long caregiverId);
    
    List<ScheduledVisit> findByCaregiverIdAndScheduledDate(Long caregiverId, LocalDate date);
    
    List<ScheduledVisit> findByCaregiverIdAndScheduledDateBetween(
        Long caregiverId, 
        LocalDate startDate, 
        LocalDate endDate
    );
    
    List<ScheduledVisit> findByCaregiverIdAndStatus(Long caregiverId, String status);
    
    List<ScheduledVisit> findByPatientId(Long patientId);
    
    @Query("SELECT COUNT(v) FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND (v.scheduledDate < :today OR (v.scheduledDate = :today AND v.scheduledTime < :currentTime)) " +
           "AND v.status = 'Scheduled'")
    long countOverdueVisits(@Param("caregiverId") Long caregiverId, 
                           @Param("today") LocalDate today,
                           @Param("currentTime") LocalTime currentTime);
    
    @Query("SELECT COUNT(v) FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND v.scheduledDate = :today " +
           "AND v.scheduledTime <= :timeThreshold " +
           "AND v.status = 'Scheduled'")
    long countReadyVisits(@Param("caregiverId") Long caregiverId,
                         @Param("today") LocalDate today,
                         @Param("timeThreshold") LocalTime timeThreshold);
    
    @Query("SELECT COUNT(v) FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND ((v.scheduledDate = :today AND v.scheduledTime > :timeThreshold) " +
           "OR v.scheduledDate > :today) " +
           "AND v.status = 'Scheduled'")
    long countUpcomingVisits(@Param("caregiverId") Long caregiverId,
                            @Param("today") LocalDate today,
                            @Param("timeThreshold") LocalTime timeThreshold);
    
    @Query("SELECT COUNT(v) FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND v.scheduledDate = :today")
    long countTodayVisits(@Param("caregiverId") Long caregiverId,
                         @Param("today") LocalDate today);
    
    @Query("SELECT v FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND (v.scheduledDate < :today OR (v.scheduledDate = :today AND v.scheduledTime < :currentTime)) " +
           "AND v.status = 'Scheduled' " +
           "ORDER BY v.scheduledDate ASC, v.scheduledTime ASC")
    List<ScheduledVisit> findOverdueVisits(@Param("caregiverId") Long caregiverId,
                                          @Param("today") LocalDate today,
                                          @Param("currentTime") LocalTime currentTime);
    
    @Query("SELECT v FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND v.scheduledDate = :today " +
           "AND v.scheduledTime <= :timeThreshold " +
           "AND v.status = 'Scheduled' " +
           "ORDER BY v.scheduledTime ASC")
    List<ScheduledVisit> findReadyVisits(@Param("caregiverId") Long caregiverId,
                                        @Param("today") LocalDate today,
                                        @Param("timeThreshold") LocalTime timeThreshold);
    
    @Query("SELECT v FROM ScheduledVisit v WHERE v.caregiverId = :caregiverId " +
           "AND ((v.scheduledDate = :today AND v.scheduledTime > :timeThreshold) " +
           "OR v.scheduledDate > :today) " +
           "AND v.status = 'Scheduled' " +
           "ORDER BY v.scheduledDate ASC, v.scheduledTime ASC")
    List<ScheduledVisit> findUpcomingVisits(@Param("caregiverId") Long caregiverId,
                                           @Param("today") LocalDate today,
                                           @Param("timeThreshold") LocalTime timeThreshold);
}

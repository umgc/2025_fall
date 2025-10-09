package com.careconnect.repository;

import com.careconnect.model.EvvRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface EvvRecordRepository extends JpaRepository<EvvRecord,Long> {
    
    @Query("SELECT e FROM EvvRecord e JOIN FETCH e.participant WHERE e.caregiverId = :caregiverId AND e.status = :status")
    List<EvvRecord> findByCaregiverIdAndStatus(@Param("caregiverId") Long caregiverId, @Param("status") String status);
    
    @Query("SELECT e FROM EvvRecord e JOIN FETCH e.participant WHERE e.status = :status")
    List<EvvRecord> findByStatus(@Param("status") String status);
    
    @Query("SELECT e FROM EvvRecord e JOIN FETCH e.participant WHERE e.id = :id")
    java.util.Optional<EvvRecord> findByIdWithParticipant(@Param("id") Long id);
    
    List<EvvRecord> findByParticipantMaNumber(String maNumber);
    
    List<EvvRecord> findByServiceType(String serviceType);
    
    List<EvvRecord> findByDateOfServiceBetween(LocalDate startDate, LocalDate endDate);
    
    List<EvvRecord> findByStateCode(String stateCode);
    
    List<EvvRecord> findByIsOfflineTrue();
    
    List<EvvRecord> findBySyncStatus(String syncStatus);
    
    List<EvvRecord> findByIsCorrectedTrue();
    
    List<EvvRecord> findByOriginalRecordId(Long originalRecordId);
    
    @Query("SELECT e FROM EvvRecord e WHERE " +
           "(:patientName IS NULL OR LOWER(e.participant.patientName) LIKE LOWER(CONCAT('%', :patientName, '%'))) AND " +
           "(:serviceType IS NULL OR LOWER(e.serviceType) LIKE LOWER(CONCAT('%', :serviceType, '%'))) AND " +
           "(:caregiverId IS NULL OR e.caregiverId = :caregiverId) AND " +
           "(:startDate IS NULL OR e.dateOfService >= :startDate) AND " +
           "(:endDate IS NULL OR e.dateOfService <= :endDate) AND " +
           "(:stateCode IS NULL OR e.stateCode = :stateCode) AND " +
           "(:status IS NULL OR e.status = :status)")
    Page<EvvRecord> searchRecords(@Param("patientName") String patientName,
                                  @Param("serviceType") String serviceType,
                                  @Param("caregiverId") Long caregiverId,
                                  @Param("startDate") LocalDate startDate,
                                  @Param("endDate") LocalDate endDate,
                                  @Param("stateCode") String stateCode,
                                  @Param("status") String status,
                                  Pageable pageable);
    
    @Query("SELECT e FROM EvvRecord e WHERE e.eorApprovalRequired = true AND e.eorApprovedBy IS NULL")
    List<EvvRecord> findPendingEorApprovals();
    
    @Query("SELECT e FROM EvvRecord e WHERE e.caregiverId = :caregiverId AND e.createdAt >= :since")
    List<EvvRecord> findByCaregiverSince(@Param("caregiverId") Long caregiverId, @Param("since") OffsetDateTime since);
}

package com.careconnect.repository;

import com.careconnect.model.Medication;
import com.careconnect.model.Patient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicationRepository extends JpaRepository<Medication, Long> {

    /**
     * Find all active medications for a specific patient
     */
    List<Medication> findByPatientAndIsActiveTrueOrderByCreatedAtDesc(Patient patient);

    /**
     * Find all medications for a specific patient (active and inactive)
     */
    List<Medication> findByPatientOrderByCreatedAtDesc(Patient patient);

    /**
     * Find active medications by patient ID
     */
    @Query("SELECT m FROM Medication m WHERE m.patient.id = :patientId AND m.isActive = true ORDER BY m.createdAt DESC")
    List<Medication> findActiveByPatientId(@Param("patientId") Long patientId);

    /**
     * Count active medications for a patient
     */
    long countByPatientAndIsActiveTrue(Patient patient);

    /**
     * Find medications by type for a patient
     */
    List<Medication> findByPatientAndMedicationTypeAndIsActiveTrueOrderByCreatedAtDesc(
            Patient patient, Medication.MedicationType medicationType);

    /**
     * Find all pending medications (approval_status = 'PENDING')
     */
    @Query("SELECT m FROM Medication m WHERE m.patient = :patient AND m.approvalStatus = 'PENDING'")
    List<Medication> findPendingByPatient(@Param("patient") Patient patient);

    /**
     * Find all medications for a patient with a specific approval status
     */
    List<Medication> findByPatientAndApprovalStatus(Patient patient, String approvalStatus);

    /**
     * Find medications waiting for approval (PENDING or REMOVAL_PENDING)
     */
    @Query("SELECT m FROM Medication m WHERE m.patient = :patient AND (m.approvalStatus = 'PENDING' OR m.approvalStatus = 'REMOVAL_PENDING') ORDER BY m.createdAt DESC")
    List<Medication> findPendingOrRemovalPendingByPatient(@Param("patient") Patient patient);
}



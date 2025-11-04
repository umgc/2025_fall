package com.careconnect.controller;

import com.careconnect.dto.MedicationDTO;
import com.careconnect.service.MedicationService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/api/patients")
@Tag(name = "Medication Management", description = "Endpoints for managing patient medications")
public class MedicationController {

    @Autowired
    private MedicationService medicationService;

    // ================================================================
    // 1. Fetch all medications for a patient
    // ================================================================
    @GetMapping("/{patientId}/medications")
    public ResponseEntity<List<MedicationDTO>> getAllMedications(@PathVariable Long patientId) {
        List<MedicationDTO> allMeds = medicationService.getAllMedicationsForPatient(patientId);
        return ResponseEntity.ok(allMeds);
    }

    // ================================================================
    // 1.1 Fetch only active medications
    // ================================================================
    @GetMapping("/{patientId}/medications/active")
    public ResponseEntity<List<MedicationDTO>> getActiveMedications(@PathVariable Long patientId) {
        List<MedicationDTO> activeMeds = medicationService.getActiveMedicationsForPatient(patientId);
        return ResponseEntity.ok(activeMeds);
    }

    // ================================================================
    // 1.2 Fetch pending medications (approval_status = 'PENDING')
    // ================================================================
    @GetMapping("/{patientId}/medications/pending")
    public ResponseEntity<List<MedicationDTO>> getPendingMedications(@PathVariable Long patientId) {
        List<MedicationDTO> pending = medicationService.getPendingMedications(patientId);
        return ResponseEntity.ok(pending);
    }

    // ================================================================
    // 2. Add a new medication (creates record as PENDING)
    // ================================================================
    @PostMapping("/{patientId}/medications")
    public ResponseEntity<MedicationDTO> addMedication(
            @PathVariable Long patientId,
            @RequestBody MedicationDTO newMedication) {

        MedicationDTO createdMedication = medicationService.addMedication(patientId, newMedication);
        return ResponseEntity.ok(createdMedication);
    }

    // ================================================================
    // 3. Approve a medication (sets isActive=true, approval_status='APPROVED')
    // ================================================================
    @PutMapping("/{patientId}/medications/{medicationId}/approve")
    public ResponseEntity<?> approveMedication(
            @PathVariable Long patientId,
            @PathVariable Long medicationId) {

        MedicationDTO approvedMedication = medicationService.approveMedication(patientId, medicationId);
        return ResponseEntity.ok(Map.of(
                "message", "Medication approved successfully",
                "approvedMedication", approvedMedication
        ));
    }

    // ================================================================
    // 4. Remove (soft delete) medication and trigger notification (Patient-side)
    // ================================================================
    @DeleteMapping("/{patientId}/medications/{medicationId}")
    public ResponseEntity<?> deleteMedication(
            @PathVariable Long patientId,
            @PathVariable Long medicationId) {

        medicationService.deactivateMedication(patientId, medicationId);
        return ResponseEntity.ok(Map.of(
                "message", "Medication removed and notification sent"
        ));
    }

    // ================================================================
    // 5. Hard delete medication (Caregiver-side)
    // ================================================================
    @DeleteMapping("/{patientId}/medications/{medicationId}/caregiver/{caregiverId}")
    public ResponseEntity<?> deleteMedicationByCaregiver(
            @PathVariable Long patientId,
            @PathVariable Long medicationId,
            @PathVariable Long caregiverId) {

        medicationService.hardDeleteMedication(patientId, medicationId, caregiverId);
        return ResponseEntity.ok(Map.of(
                "message", "Medication deleted successfully"
        ));
    }
}

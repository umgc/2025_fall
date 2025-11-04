package com.careconnect.controller;

import com.careconnect.dto.SymptomDTO;
import com.careconnect.model.Patient;
import com.careconnect.model.User;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.UserRepository;
import com.careconnect.security.Role;
import com.careconnect.service.CaregiverService;
import com.careconnect.service.SymptomService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/v1/api/symptoms")
@RequiredArgsConstructor
public class SymptomController {

    private final SymptomService symptomService;
    private final UserRepository userRepository;
    private final PatientRepository patientRepository;
    private final CaregiverService caregiverService;

    @PostMapping
    public ResponseEntity<?> create(@RequestBody SymptomDTO dto) {
        try {
            if (dto.patientId() == null || !hasAccessToPatient(dto.patientId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Not authorized to add symptoms for this patient"));
            }

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(Map.of("data", symptomService.create(dto), "message", "Symptom recorded"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody SymptomDTO dto) {
        try {
            Optional<SymptomDTO> existing = symptomService.get(id);
            if (existing.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "Symptom not found"));
            }

            if (!hasAccessToPatient(existing.get().patientId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Not authorized to update this symptom"));
            }

            return ResponseEntity.ok(Map.of("data", symptomService.update(id, dto), "message", "Symptom updated"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> list(@PathVariable Long patientId) {
        if (!hasAccessToPatient(patientId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Not authorized to view symptoms for this patient"));
        }
        return ResponseEntity.ok(Map.of("data", symptomService.listByPatient(patientId)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        try {
            Optional<SymptomDTO> existing = symptomService.get(id);
            if (existing.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "Symptom not found"));
            }

            if (!hasAccessToPatient(existing.get().patientId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Not authorized to delete this symptom"));
            }

            symptomService.delete(id);
            return ResponseEntity.ok(Map.of("message", "Symptom deleted"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    private boolean hasAccessToPatient(Long patientId) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userEmail = auth.getName();

            User currentUser = userRepository.findByEmail(userEmail)
                    .orElseThrow(() -> new IllegalStateException("User not found"));

            Optional<Patient> patientOpt = patientRepository.findById(patientId);
            if (patientOpt.isEmpty()) return false;

            Patient patient = patientOpt.get();
            User patientUser = patient.getUser();

            if (currentUser.getRole() == Role.PATIENT) {
                return currentUser.getId().equals(patientUser.getId());
            } else if (currentUser.getRole() == Role.CAREGIVER ||
                    currentUser.getRole() == Role.FAMILY_MEMBER) {
                return caregiverService.hasAccessToPatient(currentUser.getId(), patientId);
            } else if (currentUser.getRole() == Role.ADMIN) {
                return true;
            }

            return false;
        } catch (Exception e) {
            return false;
        }
    }
}

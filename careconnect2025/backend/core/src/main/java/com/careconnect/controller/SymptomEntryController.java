package com.careconnect.controller;

import com.careconnect.dto.SymptomEntryDTO;
import com.careconnect.service.SymptomEntryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/api/symptoms-entry")
@RequiredArgsConstructor
public class SymptomEntryController {

    private final SymptomEntryService symptomEntryService;

    /** Create a new symptom entry */
    @PostMapping
    public ResponseEntity<?> createSymptom(@RequestBody SymptomEntryDTO dto) {
        try {
            SymptomEntryDTO created = symptomEntryService.createSymptom(dto);
            return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("data", created, "message", "Symptom created successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to create symptom"));
        }
    }

    /** Get all symptoms for a patient */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getSymptoms(@PathVariable Long patientId) {
        try {
            List<SymptomEntryDTO> list = symptomEntryService.getSymptomsForPatient(patientId);
            return ResponseEntity.ok(Map.of("data", list, "message", "Symptoms retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to fetch symptoms"));
        }
    }

    /** Delete a symptom by ID */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteSymptom(@PathVariable Long id) {
        try {
            symptomEntryService.deleteSymptom(id);
            return ResponseEntity.ok(Map.of("message", "Symptom deleted successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to delete symptom"));
        }
    }
}

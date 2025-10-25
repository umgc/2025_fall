package com.careconnect.controller;

import com.careconnect.dto.AiSymptomDTO;
import com.careconnect.model.Allergy;
import com.careconnect.model.SymptomEntry;
import com.careconnect.repository.AllergyRepository;
import com.careconnect.repository.SymptomEntryRepository;
import com.careconnect.service.AiSymptomService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequiredArgsConstructor
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
@RequestMapping({"/api/ai", "/v1/api/ai"})
public class AiSymptomController {

    private final AiSymptomService aiSymptomService;
    private final AllergyRepository allergyRepository;
    private final SymptomEntryRepository symptomEntryRepository; // NEW

    @PostMapping(
            value = "/analyze/symptom",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<?> analyze(@Valid @RequestBody AiSymptomDTO.Request body) {
        try {
            Long pid = body.getPatientId();

            List<Allergy> allergies = (pid == null)
                    ? List.of()
                    : allergyRepository.findActiveAllergiesByPatientId(pid);

            // NEW: include recent symptom history (limit to 5 most recent)
            List<SymptomEntry> recentSymptoms = (pid == null)
                    ? List.of()
                    : symptomEntryRepository
                    .findByPatientIdOrderByTakenAtDesc(pid)
                    .stream()
                    .limit(5)
                    .toList();

            // UPDATED: pass recentSymptoms to the service so it can add context
            AiSymptomDTO.Result result = aiSymptomService.analyze(body, allergies, recentSymptoms);

            return ResponseEntity.ok(Map.of(
                    "data", Map.of(
                            "symptomKey",   result.getSymptomKey(),
                            "symptomValue", result.getSymptomValue(),
                            "severity",     result.getSeverity(),
                            "notes",        result.getNotes()
                    )
            ));
        } catch (Exception e) {
            log.error("AI symptom analyze failed", e);
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "AI_ANALYZE_FAILED",
                    "message", e.getMessage()
            ));
        }
    }
}

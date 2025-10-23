package com.careconnect.service;

import com.careconnect.dto.AiSymptomDTO;
import com.careconnect.model.Allergy;
import com.careconnect.model.SymptomEntry;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static com.careconnect.service.DeepSeekService.DeepSeekChatRequest;
import static com.careconnect.service.DeepSeekService.DeepSeekResponse;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class AiSymptomService {

    private final DeepSeekService deepSeekService;
    private final DeepSeekContextBuilder contextBuilder;
    private final ObjectMapper objectMapper; // Spring-injected

    /**
     * Analyze symptom transcript with both allergy and recent symptom context.
     */
    public AiSymptomDTO.Result analyze(AiSymptomDTO.Request req,
                                       List<Allergy> allergiesForContext,
                                       List<SymptomEntry> symptomsForContext) {

        String system = """
            You are a medical assistant. Extract structured symptom info from the user's sentence.
            Return ONLY a compact JSON object:
            {"symptomKey":"...", "symptomValue":"...", "severity":"MILD|MODERATE|SEVERE"}.
            If something is missing, leave it as an empty string. Do NOT add extra keys or text.
            """;

        // Context blocks
        String allergyBlock = contextBuilder.buildAllergyContext(req.getPatientId(), allergiesForContext);
        String symptomBlock = contextBuilder.buildSymptomContext(req.getPatientId(), symptomsForContext);

        Map<String, Object> ctx = Optional.ofNullable(req.getContext()).orElse(Map.of());

        String user = """
            Patient context (allergies for safety):
            %s

            Recent Symptom History:
            %s

            Current input (voice transcript):
            "%s"

            Hints (optional context from UI): %s

            Output JSON only.
            """.formatted(allergyBlock, symptomBlock, req.getText(), ctx);

        // Compose & call DeepSeek
        DeepSeekChatRequest chat = deepSeekService.buildChatRequest(system, user);
        DeepSeekResponse resp = deepSeekService.sendChatRequest(chat);

        // Shared parsing helpers
        String content = AiParsingUtils.extractContent(resp);

        AiSymptomDTO.Result out = new AiSymptomDTO.Result();
        out.setSymptomKey("");
        out.setSymptomValue("");
        out.setSeverity("");
        out.setNotes(Optional.ofNullable(req.getText()).orElse("")); // keep transcript as fallback

        JsonNode node = AiParsingUtils.tryParseJson(objectMapper, content);
        if (node != null) {
            out.setSymptomKey(AiParsingUtils.asText(node, "symptomKey"));
            out.setSymptomValue(AiParsingUtils.asText(node, "symptomValue"));
            out.setSeverity(
                    AiParsingUtils.normalizeSeverity(
                            AiParsingUtils.asText(node, "severity")
                    )
            );
        } else if (content != null && !content.isBlank()) {
            log.warn("AI content not strict JSON. Falling back. Content: {}", content);
        }

        return out;
    }
}

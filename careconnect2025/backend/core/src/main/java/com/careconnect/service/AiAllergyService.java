package com.careconnect.service;

import com.careconnect.dto.AiAllergyDTO;
import com.careconnect.model.Allergy;
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
public class AiAllergyService {

    private final DeepSeekService deepSeekService;
    private final DeepSeekContextBuilder contextBuilder;
    private final ObjectMapper objectMapper; // let Spring inject the shared mapper

    public AiAllergyDTO.Result analyze(AiAllergyDTO.Request req, List<Allergy> history) {
        // 1) System prompt
        String system = """
            You are a medical assistant. Extract structured allergy info from the user's sentence.
            Return ONLY a compact JSON object:
            {"allergen":"...", "reaction":"...", "severity":"MILD|MODERATE|SEVERE"}.
            If something is missing, leave it as an empty string. Do NOT add extra keys or text.
            """;

        String historyBlock = contextBuilder.buildAllergyContext(req.getPatientId(), history);

        // 2) User prompt
        Map<String, Object> ctx = Optional.ofNullable(req.getContext()).orElse(Map.of());
        String user = """
            Patient history:
            %s

            Current input (voice transcript):
            "%s"

            Hints (optional context from UI): %s

            Output JSON only.
            """.formatted(historyBlock, req.getText(), ctx);

        // Build & call DeepSeek
        DeepSeekChatRequest chat = deepSeekService.buildChatRequest(system, user);
        DeepSeekResponse resp = deepSeekService.sendChatRequest(chat);

        // Share helper
        String content = AiParsingUtils.extractContent(resp);

        AiAllergyDTO.Result out = new AiAllergyDTO.Result();
        out.setAllergen("");
        out.setReaction("");
        out.setSeverity("");

        JsonNode node = AiParsingUtils.tryParseJson(objectMapper, content);
        if (node != null) {
            out.setAllergen(AiParsingUtils.asText(node, "allergen"));
            out.setReaction(AiParsingUtils.asText(node, "reaction"));
            out.setSeverity(
                    AiParsingUtils.normalizeSeverity(
                            AiParsingUtils.asText(node, "severity")
                    )
            );
        } else if (!content.isBlank()) {
            // content present but not strict JSON → fall back to transcript
            log.warn("AI content was not strict JSON. Falling back. Content: {}", content);
            out.setReaction(Optional.ofNullable(req.getText()).orElse(""));
        } else {
            // empty content → fall back to transcript
            out.setReaction(Optional.ofNullable(req.getText()).orElse(""));
        }

        return out;
    }
}

package com.careconnect.controller;

import com.careconnect.dto.chat.AiRequest;
import com.careconnect.service.chat.GenericAiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Flux;

import java.util.List;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class GenericAiController {

    private final GenericAiService genericAiService;

    /**
     * Handles a chat request that can optionally include a file.
     * The endpoint now consumes multipart/form-data.
     */
    @PostMapping(value = "/chat", consumes = {MediaType.MULTIPART_FORM_DATA_VALUE})
    public ResponseEntity<String> chat(
            @RequestPart("request") AiRequest request,
            @RequestPart(value = "file", required = false) MultipartFile file) {

        if (request.prompt() == null || request.prompt().isBlank()) {
            return ResponseEntity.badRequest().body("The 'prompt' field cannot be empty.");
        }

        try {
            // Pass the file to the service layer
            String response = genericAiService.getAiResponse(request.context(), request.prompt(), file);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            // Proper logging should be implemented here
            return ResponseEntity.internalServerError().body("Error communicating with AI service: " + e.getMessage());
        }
    }

    /**
     * Handles a chat request that can optionally include a file.
     * The endpoint now consumes multipart/form-data.
     */
    @PostMapping(value = "/chat-with-file", consumes = {MediaType.MULTIPART_FORM_DATA_VALUE})
    public ResponseEntity<String> chatWithFile(
            @RequestPart("prompt") String prompt,
            @RequestPart(value = "context", required = false) String context,
             @RequestParam(value = "files" , required = false) List<MultipartFile> files) {
        if (prompt == null ||prompt.isBlank()) {
            return ResponseEntity.badRequest().body("The 'prompt' field cannot be empty.");
        }

        try {
            // Pass the file to the service layer
            String response = genericAiService.getAiResponse(context, prompt, files.get(0));
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            // Proper logging should be implemented here
            return ResponseEntity.internalServerError().body("Error communicating with AI service: " + e.getMessage());
        }
    }

    /**
     * Handles a streaming chat request that can optionally include a file.
     */
    @PostMapping(value = "/chat-stream", consumes = {MediaType.MULTIPART_FORM_DATA_VALUE}, produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> chatStream(
            @RequestPart("request") AiRequest request,
            @RequestPart(value = "file", required = false) MultipartFile file) {

        if (request.prompt() == null || request.prompt().isBlank()) {
            return Flux.error(new IllegalArgumentException("The 'prompt' field cannot be empty."));
        }
        // Pass the file to the service layer
        return genericAiService.streamAiResponse(request.context(), request.prompt(), file);
    }
}
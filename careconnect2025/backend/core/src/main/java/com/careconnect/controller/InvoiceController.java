package com.careconnect.controller;


import com.careconnect.dto.chat.AiRequest;
import com.careconnect.dto.invoice.InvoiceDto;
import com.careconnect.dto.invoice.InvoiceResponseDto;
import com.careconnect.dto.invoice.PaymentDto;
import com.careconnect.model.invoice.Invoice;
import com.careconnect.service.invoice.LlmExtractionService;
import com.careconnect.service.invoice.InvoiceService;
import com.careconnect.service.invoice.TextractService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;

@RestController
@RequestMapping("/v1/api/invoices")
@Slf4j
public class InvoiceController {

    private final InvoiceService service;
    private final TextractService textractService;
    private final LlmExtractionService llmExtractionService;
    private final ObjectMapper objectMapper;
    public InvoiceController(
            @Autowired(required = false) TextractService textractService,
            @Autowired(required = false) LlmExtractionService llmExtractionService,
            InvoiceService service,
            ObjectMapper objectMapper
    ) {
        this.service = service;
        this.llmExtractionService = llmExtractionService;
        this.textractService = textractService;
        this.objectMapper = objectMapper;

    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String providerName,
            @RequestParam(required = false) String patientName,
            @RequestParam(required = false) String dueStart,
            @RequestParam(required = false) String dueEnd,
            @RequestParam(required = false) String amountMin,
            @RequestParam(required = false) String amountMax,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int pageSize
    ) {
        Sort s = InvoiceService.resolveSort(sort);
        Pageable pageable = PageRequest.of(page, pageSize, s);

        var statuses = InvoiceService.parseStatuses(status);
        var ds = parseDate(dueStart);
        var de = parseDate(dueEnd);
        var amin = parseDecimal(amountMin);
        var amax = parseDecimal(amountMax);

        Page<InvoiceDto> result = service.list(
                search, statuses, providerName, patientName, ds, de, amin, amax, pageable
        );

        Map<String, Object> body = new HashMap<>();
        body.put("items", result.getContent());
        body.put("page", result.getNumber());
        body.put("pageSize", result.getSize());
        body.put("totalPages", result.getTotalPages());
        body.put("totalItems", result.getTotalElements());
        return ResponseEntity.ok(body);
    }

    @GetMapping("/{id}")
    public ResponseEntity<InvoiceDto> get(@PathVariable String id) {
        return service.get(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<InvoiceDto> create(@RequestBody InvoiceDto dto) {
        InvoiceDto created = service.create(dto);
        return ResponseEntity.status(201).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<InvoiceDto> update(@PathVariable String id, @RequestBody InvoiceDto dto) {
        InvoiceDto updated = service.update(id, dto);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
    @PostMapping("/{id}/payments")
    public ResponseEntity<InvoiceDto> addPayment(
            @PathVariable String id,
            @RequestBody PaymentDto dto,
            java.security.Principal principal
    ) {
        String actor = principal != null ? principal.getName() : "system";
        InvoiceDto updated = service.recordPayment(id, dto, actor);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}/payments/{paymentId}")
    public ResponseEntity<InvoiceDto> removePayment(
            @PathVariable String id,
            @PathVariable String paymentId
    ) {
        InvoiceDto updated = service.deletePayment(id, paymentId);
        return ResponseEntity.ok(updated);
    }
    /**
     * Endpoint that uses Textract to get raw text and then an LLM to structure the data.
     */
    @PostMapping(value = "/extract-llm", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> extractWithLlm(@RequestParam("files") List<MultipartFile> files) {
        if (isFileListInvalid(files)) {
            return ResponseEntity.badRequest().body("Please provide at least one valid file.");
        }

        // Check if Textract is available (AWS enabled)
        if (textractService == null) {
            return ResponseEntity.status(503).body("Textract service is not available. AWS services are disabled.");
        }

        try {
            log.info("received file for ocr "+files.get(0).getOriginalFilename());
            // Step 1: Get raw text using the updated service
            AiRequest.AnalysisResult result = textractService.analyzeAndGetResult(files);

            // Step 2: Send raw text to the LLM service
            var json = llmExtractionService.extractInvoiceData(result.rawText);
            String sanitizedJson = JsonSanitizer.extractFirstJsonObject(json);

            InvoiceDto invoiceDto = objectMapper.readValue(sanitizedJson, InvoiceDto.class);

            invoiceDto.documentLink=result.s3Key;

            // Step 3: Duplicate check (provider + total are the primary keys we compare)
            final String providerName = invoiceDto.provider == null ? null : invoiceDto.provider.name;
            final Double total = (invoiceDto.amounts == null) ? null : invoiceDto.amounts.total;
            final String invoiceNumber = invoiceDto.invoiceNumber;

            Optional<Invoice> dup = service.findDuplicateByProviderAndTotal(providerName, total, invoiceNumber);
            InvoiceResponseDto payload = new InvoiceResponseDto();
            payload.invoice = invoiceDto;
            if (dup.isPresent()) {
                Invoice existing = dup.get();
                payload.duplicate = true;
                payload.duplicateId = existing.getId();
                payload.duplicateInvoiceNumber = existing.getInvoiceNumber();
                payload.message = String.format(
                        "Duplicate invoice detected. This invoice is already in the system for provider %s with total %.2f.",
                        providerName == null ? "(unknown provider)" : providerName,
                        total == null ? 0.0 : total
                );
            } else {
                payload.duplicate = false;
                payload.message = null;
                payload.duplicateId = null;
                payload.duplicateInvoiceNumber = null;
            }

            // Step 4: Return the object
            return ResponseEntity.ok(payload);

        } catch (Exception e) {
            log.error("Error during LLM extraction: ", e);
            return ResponseEntity.internalServerError().body("Failed to process with LLM: " + e.getMessage());
        }
    }

    /**
     * Helper method to validate the list of uploaded files.
     */
    public final class JsonSanitizer {
        private JsonSanitizer() {}

        public static String extractFirstJsonObject(String s) {
            if (s == null) return null;
            String t = s.trim();

            // remove ```json ... ``` fences if present
            if (t.startsWith("```")) {
                int firstNewline = t.indexOf('\n');
                t = (firstNewline >= 0 ? t.substring(firstNewline + 1) : t).trim();
                int fence = t.lastIndexOf("```");
                if (fence >= 0) t = t.substring(0, fence).trim();
            }

            int start = t.indexOf('{');
            if (start < 0) return null;

            int depth = 0;
            boolean inStr = false, esc = false;
            for (int i = start; i < t.length(); i++) {
                char c = t.charAt(i);
                if (inStr) {
                    if (!esc && c == '\\') { esc = true; continue; }
                    if (!esc && c == '"') inStr = false;
                    esc = false;
                    continue;
                }
                if (c == '"') { inStr = true; continue; }
                if (c == '{') depth++;
                else if (c == '}') {
                    depth--;
                    if (depth == 0) return t.substring(start, i + 1);
                }
            }
            return null;
        }
    }

    private boolean isFileListInvalid(List<MultipartFile> files) {
        return files == null || files.isEmpty() || files.stream().allMatch(MultipartFile::isEmpty);
    }

    private static OffsetDateTime parseDate(String s) {
        return s == null || s.isBlank() ? null : OffsetDateTime.parse(s);
    }
    private static BigDecimal parseDecimal(String s) {
        return s == null || s.isBlank() ? null : new BigDecimal(s);
    }
}
package com.careconnect.controller;


import com.careconnect.dto.chat.AiRequest;
import com.careconnect.dto.invoice.InvoiceDto;
import com.careconnect.dto.invoice.PaymentDto;
import com.careconnect.model.invoice.Invoice;
import com.careconnect.service.invoice.InvoiceService;
import com.careconnect.service.invoice.LlmExtractionService;
import com.careconnect.service.invoice.TextractService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.converter.BeanOutputConverter;
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
    public InvoiceController(InvoiceService service ,TextractService textractService,LlmExtractionService llmExtractionService ) {
        this.service = service;
        this.llmExtractionService=llmExtractionService;
        this.textractService=textractService;
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
        try {
            // Step 1: Get raw text using the updated service
            AiRequest.AnalysisResult result = textractService.analyzeAndGetResult(files);

            // Step 2: Send raw text to the LLM service
            var json = llmExtractionService.extractInvoiceData(result.rawText);
            var outputConverter = new BeanOutputConverter<>(InvoiceDto.class);
            InvoiceDto invoiceDto=outputConverter.convert(json);
            invoiceDto.documentLink=result.s3Key;
            // Step 3: Return the object
            return ResponseEntity.ok(invoiceDto);

        } catch (Exception e) {
            log.error("Error during LLM extraction: ", e);
            return ResponseEntity.internalServerError().body("Failed to process with LLM: " + e.getMessage());
        }
    }

    /**
     * Helper method to validate the list of uploaded files.
     */
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

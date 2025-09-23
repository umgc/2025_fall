package com.careconnect.controller;

import com.careconnect.gateway.AiGateway;
import com.careconnect.gateway.AiRequest;
import com.careconnect.gateway.AiResult;
import com.careconnect.gateway.InvoiceExtractionService;
import com.careconnect.model.invoice.Invoice;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping(path = "/api/invoice-assistant", produces = MediaType.APPLICATION_JSON_VALUE)
@Validated
@CrossOrigin // adjust for your frontend
public class InvoiceAssistantController {

    private final AiGateway aiGateway;
    private final InvoiceExtractionService invoiceExtractionService;

    public InvoiceAssistantController(AiGateway aiGateway, InvoiceExtractionService invoiceExtractionService) {
        this.aiGateway = aiGateway;
        this.invoiceExtractionService = invoiceExtractionService;
    }

    // 1) Free-form AI chat for invoices
    @PostMapping(path = "/chat", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<InvoiceChatResponseDto> chat(@Valid @RequestBody InvoiceChatRequestDto req) {
        AiRequest aiReq = new AiRequest();
        aiReq.setProvider(nullIfBlank(req.provider));
        aiReq.setSystemPrompt(nullIfBlank(req.systemPrompt));
        aiReq.setUserPrompt(req.userPrompt);
        aiReq.setTemperature(req.temperature);
        aiReq.setMaxTokens(req.maxTokens);

        AiResult result = aiGateway.chat(aiReq);
        return ResponseEntity.ok(new InvoiceChatResponseDto(result.getText()));
    }

    // 2) Extract invoice data from OCR text
    @PostMapping(path = "/extract", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Invoice> extract(@Valid @RequestBody InvoiceExtractRequestDto req) {
        Invoice invoice = invoiceExtractionService.extractInvoice(req.ocrText, nullIfBlank(req.provider));
        return ResponseEntity.ok(invoice);
    }

    // 3) Summarize a parsed invoice
    @PostMapping(path = "/summarize", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<InvoiceSummaryResponseDto> summarize(@Valid @RequestBody InvoiceSummarizeRequestDto req) {
        String summary = invoiceExtractionService.summarizeInvoice(req.invoice, nullIfBlank(req.provider));
        return ResponseEntity.ok(new InvoiceSummaryResponseDto(summary));
    }

    private static String nullIfBlank(String s) {
        return (s == null || s.isBlank()) ? null : s;
    }

    // --- DTOs ---

    public static class InvoiceChatRequestDto {
        public String provider;
        @Size(max = 16000)
        public String systemPrompt;
        @NotBlank
        @Size(max = 16000)
        public String userPrompt;
        public Double temperature;
        public Integer maxTokens;
    }

    public static class InvoiceChatResponseDto {
        public String text;
        public InvoiceChatResponseDto() {}
        public InvoiceChatResponseDto(String text) { this.text = text; }
    }

    public static class InvoiceExtractRequestDto {
        public String provider;
        @NotBlank
        @Size(max = 200000)
        public String ocrText;
    }

    public static class InvoiceSummarizeRequestDto {
        public String provider;
        @Valid
        public Invoice invoice;
    }

    public static class InvoiceSummaryResponseDto {
        public String summary;
        public InvoiceSummaryResponseDto() {}
        public InvoiceSummaryResponseDto(String summary) { this.summary = summary; }
    }
}

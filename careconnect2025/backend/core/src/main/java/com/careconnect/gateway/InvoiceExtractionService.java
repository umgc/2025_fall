package com.careconnect.gateway;


import com.careconnect.gateway.AiGateway;
import com.careconnect.gateway.AiRequest;
import com.careconnect.model.invoice.Invoice;
import org.springframework.stereotype.Service;

@Service
public class InvoiceExtractionService {

    private static final String DEFAULT_PROVIDER = "deepseek";

    private final AiGateway gateway;

    public InvoiceExtractionService(AiGateway gateway) {
        this.gateway = gateway;
    }

    public Invoice extractInvoice(String ocrText, String provider) {
        String sys = InvoicePromptBuilder.systemPrompt();
        String user = InvoicePromptBuilder.userPrompt(ocrText, InvoiceSchema.jsonSchema());

        AiRequest req = new AiRequest();
        req.setProvider(provider != null && !provider.isBlank() ? provider : DEFAULT_PROVIDER);
        req.setSystemPrompt(sys);
        req.setUserPrompt(user);
        req.setTemperature(0.0);   // deterministic extraction
        req.setMaxTokens(1800);

        // Spring AI will parse the model output JSON into your record
        return gateway.structuredChat(req, Invoice.class);
    }

    public String summarizeInvoice(Invoice invoice, String provider) {
        String sys = "You summarize medical invoices for a layperson. No diagnosis or medical advice.";
        String user = """
        Summarize this invoice in 3 to 5 bullet points. Include payment plan if deemed necessary, financial assistance if available, service dates, total, paid, and balance

        Invoice JSON:
        %s
        """.formatted(toJson(invoice));

        AiRequest req = new AiRequest();
        req.setProvider(provider != null && !provider.isBlank() ? provider : DEFAULT_PROVIDER);
        req.setSystemPrompt(sys);
        req.setUserPrompt(user);
        req.setTemperature(0.2);
        req.setMaxTokens(400);

        return gateway.chat(req).getText();
    }

    private static String toJson(Object o) {
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(o);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to serialize invoice to JSON", e);
        }
    }
}

package com.careconnect.gateway;

public class InvoicePromptBuilder {

    public static String systemPrompt() {
        return """
        You are an expert medical billing parser.
        Extract structured data from noisy OCR text.
        Output a single JSON object that matches the provided JSON schema.
        If a field is unknown, omit it or set it to null.
        Do not fabricate data.
        Dates should be ISO 8601 when possible.
        """;
    }

    public static String userPrompt(String ocrText, String jsonSchema) {
        return """
        OCR text:
        ---
        %s
        ---

        Return one JSON object that conforms to this schema:
        %s
        """.formatted(ocrText, jsonSchema);
    }
}

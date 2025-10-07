import 'invoice_schema.dart';

const systemPrompt = '''
You extract structured data from medical invoices.
Return only JSON that validates against the provided JSON Schema.
Dates must be yyyy-MM-dd. Monetary values must be numbers.
If a value is unknown, use null. Output JSON only.
''';

String userPromptFromOcr(String ocrText) => '''
JSON_SCHEMA:
$invoiceJsonSchema

OCR_TEXT:
$ocrText

Instructions:
1) Map to the schema fields.
2) Arrays [] if empty.
3) paymentStatus must use allowed enum values.
4) createdAt and updatedAt may be current ISO timestamp.
Output JSON only.
''';

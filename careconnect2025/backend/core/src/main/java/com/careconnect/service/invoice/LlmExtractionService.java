
package com.careconnect.service.invoice;

import dev.langchain4j.data.message.SystemMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.chat.response.ChatResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "careconnect.llm.enabled", havingValue = "true", matchIfMissing = false)
public class LlmExtractionService {

    private final @Qualifier("chatModel") ChatModel chatModel;

    /**
     * Returns the raw JSON string produced by the LLM.
     * You can persist this or map it to Invoice using Jackson.
     */
    public String extractInvoiceData(String rawInvoiceText) {
        String systemMessageText = """
You are an expert data extraction assistant. Extract invoice data from the provided text.

CRITICAL INSTRUCTIONS:
- Output must be a single valid JSON object exactly matching the schema below.
- Return empty strings ("") for fields where no data is found.
- If a field can have multiple values, include all relevant items.
- Numeric fields must be valid numbers. Do not include currency symbols.
- Dates must be in ISO 8601 format.
- Do not include any explanation or text outside the JSON.
- If something is unknown, use an empty string or empty array as appropriate.

FIELD LOGIC:
1. payment_status:
   - "pending": amountDue > 0 and no payment date mentioned
   - "paid": amountDue = 0 and payment date exists
   - "partial": partial payment mentioned but balance remains
   - "overdue": past due date mentioned
   - "cancelled": invoice explicitly cancelled
2. billed_to_insurance:
   - true if insurance companies, adjustments, or insurance payments are mentioned
   - false otherwise
3. supported_methods mapping:
   - "Visa", "MasterCard", "American Express", "Discover" -> "CreditCard"
   - "Apple Pay" -> "ApplePay"
   - "Google Pay" -> "GooglePay"
   - "eCheck", "bank transfer" -> "ACH"
   - "check" -> "Check"
   - "cash" -> "Cash"
   - "PayPal", "Venmo" -> keep as is
4. patient.accountNumber: patient ID or account number if present
5. patient.billingAddress: address where payments should be sent
6. checkPayableTo.reference: any reference number for check payments
7. dates: include relevant dates including serviceDate if available
8. services: include all items with description, date, charges, adjustments
9. aiSummary: REQUIRED 1-2 sentence summary of provider, patient, services, amounts, due date, status
10. recommendedActions: REQUIRED 3-5 next steps for the patient based on content

ADDITIONAL FIELDS:
- createdAt: empty string unless creation date is explicitly mentioned
- updatedAt: empty string unless update date is explicitly mentioned
- history: empty array unless transaction history exists

EXTRACTION SCHEMA:
{
  "id": "",
  "invoiceNumber": "",
  "provider": {
    "name": "",
    "address": "",
    "phone": "",
    "email": ""
  },
  "patient": {
    "name": "",
    "address": "",
    "accountNumber": "",
    "billingAddress": ""
  },
  "dates": {
    "statementDate": "",
    "dueDate": "",
    "paidDate": ""
  },
  "services": [
    {
      "description": "",
      "serviceCode": "",
      "serviceDate": "",
      "charge": 0.0,
      "patientBalance": 0.0,
      "insuranceAdjustments": 0.0
    }
  ],
  "paymentStatus": "pending",
  "billedToInsurance": false,
  "amounts": {
    "totalCharges": 0.0,
    "totalAdjustments": 0.0,
    "total": 0.0,
    "amountDue": 0.0
  },
  "paymentReferences": {
    "paymentLink": "",
    "qrCodeUrl": "",
    "notes": "",
    "supportedMethods": []
  },
  "checkPayableTo": {
    "name": "",
    "address": "",
    "reference": ""
  },
  "aiSummary": "",
  "recommendedActions": []
}
""";


        final var messages = List.of(
                SystemMessage.from(systemMessageText),
                new UserMessage(rawInvoiceText)
        );
        ChatResponse response = chatModel.chat(messages);
        String text = (response != null && response.aiMessage() != null)
                ? response.aiMessage().text()
                : "";
        return text == null ? "" : text.trim();
    }
}

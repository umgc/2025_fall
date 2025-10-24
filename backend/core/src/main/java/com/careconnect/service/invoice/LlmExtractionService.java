package com.careconnect.service.invoice;


import com.careconnect.model.invoice.Invoice;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.converter.BeanOutputConverter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class LlmExtractionService {

    private final ChatModel chatModel;

    public String extractInvoiceData(String rawInvoiceText) {
        // 1. Create the BeanOutputConverter to specify the target class (Invoice)


        // 2. Create the system message, incorporating the format instructions from the converter
        String systemMessageText = """
You are an expert data extraction assistant. Your task is to extract information from the provided invoice text.

CRITICAL INSTRUCTIONS:
- Return empty strings ("") for fields where no data is found
- If a field has multiple values (like services), extract all available items
- For amounts and numbers, convert to appropriate data types (floats for money, integers for counts)
- For date return in ISO1601 format.
FIELD-SPECIFIC RULES:
1. payment_status:
   - "pending": if amount due > 0 and no payment date mentioned
   - "paid": if amount due = 0 and payment date exists
   - "partial": if partial payment mentioned but balance remains
   - "overdue": if past due date mentioned
   - "cancelled": if invoice explicitly cancelled
2. billed_to_insurance:
   - true: if insurance company names, adjustments, or payments are mentioned
   - false: if no insurance information present
3. supported_methods: Map payment methods from text to these standardized values:
   - "Visa", "MasterCard", "American Express", "Discover" → "CreditCard"
   - "Apple Pay" → "ApplePay"
   - "Google Pay" → "GooglePay"
   - "eCheck", "bank transfer" → "ACH"
   - "check" → "Check"
   - "cash" → "Cash"
   - "PayPal", "Venmo" → keep as is
4. patient.accountNumber: Extract patient ID or account number from the text
5. patient.billingAddress: Extract the address where payments should be sent
6. checkPayableTo.reference: Extract any reference numbers for check payments
7. dates: Extract all relevant dates including serviceDate if available
8. services: Extract all service line items with descriptions, dates, charges, and adjustments
9. aiSummary: REQUIRED - Generate a concise 1-2 sentence summary of the invoice including key details like provider, patient, services, amounts, due date, and payment status

10. recommendedActions: REQUIRED - Generate a list of 3-5 actionable recommendations based on the invoice content. Consider:
   - If insurance is mentioned but balance remains, suggest contacting insurance
   - If financial assistance is mentioned, suggest applying
   - If payment arrangements are mentioned, suggest calling to set up
   - If online payment is available, recommend using it
   - If due date is approaching, highlight urgency
   - If multiple payment methods are available, list them
   - If questions exist, suggest contacting customer service
ADDITIONAL FIELDS INSTRUCTIONS:
- createdAt: Leave as empty string unless creation date is explicitly mentioned
- updatedAt: Leave as empty string unless update date is explicitly mentioned
- history: Leave as empty array unless transaction history is provided
- aiSummary: MUST be generated - provide concise summary of the invoice
- recommendedActions: MUST be generated - provide actionable next steps for the patient
11. 
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
    "paidDate": null
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
  "paymentStatus": "pending", // MUST BE: pending, paid, partial, overdue, cancelled
  "billedToInsurance": false, // boolean
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
    "supportedMethods": [] // ARRAY OF: CreditCard, ApplePay, GooglePay, ACH, Check, Cash, PayPal, Venmo
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

        SystemMessage systemMessage = new SystemMessage(systemMessageText);
        // 3. Create the user message with the raw text
        UserMessage userMessage = new UserMessage(rawInvoiceText);

        // 4. Create the prompt and call the model
        Prompt prompt = new Prompt(List.of(systemMessage, userMessage));
        var chatResponse = chatModel.call(prompt);
        var text=chatResponse.getResult().getOutput().getText();
        // 5. Use the converter to parse the LLM's string output into a typed Invoice object
        return text;
    }
}
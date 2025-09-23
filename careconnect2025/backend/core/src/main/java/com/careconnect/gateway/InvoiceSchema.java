package com.careconnect.gateway;


public class InvoiceSchema {

    public static String jsonSchema() {
        return """
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "properties": {
            "id": { "type": ["string", "null"] },
            "invoiceNumber": { "type": ["string", "null"] },
            "provider": { "type": ["object", "null"], "properties": {
              "name": { "type": ["string", "null"] },
              "npi": { "type": ["string", "null"] },
              "address": { "type": ["string", "null"] },
              "phone": { "type": ["string", "null"] }
            }},
            "patient": { "type": ["object", "null"], "properties": {
              "fullName": { "type": ["string", "null"] },
              "dob": { "type": ["string", "null"] },
              "memberId": { "type": ["string", "null"] }
            }},
            "dates": { "type": ["object", "null"], "properties": {
              "serviceDate": { "type": ["string", "null"] },
              "billingDate": { "type": ["string", "null"] },
              "dueDate": { "type": ["string", "null"] }
            }},
            "services": {
              "type": ["array", "null"],
              "items": { "type": "object", "properties": {
                "cptCode": { "type": ["string", "null"] },
                "description": { "type": ["string", "null"] },
                "units": { "type": ["number", "null"] },
                "charge": { "type": ["number", "null"] }
              }}
            },
            "paymentStatus": { "type": ["string", "null"] },
            "billedToInsurance": { "type": ["boolean", "null"] },
            "amounts": { "type": ["object", "null"], "properties": {
              "total": { "type": ["number", "null"] },
              "paid": { "type": ["number", "null"] },
              "adjustments": { "type": ["number", "null"] },
              "balance": { "type": ["number", "null"] }
            }},
            "paymentReferences": { "type": ["object", "null"], "properties": {
              "claimNumber": { "type": ["string", "null"] },
              "checkNumber": { "type": ["string", "null"] },
              "remitAdvice": { "type": ["string", "null"] }
            }},
            "checkPayableTo": { "type": ["object", "null"], "properties": {
              "name": { "type": ["string", "null"] },
              "address": { "type": ["string", "null"] }
            }},
            "createdAt": { "type": ["string", "null"] },
            "updatedAt": { "type": ["string", "null"] },
            "history": {
              "type": ["array", "null"],
              "items": { "type": "object", "properties": {
                "event": { "type": ["string", "null"] },
                "timestamp": { "type": ["string", "null"] },
                "note": { "type": ["string", "null"] }
              }}
            },
            "aiSummary": { "type": ["string", "null"] },
            "recommendedActions": {
              "type": ["array", "null"],
              "items": { "type": "string" }
            }
          },
          "additionalProperties": false
        }
        """;
    }
}

const invoiceJsonSchema = r'''
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type":"object",
  "required": ["id","invoiceNumber","provider","patient","dates","services","amounts","paymentStatus","billedToInsurance","paymentReferences","createdAt","updatedAt","history"],
  "properties": {
    "id":{"type":"string"},
    "invoiceNumber":{"type":"string"},
    "provider":{"type":"object","required":["name","address","phone"],
      "properties":{"name":{"type":"string"},"address":{"type":"string"},"phone":{"type":"string"},"email":{"type":["string","null"]}}
    },
    "patient":{"type":"object","required":["name"],
      "properties":{"name":{"type":"string"},"address":{"type":["string","null"]},"accountNumber":{"type":["string","null"]},"billingAddress":{"type":["string","null"]}}
    },
    "dates":{"type":"object","required":["serviceDate","billedDate","dueDate"],
      "properties":{
        "serviceDate":{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$"},
        "billedDate":{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$"},
        "dueDate":{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$"},
        "paidDate":{"type":["string","null"],"pattern":"^\\d{4}-\\d{2}-\\d{2}$"}
      }
    },
    "services":{"type":"array",
      "items":{"type":"object","properties":{
        "description":{"type":["string","null"]},
        "serviceCode":{"type":["string","null"]},
        "serviceDate":{"type":["string","null"],"pattern":"^\\d{4}-\\d{2}-\\d{2}$"},
        "charge":{"type":["number","null"]},
        "patientBalance":{"type":["number","null"]},
        "insuranceAdjustments":{"type":["number","null"]}
      }, "additionalProperties": false}
    },
    "amounts":{"type":"object","properties":{
      "totalCharges":{"type":["number","null"]},
      "totalAdjustments":{"type":["number","null"]},
      "total":{"type":["number","null"]},
      "amountDue":{"type":["number","null"]}
    }, "additionalProperties": false},
    "paymentStatus":{"type":"string","enum":["pending","overdue","pendingInsurance","sent","paid","partialPayment","rejectedInsurance"]},
    "billedToInsurance":{"type":"boolean"},
    "paymentReferences":{"type":"object","required":["supportedMethods"],
      "properties":{
        "paymentLink":{"type":["string","null"]},
        "qrCodeUrl":{"type":["string","null"]},
        "notes":{"type":["string","null"]},
        "supportedMethods":{"type":"array","items":{"type":"string"}}
      }, "additionalProperties": false
    },
    "checkPayableTo":{"oneOf":[{"type":"null"},{"type":"object","required":["name","address","reference"],
      "properties":{"name":{"type":"string"},"address":{"type":"string"},"reference":{"type":"string"}}, "additionalProperties": false}]},
    "createdAt":{"type":"string"},
    "updatedAt":{"type":"string"},
    "history":{"type":"array","items":{"type":"object","required":["version","changes","userId","action","details","timestamp"],
      "properties":{"version":{"type":"integer"},"changes":{"type":"string"},"userId":{"type":"string"},"action":{"type":"string"},"details":{"type":"string"},"timestamp":{"type":"string"}}, "additionalProperties": false}},
    "aiSummary":{"type":["string","null"]},
    "recommendedActions":{"oneOf":[{"type":"null"},{"type":"array","items":{"type":"string"}}]}
  },
  "additionalProperties": false
}
''';

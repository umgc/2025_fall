import 'dart:convert';
import 'package:llm_toolkit/llm_toolkit.dart';

  
import 'package:care_connect_app/features/invoices/ai/prompt_templates.dart';
import 'package:care_connect_app/features/invoices/ai/invoice_json_guard.dart';
import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
class AiExtractorLLM {
  // Generate once
  static Future<String> _generateRaw(String ocrText) async {
    final prompt = '$systemPrompt\n\n${userPromptFromOcr(ocrText)}';
    final buf = StringBuffer();

    await for (final chunk in LLMToolkit.instance.generateText(
      prompt,
      params: GenerationParams.custom(
        maxTokens: 1024,
        temperature: 0.1,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.05,
      ),
    )) {
      buf.write(chunk);
    }
    return buf.toString();
  }

  // Try to obtain valid JSON, retry once with feedback if needed
  static Future<Map<String, dynamic>?> _generateValidJson(String ocrText) async {
    var guidance = '';
    for (var attempt = 0; attempt < 2; attempt++) {
      final out = await _generateRaw('$guidance$ocrText');

      // Some models prepend spaces or text. Trim to first '{'.
      final start = out.indexOf('{');
      if (start < 0) {
        guidance = 'The last output was not valid JSON. Output JSON only.\n\n';
        continue;
      }
      final candidate = out.substring(start);

      try {
        final obj = json.decode(candidate) as Map<String, dynamic>;
        final errs = InvoiceJsonGuard.validateBasic(obj);
        if (errs.isEmpty) return obj;
        guidance = 'Fix these validation issues: ${InvoiceJsonGuard.explain(errs)}\n\n';
      } catch (_) {
        guidance = 'The last output was not valid JSON. Output JSON only.\n\n';
      }
    }
    return null;
  }

  static Future<Invoice?> extract(String ocrText) async {
    final obj = await _generateValidJson(ocrText);
    if (obj == null) return null;
    return _toInvoice(obj);
  }

  // Mapping JSON -> your models
  static DateTime _d(String s) => DateTime.parse(s);
  static DateTime? _dn(dynamic s) => (s == null || s == "") ? null : DateTime.parse("$s");
  static double? _numOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

  static PaymentStatus _statusFrom(String? s) {
    switch (s) {
      case 'overdue': return PaymentStatus.overdue;
      case 'pendingInsurance': return PaymentStatus.pendingInsurance;
      case 'sent': return PaymentStatus.sent;
      case 'paid': return PaymentStatus.paid;
      case 'partialPayment': return PaymentStatus.partialPayment;
      case 'rejectedInsurance': return PaymentStatus.rejectedInsurance;
      default: return PaymentStatus.pending;
    }
  }

  static Invoice _toInvoice(Map<String, dynamic> m) {
    final provider = ProviderInfo(
      name: m['provider']?['name'] ?? '',
      address: m['provider']?['address'] ?? '',
      phone: m['provider']?['phone'] ?? '',
      email: m['provider']?['email'],
    );

    final patient = PatientInfo(
      name: m['patient']?['name'] ?? '',
      address: m['patient']?['address'],
      accountNumber: m['patient']?['accountNumber'],
      billingAddress: m['patient']?['billingAddress'],
    );

    final dates = InvoiceDates( 
      statementDate: _d(m['dates']?['billedDate'] ?? DateTime.now().toIso8601String().substring(0,10)),
      dueDate: _d(m['dates']?['dueDate'] ?? DateTime.now().toIso8601String().substring(0,10)),
      paidDate: _dn(m['dates']?['paidDate']),
    );

    final services = (m['services'] as List? ?? [])
        .map((x) => ServiceLine(
              description: x['description'],
              serviceCode: x['serviceCode'],
              serviceDate: _dn(x['serviceDate']),
              charge: _numOrNull(x['charge']),
              patientBalance: _numOrNull(x['patientBalance']),
              insuranceAdjustments: _numOrNull(x['insuranceAdjustments']),
            ))
        .toList();

    final amounts = Amounts(
      totalCharges: _numOrNull(m['amounts']?['totalCharges']),
      totalAdjustments: _numOrNull(m['amounts']?['totalAdjustments']),
      total: _numOrNull(m['amounts']?['total']),
      amountDue: _numOrNull(m['amounts']?['amountDue']),
    );

    final payRefs = PaymentReferences(
      paymentLink: m['paymentReferences']?['paymentLink'],
      qrCodeUrl: m['paymentReferences']?['qrCodeUrl'],
      notes: m['paymentReferences']?['notes'],
      supportedMethods: (m['paymentReferences']?['supportedMethods'] as List? ?? []).cast<String>(),
    );

    final check = m['checkPayableTo'] == null
        ? null
        : CheckPayableTo(
            name: m['checkPayableTo']?['name'] ?? '',
            address: m['checkPayableTo']?['address'] ?? '',
            reference: m['checkPayableTo']?['reference'] ?? '',
          );

    final nowIso = DateTime.now().toIso8601String();

    return Invoice(
      id: m['id'] ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: m['invoiceNumber'] ?? '',
      provider: provider,
      patient: patient,
      dates: dates,
      services: services,
      paymentStatus: _statusFrom(m['paymentStatus']),
      billedToInsurance: m['billedToInsurance'] == true,
      amounts: amounts,
      paymentReferences: payRefs,
      checkPayableTo: check,
      createdAt: m['createdAt'] ?? nowIso,
      updatedAt: m['updatedAt'] ?? nowIso,
      createdBy: m['createdBy'] ?? 'system',
      updatedBy: m['updatedBy'] ?? 'system',
      documentLink: m['documentLink'],
      history: const [],
      payments: const [],
      aiSummary: m['aiSummary'],
      recommendedActions: (m['recommendedActions'] as List?)?.cast<String>(),
    );
  }
}

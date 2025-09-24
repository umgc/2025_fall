package com.careconnect.model.invoice;

import java.util.List;
public record Invoice(
        String id,
        String invoiceNumber,
        ProviderInfo provider,
        PatientInfo patient,
        InvoiceDates dates,
        List<ServiceLine> services,
        PaymentStatus paymentStatus,
        boolean billedToInsurance,
        Amounts amounts,
        PaymentReferences paymentReferences,
        CheckPayableTo checkPayableTo,
        String createdAt,
        String updatedAt,
        List<HistoryEntry> history,
        String aiSummary,
        List<String> recommendedActions
) {}

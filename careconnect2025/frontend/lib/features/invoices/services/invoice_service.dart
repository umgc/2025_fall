import 'dart:async';
import 'package:flutter/material.dart';
import '../models/invoice_models.dart';

/// Central place to fetch invoices (mock now, API later).
class InvoiceService {
  InvoiceService._();
  static final instance = InvoiceService._();

  // In-memory store for mocks
  final List<Invoice> _store = _seed();

  // Simulate latency
  Future<T> _withDelay<T>(T value, {Duration d = const Duration(milliseconds: 250)}) async {
    await Future.delayed(d);
    return value;
  }

  /// Fetch invoices with optional filters and sort.
  /// sort: 'due_desc' | 'due_asc' | 'amount_desc' | 'amount_asc' | default billed desc
  Future<List<Invoice>> fetchInvoices({
    String? search,
    Set<PaymentStatus>? status,
    String? providerName,
    String? patientName,
    DateTimeRange? serviceRange,
    DateTimeRange? dueRange,
    RangeValues? amountRange,
    String? sort,
  }) async {
    List<Invoice> data = List.of(_store);

    // Search across invoice number, provider, patient
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      data = data.where((i) {
        final p = i.provider.name.toLowerCase();
        final pt = i.patient.name.toLowerCase();
        final num = i.invoiceNumber.toLowerCase();
        return p.contains(q) || pt.contains(q) || num.contains(q);
      }).toList();
    }

    // Status filter
    if (status != null && status.isNotEmpty) {
      data = data.where((i) => status.contains(i.paymentStatus)).toList();
    }

    // Provider filter
    if (providerName != null && providerName.isNotEmpty) {
      data = data.where((i) => i.provider.name == providerName).toList();
    }

    // Patient filter
    if (patientName != null && patientName.isNotEmpty) {
      data = data.where((i) => i.patient.name == patientName).toList();
    }

    // Service date range (dates.serviceDate is non-null in your model)
    if (serviceRange != null) {
      data = data.where((i) {
        final d = i.dates.serviceDate;
        return !d.isBefore(serviceRange.start) && !d.isAfter(serviceRange.end);
      }).toList();
    }

    // Due date range (dates.dueDate is non-null)
    if (dueRange != null) {
      data = data.where((i) {
        final d = i.dates.dueDate;
        return !d.isBefore(dueRange.start) && !d.isAfter(dueRange.end);
      }).toList();
    }

    // Amount range (amountDue can be null)
    if (amountRange != null) {
      data = data.where((i) {
        final amt = i.amounts.amountDue;
        if (amt == null) return false;
        return amt >= amountRange.start && amt <= amountRange.end;
      }).toList();
    }

    // Sorting
    switch (sort) {
      case 'due_desc':
        data.sort((a, b) => a.dates.dueDate.compareTo(b.dates.dueDate));
        data = data.reversed.toList();
        break;
      case 'due_asc':
        data.sort((a, b) => a.dates.dueDate.compareTo(b.dates.dueDate));
        break;
      case 'amount_desc':
        data.sort((a, b) => (a.amounts.amountDue ?? -double.infinity)
            .compareTo(b.amounts.amountDue ?? -double.infinity));
        data = data.reversed.toList();
        break;
      case 'amount_asc':
        data.sort((a, b) => (a.amounts.amountDue ?? double.infinity)
            .compareTo(b.amounts.amountDue ?? double.infinity));
        break;
      default:
        // newest billed first
        data.sort((a, b) => a.dates.billedDate.compareTo(b.dates.billedDate));
        data = data.reversed.toList();
    }

    return _withDelay(data);
  }

  Future<Invoice?> getById(String id) async {
    final found = _store.firstWhereOrNull((i) => i.id == id);
    return _withDelay(found);
  }

  /// Upsert after edits from detail screen.
  Future<Invoice> upsert(Invoice invoice) async {
    final idx = _store.indexWhere((i) => i.id == invoice.id);
    if (idx == -1) {
      _store.add(invoice);
    } else {
      _store[idx] = invoice;
    }
    return _withDelay(invoice, d: const Duration(milliseconds: 120));
  }

  /// Dev helper
  Future<void> reset() async {
    _store
      ..clear()
      ..addAll(_seed());
    await _withDelay(true);
  }
}

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// ---------- Mock fixtures ----------

List<Invoice> _seed() {
  final now = DateTime.now();
  DateTime d(int days) => now.add(Duration(days: days));

  return [
    Invoice(
      id: 'INV-1001',
      invoiceNumber: '1001',
      provider: const ProviderInfo(
        name: 'Green Valley Health',
        address: '123 Oak St, Springfield, NY',
        phone: '(555) 123-1001',
        email: 'billing@greenvalleyhealth.org',
      ),
      patient: const PatientInfo(
        name: 'Alex Johnson',
        address: '99 Maple Ave, Springfield, NY',
        accountNumber: 'AJ-8831',
      ),
      dates: InvoiceDates(
        serviceDate: d(-20),
        billedDate: d(-15),
        dueDate: d(10),
        // unpaid -> leave paidDate null if you want
        // paidDate: null,
      ),
      services: const [
        ServiceLine(
          description: 'Consultation',
          serviceCode: '99213',
          serviceDate: null, // optional; you already have dates.serviceDate
          charge: 180.0,
          patientBalance: 180.0,
          insuranceAdjustments: 0.0,
        ),
        ServiceLine(
          description: 'Lab Panel',
          serviceCode: '80050',
          serviceDate: null,
          charge: 40.5,
          patientBalance: 40.5,
          insuranceAdjustments: 0.0,
        ),
      ],
      paymentStatus: PaymentStatus.pending,
      billedToInsurance: false,
      amounts: const Amounts(
        totalCharges: 220.5,
        totalAdjustments: 0.0,
        amountDue: 220.5,
      ),
      paymentReferences: PaymentReferences(
        paymentLink: 'https://pay.greenvalleyhealth.org/1001',
        qrCodeUrl: null,
        notes: 'Online payment preferred. Financial assistance available.',
        supportedMethods: const ['Card', 'Online'],
      ),
      checkPayableTo: const CheckPayableTo(
        name: 'Green Valley Health',
        address: 'P.O. Box 1234, Springfield, NY 10010',
        reference: '1001',
      ),
      createdAt: d(-15).toIso8601String(),
      updatedAt: d(-15).toIso8601String(),
      history: [
        HistoryEntry(
          timestamp: d(-15).toIso8601String(),
          userId: 'system',
          action: 'created',
          details: 'Invoice created by OCR',
          version: 1,
          changes: '',
        ),
      ],
      aiSummary:
          'Consultation and labs. Insurance not applied. Consider calling provider about financial assistance.',
      recommendedActions: const [
        'Review insurance eligibility',
        'Contact provider for assistance options'
      ],
    ),
    Invoice(
      id: 'INV-1002',
      invoiceNumber: '1002',
      provider: const ProviderInfo(
        name: 'Blue Ridge Clinic',
        address: '45 Ridge Rd, Weston, NC',
        phone: '(555) 234-2002',
        email: 'billing@blueridgeclinic.com',
      ),
      patient: const PatientInfo(
        name: 'Maria Lopez',
        address: '12 Cedar Ln, Weston, NC',
        accountNumber: 'ML-5512',
      ),
      dates: InvoiceDates(
        serviceDate: d(-33),
        billedDate: d(-30),
        dueDate: d(-10),
        paidDate: d(-9),
      ),
      services: const [
        ServiceLine(
          description: 'Follow-up visit',
          serviceCode: '99212',
          serviceDate: null,
          charge: 95.0,
          patientBalance: 0.0,
          insuranceAdjustments: 95.0,
        ),
      ],
      paymentStatus: PaymentStatus.paid,
      billedToInsurance: true,
      amounts: const Amounts(
        totalCharges: 95.0,
        totalAdjustments: 95.0,
        amountDue: 0.0,
      ),
      paymentReferences: PaymentReferences(
        paymentLink: 'https://pay.blueridgeclinic.com/1002',
        qrCodeUrl: null,
        notes: 'Paid in full',
        supportedMethods: const ['Card', 'Online', 'Check'],
      ),
      checkPayableTo: null,
      createdAt: d(-30).toIso8601String(),
      updatedAt: d(-9).toIso8601String(),
      history: [
        HistoryEntry(
          timestamp: d(-30).toIso8601String(),
          userId: 'system',
          action: 'created',
          details: 'Invoice created',
          version: 1,
          changes: 'amount changed',
        ),
        HistoryEntry(
          timestamp: d(-9).toIso8601String(),
          userId: 'system',
          action: 'paid',
          details: 'Payment confirmation #BR-1002',
          changes: 'amount changed',
          version: 2,
        ),
      ],
      aiSummary: 'No further action required.',
      recommendedActions: const [],
    ),
    Invoice(
      id: 'INV-1003',
      invoiceNumber: '1003',
      provider: const ProviderInfo(
        name: 'Northside Pediatrics',
        address: '10 Elm St, Northside, IL',
        phone: '(555) 345-3003',
        email: 'billing@northsidepeds.org',
      ),
      patient: const PatientInfo(
        name: 'Sam Carter',
        address: '44 Willow Dr, Northside, IL',
        accountNumber: 'SC-9021',
      ),
      dates: InvoiceDates(
        serviceDate: d(-42),
        billedDate: d(-40),
        dueDate: d(-5),
        // Unpaid/overdue: no paidDate
      ),
      services: const [
        ServiceLine(
          description: 'Wellness visit',
          serviceCode: '99393',
          serviceDate: null,
          charge: 415.0,
          patientBalance: 415.0,
          insuranceAdjustments: 0.0,
        ),
      ],
      paymentStatus: PaymentStatus.overdue,
      billedToInsurance: false,
      amounts: const Amounts(
        totalCharges: 415.0,
        totalAdjustments: 0.0,
        amountDue: 415.0,
      ),
      paymentReferences: PaymentReferences(
        paymentLink: 'https://pay.northsidepeds.org/1003',
        qrCodeUrl: null,
        notes: 'Overdue fee may apply after 30 days.',
        supportedMethods: const ['Card', 'Online', 'Check'],
      ),
      checkPayableTo: const CheckPayableTo(
        name: 'Northside Pediatrics',
        address: '10 Elm St, Northside, IL',
        reference: '1003',
      ),
      createdAt: d(-40).toIso8601String(),
      updatedAt: d(-5).toIso8601String(),
      history: [
        HistoryEntry(
          timestamp: d(-40).toIso8601String(),
          userId: 'system',
          action: 'created',
          details: 'Invoice created',
          version: 1,
          changes: 'none',
        ),
      ],
      aiSummary: 'Overdue. Pay or set up payment plan.',
      recommendedActions: const [
        'Pay now or request a payment plan',
        'Ask about financial assistance'
      ],
    ),
    Invoice(
      id: 'INV-1004',
      invoiceNumber: '1004',
      provider: const ProviderInfo(
        name: 'City Imaging Center',
        address: '500 Center Ave, Austin, TX',
        phone: '(555) 456-4004',
        email: 'billing@cityimaging.com',
      ),
      patient: const PatientInfo(
        name: 'Alex Johnson',
        address: '99 Maple Ave, Springfield, NY',
        accountNumber: 'AJ-8831',
      ),
      dates: InvoiceDates(
        serviceDate: d(-14),
        billedDate: d(-12),
        dueDate: d(14),
        // no paidDate, claim rejected by insurance
      ),
      services: const [
        ServiceLine(
          description: 'MRI Scan',
          serviceCode: '70551',
          serviceDate: null,
          charge: 780.0,
          patientBalance: 780.0,
          insuranceAdjustments: 0.0,
        ),
      ],
      paymentStatus: PaymentStatus.rejectedInsurance,
      billedToInsurance: true,
      amounts: const Amounts(
        totalCharges: 780.0,
        totalAdjustments: 0.0,
        amountDue: 780.0,
      ),
      paymentReferences: PaymentReferences(
        paymentLink: 'https://pay.cityimaging.com/1004',
        qrCodeUrl: null,
        notes: 'Insurance rejected. Appeal possible.',
        supportedMethods: const ['Card', 'Online', 'Check'],
      ),
      checkPayableTo: null,
      createdAt: d(-12).toIso8601String(),
      updatedAt: d(-12).toIso8601String(),
      history: [
        HistoryEntry(
          timestamp: d(-12).toIso8601String(),
          userId: 'system',
          action: 'created',
          details: 'Invoice created',
          version: 1,
          changes: '',
        ),
      ],
      aiSummary: 'Insurance rejected. Consider appeal.',
      recommendedActions: const [
        'Contact insurer for appeal',
        'Ask provider for itemized bill'
      ],
    ),
    Invoice(
      id: 'INV-1005',
      invoiceNumber: '1005',
      provider: const ProviderInfo(
        name: 'Evergreen Dental',
        address: '88 Pine St, Boulder, CO',
        phone: '(555) 567-5005',
        email: 'billing@evergreendental.com',
      ),
      patient: const PatientInfo(
        name: 'Jamie Lee',
        address: '22 Aspen Way, Boulder, CO',
        accountNumber: 'JL-7742',
      ),
      dates: InvoiceDates(
        serviceDate: d(-9),
        billedDate: d(-7),
        dueDate: d(20),
      ),
      services: const [
        ServiceLine(
          description: 'Cleaning & X-Ray',
          serviceCode: 'D1110',
          serviceDate: null,
          charge: 120.0,
          patientBalance: 120.0,
          insuranceAdjustments: 0.0,
        ),
      ],
      paymentStatus: PaymentStatus.pendingInsurance,
      billedToInsurance: true,
      amounts: const Amounts(
        totalCharges: 120.0,
        totalAdjustments: 0.0,
        amountDue: 120.0,
      ),
      paymentReferences: PaymentReferences(
        paymentLink: 'https://pay.evergreendental.com/1005',
        qrCodeUrl: null,
        notes: 'Claim in process.',
        supportedMethods: const ['Card', 'Online', 'Check'],
      ),
      checkPayableTo: null,
      createdAt: d(-7).toIso8601String(),
      updatedAt: d(-7).toIso8601String(),
      history: [
        HistoryEntry(
          timestamp: d(-7).toIso8601String(),
          userId: 'system',
          action: 'created',
          details: 'Invoice created',
          version: 1,
          changes: '',
        ),
      ],
      aiSummary: 'Await insurer decision.',
      recommendedActions: const ['Track claim status'],
    ),
  ];
}

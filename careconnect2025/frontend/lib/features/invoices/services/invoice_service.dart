<<<<<<< HEAD
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/invoice_models.dart';

/// Central place to fetch invoices (mock now, API later).
=======
import 'dart:convert';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/services/auth_token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart'; // for openPdf
import '../models/invoice_models.dart';

/// REST-backed invoice service with filtering, sorting, and CRUD.
>>>>>>> origin/team_d_ocr_textract
class InvoiceService {
  InvoiceService._();
  static final instance = InvoiceService._();

<<<<<<< HEAD
  // In-memory store for mocks
  final List<Invoice> _store = _seed();

  // Simulate latency
  Future<T> _withDelay<T>(T value, {Duration d = const Duration(milliseconds: 250)}) async {
    await Future.delayed(d);
    return value;
  }

  /// Fetch invoices with optional filters and sort.
  /// sort: 'due_desc' | 'due_asc' | 'amount_desc' | 'amount_asc' | default billed desc
=======
  // ---------- Public API ----------

>>>>>>> origin/team_d_ocr_textract
  Future<List<Invoice>> fetchInvoices({
    String? search,
    Set<PaymentStatus>? status,
    String? providerName,
    String? patientName,
<<<<<<< HEAD
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
=======
    DateTimeRange? dueRange,
    RangeValues? amountRange,
    String? sort,
    int? page,
    int? pageSize,
  }) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse(ApiConstants.invoices).replace(queryParameters: _cleanQueryParams({
        'search': _nz(search),
        'status': status == null || status.isEmpty ? null : status.map(_paymentStatusToWire).join(','),
        'providerName': _nz(providerName),
        'patientName': _nz(patientName),
        'dueStart': dueRange == null ? null : _dateOnly(dueRange.start),
        'dueEnd': dueRange == null ? null : _dateOnly(dueRange.end),
        'amountMin': amountRange == null ? null : amountRange.start.toString(),
        'amountMax': amountRange == null ? null : amountRange.end.toString(),
        'sort': _nz(sort),
        'page': page?.toString(),
        'pageSize': pageSize?.toString(),
      }));

      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        print('Failed to fetch invoices: ${resp.statusCode} ${resp.body}');
        return <Invoice>[];
      }

      final body = jsonDecode(resp.body);
      if (body is List) {
        return body.map<Invoice>((e) => _invoiceFromJson(e as Map<String, dynamic>)).toList();
      }
      if (body is Map && body['items'] is List) {
        return (body['items'] as List)
            .map<Invoice>((e) => _invoiceFromJson(e as Map<String, dynamic>))
            .toList();
      }

      print('Unexpected list payload shape from invoices endpoint');
      return <Invoice>[];
    } catch (e) {
      print('Error fetching invoices: $e');
      return <Invoice>[];
    }
  }

  Future<Invoice?> getById(String id) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse('${ApiConstants.invoices}/$id');

      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        print('Failed to fetch invoice $id: ${resp.statusCode}');
        return null;
      }
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return _invoiceFromJson(map);
    } catch (e) {
      print('Error fetching invoice $id: $e');
      return null;
    }
  }

  Future<Invoice?> create(Invoice draft) async {
    try {
      final headers = {
        ...await AuthTokenManager.getAuthHeaders(),
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse(ApiConstants.invoices);

      final payload = _invoiceToJson(draft);
      final resp = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 201 && resp.statusCode != 200) {
        print('Failed to create invoice: ${resp.statusCode} ${resp.body}');
        return null;
      }
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return _invoiceFromJson(map);
    } catch (e) {
      print('Error creating invoice: $e');
      return null;
    }
  }

  Future<Invoice?> update(Invoice invoice) async {
    try {
      final headers = {
        ...await AuthTokenManager.getAuthHeaders(),
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse('${ApiConstants.invoices}/${invoice.id}');

      final payload = _invoiceToJson(invoice);
      final resp = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        print('Failed to update invoice ${invoice.id}: ${resp.statusCode} ${resp.body}');
        return null;
      }
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return _invoiceFromJson(map);
    } catch (e) {
      print('Error updating invoice ${invoice.id}: $e');
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse('${ApiConstants.invoices}/$id');

      final resp = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 204 || resp.statusCode == 200) {
        return true;
      }
      print('Failed to delete invoice $id: ${resp.statusCode} ${resp.body}');
      return false;
    } catch (e) {
      print('Error deleting invoice $id: $e');
      return false;
    }
  }

  Future<Invoice?> upsert(Invoice invoice) {
    if (invoice.id.startsWith('local-') || invoice.id.isEmpty) {
      return create(invoice);
    }
    return update(invoice);
  }

  // ---------- Payments ----------

  Future<Invoice?> recordPayment({
    required String invoiceId,
    required PaymentRecord record,
  }) async {
    try {
      final headers = {
        ...await AuthTokenManager.getAuthHeaders(),
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse('${ApiConstants.invoices}/$invoiceId/payments');

      final resp = await http
          .post(uri, headers: headers, body: jsonEncode(record.toJson()))
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        print('Failed to record payment: ${resp.statusCode} ${resp.body}');
        return null;
      }

      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return _invoiceFromJson(map);
    } catch (e) {
      print('Error recording payment: $e');
      return null;
    }
  }

  Future<Invoice?> deletePayment({
    required String invoiceId,
    required String paymentId,
  }) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse('${ApiConstants.invoices}/$invoiceId/payments/$paymentId');

      final resp = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        print('Failed to delete payment: ${resp.statusCode} ${resp.body}');
        return null;
      }
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return _invoiceFromJson(map);
    } catch (e) {
      print('Error deleting payment: $e');
      return null;
    }
  }

  // ---------- PDF helpers (optional) ----------

  String pdfDownloadUrl(String invoiceId) => '${ApiConstants.invoices}/$invoiceId/pdf';

  Future<bool> openPdf(String invoiceId) async {
    final url = pdfDownloadUrl(invoiceId);
    if (await canLaunchUrlString(url)) {
      return launchUrlString(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  // ---------- Helpers: query params ----------

  String? _nz(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

  Map<String, String> _cleanQueryParams(Map<String, String?> raw) {
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (v != null && v.isNotEmpty) out[k] = v;
    });
    return out;
  }

  String _dateOnly(DateTime d) {
    final utc = d.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }

  // ---------- Mappers: JSON <-> Models ----------

  Invoice _invoiceFromJson(Map<String, dynamic> j) {
    final payments = (j['payments'] as List<dynamic>? ?? const [])
        .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return Invoice(
      id: j['id'] as String,
      invoiceNumber: j['invoiceNumber'] as String? ?? '',
      provider: _providerFromJson(j['provider'] as Map<String, dynamic>),
      patient: _patientFromJson(j['patient'] as Map<String, dynamic>),
      dates: _datesFromJson(j['dates'] as Map<String, dynamic>),
      services: ((j['services'] as List?) ?? const [])
          .map<ServiceLine>((e) => _serviceFromJson(e as Map<String, dynamic>))
          .toList(),
      paymentStatus: _paymentStatusFromWire(j['paymentStatus'] as String?),
      billedToInsurance: j['billedToInsurance'] as bool? ?? false,
      amounts: _amountsFromJson(j['amounts'] as Map<String, dynamic>?),
      paymentReferences: _payRefsFromJson(j['paymentReferences'] as Map<String, dynamic>?),
      checkPayableTo: j['checkPayableTo'] == null
          ? null
          : _checkPayableFromJson(j['checkPayableTo'] as Map<String, dynamic>),
      createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: j['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      createdBy: j['createdBy'] as String? ?? 'system',
      updatedBy: j['updatedBy'] as String? ?? 'system',
      documentLink: j['documentLink'] as String?,
      history: ((j['history'] as List?) ?? const [])
          .map<HistoryEntry>((e) => _historyFromJson(e as Map<String, dynamic>))
          .toList(),
      payments: payments,
      aiSummary: j['aiSummary'] as String?,
      recommendedActions: (j['recommendedActions'] as List?)
          ?.map<String>((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> _invoiceToJson(Invoice i) {
    final map = <String, dynamic>{
      'id': i.id,
      'invoiceNumber': i.invoiceNumber,
      'provider': _providerToJson(i.provider),
      'patient': _patientToJson(i.patient),
      'dates': _datesToJson(i.dates),
      'services': i.services.map(_serviceToJson).toList(),
      'paymentStatus': _paymentStatusToWire(i.paymentStatus),
      'billedToInsurance': i.billedToInsurance,
      'amounts': _amountsToJson(i.amounts),
      'paymentReferences': _payRefsToJson(i.paymentReferences),
      'checkPayableTo': i.checkPayableTo == null ? null : _checkPayableToJson(i.checkPayableTo!),
      'createdAt': i.createdAt,
      'updatedAt': i.updatedAt,
      'createdBy': i.createdBy,
      'updatedBy': i.updatedBy,
      'documentLink': i.documentLink,
      'history': i.history.map(_historyToJson).toList(),
      'aiSummary': i.aiSummary,
      'recommendedActions': i.recommendedActions?.toList(),
      // Note: do not send payments here if you manage them with a dedicated endpoint
      // 'payments': i.payments.map((p) => p.toJson()).toList(),
    };

    map.removeWhere((_, v) => v == null);
    return map;
  }

  ProviderInfo _providerFromJson(Map<String, dynamic> j) => ProviderInfo(
        name: j['name'] as String? ?? '',
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String?,
      );

  Map<String, dynamic> _providerToJson(ProviderInfo p) => {
        'name': p.name,
        'address': p.address,
        'phone': p.phone,
        'email': p.email,
      };

  PatientInfo _patientFromJson(Map<String, dynamic> j) => PatientInfo(
        name: j['name'] as String? ?? '',
        address: j['address'] as String?,
        accountNumber: j['accountNumber'] as String?,
        billingAddress: j['billingAddress'] as String?,
      );

  Map<String, dynamic> _patientToJson(PatientInfo p) => {
        'name': p.name,
        'address': p.address,
        'accountNumber': p.accountNumber,
        'billingAddress': p.billingAddress,
      };

  InvoiceDates _datesFromJson(Map<String, dynamic> j) => InvoiceDates(
        statementDate: _parseDate(j['statementDate']),
        dueDate: _parseDate(j['dueDate']),
        paidDate: j['paidDate'] == null ? null : _parseDate(j['paidDate']),
      );

  Map<String, dynamic> _datesToJson(InvoiceDates d) => {
        'statementDate': d.statementDate.toIso8601String(),
        'dueDate': d.dueDate.toIso8601String(),
        'paidDate': d.paidDate?.toIso8601String(),
      };

  ServiceLine _serviceFromJson(Map<String, dynamic> j) => ServiceLine(
        description: j['description'] as String?,
        serviceCode: j['serviceCode'] as String?,
        serviceDate: j['serviceDate'] == null ? null : _parseDate(j['serviceDate']),
        charge: _asDouble(j['charge']),
        patientBalance: _asDouble(j['patientBalance']),
        insuranceAdjustments: _asDouble(j['insuranceAdjustments']),
      );

  Map<String, dynamic> _serviceToJson(ServiceLine s) => {
        'description': s.description,
        'serviceCode': s.serviceCode,
        'serviceDate': s.serviceDate?.toIso8601String(),
        'charge': s.charge,
        'patientBalance': s.patientBalance,
        'insuranceAdjustments': s.insuranceAdjustments,
      };

  Amounts _amountsFromJson(Map<String, dynamic>? j) => Amounts(
        totalCharges: _asDouble(j?['totalCharges']),
        totalAdjustments: _asDouble(j?['totalAdjustments']),
        total: _asDouble(j?['total']),
        amountDue: _asDouble(j?['amountDue']),
      );

  Map<String, dynamic> _amountsToJson(Amounts a) => {
        'totalCharges': a.totalCharges,
        'totalAdjustments': a.totalAdjustments,
        'total': a.total,
        'amountDue': a.amountDue,
      };

  PaymentReferences _payRefsFromJson(Map<String, dynamic>? j) => PaymentReferences(
        paymentLink: j?['paymentLink'] as String?,
        qrCodeUrl: j?['qrCodeUrl'] as String?,
        notes: j?['notes'] as String?,
        supportedMethods: (j?['supportedMethods'] as List?)
                ?.map<String>((e) => e.toString())
                .toList() ??
            const <String>[],
      );

  Map<String, dynamic> _payRefsToJson(PaymentReferences p) => {
        'paymentLink': p.paymentLink,
        'qrCodeUrl': p.qrCodeUrl,
        'notes': p.notes,
        'supportedMethods': p.supportedMethods.toList(),
      };

  CheckPayableTo _checkPayableFromJson(Map<String, dynamic> j) => CheckPayableTo(
        name: j['name'] as String? ?? '',
        address: j['address'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
      );

  Map<String, dynamic> _checkPayableToJson(CheckPayableTo c) => {
        'name': c.name,
        'address': c.address,
        'reference': c.reference,
      };

  HistoryEntry _historyFromJson(Map<String, dynamic> j) => HistoryEntry(
        version: (j['version'] as num?)?.toInt() ?? 1,
        changes: j['changes'] as String? ?? '',
        userId: j['userId'] as String? ?? '',
        action: j['action'] as String? ?? '',
        details: j['details'] as String? ?? '',
        timestamp: j['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> _historyToJson(HistoryEntry h) => {
        'version': h.version,
        'changes': h.changes,
        'userId': h.userId,
        'action': h.action,
        'details': h.details,
        'timestamp': h.timestamp,
      };

  // ---------- Low-level utils ----------

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw ArgumentError('Invalid date value: $v');
  }

  String _paymentStatusToWire(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.overdue:
        return 'overdue';
      case PaymentStatus.pendingInsurance:
        return 'pendingInsurance';
      case PaymentStatus.sent:
        return 'sent';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.partialPayment:
        return 'partialPayment';
      case PaymentStatus.rejectedInsurance:
        return 'rejectedInsurance';
    }
  }

  PaymentStatus _paymentStatusFromWire(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'pendinginsurance':
        return PaymentStatus.pendingInsurance;
      case 'sent':
        return PaymentStatus.sent;
      case 'paid':
        return PaymentStatus.paid;
      case 'partialpayment':
        return PaymentStatus.partialPayment;
      case 'rejectedinsurance':
        return PaymentStatus.rejectedInsurance;
      default:
        return PaymentStatus.pending;
    }
  }
>>>>>>> origin/team_d_ocr_textract
}

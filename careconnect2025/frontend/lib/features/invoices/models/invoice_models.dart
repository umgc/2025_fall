import 'dart:collection';
import 'package:flutter/foundation.dart';

@immutable
class ProviderInfo {
  final String name;
  final String address;
  final String phone;
  final String? email;

  const ProviderInfo({
    required this.name,
    required this.address,
    required this.phone,
    this.email,
  });

  ProviderInfo copyWith({
    String? name,
    String? address,
    String? phone,
    String? email, // note: cannot clear to null with this signature
  }) =>
      ProviderInfo(
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );
}

@immutable
class PatientInfo {
  final String name;
  final String? address;
  final String? accountNumber;
  final String? billingAddress;

  const PatientInfo({
    required this.name,
    this.address,
    this.accountNumber,
    this.billingAddress,
  });

  PatientInfo copyWith({
    String? name,
    String? address,
    String? accountNumber,
    String? billingAddress,
  }) =>
      PatientInfo(
        name: name ?? this.name,
        address: address ?? this.address,
        accountNumber: accountNumber ?? this.accountNumber,
        billingAddress: billingAddress ?? this.billingAddress,
      );
}

@immutable
class InvoiceDates {
  final DateTime serviceDate;   // yyyy-MM-dd
  final DateTime billedDate;    // yyyy-MM-dd
  final DateTime dueDate;       // yyyy-MM-dd
  final DateTime? paidDate;     // yyyy-MM-dd, null if unpaid

  const InvoiceDates({
    required this.serviceDate,
    required this.billedDate,
    required this.dueDate,
    this.paidDate,
  });

  InvoiceDates copyWith({
    DateTime? serviceDate,
    DateTime? billedDate,
    DateTime? dueDate,
    DateTime? paidDate, // cannot clear to null with this signature
  }) =>
      InvoiceDates(
        serviceDate: serviceDate ?? this.serviceDate,
        billedDate: billedDate ?? this.billedDate,
        dueDate: dueDate ?? this.dueDate,
        paidDate: paidDate ?? this.paidDate,
      );
}

@immutable
class ServiceLine {
  final String? description;
  final String? serviceCode;
  final DateTime? serviceDate;
  final double? charge;
  final double? patientBalance;
  final double? insuranceAdjustments;

  const ServiceLine({
    this.description,
    this.serviceCode,
    this.serviceDate,
    this.charge,
    this.patientBalance,
    this.insuranceAdjustments,
  });
}

@immutable
class Amounts {
  final double? totalCharges;
  final double? totalAdjustments;
  final double? total;
  final double? amountDue;

  const Amounts({
    this.totalCharges,
    this.totalAdjustments,
    this.total,
    this.amountDue,
  });
}

enum PaymentStatus {
  pending,
  overdue,
  pendingInsurance,
  sent,
  paid,
  partialPayment,
  rejectedInsurance,
}

@immutable
class PaymentReferences {
  final String? paymentLink;
  final String? qrCodeUrl;
  final String? notes;
  final UnmodifiableListView<String> supportedMethods;

  PaymentReferences({
    this.paymentLink,
    this.qrCodeUrl,
    this.notes,
    required List<String> supportedMethods,
  }) : supportedMethods = UnmodifiableListView(List<String>.from(supportedMethods));
}

@immutable
class CheckPayableTo {
  final String name;
  final String address;
  final String reference;

  const CheckPayableTo({
    required this.name,
    required this.address,
    required this.reference,
  });
}

@immutable
class HistoryEntry {
  final int version;
  final String changes;
  final String userId;
  final String action;
  final String details;
  final String timestamp; // consider DateTime if you’ll sort/filter often

  const HistoryEntry({
    required this.userId,
    required this.action,
    required this.details,
    required this.version,
    required this.changes,
    required this.timestamp,
  });
}

@immutable
class Invoice {
  final String id;
  final String invoiceNumber;

  final ProviderInfo provider;
  final PatientInfo patient;
  final InvoiceDates dates;
  final UnmodifiableListView<ServiceLine> services;

  final PaymentStatus paymentStatus;
  final bool billedToInsurance;

  final Amounts amounts;
  final PaymentReferences paymentReferences;
  final CheckPayableTo? checkPayableTo;

  final String createdAt;
  final String updatedAt;
  final UnmodifiableListView<HistoryEntry> history;

  final String? aiSummary;
  final UnmodifiableListView<String>? recommendedActions;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.provider,
    required this.patient,
    required this.dates,
    required List<ServiceLine> services,
    required this.paymentStatus,
    required this.billedToInsurance,
    required this.amounts,
    required this.paymentReferences,
    this.checkPayableTo,
    required this.createdAt,
    required this.updatedAt,
    required List<HistoryEntry> history,
    this.aiSummary,
    List<String>? recommendedActions,
  })  : services = UnmodifiableListView(List<ServiceLine>.from(services)),
        history = UnmodifiableListView(List<HistoryEntry>.from(history)),
        recommendedActions = recommendedActions == null
            ? null
            : UnmodifiableListView(List<String>.from(recommendedActions));

  Invoice copyWith({
    ProviderInfo? provider,
    PatientInfo? patient,
    InvoiceDates? dates,
    List<ServiceLine>? services,
    PaymentStatus? paymentStatus,
    bool? billedToInsurance,
    Amounts? amounts,
    PaymentReferences? paymentReferences,
    CheckPayableTo? checkPayableTo,
    String? updatedAt,
    List<HistoryEntry>? history,
    String? aiSummary,
    List<String>? recommendedActions,
  }) =>
      Invoice(
        id: id,
        invoiceNumber: invoiceNumber,
        provider: provider ?? this.provider,
        patient: patient ?? this.patient,
        dates: dates ?? this.dates,
        services: services ?? this.services,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        billedToInsurance: billedToInsurance ?? this.billedToInsurance,
        amounts: amounts ?? this.amounts,
        paymentReferences: paymentReferences ?? this.paymentReferences,
        checkPayableTo: checkPayableTo ?? this.checkPayableTo,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        history: history ?? this.history,
        aiSummary: aiSummary ?? this.aiSummary,
        recommendedActions: recommendedActions ?? this.recommendedActions,
      );
}
 

extension InvoiceFactories on Invoice {
  static Invoice empty() {
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String();

    return Invoice(
      id: 'local-${now.millisecondsSinceEpoch}',     // temporary client id
      invoiceNumber: '',                             // let server fill later
      provider: const ProviderInfo(
        name: '',
        address: '',
        phone: '',
        email: null,
      ),
      patient: const PatientInfo(
        name: '',
        address: null,
        accountNumber: null,
        billingAddress: null,
      ),
      dates: InvoiceDates(
        serviceDate: now,
        billedDate: now,
        dueDate: now.add(const Duration(days: 30)),
        paidDate: null,
      ),
      services: const <ServiceLine>[],
      paymentStatus: PaymentStatus.pending,
      billedToInsurance: false,
      amounts: const Amounts(
        totalCharges: 0,
        totalAdjustments: 0,
        total: 0,
        amountDue: 0,
      ),
      paymentReferences: PaymentReferences(
        paymentLink: null,
        qrCodeUrl: null,
        notes: null,
        supportedMethods: const <String>[],  
      ),
      checkPayableTo: null,
      createdAt: iso(now),
      updatedAt: iso(now),
      history: const <HistoryEntry>[],
      aiSummary: null,
      recommendedActions: const <String>[],
    );
  }
}

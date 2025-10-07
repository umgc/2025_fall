import 'dart:convert';

final _dateRx = RegExp(r'^\d{4}-\d{2}-\d{2}$');

class InvoiceJsonGuard {
  static List<String> validateBasic(Map<String, dynamic> m) {
    final errs = <String>[];

    bool has(String k) => m.containsKey(k);
    if (!has('provider')) errs.add('provider missing');
    if (!has('patient')) errs.add('patient missing');
    if (!has('dates')) errs.add('dates missing');
    if (!has('services')) errs.add('services missing');
    if (!has('amounts')) errs.add('amounts missing');
    if (!has('paymentStatus')) errs.add('paymentStatus missing');
    if (!has('billedToInsurance')) errs.add('billedToInsurance missing');
    if (!has('paymentReferences')) errs.add('paymentReferences missing');

    final dates = m['dates'] as Map<String, dynamic>?;

    String? d(String key) => dates == null ? null : (dates[key] as String?);
    for (final key in ['serviceDate','billedDate','dueDate']) {
      final v = d(key);
      if (v == null || !_dateRx.hasMatch(v)) errs.add('dates.$key invalid or missing');
    }
    final paid = d('paidDate');
    if (paid != null && paid.isNotEmpty && !_dateRx.hasMatch(paid)) {
      errs.add('dates.paidDate invalid');
    }

    return errs;
  }

  static String explain(List<String> errs) =>
      errs.isEmpty ? 'ok' : 'Fix: ${errs.join("; ")}';
}

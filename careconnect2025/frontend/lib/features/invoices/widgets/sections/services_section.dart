// sections/services_section.dart
import 'package:flutter/material.dart';
import '../components/key_value_row.dart';
import '../../models/invoice_models.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({
    super.key,
    required this.value,
    required this.isEditing,
    required this.onChanged,
  });

  final Invoice value;
  final bool isEditing;
  final ValueChanged<Invoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = value.services;
    final a = value.amounts;
    String money(double? v) => v == null ? '-' : '\$${v.toStringAsFixed(2)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Services & Charges', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...s.map((line) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.description ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Service Code: ${line.serviceCode ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
                    if (line.serviceDate != null)
                      Text('Service Date: ${_fmt(line.serviceDate!)}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: KeyValueRow('Total Charge', money(line.charge))),
                        if (line.insuranceAdjustments != null)
                          Expanded(child: KeyValueRow('Insurance Paid', money(line.insuranceAdjustments), success: true)),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Charges'),
                  Text(money(a.totalCharges)),
                ]),
                if ((a.totalAdjustments ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Insurance Adjustments'),
                    Text('-${money(a.totalAdjustments)}', style: const TextStyle(color: Color(0xFF059669))),
                  ]),
                ],
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Due', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    money(a.total ?? a.amountDue),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Services & Charges',
                style: Theme.of(context).textTheme.titleMedium),
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Service',
                onPressed: () async {
                  final newLine = await _showEditDialog(context, const ServiceLine());
                  if (newLine != null) {
                    final updated = [...s, newLine];
                    onChanged(value.copyWith(services: updated));
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...s.map(
          (line) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(line.description ?? 'Service',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () async {
                            final edited =
                                await _showEditDialog(context, line);
                            if (edited != null) {
                              final updated = s
                                  .map((e) => e == line ? edited : e)
                                  .toList();
                              onChanged(value.copyWith(services: updated));
                            }
                          },
                        ),
                    ],
                  ),
                  Text('Service Code: ${line.serviceCode ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (line.serviceDate != null)
                    Text('Service Date: ${_fmt(line.serviceDate!)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: KeyValueRow('Total Charge', money(line.charge))),
                      if (line.insuranceAdjustments != null)
                        Expanded(
                            child: KeyValueRow('Insurance Paid',
                                money(line.insuranceAdjustments),
                                success: true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Charges'),
                      Text(money(a.totalCharges)),
                    ]),
                if ((a.totalAdjustments ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Insurance Adjustments'),
                        Text('-${money(a.totalAdjustments)}',
                            style: const TextStyle(color: Color(0xFF059669))),
                      ]),
                ],
                const Divider(),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Due',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        money(a.total ?? a.amountDue),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
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

  Future<ServiceLine?> _showEditDialog(
      BuildContext context, ServiceLine line) async {
    final descCtrl = TextEditingController(text: line.description);
    final codeCtrl = TextEditingController(text: line.serviceCode);
    final chargeCtrl =
        TextEditingController(text: line.charge?.toStringAsFixed(2));
    final insCtrl = TextEditingController(
        text: line.insuranceAdjustments?.toStringAsFixed(2));

    return showDialog<ServiceLine>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Service Code'),
              ),
              TextField(
                controller: chargeCtrl,
                decoration: const InputDecoration(labelText: 'Charge'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: insCtrl,
                decoration:
                    const InputDecoration(labelText: 'Insurance Paid'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                line.copyWith(
                  description: descCtrl.text,
                  serviceCode: codeCtrl.text,
                  charge: double.tryParse(chargeCtrl.text),
                  insuranceAdjustments: double.tryParse(insCtrl.text),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

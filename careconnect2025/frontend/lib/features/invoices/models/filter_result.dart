import 'package:flutter/material.dart';
import 'invoice_models.dart';

class FilterResult {
  final String sort;
  final String search;
  final Set<PaymentStatus> status;
  final String? provider;
  final String? patient;
  final DateTimeRange? serviceRange;
  final DateTimeRange? dueRange;
  final RangeValues? amountRange;

  const FilterResult({
    required this.sort,
    required this.search,
    required this.status,
    this.provider,
    this.patient,
    this.serviceRange,
    this.dueRange,
    this.amountRange,
  });
}
class DesktopTable extends StatelessWidget {
  final List<Invoice> invoices;
  final void Function(Invoice) onView;
  final void Function(Invoice) onPay;

  const DesktopTable({
    required this.invoices,
    required this.onView,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Invoice #')),
        DataColumn(label: Text('Provider')),
        DataColumn(label: Text('Patient')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: invoices.map((i) {
        return DataRow(cells: [
          DataCell(Text(i.invoiceNumber)),
          DataCell(Text(i.provider.name)),
          DataCell(Text(i.patient.name)),
          DataCell(Text('\$${i.amounts.amountDue?.toStringAsFixed(2) ?? "-"}')),
          DataCell(Text(i.paymentStatus.name)),
          DataCell(Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => onView(i),
              ),
              IconButton(
                icon: const Icon(Icons.payment),
                onPressed: () => onPay(i),
              ),
            ],
          )),
        ]);
      }).toList(),
    );
  }
}

class MobileCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onView;
  final VoidCallback onPay;

  const MobileCard({
    required this.invoice,
    required this.onView,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(invoice.invoiceNumber),
        subtitle: Text(
          '${invoice.patient.name} • ${invoice.provider.name}\n'
          'Amount: \$${invoice.amounts.amountDue?.toStringAsFixed(2) ?? "-"}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.visibility), onPressed: onView),
            IconButton(icon: const Icon(Icons.payment), onPressed: onPay),
          ],
        ),
      ),
    );
  }
}

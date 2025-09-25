import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:flutter/material.dart';
import 'models/invoice_models.dart';

class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({
    super.key,
    required this.invoice,
    this.initialTabIndex = 0,
  });

  final Invoice invoice;
  final int initialTabIndex;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage>
    with TickerProviderStateMixin {
  late Invoice _edited;
  bool _editing = false;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _edited = widget.invoice;
    _tab = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusIcon = _statusIcon(_edited.paymentStatus, context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Invoice ${_edited.invoiceNumber}'),
            const SizedBox(width: 8),
            statusIcon,
          ],
        ),
        actions: [
          if (_editing)
            OutlinedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          if (_editing) const SizedBox(width: 8),
          if (_editing)
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          if (!_editing)
            OutlinedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Services'),
            Tab(text: 'Payment'),
            Tab(text: 'AI Insights'),
            Tab(text: 'History'),
          ],
        ),
      ),
      drawer: const CommonDrawer(currentRoute: '/invoice-assistant/detail'),
      body: TabBarView(
        controller: _tab,
        children: [
          _detailsTab(),
          _servicesTab(),
          _paymentTab(),
          _aiTab(),
          _historyTab(),
        ],
      ),
    );
  }

  // ------------------- Tabs -------------------

  Widget _detailsTab() {
    final p = _edited.provider;
    final pt = _edited.patient;

    InputDecoration dec(String label) => InputDecoration(labelText: label);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Provider Information',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: _editing,
                initialValue: p.name,
                decoration: dec('Provider Name'),
                onChanged: (v) => setState(() {
                  _edited = _edited.copyWith(provider: p.copyWith(name: v));
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                enabled: _editing,
                initialValue: p.email,
                decoration: dec('Email'),
                onChanged: (v) => setState(() {
                  _edited = _edited.copyWith(provider: p.copyWith(email: v));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: _editing,
                initialValue: p.phone,
                decoration: dec('Phone'),
                onChanged: (v) => setState(() {
                  _edited = _edited.copyWith(provider: p.copyWith(phone: v));
                }),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          enabled: _editing,
          initialValue: p.address,
          maxLines: 2,
          decoration: dec('Address'),
          onChanged: (v) => setState(() {
            _edited = _edited.copyWith(provider: p.copyWith(address: v));
          }),
        ),
        const Divider(height: 32),

        Text('Patient Information',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: _editing,
                initialValue: pt.name,
                decoration: dec('Patient Name'),
                onChanged: (v) => setState(() {
                  _edited = _edited.copyWith(patient: pt.copyWith(name: v));
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                enabled: _editing,
                initialValue: pt.accountNumber,
                decoration: dec('Account Number'),
                onChanged: (v) => setState(() {
                  _edited = _edited
                      .copyWith(patient: pt.copyWith(accountNumber: v));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          enabled: _editing,
          initialValue: pt.billingAddress,
          maxLines: 3,
          decoration: dec('Billing Address'),
          onChanged: (v) => setState(() {
            _edited =
                _edited.copyWith(patient: pt.copyWith(billingAddress: v));
          }),
        ),
        const Divider(height: 32),

        Text('Dates & Payment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dateField(
                'Service Date',
                _edited.dates.serviceDate,
                (v) => setState(() {
                  _edited = _edited.copyWith(
                    dates: _edited.dates.copyWith(serviceDate: v),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dateField(
                'Billed Date',
                _edited.dates.billedDate,
                (v) => setState(() {
                  _edited = _edited.copyWith(
                    dates: _edited.dates.copyWith(billedDate: v),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dateField(
                'Due Date',
                _edited.dates.dueDate,
                (v) => setState(() {
                  _edited = _edited.copyWith(
                    dates: _edited.dates.copyWith(dueDate: v),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _dateField(
          'Paid Date (optional)',
          _edited.dates.paidDate,
          (v) => setState(() {
            _edited =
                _edited.copyWith(dates: _edited.dates.copyWith(paidDate: v));
          }),
          optional: true,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PaymentStatus>(
          value: _edited.paymentStatus,
          decoration: const InputDecoration(labelText: 'Payment Status'),
          onChanged: _editing
              ? (v) => setState(
                  () => _edited = _edited.copyWith(paymentStatus: v))
              : null,
          items: PaymentStatus.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(_label(e)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _servicesTab() {
    final s = _edited.services;
    final amounts = _edited.amounts;

    String money(double? v) =>
        v == null ? '-' : '\$${v.toStringAsFixed(2)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Services & Charges',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...s.map(
          (line) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.description ?? 'Service',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Service Code: ${line.serviceCode ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (line.serviceDate != null)
                    Text(
                      'Service Date: ${_fmtDate(line.serviceDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _kv('Total Charge', money(line.charge)),
                      ),
                      if (line.insuranceAdjustments != null)
                        Expanded(
                          child: _kv(
                            'Insurance Paid',
                            money(line.insuranceAdjustments),
                            success: true,
                          ),
                        ),
                    ],
                  ),
                  if (line.insuranceAdjustments != null) const Divider(),
                  if (line.insuranceAdjustments != null &&
                      line.charge != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Patient Responsibility:',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          money(line.charge! - line.insuranceAdjustments!),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                    Text(money(amounts.totalCharges)),
                  ],
                ),
                if ((amounts.totalAdjustments ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Insurance Adjustments'),
                      Text(
                        '-${money(amounts.totalAdjustments)}',
                        style: const TextStyle(color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Due',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      money(amounts.total ?? amounts.amountDue),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentTab() {
    final paid = _edited.paymentStatus == PaymentStatus.paid;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('Payment Options',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Chip(
              label: Text(_label(_edited.paymentStatus)),
              backgroundColor: paid
                  ? const Color(0xFF059669)
                  : _edited.paymentStatus == PaymentStatus.rejectedInsurance
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.secondary,
              labelStyle: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_money),
              label: const Text('Record Payment'),
              onPressed: _openPaymentDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_edited.paymentReferences.paymentLink != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Online Payment Available'),
              subtitle: const Text(
                "Pay online using the provider's secure payment portal.",
              ),
              trailing: FilledButton.icon(
                onPressed: () {
                  // TODO: launch URL
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Pay Now'),
              ),
            ),
          ),
        if (_edited.checkPayableTo != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Check Payment Instructions',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _kv('Make check payable to', _edited.checkPayableTo!.name),
                  _kv('Mail payment to', _edited.checkPayableTo!.address,
                      muted: true),
                  _kv('Include invoice number', _edited.invoiceNumber,
                      mono: true),
                ],
              ),
            ),
          ),
        if (_edited.paymentReferences.notes != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Payment Notes'),
              subtitle: Text(_edited.paymentReferences.notes!),
            ),
          ),
      ],
    );
  }

  Widget _aiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('AI Summary'),
            subtitle: Text(_edited.aiSummary ?? 'No AI summary available.'),
          ),
        ),
        const SizedBox(height: 12),
        if (_edited.recommendedActions?.isNotEmpty == true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended Actions',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._edited.recommendedActions!.map(
                    (a) => ListTile(
                      leading: const Icon(Icons.check),
                      title: Text(a),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _historyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _edited.history
          .map(
            (h) => Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  'Version ${h.version} • ${DateTime.parse(h.timestamp).toLocal()}',
                ),
                subtitle: Text(h.changes),
              ),
            ),
          )
          .toList(),
    );
  }

  // ------------------- Actions & helpers -------------------

  void _openPaymentDialog() async {
    final res = await showDialog<_PaymentCapture>(
      context: context,
      builder: (_) => const _PaymentDialog(),
    );
    if (res == null) return;

    final newStatus =
        res.inFull ? PaymentStatus.paid : PaymentStatus.partialPayment;

    final newHistory = [
      ..._edited.history,
      HistoryEntry(
        version: _edited.history.length + 1,
        changes: res.inFull
            ? 'Payment completed in full'
            : 'Partial payment recorded (${res.partialAmount ?? 0})',
        timestamp: DateTime.now().toIso8601String(),
        userId: 'currentUser', // TODO: replace with real user id
        action: 'payment',
        details:
            'method=${res.method}; confirmation=${res.confirmation}; date=${res.date}',
      ),
    ];

    setState(() {
      _edited = _edited.copyWith(
        paymentStatus: newStatus,
        updatedAt: DateTime.now().toIso8601String(),
        history: newHistory,
        dates: _edited.dates.copyWith(
          paidDate: DateTime.tryParse(res.date),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.inFull ? 'Invoice marked paid in full' : 'Partial payment recorded',
        ),
      ),
    );
  }

  Widget _kv(
    String k,
    String v, {
    bool success = false,
    bool muted = false,
    bool mono = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: theme.textTheme.bodySmall),
        Text(
          v,
          style: TextStyle(
            color: success
                ? const Color(0xFF059669)
                : muted
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : null,
            fontFamily: mono ? 'monospace' : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Updated to use DateTime rather than String
  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onChanged, {
    bool optional = false,
  }) {
    final controller = TextEditingController(
      text: value == null ? '' : _fmtDate(value),
    );

    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: optional ? 'Not set' : null,
      ),
      onTap: !_editing
          ? null
          : () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 3),
                lastDate: DateTime(now.year + 3),
                initialDate: value ?? now,
              );
              if (picked != null) {
                onChanged(DateTime(picked.year, picked.month, picked.day));
                setState(() {}); // refresh text
              }
            },
    );
  }

  String _fmtDate(DateTime d) {
    // yyyy-MM-dd
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
    // If you prefer locale formatting later, swap to intl.
  }

  void _cancel() => setState(() {
        _edited = widget.invoice;
        _editing = false;
      });

  void _save() {
    setState(() => _editing = false);
    Navigator.pop(context, _edited);
  }

  Widget _statusIcon(PaymentStatus s, BuildContext context) {
    switch (s) {
      case PaymentStatus.paid:
        return const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18);
      case PaymentStatus.partialPayment:
        return const Icon(Icons.info, color: Color(0xFFF59E0B), size: 18);
      case PaymentStatus.rejectedInsurance:
        return Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 18);
      case PaymentStatus.overdue:
        return const Icon(Icons.warning, color: Color(0xFFF59E0B), size: 18);
      case PaymentStatus.pendingInsurance:
        return const Icon(Icons.schedule, color: Color(0xFF3B82F6), size: 18);
      case PaymentStatus.pending:
        return const Icon(Icons.schedule, color: Color(0xFFF59E0B), size: 18);
      case PaymentStatus.sent:
        return const Icon(Icons.outgoing_mail, color: Color(0xFF3B82F6), size: 18);
    }
  }

  String _label(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.pendingInsurance:
        return 'Pending Insurance';
      case PaymentStatus.sent:
        return 'Sent';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partialPayment:
        return 'Partial Payment';
      case PaymentStatus.rejectedInsurance:
        return 'Rejected by Insurance';
    }
  }
}

/* Payment dialog */

class _PaymentCapture {
  final bool inFull;
  final String method;
  final String date; // yyyy-MM-dd
  final String confirmation;
  final double? partialAmount;
  final bool hasPlan;
  final String? planDuration;
  const _PaymentCapture({
    required this.inFull,
    required this.method,
    required this.date,
    required this.confirmation,
    this.partialAmount,
    required this.hasPlan,
    this.planDuration,
  });
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog();

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  bool inFull = true;
  bool hasPlan = false;
  String method = 'credit_card';
  String date = DateTime.now().toIso8601String().split('T').first;
  String confirmation = '';
  double partial = 0;
  String planDuration = '3 months';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'check', child: Text('Check')),
                DropdownMenuItem(value: 'online', child: Text('Online Payment')),
                DropdownMenuItem(value: 'ach', child: Text('ACH')),
              ],
              onChanged: (v) => setState(() => method = v ?? method),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Payment Date'),
              initialValue: date,
              readOnly: true,
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                  initialDate: DateTime.parse(date),
                );
                if (picked != null) {
                  setState(() {
                    final m = picked.month.toString().padLeft(2, '0');
                    final d = picked.day.toString().padLeft(2, '0');
                    date = '${picked.year}-$m-$d';
                  });
                }
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Confirmation Number'),
              onChanged: (v) => confirmation = v,
            ),
            SwitchListTile(
              title: const Text('Payment in Full'),
              value: inFull,
              onChanged: (v) => setState(() => inFull = v),
            ),
            if (!inFull)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Partial Amount'),
                keyboardType: TextInputType.number,
                onChanged: (v) => partial = double.tryParse(v) ?? 0,
              ),
            if (!inFull)
              SwitchListTile(
                title: const Text('Set up payment plan'),
                value: hasPlan,
                onChanged: (v) => setState(() => hasPlan = v),
              ),
            if (!inFull && hasPlan)
              DropdownButtonFormField<String>(
                value: planDuration,
                decoration: const InputDecoration(labelText: 'Plan duration'),
                items: const [
                  DropdownMenuItem(value: '3 months', child: Text('3 months')),
                  DropdownMenuItem(value: '6 months', child: Text('6 months')),
                  DropdownMenuItem(value: '12 months', child: Text('12 months')),
                ],
                onChanged: (v) => setState(() => planDuration = v ?? planDuration),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _PaymentCapture(
                inFull: inFull,
                method: method,
                date: date,
                confirmation: confirmation,
                partialAmount: inFull ? null : partial,
                hasPlan: hasPlan,
                planDuration: hasPlan ? planDuration : null,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

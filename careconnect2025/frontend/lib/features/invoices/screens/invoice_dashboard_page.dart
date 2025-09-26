import 'package:flutter/material.dart';

import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'package:care_connect_app/features/invoices/services/invoice_service.dart';
import 'invoice_detail_page.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';

class InvoiceDashboardPage extends StatelessWidget {
  const InvoiceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const CommonDrawer(currentRoute: '/invoice-assistant/dashboard'),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 900; // breakpoint for desktop-like
          final pagePad = 16.0;
          final gap = 12.0;
          final columns = isWide ? 3 : 1;
          final cardWidth =
              (c.maxWidth - (pagePad * 2) - (gap * (columns - 1))) / columns;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(width: cardWidth, child: const _OverdueBlock()),
                SizedBox(
                  width: cardWidth,
                  child: _KpiCard(
                    icon: Icons.receipt_long,
                    title: 'Total Invoices',
                    subtitle: 'Active medical invoices',
                    valueBuilder: (m) => '${m.totalCount}',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _KpiCard(
                    icon: Icons.attach_money,
                    title: 'Total Amount',
                    subtitle: 'Across all invoices',
                    valueBuilder: (m) => _currency(m.totalAmount),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _KpiCard(
                    icon: Icons.schedule,
                    title: 'Pending Payments',
                    subtitle: 'Requires attention',
                    valueBuilder: (m) => _currency(m.pendingAmount),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _KpiCard(
                    icon: Icons.report_gmailerrorred_outlined,
                    title: 'Overdue Bills',
                    subtitle: 'Past due date',
                    valueBuilder: (m) => '${m.overdueCount}',
                  ),
                ),
                SizedBox(
                  width: isWide ? (cardWidth * 2 + gap) : cardWidth,
                  child: const _RecentActivityCard(),
                ),
                SizedBox(
                  width: cardWidth,
                  child: const _PaymentProgressCard(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* =====================  OVERDUE BLOCK  ===================== */

class _OverdueBlock extends StatelessWidget {
  const _OverdueBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('Urgent Attention Required',
                  style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Overdue and upcoming bills',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            FutureBuilder<List<Invoice>>(
              future: InvoiceService.instance.fetchInvoices(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(minHeight: 4),
                  );
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Text('No invoices found.');
                }
                final now = DateTime.now();
                final overdue = snap.data!
                    .where((i) =>
                        i.paymentStatus != PaymentStatus.paid &&
                        i.dates.dueDate.isBefore(now))
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overdue Bills (${overdue.length})',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...overdue.map((inv) => _OverdueTile(invoice: inv)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueTile extends StatelessWidget {
  const _OverdueTile({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${_fmt(invoice.dates.dueDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            avatar: const Icon(Icons.attach_money, size: 16),
            label: Text(
              _currency(invoice.amounts.amountDue ?? invoice.amounts.total ?? 0),
            ),
            backgroundColor: theme.colorScheme.error.withOpacity(.15),
            labelStyle: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceDetailPage(invoice: invoice),
                ),
              );
            },
            icon: const Icon(Icons.remove_red_eye, size: 16),
            label: const Text('View'),
          ),
        ],
      ),
    );
  }
}

/* =====================  KPI CARD  ===================== */

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueBuilder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String Function(_Metrics) valueBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_Metrics>(
      future: _loadMetrics(),
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final metrics = snap.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      if (loading)
                        const LinearProgressIndicator(minHeight: 4)
                      else
                        Text(
                          valueBuilder(metrics!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* =====================  RECENT ACTIVITY  ===================== */

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.update, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Recent Invoice Activity',
                  style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Latest updates and submissions',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            FutureBuilder<List<Invoice>>(
              future: InvoiceService.instance.fetchInvoices(sort: 'service_desc'),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator(minHeight: 4);
                }
                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const Text('No recent activity.');
                }
                // show up to 5
                return Column(
                  children: data.take(5).map((i) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          i.provider.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(_label(i.paymentStatus)),
                            const SizedBox(width: 12),
                            Text(_fmt(i.dates.serviceDate)),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(_currency(i.amounts.amountDue ??
                                  i.amounts.total ??
                                  0)),
                              backgroundColor: theme
                                  .colorScheme.surfaceVariant
                                  .withOpacity(.8),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InvoiceDetailPage(invoice: i),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.remove_red_eye, size: 16),
                              label: const Text('View'),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* =====================  PAYMENT PROGRESS  ===================== */

class _PaymentProgressCard extends StatelessWidget {
  const _PaymentProgressCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<_Metrics>(
          future: _loadMetrics(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator(minHeight: 4);
            }
            final m = snap.data!;
            final total = m.totalAmount;
            final paid = m.paidAmount;
            final remaining = (total - paid).clamp(0, double.infinity);
            final pct = total > 0 ? (paid / total) : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.trending_up, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Payment Progress',
                      style: theme.textTheme.titleMedium),
                ]),
                const SizedBox(height: 4),
                Text('Your payment completion rate',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paid Invoices', style: theme.textTheme.bodySmall),
                    Text('${(pct * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paid',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.green)),
                        Text(_currency(paid),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Remaining',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.error)),
                        Text(_currency(remaining),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Recent Invoice Insights',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const _Insight(text: 'Contact insurance for claim status'),
                const _Insight(
                    text: 'Explore financial assistance programs'),
                const _Insight(
                    text: 'Set up payment plans for large bills'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.check_circle_outline, size: 18),
      const SizedBox(width: 6),
      Expanded(child: Text(text)),
    ]);
  }
}

/* =====================  METRICS HELPERS  ===================== */

class _Metrics {
  final int totalCount;
  final double totalAmount;
  final double pendingAmount;
  final int overdueCount;
  final double paidAmount;

  _Metrics({
    required this.totalCount,
    required this.totalAmount,
    required this.pendingAmount,
    required this.overdueCount,
    required this.paidAmount,
  });
}

Future<_Metrics> _loadMetrics() async {
  final invoices = await InvoiceService.instance.fetchInvoices();
  final now = DateTime.now();

  final totalCount = invoices.length;

  double sumAmount(Invoice i) =>
      (i.amounts.amountDue ?? i.amounts.total ?? 0);

  final totalAmount =
      invoices.fold<double>(0, (s, i) => s + sumAmount(i));

  final pendingAmount = invoices
      .where((i) => i.paymentStatus == PaymentStatus.pending)
      .fold<double>(0, (s, i) => s + sumAmount(i));

  final overdueCount = invoices
      .where((i) =>
          i.paymentStatus != PaymentStatus.paid &&
          i.dates.dueDate.isBefore(now))
      .length;

  final paidAmount = invoices
      .where((i) => i.paymentStatus == PaymentStatus.paid)
      .fold<double>(0, (s, i) => s + sumAmount(i));

  return _Metrics(
    totalCount: totalCount,
    totalAmount: totalAmount,
    pendingAmount: pendingAmount,
    overdueCount: overdueCount,
    paidAmount: paidAmount,
  );
}

/* =====================  UTILS  ===================== */

String _fmt(DateTime d) => d.toLocal().toString().split(' ').first;

String _currency(num value) {
  final v = value.toDouble();
  return '\$${v.toStringAsFixed(2)}';
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
      return 'Rejected Insurance';
  }
}

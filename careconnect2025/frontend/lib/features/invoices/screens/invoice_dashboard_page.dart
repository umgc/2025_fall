import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'package:care_connect_app/features/invoices/services/invoice_service.dart';
import 'invoice_detail_page.dart';


class InvoiceDashboardPage extends StatefulWidget {
  const InvoiceDashboardPage({super.key});

  @override
  State<InvoiceDashboardPage> createState() => _InvoiceDashboardPageState();
}

class _InvoiceDashboardPageState extends State<InvoiceDashboardPage> {
  late final Future<List<Invoice>> _invoicesFuture = InvoiceService.instance.fetchInvoices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Invoice>>(
        future: _invoicesFuture,
        builder: (context, snap) {
          final loading = snap.connectionState != ConnectionState.done;
          final invoices = snap.data ?? const <Invoice>[];
          final metrics = _computeMetrics(invoices);

          return LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;
              final pagePad = 16.0;
              final gap = 12.0;
              final columns = isWide ? 3 : 1;
              final maxContentWidth = 1400.0; // keeps web from stretching too wide
              final contentWidth = c.maxWidth.clamp(0, maxContentWidth);
              final cardWidth = (contentWidth - (pagePad * 2) - (gap * (columns - 1))) / columns;

              Widget gridChild(Widget child, {bool span2 = false}) {
                return SizedBox(
                  width: span2 && isWide ? (cardWidth * 2 + gap) : cardWidth,
                  child: child,
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        gridChild(_OverdueBlock(invoices: invoices, loading: loading)),
                        gridChild(_KpiCard(
                          icon: Icons.receipt_long,
                          title: 'Total Invoices',
                          subtitle: 'Active medical invoices',
                          value: '${metrics.totalCount}',
                          loading: loading,
                        )),
                        gridChild(_KpiCard(
                          icon: Icons.attach_money,
                          title: 'Total Amount',
                          subtitle: 'Across all invoices',
                          value: _currency(metrics.totalAmount),
                          loading: loading,
                        )),
                        gridChild(_KpiCard(
                          icon: Icons.schedule,
                          title: 'Pending Payments',
                          subtitle: 'Requires attention',
                          value: _currency(metrics.pendingAmount),
                          loading: loading,
                        )),
                        gridChild(_KpiCard(
                          icon: Icons.report_gmailerrorred_outlined,
                          title: 'Overdue Bills',
                          subtitle: 'Past due date',
                          value: '${metrics.overdueCount}',
                          loading: loading,
                        )),
                        gridChild(_RecentActivityCard(invoices: invoices, loading: loading), span2: true),
                        gridChild(_PaymentProgressCard(metrics: metrics, loading: loading)),
                        gridChild(_PaymentStatusChartCard(invoices: invoices, loading: loading), span2: true),
                        gridChild(_MonthlyInvoiceTrendsCard(invoices: invoices, loading: loading), span2: true),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* =====================  OVERDUE BLOCK  ===================== */

class _OverdueBlock extends StatelessWidget {
  const _OverdueBlock({required this.invoices, required this.loading});
  final List<Invoice> invoices;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final overdue = invoices
        .where((i) => i.paymentStatus != PaymentStatus.paid && i.dates.dueDate.isBefore(now))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('Urgent Attention Required', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Overdue and upcoming bills', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (loading)
              const _BlockLoading(height: 120)
            else if (overdue.isEmpty)
              const Text('No invoices found.')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overdue Bills (${overdue.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...overdue.map((inv) => _OverdueTile(invoice: inv)),
                ],
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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 600),
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
                Text('Due: ${_fmt(invoice.dates.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),
          _AmountBadge(text: _currency(invoice.amounts.amountDue ?? invoice.amounts.total ?? 0)),
          FilledButton.tonalIcon(
            onPressed: () {
               Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: invoice)),
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
    required this.value,
    required this.loading,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (loading)
                    const LinearProgressIndicator(minHeight: 4)
                  else
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =====================  RECENT ACTIVITY  ===================== */

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.invoices, required this.loading});
  final List<Invoice> invoices;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = invoices.toList()
      ..sort((a, b) => b.dates.statementDate.compareTo(a.dates.statementDate));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.update, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Recent Invoice Activity', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Latest updates and submissions', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (loading)
              const _BlockLoading(height: 160)
            else if (data.isEmpty)
              const Text('No recent activity.')
            else
              Column(
                children: data.take(5).map((i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      title: Text(i.provider.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(_label(i.paymentStatus), style: theme.textTheme.bodySmall),
                          Text(_fmt(i.dates.statementDate), style: theme.textTheme.bodySmall),
                        ],
                      ),
                      trailing: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _AmountBadge(text: _currency(i.amounts.amountDue ?? i.amounts.total ?? 0)),
                            OutlinedButton.icon(
                           onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: i)),
                            );
},
                              icon: const Icon(Icons.remove_red_eye, size: 16),
                              label: const Text('View'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/* =====================  PAYMENT PROGRESS  ===================== */

class _PaymentProgressCard extends StatelessWidget {
  const _PaymentProgressCard({required this.metrics, required this.loading});
  final _Metrics metrics;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Card(child: Padding(padding: EdgeInsets.all(12), child: _BlockLoading(height: 160)));
    }

    final total = metrics.totalAmount;
    final paid = metrics.paidAmount;
    final remaining = (total - paid).clamp(0, double.infinity);
    final pct = total > 0 ? (paid / total) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Payment Progress', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Your payment completion rate', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Paid Invoices', style: theme.textTheme.bodySmall),
              Text('${(pct * 100).round()}%'),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: pct, minHeight: 10),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Paid', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(_currency(paid), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Remaining', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(_currency(remaining), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
            const SizedBox(height: 12),
            Text('Recent Invoice Insights', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const _Insight(text: 'Contact insurance for claim status'),
            const _Insight(text: 'Explore financial assistance programs'),
            const _Insight(text: 'Set up payment plans for large bills'),
          ],
        ),
      ),
    );
  }
}

/* =====================  STATUS PIE  ===================== */

class _PaymentStatusChartCard extends StatelessWidget {
  const _PaymentStatusChartCard({required this.invoices, required this.loading});
  final List<Invoice> invoices;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Card(child: Padding(padding: EdgeInsets.all(12), child: _BlockLoading(height: 240)));
    }

    final paid = invoices.where((i) => i.paymentStatus == PaymentStatus.paid).length;
    final pending = invoices.where((i) => i.paymentStatus == PaymentStatus.pending).length;
    final rejected = invoices.where((i) => i.paymentStatus == PaymentStatus.rejectedInsurance).length;
    final total = (paid + pending + rejected).clamp(1, 1 << 30);

    PieChartSectionData _section({required double value, required Color color}) {
      return PieChartSectionData(
        value: value <= 0 ? 0.001 : value,
        color: color,
        title: '',
        radius: 56,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.pie_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Payment Status Distribution', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Overview of invoice payment statuses', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: kIsWeb ? 1.8 : 1.5, // a touch wider on web to reduce wrap
              child: PieChart(
                PieChartData(
                  sections: [
                    _section(value: paid.toDouble(), color: Colors.green),
                    _section(value: pending.toDouble(), color: Colors.orange),
                    _section(value: rejected.toDouble(), color: Colors.red.shade600),
                  ],
                  centerSpaceRadius: 46,
                  sectionsSpace: 4,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(enabled: true),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                _LegendDot(color: Colors.green, label: 'Paid ($paid)'),
                _LegendDot(color: Colors.orange, label: 'Pending ($pending)'),
                _LegendDot(color: Colors.red.shade600, label: 'Rejected ($rejected)'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Total: $total', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/* =====================  MONTHLY TRENDS  ===================== */

class _MonthlyInvoiceTrendsCard extends StatelessWidget {
  const _MonthlyInvoiceTrendsCard({required this.invoices, required this.loading});
  final List<Invoice> invoices;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Card(child: Padding(padding: EdgeInsets.all(12), child: _BlockLoading(height: 260)));
    }

    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final label = _monthShort(d.month);
      return _MonthBucket(key: key, label: label, date: d);
    });

    final counts = Map<String, int>.fromEntries(months.map((m) => MapEntry(m.key, 0)));
    for (final inv in invoices) {
      final d = inv.dates.statementDate;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }

    final bars = months
        .map((m) => BarChartGroupData(
              x: months.indexOf(m),
              barRods: [
                BarChartRodData(
                  toY: (counts[m.key] ?? 0).toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ))
        .toList();

    final maxY = (counts.values.isEmpty ? 0 : counts.values.reduce((a, b) => a > b ? a : b)).toDouble();
    final yMax = (maxY <= 5) ? 6.0 : maxY + 2.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Monthly Invoice Trends', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Invoice volume and amounts over time', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2),
                  borderData: FlBorderData(show: false),
                  barGroups: bars,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 2, reservedSize: 28),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(months[idx].label, style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(enabled: true),
                  maxY: yMax,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =====================  SHARED / METRICS / UTILS  ===================== */

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

class _AmountBadge extends StatelessWidget {
  const _AmountBadge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.4)),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

class _MonthBucket {
  _MonthBucket({required this.key, required this.label, required this.date});
  final String key;
  final String label;
  final DateTime date;
}

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

_Metrics _computeMetrics(List<Invoice> invoices) {
  final now = DateTime.now();
  double sumAmount(Invoice i) => (i.amounts.amountDue ?? i.amounts.total ?? 0).toDouble();
  final totalAmount = invoices.fold<double>(0, (s, i) => s + sumAmount(i));
  final pendingAmount = invoices
      .where((i) => i.paymentStatus == PaymentStatus.pending)
      .fold<double>(0, (s, i) => s + sumAmount(i));
  final overdueCount =
      invoices.where((i) => i.paymentStatus != PaymentStatus.paid && i.dates.dueDate.isBefore(now)).length;
  final paidAmount =
      invoices.where((i) => i.paymentStatus == PaymentStatus.paid).fold<double>(0, (s, i) => s + sumAmount(i));
  return _Metrics(
    totalCount: invoices.length,
    totalAmount: totalAmount,
    pendingAmount: pendingAmount,
    overdueCount: overdueCount,
    paidAmount: paidAmount,
  );
}

String _monthShort(int m) =>
    const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

class _BlockLoading extends StatelessWidget {
  const _BlockLoading({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: LinearProgressIndicator(minHeight: 4)),
    );
  }
}

String _fmt(DateTime d) => d.toLocal().toString().split(' ').first;
String _currency(num value) => '\$${value.toDouble().toStringAsFixed(2)}';
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
import 'package:care_connect_app/features/invoices/models/filter_result.dart';
import 'package:care_connect_app/features/invoices/services/invoice_service.dart';
import 'package:care_connect_app/features/invoices/widgets/search_filter_sheet.dart';   
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:flutter/material.dart';
import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'invoice_detail_page.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key, this.quickFilter});
  final String? quickFilter; // 'all' | 'pending' | 'overdue' | 'rejected'

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Invoice> _invoices = [];
  bool _loading = true;

  String _searchQuery = '';
  String _sort = 'recently_added';
  Set<PaymentStatus> _statusFilter = {};
  String? _providerFilter;
  String? _patientFilter;
  DateTimeRange? _serviceRange;
  DateTimeRange? _dueRange;
  RangeValues? _amountRange;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    final results = await InvoiceService.instance.fetchInvoices(
      search: _searchQuery,
      status: _statusFilter,
      providerName: _providerFilter,
      patientName: _patientFilter,
      serviceRange: _serviceRange,
      dueRange: _dueRange,
      amountRange: _amountRange,
      sort: _mapSort(_sort),
    );

    // apply quick filter locally
    List<Invoice> filtered = results;
    final now = DateTime.now();
    switch (widget.quickFilter) {
      case 'pending':
        filtered = filtered
            .where((i) => i.paymentStatus == PaymentStatus.pending)
            .toList();
        break;
      case 'rejected':
        filtered = filtered
            .where((i) => i.paymentStatus == PaymentStatus.rejectedInsurance)
            .toList();
        break;
      case 'overdue':
        filtered = filtered.where((i) {
          final due = i.dates.dueDate;
          return i.paymentStatus != PaymentStatus.paid &&
              due.isBefore(now);
        }).toList();
        break;
      default:
        break;
    }

    setState(() {
      _invoices = filtered;
      _loading = false;
    });
  }

  // Map UI sort -> service sort. (Returns null for default.)
  String? _mapSort(String uiSort) {
    switch (uiSort) {
      case 'service_date_desc':
        return 'service_desc';
      case 'service_date_asc':
        return 'service_asc';
      case 'due_date_desc':
        return 'due_desc';
      case 'due_date_asc':
        return 'due_asc';
      case 'amount_desc':
        return 'amount_desc';
      case 'amount_asc':
        return 'amount_asc';
      case 'recently_added':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _invoices.fold<double>(
      0,
      (sum, i) => sum + (i.amounts.amountDue ?? i.amounts.total ?? 0),
    );

    final pendingCount = _invoices
        .where((i) => i.paymentStatus == PaymentStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        actions: [
          IconButton(
            tooltip: 'Search & Filter',
            onPressed: () async {
              final cfg = await showSearchFilterSheet(
                context: context,
                invoices: _invoices,
                initialSort: _sort,
                initialSearch: _searchQuery,
                initialStatus: _statusFilter,
                initialProvider: _providerFilter,
                initialPatient: _patientFilter,
                initialServiceRange: _serviceRange,
                initialDueRange: _dueRange,
                initialAmountRange: _amountRange,
              );

              if (cfg != null) {
                setState(() {
                  _sort = cfg.sort;
                  _searchQuery = cfg.search;
                  _statusFilter = cfg.status;
                  _providerFilter = cfg.provider;
                  _patientFilter = cfg.patient;
                  _serviceRange = cfg.serviceRange;
                  _dueRange = cfg.dueRange;
                  _amountRange = cfg.amountRange;
                });
                _fetch();
              }
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      drawer: const CommonDrawer(currentRoute: '/invoice-assistant/list'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // results header
                Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        const Icon(Icons.description, size: 20),
                        const SizedBox(width: 8),
                        const Text('Invoice Results'),
                        const SizedBox(width: 8),
                        if (_invoices.isNotEmpty)
                          Chip(label: Text('${_invoices.length} found')),
                      ],
                    ),
                    subtitle: Text(
                      'Total Amount: \$${total.toStringAsFixed(2)}'
                      '${pendingCount > 0 ? ' • $pendingCount pending' : ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // desktop or mobile
                LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 720;
                    if (isWide) {
                      return DesktopTable(
                        invoices: _invoices,
                        onView: _openDetail,
                        onPay: _openDetailPaymentTab,
                      );
                    }
                    return Column(
                      children: _invoices
                          .map(
                            (i) => MobileCard(
                              invoice: i,
                              onView: () => _openDetail(i),
                              onPay: () => _openDetailPaymentTab(i),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }

  void _openDetail(Invoice invoice) async {
    final updated = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: invoice)),
    );
    if (updated != null) {
      await InvoiceService.instance.upsert(updated);
      _fetch();
    }
  }

  void _openDetailPaymentTab(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InvoiceDetailPage(invoice: invoice, initialTabIndex: 2),
      ),
    );
  }
}

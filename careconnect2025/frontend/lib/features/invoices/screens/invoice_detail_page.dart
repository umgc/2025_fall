// invoice_detail_page.dart
import 'package:flutter/material.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';

import 'package:care_connect_app/features/invoices/models/invoice_models.dart';
import 'package:care_connect_app/features/invoices/widgets/toolbar/invoice_toolbar.dart';
import 'package:care_connect_app/features/invoices/widgets/components/prev_next_bar.dart';
import 'package:care_connect_app/features/invoices/widgets/sections/details_section.dart';
import 'package:care_connect_app/features/invoices/widgets/sections/services_section.dart';
import 'package:care_connect_app/features/invoices/widgets/sections/payment_section.dart';
import 'package:care_connect_app/features/invoices/widgets/sections/ai_section.dart';
import 'package:care_connect_app/features/invoices/widgets/sections/history_section.dart';
 
class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({
    super.key,
    required this.invoice,
    this.initialTabIndex = 0,
    this.isNew = false,
  });

  final Invoice invoice;
  final int initialTabIndex;
  final bool isNew;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage>
    with TickerProviderStateMixin {
  late Invoice _edited;
  late TabController _tab;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _edited = widget.invoice;
    _editing = widget.isNew;

    final tabCount = widget.isNew ? 3 : 5;
    final safeIndex = widget.initialTabIndex.clamp(0, tabCount - 1);
    _tab = TabController(length: tabCount, vsync: this, initialIndex: safeIndex)
      ..addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.isNew;
    final hasNumber = _edited.invoiceNumber.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(isNew && !hasNumber ? 'New Invoice' : 'Invoice ${_edited.invoiceNumber}'),
            const SizedBox(width: 8),
            if (!isNew || hasNumber) _statusIcon(_edited.paymentStatus, context),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Scrollable toolbar so actions never overflow
              InvoiceToolbar(
                isEditing: _editing,
                isNew: isNew,
                showPdf: !isNew, // hide PDF while creating
                onEdit: () => setState(() => _editing = true),
                onCancel: _cancel,
                onSave: _save,
                onPdf: () {}, // hook up export
                onClose: () => Navigator.pop(context),
              ),
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabs: _tabs(isNew),
              ),
            ],
          ),
        ),
      ),
      drawer: const CommonDrawer(currentRoute: '/invoice-assistant/detail'),
      body: TabBarView(
        controller: _tab,
        children: _views(isNew),
      ),
      bottomNavigationBar: PrevNextBar(
        canPrev: _tab.index > 0,
        isLast: _tab.index == _tab.length - 1,
        onPrev: () => _tab.animateTo(_tab.index - 1),
        onNextOrSave: () {
          if (_tab.index < _tab.length - 1) {
            _tab.animateTo(_tab.index + 1);
          } else {
            _save();
          }
        },
      ),
    );
  }

  List<Widget> _tabs(bool isNew) {
    final base = const [
      Tab(text: 'Details'),
      Tab(text: 'Services'),
      Tab(text: 'Payment'),
    ];
    if (isNew) return base;
    return [
      ...base,
      const Tab(text: 'AI Insights'),
      const Tab(text: 'History'),
    ];
  }

  List<Widget> _views(bool isNew) {
    final base = [
      DetailsSection(
        value: _edited,
        isEditing: _editing,
        onChanged: (v) => setState(() => _edited = v),
      ),
      ServicesSection(
        value: _edited,
        isEditing: _editing,
        onChanged: (v) => setState(() => _edited = v),
      ),
      PaymentSection(
        value: _edited,
        isEditing: _editing,
        onChanged: (v) => setState(() => _edited = v),
      ),
    ];
    if (isNew) return base;
    return [
      ...base,
      AiSection(value: _edited),
      HistorySection(value: _edited),
    ];
  }

  void _cancel() {
    if (widget.isNew) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _edited = widget.invoice;
      _editing = false;
    });
  }

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
}

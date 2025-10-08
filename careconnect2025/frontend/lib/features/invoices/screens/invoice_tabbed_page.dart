import 'package:flutter/material.dart';
import 'package:care_connect_app/features/invoices/screens/invoice_dashboard_page.dart';
import 'package:care_connect_app/features/invoices/screens/upload_invoice.dart';
import 'package:care_connect_app/features/invoices/screens/invoice_list_page.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';

class InvoiceTabbedPage extends StatefulWidget {
  const InvoiceTabbedPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<InvoiceTabbedPage> createState() => _InvoiceTabbedPageState();
}

class _InvoiceTabbedPageState extends State<InvoiceTabbedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final index = _tabController.index;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Assistant'),
        bottom: TabBar(
          unselectedLabelColor: Theme.of(context).secondaryHeaderColor,
          labelColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard_outlined, color: Colors.white), text: 'Dashboard'),
            Tab(icon: Icon(Icons.upload_file_outlined, color: Colors.white), text: 'Upload Invoice'),
            Tab(icon: Icon(Icons.list_alt_outlined, color: Colors.white), text: 'Invoice List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(key: const ValueKey('dashboard')),
          _UploadInvoiceTab(key: const ValueKey('upload')),
          _InvoiceListTab(key: const ValueKey('list')),
        ],
      ),
    );
  }
}

/// Wrapper that renders InvoiceDashboardPage without its Scaffold/AppBar/Drawer
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    // We'll use a nested Navigator to intercept the Scaffold
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const InvoiceDashboardPage(),
        );
      },
    );
  }
}

/// Wrapper that renders UploadInvoicePage without its Scaffold/AppBar/Drawer
class _UploadInvoiceTab extends StatelessWidget {
  const _UploadInvoiceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const UploadInvoicePage(),
        );
      },
    );
  }
}

/// Wrapper that renders InvoiceListPage without its Scaffold/AppBar/Drawer
class _InvoiceListTab extends StatelessWidget {
  const _InvoiceListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const InvoiceListPage(),
        );
      },
    );
  }
}
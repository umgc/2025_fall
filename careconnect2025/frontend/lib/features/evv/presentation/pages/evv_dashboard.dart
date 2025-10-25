import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/user_provider.dart';
import '../../../../services/evv_service.dart';
import '../../../../widgets/common_drawer.dart';
import '../../../../widgets/app_bar_helper.dart';
import 'evv_record_review.dart';
import 'evv_visit_history.dart';
import 'evv_corrections.dart';
import 'evv_offline_sync.dart';
import 'patient_selection_page.dart';

class EvvDashboard extends StatefulWidget {
  const EvvDashboard({super.key});

  @override
  State<EvvDashboard> createState() => _EvvDashboardState();
}

class _EvvDashboardState extends State<EvvDashboard> {
  final EvvService _evvService = EvvService();
  bool _isLoading = true;
  List<EvvOfflineQueue> _offlineQueue = [];
  int _pendingApprovals = 0;
  int _pendingCorrections = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user?.role == 'ADMIN' || user?.role == 'SUPERVISOR') {
        // Load admin/supervisor specific data
        final pendingApprovals = await _evvService.getPendingEorApprovals();
        final pendingCorrections = await _evvService.getPendingCorrections();
        
        setState(() {
          _pendingApprovals = pendingApprovals.length;
          _pendingCorrections = pendingCorrections.length;
        });
      }
      
      // Load offline queue for all users
      final offlineQueue = await _evvService.getOfflineQueue();
      setState(() {
        _offlineQueue = offlineQueue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isAdmin = user?.role == 'ADMIN';
    final isSupervisor = user?.role == 'SUPERVISOR';
    final isCaregiver = user?.role == 'CAREGIVER';

    if (_isLoading) {
      return Scaffold(
        drawer: const CommonDrawer(currentRoute: '/evv/dashboard'),
        appBar: AppBarHelper.createAppBar(
          context,
          title: 'EVV Dashboard',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const CommonDrawer(currentRoute: '/evv/dashboard'),
      appBar: AppBarHelper.createAppBar(
        context,
        title: 'EVV Dashboard',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        additionalActions: [
          if (_offlineQueue.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.sync),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_offlineQueue.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EvvOfflineSyncPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              _buildQuickStats(isAdmin, isSupervisor),
              const SizedBox(height: 24),
              
              // Main Actions
              _buildMainActions(isAdmin, isSupervisor, isCaregiver),
              const SizedBox(height: 24),
              
              // Pending Items (Admin/Supervisor only)
              if (isAdmin || isSupervisor) ...[
                _buildPendingItems(),
                const SizedBox(height: 24),
              ],
              
              // Offline Queue Status
              if (_offlineQueue.isNotEmpty) ...[
                _buildOfflineQueueStatus(),
                const SizedBox(height: 24),
              ],
              
              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isAdmin, bool isSupervisor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Offline Records',
                    '${_offlineQueue.length}',
                    Icons.cloud_off,
                    Colors.orange,
                  ),
                ),
                if (isAdmin || isSupervisor) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Approvals',
                      '$_pendingApprovals',
                      Icons.approval,
                      Colors.blue,
                    ),
                  ),
                ],
                if (isAdmin || isSupervisor) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Corrections',
                      '$_pendingCorrections',
                      Icons.edit,
                      Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(bool isAdmin, bool isSupervisor, bool isCaregiver) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (isCaregiver)
                  _buildActionButton(
                    'Start Visit',
                    Icons.play_circle,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientSelectionPage(),
                      ),
                    ),
                  ),
                if (isCaregiver)
                  _buildActionButton(
                    'Review Records',
                    Icons.rate_review,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EvvRecordReviewPage(),
                      ),
                    ),
                  ),
                if (isAdmin || isSupervisor)
                  _buildActionButton(
                    'Visit History',
                    Icons.history,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EvvVisitHistoryPage(),
                      ),
                    ),
                  ),
                if (isAdmin || isSupervisor)
                  _buildActionButton(
                    'Manage Corrections',
                    Icons.edit_note,
                    Colors.red,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EvvCorrectionsPage(),
                      ),
                    ),
                  ),
                _buildActionButton(
                  'Offline Sync',
                  Icons.sync,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EvvOfflineSyncPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Items',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_pendingApprovals > 0)
              ListTile(
                leading: const Icon(Icons.approval, color: Colors.blue),
                title: const Text('EOR Approvals'),
                subtitle: Text('$_pendingApprovals pending'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to EOR approvals
                },
              ),
            if (_pendingCorrections > 0)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.red),
                title: const Text('Corrections'),
                subtitle: Text('$_pendingCorrections pending'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EvvCorrectionsPage(),
                    ),
                  );
                },
              ),
            if (_pendingApprovals == 0 && _pendingCorrections == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No pending items'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineQueueStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Offline Queue',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('${_offlineQueue.length} records waiting to sync'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EvvOfflineSyncPage(),
                  ),
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No recent activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _evvService.dispose();
    super.dispose();
  }
}

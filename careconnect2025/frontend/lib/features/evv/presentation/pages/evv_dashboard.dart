import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        final pendingApprovals = await _evvService.getPendingEorApprovals();
        final pendingCorrections = await _evvService.getPendingCorrections();
        setState(() {
          _pendingApprovals = pendingApprovals.length;
          _pendingCorrections = pendingCorrections.length;
        });
      }

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

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        drawer: const CommonDrawer(currentRoute: '/evv/dashboard'),
        appBar: AppBarHelper.createAppBar(context, title: 'EVV Dashboard'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const CommonDrawer(currentRoute: '/evv/dashboard'),
      appBar: AppBarHelper.createAppBar(
        context,
        title: 'EVV Dashboard',
        additionalActions: [
          if (_offlineQueue.isNotEmpty)
            IconButton(
              tooltip: 'Offline sync',
              icon: Badge.count(
                count: _offlineQueue.length,
                backgroundColor: scheme.error,
                textColor: scheme.onError,
                child: const Icon(Icons.sync),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final horizontalPadding = maxWidth < 600
                ? 16.0
                : maxWidth < 1024
                    ? 20.0
                    : 24.0;

            final content = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuickStats(
                        offlineCount: _offlineQueue.length,
                        pendingApprovals: _pendingApprovals,
                        pendingCorrections: _pendingCorrections,
                        showManagerTiles: isAdmin || isSupervisor,
                      ),
                      const SizedBox(height: 24),
                      _MainActions(
                        isAdmin: isAdmin,
                        isSupervisor: isSupervisor,
                        isCaregiver: isCaregiver,
                      ),
                      const SizedBox(height: 24),
                      if (isAdmin || isSupervisor) ...[
                        _PendingItems(
                          pendingApprovals: _pendingApprovals,
                          pendingCorrections: _pendingCorrections,
                          onOpenCorrections: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EvvCorrectionsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_offlineQueue.isNotEmpty) ...[
                        _OfflineQueueStatus(
                          count: _offlineQueue.length,
                          onSync: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EvvOfflineSyncPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      _RecentActivity(),
                    ],
                  ),
                ),
              ),
            );

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SafeArea(child: content),
            );
          },
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

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.offlineCount,
    required this.pendingApprovals,
    required this.pendingCorrections,
    required this.showManagerTiles,
  });

  final int offlineCount;
  final int pendingApprovals;
  final int pendingCorrections;
  final bool showManagerTiles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final items = <_StatItem>[
      _StatItem(
        label: 'Offline Records',
        value: offlineCount.toString(),
        icon: Icons.cloud_off,
        color: scheme.tertiary,
      ),
      if (showManagerTiles)
        _StatItem(
          label: 'Pending Approvals',
          value: pendingApprovals.toString(),
          icon: Icons.approval,
          color: scheme.primary,
        ),
      if (showManagerTiles)
        _StatItem(
          label: 'Pending Corrections',
          value: pendingCorrections.toString(),
          icon: Icons.edit,
          color: scheme.error,
        ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width < 480
                    ? 1
                    : width < 840
                        ? 2
                        : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 96,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) => _StatCard(item: items[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surfaceVariant;

    return Card(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: item.color.withOpacity(0.15),
              foregroundColor: item.color,
              child: Icon(item.icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold, color: item.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  const _MainActions({
    required this.isAdmin,
    required this.isSupervisor,
    required this.isCaregiver,
  });

  final bool isAdmin;
  final bool isSupervisor;
  final bool isCaregiver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final actions = <_ActionItem>[
      if (isCaregiver)
        _ActionItem(
          label: 'Start Visit',
          icon: Icons.play_circle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientSelectionPage()),
          ),
        ),
      if (isCaregiver)
        _ActionItem(
          label: 'Review Records',
          icon: Icons.rate_review,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EvvRecordReviewPage()),
          ),
        ),
      if (isAdmin || isSupervisor)
        _ActionItem(
          label: 'Visit History',
          icon: Icons.history,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EvvVisitHistoryPage()),
          ),
        ),
      if (isAdmin || isSupervisor)
        _ActionItem(
          label: 'Manage Corrections',
          icon: Icons.edit_note,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EvvCorrectionsPage()),
          ),
        ),
      _ActionItem(
        label: 'Offline Sync',
        icon: Icons.sync,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EvvOfflineSyncPage()),
        ),
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Actions',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width < 480
                    ? 2
                    : width < 840
                        ? 3
                        : 5;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 112,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) => _ActionCard(item: actions[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});
  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(item.icon),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingItems extends StatelessWidget {
  const _PendingItems({
    required this.pendingApprovals,
    required this.pendingCorrections,
    required this.onOpenCorrections,
  });

  final int pendingApprovals;
  final int pendingCorrections;
  final VoidCallback onOpenCorrections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Items',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (pendingApprovals > 0)
              ListTile(
                leading: const Icon(Icons.approval),
                title: const Text('EOR Approvals'),
                subtitle: Text('$pendingApprovals pending'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to EOR approvals
                },
              ),
            if (pendingCorrections > 0)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Corrections'),
                subtitle: Text('$pendingCorrections pending'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: onOpenCorrections,
              ),
            if (pendingApprovals == 0 && pendingCorrections == 0)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: Text('No pending items')),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfflineQueueStatus extends StatelessWidget {
  const _OfflineQueueStatus({required this.count, required this.onSync});
  final int count;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off),
                const SizedBox(width: 8),
                Text(
                  'Offline Queue',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('$count records waiting to sync'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onSync,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
}

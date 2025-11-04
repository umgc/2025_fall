import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_token_manager.dart';
import '../../../dashboard/models/patient_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<ScheduledVisit> _scheduledVisits = [];
  List<ScheduledVisit> _upcomingVisits = [];
  bool _isLoading = false;
  Map<String, int> _summaryData = {
    'overdue': 0,
    'ready': 0,
    'upcoming': 0,
    'totalToday': 0,
  };

  // Internal pool used to compute summary consistently with UI
  List<ScheduledVisit> _summaryPool = [];

  @override
  void initState() {
    super.initState();
    _loadScheduledVisits();
    _loadUpcomingVisits();
    _loadAndSetSummaryData();
  }

  Future<void> _refreshAllData() async {
    print('🔄 Refreshing all schedule data...');
    await Future.wait([
      _loadScheduledVisits(),
      _loadUpcomingVisits(),
      _loadAndSetSummaryData(),
    ]);
    print('✅ Data refresh complete');
  }

  Future<void> _loadAndSetSummaryData() async {
    final data = await _loadSummaryDataClientSide();
    setState(() {
      _summaryData = data;
    });
  }

  Future<void> _loadScheduledVisits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final caregiverId = userProvider.user?.caregiverId ?? 1;

      final headers = await AuthTokenManager.getAuthHeaders();
      final baseUrl = ApiConstants.baseUrl;

      // Fetch a range from the past 7 days up to today so we can include recent overdue items
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final startStr = DateFormat('yyyy-MM-dd').format(weekAgo);
      final endStr = DateFormat('yyyy-MM-dd').format(now);
      final url = Uri.parse(
        '${baseUrl}scheduled-visits/caregiver/$caregiverId/range?startDate=$startStr&endDate=$endStr',
      );

      print('🔍 Fetching scheduled visits (week range) from: $url');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final all = data.map((json) => ScheduledVisit.fromJson(json)).toList();

        // Keep today's visits and overdue (within past 7 days) that are still Scheduled
        final today = DateTime(now.year, now.month, now.day);
        final startWindow = now.subtract(const Duration(days: 7));
        final visits = all.where((v) {
          final dt = v.scheduledTime;
          final isToday =
              dt.year == today.year &&
              dt.month == today.month &&
              dt.day == today.day;
          final isOverdueWithinWeek =
              dt.isBefore(now) &&
              dt.isAfter(startWindow) &&
              v.status == 'Scheduled';
          return isToday || isOverdueWithinWeek;
        }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

        setState(() {
          _scheduledVisits = visits;
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load scheduled visits: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading scheduled visits: $e');
      setState(() {
        _scheduledVisits = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingVisits() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final caregiverId = userProvider.user?.caregiverId ?? 1;

      final headers = await AuthTokenManager.getAuthHeaders();
      final baseUrl = ApiConstants.baseUrl;

      // Get date range: tomorrow to 30 days out
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final endDate = DateTime.now().add(const Duration(days: 30));

      final startDateStr = DateFormat('yyyy-MM-dd').format(tomorrow);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      final url = Uri.parse(
        '${baseUrl}scheduled-visits/caregiver/$caregiverId/range?startDate=$startDateStr&endDate=$endDateStr',
      );

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final visits = data
            .map((json) => ScheduledVisit.fromJson(json))
            .toList();

        // Sort by date and time
        visits.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

        setState(() {
          _upcomingVisits = visits;
        });
      } else {
        throw Exception(
          'Failed to load upcoming visits: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading upcoming visits: $e');
      setState(() {
        _upcomingVisits = [];
      });
    }
  }

  Future<Map<String, int>> _loadSummaryDataClientSide() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final caregiverId = userProvider.user?.caregiverId ?? 1;
      final headers = await AuthTokenManager.getAuthHeaders();
      final baseUrl = ApiConstants.baseUrl;

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final end = now.add(const Duration(days: 30));
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      final url = Uri.parse(
        '${baseUrl}scheduled-visits/caregiver/$caregiverId/range?startDate=$startStr&endDate=$endStr',
      );
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200)
        throw Exception('summary range fetch failed');
      final List<dynamic> data = jsonDecode(response.body);
      _summaryPool = data.map((json) => ScheduledVisit.fromJson(json)).toList();

      int overdue = 0, ready = 0, upcoming = 0, totalToday = 0;
      for (final v in _summaryPool) {
        if (v.status != 'Scheduled') continue; // only pending visits
        final dt = v.scheduledTime;
        final isToday =
            dt.year == now.year && dt.month == now.month && dt.day == now.day;
        if (isToday) totalToday++;
        final diffMinutes = dt.difference(now).inMinutes;
        if (diffMinutes < 0) {
          overdue++;
        } else if (diffMinutes <= 30) {
          ready++;
        } else {
          upcoming++;
        }
      }
      return {
        'overdue': overdue,
        'ready': ready,
        'upcoming': upcoming,
        'totalToday': totalToday,
      };
    } catch (e) {
      print('Error computing summary client-side: $e');
      return _summaryData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVV Visit Schedules'),
 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
            tooltip: 'Refresh', 
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(context),
                const SizedBox(
                  height: 12,
                ), // add this to avoid touching the border
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSummaryCards(context),
                        const SizedBox(height: 24),
                        _buildTodaysVisitsSection(),
                        const SizedBox(height: 32),
                        _buildUpcomingVisitsSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Manage your visit schedule',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _scheduleNewVisit,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Schedule New Visit'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildSummaryCards(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        // Give tiles more vertical room on narrow screens
        final crossAxisCount = isNarrow ? 2 : 4;
        final aspect = isNarrow ? 2.0 : 2.6;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspect,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildSummaryCard(
              context: context,
              title: 'Overdue',
              count: _summaryData['overdue'].toString(),
              icon: Icons.error_outline,
              iconColor: cs.error,
              iconBackgroundColor: cs.errorContainer.withOpacity(0.6),
            ),
            _buildSummaryCard(
              context: context,
              title: 'Ready',
              count: _summaryData['ready'].toString(),
              icon: Icons.play_arrow,
              iconColor: cs.tertiary,
              iconBackgroundColor: cs.tertiaryContainer.withOpacity(0.6),
            ),
            _buildSummaryCard(
              context: context,
              title: 'Upcoming',
              count: _summaryData['upcoming'].toString(),
              icon: Icons.access_time,
              iconColor: cs.primary,
              iconBackgroundColor: cs.primaryContainer.withOpacity(0.6),
            ),
            _buildSummaryCard(
              context: context,
              title: 'Total Today',
              count: _summaryData['totalToday'].toString(),
              icon: Icons.calendar_today,
              iconColor: cs.secondary,
              iconBackgroundColor: cs.secondaryContainer.withOpacity(0.6),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildSummaryCard({
  required BuildContext context,
  required String title,
  required String count,
  required IconData icon,
  required Color iconColor,
  required Color iconBackgroundColor,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  // Cap text scale so accessibility settings do not overflow these compact tiles
  final cappedScale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.2);

  return MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaleFactor: cappedScale),
    child: Container(
      // Allow it to grow if needed, but ensure a comfortable minimum
      constraints: const BoxConstraints(minHeight: 98),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Slightly smaller than headlineSmall to avoid overflow on dense UIs
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTodaysVisitsSection() {
    final theme = Theme.of(context);

    // Filter out completed visits - only show scheduled visits
    final activeVisits = _scheduledVisits
        .where((visit) => visit.status == 'Scheduled')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Scheduled Visits",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          activeVisits.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: activeVisits.map((visit) {
                    return _buildTodayVisitCard(visit);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: cs.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No visits scheduled for today',
              style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to schedule a new visit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVisitStatus(ScheduledVisit visit) {
    if (visit.status != 'Scheduled') {
      return 'completed';
    }

    final now = DateTime.now();
    final visitDateTime = visit.scheduledTime;
    final currentTime = TimeOfDay.fromDateTime(now);
    final visitTime = TimeOfDay.fromDateTime(visitDateTime);

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final visitMinutes = visitTime.hour * 60 + visitTime.minute;

    if (visitMinutes < currentMinutes) {
      return 'overdue';
    } else if (visitMinutes - currentMinutes <= 30) {
      return 'ready';
    } else {
      return 'upcoming';
    }
  }

  Widget _buildTodayVisitCard(ScheduledVisit visit) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = _getVisitStatus(visit);

    Color backgroundColor;
    Color borderColor;
    Color statusBadgeColor;
    String statusText;
    String buttonText;
    IconData buttonIcon;

    if (status == 'overdue') {
      backgroundColor = cs.errorContainer.withOpacity(0.35);
      borderColor = cs.error;
      statusBadgeColor = cs.error;
      statusText = 'Overdue';
      buttonText = 'Start Overdue Visit';
      buttonIcon = Icons.play_arrow;
    } else if (status == 'ready') {
      backgroundColor = cs.primaryContainer.withOpacity(0.35);
      borderColor = cs.primary;
      statusBadgeColor = cs.primary;
      statusText = 'Ready';
      buttonText = 'Start Visit';
      buttonIcon = Icons.play_arrow;
    } else {
      backgroundColor = cs.surface;
      borderColor = theme.dividerColor;
      statusBadgeColor = cs.outline;
      statusText = 'Upcoming';
      buttonText = 'View Details';
      buttonIcon = Icons.info_outline;
    }

    final timeStr =
        '${visit.scheduledTime.hour.toString().padLeft(2, '0')}:${visit.scheduledTime.minute.toString().padLeft(2, '0')}';
    final durationHours = visit.duration.inHours;
    final durationMinutes = visit.duration.inMinutes.remainder(60);
    final durationStr = durationHours > 0
        ? '${durationHours}h ${durationMinutes}m'
        : '${durationMinutes}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visit.patientName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (status == 'overdue')
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBadgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              visit.serviceType,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Scheduled Time: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Estimated Duration: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  durationStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (status == 'overdue' || status == 'ready') {
                    final encodedServiceType = Uri.encodeComponent(
                      visit.serviceType,
                    );
                    context.push(
                      '/evv/checkin-location?patientId=${visit.patientId}&serviceType=$encodedServiceType&scheduledVisitId=${visit.id}',
                    );
                  } else {
                    _viewVisitDetails(visit);
                  }
                },
                icon: Icon(buttonIcon, size: 18),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'overdue' ? cs.error : cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUpcomingVisitsSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_upcomingVisits.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group visits by date
    final Map<String, List<ScheduledVisit>> groupedVisits = {};
    for (var visit in _upcomingVisits) {
      final dateKey = DateFormat('yyyy-MM-dd').format(visit.scheduledTime);
      groupedVisits.putIfAbsent(dateKey, () => []).add(visit);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Visits',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...groupedVisits.entries.map((entry) {
              final dateStr = entry.key;
              final visits = entry.value;
              final date = DateTime.parse(dateStr);
              final formattedDate = DateFormat('EEEE, MMMM d').format(date);

              return _buildDateGroup(formattedDate, visits);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(String dateLabel, List<ScheduledVisit> visits) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(
            dateLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ),
        ...visits.asMap().entries.map((entry) {
          final index = entry.key;
          final visit = entry.value;
          final isLast = index == visits.length - 1;

          return _buildUpcomingVisitEntry(visit, isLast);
        }).toList(),
      ],
    );
  }

  Widget _buildUpcomingVisitEntry(ScheduledVisit visit, bool isLast) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final timeStr =
        '${visit.scheduledTime.hour.toString().padLeft(2, '0')}:${visit.scheduledTime.minute.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 4,
          child: Column(
            children: [
              Container(
                width: 4,
                height: isLast ? 60 : 80,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: isLast
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primaryContainer, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              visit.patientName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          '${visit.serviceType} at $timeStr',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'upcoming',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _scheduleNewVisit() {
    showDialog(
      context: context,
      builder: (context) => _ScheduleVisitDialog(
        onScheduled: () {
          _loadScheduledVisits();
          _loadUpcomingVisits();
          _loadAndSetSummaryData();
        },
      ),
    );
  }

  void _viewVisitDetails(ScheduledVisit visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Visit Details - ${visit.patientName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Service Type', visit.serviceType),
            _buildDetailRow(
              'Time',
              '${visit.scheduledTime.hour}:${visit.scheduledTime.minute.toString().padLeft(2, '0')}',
            ),
            _buildDetailRow(
              'Duration',
              '${visit.duration.inHours}h ${visit.duration.inMinutes.remainder(60)}m',
            ),
            _buildDetailRow('Status', visit.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/evv/select-patient');
            },
            child: const Text('Start Visit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Schedule Visit Dialog
class _ScheduleVisitDialog extends StatefulWidget {
  final VoidCallback onScheduled;

  const _ScheduleVisitDialog({required this.onScheduled});

  @override
  State<_ScheduleVisitDialog> createState() => _ScheduleVisitDialogState();
}

class _ScheduleVisitDialogState extends State<_ScheduleVisitDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  Patient? _selectedPatient;
  String? _selectedServiceType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  int _duration = 60;
  String _priority = 'Normal';
  final TextEditingController _notesController = TextEditingController();

  // Data
  List<Patient> _patients = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  final List<String> _serviceTypes = [
    'Personal Care',
    'Medication Management',
    'Meal Preparation',
    'Light Housekeeping',
    'Companionship',
    'Transportation',
    'Respite Care',
    'Physical Therapy',
    'Occupational Therapy',
    'Skilled Nursing',
  ];

  final List<String> _priorities = ['Normal', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final caregiverId = userProvider.user?.caregiverId ?? 1;

      final headers = await AuthTokenManager.getAuthHeaders();
      final baseUrl = ApiConstants.baseUrl;
      final url = Uri.parse('${baseUrl}caregivers/$caregiverId/patients');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _patients = data.map((json) => Patient.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scheduleVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final caregiverId = userProvider.user?.caregiverId ?? 1;

      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final baseUrl = ApiConstants.baseUrl;
      final url = Uri.parse(
        '${baseUrl}scheduled-visits/caregiver/$caregiverId',
      );

      // Build request body
      final requestBody = {
        'patientId': _selectedPatient!.id,
        'serviceType': _selectedServiceType,
        'scheduledDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'scheduledTime':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
        'durationMinutes': _duration,
        'priority': _priority,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      print('📤 Scheduling visit: $requestBody');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onScheduled();
        }
      } else {
        throw Exception(
          'Failed to schedule visit: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error scheduling visit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling visit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedule New Visit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient dropdown
                      _buildLabel('Patient *'),
                      const SizedBox(height: 8),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<Patient>(
                              value: _selectedPatient,
                              decoration: InputDecoration(
                                hintText: 'Select a patient',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: _patients.map((patient) {
                                return DropdownMenuItem<Patient>(
                                  value: patient,
                                  child: Text(
                                    '${patient.firstName} ${patient.lastName}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPatient = value;
                                });
                              },
                            ),
                      const SizedBox(height: 16),

                      // Service Type dropdown
                      _buildLabel('Service Type *'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedServiceType,
                        decoration: InputDecoration(
                          hintText: 'Select service type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _serviceTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date and Time row
                      Row(
                        children: [
                          // Date picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Date *'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'MM/dd/yyyy',
                                      ).format(_selectedDate),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Time picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Time *'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectTime(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    child: Text(
                                      _selectedTime != null
                                          ? _selectedTime!.format(context)
                                          : '--:-- --',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duration and Priority row
                      Row(
                        children: [
                          // Duration
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Duration (minutes)'),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: _duration > 15
                                            ? () {
                                                setState(() {
                                                  _duration = (_duration - 15)
                                                      .clamp(15, 480);
                                                });
                                              }
                                            : null,
                                        padding: const EdgeInsets.all(8),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            _duration.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: theme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: _duration < 480
                                            ? () {
                                                setState(() {
                                                  _duration = (_duration + 15)
                                                      .clamp(15, 480);
                                                });
                                              }
                                            : null,
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Priority
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Priority'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _priority,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: _priorities.map((priority) {
                                    return DropdownMenuItem<String>(
                                      value: priority,
                                      child: Text(priority),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _priority = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      _buildLabel('Notes'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Add any special instructions or notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _scheduleVisit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Schedule Visit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
}

// Model class for scheduled visits
class ScheduledVisit {
  final int id;
  final int patientId;
  final String patientName;
  final String serviceType;
  final DateTime scheduledTime;
  final Duration duration;
  final String status;
  final String priority;

  ScheduledVisit({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.serviceType,
    required this.scheduledTime,
    required this.duration,
    required this.status,
    required this.priority,
  });

  factory ScheduledVisit.fromJson(Map<String, dynamic> json) {
    // Parse date and time from the response
    final dateStr = json['scheduledDate'] as String;
    final timeStr = json['scheduledTime'] as String;

    // Parse date (format: yyyy-MM-dd)
    final dateParts = dateStr.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    // Parse time (format: HH:mm:ss or HH:mm)
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final scheduledDateTime = DateTime(year, month, day, hour, minute);
    final durationMinutes = json['durationMinutes'] as int;

    return ScheduledVisit(
      id: json['id'] as int,
      patientId: json['patientId'] as int,
      patientName: json['patientName'] as String,
      serviceType: json['serviceType'] as String,
      scheduledTime: scheduledDateTime,
      duration: Duration(minutes: durationMinutes),
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'Normal',
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Primary Backend address 
const String kApiBase = 'http://127.0.0.1:8080';
const String kAuthToken = ''; // optional
Map<String, String> get _authHeaders => {
  if (kAuthToken.isNotEmpty) 'Authorization': 'Bearer $kAuthToken',
  'Content-Type': 'application/json',
};


// 🟢 Reusable function to show a "Calling..." SnackBar
void showCallingSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        '📞 Calling...',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      duration: Duration(seconds: 2),
    ),
  );
}

void main() => runApp(const CareConnectApp());

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2563EB);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareConnect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            letterSpacing: .1,
          ),
          titleMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          bodyMedium: TextStyle(fontSize: 15, height: 1.35),
          bodySmall: TextStyle(fontSize: 13.5, height: 1.35),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      ),
      home: const CaregiverHome(),
    );
  }
}

/* --------------------------- Shell + Bottom Nav --------------------------- */

class CaregiverHome extends StatefulWidget {
  const CaregiverHome({super.key});
  @override
  State<CaregiverHome> createState() => _CaregiverHomeState();
}

class _CaregiverHomeState extends State<CaregiverHome> {
  int _index = 0;

  @override
  @override
  Widget build(BuildContext context) {
    // Order mirrors the bottom nav: Home, Calendar, Patients, Mail, Messages, Features
    final pages = <Widget>[
      const CaregiverDashboardScreen(),
      const ScheduleScreen(), // Calendar
      const PatientDashboardScreen(), // << CHANGED: Patients tab goes to PatientDashboardScreen
      const MailScreen(),
      const MessagesScreen(),
      const FeaturesScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        // Badges per screenshot: Home(0), Calendar(12), Patients(4), Mail(0), Messages(8), Features(0)
        badges: const [0, 12, 4, 0, 8, 0],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onTap,
    required this.badges,
  });

  final int index;
  final void Function(int) onTap;
  final List<int> badges;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    BottomNavigationBarItem item(String label, IconData icon, int i) {
      final active = index == i;
      final iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? cs.primaryContainer.withOpacity(.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    active ? cs.primary.withOpacity(.25) : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: active ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          if (badges[i] > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD94B45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '${badges[i]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
      return BottomNavigationBarItem(icon: iconWidget, label: label);
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x22000000),
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: cs.surface,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurfaceVariant,
          showUnselectedLabels: true,
          items: [
            item('Home', Icons.home_outlined, 0),
            item('Calendar', Icons.event_note_outlined, 1),
            item('Patients', Icons.groups_2_outlined, 2),
            item('Mail', Icons.mail_outline, 3),
            item('Messages', Icons.forum_outlined, 4),
            item('Features', Icons.grid_view_rounded, 5),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- Dashboard ------------------------------- */

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ScrollConfiguration(
      behavior: const _NoGlow(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const SizedBox(height: 10),
          const _HeaderCard(),
          const _OfflineCard(
            title: 'Offline Mode',
            subtitle:
                'Last synced 2 hours ago. Your data will sync when reconnected.',
          ),
          _AlertCard(
            tone: _AlertTone.urgent,
            titleRich: const [
              TextSpan(
                text: 'URGENT: ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: 'Fall detected - John Smith may need help.'),
            ],
            subtitle: 'No response from patient • 3 minutes ago',
            actionLabel: 'Respond',
            onAction: () => showFallAlert(context),
          ),
          const _AlertCard(
            tone: _AlertTone.important,
            titleRich: [
              TextSpan(
                text: 'Important: ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: '3 _visiblePatients have missed their scheduled check-ins today.',
              ),
            ],
          ),
          const _AlertCard(
            tone: _AlertTone.reminder,
            titleRich: [
              TextSpan(
                text: 'Reminder: ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text:
                    'Sarah Johnson reported severe symptoms. Follow up required.',
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.groups_outlined,
                    iconBg: Color(0xFFE9EDFF),
                    labelLines: ['# of', 'Missed', 'Check-Ins'],
                    value: '24',
                    valueColor: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.monitor_heart_rounded,
                    iconBg: Color(0xFFE9F7EF),
                    labelLines: ['Active', 'Patients'],
                    value: '32',
                    valueColor: Color(0xFF0A7D3E),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Color(0x11000000),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upcoming Check-Ins',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _UpcomingVisitsCard(),
          const SizedBox(height: 8),
          const _RecentActivitySection(),
          const SizedBox(height: 12),
          const _CareTeamPerformanceCard(),
        ],
      ),
    );
  }
}

/* --------------------------------- Header -------------------------------- */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/careconnect_logo.png',
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.health_and_safety_rounded,
                        color: cs.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CARECONNECT',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withOpacity(.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/doctor_avatar.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: (Theme.of(context).textTheme.headlineSmall ??
                                const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ))
                            .copyWith(color: const Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Timezone: EDT',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            'Your _visiblePatients\' health summary',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- Offline Card ------------------------------ */

class _OfflineCard extends StatelessWidget {
  const _OfflineCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x22000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white70),
            SizedBox(width: 12),
            Expanded(child: _OfflineText()),
          ],
        ),
      ),
    );
  }
}

class _OfflineText extends StatelessWidget {
  const _OfflineText();
  @override
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline Mode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          'Last synced 2 hours ago. Your data will sync when reconnected.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

/* --------------------------------- Alerts --------------------------------- */

enum _AlertTone { urgent, important, reminder }

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.tone,
    required this.titleRich,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final _AlertTone tone;
  final List<InlineSpan> titleRich;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _AlertTone.urgent => (
          bg: const Color(0xFFFFECE9),
          border: const Color(0xFFE24B42),
          text: const Color(0xFFB91C1C),
        ),
      _AlertTone.important => (
          bg: const Color(0xFFFDECEC),
          border: const Color(0xFFE11D48),
          text: const Color(0xFF9F1239),
        ),
      _AlertTone.reminder => (
          bg: const Color(0xFFFFF4E6),
          border: const Color(0xFFF59E0B),
          text: const Color(0xFF92400E),
        ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.text),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: colors.text, fontSize: 15),
                      children: titleRich,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      subtitle!,
                      style: TextStyle(color: colors.text.withOpacity(.95)),
                    ),
                  ],
                ],
              ),
            ),
            if (actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD94B45),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------- Metric tiles ------------------------------ */

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.labelLines,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconBg;
  final List<String> labelLines;
  final String value;
  final Color valueColor;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x14000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: iconBg,
            child: Icon(icon, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              labelLines.join('\n'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Placeholder screens -------------------------- */

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});
  @override
  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'Patient List',
      child: Column(
        children: List.generate(
          6,
          (i) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Patient ${i + 1}'),
              subtitle: const Text('Tap to view details'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override
  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'Calendar',
      child: Column(
        children: List.generate(
          6,
          (i) => Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text('Appointment ${(i + 1)}'),
              subtitle: const Text('Tomorrow at 10:00 AM'),
            ),
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'Messages',
      child: Column(
        children: List.generate(
          6,
          (i) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Conversation ${i + 1}'),
              subtitle: const Text('Last message preview…'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    );
  }
}

// NEW placeholders so teammates can connect their UIs later:

class MailScreen extends StatelessWidget {
  const MailScreen({super.key});
  @override
  @override
  Widget build(BuildContext context) {
    return const _SimpleScaffold(
      title: 'Mail',
      child: _EmptyHint(text: 'Connect your Mail UI here.'),
    );
  }
}

// ===================== FEATURES TAB (opens feature sheet) =====================
class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  bool _shown = false;

    @override
  void initState() {
    super.initState();
    // Open the sheet once when this tab is shown
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    if (_shown) return;
    _shown = true;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeatureListSheet(),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Fallback content if the user dismisses the sheet (they can re-open it)
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: SafeArea(
        child: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.apps),
            label: const Text('Open Additional Features'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: _openSheet,
          ),
        ),
      ),
    );
  }
}

// ----------------------- Bottom sheet: Feature list -----------------------
class _FeatureListSheet extends StatelessWidget {
  const _FeatureListSheet();

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <_FeatureItem>[
      _FeatureItem(
        icon: Icons.sports_esports_outlined,
        title: 'Gamification',
        subtitle: 'Track progress and earn rewards',
        onTap: () {
          // TODO: hook up teammate's UI
          Navigator.pop(context);
        },
      ),
      _FeatureItem(
        icon: Icons.mail_outline,
        title: 'Mail Assistant',
        subtitle: 'AI-powered email management',
        onTap: () {
          // TODO
          Navigator.pop(context);
        },
      ),
      _FeatureItem(
        icon: Icons.credit_card,
        title: 'Billing & Subscription',
        subtitle: 'Manage payments and plans',
        onTap: () {
          // TODO
          Navigator.pop(context);
        },
      ),
      _FeatureItem(
        icon: Icons.access_time,
        title: 'Electronic Visit Verification',
        subtitle: 'Clock in/out and track visits',
        onTap: () {
          // TODO
          Navigator.pop(context);
        },
      ),
      _FeatureItem(
        icon: Icons.note_alt_outlined,
        title: 'Visit Notetaker',
        subtitle: 'AI-powered visit documentation',
        onTap: () {
          // TODO
          Navigator.pop(context);
        },
      ),
      _FeatureItem(
        icon: Icons.chat_bubble_outline,
        title: 'ASL Converter',
        subtitle: 'Sign language translation',
        onTap: () {
          // TODO
          Navigator.pop(context);
        },
      ),
      _FeatureItem(
        icon: Icons.medical_services_outlined,
        title: 'ASL Telemedicine',
        subtitle: 'Video calls with ASL support',
        onTap: () {
          // TODO
          Navigator.pop(context);
        },
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
                blurRadius: 24,
                color: Color(0x33000000),
                offset: Offset(0, -6)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Additional Features',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Access advanced tools and features',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Feature list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemBuilder: (_, i) => _FeatureTile(item: items[i]),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: items.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});
  final _FeatureItem item;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 10, color: Color(0x0F000000))
          ],
          border: Border.all(color: cs.outlineVariant.withOpacity(.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _SimpleScaffold extends StatelessWidget {
  const _SimpleScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- Utilities -------------------------------- */

class _NoGlow extends ScrollBehavior {
  const _NoGlow();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

/* ============================ FALL ALERT SHEET ============================ */

Future<void> showFallAlert(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          // Sheet-scoped messenger so SnackBars appear at the bottom of this sheet.
          return ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Builder(
                builder: (scopedCtx) => FallAlertSheet(
                  scrollController: controller,
                  cs: cs,
                  snackbarContext: scopedCtx,
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class FallAlertSheet extends StatelessWidget {
  const FallAlertSheet({
    super.key,
    required this.scrollController,
    required this.cs,
    required this.snackbarContext,
  });

  final ScrollController scrollController;
  final ColorScheme cs;
  final BuildContext snackbarContext;

  @override
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 20,
              color: Color(0x33000000),
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE24B42),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fall Alert',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Patient may need help.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Color(0x0F000000)),
                ],
                border: Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFF2F4F8),
                    child: Text(
                      'JS',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Smith',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Last detected in Living Room',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Fall detected 3 minutes ago',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE2DF),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Text(
                  'No response from patient',
                  style: TextStyle(
                    color: Color(0xFFCC4B44),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _OutlinedActionButton(
              label: 'View Fall Detection Video',
              leading: Icons.videocam_outlined,
              trailing: Icons.open_in_new,
              onPressed: () => _showFallVideoToast(snackbarContext),
              cs: cs,
            ),
            const SizedBox(height: 12),
            _SolidActionButton(
              label: 'Call Patient',
              icon: Icons.phone_in_talk,
              color: const Color(0xFF2242C6),
              onPressed: () => _showCallPatientToast(snackbarContext),
            ),
            const SizedBox(height: 12),
            _SolidActionButton(
              label: 'Send Message',
              icon: Icons.chat_bubble_outline,
              color: cs.surface,
              fg: cs.onSurface,
              border: cs.outlineVariant,
              onPressed: () => _showSendMessageToast(snackbarContext),
            ),
            const SizedBox(height: 12),
            _SolidActionButton(
              label: 'Contact Emergency Services',
              icon: Icons.emergency_outlined,
              color: const Color(0xFFD94B45),
              onPressed: () => _showEmergencyToast(snackbarContext),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: () => _showPatientDetailsToast(snackbarContext),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'View Patient Medical Records',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.open_in_new, size: 18, color: cs.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_pin_circle_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Emergency Contact: Sarah Smith (Daughter)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Patient ID: MID-12345',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- Snack-style bottom notifications -------------------- */

void _showFallVideoToast(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.surface,
      elevation: 10,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fall Detection Video',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opening fall detection footage…',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showCallPatientToast(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.surface,
      elevation: 10,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: cs.onSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Calling patient',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connecting call to John Smith…',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showSendMessageToast(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.surface,
      elevation: 10,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Messaging patient',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opening conversation with John Smith…',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showEmergencyToast(BuildContext context) {
  const bg = Color(0xFFD94B45);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      elevation: 10,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.white,
            child: Icon(Icons.check, size: 14, color: bg),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Emergency services contacted',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Emergency responders have been dispatched.',
                  style: TextStyle(color: Color(0xFFFFF3F2)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Patient Medical Records toast
void _showPatientDetailsToast(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.surface,
      elevation: 10,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Patient Medical Records',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opening detailed patient records…',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/* -------------------- Buttons used in the alert sheet -------------------- */

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.leading,
    required this.trailing,
    required this.onPressed,
    required this.cs,
  });

  final String label;
  final IconData leading;
  final IconData trailing;
  final VoidCallback onPressed;
  final ColorScheme cs;

  @override
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.primary),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(leading, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Icon(trailing, color: cs.primary),
        ],
      ),
    );
  }
}

class _SolidActionButton extends StatelessWidget {
  const _SolidActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.fg,
    this.border,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color? fg;
  final Color? border;
  final VoidCallback onPressed;

  @override
  @override
  Widget build(BuildContext context) {
    final textColor = fg ?? Colors.white;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border ?? Colors.transparent),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------- NEW: Upcoming Visits & Activity --------------------- */

class _UpcomingVisitsCard extends StatelessWidget {
  const _UpcomingVisitsCard();

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final appts = <Map<String, String>>[
      {'name': 'Sarah Johnson', 'time': '12/28/2024 at 10:00 AM'},
      {'name': 'Robert Chen', 'time': '12/28/2024 at 2:30 PM'},
      {'name': 'Maria Rodriguez', 'time': '12/29/2024 at 9:15 AM'},
      {'name': 'David Thompson', 'time': '12/29/2024 at 11:45 AM'},
    ];

    void openPatient(BuildContext context, String? name) {
      if (name == 'Sarah Johnson') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PatientDetailScreenSarah()),
        );
      } else if (name == 'Robert Chen') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PatientDetailScreenRobert()),
        );
      } else if (name == 'Maria Rodriguez') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PatientDetailScreenMaria()),
        );
      } else if (name == 'David Thompson') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PatientDetailScreenDavid()),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...appts.map(
            (a) => InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openPatient(context, a['name']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(.6),
                  ),
                ),
                child: Row(
                  children: [
                    // Left side: name + time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['name']!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a['time']!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    // Right side: View button (also navigates)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => openPatient(context, a['name']),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PatientDashboardScreen(),
                      ),
                    );
                  },
                  child: const Text('View All Patients'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2847D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EVVSessionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.av_timer_outlined),
                  label: const Text('Start EVV Session'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <Map<String, String>>[
      {
        'title': 'Sarah Johnson completed check-in',
        'subtitle': '2 hours ago • Mood: Good (8/10)',
        'emoji': '😊',
      },
      {
        'title': 'Robert Chen reported symptoms',
        'subtitle': '4 hours ago • Mild headache',
        'emoji': '😐',
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF0EA5A4)),
              const SizedBox(width: 8),
              Text(
                'Recent Patient Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0EA5A4),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (it) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it['title']!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          it['subtitle']!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(it['emoji']!, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------- Care Team Performance card ------------------- */

class _CareTeamPerformanceCard extends StatelessWidget {
  const _CareTeamPerformanceCard();

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const green = Color(0xFF1F9D55);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: green),
              const SizedBox(width: 8),
              Text(
                'Care Team Performance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: green,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Overall Patient Satisfaction',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '4.8/5',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Excellent',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on last 30 days',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in Completion Rate',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              ),
              const Text(
                '89%',
                style: TextStyle(color: green, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.89,
              minHeight: 10,
              backgroundColor: cs.outlineVariant.withOpacity(.3),
              valueColor: const AlwaysStoppedAnimation<Color>(green),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== Patient Dashboard (View All Patients) ===================== */

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});
  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final TextEditingController _patientSearchCtrl = TextEditingController();
  List<_PatientCardData> _allPatients = [];
  List<_PatientCardData> _visiblePatients = [];

    @override
  void initState() {
    super.initState();
    _allPatients = <_PatientCardData>[
      _PatientCardData(
        name: 'Sarah Johnson',
        urgent: true,
        lastUpdated: '12/25/2024',
        statusTitle: 'Severe symptoms reported',
        statusIsAlert: true,
        nextCheckIn: '12/28/2024',
        moodEmoji: '😟',
        moodLabel: 'Poor',
      ),
      _PatientCardData(
        name: 'Robert Chen',
        urgent: true,
        lastUpdated: '12/24/2024',
        statusTitle: 'Missed medication dose',
        statusIsAlert: true,
        nextCheckIn: '12/28/2024',
        moodEmoji: '😕',
        moodLabel: 'Concerned',
      ),
      _PatientCardData(
        name: 'James Miller',
        urgent: true,
        lastUpdated: '12/26/2024',
        statusTitle: 'Emergency contact needed',
        statusIsAlert: true,
        nextCheckIn: '12/28/2024',
        moodEmoji: '😰',
        moodLabel: 'Distressed',
      ),
      _PatientCardData(
        name: 'Maria Rodriguez',
        urgent: false,
        lastUpdated: '12/26/2024',
        statusTitle: 'Feeling good',
        statusIsAlert: false,
        nextCheckIn: '12/29/2024',
        moodEmoji: '😊',
        moodLabel: 'Good',
      ),
      _PatientCardData(
        name: 'David Thompson',
        urgent: false,
        lastUpdated: '12/23/2024',
        statusTitle: 'Some fatigue',
        statusIsAlert: false,
        nextCheckIn: '12/29/2024',
        moodEmoji: '😟',
        moodLabel: 'Fair',
      ),
    ];
    _visiblePatients = List<_PatientCardData>.from(_allPatients);
    _patientSearchCtrl.addListener(_applyPatientFilterLive);
  }

  @override
  void dispose() {
    _patientSearchCtrl.dispose();
    super.dispose();
  }

  void _applyPatientFilterLive() {
    final q = _patientSearchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _visiblePatients = List<_PatientCardData>.from(_allPatients);
      } else {
        _visiblePatients = _allPatients.where((p) {
          final name = (p.name ?? '').toLowerCase();
          return name.contains(q);
        }).toList();
      }
    });
  }

  void _applyPatientFilterOnSubmit() {
    _applyPatientFilterLive();
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // moved to initState -> _allPatients assignment

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Color(0x14000000),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: const Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      count: '3',
                      label: 'Urgent Cases',
                      color: Color(0xFFD94B45),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      count: '3',
                      label: 'Normal Status',
                      color: Color(0xFF1F9D55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patientSearchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyPatientFilterOnSubmit(),
              decoration: InputDecoration(
                hintText: 'Enter patient name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _applyPatientFilterOnSubmit,
                  tooltip: 'Search',
                ),
                  
                filled: true,
                fillColor: cs.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._visiblePatients.map((p) => _PatientCard(data: p)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
  });
  final String count;
  final String label;
  final Color color;

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _PatientCardData {
  _PatientCardData({
    required this.name,
    required this.urgent,
    required this.lastUpdated,
    required this.statusTitle,
    required this.statusIsAlert,
    required this.nextCheckIn,
    required this.moodEmoji,
    required this.moodLabel,
  });

  final String name;
  final bool urgent;
  final String lastUpdated;
  final String statusTitle;
  final bool statusIsAlert;
  final String nextCheckIn;
  final String moodEmoji;
  final String moodLabel;
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.data});
  final _PatientCardData data;

  void _openDetail(BuildContext context) {
    if (data.name == 'Sarah Johnson') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PatientDetailScreenSarah()),
      );
    } else if (data.name == 'Robert Chen') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PatientDetailScreenRobert()),
      );
    } else if (data.name == 'James Miller') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PatientDetailScreenJames()),
      );
    } else if (data.name == 'Maria Rodriguez') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PatientDetailScreenMaria()),
      );
    } else if (data.name == 'David Thompson') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PatientDetailScreenDavid()),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const red = Color(0xFFD94B45);
    const green = Color(0xFF1F9D55);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                blurRadius: 12, color: Color(0x14000000), offset: Offset(0, 2)),
          ],
          border: data.urgent
              ? Border.all(color: red.withOpacity(.25), width: 1)
              : Border.all(color: cs.outlineVariant.withOpacity(.35), width: 1),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              left: 0,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 4,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: data.urgent ? red : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              data.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (data.urgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: red,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  'URGENT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.notifications_none, color: Colors.black54),
                          const SizedBox(width: 12),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: data.urgent ? red : green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            color: cs.primary,
                            onPressed: () => _openDetail(context),
                            tooltip: 'Open details',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _kv('Last Updated:', data.lastUpdated, context),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: data.statusTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: data.statusIsAlert ? red : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _kv('Next Check-In:', data.nextCheckIn, context),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Mood:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black54)),
                      const SizedBox(width: 8),
                      Text(data.moodEmoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        data.moodLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54)),
          const SizedBox(height: 2),
          Text(v, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

/* ========================== EVV Placeholder Screen ========================== */

class EVVSessionScreen extends StatefulWidget {
  const EVVSessionScreen({super.key});

  @override
  State<EVVSessionScreen> createState() => _EVVSessionScreenState();
}

class _EVVSessionScreenState extends State<EVVSessionScreen> {
  bool _busy = false;
  String? _evvError;
  String? _sessionId;
  DateTime? _startedAt;

  Future<void> _clockIn({required String caregiverId, required String patientId}) async {
    setState(() { _busy = true; _evvError = null; });
    final uri = Uri.parse('$kApiBase/evv/checkin');
    try {
      final res = await http.post(
        uri,
        headers: _authHeaders,
        body: json.encode({
          'caregiverId': caregiverId,
          'patientId': patientId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(res.body);
        _sessionId = (data['sessionId'] ?? '').toString();
        _startedAt = DateTime.now();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in')));
        }
      } else {
        _evvError = 'Clock-in failed (${res.statusCode})';
      }
    } catch (_) {
      _evvError = 'Network error';
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _clockOut() async {
    if (_sessionId == null) {
      setState(() { _evvError = 'No active session'; });
      return;
    }
    setState(() { _busy = true; _evvError = null; });
    final uri = Uri.parse('$kApiBase/evv/checkout');
    try {
      final res = await http.post(
        uri,
        headers: _authHeaders,
        body: json.encode({
          'sessionId': _sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked out')));
        }
        _sessionId = null;
        _startedAt = null;
      } else {
        _evvError = 'Clock-out failed (${res.statusCode})';
      }
    } catch (_) {
      _evvError = 'Network error';
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'EVV Session',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_evvError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_evvError!, style: const TextStyle(color: Colors.red)),
              ),
            if (_startedAt != null)
              Text(
                'In session • started at ${_startedAt!.toLocal().toString().substring(11,16)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : () => _clockIn(caregiverId: 'demo-caregiver', patientId: 'demo-patient'),
              child: const Text('Clock In'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _clockOut,
              child: const Text('Clock Out'),
            ),
          ],
        ),
      ),
    );
  }
}
/* ==================== SARAH JOHNSON • PATIENT DETAILS (TABBED) ==================== */

class PatientDetailScreenSarah extends StatefulWidget {
  const PatientDetailScreenSarah({super.key});

  @override
  State<PatientDetailScreenSarah> createState() =>
      _PatientDetailScreenSarahState();
}

class _PatientDetailScreenSarahState extends State<PatientDetailScreenSarah>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

    @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Details'),
            SizedBox(height: 2),
            Text('Medical Record', style: TextStyle(fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          // 1️⃣ Video call button (filled camera icon)
          _chipButton(
            context,
            icon: Icons.videocam, // changed to filled variant
            label: 'Call',
            onTap: () {
              // TODO: integrate video call feature
            },
          ),
          const SizedBox(width: 8),

          // 2️⃣ Emergency contact button (phone handset icon)
          _chipButton(
            context,
            icon: Icons.phone, // changed from call_outlined to phone
            label: 'Emergency Contact',
            filled: true,
            onTap: () {
              // TODO: integrate emergency contact call
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _PatientHeaderCard(
              initials: 'SJ',
              name: 'Sarah Johnson',
              riskLabel: 'MEDIUM RISK',
              age: '72 years',
              id: 'MID-12345',
              location: 'Living Room',
              lastSeen: '5 minutes ago',
              emergencyContact: 'Sarah Smith (Daughter)',
              healthConditions: ['Diabetes Type 2', 'Hypertension'],
            ),
            const SizedBox(height: 8),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SegmentedTabBar(controller: _tab),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _OverviewTab(),
                  _MedsTab(),
                  _MoodTab(),
                  _AlertsTab(),
                  _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== ROBERT CHEN • PATIENT DETAILS (TABBED) ==================== */

class PatientDetailScreenRobert extends StatefulWidget {
  const PatientDetailScreenRobert({super.key});

  @override
  State<PatientDetailScreenRobert> createState() =>
      _PatientDetailScreenRobertState();
}

class _PatientDetailScreenRobertState extends State<PatientDetailScreenRobert>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

    @override
  void initState() {
    super.initState();
    _tab = TabController(
        length: 5, vsync: this); // Overview, Meds, Mood, Alerts, Activity
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Details'),
            SizedBox(height: 2),
            Text('Medical Record', style: TextStyle(fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          _chipButton(
            context,
            icon: Icons.videocam,
            label: 'Call',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _chipButton(
            context,
            icon: Icons.phone,
            label: 'Emergency Contact',
            filled: true,
            onTap: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _PatientHeaderCard(
              initials: 'RC',
              name: 'Robert Chen',
              riskLabel: 'MEDIUM RISK',
              age: '68 years',
              id: 'MID-22341',
              location: 'Bedroom',
              lastSeen: '8 minutes ago',
              emergencyContact: 'Lina Chen (Wife)',
              healthConditions: ['Hypertension', 'Type 2 Diabetes'],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SegmentedTabBar(controller: _tab),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _OverviewTab(),
                  _MedsTab(),
                  _MoodTab(),
                  _AlertsTab(),
                  _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== JAMES MILLER • PATIENT DETAILS (TABBED) ==================== */

class PatientDetailScreenJames extends StatefulWidget {
  const PatientDetailScreenJames({super.key});

  @override
  State<PatientDetailScreenJames> createState() =>
      _PatientDetailScreenJamesState();
}

class _PatientDetailScreenJamesState extends State<PatientDetailScreenJames>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

    @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Details'),
            SizedBox(height: 2),
            Text('Medical Record', style: TextStyle(fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          _chipButton(context,
              icon: Icons.videocam, label: 'Call', onTap: () {}),
          const SizedBox(width: 8),
          _chipButton(
            context,
            icon: Icons.phone,
            label: 'Emergency Contact',
            filled: true,
            onTap: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _PatientHeaderCard(
              initials: 'JM',
              name: 'James Miller',
              riskLabel: 'HIGH RISK',
              age: '74 years',
              id: 'MID-33452',
              location: 'Kitchen',
              lastSeen: '2 minutes ago',
              emergencyContact: 'Anna Miller (Daughter)',
              healthConditions: ['COPD', 'Arrhythmia'],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SegmentedTabBar(controller: _tab),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _OverviewTab(),
                  _MedsTab(),
                  _MoodTab(),
                  _AlertsTab(),
                  _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== MARIA RODRIGUEZ • PATIENT DETAILS (TABBED) ==================== */

class PatientDetailScreenMaria extends StatefulWidget {
  const PatientDetailScreenMaria({super.key});

  @override
  State<PatientDetailScreenMaria> createState() =>
      _PatientDetailScreenMariaState();
}

class _PatientDetailScreenMariaState extends State<PatientDetailScreenMaria>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

    @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Details'),
            SizedBox(height: 2),
            Text('Medical Record', style: TextStyle(fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          _chipButton(context,
              icon: Icons.videocam, label: 'Call', onTap: () {}),
          const SizedBox(width: 8),
          _chipButton(
            context,
            icon: Icons.phone,
            label: 'Emergency Contact',
            filled: true,
            onTap: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _PatientHeaderCard(
              initials: 'MR',
              name: 'Maria Rodriguez',
              riskLabel: 'LOW RISK',
              age: '65 years',
              id: 'MID-44563',
              location: 'Living Room',
              lastSeen: '20 minutes ago',
              emergencyContact: 'Carlos Rodriguez (Son)',
              healthConditions: ['Osteoarthritis'],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SegmentedTabBar(controller: _tab),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _OverviewTab(),
                  _MedsTab(),
                  _MoodTab(),
                  _AlertsTab(),
                  _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== DAVID THOMPSON • PATIENT DETAILS (TABBED) ==================== */

class PatientDetailScreenDavid extends StatefulWidget {
  const PatientDetailScreenDavid({super.key});

  @override
  State<PatientDetailScreenDavid> createState() =>
      _PatientDetailScreenDavidState();
}

class _PatientDetailScreenDavidState extends State<PatientDetailScreenDavid>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

    @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Details'),
            SizedBox(height: 2),
            Text('Medical Record', style: TextStyle(fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          _chipButton(context,
              icon: Icons.videocam, label: 'Call', onTap: () {}),
          const SizedBox(width: 8),
          _chipButton(
            context,
            icon: Icons.phone,
            label: 'Emergency Contact',
            filled: true,
            onTap: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _PatientHeaderCard(
              initials: 'DT',
              name: 'David Thompson',
              riskLabel: 'LOW RISK',
              age: '70 years',
              id: 'MID-55674',
              location: 'Garden',
              lastSeen: '15 minutes ago',
              emergencyContact: 'Emily Thompson (Wife)',
              healthConditions: ['Heart Disease'],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SegmentedTabBar(controller: _tab),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _OverviewTab(),
                  _MedsTab(),
                  _MoodTab(),
                  _AlertsTab(),
                  _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------- Header --------------------------------- */

class _PatientHeaderCard extends StatelessWidget {
  const _PatientHeaderCard({
    required this.initials,
    required this.name,
    required this.riskLabel,
    required this.age,
    required this.id,
    required this.location,
    required this.lastSeen,
    required this.emergencyContact,
    this.healthConditions = const <String>[], // NEW (optional)
  });

  final String initials,
      name,
      riskLabel,
      age,
      id,
      location,
      lastSeen,
      emergencyContact;

  // NEW
  final List<String> healthConditions;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.surfaceContainerHighest.withOpacity(.5),
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    _pill(riskLabel),
                  ],
                ),
                const SizedBox(height: 8),
                _kv(context, 'Age', age),
                const SizedBox(height: 6),
                _kv(context, 'ID', id),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.schedule, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      lastSeen,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Emergency Contact: ',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: emergencyContact,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // NEW: Health condition chips
                if (healthConditions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: healthConditions.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFB45309),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );

  Widget _kv(BuildContext context, String k, String v) => Row(
        children: [
          Text(
            '$k: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(v, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

/* --------------------------------- Tabs ----------------------------------- */

/* ------------------------------ Segmented tabs ------------------------------ */

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({required this.controller});
  final TabController controller;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin:
          const EdgeInsets.only(right: 6), // move the tab bar slightly right
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: cs.primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary),
        ),
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Meds'),
          Tab(text: 'Mood'),
          Tab(text: 'Alerts'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }
}

/* ------------------------------ OVERVIEW TAB ------------------------------ */

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      children: const [
        _SectionCard(
          title: 'Vital Signs',
          subtitle: '15 minutes ago',
          leading: Icons.favorite_outline,
          child: Padding(
            padding: EdgeInsets.only(top: 6),
            child: Wrap(
              runSpacing: 14,
              children: [
                _VitalKV(label: 'Heart Rate', value: '77 BPM'),
                _VitalKV(label: 'Blood Pressure', value: '132/85'),
                _VitalKV(label: 'Oxygen Sat', value: '97%'),
                _VitalKV(label: 'Temperature', value: '98.6°F'),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: 'Medication Adherence',
          child: Column(
            children: [
              _MedAdherenceRow(name: 'Lisinopril', percent: 0.95),
              SizedBox(height: 10),
              _MedAdherenceRow(name: 'Metformin', percent: 0.82),
              SizedBox(height: 10),
              _MedAdherenceRow(name: 'Atorvastatin', percent: 0.90),
            ],
          ),
        ),
        SizedBox(height: 12),

        // 🆕 Added Pain Level Card
        _PainLevelCard(
          lastReported: '6 hours ago',
          scoreOutOf10: 4,
          location: 'Lower back',
        ),
      ],
    );
  }
}

class _VitalKV extends StatelessWidget {
  const _VitalKV({required this.label, required this.value});
  final String label, value;

  @override
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MedAdherenceRow extends StatelessWidget {
  const _MedAdherenceRow({required this.name, required this.percent});
  final String name;
  final double percent;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: cs.outlineVariant.withOpacity(.35),
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Pain Level card ----------------------------- */

class _PainLevelCard extends StatelessWidget {
  const _PainLevelCard({
    required this.lastReported,
    required this.scoreOutOf10,
    required this.location,
  });

  final String lastReported;
  final int scoreOutOf10; // 0–10
  final String location;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (scoreOutOf10.clamp(0, 10)) / 10.0;

    return _SectionCard(
      title: 'Pain Level',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last reported time
          Text(
            'Last reported $lastReported',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // Current Pain label + numeric score
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Pain',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '$scoreOutOf10/10',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pain bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: cs.outlineVariant.withOpacity(.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                cs.primary, // dark thumb
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Scale text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No Pain',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                'Severe',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pain location
          Text(
            'Location: $location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------- MEDS TAB -------------------------------- */

class _MedsTab extends StatelessWidget {
  const _MedsTab();

  @override
  @override
  Widget build(BuildContext context) {
    const meds = [
      ('Lisinopril', '10mg • Once daily', 'Next dose: 8:00 AM', 0.95),
      ('Metformin', '500mg • Twice daily', 'Next dose: 12:00 PM', 0.88),
      ('Atorvastatin', '20mg • Once daily', 'Next dose: 8:00 PM', 0.92),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      itemCount: meds.length,
      itemBuilder: (context, i) {
        final m = meds[i];
        return _MedItemCard(
          name: m.$1,
          regimen: m.$2,
          nextDose: m.$3,
          adherence: m.$4,
        );
      },
    );
  }
}

class _MedItemCard extends StatelessWidget {
  const _MedItemCard({
    required this.name,
    required this.regimen,
    required this.nextDose,
    required this.adherence,
  });

  final String name, regimen, nextDose;
  final double adherence;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x12000000))],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _statusChip('active'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            regimen,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            nextDose,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${(adherence * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: adherence,
                    minHeight: 8,
                    backgroundColor: cs.outlineVariant.withOpacity(.35),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF3730A3),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
}

/* -------------------------------- MOOD TAB -------------------------------- */

class _MoodTab extends StatelessWidget {
  const _MoodTab();

  @override
  @override
  Widget build(BuildContext context) {
    const entries = [
      (
        'Today',
        'Feeling positive after morning walk',
        '7/10',
        Icons.trending_up,
      ),
      ('Yesterday', 'Tired but okay', '5/10', Icons.trending_flat),
      ('2 days ago', 'Great day with family visit', '9/10', Icons.trending_up),
      ('3 days ago', 'Joint pain bothering me', '4/10', Icons.trending_down),
      ('4 days ago', 'Physical therapy went well', '7/10', Icons.trending_up),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      children: [
        _SectionCard(
          title: 'Mood History (7 days)',
          icon: Icons.show_chart,
          child: Column(
            children: [
              for (final e in entries)
                _MoodRow(when: e.$1, note: e.$2, score: e.$3, trend: e.$4),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.when,
    required this.note,
    required this.score,
    required this.trend,
  });

  final String when, note, score;
  final IconData trend;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🙂', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        when,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          score,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(trend, size: 16, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- ALERTS TAB ------------------------------- */

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  @override
  Widget build(BuildContext context) {
    const alerts = [
      (
        'Missed evening medication',
        '2 hours ago',
        'medium',
        Icons.warning_amber_rounded,
      ),
      (
        'Low activity detected today',
        '4 hours ago',
        'low',
        Icons.error_outline,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      itemCount: alerts.length,
      itemBuilder: (context, i) {
        final a = alerts[i];
        return _AlertRowItem(title: a.$1, when: a.$2, level: a.$3, icon: a.$4);
      },
    );
  }
}

class _AlertRowItem extends StatelessWidget {
  const _AlertRowItem({
    required this.title,
    required this.when,
    required this.level,
    required this.icon,
  });

  final String title, when, level;
  final IconData icon;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x12000000))],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _levelPill(level),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            when,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _levelPill(String level) {
    final text = level.toLowerCase();
    final bg = text == 'low'
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFF3F4F6); // low vs medium
    final fg =
        text == 'low' ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        level,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/* -------------------------------- Activity tab ----------------------------- */

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  @override
  Widget build(BuildContext context) {
    const items = [
      _ActivityItem(
        title: 'Took medication: Lisinopril 10mg',
        whenText: '2 hours ago',
      ),
      _ActivityItem(
        title: 'Completed physical therapy session',
        whenText: '3 hours ago',
      ),
      _ActivityItem(
        title: 'Reported pain level: 4/10',
        whenText: '6 hours ago',
      ),
      _ActivityItem(
        title: 'Appointment with Dr. Debartolo scheduled',
        whenText: 'Yesterday',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      children: [
        _SectionCard(
          title: 'Recent Activity',
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.title, required this.whenText});
  final String title;
  final String whenText;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left vertical bar
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: cs.onSurface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        // text block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                whenText,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* --------------------------- Small shared widgets -------------------------- */

/* --------------------------- Small shared widgets -------------------------- */

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon, // legacy support (still works)
    this.leading, // NEW: can be IconData or Widget
  });

  final String title;
  final String? subtitle;
  final IconData? icon; // legacy
  final Object? leading; // IconData or Widget
  final Widget child;

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Resolve a leading widget from either `leading` or legacy `icon`
    Widget? leadingWidget;
    if (leading is IconData) {
      leadingWidget = Icon(leading as IconData, color: cs.primary);
    } else if (leading is Widget) {
      leadingWidget = leading as Widget;
    } else if (icon != null) {
      leadingWidget = Icon(icon, color: cs.primary);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x12000000))],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Small “chip” style button used for actions like Call or Message
Widget _chipButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  bool filled = false,
  required VoidCallback onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final bg = filled ? cs.primary : cs.surface;
  final fg = filled ? Colors.white : cs.onSurface;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Execute the caller's action first
        onTap();

        // Show global "Calling…" toast (applies to all chip taps, per your request)
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('📞 Calling…'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // lifts it a bit above a bottom nav if present
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? Colors.transparent : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg), // smaller icon
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13, // slightly smaller text
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

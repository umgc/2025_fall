import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vol_api_service.dart';

// Bring in the read-only views you copied over
import 'allergies_view.dart';
import 'medications_view.dart';
import 'conditions_view.dart';
import 'vol_manage_contacts.dart';
import 'vol_share_screen.dart';


/// Lightweight view model used only for the hub/detail views.
class ContactView {
  final String name, role, phone;
  final bool isPrimary;
  const ContactView({
    required this.name,
    required this.role,
    required this.phone,
    this.isPrimary = false,
  });
}

/// Wrapper screen that pulls live data from the backend, then shows VolHome.
class VolHomeScreen extends StatefulWidget {
  final int patientId;
  const VolHomeScreen({super.key, required this.patientId});

  @override
  State<VolHomeScreen> createState() => _VolHomeScreenState();
}

class _VolHomeScreenState extends State<VolHomeScreen> {
  bool loading = true;
  String? error;
  String firstName = '';
  String lastName = '';
  String? vialId;
  String bloodType = '-';
  List<String> allergiesCritical = const [];
  List<String> medications = const [];
  List<String> conditions = const [];
  List<ContactView> contacts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await VolApiService.getVial(widget.patientId);
      if (data == null) {
        setState(() {
          error = 'No data found.';
          loading = false;
        });
        return;
      }

      setState(() {
        firstName = (data['firstName'] ?? '').toString();
        lastName = (data['lastName'] ?? '').toString();
        vialId = (data['id'] ?? data['vialId'])?.toString();
        bloodType = (data['bloodType'] ?? '-').toString();
        allergiesCritical = List<String>.from(data['allergies'] ?? const []);
        medications = List<String>.from(data['medications'] ?? const []);
        conditions = List<String>.from(data['conditions'] ?? const []);

        final raw = data['emergencyContacts'] as List? ?? const [];
        contacts = raw.map((c) {
          if (c is Map) {
            return ContactView(
              name: (c['name'] ?? '').toString(),
              role: (c['role'] ?? '').toString(),
              phone: (c['phone'] ?? '').toString(),
              isPrimary: (c['isPrimary'] ?? false) == true,
            );
          } else {
            final s = c.toString();
            final parts = s.split('|');
            final name = parts.isNotEmpty ? parts[0].trim() : '';
            final role = parts.length > 1 ? parts[1].trim() : '';
            final phone = parts.length > 2 ? parts[2].trim() : '';
            final isPrim = parts.length > 3 ? parts[3].trim().toUpperCase() == 'PRIMARY' : false;
            return ContactView(name: name, role: role, phone: phone, isPrimary: isPrim);
          }
        }).toList();

        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vial Hub')),
        body: Center(child: Text(error!)),
      );
    }
    return VolHome(
      firstName: firstName,
      lastName: lastName,
      vialId: vialId,
      bloodType: bloodType,
      allergiesCritical: allergiesCritical,
      medications: medications,
      conditions: conditions,
      contacts: contacts,
      onManageContacts: () async {
        final ok = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ManageContactsScreen(patientId: widget.patientId)),
        );
        if (ok == true) {
          await _load();
        }
      },


      onShare: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VolShareScreen(patientId: widget.patientId)),
        );
      },

      onOpenAllergies: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AllergiesView(items: allergiesCritical, critical: [], caution: [],),
      )),
      onOpenMedications: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MedicationsView(items: medications),
      )),
      onOpenConditions: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConditionsView(items: conditions),
      )),
    );
  }
}

class VolHome extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? vialId;
  final String bloodType;
  final List<String> allergiesCritical;
  final List<String> medications;
  final List<String> conditions;
  final List<ContactView> contacts;
  final VoidCallback onManageContacts;
  final VoidCallback onShare;
  final VoidCallback onOpenAllergies;
  final VoidCallback onOpenMedications;
  final VoidCallback onOpenConditions;

  const VolHome({
    super.key,
    required this.firstName,
    required this.lastName,
    this.vialId,
    required this.bloodType,
    required this.allergiesCritical,
    required this.medications,
    required this.conditions,
    required this.contacts,
    required this.onManageContacts,
    required this.onShare,
    required this.onOpenAllergies,
    required this.onOpenMedications,
    required this.onOpenConditions,
  });

  @override
  Widget build(BuildContext context) {
    final int aCount = allergiesCritical.length;
    final int mCount = medications.length;
    final int cCount = conditions.length;
    final int eCount = contacts.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vial Hub'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.qr_code_2),
            onPressed: onShare,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$firstName $lastName',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vialId != null && vialId!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Text('•', style: TextStyle(fontSize: 18, color: Colors.black54)),
                        const SizedBox(width: 10),
                        Text(
                          'Vial ID: $vialId',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE53935)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Blood Type: $bloodType',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _HubButton(
              color: const Color(0xFF2E5AAC),
              label: 'Critical Allergies',
              count: aCount,
              onTap: onOpenAllergies,
            ),
            const SizedBox(height: 12),

            _HubButton(
              color: const Color(0xFF2E49C8),
              label: 'Current Medications',
              count: mCount,
              onTap: onOpenMedications,
            ),
            const SizedBox(height: 12),

            _HubButton(
              color: const Color(0xFFFFA000),
              label: 'Medical Conditions',
              count: cCount,
              onTap: onOpenConditions,
            ),
            const SizedBox(height: 12),

            _HubButton(
              color: const Color(0xFFEB3B3B),
              label: 'Emergency Contacts',
              count: eCount,
              onTap: onManageContacts,
            ),
          ],
        ),
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _HubButton({
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

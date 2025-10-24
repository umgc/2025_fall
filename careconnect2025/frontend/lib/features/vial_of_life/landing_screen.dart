import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:care_connect_app/features/vial_of_life/vial_models.dart';

// Local screens/utilities
import 'medications_view.dart';
import 'allergies_view.dart';
import 'conditions_view.dart';
import 'vol_home.dart';

void main() => runApp(const VialOfLifeApp());

class VialOfLifeApp extends StatelessWidget {
  const VialOfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFFEB3B3B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vial of Life',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandRed,
          primary: brandRed,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      ),
      // Only include routes that don't need runtime data
      routes: {
        '/vial-of-life': (context) => SizedBox.shrink(),
      },
      home: const VialHomePage(),
    );
  }
}


// Landing / First screen (big avatar + details + Scan button)
class LandingScreen extends StatelessWidget {
  final Profile profile;
  const LandingScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big tappable avatar → Vial hub
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (volCtx) => VolHome(
                      firstName: profile.firstName,
                      lastName: profile.lastName,
                      bloodType: profile.bloodType,
                      vialId: profile.id,
                      allergiesCritical: profile.allergiesCritical,
                      medications: profile.medications,
                      conditions: profile.conditions.map((t) => t.label).toList(),
                      contacts: profile.contacts.map((c) => ContactView(
                        name: c.name,
                        role: c.role,
                        phone: c.phone,
                        isPrimary: c.isPrimary,
                      )).toList(),
                      onManageContacts: () {
                        Navigator.of(volCtx).push(
                          MaterialPageRoute(
                            builder: (ctx) => _EditVialScreen(profile: profile),
                          ),
                        );
                      },
                      onShare: () {},
                      onOpenAllergies: () {},
                      onOpenMedications: () {},
                      onOpenConditions: () {},
                    ),
                  ),
                ),
                  child: Container(
                    width: 480,
                    height: 480,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE8EEFF), Color(0xFFDDE6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: const TextStyle(
                          color: Color(0xFF2E5AAC),
                          fontWeight: FontWeight.w800,
                          fontSize: 72,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '(click avatar for Vial)',
                  style: TextStyle(color: Colors.black45, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),

              
              
              // Name + details (right)  |  Blood type (right column centered)
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name and Blood Type Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Name and details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.firstName} ${profile.lastName}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${profile.age} years old',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'DOB: ${profile.dob.toIso8601String().substring(0, 10)}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            Text(
                              'Gender: ${profile.gender}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            Text(
                              'ID: ${profile.id}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Blood type pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFE53935)),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Blood Type: ${profile.bloodType}',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 14),
    // Centered Scan button (not full-width) directly under the row
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _QrScreen(payload: profile.qrPayload()),
                      fullscreenDialog: true,
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 32),
                  label: const Text(
                    'Press to Scan for Emergency Contact',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    backgroundColor: const Color(0xFFEB3B3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
],
          ),
        ),
      ),
    );
  }
}



/* ===================== HOME ===================== */
class VialHomePage extends StatefulWidget {
  const VialHomePage({super.key});
  @override
  State<VialHomePage> createState() => _VialHomePageState();
}

class _VialHomePageState extends State<VialHomePage> {
  final Profile _profile = Profile(
    firstName: 'Margaret',
    lastName: 'Thompson',
    gender: 'Female',
    dob: DateTime(1942, 3, 15),
    id: 'VL-82934',
    bloodType: 'O+',
    allergiesCritical: const ['Penicillin', 'Shellfish'],
    allergiesCaution: const ['Latex'],
    medications: const [
      'Metformin 500mg - Twice daily',
      'Lisinopril 10mg - Once daily',
      'Atorvastatin 20mg - Evening',
      'Aspirin 81mg - Daily',
    ],
    conditions: const [
      Tag('Type 2 Diabetes', TagColor.orange),
      Tag('Hypertension', TagColor.orange),
      Tag('High Cholesterol', TagColor.blue),
      Tag('Osteoarthritis', TagColor.blue),
    ],
    contacts: const [
      Contact(
        name: 'Sarah Thompson',
        role: 'Daughter',
        phone: '(555) 123–4567',
        isPrimary: true,
      ),
      Contact(name: 'Michael Thompson', role: 'Son', phone: '(555) 234–5678'),
      Contact(
        name: 'Dr. Jennifer Davis',
        role: 'Primary Care Physician',
        phone: '(555) 345–6789',
      ),
    ],
    lastUpdated: '2024-12-15',
  );

  @override
  Widget build(BuildContext context) {
    return LandingScreen(profile: _profile);

  }
}

/* ====================== HEADER UTILS ======================= */
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}

/* ====================== PROFILE CARD ======================= */
class ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onShowQr, onEdit;
  const ProfileCard({
    required this.profile,
    required this.onShowQr,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE1E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar (tappable)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (volCtx) => VolHome(
                      firstName: profile.firstName,
                      lastName: profile.lastName,
                      bloodType: profile.bloodType,
                      vialId: profile.id,
                      allergiesCritical: profile.allergiesCritical,
                      medications: profile.medications,
                      conditions: profile.conditions.map((t) => t.label).toList(),
                      contacts: profile.contacts.map((c) => ContactView(
                        name: c.name,
                        role: c.role,
                        phone: c.phone,
                        isPrimary: c.isPrimary,
                      )).toList(),
                      onManageContacts: () {
                        Navigator.of(volCtx).push(
                          MaterialPageRoute(
                            builder: (ctx) => _EditVialScreen(profile: profile),
                          ),
                        );
                      },
                      onShare: () {},
                      onOpenAllergies: () {},
                      onOpenMedications: () {},
                      onOpenConditions: () {},
                    ),
                  ),
                ),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8EEFF), Color(0xFFDDE6FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: Color(0xFF2E5AAC),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.firstName} ${profile.lastName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.age} years old',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'DOB: ${profile.dob.toIso8601String().substring(0, 10)}',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    Text(
                      'Gender: ${profile.gender}',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    Text(
                      'ID: ${profile.id}',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Blood-type pill
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE53935)),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Blood Type: ${profile.bloodType}',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: _GhostButton(
                  icon: Icons.edit_outlined,
                  label: 'Manage Emergency Contacts',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RedButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Scan for Emergency Contact',
                  onTap: onShowQr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          border: Border.all(color: const Color(0xFFE6E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black.withOpacity(0.8)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RedButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEB3B3B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ====================== SECTION SHELLS ======================= */
class _SectionShell extends StatelessWidget {
  final Widget child;
  final Color? borderTint;
  const _SectionShell({required this.child, this.borderTint});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderTint ?? const Color(0xFFE7EBF3)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: child,
    );
  }
}

class _IconSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _IconSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconSectionHeader(icon: icon, iconColor: iconColor, title: title),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _IconSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  const _IconSectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: titleColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

class _SoftRowTile extends StatelessWidget {
  final IconData leadingIcon;
  final String text;
  const _SoftRowTile({required this.leadingIcon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(leadingIcon, size: 20, color: Colors.black.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

/* ====================== ALLERGY CHIPS ======================= */
class _AllergyChip extends StatelessWidget {
  final String label;
  final Color bg, border, textColor, iconColor;
  const _AllergyChip._({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
    required this.iconColor,
  });
  factory _AllergyChip.critical(String label) => _AllergyChip._(
        label: label,
        bg: const Color(0xFFFFEDED),
        border: const Color(0xFFFFD3D3),
        textColor: const Color(0xFFD32F2F),
        iconColor: const Color(0xFFD32F2F),
      );
  factory _AllergyChip.caution(String label) => _AllergyChip._(
        label: label,
        bg: const Color(0xFFFFF4E5),
        border: const Color(0xFFFFE1BB),
        textColor: const Color(0xFFBF6A00),
        iconColor: const Color(0xFFBF6A00),
      );
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }
}

/* ====================== TAGS ======================= */
class TagChip extends StatelessWidget {
  final Tag tag;
  const TagChip({required this.tag});
  @override
  Widget build(BuildContext context) {
    final isOrange = tag.color == TagColor.orange;
    final bg = isOrange ? const Color(0xFFFFF1E0) : const Color(0xFFEAF0FF);
    final fg = isOrange ? const Color(0xFFBF6A00) : const Color(0xFF2E5AAC);
    final border = isOrange ? const Color(0xFFFFD7B2) : const Color(0xFFC9D8FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        tag.label,
        style: TextStyle(fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

/* ====================== CONTACTS (view) ======================= */
class ContactTile extends StatelessWidget {
  final Contact contact;
  const ContactTile({required this.contact});
  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        Expanded(
          child: Text(
            contact.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (contact.isPrimary)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PRIMARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2446D2),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Text(
          contact.phone,
          style: const TextStyle(
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 18,
                color: Colors.black.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                contact.role,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionChip(
                icon: Icons.call,
                label: 'Call',
                onTap: () => _copyAndToast(
                  context,
                  contact.phone,
                  'Number copied — use your Phone app to call',
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.sms,
                label: 'Text',
                onTap: () => _copyAndToast(
                  context,
                  contact.phone,
                  'Number copied — use your Messages app to text',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE0E4EE)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

Future<void> _copyAndToast(BuildContext context, String value, String msg) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

/* ====================== QR SCREEN ======================= */
class _QrScreen extends StatelessWidget {
  final String payload;
  const _QrScreen({required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency QR Code'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 260,
                  gapless: false,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '(click avatar for Vial)',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: payload));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR text copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: const Text('Copy QR Text'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E5AAC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== EDIT SCREEN ===================== */
/* Only Emergency Contacts remain editable here */
class _EditVialScreen extends StatefulWidget {
  final Profile profile;
  const _EditVialScreen({required this.profile});

  @override
  State<_EditVialScreen> createState() => _EditVialScreenState();
}

class _EditVialScreenState extends State<_EditVialScreen> {
  late List<String> allergies;
  late List<String> medications;
  late List<Tag> conditions;
  late List<Contact> contacts;

  final _newAllergyCtrl = TextEditingController();
  final _newMedCtrl = TextEditingController();
  final _newCondCtrl = TextEditingController();
  final _newContactName = TextEditingController();
  final _newContactRole = TextEditingController();
  final _newContactPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    allergies = [
      ...widget.profile.allergiesCritical,
      ...widget.profile.allergiesCaution,
    ];
    medications = [...widget.profile.medications];
    conditions = [...widget.profile.conditions];
    contacts = [...widget.profile.contacts];
    // (No tracker writes here; this screen edits contacts only)
  }

  @override
  void dispose() {
    _newAllergyCtrl.dispose();
    _newMedCtrl.dispose();
    _newCondCtrl.dispose();
    _newContactName.dispose();
    _newContactRole.dispose();
    _newContactPhone.dispose();
    super.dispose();
  }

  Profile _buildUpdatedProfile() {
    return Profile(
      firstName: widget.profile.firstName,
      lastName: widget.profile.lastName,
      gender: widget.profile.gender,
      dob: widget.profile.dob,
      id: widget.profile.id,
      bloodType: widget.profile.bloodType,
      allergiesCritical: allergies,
      allergiesCaution: const [],
      medications: medications,
      conditions: conditions,
      contacts: contacts,
      lastUpdated: DateTime.now().toIso8601String().substring(0, 10),
      secureToken: widget.profile.secureToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        top: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Emergency Contacts ONLY
            SliverToBoxAdapter(
              child: _Shell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _IconSectionHeader(
                      icon: Icons.phone_in_talk_outlined,
                      iconColor: Color(0xFF1B9E4B),
                      title: 'Emergency Contacts',
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        for (int i = 0; i < contacts.length; i++) ...[
                          ContactEditCard(
                            contact: contacts[i],
                            onDelete: () =>
                                setState(() => contacts.removeAt(i)),
                            onSetPrimary: () => setState(() {
                              contacts = contacts
                                  .map(
                                    (c) => Contact(
                                      name: c.name,
                                      role: c.role,
                                      phone: c.phone,
                                      isPrimary: c == contacts[i],
                                    ),
                                  )
                                  .toList();
                            }),
                            onChangeRole: (v) => setState(() {
                              final c = contacts[i];
                              contacts[i] = Contact(
                                name: c.name,
                                role: v,
                                phone: c.phone,
                                isPrimary: c.isPrimary,
                              );
                            }),
                            onChangePhone: (v) => setState(() {
                              final c = contacts[i];
                              contacts[i] = Contact(
                                name: c.name,
                                role: c.role,
                                phone: v,
                                isPrimary: c.isPrimary,
                              );
                            }),
                          ),
                          if (i != contacts.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Add New Emergency Contact',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    _Input(hint: 'Contact Name', controller: _newContactName),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Input(
                            hint: 'Relation (e.g., Son)',
                            controller: _newContactRole,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Input(
                            hint: 'Phone Number',
                            controller: _newContactPhone,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AddButton(
                      label: 'Add Contact',
                      onTap: () {
                        final name = _newContactName.text.trim();
                        final role = _newContactRole.text.trim();
                        final phone = _newContactPhone.text.trim();
                        if (name.isNotEmpty && role.isNotEmpty && phone.isNotEmpty) {
                          setState(() {
                            contacts.add(Contact(name: name, role: role, phone: phone));
                          });
                          _newContactName.clear();
                          _newContactRole.clear();
                          _newContactPhone.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFE6E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () =>
                            Navigator.pop(context, _buildUpdatedProfile()),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E49C8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () =>
                            Navigator.pop(context, _buildUpdatedProfile()),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 1,
        16,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context, _buildUpdatedProfile()),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Vial of Life',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Update emergency medical information',
                  style: TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
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

/* ============ Reusable UI bits for Edit screen ============ */
class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EBF3)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: child,
      ),
    );
  }
}

class _DismissTile extends StatelessWidget {
  final String text;
  final Color color;
  final Color border;
  final VoidCallback onDelete;
  final Color? deleteIconColor;
  const _DismissTile({
    required this.text,
    required this.color,
    required this.border,
    required this.onDelete,
    this.deleteIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.close_rounded,
              color: deleteIconColor ?? const Color(0xFFD32F2F),
            ),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  const _AddRow({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Input(hint: hint, controller: controller),
        ),
        const SizedBox(width: 10),
        _IconSquareButton(icon: Icons.add, onTap: onAdd),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _Input({
    required this.hint,
    required this.controller,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconSquareButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8F0)),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          border: Border.all(color: const Color(0xFFE6E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class ContactEditCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;
  final ValueChanged<String> onChangeRole;
  final ValueChanged<String> onChangePhone;

  const ContactEditCard({
    required this.contact,
    required this.onDelete,
    required this.onSetPrimary,
    required this.onChangeRole,
    required this.onChangePhone,
  });

  @override
  Widget build(BuildContext context) {
    final roleCtrl = TextEditingController(text: contact.role);
    final phoneCtrl = TextEditingController(text: contact.phone);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // name + primary chip + delete
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE6E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contact.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (contact.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2446D2),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEB3B3B),
                ),
                tooltip: 'Delete',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: roleCtrl,
                  decoration: ContactInputDecoration('Relation'),
                  onChanged: onChangeRole,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: ContactInputDecoration('Phone Number'),
                  onChanged: onChangePhone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: contact.isPrimary ? null : onSetPrimary,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE6E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: Colors.black87,
              ),
              child: const Text(
                'Set as Primary Contact',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration ContactInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}

class _RemovableTag extends StatelessWidget {
  final String label;
  final bool isOrange;
  final VoidCallback onRemove;
  const _RemovableTag({
    required this.label,
    required this.isOrange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOrange ? const Color(0xFFFFF1E0) : const Color(0xFFEAF0FF);
    final fg = isOrange ? const Color(0xFFBF6A00) : const Color(0xFF2E5AAC);
    final border = isOrange ? const Color(0xFFFFD7B2) : const Color(0xFFC9D8FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: fg),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: fg),
          ),
        ],
      ),
    );
  }
}

/* =================== Share / "Print" helper =================== */
Future<void> _openShareSheet(BuildContext context, Profile p) async {
  final primary = p.contacts.firstWhere(
    (c) => c.isPrimary,
    orElse: () => p.contacts.isNotEmpty ? p.contacts.first : const Contact(name: 'N/A', role: '', phone: ''),
  );

  final text = '''
  Vial of Life — Emergency Info

  Name: ${p.firstName} ${p.lastName}
  DOB: ${p.dob.toIso8601String().substring(0,10)} (Age: ${p.age}) | Gender: ${p.gender}
  ID: ${p.id}
  Blood Type: ${p.bloodType}

  Allergies: ${[...p.allergiesCritical, ...p.allergiesCaution].join(', ')}

  Medications:
  ${p.medications.map((m) => '• $m').join('\\n')}

  Primary Contact: ${primary.name} — ${primary.phone}

  Full Details Online: https://vialoflife.app/ei?t=${p.secureToken}
  ''';

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy emergency text'),
              onTap: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_rounded),
              title: const Text('Show printable view'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _PrintableEmergencyView(text: text),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrintableEmergencyView extends StatelessWidget {
  final String text;
  const _PrintableEmergencyView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Info (Printable)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
            tooltip: 'Copy',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
    );
  }
}

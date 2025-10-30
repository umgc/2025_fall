import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import '../../../../providers/user_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../services/api_service.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../dashboard/models/patient_model.dart';

class VisitCompletedSuccessPage extends StatefulWidget {
  final int patientId;
  final String serviceType;
  final String checkinLocationType;
  final String checkoutLocationType;
  final double? checkinLatitude;
  final double? checkinLongitude;
  final double? checkoutLatitude;
  final double? checkoutLongitude;
  final String notes;
  final int duration; // seconds
  final DateTime checkinTime;
  final DateTime checkoutTime;

  const VisitCompletedSuccessPage({
    super.key,
    required this.patientId,
    required this.serviceType,
    required this.checkinLocationType,
    required this.checkoutLocationType,
    this.checkinLatitude,
    this.checkinLongitude,
    this.checkoutLatitude,
    this.checkoutLongitude,
    required this.notes,
    required this.duration,
    required this.checkinTime,
    required this.checkoutTime,
  });

  @override
  State<VisitCompletedSuccessPage> createState() => _VisitCompletedSuccessPageState();
}

class _VisitCompletedSuccessPageState extends State<VisitCompletedSuccessPage> {
  Patient? _selectedPatient;
  bool _isLoading = true;
  String? _error;

  // Compact style
  static const double _kPad = 10.0;
  TextStyle get _labelSm => const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54);
  TextStyle get _valueMd => const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87);

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) throw Exception('User not authenticated');

      final caregiverId = user.caregiverId ?? user.id;
      final response = await ApiService.getCaregiverPatients(caregiverId);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (var json in data) {
          try {
            Map<String, dynamic> patientJson;
            if (json is Map && json.containsKey('patient') && json['patient'] != null) {
              final patientData = json['patient'];
              patientJson = patientData is Map ? Map<String, dynamic>.from(patientData) : Map<String, dynamic>.from(json);
            } else {
              patientJson = Map<String, dynamic>.from(json);
            }
            final patient = Patient.fromJson(patientJson);
            if (patient.id == widget.patientId) {
              setState(() {
                _selectedPatient = patient;
                _isLoading = false;
              });
              return;
            }
          } catch (_) {}
        }
        throw Exception('Patient not found');
      } else {
        throw Exception('Failed to load patient details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatAddress(Patient patient) {
    final a = patient.address;
    if (a == null) return 'Address not available';
    final parts = <String>[
      if ((a.line1 ?? '').isNotEmpty) a.line1!,
      if ((a.line2 ?? '').isNotEmpty) a.line2!,
      if ((a.city ?? '').isNotEmpty) a.city!,
      if ((a.state ?? '').isNotEmpty) a.state!,
      if ((a.zip ?? '').isNotEmpty) a.zip!,
    ];
    return parts.join(', ');
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    if (m > 0 && s == 0) return '${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${d.inSeconds}s';
  }

  String _formatDurationDetailed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : t.hour;
    final display = h == 0 ? 12 : h;
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$display:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} $ampm';
  }

  String _formatLocation(String locationType, double? lat, double? lng, Patient patient) {
    if (locationType.toLowerCase() == 'gps' && lat != null && lng != null) {
      return 'GPS ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
    if (locationType.toLowerCase() == 'gps') return 'GPS (coords unavailable)';
    return _formatAddress(patient);
  }

  String _uniqueFileName(String base) {
    final ts = DateTime.now().toUtc().microsecondsSinceEpoch;
    final rand = math.Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return '${base}_${ts}_$rand.edi';
  }

  void _goToDashboard() => context.go('/dashboard?role=CAREGIVER');

  Future<void> _exportVisitData() async {
    try {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient data not available for export'), backgroundColor: Colors.red));
        return;
      }
      final edi = _generateEDIContent();
      final bytes = utf8.encode(edi);

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'text/plain');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final a = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'visit_${_selectedPatient!.id}_${widget.checkinTime.millisecondsSinceEpoch}.edi';
        html.document.body?.children.add(a);
        a.click();
        html.document.body?.children.remove(a);
        html.Url.revokeObjectUrl(url);
      } else {
        final fileName = _uniqueFileName('visit_${_selectedPatient!.id}');
        String? downloadsPath;
        try {
          downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir = Directory(downloadsPath);
          if (!await downloadsDir.exists()) {
            final ext = await getExternalStorageDirectory();
            downloadsPath = ext?.path;
          }
          final savePath = '$downloadsPath/$fileName';
          final file = File(savePath);
          await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
          await OpenFilex.open(savePath);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: $savePath')));
        } catch (_) {
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/$fileName';
          await File(tempPath).writeAsBytes(Uint8List.fromList(bytes), flush: true);
          final xfile = XFile(tempPath, mimeType: 'text/plain', name: fileName);
          await Share.shareXFiles([xfile], text: 'EVV EDI export');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit data exported successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _previewVisitEdi() async {
    if (kIsWeb) return;
    final edi = _generateEDIContent();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Preview EDI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(edi, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: edi));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exportVisitData,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save to Downloads'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _generateEDIContent() {
    final patient = _selectedPatient!;
    final maNumber = patient.maNumber ?? 'SUBSCR${patient.id.toString().padLeft(5, '0')}';

    final now = DateTime.now();
    final isaDate = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final isaTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final gsDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final gsTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final serviceDate = '${widget.checkinTime.year}${widget.checkinTime.month.toString().padLeft(2, '0')}${widget.checkinTime.day.toString().padLeft(2, '0')}';

    String patientDob = '19700101';
    if (patient.dob.isNotEmpty) {
      try {
        final dobDate = DateTime.parse(patient.dob);
        patientDob = '${dobDate.year}${dobDate.month.toString().padLeft(2, '0')}${dobDate.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final gender = (patient.gender?.toUpperCase() == 'MALE' || patient.gender?.toUpperCase() == 'M') ? 'M' : 'F';
    final claimId = '${patient.id}${widget.checkinTime.millisecondsSinceEpoch.toString().substring(0, 10)}';
    final evvId = 'EVV-$claimId';
    final units = ((widget.duration / 15).ceil()).toString();
    final totalCharge = (30.0 * (widget.duration / 15).ceil()).toStringAsFixed(2);

    final addressLine1 = patient.address?.line1 ?? '123 Main St';
    final city = patient.address?.city ?? 'Richmond';
    final state = patient.address?.state ?? 'VA';
    final zip = patient.address?.zip ?? '23220';

    final controlNumber = now.millisecondsSinceEpoch.toString().substring(3, 12);
    final segmentCount = widget.notes.isNotEmpty ? 31 : 30;

    final ediContent = '''ISA*00*          *00*          *ZZ*SUBMIT123      *ZZ*987654321      *$isaDate*$isaTime*^*00501*$controlNumber*0*P*:~
GS*HC*SUBMIT123*987654321*$gsDate*$gsTime*$controlNumber*X*005010X222A1~
ST*837*0001*005010X222A1~
BHT*0019*00*$claimId*$gsDate*$gsTime*CH~
NM1*41*2*Your Agency Name*****46*SUBMIT123~
PER*IC*Billing Contact*TE*5551234567~
NM1*40*2*ANTHEM*****46*987654321~
HL*1**20*1~
PRV*BI*PXC*251E00000X~
NM1*85*2*Your Agency Name*****XX*1234567893~
N3*123 Care Street~
N4*Richmond*VA*23220~
REF*EI*123456789~
HL*2*1*22*0~
SBR*P*18**MC*****MC~
NM1*IL*1*${patient.lastName}*${patient.firstName}****MI*$maNumber~
N3*$addressLine1~
N4*$city*$state*$zip~
DMG*D8*$patientDob*$gender~
NM1*PR*2*ANTHEM*****PI*00123~
CLM*$claimId*$totalCharge***12:B:1**A*Y*Y~
DTP*434*RD8*$serviceDate-$serviceDate~
REF*D9*AUTH12345~
REF*F8*$evvId~
HI*BK:I10~
NM1*82*1*Worker*Alice****XX*1098765432~
PRV*PE*PXC*3747P1801X~
LX*1~
SV1*HC:T1019*$totalCharge*UN*$units***1~
DTP*472*D8*$serviceDate~
${widget.notes.isNotEmpty ? 'NTE*ADD*${widget.notes.replaceAll('~', '')}~\n' : ''}SE*$segmentCount*0001~
GE*1*$controlNumber~
IEA*1*$controlNumber~
''';

    return ediContent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Visit Completed'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/evv'),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState();
    if (_selectedPatient == null) return _buildPatientNotFoundState();
    return _buildSuccessPage();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            const Text('Error Loading Patient', style: AppTheme.headingSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_error!, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadPatientDetails, style: AppTheme.primaryButtonStyle, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 16),
            const Text('Patient Not Found', style: AppTheme.headingSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('The selected patient could not be found.', style: AppTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.go('/evv/select-patient'), style: AppTheme.primaryButtonStyle, child: const Text('Back to Patient Selection')),
          ],
        ),
      ),
    );
  }

  // ---------- COMPACT SUCCESS PAGE ----------
  Widget _buildSuccessPage() {
    final patient = _selectedPatient!;
    final fullName = '${patient.firstName} ${patient.lastName}';
    final maNumber = patient.maNumber ?? 'MA${patient.id.toString().padLeft(9, '0')}';
    final addr = _formatAddress(patient);
    final duration = Duration(seconds: widget.duration);

    final inLoc = _formatLocation(widget.checkinLocationType, widget.checkinLatitude, widget.checkinLongitude, patient);
    final outLoc = _formatLocation(widget.checkoutLocationType, widget.checkoutLatitude, widget.checkoutLongitude, patient);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_kPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // compact success banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!, width: 1),
            ),
            child: Text('Visit completed and ready for submission', style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),

          // EVV compact
          _evvCompact(inLoc, outLoc),

          const SizedBox(height: 8),

          // two tight cards
          LayoutBuilder(builder: (c, cons) {
            final isWide = cons.maxWidth >= 640;

            final left = _cardTight(children: [
              Row(children: [const Icon(Icons.person_outline, size: 18, color: Colors.black54), const SizedBox(width: 6), Text('Patient & Service', style: _labelSm)]),
              const SizedBox(height: 6),
              Text(fullName, style: _valueMd),
              const SizedBox(height: 4),
              _chip(maNumber),
              const SizedBox(height: 6),
              Text(addr, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const Divider(height: 16),
              Text('Service Type', style: _labelSm),
              const SizedBox(height: 2),
              Text(widget.serviceType, style: _valueMd),
            ]);

            final right = _cardTight(children: [
              Row(children: [const Icon(Icons.schedule, size: 18, color: Colors.black54), const SizedBox(width: 6), Text('Time & Duration', style: _labelSm)]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _kvTight('Check-In', _formatTime(widget.checkinTime))),
                Expanded(child: _kvTight('Check-Out', _formatTime(widget.checkoutTime))),
              ]),
              const SizedBox(height: 4),
              _kvTight('Total', _formatDuration(duration)),
              Text('(${_formatDurationDetailed(duration)})', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ]);

            if (!isWide) return Column(children: [left, right]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 8), Expanded(child: right)]);
          }),

          // compact actions
          _compactActions(),
        ],
      ),
    );
  }

  // ---------- SMALL HELPERS ----------
  Widget _kvTight(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _labelSm),
        const SizedBox(height: 1),
        Text(value, style: _valueMd),
      ]);

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _cardTight({required List<Widget> children}) => Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      );

  Widget _evvCompact(String inLoc, String outLoc) {
    String badge(String type) => type.toLowerCase() == 'gps' ? 'GPS' : 'PATIENT ADDRESS';
    Color badgeColor(String type) => type.toLowerCase() == 'gps' ? Colors.blue : Colors.green;

    return _cardTight(children: [
      Row(children: [const Icon(Icons.verified, size: 18, color: Colors.blue), const SizedBox(width: 6), Text('EVV Location Verification', style: _labelSm)]),
      const SizedBox(height: 6),
      Row(children: [
        Icon(widget.checkinLocationType.toLowerCase() == 'gps' ? Icons.gps_fixed : Icons.home, size: 16, color: badgeColor(widget.checkinLocationType)),
        const SizedBox(width: 6),
        Text('Check-In', style: _labelSm),
        const SizedBox(width: 6),
        _tinyBadge(badge(widget.checkinLocationType), badgeColor(widget.checkinLocationType)),
      ]),
      const SizedBox(height: 2),
      Padding(padding: const EdgeInsets.only(left: 22), child: Text(inLoc, style: const TextStyle(fontSize: 12))),
      const SizedBox(height: 8),
      Row(children: [
        Icon(widget.checkoutLocationType.toLowerCase() == 'gps' ? Icons.gps_fixed : Icons.home, size: 16, color: badgeColor(widget.checkoutLocationType)),
        const SizedBox(width: 6),
        Text('Check-Out', style: _labelSm),
        const SizedBox(width: 6),
        _tinyBadge(badge(widget.checkoutLocationType), badgeColor(widget.checkoutLocationType)),
      ]),
      const SizedBox(height: 2),
      Padding(padding: const EdgeInsets.only(left: 22), child: Text(outLoc, style: const TextStyle(fontSize: 12))),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
        child: const Text('EVV compliance confirmed for this visit.', style: TextStyle(fontSize: 12)),
      ),
    ]);
  }

  Widget _tinyBadge(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.25))),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      );

  Widget _compactActions() {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 6, _kPad, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportVisitData,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: shape),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export EDI', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          if (!kIsWeb)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previewVisitEdi,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: shape),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: const Text('Preview', style: TextStyle(fontSize: 13)),
              ),
            ),
          if (!kIsWeb) const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _goToDashboard,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: shape, backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, elevation: 1),
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              label: const Text('Dashboard', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

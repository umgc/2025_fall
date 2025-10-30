import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import '../../../../providers/user_provider.dart';
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
  final int duration; // Duration in seconds
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
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch patient details
      final caregiverId = user.caregiverId ?? user.id;
      final response = await ApiService.getCaregiverPatients(caregiverId);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Find the specific patient
        for (var json in data) {
          try {
            Map<String, dynamic> patientJson;
            if (json.containsKey('patient') && json['patient'] != null) {
              final patientData = json['patient'];
              if (patientData is Map) {
                patientJson = Map<String, dynamic>.from(patientData);
              } else {
                patientJson = Map<String, dynamic>.from(json);
              }
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
          } catch (e) {
            print('Error parsing patient: $e');
          }
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
    final address = patient.address;
    if (address == null) {
      return 'Address not available';
    }

    final line1 = address.line1 ?? '';
    final line2 = address.line2 ?? '';
    final city = address.city ?? '';
    final state = address.state ?? '';
    final zip = address.zip ?? '';

    final addressParts = <String>[];
    if (line1.isNotEmpty) addressParts.add(line1);
    if (line2.isNotEmpty) addressParts.add(line2);
    if (city.isNotEmpty) addressParts.add(city);
    if (state.isNotEmpty) addressParts.add(state);
    if (zip.isNotEmpty) addressParts.add(zip);

    return addressParts.join(', ');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds;
    
    if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDurationDetailed(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute:$second $amPm';
  }

  String _formatLocation(String locationType, double? latitude, double? longitude, Patient patient) {
    if (locationType == 'gps' && latitude != null && longitude != null) {
      return 'GPS: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    } else {
      return _formatAddress(patient);
    }
  }

  void _goToDashboard() {
    context.go('/evv');
  }

  void _exportVisitData() {
    try {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient data not available for export'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate EDI content
      final ediContent = _generateEDIContent();
      
      // Create blob and download
      final bytes = utf8.encode(ediContent);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'visit_${_selectedPatient!.id}_${widget.checkinTime.millisecondsSinceEpoch}.edi';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      } catch (e) {
        patientDob = '19700101';
      }
    }
    
    final gender = (patient.gender?.toUpperCase() == 'MALE' || patient.gender?.toUpperCase() == 'M') ? 'M' : 'F';
    
    final claimId = '${patient.id}${widget.checkinTime.millisecondsSinceEpoch.toString().substring(0, 10)}';
    final evvId = 'EVV-${claimId}';
    final lineEvvId = 'EVV-LINE-${claimId}';
    
    final units = ((widget.duration / 15).ceil()).toString();
    final totalCharge = (30.0 * (widget.duration / 15).ceil()).toStringAsFixed(2);
    
    final addressLine1 = patient.address?.line1 ?? '123 Main St';
    final city = patient.address?.city ?? 'Richmond';
    final state = patient.address?.state ?? 'VA';
    final zip = patient.address?.zip ?? '23220';
    
    final controlNumber = now.millisecondsSinceEpoch.toString().substring(3, 12);
    
    // Calculate segment count (base 30 segments + 1 if notes exist)
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Visit Completed'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/evv'),
           icon: Icon( Icons.cancel,
                color: Theme.of(context).colorScheme.primary,
              ),
           label: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                )),
          ), 
         
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_selectedPatient == null) {
      return _buildPatientNotFoundState();
    }
    
    return _buildSuccessPage();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Patient',
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPatientDetails,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
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
            Icon(
              Icons.person_off,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Patient Not Found',
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The selected patient could not be found.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/evv/select-patient'),
              style: AppTheme.primaryButtonStyle,
              child: const Text('Back to Patient Selection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessPage() {
    final patient = _selectedPatient!;
    final fullName = '${patient.firstName} ${patient.lastName}';
    final maNumber = 'MA${patient.id.toString().padLeft(9, '0')}';
    final address = _formatAddress(patient);
    final duration = Duration(seconds: widget.duration);
    
    final checkinLocation = _formatLocation(
      widget.checkinLocationType, 
      widget.checkinLatitude, 
      widget.checkinLongitude, 
      patient
    );
    
    final checkoutLocation = _formatLocation(
      widget.checkoutLocationType, 
      widget.checkoutLatitude, 
      widget.checkoutLongitude, 
      patient
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visit Completed Successfully',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your visit has been recorded and is ready for submission to the EVV system.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Patient & Service Card
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Patient & Service',
                  icon: Icons.person,
                  iconColor: Colors.blue[600]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          maNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Service Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.serviceType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Time & Duration',
                  icon: Icons.access_time,
                  iconColor: Colors.orange[600]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check-In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(widget.checkinTime),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check-Out',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(widget.checkoutTime),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Total Duration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '(${_formatDurationDetailed(duration)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // EVV Location Verification Card
          _buildInfoCard(
            title: 'EVV Location Verification',
            icon: Icons.location_on,
            iconColor: Colors.purple[600]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Check-In Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    checkinLocation,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Check-Out Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    checkoutLocation,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'EVV Compliance: Both check-in and check-out locations have been recorded and meet Electronic Visit Verification requirements.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              // Export Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportVisitData,
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Export EDI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Dashboard Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _goToDashboard,
                  icon: const Icon(
                    Icons.dashboard,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Return to Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

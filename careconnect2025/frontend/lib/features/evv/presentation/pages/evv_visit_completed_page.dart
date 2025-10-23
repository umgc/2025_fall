import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import '../../../../providers/user_provider.dart';
import '../../../../widgets/responsive_page_wrapper.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../services/edi_service.dart';
import '../../../dashboard/models/patient_model.dart';

class EvvVisitCompletedPage extends StatefulWidget {
  final int patientId;
  
  const EvvVisitCompletedPage({
    super.key,
    required this.patientId,
  });

  @override
  State<EvvVisitCompletedPage> createState() => _EvvVisitCompletedPageState();
}

class _EvvVisitCompletedPageState extends State<EvvVisitCompletedPage> {
  Patient? _patient;
  bool _isLoading = true;
  String? _error;
  
  // Visit summary data (in a real app, this would come from the backend)
  DateTime? _visitStartTime;
  DateTime? _visitEndTime;
  Duration? _visitDuration;
  List<String> _completedTasks = [];
  String _visitNotes = '';
  String _locationAddress = '';
  
  // EDI generation state
  final EdiService _ediService = EdiService();
  bool _isGeneratingEdi = false;
  String? _ediGenerationStatus;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _loadVisitSummary();
  }

  Future<void> _loadPatientData() async {
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

      // In a real implementation, you would fetch the specific patient
      // For now, we'll create a mock patient object
      _patient = Patient(
        id: widget.patientId,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '555-0123',
        dob: '1980-01-01',
        relationship: 'self',
        address: Address(
          line1: '123 Main St',
          city: 'Anytown',
          state: 'NY',
          zip: '12345',
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVisitSummary() async {
    // In a real implementation, you would fetch the visit summary from the backend
    // For now, we'll use mock data
    setState(() {
      _visitStartTime = DateTime.now().subtract(const Duration(hours: 1, minutes: 30));
      _visitEndTime = DateTime.now();
      _visitDuration = _visitEndTime!.difference(_visitStartTime!);
      _completedTasks = [
        'Medication Administration',
        'Vital Signs Check',
        'Meal Preparation',
        'Personal Care',
      ];
      _visitNotes = 'Patient was in good spirits. Completed all scheduled tasks. No issues reported.';
      _locationAddress = '123 Main St, Anytown, NY 12345';
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Generate EDI 837 file for the completed visit
  Future<void> _generateEdiFile() async {
    if (_patient == null || _visitStartTime == null || _visitEndTime == null || _visitDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit data incomplete. Cannot generate EDI file.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingEdi = true;
      _ediGenerationStatus = 'Preparing EDI file...';
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate EDI 837 file
      final result = await _ediService.generateMockEdi837(
        visitId: widget.patientId, // Using patientId as visitId for demo
        patientId: widget.patientId,
        caregiverId: user.id ?? 1,
        visitDate: _visitStartTime!,
        visitDuration: _visitDuration!,
        servicesProvided: _completedTasks,
        location: _locationAddress,
        notes: _visitNotes,
      );

      if (result.success && result.ediContent != null && result.fileName != null) {
        setState(() {
          _ediGenerationStatus = 'Downloading file...';
        });

        // Save the EDI file - handle web and mobile differently
        if (kIsWeb) {
          // Web download using dart:html
          final bytes = Uint8List.fromList(result.ediContent!.codeUnits);
          final blob = html.Blob([bytes], 'text/plain');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', result.fileName!)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          // Mobile download using file_saver
          await FileSaver.instance.saveAs(
            name: result.fileName!,
            bytes: Uint8List.fromList(result.ediContent!.codeUnits),
            ext: 'txt',
            mimeType: MimeType.text,
          );
        }

        setState(() {
          _ediGenerationStatus = 'EDI file generated successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'EDI file generated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(result.error ?? 'Failed to generate EDI file');
      }
    } catch (e) {
      setState(() {
        _ediGenerationStatus = 'Error generating EDI file';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating EDI file: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingEdi = false;
      });

      // Clear status message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _ediGenerationStatus = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Completed'),
        backgroundColor: const Color(0xFF14366E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_patient == null) {
      return _buildErrorState();
    }
    
    return _buildVisitSummary();
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
              'Error Loading Visit Summary',
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Visit summary not found',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/evv/dashboard'),
              style: AppTheme.primaryButtonStyle,
              child: const Text('Back to EVV Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitSummary() {
    final theme = Theme.of(context);
    final fullName = '${_patient!.firstName} ${_patient!.lastName}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Header
          Card(
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit Completed Successfully!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fullName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Visit Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Start Time',
                    value: _visitStartTime != null ? _formatDateTime(_visitStartTime!) : 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.access_time_filled,
                    label: 'End Time',
                    value: _visitEndTime != null ? _formatDateTime(_visitEndTime!) : 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: _visitDuration != null ? _formatDuration(_visitDuration!) : 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: _locationAddress,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Completed Tasks
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completed Tasks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_completedTasks.isEmpty)
                    const Text(
                      'No tasks completed',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...(_completedTasks.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Visit Notes
          if (_visitNotes.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit Notes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _visitNotes,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/evv/dashboard'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('EVV Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/evv/select-patient'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Visit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // EDI Generation Section
          Card(
            color: Colors.blue.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EDI Generation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate EDI 837 (Healthcare Claim) file for billing and claims processing.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingEdi ? null : _generateEdiFile,
                          icon: _isGeneratingEdi 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.file_download),
                          label: Text(_isGeneratingEdi ? 'Generating...' : 'Generate EDI 837'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_ediGenerationStatus != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _ediGenerationStatus!.contains('Error') 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _ediGenerationStatus!.contains('Error') 
                              ? Icons.error_outline 
                              : Icons.info_outline,
                            size: 16,
                            color: _ediGenerationStatus!.contains('Error') 
                              ? Colors.red 
                              : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ediGenerationStatus!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _ediGenerationStatus!.contains('Error') 
                                  ? Colors.red 
                                  : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Additional Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/evv/review-records'),
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Review Records'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/evv/visit-history'),
                          icon: const Icon(Icons.history),
                          label: const Text('Visit History'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => context.go('/dashboard'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

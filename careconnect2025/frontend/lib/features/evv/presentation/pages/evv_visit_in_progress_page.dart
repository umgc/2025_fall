import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../../providers/user_provider.dart';
import '../../../../services/evv_service.dart';
import '../../../../widgets/responsive_page_wrapper.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../dashboard/models/patient_model.dart';
import 'evv_visit_completed_page.dart';

class EvvVisitInProgressPage extends StatefulWidget {
  final int patientId;
  
  const EvvVisitInProgressPage({
    super.key,
    required this.patientId,
  });

  @override
  State<EvvVisitInProgressPage> createState() => _EvvVisitInProgressPageState();
}

class _EvvVisitInProgressPageState extends State<EvvVisitInProgressPage> {
  Patient? _patient;
  bool _isLoading = true;
  bool _isEndingVisit = false;
  String? _error;
  
  // Visit tracking
  DateTime? _visitStartTime;
  Timer? _visitTimer;
  Duration _visitDuration = Duration.zero;
  
  // Location tracking
  double? _currentLat;
  double? _currentLng;
  String? _currentAddress;
  bool _isTrackingLocation = false;
  
  // Visit notes
  final TextEditingController _notesController = TextEditingController();
  final List<String> _completedTasks = [];
  final List<String> _availableTasks = [
    'Medication Administration',
    'Vital Signs Check',
    'Meal Preparation',
    'Personal Care',
    'Physical Therapy',
    'Housekeeping',
    'Companionship',
    'Transportation',
  ];

  @override
  void initState() {
    super.initState();
    _visitStartTime = DateTime.now();
    _startVisitTimer();
    _loadPatientData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _visitTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startVisitTimer() {
    _visitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_visitStartTime != null) {
        setState(() {
          _visitDuration = DateTime.now().difference(_visitStartTime!);
        });
      }
    });
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

  Future<void> _startLocationTracking() async {
    setState(() {
      _isTrackingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get initial location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });

      // Set up location stream for continuous tracking
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      });
    } catch (e) {
      print('Location tracking error: $e');
    } finally {
      setState(() {
        _isTrackingLocation = false;
      });
    }
  }

  void _toggleTask(String task) {
    setState(() {
      if (_completedTasks.contains(task)) {
        _completedTasks.remove(task);
      } else {
        _completedTasks.add(task);
      }
    });
  }

  Future<void> _endVisit() async {
    if (_completedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete at least one task before ending the visit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isEndingVisit = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create visit completion data
      final visitData = {
        'patientId': widget.patientId,
        'caregiverId': user.caregiverId ?? user.id,
        'startTime': _visitStartTime?.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'duration': _visitDuration.inMinutes,
        'location': {
          'latitude': _currentLat,
          'longitude': _currentLng,
          'address': _currentAddress,
        },
        'completedTasks': _completedTasks,
        'notes': _notesController.text,
        'status': 'COMPLETED',
      };

      // In a real implementation, you would save this to the backend
      print('Completing visit with data: $visitData');

      // Navigate to visit completed page
      if (mounted) {
        context.go('/evv/visit-completed?patientId=${widget.patientId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending visit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isEndingVisit = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit in Progress'),
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
    
    return _buildVisitInProgress();
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
              _error ?? 'Patient not found',
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

  Widget _buildVisitInProgress() {
    final theme = Theme.of(context);
    final fullName = '${_patient!.firstName} ${_patient!.lastName}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info & Timer Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Visit in Progress',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Visit Timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _formatDuration(_visitDuration),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isTrackingLocation)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Tracking location...'),
                      ],
                    )
                  else if (_currentLat != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Location Tracked',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentAddress ?? 'Location coordinates captured',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Location not available',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tasks Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks & Services',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mark completed tasks:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTasks.map((task) {
                      final isCompleted = _completedTasks.contains(task);
                      return FilterChip(
                        label: Text(task),
                        selected: isCompleted,
                        onSelected: (selected) => _toggleTask(task),
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                        avatar: isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.green)
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Visit Notes
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
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add notes about the visit...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // End Visit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEndingVisit ? null : _endVisit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isEndingVisit
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Ending Visit...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'End Visit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
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

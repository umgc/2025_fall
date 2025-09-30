import 'dart:convert';

import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/features/notetaker/models/patient_note_model.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/notetaker_config_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotetakerSearchPage extends StatefulWidget {
  const NotetakerSearchPage({super.key});

  @override
  State<NotetakerSearchPage> createState() => _NotetakerSearchPageState();
}

class _NotetakerSearchPageState extends State<NotetakerSearchPage> {
  static const String fetchURL = '/patient-notes/{patientId}/search';
  PatientNotetakerConfigDTO? _currentConfig;
  List<PatientNote>? _currentPatientNotes;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  UserSession? _user;
  List<Map<String, String>> _patientList = [];
  String? _selectedPatientId;
  bool _isPatient = false;
  bool _isEnabled = true;
  bool _permitCaregiverAccess = false;
  late List<Widget> _NotesWidgetList = [];

  // Form controllers
  final TextEditingController _noteController = TextEditingController();
  String? _selectedDropdownValue;

  @override
  void initState() {
    super.initState();
    // need to load the page. first thing we need is patients
    init();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    if (user == null) {
      Future.microtask(() => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    //TODO
    return Scaffold(
      appBar: AppBar(title: const Text('Notetaker Search')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildConfigForm(),
    );
  }

  Widget _buildConfigForm() {
    final theme = Theme.of(context);
    List<Widget> childWidgets = [];
    final successText =
        'Configure your Notetaker assistant to recognize PII, trigger words, etc and upload voice samples for speaker recognition.';
    final failureText =
        'Configuration options cannot be displayed because either you have no patients or their was an error fetching them.';
    if (_isPatient) {
      childWidgets = [
        _buildInfoCard(theme, successText),
        const SizedBox(height: 24),
        // _buildNotesSearchFilters(theme),
        // const SizedBox(height: 24),
        _buildNotesSection(theme),
        const SizedBox(height: 24),
      ];
    } else if (_patientList.isEmpty) {
      childWidgets = [_buildInfoCard(theme, failureText)];
    } else if (_selectedPatientId == null) {
      childWidgets = [
        _buildInfoCard(theme, successText),
        const SizedBox(height: 24),
        _buildPatientSection(theme),
      ];
    } else {
      childWidgets = [
        _buildInfoCard(theme, successText),
        const SizedBox(height: 24),
        _buildPatientSection(theme),
        const SizedBox(height: 24),
        // _buildNotesSearchFilters(theme),
        // const SizedBox(height: 24),
        _buildNotesSection(theme),
        const SizedBox(height: 24),
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: childWidgets,
      ),
    );
  }

  Future<void> _fetchPatientData(int patientId) async {
    try {
      final config = await NotetakerConfigService.getUserNotetakerConfig(
        patientId,
        context,
      );
      final patientNotes = await NotetakerConfigService.getPatientNotes(
        patientId,
      );
      if (config != null) {
        setState(() {
          _currentConfig = config;
          _isEnabled = config.isEnabled;
          _permitCaregiverAccess = config.permitCaregiverAccess;
          _currentPatientNotes = patientNotes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load Patient\'s Notetaker configuration: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> init() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        _user = userProvider.user;
        if (_user == null) throw Exception('User not found');
        final userRole = _user!.role;
        _isPatient = userRole.toUpperCase() == 'PATIENT';
      });
      if (!_isPatient && _user!.caregiverId != null) {
        http.Response patientResponse = await ApiService.getCaregiverPatients(
          _user!.caregiverId!,
        );
        setState(() {
          _patientList = (jsonDecode(patientResponse.body) as List<dynamic>)
              .map(
                (patientWLink) => {
                  'id': patientWLink['patient']['id'].toString(),
                  'name':
                      '${patientWLink['patient']['firstName']} ${patientWLink['patient']['lastName']}',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    if (_isPatient) {
      _fetchPatientData(_user!.patientId!);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //TODO
  Future<void> _saveEditNote() async {
    setState(() => _isSaving = true);
    try {
      if (_user == null) throw Exception('User not found');
      List<PatientNotetakerKeyword> keywordList = [];
      final config = PatientNotetakerConfigDTO(
        id: _currentConfig?.id,
        patientId: _isPatient
            ? _user!.patientId!
            : int.parse(_selectedPatientId ?? '-1'),
        isEnabled: _isEnabled,
        permitCaregiverAccess: _permitCaregiverAccess,
        triggerKeywords: keywordList,
      );
      // Use NotetakerConfigService to update config
      final savedConfig = await NotetakerConfigService.saveUserNotetakerConfig(
        config,
        userId: _user!.id,
      );

      if (savedConfig != null) {
        setState(() => _currentConfig = savedConfig);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Notetaker configuration saved successfully!',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        throw Exception('Failed to save configuration');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildNotesSection(ThemeData theme) {
    return new Container();
  }

  Widget _buildPatientSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Select patient',
      Icons.person, // Changed from Icons.psychology for better compatibility
      [
        DropdownButtonFormField<String>(
          value: _selectedPatientId,
          decoration: InputDecoration(labelText: 'Select an option'),
          items: _patientList
              .map(
                (patient) => DropdownMenuItem(
                  value: patient['id'],
                  child: Text(patient['name']!),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedPatientId = value!;
            });
            _fetchPatientData(int.parse(_selectedPatientId!));
          },
          validator: (value) {
            if (value == null) {
              return 'Please select an option';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primaryContainer, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

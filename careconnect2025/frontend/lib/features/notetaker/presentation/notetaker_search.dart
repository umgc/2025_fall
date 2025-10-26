import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/features/notetaker/models/patient_note_model.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/notetaker_config_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../streaming_asr_with_diarization/streaming_asr_and_diarization.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/utils/task_utils.dart';

class NotetakerSearchPage extends StatefulWidget {
  const NotetakerSearchPage({super.key});

  @override
  State<NotetakerSearchPage> createState() => _NotetakerSearchPageState();
}

class _NotetakerSearchPageState extends State<NotetakerSearchPage> {
  List<PatientNote>? _currentPatientNotes;
  bool _isLoading = true;
  UserSession? _user;
  List<Map<String, String>> _patientList = [];
  String? _selectedPatientId;
  bool _isPatient = false;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<PatientNote> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    if (user == null) {
      Future.microtask(() => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notetaker Assistant')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildConfigForm(),
    );
  }

  Widget _buildConfigForm() {
    final theme = Theme.of(context);
    List<Widget> childWidgets = [];
    final successText =
        'View, Edit, and Delete your Notes from Notetaker Assistant.';
    final failureText = 'Error fetching Medical Notetaker Notes.';
    if (_isPatient) {
      childWidgets = [
        _buildInfoCard(theme, successText),
        const SizedBox(height: 24),
        _buildDiarizationCard(theme),
        const SizedBox(height: 24),
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
        _buildDiarizationCard(theme),
        const SizedBox(height: 24),
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
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final patientNotes = await NotetakerConfigService.getPatientNotes(
        patientId,
      );
      if (mounted) {
        List<PatientNote> sortedNotes = List.from(patientNotes);
        sortedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _currentPatientNotes = patientNotes;
          _filteredNotes = sortedNotes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load Patient\'s Notetaker notes: $e'),
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
      } else {
        setState(() {
          _selectedPatientId = _user!.patientId.toString();
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
        setState(() => _isLoading = false);
      }
    } finally {
      if (_isPatient) {
        if (_user?.patientId != null) {
          await _fetchPatientData(_user!.patientId!);
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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

  void _filterNotes() {
    if (_currentPatientNotes == null) {
      _filteredNotes = [];
      return;
    }

    List<PatientNote> notes = List.from(_currentPatientNotes!);

    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      notes = notes.where((note) {
        return note.aiSummary.toLowerCase().contains(searchText);
      }).toList();
    }

    if (_startDate != null) {
      final startDate = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      notes = notes.where((note) {
        final noteDate = DateTime(
          note.createdAt.year,
          note.createdAt.month,
          note.createdAt.day,
        );
        return noteDate.isAfter(startDate.subtract(const Duration(days: 1)));
      }).toList();
    }
    if (_endDate != null) {
      final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      notes = notes.where((note) {
        final noteDate = DateTime(
          note.createdAt.year,
          note.createdAt.month,
          note.createdAt.day,
        );
        return noteDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredNotes = notes;
    });
  }

  void _onNoteSelected(PatientNote note) async {
    // Navigate to detail view with note
    final result = await context.push(
      '/notetaker/detail/${note.id}',
      extra: note,
    );
    if (result == true) {
      await _fetchPatientData(int.parse(_selectedPatientId!));
    }
  }

  Widget _buildNotesSection(ThemeData theme) {
    return _buildSection(theme, 'Patient Notes', Icons.note, [
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search notes',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => _filterNotes(),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                  _filterNotes();
                }
              },
              icon: Icon(Icons.calendar_today),
              label: Text(
                _startDate != null
                    ? 'Start: ${_startDate!.toString().split(' ')[0]}'
                    : 'Start Date',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                  _filterNotes();
                }
              },
              icon: Icon(Icons.calendar_today),
              label: Text(
                _endDate != null
                    ? 'End: ${_endDate!.toString().split(' ')[0]}'
                    : 'End Date',
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _searchController.clear();
              });
              _filterNotes();
            },
            icon: Icon(Icons.clear),
            tooltip: 'Clear filters',
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Notes list
      if (_filteredNotes.isEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'No notes found',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ),
        )
      else
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _filteredNotes.length,
          itemBuilder: (context, index) {
            final note = _filteredNotes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  note.aiSummary.length > 100
                      ? '${note.aiSummary.substring(0, 100)}...'
                      : note.aiSummary,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Created: ${note.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _onNoteSelected(note),
              ),
            );
          },
        ),
    ]);
  }

  Widget _buildPatientSection(ThemeData theme) {
    return _buildSection(theme, 'Select patient', Icons.person, [
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
    ]);
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

  Future<void> checkForAITasks() async {
    final response = await ApiService.getPatientTasksV2(
      int.parse(_selectedPatientId!),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final List<Task> tasks = [];
      for (final raw in data) {
        final map = TaskUtils.normalizeTaskMap(Map<String, dynamic>.from(raw));

        try {
          final baseTask = Task.fromJson(map);
          baseTask.date = TaskUtils.normalizeDate(baseTask.date.toLocal());
          tasks.add(baseTask);
        } catch (e) {
          debugPrint("Error parsing task for patient $_selectedPatientId: $e");
        }
      }
      tasks.map((task) => task.createdAt).forEach(print);
      DateTime currentTime = DateTime.now();
      //check for tasks created in last 30 seconds
      Task? recentTask = tasks.firstWhereOrNull(
        (task) =>
            task.createdAt! > (currentTime.millisecondsSinceEpoch - 30000),
      );
      if (recentTask != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.smart_toy),
                SizedBox(width: 10),
                Text('AI Generated A Task From Your Notes'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      debugPrint(
        "Failed to fetch tasks for patient $_selectedPatientId: ${response.statusCode}",
      );
    }
  }

  Widget _buildDiarizationCard(ThemeData theme) {
    return _buildSection(theme, 'Record A Note', Icons.mic, [
      StreamingAsrAndDiarizationScreen(
        patientId: _selectedPatientId,
        onUploadSuccess: (note) {
          setState(() {
            _currentPatientNotes?.add(note);
            _filterNotes();
          });
          checkForAITasks();
        },
        onUploadError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      ),
    ]);
  }
}

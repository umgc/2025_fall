import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notetaker_config_service.dart';
import '../widgets/common_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:record/record.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:http/http.dart' as http;

class NotetakerConfigurationPage extends StatefulWidget {
  const NotetakerConfigurationPage({super.key});

  @override
  State<NotetakerConfigurationPage> createState() => _NotetakerConfigurationPageState();
}

class _NotetakerConfigurationPageState extends State<NotetakerConfigurationPage> {
  Widget _buildConfigForm() {
    final theme = Theme.of(context);
    List<Widget> childWidgets = [];
    final successText = 'Configure your Notetaker assistant to recognize PII, trigger words, etc and upload voice samples for speaker recognition.';
    final failureText = 'Configuration options cannot be displayed because either you have no patients or their was an error fetching them.';
    if(_isPatient) {
      childWidgets = [
        _buildInfoCard(theme, successText),
        const SizedBox(height: 24),
        _buildToggleSection(theme),
        const SizedBox(height: 24),
        _buildPIISection(theme),
        const SizedBox(height: 24),
        _buildKeywordSection(theme),
        const SizedBox(height: 24),
        _buildVoiceSampleSection(theme)
      ];
    } else if(_patientList.isEmpty) {
      childWidgets = [
        _buildInfoCard(theme, failureText),
      ];
    } else if(_selectedPatientId == null) {
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
        _buildPIISection(theme),
        const SizedBox(height: 24),
        _buildKeywordSection(theme),
        const SizedBox(height: 24),
        _buildVoiceSampleSection(theme)
      ];
    }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: childWidgets
        ),
      );
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
      appBar: AppBar(
        title: const Text('Notetaker Configuration'),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isSaving)
                ? null
                : () {
              // Discard changes and navigate back
              context.pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: (_isLoading || _isSaving)
                ? null
                : () async {
              await _saveConfiguration();
            },
            child: _isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      drawer: const CommonDrawer(currentRoute: '/ai-configuration'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildConfigForm(),
    );
  }

  List<Widget> piiToCard (List<String> piiList) {
    return piiList.map((PIIString)=>
        Card(
            child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(PIIString),
                      IconButton(
                          icon: new Icon(Icons.cancel),
                          tooltip: 'delete PII term',
                          onPressed: () {
                            setState(() {
                              _PIIList.remove(PIIString);
                              _PIIWidgetList = piiToCard(piiList);
                            });
                          }
                      )
                    ]
                )
            )
        )
    ).toList();
  }
  
  List<DataRow> generateRows() {
    List<DataRow> rowList = [];
    keyword_Event.forEach((key, value)=>
      rowList.add(DataRow(cells: [
        DataCell(Text(key)),
        DataCell(Text(value)),
        DataCell(IconButton(
          icon: Icon(Icons.delete),
          onPressed: (){
            setState(() {
              keyword_Event.remove(key);
            });
          },
        ))
      ]))
    );
    return rowList;
  }

  Widget _buildToggleCard(
      BuildContext context, {
        required String name,
        required bool value,
        required Function(bool) onChanged,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _startListening() async {
    if(await recorder.hasPermission()) {
      setState(() {
        _isListening = true;
        voiceSamplePath = null;
      });
      final File file = await File('../../assets/voice_samples/audio_sample.webm').create(recursive: true);
      print(file.path);
      await recorder.start(const RecordConfig(encoder: AudioEncoder.pcm16bits), path: file.path);
    }
  }

  void _stopListening() async{
    String? filePath = await recorder.stop();
    if(filePath != null) {
      setState(() {
        _isListening = false;
        voiceSamplePath = filePath;
      });
    }
  }

  Future<void> _saveAudioSample() async {
    //need to fill in

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice was saved')),
    );
  }

  PatientNotetakerConfigDTO? _currentConfig;
  bool _isLoading = true;
  bool _isSaving = false;
  UserSession? _user;
  final AudioRecorder recorder = AudioRecorder();
  List<Map<String, String>> _patientList = [];
  String? _selectedPatientId;
  String? voiceSamplePath;
  bool _isPatient = false;
  bool _isListening = false;
  bool _isEnabled = true;
  bool _permitCaregiverAccess = false;
  List<String>_PIIList = [];
  late List<Widget> _PIIWidgetList = piiToCard(_PIIList);
  Map<String, String> keyword_Event = {};

    // Form controllers
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _PIIController = TextEditingController();
  String? _selectedDropdownValue;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _fetchConfig(int patientId) async {
    try {
      final config = await NotetakerConfigService.getUserNotetakerConfig(patientId, context);
      if (config != null) {
        setState(() {
          _currentConfig = config;
          _isEnabled = config.isEnabled;
          _permitCaregiverAccess = config.permitCaregiverAccess;
          _PIIList = config.triggerKeywords.where((trigger)=> trigger.keyword.contains("PII_"))
              .map((trigger)=> trigger.keyword.replaceAll("PII_", "")).toList();
          keyword_Event = {};
          config.triggerKeywords.where((trigger)=> !trigger.keyword.contains("PII_")).forEach((trigger)=>
          keyword_Event[trigger.keyword] = trigger.event_type
          );
          _PIIWidgetList = piiToCard(_PIIList);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load Notetaker configuration: $e'),
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

  Future<void> _loadConfiguration() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        _user = userProvider.user;
        if (_user == null) throw Exception('User not found');
        final userRole = _user!.role;
        _isPatient = userRole.toUpperCase() == 'PATIENT';
      });
      if(!_isPatient && _user!.caregiverId != null) {
        http.Response patientResponse = await ApiService.getCaregiverPatients(_user!.caregiverId!);
        setState(() {
          _patientList = (jsonDecode(patientResponse.body) as List<dynamic>).map((patientWLink)=> {
            'id': patientWLink['patient']['id'].toString(),
            'name': '${patientWLink['patient']['firstName']} ${patientWLink['patient']['lastName']}'
          }).toList();
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

    if(_isPatient) {
      _fetchConfig(_user!.patientId!);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);
    try {
      if (_user == null) throw Exception('User not found');
      List<PatientNotetakerKeyword> keywordList = [];
      _PIIList.forEach((pii)=>keywordList.add(PatientNotetakerKeyword(keyword:'PII_$pii', event_type: 'ALERT')));
      keyword_Event.forEach((keyword,event)=>keywordList.add(PatientNotetakerKeyword(keyword:keyword, event_type: event)));
      final config = PatientNotetakerConfigDTO(
        id: _currentConfig?.id,
        patientId: _isPatient ? _user!.patientId! : int.parse(_selectedPatientId ?? '-1'),
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
              content: const Text('Notetaker configuration saved successfully!'),
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
                .map((patient) => DropdownMenuItem(
              value: patient['id'],
              child: Text(patient['name']!),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPatientId = value!;
              });
              _fetchConfig(int.parse(_selectedPatientId!));
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an option';
              }
              return null;
            },
          ),
        ]
    );
  }

  Widget _buildToggleSection(ThemeData theme) {
    return _buildSection(
        theme,
        'Enable Usage/Access',
        Icons.person, // Changed from Icons.psychology for better compatibility
        [
          _buildToggleCard(context, name: 'Enable Notetaker Assistant', value: _isEnabled, onChanged: (value)=>{setState(() {
            _isEnabled = !_isEnabled;
          })}),
          SizedBox(height: 16),
          _buildToggleCard(context, name: 'Enable Caregiver Access', value: _permitCaregiverAccess, onChanged: (value)=>{setState(() {
            _permitCaregiverAccess = !_permitCaregiverAccess;
          })})
        ]
    );
  }

  Widget _buildPIISection(ThemeData theme) {
    return _buildSection(
      theme,
      'PII terms',
      Icons.warning,
      [
        SizedBox(
            height: 250,
            child: ListView.builder(
              itemCount: _PIIWidgetList.length,
              itemBuilder: (context, index) {
                return _PIIWidgetList[index];
              },
            )),
        TextButton.icon(
            onPressed: () {
              _PIIController.clear();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Expanded(
                    child: SimpleDialog(
                        title: Text("Add a PII term"),
                        children: <Widget> [
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: _PIIController,
                              decoration: InputDecoration(labelText: 'Enter text'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                          SimpleDialogOption(
                            onPressed: () {
                              setState(() {
                                _PIIList.add(_PIIController.text);
                                _PIIWidgetList = piiToCard(_PIIList);
                              });
                              Navigator.of(context).pop();
                              },
                            child:const Text('Add'),
                          )
                        ]
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.add, size: 24),
            label: Text('Add PII'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            )
        ),
      ],
    );
  }

  Widget _buildKeywordSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Keywords',
      Icons.key,
      [
        SizedBox(
          height: 250,
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child:
                      DataTable(
                        columnSpacing: 16.0,
                        columns: [
                          DataColumn(label: Expanded(child: Text("Keyword"))),
                          DataColumn(label: Expanded(child: Text("Event Type"))),
                          DataColumn(label: Expanded(child: Text("")))
                        ],
                        rows: generateRows()
                      )
                )
            );
          })
        ),
        SizedBox(height: 16,),
        TextButton.icon(
            onPressed: () {
              _keywordController.clear();
              _selectedDropdownValue = null;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Expanded(
                    child: SimpleDialog(
                        title: Text("Add a keyword"),
                        children: <Widget> [
                          Padding(
                          padding: EdgeInsets.all(10.0),
                          child:
                            TextFormField(
                              controller: _keywordController,
                              decoration: InputDecoration(labelText: 'Enter text'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required';
                                }
                                return null;
                              },
                            )
                          ),
                          SizedBox(width: 12),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<String>(
                              value: _selectedDropdownValue,
                              decoration: InputDecoration(labelText: 'Select an option'),
                              items: ['ALERT', 'TASK']
                                  .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDropdownValue = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an option';
                                }
                                return null;
                              },
                            ),
                          ),
                          SimpleDialogOption(
                            onPressed: () {
                              setState(() {
                                if(_selectedDropdownValue != null) {
                                  keyword_Event[_keywordController.text] = _selectedDropdownValue as String;
                                }
                              });
                              Navigator.of(context).pop();
                              },
                            child:const Text('Add'),
                          )
                        ]
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.add, size: 24),
            label: Text('Add Keyword'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            )
        ),
      ],
    );
  }

  Widget _buildVoiceSampleSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Upload Voice Sample',
      Icons.voice_chat,
      [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme
                  .of(context)
                  .dividerColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Theme
                .of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.1),
          ),
          child: Column(
            children: [
              Icon(Icons.construction, color: theme.colorScheme.primary, size: 48),
              const SizedBox(width: 12),
              Text(
                'Under Construction',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Text('Tap the button below to start voice recognition and read the following message: \n' +
              //       'The dog fetches the ball',
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(fontSize: 14),
              // ),
              // const SizedBox(height: 16),
              // ElevatedButton(
              //   onPressed: () {
              //     if (_isListening) {
              //       _stopListening();
              //     } else {
              //       _startListening();
              //     }
              //   },
              //   child: Text(
              //       _isListening ? 'Stop Listening' : 'Start Listening'),
              // ),
              // const SizedBox(height: 8),
              // ElevatedButton(
              //   onPressed: _saveAudioSample,
              //   child: const Text('Save Voice'),
              // ),
            ],
          ),
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
}
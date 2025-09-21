import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NotetakerConfigurationPage extends StatefulWidget {
  const NotetakerConfigurationPage({super.key});

  @override
  State<NotetakerConfigurationPage> createState() => _NotetakerConfigurationPageState();
}

class _NotetakerConfigurationPageState extends State<NotetakerConfigurationPage> {
  Widget _buildConfigForm() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(theme),
          const SizedBox(height: 24),
          _buildPIISection(theme),
          const SizedBox(height: 24),
          _buildKeywordSection(theme),
          const SizedBox(height: 24),
          _buildVoiceSampleSection(theme)
        ],
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

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _saveRecognizedText() async {
    if (_recognizedText
        .trim()
        .isEmpty) {
      return;
    }

    print(_recognizedText);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice was saved')),
    );
  }

  bool _isLoading = true;
  bool _isSaving = false;
  String _recognizedText = '';
  bool _isListening = false;
  late stt.SpeechToText _speech = stt.SpeechToText();
  List<String> _PIIList = ['Hello', 'World', 'Dart', 'Flutter'];
  late List<Widget> _PIIWidgetList = piiToCard(_PIIList);
  Map<String, String> keyword_Event = {
    'keyword1': 'event1',
    'keyword2': 'event2'
  };
  
  // Form controllers
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _PIIController = TextEditingController();
  String? _selectedDropdownValue;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      //
      //}final config = await AIConfigService.getUserAIConfig(context);
    // if (config != null) {
    //   setState(() {
    //     _currentConfig = config;
    //     _contextMemoryEnabled = config.contextMemoryEnabled;
    //     _medicalContextEnabled = config.medicalContextEnabled;
    //     _emergencyDetection = config.emergencyAlertsEnabled;
    //     _maxTokens = config.maxTokensPerSession;
    //     _temperature = config.temperature;
    //     _language = config.language;
    //
    //     // Map enabled features to UI switches (ensure keys match backend DTO)
    //     _voiceEnabled = config.enabledFeatures.contains('general_chat');
    //     _emotionalSupport = config.enabledFeatures.contains(
    //       'mental_health_support',
    //     );
    //     _medicationReminders = config.enabledFeatures.contains(
    //       'medication_reminders',
    //     );
    //   });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load AI configuration: $e'),
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

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) throw Exception('User not found');

      // Build enabled features list from current UI state (use backend keys)
      List<String> enabledFeatures = [];
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

  // ...existing code...

  Widget _buildInfoCard(ThemeData theme) {
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
              'Configure your Notetaker assistant to recognize PII, trigger words, etc and upload voice samples for speaker recognition.',
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

  Widget _buildPIISection(ThemeData theme) {
    return _buildSection(
      theme,
      'Personality',
      Icons.person, // Changed from Icons.psychology for better compatibility
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
      Icons.android, // Changed from Icons.smart_toy for better compatibility
      [
        SizedBox(
          height: 250,
          child: LayoutBuilder(builder: (context, constraints) {
            double spacing = constraints.maxWidth/3;
            return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                    columnSpacing: spacing,
                    columns: [
                      DataColumn(label: Text("Keyword")),
                      DataColumn(label: Text("Event Type")),
                      DataColumn(label: Text(""))
                    ],
                    rows: generateRows()
                )
            );
          })
        ),
        SizedBox(height: 16,),
        TextButton.icon(
            onPressed: () {
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
                              items: ['Option 1', 'Option 2', 'Option 3']
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
      Icons.android, // Changed from Icons.smart_toy for better compatibility
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
              Text(
                _recognizedText.isNotEmpty
                    ? 'Recognized Text:\n$_recognizedText'
                    : 'Tap the button below to start voice recognition and read the following message: \n' +
                    'The dog fetches the ball',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                child: Text(
                    _isListening ? 'Stop Listening' : 'Start Listening'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _recognizedText.isNotEmpty
                    ? _saveRecognizedText
                    : null,
                child: const Text('Save Voice'),
              ),
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
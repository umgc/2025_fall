import 'package:flutter/material.dart';
import 'package:editable/editable.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; 
import 'dart:html' as html; 

import 'send_essay_to_moodle.dart'; // Import for JSON encoding

class EssayEditPage extends StatefulWidget {
  final String jsonData;
  final String description;
  
  EssayEditPage(this.jsonData, this.description);
  
  @override
  EssayEditPageState createState() => EssayEditPageState(); // Public State class
}

class EssayEditPageState extends State<EssayEditPage> {
  // Checks is weights sum to 100
  bool _weightsValid = true;

  // Convert JSON to rows compatible with Editable
  List rows = [];

  // Headers or Columns
  List headers = [];

  @override
  void initState() {
    super.initState();
    
    populateHeadersAndRows();
  }

  // Function to dynamically populate headers and rows based on JSON data
  void populateHeadersAndRows() {
    // Decode the JSON string into a Map
    Map<String, dynamic> mappedData = jsonDecode(widget.jsonData);

    // Step 1: Build headers dynamically based on the number of levels in the first criterion
    List<dynamic> levels = List<dynamic>.from(mappedData['criteria']?[0]['levels'] ?? []);

    // Define the headers for the Editable table
    headers = [
      {"title": 'Criteria', 'index': 1, 'key': 'name', 'widthFactor': 0.25}, // Criteria column
      {"title": 'Weight', 'index': 2, 'key': 'weight', 'widthFactor': 0.1},  // Weight column
    ];

    // Add columns for each score level dynamically
    for (int i = 0; i < levels.length; i++) {
      headers.add({
        "title": '${levels[i]['score']}',        // Column title is the score
        'index': i + 3,                          // Start after Criteria and Weight columns
        'key': 'level_$i',                        // Key for Editable row mapping
        'widthFactor': 0.65 / levels.length,     // Width evenly divided among levels
      });
    }

    // Step 2: Build rows by mapping each criterion and its levels dynamically
    rows = (mappedData['criteria'] ?? []).map((criterion) {
      Map<String, dynamic> row = {
        "name": criterion['description'],         // Criteria description
        "weight": criterion['weight'].toString(), // Weight as string to make it editable
      };

      for (int i = 0; i < (criterion['levels'] as List).length; i++) {
        row['level_$i'] = (criterion['levels'] as List)[i]['definition'];
      }

      return row;
    }).toList();

    setState(() {}); // Ensure the UI is updated after populating headers and rows
  }

  /// Create a Key for EditableState
  final _editableKey = GlobalKey<EditableState>(); 

  /// Merge edits into the original jsonData and return updated JSON
  String getUpdatedJson() {
    List editedRows = _editableKey.currentState!.editedRows;
    Map<String, dynamic> mappedData = jsonDecode(widget.jsonData);

    int totalWeight = 0;

    // Apply the edits to the original jsonData
    for (var editedRow in editedRows) {
      int rowIndex = editedRow['row'];
      var originalCriterion = mappedData['criteria']?[rowIndex];

      // Update weight column if changed
      if (editedRow.containsKey('weight')) {
        // Parse as int, fallback to 0
        int newWeight = int.tryParse(editedRow['weight']) ?? 0;
        (originalCriterion as Map<String, dynamic>)['weight'] = newWeight;
      }

      // For each edited level, update the corresponding level in the original data
      editedRow.forEach((key, value) {
        if (key != 'row' && key.startsWith('level_')) {
          int levelIndex = int.parse(key.split('_')[1]);
          (originalCriterion as Map<String, dynamic>)['levels']?[levelIndex]['definition'] = value;
        }
      });

      totalWeight += (originalCriterion['weight'] ?? 0) as int;
    }

    // Validate total weight
    setState(() {
      _weightsValid = totalWeight == 100;
    });

    // Convert the updated jsonData back to the required format and return it
    Map<String, dynamic> updatedData = {
      "criteria": mappedData['criteria']
    };
    return jsonEncode(updatedData); // Return the JSON as a string
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(title: 'Edit Essay Rubric', userprofileurl: LmsFactory.getLmsService().profileImage ?? '',),
    body: LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the top-left
          children: [
            SizedBox(height: 24.0),
            
            // Expanded is used for the Editable, wrapped with SingleChildScrollView for horizontal scrolling
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Allow horizontal scrolling for the Editable
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 600, // Ensure the table never shrinks below 600px
                    maxWidth: constraints.maxWidth > 600 ? constraints.maxWidth : 600,
                  ),
                  child: Editable(
                    key: _editableKey,
                    tdEditableMaxLines: 1,
                    trHeight: 100,
                    columns: headers,
                    rows: rows,
                    showCreateButton: false,
                    tdStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    showSaveIcon: false,
                    borderColor: Theme.of(context).colorScheme.primaryContainer,

                    // Trigger live validation whenever a cell is edited
                    onSubmitted: (value) {
                      final editedRows = _editableKey.currentState?.editedRows ?? [];

                      for (var editedRow in editedRows) {
                        int rowIndex = editedRow['row'];
                        if (editedRow.containsKey('weight')) {
                          // Update the rows list with the latest weight
                          double weight = double.tryParse(editedRow['weight'].toString()) ?? 0;
                          rows[rowIndex]['weight'] = weight.toString();
                        }
                      }
                      // Recalculate total weight and enable/disable buttons
                      _validateWeights();
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20), // Add some spacing between the Editable and the button
            
            // Row for Send to Moodle and Export buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center all buttons
              children: [
                // Send to Moodle button
                ElevatedButton(
                  child: const Text('Send to Moodle'),
                  onPressed: _weightsValid
                      ? () {
                          String updatedJson = getUpdatedJson();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EssayAssignmentSettings(
                                  updatedJson, widget.description),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data sent to Moodle')));
                        }
                      : null, // Disabled if weights invalid
                ),
                const SizedBox(width: 12),

                // Export PDF
                ElevatedButton.icon(
                  onPressed: _weightsValid
                      ? () {
                          final updatedRubric = jsonDecode(getUpdatedJson());
                          exportPdf(updatedRubric, 'rubric.pdf');
                        }
                      : null, // Disabled if weights invalid
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("Export PDF"),
                ),
                const SizedBox(width: 12),

                // Export Excel
                ElevatedButton.icon(
                  onPressed: _weightsValid
                      ? () {
                          final updatedRubric = jsonDecode(getUpdatedJson());
                          exportExcel(updatedRubric, 'rubric.xlsx');
                        }
                      : null, // Disabled if weights invalid
                  icon: Icon(Icons.table_chart),
                  label: Text("Export Excel"),
                ),
              ],
            ),
            SizedBox(height: 20), // Optional additional spacing
          ],
        );
      },
    ),
  );
}

// PDF Export Feature
Future<void> exportPdf(dynamic rubricData, String fileName) async {
  try {
    final pdf = pw.Document();
    final criteria = rubricData['criteria'] as List<dynamic>;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rubric',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              for (var c in criteria) ...[
                pw.Text('${c['description']} (Weight: ${c['weight']}%)',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                for (var level in c['levels'])
                  pw.Text('${level['score']}: ${level['definition']}'),
                pw.SizedBox(height: 12),
              ]
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    // Web Export Donwload
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    print('Error exporting PDF: $e');
  }
}

// Excel Export Feature
Future<void> exportExcel(dynamic rubricData, String fileName) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    final criteria = rubricData['criteria'] as List<dynamic>;

    // Header
    final header = ['Criteria', 'Weight'];
    if (criteria.isNotEmpty) {
      for (var level in criteria[0]['levels']) {
        header.add(level['score'].toString());
      }
    }
    sheet.appendRow(header);
    // Data 
    for (var c in criteria) {
      final row = [c['description'], c['weight']];
      for (var level in c['levels']) {
        row.add(level['definition']);
      }
      sheet.appendRow(row);
    }
    final excelBytes = excel.encode()!;
    // Web Export Download
    final blob = html.Blob([excelBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    print('Error exporting Excel: $e');
  }
}

// Calculate the total weight and update _weightsValid
void _validateWeights() {
  double total = 0;

  // Loop through each row and parse the weight safely as double
  for (var row in rows) {
    double weight = double.tryParse(row['weight'].toString()) ?? 0;
    total += weight;
  }

  // Update the state to enable/disable buttons live
  setState(() {
    _weightsValid = total == 100;
  });
}

}
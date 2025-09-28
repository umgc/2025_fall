import 'package:flutter/material.dart';
import 'package:editable/editable.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:html' as html;

import 'send_essay_to_moodle.dart'; // Import for JSON encoding

class EssayEditPage extends StatefulWidget {
  final String jsonData;
  final String description;

  EssayEditPage(this.jsonData, this.description);

  @override
  EssayEditPageState createState() =>
      EssayEditPageState(); // Public State class
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
    List<dynamic> levels =
        List<dynamic>.from(mappedData['criteria']?[0]['levels'] ?? []);

    // Define the headers for the Editable table
    headers = [
      {
        "title": 'Criteria',
        'index': 1,
        'key': 'name',
        'widthFactor': 0.25
      }, // Criteria column
      {
        "title": 'Weight',
        'index': 2,
        'key': 'weight',
        'widthFactor': 0.1
      }, // Weight column
    ];

    // Add columns for each score level dynamically
    for (int i = 0; i < levels.length; i++) {
      headers.add({
        "title": '${levels[i]['score']}', // Column title is the score
        'index': i + 3, // Start after Criteria and Weight columns
        'key': 'level_$i', // Key for Editable row mapping
        'widthFactor':
            0.65 / levels.length, // Width evenly divided among levels
      });
    }

    // Step 2: Build rows by mapping each criterion and its levels dynamically
    rows = (mappedData['criteria'] ?? []).map((criterion) {
      Map<String, dynamic> row = {
        "name": criterion['description'], // Criteria description
        "weight": criterion['weight']
            .toString(), // Weight as string to make it editable
      };

      for (int i = 0; i < (criterion['levels'] as List).length; i++) {
        row['level_$i'] = (criterion['levels'] as List)[i]['definition'];
      }

      return row;
    }).toList();

    setState(
        () {}); // Ensure the UI is updated after populating headers and rows
  }

  /// Create a Key for EditableState
  final _editableKey = GlobalKey<EditableState>();

  /// Get the current JSON from Editable safely
  String getUpdatedJson() {
    final editableState = _editableKey.currentState;
    final updatedRows = List<Map<String, dynamic>>.from(rows);

    // Merge edited rows safely
    if (editableState != null) {
      for (var editedRow in editableState.editedRows) {
        int rowIndex = editedRow['row'];
        Map<String, dynamic> safeRow =
            Map<String, dynamic>.from(updatedRows[rowIndex]);

        editedRow.forEach((key, value) {
          if (key != 'row') {
            safeRow[key] = value ?? '';
          }
        });

        updatedRows[rowIndex] = safeRow;
      }
    }

    // Update JSON safely
    Map<String, dynamic> mappedData = jsonDecode(widget.jsonData);
    final criteriaList = mappedData['criteria'] as List<dynamic>;

    for (int i = 0; i < updatedRows.length; i++) {
      final row = updatedRows[i];
      final criterion = criteriaList[i];

      // Safe weight parsing
      final weightValue = row['weight'];
      int weightInt = 0;
      if (weightValue is int) {
        weightInt = weightValue;
      } else if (weightValue is double) {
        weightInt = weightValue.toInt();
      } else if (weightValue is String) {
        weightInt = double.tryParse(weightValue)?.toInt() ?? 0;
      }
      criterion['weight'] = weightInt;

      // Update level definitions safely
      for (int j = 0; j < (criterion['levels'] as List).length; j++) {
        final def = row['level_$j'];
        criterion['levels'][j]['definition'] = def?.toString() ?? '';
      }
    }

    return jsonEncode(mappedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Essay Rubric',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.0),

              // Editable table with horizontal scrolling
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 600,
                      maxWidth: constraints.maxWidth > 600
                          ? constraints.maxWidth
                          : 600,
                    ),
                    child: Editable(
                      key: _editableKey,
                      tdEditableMaxLines: 100,
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
                      borderColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: const Text('Send to Moodle'),
                    onPressed: () => _handleButtonClick(action: () {
                      String updatedJson = getUpdatedJson();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EssayAssignmentSettings(
                              updatedJson, widget.description),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data sent to Moodle')),
                      );
                    }),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleButtonClick(action: () {
                      final updatedRubric = jsonDecode(getUpdatedJson());
                      exportPdf(updatedRubric, 'rubric.pdf');
                    }),
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text("Export PDF"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleButtonClick(action: () {
                      final updatedRubric = jsonDecode(getUpdatedJson());
                      exportExcel(updatedRubric, 'rubric.xlsx');
                    }),
                    icon: Icon(Icons.table_chart),
                    label: Text("Export Excel"),
                  ),
                ],
              ),

              SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  void _handleButtonClick({required VoidCallback action}) {
    final editableState = _editableKey.currentState;
    if (editableState == null) return;

    // Use the currently displayed rows from Editable
    final allRows = List<Map<String, dynamic>>.from(rows);

    // Merge any edits
    for (var editedRow in editableState.editedRows) {
      int rowIndex = editedRow['row'];
      Map<String, dynamic> safeRow =
          Map<String, dynamic>.from(allRows[rowIndex]);

      editedRow.forEach((key, value) {
        if (key != 'row') {
          safeRow[key] = value ?? '';
        }
      });

      allRows[rowIndex] = safeRow;
    }

    double total = 0;

    // Validate each weight first
    for (int i = 0; i < allRows.length; i++) {
      final weightValue = allRows[i]['weight'];
      double? weightDouble;

      if (weightValue == null ||
          (weightValue is String && weightValue.trim().isEmpty)) {
        weightDouble = null;
      } else if (weightValue is int) {
        weightDouble = weightValue.toDouble();
      } else if (weightValue is double) {
        weightDouble = weightValue;
      } else if (weightValue is String) {
        weightDouble = double.tryParse(weightValue);
      }

      if (weightDouble == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Invalid weight in row ${i + 1}: "$weightValue". Please enter a number.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      total += weightDouble;
    }

    // Validate total weight
    if (total != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total weight must sum to 100%. Current sum: $total%'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update JSON safely
    Map<String, dynamic> mappedData = jsonDecode(widget.jsonData);
    final criteriaList = mappedData['criteria'] as List<dynamic>;

    for (int i = 0; i < allRows.length; i++) {
      final row = allRows[i];
      final criterion = criteriaList[i];

      // Update weight safely
      final weightValue = row['weight'];
      int weightInt = 0;
      if (weightValue is int) {
        weightInt = weightValue;
      } else if (weightValue is double) {
        weightInt = weightValue.toInt();
      } else if (weightValue is String) {
        weightInt = double.tryParse(weightValue)?.toInt() ?? 0;
      }
      criterion['weight'] = weightInt;

      // Update levels
      for (int j = 0; j < (criterion['levels'] as List).length; j++) {
        final def = row['level_$j'];
        criterion['levels'][j]['definition'] = def?.toString() ?? '';
      }
    }

    // Update the main rows so Editable stays in sync
    rows = List<Map<String, dynamic>>.from(allRows);

    setState(() {}); // Refresh UI

    // Perform the requested action (PDF/Excel/Moodle)
    action();
  }

  Future<void> exportPdf(dynamic rubricData, String fileName) async {
    final pdf = pw.Document();
    final criteria = rubricData['criteria'] as List<dynamic>;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rubric',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Criteria',
                  'Weight',
                  for (var level in criteria[0]['levels'])
                    level['score'].toString()
                ],
                data: [
                  for (var c in criteria)
                    [
                      c['description'],
                      c['weight'].toString(),
                      for (var level in c['levels']) level['definition']
                    ]
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.topLeft,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                border: pw.TableBorder.all(color: PdfColors.grey),
                columnWidths: {
                  0: pw.FlexColumnWidth(2.8),
                  1: pw.FlexColumnWidth(1.8),
                  for (int i = 2; i < (criteria[0]['levels'].length + 2); i++)
                    i: pw.FlexColumnWidth(2),
                },
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Excel Export Feature
  Future<void> exportExcel(dynamic rubricData, String fileName) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];
      final criteria = rubricData['criteria'] as List<dynamic>;

      final header = ['Criteria', 'Weight'];
      if (criteria.isNotEmpty) {
        for (var level in criteria[0]['levels']) {
          header.add(level['score'].toString());
        }
      }
      sheet.appendRow(header);

      for (var c in criteria) {
        final row = [c['description'], c['weight']];
        for (var level in c['levels']) {
          row.add(level['definition']);
        }
        sheet.appendRow(row);
      }

      final excelBytes = excel.encode()!;
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
}

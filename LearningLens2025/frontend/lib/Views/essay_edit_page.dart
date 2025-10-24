import 'package:flutter/material.dart';
import 'package:editable/editable.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:learninglens_app/stub/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;

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
  // Convert JSON to rows compatible with Editable
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> headers = [];
  List<TextEditingController> headerControllers = [];

  final _editableKey = GlobalKey<EditableState>();

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
    List<dynamic> criteria = List<dynamic>.from(mappedData['criteria'] ?? []);
    if (criteria.isEmpty) return;

    List<dynamic> levels = List<dynamic>.from(criteria[0]['levels'] ?? []);

    // Initialize controllers for score headers
    headerControllers = levels
        .map((level) => TextEditingController(
            text: level['score'].toString().replaceAll('%', '').trim()))
        .toList();

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
      String sanitizedScore =
          levels[i]['score'].toString().replaceAll('%', '').trim();
      headers.add({
        "title": sanitizedScore.isEmpty ? '' : '$sanitizedScore%',
        'index': i + 3,
        'key': 'level_$i',
        'widthFactor': 0.65 / levels.length,
      });
    }

    // Step 2: Build rows by mapping each criterion and its levels dynamically
    rows = criteria.map<Map<String, dynamic>>((criterion) {
      Map<String, dynamic> row = {
        "name": criterion['description'].toString(),
        "weight": criterion['weight'].toString(),
      };
      List<dynamic> lvl = List<dynamic>.from(criterion['levels'] ?? []);
      for (int i = 0; i < lvl.length; i++) {
        row['level_$i'] = lvl[i]['definition'].toString();
      }

      return row;
    }).toList();

    setState(
        () {}); // Ensure the UI is updated after populating headers and rows
  }

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
        criterion['levels'][j]['score'] =
            headerControllers[j].text.replaceAll('%', '').trim();
      }
    }

    return jsonEncode(mappedData);
  }

  // Build the aligned score header row above percent columns
  Widget buildScoreHeaderRow(double totalWidth) {
    double criteriaWeightWidth = totalWidth * 0.25 + totalWidth * 0.1;
    double scoreColumnWidth =
        (totalWidth - criteriaWeightWidth) / headerControllers.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "Percentage Levels:" label
          Container(
            width: criteriaWeightWidth,
            padding: EdgeInsets.only(left: 16.0),
            child: Text(
              'Percentage Levels:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Editable scores aligned above percent columns
          ...headerControllers.map((controller) {
            int index = headerControllers.indexOf(controller);
            bool isLocked = index == 0 || index == headerControllers.length - 1;

            return Container(
              width: scoreColumnWidth - 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 40,
              child: TextField(
                controller: controller,
                enabled: !isLocked,
                readOnly: isLocked,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: isLocked ? null : 'Score',
                  filled: isLocked,
                  fillColor: isLocked ? Colors.grey.shade200 : null,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey.shade600 : Colors.black,
                ),
                onChanged: isLocked
                    ? null
                    : (_) {
                        String sanitizedText =
                            controller.text.replaceAll('%', '').trim();
                        setState(() {
                          headers[index + 2]['title'] =
                              sanitizedText.isEmpty ? '' : '$sanitizedText%';
                        });
                      },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Essay Rubric',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        double totalWidth =
            constraints.maxWidth > 600 ? constraints.maxWidth : 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            buildScoreHeaderRow(totalWidth),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minWidth: 600, maxWidth: totalWidth),
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
                    borderColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: Text('Send to Moodle'),
                  onPressed: () => _handleButtonClick(() {
                    String updatedJson = getUpdatedJson();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EssayAssignmentSettings(
                            updatedJson, widget.description),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data sent to Moodle')),
                    );
                  }),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _handleButtonClick(() {
                    // Force Editable to commit any ongoing edits
                    FocusScope.of(context).unfocus();

                    // Wait a moment for state update to finish
                    Future.delayed(Duration(milliseconds: 200), () {
                      final updatedJson = getUpdatedJson();
                      final updatedRubric = jsonDecode(updatedJson);

                      if (updatedRubric['criteria'] == null ||
                          (updatedRubric['criteria'] as List).isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('No rubric data available to export')),
                        );
                        return;
                      }

                      exportPdf(updatedRubric, 'rubric.pdf');
                    });
                  }),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("Export PDF"),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _handleButtonClick(() {
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
      }),
    );
  }

  void _handleButtonClick(VoidCallback action) {
    final editableState = _editableKey.currentState;
    if (editableState == null) return;

    // Merge current rows with edits
    final allRows = List<Map<String, dynamic>>.from(rows);
    for (var editedRow in editableState.editedRows) {
      int rowIndex = editedRow['row'];
      Map<String, dynamic> safeRow =
          Map<String, dynamic>.from(allRows[rowIndex]);

      editedRow.forEach((key, value) {
        if (key != 'row') safeRow[key] = value ?? '';
      });

      allRows[rowIndex] = safeRow;
    }

    // Step 1: Validate headerControllers
    for (int i = 0; i < headerControllers.length; i++) {
      final text = headerControllers[i].text.trim();

      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Percentage level ${i + 1} cannot be blank.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final value = double.tryParse(text);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Invalid percentage value in level ${i + 1}: "$text".'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (headerControllers
              .where((element) => element.text.trim() == text)
              .length >
          1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Score level $text% is not unique.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (value > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Percentage in level ${i + 1} exceeds 100%. Please enter a valid value.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Check overall order
      List<double> scores = headerControllers
          .map((c) => double.tryParse(c.text.trim()) ?? -1)
          .toList();

      // First and last values remain at 0 and 100
      if (scores.first != 0 || scores.last != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('First level must be 0% and last level must be 100%.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ascending order check
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] <= scores[i - 1]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Percentage levels must increase from left to right (0% to 100%).',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Validate each weight first
    double total = 0;
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

      if (weightDouble < 0 || weightDouble > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Weight in row ${i + 1} must be between 0 and 100. Found $weightDouble%.'),
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
          content: Text('Total weight must sum to 100%. Current sum: $total%.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 3: Moving onwards
    rows = List<Map<String, dynamic>>.from(allRows);

    setState(() {}); // Refresh UI

    // Perform the requested action (PDF/Excel/Moodle)
    action();
  }

  Future<void> exportPdf(dynamic rubricData, String fileName) async {
    final pdf = pw.Document();
    final criteria = rubricData['criteria'] as List<dynamic>;

    if (criteria.isEmpty) {
      // Safety check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No criteria found to export')),
      );
      return;
    }

    // Extract headers dynamically from first criterion
    final levels = List<dynamic>.from(criteria[0]['levels'] ?? []);
    final scoreHeaders = levels.map((l) => '${l['score']}%').toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return [
            pw.Text('Rubric',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Criteria', 'Weight', ...scoreHeaders],
              data: [
                for (var c in criteria)
                  [
                    c['description'] ?? '',
                    c['weight'].toString(),
                    for (var level in List<dynamic>.from(c['levels'] ?? []))
                      level['definition'] ?? ''
                  ]
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(fontSize: 12),
              cellAlignment: pw.Alignment.topLeft,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: pw.FlexColumnWidth(1.7),
                1: pw.FlexColumnWidth(1),
                for (int i = 2; i < scoreHeaders.length + 2; i++)
                  i: pw.FlexColumnWidth(1),
              },
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Excel Export Feature
  Future<void> exportExcel(dynamic rubricData, String fileName) async {
    try {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Rubric');
      final sheet = excel['Rubric'];
      final criteria = rubricData['criteria'] as List<dynamic>;

      if (criteria.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No criteria found to export')),
        );
        return;
      }

      // Extract headers dynamically from first criterion
      final levels = List<dynamic>.from(criteria[0]['levels'] ?? []);
      final scoreHeaders = levels.map((l) => '${l['score']}%').toList();

      // Write header row
      final headerRow = [
        TextCellValue('Criteria'),
        TextCellValue('Weight'),
        ...scoreHeaders.map((e) => TextCellValue(e))
      ];
      sheet.appendRow(headerRow);

      // Write data rows
      for (var c in criteria) {
        final row = [
          TextCellValue(c['description'] ?? ''),
          TextCellValue(c['weight'].toString()),
          for (var level in List<dynamic>.from(c['levels'] ?? []))
            TextCellValue(level['definition'] ?? '')
        ];
        sheet.appendRow(row);
      }

      // Encode Excel file
      final excelBytes = excel.encode()!;
      final blob = html.Blob([excelBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..download = fileName
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error exporting Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting Excel: $e')),
      );
    }
  }
}

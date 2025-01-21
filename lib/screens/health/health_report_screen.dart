import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:cross_file/cross_file.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final Set<String> _selectedMetrics = {};
  bool _isLoading = false;
  final String _reportText = 'Generating report, please wait...';
  Uint8List? _pdfBytes;
  String? _userName;

  final List<String> _availableMetrics = [
    'Blood Pressure',
    'Blood Sugar',
    'Heart Rate',
    'Weight',
    'Temperature',
    'Medications',
    'Appointments',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    setState(() {
      _userName = userDoc.data()?['fullName'] ?? 'User';
    });
  }

  Future<void> _generateReport() async {
    if (_selectedMetrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one metric')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting report generation');
      print('Selected metrics: $_selectedMetrics');
      final pdf = pw.Document();

      // Fetch all metric data first
      final allMetricData = <String, List<Map<String, dynamic>>>{};
      for (final metric in _selectedMetrics) {
        print('Fetching data for metric: $metric');
        final data = await _fetchMetricData(metric);
        print('Fetched ${data.length} records for $metric');
        print(
            'Sample data for $metric: ${data.isNotEmpty ? data.first : "no data"}');
        allMetricData[metric] = data;
      }

      // Check if we have any data
      final hasData = allMetricData.values.any((list) => list.isNotEmpty);
      if (!hasData) {
        print('No data found for any selected metrics');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data found for the selected date range'),
            ),
          );
        }
        return;
      }

      print('Building PDF document');
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${_userName!.toUpperCase()}\'S HEALTH REPORT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Date Range: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                ),
                pw.SizedBox(height: 20),
              ],
            ),

            // Each metric in sequence
            ..._selectedMetrics.map((metric) {
              print('Processing metric for PDF: $metric');
              final metricData = allMetricData[metric] ?? [];
              print('Data length for $metric: ${metricData.length}');

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(height: 2, borderStyle: pw.BorderStyle.dashed),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    metric.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  if (metricData.isEmpty)
                    pw.Text('No data available for this metric')
                  else if (metric == 'Blood Sugar')
                    _buildBloodSugarTable(metricData)
                  else if (metric == 'Blood Pressure')
                    _buildBloodPressureTable(metricData)
                  else if (metric == 'Medications')
                    _buildMedicationTable(metricData)
                  else
                    _buildGenericTable(metric, metricData),
                  pw.SizedBox(height: 30),
                ],
              );
            }).toList(),
          ],
        ),
      );

      _pdfBytes = await pdf.save();
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFScreen(pdfBytes: _pdfBytes!),
          ),
        );
      }
    } catch (e) {
      print('Error generating PDF: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMetricData(String metric) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    print('Fetching data for metric: $metric, userId: $userId');

    if (metric == 'Medications') {
      final snapshot = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: userId)
          .get();

      print('Raw documents fetched for $metric: ${snapshot.docs.length}');

      final processedData = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing document for $metric: ${doc.id}');
        print('Document data: $data');
        return {...data, 'id': doc.id};
      }).toList();

      print('Final processed data count for $metric: ${processedData.length}');
      return processedData;
    }

    if (metric == 'Appointments') {
      try {
        print('Fetching appointments with userId: $userId');

        // Query appointments within the date range
        final snapshot = await _firestore
            .collection('healthcare_appointments')
            .where('userId', isEqualTo: userId)
            .where('appointmentDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
            .where('appointmentDate',
                isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
            .orderBy('appointmentDate', descending: false)
            .get();

        print('Found ${snapshot.docs.length} appointments in date range');

        if (snapshot.docs.isEmpty) {
          print('No appointments found in the date range');
          return [];
        }

        final processedData = snapshot.docs
            .map((doc) {
              final data = doc.data();
              print('Processing appointment document: ${doc.id}');
              print('Raw appointment data: $data');

              try {
                final appointmentDate = data['appointmentDate'] as Timestamp;
                final appointmentData = {
                  'id': doc.id,
                  'dateTime': appointmentDate.toDate(),
                  'title': data['title'] ?? 'N/A',
                  'provider': data['provider'] ?? 'N/A',
                  'location': data['location'] ?? 'N/A',
                  'notes': data['notes'] ?? '',
                  'speciality': data['speciality'] ?? 'N/A'
                };
                print('Successfully processed appointment: $appointmentData');
                return appointmentData;
              } catch (e) {
                print('Error processing appointment data: $e');
                return null;
              }
            })
            .where((data) => data != null)
            .cast<Map<String, dynamic>>()
            .toList();

        print('Final processed appointments: ${processedData.length}');
        if (processedData.isNotEmpty) {
          print('Sample appointment: ${processedData.first}');
        }

        return processedData;
      } catch (e) {
        print('Error fetching appointments: $e');
        return [];
      }
    }

    final snapshot = await _firestore
        .collection('health_metrics')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: metric)
        .get();

    print('Raw documents fetched for $metric: ${snapshot.docs.length}');

    final processedData = snapshot.docs
        .map((doc) {
          final data = doc.data();
          print('Processing document for $metric: ${doc.id}');
          print('Document data: $data');

          try {
            final timestamp = _parseTimestamp(data['timestamp']);
            print('Parsed timestamp: $timestamp');

            if (timestamp
                    .isAfter(_startDate.subtract(const Duration(days: 1))) &&
                timestamp.isBefore(_endDate.add(const Duration(days: 1)))) {
              print('Document is within date range');
              final processedDoc = {
                ...data,
                'id': doc.id,
                'parsedDate': timestamp
              };
              print('Processed document: $processedDoc');
              return processedDoc;
            } else {
              print(
                  'Document outside date range: $timestamp not in ${_startDate} - ${_endDate}');
            }
          } catch (e) {
            print('Error processing document ${doc.id} for $metric: $e');
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    print('Final processed data count for $metric: ${processedData.length}');
    return processedData;
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    throw FormatException('Unable to parse timestamp: $timestamp');
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  pw.Widget _buildBloodSugarTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Date & Time'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('mg/dL'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('mmol/L'),
            ),
          ],
        ),
        ...data.map((item) {
          final dateStr = DateFormat('MMM d, yyyy h:mm a')
              .format(item['parsedDate'] as DateTime);
          final value = double.tryParse(item['value']?.toString() ?? '') ?? 0.0;

          double mgdL;
          double mmolL;

          if (value > 10) {
            // Input is likely in mg/dL, convert to mmol/L
            mgdL = value;
            mmolL = value / 18;
          } else {
            // Input is likely in mmol/L, convert to mg/dL
            mmolL = value;
            mgdL = value * 18;
          }

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(dateStr),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${mgdL.toStringAsFixed(0)}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(mmolL.toStringAsFixed(1)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildBloodPressureTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Date & Time'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Systolic'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Diastolic'),
            ),
          ],
        ),
        ...data.map((item) {
          final dateStr = DateFormat('MMM d, yyyy h:mm a')
              .format(item['parsedDate'] as DateTime);
          final systolic = item['systolic']?.toString() ?? 'N/A';
          final diastolic = item['diastolic']?.toString() ?? 'N/A';
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(dateStr),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(systolic),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(diastolic),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildMedicationTable(List<Map<String, dynamic>> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Current Medications',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Medication name
            1: const pw.FlexColumnWidth(1.5), // Dosage
            2: const pw.FlexColumnWidth(1.5), // Frequency
            3: const pw.FlexColumnWidth(3), // Instructions
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Medication'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Dosage'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Frequency'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Instructions'),
                ),
              ],
            ),
            ...data.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(item['name']?.toString() ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(item['dosage']?.toString() ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(item['frequency']?.toString() ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(item['instructions']?.toString() ?? 'N/A'),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAppointmentTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Healthcare Appointments',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('No appointments found for the selected period.'),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Healthcare Appointments',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5), // Date & Time
            1: const pw.FlexColumnWidth(1.5), // Title
            2: const pw.FlexColumnWidth(1.5), // Doctor
            3: const pw.FlexColumnWidth(1.5), // Location
            4: const pw.FlexColumnWidth(2), // Description
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              children: [
                _buildTableHeader('Date & Time'),
                _buildTableHeader('Title'),
                _buildTableHeader('Doctor'),
                _buildTableHeader('Location'),
                _buildTableHeader('Description'),
              ],
            ),
            ...data.map((item) {
              final dateTime = item['dateTime'] as DateTime;
              final dateStr = DateFormat('MMM d, yyyy h:mm a').format(dateTime);
              return pw.TableRow(
                children: [
                  _buildTableCell(dateStr),
                  _buildTableCell(item['title'] ?? 'N/A'),
                  _buildTableCell(item['provider'] ?? 'N/A'),
                  _buildTableCell(item['location'] ?? 'N/A'),
                  _buildTableCell(item['notes'] ?? ''),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text),
    );
  }

  pw.Widget _buildGenericTable(String metric, List<Map<String, dynamic>> data) {
    print('Building generic table for $metric with ${data.length} records');
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Date & Time'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Value'),
            ),
          ],
        ),
        ...data.map((item) {
          print('Processing item for table: $item');
          final dateStr = DateFormat('MMM d, yyyy h:mm a')
              .format(item['parsedDate'] as DateTime);

          String valueStr;
          if (metric == 'Weight') {
            final weight = item['weight']?.toString() ?? 'N/A';
            final height = item['height']?.toString();
            valueStr = height != null
                ? '$weight kg (Height: $height cm)'
                : '$weight kg';
          } else {
            final value = item['value']?.toString() ?? 'N/A';
            final unit = item['unit']?.toString() ?? '';
            valueStr = '$value $unit';
          }

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(dateStr),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(valueStr),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Report'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Date Range',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMM d, y').format(_startDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMM d, y').format(_endDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Select Metrics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableMetrics.map((metric) {
                  final isSelected = _selectedMetrics.contains(metric);
                  return FilterChip(
                    label: Text(metric),
                    selected: isSelected,
                    onSelected: (selected) {
                      print(
                          'Metric ${selected ? "selected" : "deselected"}: $metric'); // Debug log
                      setState(() {
                        if (selected) {
                          _selectedMetrics.add(metric);
                        } else {
                          _selectedMetrics.remove(metric);
                        }
                      });
                      print(
                          'Current selected metrics: $_selectedMetrics'); // Debug log
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateReport,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PDFScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PDFScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) async => pdfBytes,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final file = XFile.fromData(
                pdfBytes,
                mimeType: 'application/pdf',
                name: 'health_report.pdf',
              );
              await Share.shareXFiles([file]);
            },
          ),
        ],
      ),
      body: pdfx.PdfView(
        controller: pdfx.PdfController(
          document: pdfx.PdfDocument.openData(pdfBytes),
        ),
      ),
    );
  }
}

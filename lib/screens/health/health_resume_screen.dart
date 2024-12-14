import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class HealthResumeScreen extends StatefulWidget {
  const HealthResumeScreen({super.key});

  @override
  State<HealthResumeScreen> createState() => _HealthResumeScreenState();
}

class _HealthResumeScreenState extends State<HealthResumeScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now(); // fallback
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final firstName = userData['firstName'] as String? ?? '';
          final lastName = userData['lastName'] as String? ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '$firstName $lastName'.trim();
          }
        }
      }
      
      // If no name is found in the users collection, try to get from auth
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser?.displayName?.isNotEmpty == true) {
        return authUser!.displayName!;
      }
      
      return 'Patient'; // Default fallback
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return 'Patient';
    }
  }

  Future<Uint8List> _generatePdf(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Uint8List(0);

    final pdf = pw.Document();
    
    try {
      // Get user name
      final userName = await _getUserName(user.uid);
      
      // Fetch health metrics within date range
      final metricsSnapshot = await FirebaseFirestore.instance
          .collection('health_metrics')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
          .orderBy('timestamp', descending: true)
          .get();

      // Group metrics by type
      final bloodPressureReadings = <Map<String, dynamic>>[];
      final bloodSugarReadings = <Map<String, dynamic>>[];
      final weightReadings = <Map<String, dynamic>>[];
      final heartRateReadings = <Map<String, dynamic>>[];

      for (var doc in metricsSnapshot.docs) {
        final data = doc.data();
        switch (data['type']) {
          case 'Blood Pressure':
            bloodPressureReadings.add(data);
            break;
          case 'Blood Sugar':
            bloodSugarReadings.add(data);
            break;
          case 'Weight':
            weightReadings.add(data);
            break;
          case 'Heart Rate':
            heartRateReadings.add(data);
            break;
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) {
              return pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                ),
              );
            },
            theme: pw.ThemeData(
              defaultTextStyle: pw.TextStyle(
                color: PdfColors.black,
              ),
            ),
          ),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      userName,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Health Data Resume',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              if (bloodPressureReadings.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Blood Pressure History',
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                  cellStyle: pw.TextStyle(
                    color: PdfColors.black,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.centerLeft,
                  },
                  data: [
                    ['Date', 'Systolic', 'Diastolic', 'Pulse', 'Category'],
                    ...bloodPressureReadings.map((data) {
                      final timestamp = _parseTimestamp(data['timestamp']);
                      final systolic = (data['systolic'] as num?)?.toInt() ?? 0;
                      final diastolic = (data['diastolic'] as num?)?.toInt() ?? 0;
                      final pulse = (data['pulse'] as num?)?.toInt() ?? 0;
                      String category = 'Normal';
                      
                      if (systolic >= 180 || diastolic >= 120) {
                        category = 'Hypertensive Crisis';
                      } else if (systolic >= 140 || diastolic >= 90) {
                        category = 'Stage 2 Hypertension';
                      } else if (systolic >= 130 || diastolic >= 80) {
                        category = 'Stage 1 Hypertension';
                      } else if (systolic >= 120 && diastolic < 80) {
                        category = 'Elevated';
                      }

                      return [
                        DateFormat('MMM d, y h:mm a').format(timestamp),
                        systolic.toString(),
                        diastolic.toString(),
                        pulse.toString(),
                        category,
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              if (bloodSugarReadings.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Blood Sugar History',
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                  cellStyle: pw.TextStyle(
                    color: PdfColors.black,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerLeft,
                  },
                  data: [
                    ['Date', 'Value (mg/dL)', 'Category'],
                    ...bloodSugarReadings.map((data) {
                      final timestamp = _parseTimestamp(data['timestamp']);
                      final value = (data['value'] as num?)?.toDouble() ?? 0.0;
                      String category = 'Normal';
                      
                      if (value < 70) {
                        category = 'Low';
                      } else if (value > 200) {
                        category = 'High';
                      } else if (value > 140) {
                        category = 'Elevated';
                      }

                      return [
                        DateFormat('MMM d, y h:mm a').format(timestamp),
                        value.toString(),
                        category,
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              if (weightReadings.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Weight History',
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                  cellStyle: pw.TextStyle(
                    color: PdfColors.black,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerLeft,
                  },
                  data: [
                    ['Date', 'Weight (kg)', 'BMI', 'Category'],
                    ...weightReadings.map((data) {
                      final timestamp = _parseTimestamp(data['timestamp']);
                      final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
                      final height = (data['height'] as num?)?.toDouble() ?? 1.0;
                      final bmi = weight / (height * height);
                      String category = 'Normal';
                      
                      if (bmi < 18.5) {
                        category = 'Underweight';
                      } else if (bmi < 25) {
                        category = 'Normal';
                      } else if (bmi < 30) {
                        category = 'Overweight';
                      } else {
                        category = 'Obese';
                      }

                      return [
                        DateFormat('MMM d, y').format(timestamp),
                        weight.toStringAsFixed(1),
                        bmi.toStringAsFixed(1),
                        category,
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              if (heartRateReadings.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Heart Rate History',
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                  cellStyle: pw.TextStyle(
                    color: PdfColors.black,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerLeft,
                  },
                  data: [
                    ['Date', 'BPM', 'Category'],
                    ...heartRateReadings.map((data) {
                      final timestamp = _parseTimestamp(data['timestamp']);
                      final value = (data['value'] as num?)?.toInt() ?? 0;
                      String category = 'Normal';
                      
                      if (value < 60) {
                        category = 'Bradycardia';
                      } else if (value > 100) {
                        category = 'Tachycardia';
                      }

                      return [
                        DateFormat('MMM d, y h:mm a').format(timestamp),
                        value.toString(),
                        category,
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on ${DateFormat('MMMM d, y').format(DateTime.now())} at ${DateFormat('h:mm a').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Resume'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date Range:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                TextButton(
                  onPressed: _selectDateRange,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(context),
              allowPrinting: false,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: 'health_resume_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
              previewPageMargin: const EdgeInsets.all(10),
              scrollViewDecoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              actions: const [],
              loadingWidget: const Center(
                child: CircularProgressIndicator(),
              ),
              initialPageFormat: PdfPageFormat.a4,
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
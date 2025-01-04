import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
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
  bool _isGenerating = false;
  String _reportText = '';

  final List<String> _availableMetrics = [
    'Blood Pressure',
    'Blood Sugar',
    'Heart Rate',
    'Weight',
    'Temperature',
    'Oxygen Level',
  ];

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

  Future<void> _generateReport() async {
    if (_selectedMetrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one metric'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _reportText = '';
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get user's name from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['fullName'] ?? 'User';

      // Build report header
      final StringBuffer report = StringBuffer();
      report.writeln('${userName.toUpperCase()}\'S HEALTH REPORT');
      report.writeln('=' * 100);
      report.writeln(
          'Date Range: ${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}');
      report.writeln('=' * 100);
      report.writeln();

      // Fetch and format data for each metric
      for (final metric in _selectedMetrics) {
        final snapshot = await _firestore
            .collection('health_metrics')
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: metric)
            .get();

        final data = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .where((data) {
          DateTime? date;
          try {
            final timestamp = data['timestamp'];
            if (timestamp is Timestamp) {
              date = timestamp.toDate();
            } else if (timestamp is int) {
              date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            } else {
              final timestampInt = int.tryParse(timestamp.toString());
              if (timestampInt != null) {
                date = DateTime.fromMillisecondsSinceEpoch(timestampInt);
              }
            }

            if (date == null || date.isAfter(DateTime.now())) {
              return false;
            }

            return date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                date.isBefore(_endDate.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList()
          ..sort((a, b) {
            DateTime? getDate(dynamic timestamp) {
              try {
                if (timestamp is Timestamp) {
                  return timestamp.toDate();
                } else if (timestamp is int) {
                  return DateTime.fromMillisecondsSinceEpoch(timestamp);
                } else {
                  final timestampInt = int.tryParse(timestamp.toString());
                  if (timestampInt != null) {
                    return DateTime.fromMillisecondsSinceEpoch(timestampInt);
                  }
                }
              } catch (e) {
                return null;
              }
              return null;
            }

            final aDate = getDate(a['timestamp']);
            final bDate = getDate(b['timestamp']);

            if (aDate == null || bDate == null) return 0;
            return aDate.compareTo(bDate);
          });

        if (data.isNotEmpty) {
          report.writeln(metric.toUpperCase());
          report.writeln('-' * 100);

          // Write table header with clear column separation
          if (metric == 'Blood Pressure') {
            report.writeln(
                '| ${_padCenter('Date & Time', 22)} | ${_padCenter('Systolic/Diastolic', 18)} | ${_padCenter('Pulse', 10)} | ${_padCenter('Notes', 40)} |');
            report.writeln('|${'-' * 24}|${'-' * 20}|${'-' * 12}|${'-' * 42}|');
          } else if (metric == 'Blood Sugar') {
            report.writeln(
                '| ${_padCenter('Date & Time', 22)} | ${_padCenter('mg/dL', 10)} | ${_padCenter('mmol/L', 10)} | ${_padCenter('Notes', 48)} |');
            report.writeln('|${'-' * 24}|${'-' * 12}|${'-' * 12}|${'-' * 50}|');
          } else {
            report.writeln(
                '| ${_padCenter('Date & Time', 22)} | ${_padCenter('Value', 18)} | ${_padCenter('Notes', 50)} |');
            report.writeln('|${'-' * 24}|${'-' * 20}|${'-' * 52}|');
          }

          for (final item in data) {
            final timestamp = item['timestamp'];
            DateTime? date;
            try {
              if (timestamp is Timestamp) {
                date = timestamp.toDate();
              } else if (timestamp is int) {
                date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              } else {
                final timestampInt = int.tryParse(timestamp.toString());
                if (timestampInt != null) {
                  date = DateTime.fromMillisecondsSinceEpoch(timestampInt);
                }
              }

              if (date == null || date.isAfter(DateTime.now())) {
                continue;
              }
            } catch (e) {
              continue;
            }

            final dateStr = DateFormat('MMM d, yyyy h:mm a').format(date);
            String formattedLine = '';

            if (metric == 'Blood Pressure') {
              final systolicDiastolic =
                  '${item['systolic']}/${item['diastolic']} mmHg';
              final pulse = '${item['pulse']} bpm';
              final notes = item['notes'] ?? '';
              formattedLine =
                  '| ${_padRight(dateStr, 22)} | ${_padRight(systolicDiastolic, 18)} | ${_padRight(pulse, 10)} | ${_padRight(notes, 40)} |';
            } else if (metric == 'Blood Sugar') {
              final value = item['value'] as num;
              String mgdL, mmolL;

              // If value > 10, it's likely in mg/dL
              if (value > 10) {
                mgdL = value.round().toString();
                mmolL = (value / 18).toStringAsFixed(1);
              } else {
                // Value is in mmol/L
                mmolL = value.toString();
                mgdL = (value * 18).round().toString();
              }

              final notes = item['notes'] ?? '';
              final mealTime = item['mealTime']?.toString() ?? '';
              final mealTimeStr =
                  mealTime.trim().isNotEmpty ? '($mealTime) ' : '';
              formattedLine =
                  '| ${_padRight(dateStr, 22)} | ${_padRight(mgdL, 10)} | ${_padRight(mmolL, 10)} | ${_padRight(mealTimeStr + notes, 48)} |';
            } else if (metric == 'Weight') {
              final weightText = '${item['weight']} kg';
              final heightText =
                  item['height'] != null ? ' (H: ${item['height']} m)' : '';
              final notes = item['notes'] ?? '';
              formattedLine =
                  '| ${_padRight(dateStr, 22)} | ${_padRight(weightText + heightText, 18)} | ${_padRight(notes, 50)} |';
            } else if (metric == 'Heart Rate') {
              final valueText = '${item['value']} bpm';
              final notes = item['notes'] ?? '';
              formattedLine =
                  '| ${_padRight(dateStr, 22)} | ${_padRight(valueText, 18)} | ${_padRight(notes, 50)} |';
            } else {
              final valueText = '${item['value']} ${item['unit']}';
              final notes = item['notes'] ?? '';
              formattedLine =
                  '| ${_padRight(dateStr, 22)} | ${_padRight(valueText, 18)} | ${_padRight(notes, 50)} |';
            }

            report.writeln(formattedLine);
          }

          // Add bottom border to table
          if (metric == 'Blood Pressure') {
            report.writeln('|${'-' * 24}|${'-' * 20}|${'-' * 12}|${'-' * 42}|');
          } else if (metric == 'Blood Sugar') {
            report.writeln('|${'-' * 24}|${'-' * 12}|${'-' * 12}|${'-' * 50}|');
          } else {
            report.writeln('|${'-' * 24}|${'-' * 20}|${'-' * 52}|');
          }
          report.writeln();
        }
      }

      setState(() {
        _reportText = report.toString();
        _isGenerating = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isGenerating = false);
    }
  }

  // Helper methods for text padding
  String _padRight(String text, int width) {
    if (text.length > width) {
      return text.substring(0, width);
    }
    return text.padRight(width);
  }

  String _padCenter(String text, int width) {
    if (text.length > width) {
      return text.substring(0, width);
    }
    final padding = width - text.length;
    final leftPad = padding ~/ 2;
    final rightPad = padding - leftPad;
    return ' ' * leftPad + text + ' ' * rightPad;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Report'),
        actions: [
          if (_reportText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                // TODO: Implement printing functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Printing not implemented yet')),
                );
              },
            ),
          if (_reportText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Share.share(_reportText, subject: 'Health Report');
              },
            ),
        ],
      ),
      body: Padding(
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
                    setState(() {
                      if (selected) {
                        _selectedMetrics.add(metric);
                      } else {
                        _selectedMetrics.remove(metric);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Generate Report'),
            ),
            const SizedBox(height: 16),
            if (_reportText.isNotEmpty) ...[
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _reportText,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

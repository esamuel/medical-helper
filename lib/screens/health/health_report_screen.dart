import 'package:flutter/material.dart' hide TableRow;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> _healthData = {};
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final Set<String> _selectedMetrics = {};
  String? _userName;
  Uint8List? _pdfBytes;

  final List<String> _availableMetrics = [
    'Blood Pressure',
    'Blood Sugar',
    'Heart Rate',
    'Weight',
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
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    setState(() {
      _userName = userDoc.data()?['fullName'] ?? 'User';
    });
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    debugPrint('Warning: Invalid timestamp format: $timestamp');
    return DateTime.now();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('health_metrics')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final data = <String, List<Map<String, dynamic>>>{
        'Blood Pressure': [],
        'Blood Sugar': [],
        'Heart Rate': [],
        'Weight': [],
      };

      for (var doc in snapshot.docs) {
        try {
          final metric = doc.data();
          final type = metric['type'] as String;
          if (data.containsKey(type)) {
            final timestamp = _parseTimestamp(metric['timestamp']);
            // Only include data within the selected date range
            if (timestamp
                    .isAfter(_startDate.subtract(const Duration(days: 1))) &&
                timestamp.isBefore(_endDate.add(const Duration(days: 1)))) {
              data[type]!.add({
                ...metric,
                'id': doc.id,
                'timestamp': timestamp,
              });
            }
          }
        } catch (e) {
          debugPrint('Error processing document ${doc.id}: $e');
        }
      }

      setState(() {
        _healthData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading health data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_selectedMetrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one metric')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _loadHealthData(); // Load data for selected date range
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
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
                ..._buildPdfContent(),
              ],
            ),
          ],
        ),
      );

      _pdfBytes = await pdf.save();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFScreen(pdfBytes: _pdfBytes!),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<pw.Widget> _buildPdfContent() {
    final List<pw.Widget> content = [];

    for (final metric in _selectedMetrics) {
      content.add(pw.Header(
        level: 0,
        child: pw.Text(metric),
      ));

      // Add chart image if available
      if (_healthData.containsKey(metric) && _healthData[metric]!.isNotEmpty) {
        content.add(_buildPdfChart(metric));
      }

      // Add metric data table
      content.add(_buildMetricTable(metric));
      content.add(pw.SizedBox(height: 20));
    }

    return content;
  }

  pw.Widget _buildPdfChart(String metric) {
    // Implementation for PDF chart will be added here
    return pw.Container(
      height: 200,
      child: pw.Center(
        child: pw.Text('Chart will be added here'),
      ),
    );
  }

  Widget _buildHealthChart(String type) {
    final data = _healthData[type] ?? [];
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No $type data available'),
        ),
      );
    }

    // Extract values based on metric type
    List<double> values = [];
    List<DateTime> dates = [];

    for (var item in data) {
      try {
        final timestamp = item['timestamp'] as DateTime;
        dates.add(timestamp);

        if (type == 'Blood Sugar') {
          final originalValue = (item['value'] as num).toDouble();
          // Always convert to mg/dL for the chart
          final mgdl =
              _normalizeToMgdl(originalValue, item['unit']?.toString());
          values.add(mgdl);
        } else if (type == 'Blood Pressure') {
          values.add((item['systolic'] as num).toDouble());
        } else if (type == 'Weight') {
          values.add((item['weight'] as num).toDouble());
        } else if (type == 'Heart Rate') {
          values.add((item['value'] as num).toDouble());
        }
      } catch (e) {
        debugPrint('Error processing data point: $e');
      }
    }

    if (values.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No valid $type data available'),
        ),
      );
    }

    final color = _getColorForMetric(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _calculateInterval(values),
                    verticalInterval: 1,
                    checkToShowHorizontalLine: (value) =>
                        value <= values.reduce((a, b) => a > b ? a : b),
                    checkToShowVerticalLine: (value) =>
                        value <= values.length - 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd')
                                    .format(dates[value.toInt()]),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: type == 'Blood Sugar'
                          ? const Text('mg/dL', style: TextStyle(fontSize: 10))
                          : null,
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateInterval(values),
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: (values.length - 1).toDouble(),
                  minY: _calculateMinY(values),
                  maxY: _calculateMaxY(values),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(values.length, (index) {
                        return FlSpot(index.toDouble(), values[index]);
                      }),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatistics(values, type),
            const SizedBox(height: 16),
            _buildDataTable(type, data),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(String type, List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _getColumnsForType(type),
        rows: _getRowsForType(type, data),
      ),
    );
  }

  List<DataColumn> _getColumnsForType(String type) {
    switch (type) {
      case 'Blood Pressure':
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('Systolic')),
          const DataColumn(label: Text('Diastolic')),
          const DataColumn(label: Text('Pulse')),
        ];
      case 'Blood Sugar':
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('mg/dL')),
          const DataColumn(label: Text('mmol/L')),
          const DataColumn(label: Text('Meal Time')),
        ];
      case 'Weight':
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('Weight (kg)')),
        ];
      case 'Heart Rate':
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('BPM')),
        ];
      default:
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('Value')),
        ];
    }
  }

  List<DataRow> _getRowsForType(String type, List<Map<String, dynamic>> data) {
    return data.map((item) {
      final date = DateFormat('MMM d, yyyy').format(item['timestamp']);
      final time = DateFormat('h:mm a').format(item['timestamp']);

      switch (type) {
        case 'Blood Pressure':
          return DataRow(cells: [
            DataCell(Text(date)),
            DataCell(Text(time)),
            DataCell(Text(item['systolic'].toString())),
            DataCell(Text(item['diastolic'].toString())),
            DataCell(Text(item['pulse'].toString())),
          ]);
        case 'Blood Sugar':
          final originalValue = (item['value'] as num).toDouble();
          final mgdl =
              _normalizeToMgdl(originalValue, item['unit']?.toString());
          final mmol =
              _normalizeToMmol(originalValue, item['unit']?.toString());

          return DataRow(cells: [
            DataCell(Text(date)),
            DataCell(Text(time)),
            DataCell(Text('${mgdl.toStringAsFixed(0)} mg/dL')),
            DataCell(Text('${mmol.toStringAsFixed(1)} mmol/L')),
            DataCell(Text(item['mealTime'].toString())),
          ]);
        case 'Weight':
          return DataRow(cells: [
            DataCell(Text(date)),
            DataCell(Text(time)),
            DataCell(Text('${item['weight']} kg')),
          ]);
        case 'Heart Rate':
          return DataRow(cells: [
            DataCell(Text(date)),
            DataCell(Text(time)),
            DataCell(Text('${item['value']} bpm')),
          ]);
        default:
          return DataRow(cells: [
            DataCell(Text(date)),
            DataCell(Text(time)),
            DataCell(Text(item['value'].toString())),
          ]);
      }
    }).toList();
  }

  pw.Widget _buildMetricTable(String metric) {
    final data = _healthData[metric] ?? [];
    if (data.isEmpty) {
      return pw.Text('No data available for this period');
    }

    switch (metric) {
      case 'Blood Pressure':
        return _buildBloodPressureTable(data);
      case 'Blood Sugar':
        return _buildBloodSugarTable(data);
      case 'Weight':
        return _buildGenericTable(metric, data);
      case 'Heart Rate':
        return _buildGenericTable(metric, data);
      default:
        return pw.Container();
    }
  }

  pw.Widget _buildBloodPressureTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Pulse'),
            ),
          ],
        ),
        ...data.map((item) {
          final dateStr =
              DateFormat('MMM d, y h:mm a').format(item['timestamp']);
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(dateStr),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['systolic'].toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['diastolic'].toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['pulse'].toString()),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildBloodSugarTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Meal Time'),
            ),
          ],
        ),
        ...data.map((item) {
          final dateStr =
              DateFormat('MMM d, y h:mm a').format(item['timestamp']);
          final originalValue = (item['value'] as num).toDouble();
          final mgdl =
              _normalizeToMgdl(originalValue, item['unit']?.toString());
          final mmol =
              _normalizeToMmol(originalValue, item['unit']?.toString());

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(dateStr),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${mgdl.toStringAsFixed(0)} mg/dL'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${mmol.toStringAsFixed(1)} mmol/L'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['mealTime'].toString()),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildGenericTable(String metric, List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
          final dateStr =
              DateFormat('MMM d, y h:mm a').format(item['timestamp']);
          final value = metric == 'Weight' ? item['weight'] : item['value'];
          final unit = metric == 'Weight' ? 'kg' : 'bpm';
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(dateStr),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('$value $unit'),
              ),
            ],
          );
        }).toList(),
      ],
    );
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
      _loadHealthData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Report'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(16),
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
                      _loadHealthData();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              if (_selectedMetrics.isNotEmpty) ...[
                for (final metric in _selectedMetrics)
                  if (_healthData.containsKey(metric)) ...[
                    _buildHealthChart(metric),
                    const SizedBox(height: 24),
                  ],
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _generateReport,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate PDF Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForMetric(String metric) {
    switch (metric) {
      case 'Blood Pressure':
        return Colors.red;
      case 'Blood Sugar':
        return Colors.orange;
      case 'Heart Rate':
        return Colors.blue;
      case 'Weight':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatistics(List<double> values, String type) {
    if (values.isEmpty) return const SizedBox.shrink();

    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    if (type == 'Blood Sugar') {
      // Values are already normalized to mg/dL in the chart data
      final mgdlAvg = average;
      final mgdlMin = min;
      final mgdlMax = max;

      final mmolAvg = _normalizeToMmol(average, null);
      final mmolMin = _normalizeToMmol(min, null);
      final mmolMax = _normalizeToMmol(max, null);

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Average', mgdlAvg, 'mg/dL'),
              _buildStatCard('Min', mgdlMin, 'mg/dL'),
              _buildStatCard('Max', mgdlMax, 'mg/dL'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Average', mmolAvg, 'mmol/L'),
              _buildStatCard('Min', mmolMin, 'mmol/L'),
              _buildStatCard('Max', mmolMax, 'mmol/L'),
            ],
          ),
        ],
      );
    }

    String unit = '';
    switch (type) {
      case 'Blood Pressure':
        unit = 'mmHg';
        break;
      case 'Weight':
        unit = 'kg';
        break;
      case 'Heart Rate':
        unit = 'bpm';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('Average', average, unit),
        _buildStatCard('Min', min, unit),
        _buildStatCard('Max', max, unit),
      ],
    );
  }

  Widget _buildStatCard(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  double _calculateInterval(List<double> values) {
    if (values.isEmpty) return 1;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max - min) / 5;
  }

  double _calculateMinY(List<double> values) {
    if (values.isEmpty) return 0;
    final min = values.reduce((a, b) => a < b ? a : b);
    return min * 0.9;
  }

  double _calculateMaxY(List<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max * 1.1;
  }

  double _normalizeToMmol(double value, String? unit) {
    if (!_isValueInMmol(value)) {
      return value / 18.018; // Convert from mg/dL to mmol/L
    }
    return value; // Already in mmol/L
  }

  double _normalizeToMgdl(double value, String? unit) {
    if (_isValueInMmol(value)) {
      return value * 18.018; // Convert from mmol/L to mg/dL
    }
    return value; // Already in mg/dL
  }

  bool _isValueInMmol(double value) {
    return value < 80 || (value <= 12 && value >= 3); // Typical mmol/L ranges
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

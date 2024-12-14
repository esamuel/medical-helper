import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

enum BloodPressureCategory {
  normal,
  elevated,
  hypertensionStage1,
  hypertensionStage2,
  hypertensiveCrisis
}

class BloodPressureReading {
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime timestamp;
  final String notes;

  BloodPressureReading({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.timestamp,
    this.notes = '',
  });

  BloodPressureCategory get category {
    if (systolic >= 180 || diastolic >= 120) {
      return BloodPressureCategory.hypertensiveCrisis;
    } else if (systolic >= 140 || diastolic >= 90) {
      return BloodPressureCategory.hypertensionStage2;
    } else if (systolic >= 130 || diastolic >= 80) {
      return BloodPressureCategory.hypertensionStage1;
    } else if (systolic >= 120 && diastolic < 80) {
      return BloodPressureCategory.elevated;
    } else {
      return BloodPressureCategory.normal;
    }
  }

  Color get categoryColor {
    switch (category) {
      case BloodPressureCategory.normal:
        return Colors.green;
      case BloodPressureCategory.elevated:
        return Colors.yellow.shade800;
      case BloodPressureCategory.hypertensionStage1:
        return Colors.orange;
      case BloodPressureCategory.hypertensionStage2:
        return Colors.red;
      case BloodPressureCategory.hypertensiveCrisis:
        return Colors.purple;
    }
  }

  String get categoryText {
    switch (category) {
      case BloodPressureCategory.normal:
        return 'Normal';
      case BloodPressureCategory.elevated:
        return 'Elevated';
      case BloodPressureCategory.hypertensionStage1:
        return 'Hypertension Stage 1';
      case BloodPressureCategory.hypertensionStage2:
        return 'Hypertension Stage 2';
      case BloodPressureCategory.hypertensiveCrisis:
        return 'Hypertensive Crisis';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory BloodPressureReading.fromMap(Map<String, dynamic> map) {
    return BloodPressureReading(
      systolic: map['systolic'] ?? 0,
      diastolic: map['diastolic'] ?? 0,
      pulse: map['pulse'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'] ?? '',
    );
  }
}

enum BloodSugarCategory {
  low,
  normal,
  preDiabetes,
  diabetes,
  high
}

enum MealTime {
  fasting,
  beforeMeal,
  afterMeal,
  bedtime
}

class BloodSugarReading {
  final double value;
  final DateTime timestamp;
  final MealTime mealTime;
  final String notes;

  BloodSugarReading({
    required this.value,
    required this.timestamp,
    required this.mealTime,
    this.notes = '',
  });

  BloodSugarCategory get category {
    switch (mealTime) {
      case MealTime.fasting:
        if (value < 70) return BloodSugarCategory.low;
        if (value < 100) return BloodSugarCategory.normal;
        if (value < 126) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
      case MealTime.beforeMeal:
        if (value < 70) return BloodSugarCategory.low;
        if (value < 100) return BloodSugarCategory.normal;
        if (value < 126) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
      case MealTime.afterMeal:
        if (value < 70) return BloodSugarCategory.low;
        if (value < 140) return BloodSugarCategory.normal;
        if (value < 200) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
      case MealTime.bedtime:
        if (value < 70) return BloodSugarCategory.low;
        if (value < 120) return BloodSugarCategory.normal;
        if (value < 140) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
    }
  }

  Color get categoryColor {
    switch (category) {
      case BloodSugarCategory.low:
        return Colors.purple;
      case BloodSugarCategory.normal:
        return Colors.green;
      case BloodSugarCategory.preDiabetes:
        return Colors.orange;
      case BloodSugarCategory.diabetes:
        return Colors.red;
      case BloodSugarCategory.high:
        return Colors.deepPurple;
    }
  }

  String get categoryText {
    switch (category) {
      case BloodSugarCategory.low:
        return 'Low';
      case BloodSugarCategory.normal:
        return 'Normal';
      case BloodSugarCategory.preDiabetes:
        return 'Pre-Diabetes';
      case BloodSugarCategory.diabetes:
        return 'Diabetes';
      case BloodSugarCategory.high:
        return 'High';
    }
  }

  String get mealTimeText {
    switch (mealTime) {
      case MealTime.fasting:
        return 'Fasting';
      case MealTime.beforeMeal:
        return 'Before Meal';
      case MealTime.afterMeal:
        return 'After Meal';
      case MealTime.bedtime:
        return 'Bedtime';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'timestamp': Timestamp.fromDate(timestamp),
      'mealTime': mealTime.index,
      'notes': notes,
    };
  }

  factory BloodSugarReading.fromMap(Map<String, dynamic> map) {
    return BloodSugarReading(
      value: (map['value'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      mealTime: MealTime.values[map['mealTime'] ?? 0],
      notes: map['notes'] ?? '',
    );
  }
}

enum BMICategory {
  underweight,
  normal,
  overweight,
  obese,
  extremelyObese
}

class WeightReading {
  final double weight;
  final double height; // in meters
  final DateTime timestamp;
  final String notes;

  WeightReading({
    required this.weight,
    required this.height,
    required this.timestamp,
    this.notes = '',
  });

  double get bmi => weight / (height * height);

  BMICategory get category {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.normal;
    if (bmi < 30) return BMICategory.overweight;
    if (bmi < 35) return BMICategory.obese;
    return BMICategory.extremelyObese;
  }

  Color get categoryColor {
    switch (category) {
      case BMICategory.underweight:
        return Colors.blue;
      case BMICategory.normal:
        return Colors.green;
      case BMICategory.overweight:
        return Colors.orange;
      case BMICategory.obese:
        return Colors.red;
      case BMICategory.extremelyObese:
        return Colors.purple;
    }
  }

  String get categoryText {
    switch (category) {
      case BMICategory.underweight:
        return 'Underweight';
      case BMICategory.normal:
        return 'Normal';
      case BMICategory.overweight:
        return 'Overweight';
      case BMICategory.obese:
        return 'Obese';
      case BMICategory.extremelyObese:
        return 'Extremely Obese';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory WeightReading.fromMap(Map<String, dynamic> map) {
    return WeightReading(
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'] ?? '',
    );
  }
}

enum HeartRateCategory {
  bradycardia,
  normal,
  elevated,
  tachycardia
}

enum ActivityType {
  resting,
  sleeping,
  lightActivity,
  moderateActivity,
  intenseActivity
}

class HeartRateReading {
  final int value;
  final DateTime timestamp;
  final ActivityType activity;
  final String notes;

  HeartRateReading({
    required this.value,
    required this.timestamp,
    required this.activity,
    this.notes = '',
  });

  HeartRateCategory get category {
    if (value < 60) return HeartRateCategory.bradycardia;
    if (value < 100) return HeartRateCategory.normal;
    if (value < 120) return HeartRateCategory.elevated;
    return HeartRateCategory.tachycardia;
  }

  Color get categoryColor {
    switch (category) {
      case HeartRateCategory.bradycardia:
        return Colors.blue;
      case HeartRateCategory.normal:
        return Colors.green;
      case HeartRateCategory.elevated:
        return Colors.orange;
      case HeartRateCategory.tachycardia:
        return Colors.red;
    }
  }

  String get categoryText {
    switch (category) {
      case HeartRateCategory.bradycardia:
        return 'Bradycardia';
      case HeartRateCategory.normal:
        return 'Normal';
      case HeartRateCategory.elevated:
        return 'Elevated';
      case HeartRateCategory.tachycardia:
        return 'Tachycardia';
    }
  }

  String get activityText {
    switch (activity) {
      case ActivityType.resting:
        return 'Resting';
      case ActivityType.sleeping:
        return 'Sleeping';
      case ActivityType.lightActivity:
        return 'Light Activity';
      case ActivityType.moderateActivity:
        return 'Moderate Activity';
      case ActivityType.intenseActivity:
        return 'Intense Activity';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'timestamp': Timestamp.fromDate(timestamp),
      'activity': activity.index,
      'notes': notes,
    };
  }

  factory HeartRateReading.fromMap(Map<String, dynamic> map) {
    return HeartRateReading(
      value: (map['value'] ?? 0).toInt(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      activity: ActivityType.values[map['activity'] ?? 0],
      notes: map['notes'] ?? '',
    );
  }
}

class HealthMetric {
  final String id;
  final String userId;
  final DateTime timestamp;
  final dynamic value; // Can be double, BloodPressureReading, BloodSugarReading, WeightReading, or HeartRateReading
  final String unit;
  final String type;
  final String notes;

  HealthMetric({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.value,
    required this.unit,
    required this.type,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> valueMap;
    if (value is BloodPressureReading) {
      valueMap = (value as BloodPressureReading).toMap();
    } else if (value is BloodSugarReading) {
      valueMap = (value as BloodSugarReading).toMap();
    } else if (value is WeightReading) {
      valueMap = (value as WeightReading).toMap();
    } else if (value is HeartRateReading) {
      valueMap = (value as HeartRateReading).toMap();
    } else {
      valueMap = {'value': value};
    }

    return {
      'id': id,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      ...valueMap,
      'unit': unit,
      'type': type,
      'notes': notes,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    final timestamp = (map['timestamp'] as Timestamp).toDate();
    dynamic value;

    if (type == 'Blood Pressure') {
      value = BloodPressureReading(
        systolic: map['systolic'] as int,
        diastolic: map['diastolic'] as int,
        pulse: map['pulse'] as int,
        timestamp: timestamp,
        notes: map['notes'] as String? ?? '',
      );
    } else if (type == 'Blood Sugar') {
      value = BloodSugarReading(
        value: (map['value'] as num).toDouble(),
        timestamp: timestamp,
        mealTime: map['mealTime'] != null 
          ? MealTime.values[map['mealTime'] as int]
          : MealTime.beforeMeal,
        notes: map['notes'] as String? ?? '',
      );
    } else if (type == 'Weight') {
      value = WeightReading(
        weight: (map['weight'] as num).toDouble(),
        height: (map['height'] as num).toDouble(),
        timestamp: timestamp,
        notes: map['notes'] as String? ?? '',
      );
    } else if (type == 'Heart Rate') {
      value = HeartRateReading(
        value: (map['value'] as num).toInt(),
        timestamp: timestamp,
        activity: map['activity'] != null 
          ? ActivityType.values[map['activity'] as int]
          : ActivityType.resting,
        notes: map['notes'] as String? ?? '',
      );
    } else {
      value = map['value'];
    }

    return HealthMetric(
      id: map['id'] as String,
      userId: map['userId'] as String,
      timestamp: timestamp,
      value: value,
      unit: map['unit'] as String,
      type: type,
      notes: map['notes'] as String? ?? '',
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Map<String, List<HealthMetric>> _healthData = {
    'Blood Pressure': [],
    'Heart Rate': [],
    'Blood Sugar': [],
    'Weight': [],
    'Temperature': [],
  };

  final _valueController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMetric = 'Blood Pressure';
  MealTime _selectedMealTime = MealTime.beforeMeal;
  double _lastHeight = 1.7; // Default height in meters
  bool _isLoading = true;
  ActivityType _selectedActivity = ActivityType.resting;

  final Map<String, String> _units = {
    'Blood Pressure': 'mmHg',
    'Heart Rate': 'bpm',
    'Blood Sugar': 'mg/dL',
    'Weight': 'kg',
    'Temperature': '°C',
  };

  final TextEditingController _heartRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHealthData();
    _loadLastHeight();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _valueController.clear();
    _systolicController.clear();
    _diastolicController.clear();
    _pulseController.clear();
    _heightController.clear();
    _notesController.clear();
    _heartRateController.clear();
  }

  Future<void> _loadLastHeight() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['height'] != null) {
          setState(() {
            _lastHeight = (data['height'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading height: $e');
    }
  }

  Future<void> _saveHeight(double height) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .set({'height': height}, SetOptions(merge: true));

      setState(() {
        _lastHeight = height;
      });
    } catch (e) {
      debugPrint('Error saving height: $e');
    }
  }

  Future<void> _loadHealthData() async {
    if (!mounted) return;
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user ID found. User might not be logged in.');
        return;
      }

      debugPrint('Loading health data for user: $userId');

      // Clear existing data
      setState(() {
        for (var key in _healthData.keys) {
          _healthData[key]?.clear();
        }
      });

      // Query all health metrics for the user
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('health_metrics')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('Found ${snapshot.docs.length} health metrics');

      // Process all documents first
      final List<HealthMetric> allMetrics = [];
      
      for (var doc in snapshot.docs) {
        try {
          debugPrint('Processing document: ${doc.id}');
          final map = doc.data();
          final type = map['type'] as String;
          dynamic value;

          // Parse timestamp
          DateTime timestamp;
          final timestampData = map['timestamp'];
          if (timestampData is Timestamp) {
            timestamp = timestampData.toDate();
          } else if (timestampData is String) {
            timestamp = DateTime.parse(timestampData);
          } else if (timestampData is int) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
          } else {
            throw Exception('Invalid timestamp format');
          }

          if (type == 'Blood Pressure') {
            value = BloodPressureReading(
              systolic: map['systolic'] as int,
              diastolic: map['diastolic'] as int,
              pulse: map['pulse'] as int,
              timestamp: timestamp,
              notes: map['notes'] as String? ?? '',
            );
          } else if (type == 'Blood Sugar') {
            value = BloodSugarReading(
              value: (map['value'] as num).toDouble(),
              timestamp: timestamp,
              mealTime: map['mealTime'] != null 
                ? MealTime.values[map['mealTime'] as int]
                : MealTime.beforeMeal,
              notes: map['notes'] as String? ?? '',
            );
          } else if (type == 'Weight') {
            value = WeightReading(
              weight: (map['weight'] as num).toDouble(),
              height: (map['height'] as num).toDouble(),
              timestamp: timestamp,
              notes: map['notes'] as String? ?? '',
            );
          } else if (type == 'Heart Rate') {
            value = HeartRateReading(
              value: (map['value'] as num).toInt(),
              timestamp: timestamp,
              activity: map['activity'] != null 
                ? ActivityType.values[map['activity'] as int]
                : ActivityType.resting,
              notes: map['notes'] as String? ?? '',
            );
          } else {
            value = map['value'];
          }

          allMetrics.add(
            HealthMetric(
              id: doc.id,
              userId: map['userId'] as String,
              timestamp: timestamp,
              value: value,
              unit: map['unit'] as String,
              type: type,
              notes: map['notes'] as String? ?? '',
            ),
          );

        } catch (e, stackTrace) {
          debugPrint('Error processing document ${doc.id}: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      // Sort metrics by timestamp (newest first)
      allMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Group sorted metrics by type
      if (mounted) {
        setState(() {
          for (var metric in allMetrics) {
            _healthData[metric.type]?.add(metric);
          }
          _isLoading = false;
        });
      }

    } catch (e, stackTrace) {
      debugPrint('Error loading health data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading health data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addHealthMetric({
    required dynamic value,
    required String unit,
    required String type,
    String notes = '',
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user ID found when trying to add health metric');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add health data'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final timestamp = DateTime.now();
      final docId = '${userId}_${timestamp.millisecondsSinceEpoch}';

      final metric = HealthMetric(
        id: docId,
        userId: userId,
        timestamp: timestamp,
        value: value,
        unit: unit,
        type: type,
        notes: notes,
      );

      final Map<String, dynamic> data = metric.toMap();
      await _firestore
          .collection('health_metrics')
          .doc(docId)
          .set(data);

      if (!mounted) return;

      setState(() {
        final metrics = _healthData[type] ?? [];
        metrics.add(metric);
        metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type data saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving health metric: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving health metric: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteHealthMetric(String metricId, int index) async {
    try {
      await _firestore.collection('health_metrics').doc(metricId).delete();
      setState(() {
        _healthData[_selectedMetric]?.removeAt(index);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health data deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting health data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHeartRateInputDialog() {
    _heartRateController.clear();
    _notesController.clear();
    _selectedActivity = ActivityType.resting;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Heart Rate Reading'),
          content: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _heartRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Heart Rate (BPM)',
                    hintText: 'Enter heart rate in beats per minute',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ActivityType>(
                  value: _selectedActivity,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    border: OutlineInputBorder(),
                  ),
                  items: ActivityType.values.map((activity) {
                    return DropdownMenuItem(
                      value: activity,
                      child: Text(activity.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivity = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any additional notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearControllers();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (_heartRateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a heart rate value'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final heartRate = int.tryParse(_heartRateController.text);
                if (heartRate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (heartRate < 30 || heartRate > 220) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a realistic heart rate (30-220 BPM)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  debugPrint('Creating new heart rate reading...');
                  final reading = HeartRateReading(
                    value: heartRate,
                    timestamp: DateTime.now(),
                    activity: _selectedActivity,
                    notes: _notesController.text.trim(),
                  );

                  _addHealthMetric(
                    value: reading,
                    unit: 'bpm',
                    type: 'Heart Rate',
                    notes: _notesController.text.trim(),
                  );

                  Navigator.pop(context);
                  _clearControllers();
                } catch (e, stackTrace) {
                  debugPrint('Error creating heart rate reading: $e');
                  debugPrint('Stack trace: $stackTrace');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving heart rate: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog() {
    if (_selectedMetric == 'Blood Pressure') {
      _showBloodPressureInputDialog();
    } else if (_selectedMetric == 'Blood Sugar') {
      _showBloodSugarInputDialog();
    } else if (_selectedMetric == 'Weight') {
      _showWeightInputDialog();
    } else if (_selectedMetric == 'Heart Rate') {
      _showHeartRateInputDialog();
    } else {
      // ... existing code for other metrics ...
    }
  }

  void _addHealthData() {
    switch (_selectedMetric) {
      case 'Blood Pressure':
        _showBloodPressureInputDialog();
        break;
      case 'Blood Sugar':
        _showBloodSugarInputDialog();
        break;
      case 'Weight':
        _showWeightInputDialog();
        break;
      case 'Heart Rate':
        _showHeartRateInputDialog();
        break;
      default:
        break;
    }
  }

  void _showBloodPressureInputDialog() {
    _systolicController.clear();
    _diastolicController.clear();
    _pulseController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Blood Pressure Reading'),
        content: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _systolicController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Systolic (mmHg)',
                  hintText: 'Enter systolic pressure',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _diastolicController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                  hintText: 'Enter diastolic pressure',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pulseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Pulse (bpm)',
                  hintText: 'Enter pulse rate',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_systolicController.text.isEmpty ||
                  _diastolicController.text.isEmpty ||
                  _pulseController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final systolic = int.tryParse(_systolicController.text);
              final diastolic = int.tryParse(_diastolicController.text);
              final pulse = int.tryParse(_pulseController.text);

              if (systolic == null || diastolic == null || pulse == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (systolic < 70 || systolic > 250 ||
                  diastolic < 40 || diastolic > 150 ||
                  pulse < 40 || pulse > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter realistic values'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final reading = BloodPressureReading(
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                timestamp: DateTime.now(),
                notes: _notesController.text.trim(),
              );

              _addHealthMetric(
                value: reading,
                unit: 'mmHg',
                type: 'Blood Pressure',
                notes: _notesController.text.trim(),
              );

              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBloodSugarInputDialog() {
    _valueController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Blood Sugar Reading'),
        content: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Blood Sugar (mg/dL)',
                  hintText: 'Enter blood sugar level',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealTime>(
                value: _selectedMealTime,
                decoration: const InputDecoration(
                  labelText: 'Meal Time',
                  border: OutlineInputBorder(),
                ),
                items: MealTime.values.map((mealTime) {
                  return DropdownMenuItem(
                    value: mealTime,
                    child: Text(mealTime.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      _selectedMealTime = value;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_valueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a blood sugar value'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final value = double.tryParse(_valueController.text);
              if (value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (value < 20 || value > 600) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a realistic blood sugar value (20-600 mg/dL)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final reading = BloodSugarReading(
                value: value,
                timestamp: DateTime.now(),
                mealTime: _selectedMealTime,
                notes: _notesController.text.trim(),
              );

              _addHealthMetric(
                value: reading,
                unit: 'mg/dL',
                type: 'Blood Sugar',
                notes: _notesController.text.trim(),
              );

              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWeightInputDialog() {
    _valueController.clear();
    _heightController.clear();
    _notesController.clear();
    _heightController.text = _lastHeight.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weight Reading'),
        content: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter your weight',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  hintText: 'Enter your height',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_valueController.text.isEmpty || _heightController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final weight = double.tryParse(_valueController.text);
              final height = double.tryParse(_heightController.text);

              if (weight == null || height == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (weight < 20 || weight > 300 || height < 0.5 || height > 2.5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter realistic values'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _saveHeight(height);

              final reading = WeightReading(
                weight: weight,
                height: height,
                timestamp: DateTime.now(),
                notes: _notesController.text.trim(),
              );

              _addHealthMetric(
                value: reading,
                unit: 'kg',
                type: 'Weight',
                notes: _notesController.text.trim(),
              );

              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: _healthData.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Data'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            isScrollable: true,
            tabs: _healthData.keys.map((String metric) {
              return Tab(text: metric);
            }).toList(),
            onTap: (index) {
              setState(() {
                _selectedMetric = _healthData.keys.elementAt(index);
              });
            },
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: _healthData.entries.map((entry) {
            final metrics = entry.value;
            return metrics.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${entry.key} data yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add data',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        if (entry.key == 'Blood Pressure') 
                          _buildBloodPressureGraph()
                        else if (entry.key == 'Blood Sugar')
                          _buildBloodSugarGraph()
                        else if (entry.key == 'Weight')
                          _buildWeightGraph()
                        else if (entry.key == 'Heart Rate')
                          _buildHeartRateGraph(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 16, bottom: 80),
                            itemCount: metrics.length,
                            itemBuilder: (context, index) {
                              final metric = metrics[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  title: metric.type == 'Blood Pressure'
                                      ? _buildBloodPressureTitle(metric.value as BloodPressureReading)
                                      : metric.type == 'Blood Sugar'
                                          ? _buildBloodSugarTitle(metric.value as BloodSugarReading)
                                          : metric.type == 'Weight'
                                              ? _buildWeightTitle(metric.value as WeightReading)
                                              : metric.type == 'Heart Rate'
                                                  ? _buildHeartRateTitle(metric.value as HeartRateReading)
                                                  : Text(
                                                      '${metric.value} ${metric.unit}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('MMM d, y - h:mm a')
                                            .format(metric.timestamp),
                                      ),
                                      if (metric.notes.isNotEmpty)
                                        Text('Notes: ${metric.notes}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteHealthMetric(metric.id, index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addHealthData,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBloodPressureTitle(BloodPressureReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${reading.systolic}/${reading.diastolic} mmHg',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reading.categoryColor.withOpacity(0.2),
                border: Border.all(color: reading.categoryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reading.categoryText,
                style: TextStyle(
                  fontSize: 12,
                  color: reading.categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Pulse: ${reading.pulse} bpm',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodPressureGraph() {
    if (_selectedMetric != 'Blood Pressure' || _healthData['Blood Pressure']?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final readings = _healthData['Blood Pressure']!
        .map((metric) => metric.value as BloodPressureReading)
        .toList(); // Show newest to oldest

    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blood Pressure Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < readings.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(readings[value.toInt()].timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Systolic line
                    LineChartBarData(
                      spots: List.generate(readings.length, (index) {
                        return FlSpot(index.toDouble(), readings[index].systolic.toDouble());
                      }),
                      isCurved: true,
                      color: Colors.red,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Diastolic line
                    LineChartBarData(
                      spots: List.generate(readings.length, (index) {
                        return FlSpot(index.toDouble(), readings[index].diastolic.toDouble());
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 40,
                  maxY: 200,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.red, label: 'Systolic'),
                SizedBox(width: 16),
                _LegendItem(color: Colors.blue, label: 'Diastolic'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarTitle(BloodSugarReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${reading.value} mg/dL',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reading.categoryColor.withOpacity(0.2),
                border: Border.all(color: reading.categoryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reading.categoryText,
                style: TextStyle(
                  fontSize: 12,
                  color: reading.categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          reading.mealTimeText,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodSugarGraph() {
    if (_selectedMetric != 'Blood Sugar' || _healthData['Blood Sugar']?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final readings = _healthData['Blood Sugar']!
        .map((metric) => metric.value as BloodSugarReading)
        .toList(); // Show newest to oldest

    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blood Sugar Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 50,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < readings.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(readings[value.toInt()].timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(readings.length, (index) {
                        return FlSpot(index.toDouble(), readings[index].value);
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: readings[index].categoryColor,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 40,
                  maxY: 300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealTime.values.map((time) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    time.toString().split('.').last,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTitle(WeightReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${reading.weight.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reading.categoryColor.withOpacity(0.2),
                border: Border.all(color: reading.categoryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'BMI: ${reading.bmi.toStringAsFixed(1)} - ${reading.categoryText}',
                style: TextStyle(
                  fontSize: 12,
                  color: reading.categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Height: ${reading.height.toStringAsFixed(2)} m',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightGraph() {
    if (_selectedMetric != 'Weight' || _healthData['Weight']?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final readings = _healthData['Weight']!
        .map((metric) => metric.value as WeightReading)
        .toList(); // Show newest to oldest

    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate min and max for better graph scaling
    final weights = readings.map((r) => r.weight).toList();
    final minWeight = weights.reduce(min);
    final maxWeight = weights.reduce(max);
    final padding = (maxWeight - minWeight) * 0.1;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight & BMI Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < readings.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(readings[value.toInt()].timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final bmi = value / (_lastHeight * _lastHeight);
                          return Text(
                            'BMI: ${bmi.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(readings.length, (index) {
                        return FlSpot(index.toDouble(), readings[index].weight);
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: readings[index].categoryColor,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: max(0, minWeight - padding),
                  maxY: maxWeight + padding,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBMILegendItem(BMICategory.underweight),
                _buildBMILegendItem(BMICategory.normal),
                _buildBMILegendItem(BMICategory.overweight),
                _buildBMILegendItem(BMICategory.obese),
                _buildBMILegendItem(BMICategory.extremelyObese),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMILegendItem(BMICategory category) {
    final reading = WeightReading(
      weight: 70,
      height: 1.7,
      timestamp: DateTime.now(),
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: reading.categoryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        reading.categoryText,
        style: TextStyle(
          fontSize: 12,
          color: reading.categoryColor,
        ),
      ),
    );
  }

  Widget _buildHeartRateTitle(HeartRateReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${reading.value} bpm',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reading.categoryColor.withOpacity(0.2),
                border: Border.all(color: reading.categoryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reading.categoryText,
                style: TextStyle(
                  fontSize: 12,
                  color: reading.categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Activity: ${reading.activityText}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHeartRateGraph() {
    if (_selectedMetric != 'Heart Rate' || _healthData['Heart Rate']?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final readings = _healthData['Heart Rate']!
        .map((metric) => metric.value as HeartRateReading)
        .toList(); // Show newest to oldest

    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate min and max for better graph scaling
    final values = readings.map((r) => r.value).toList();
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final padding = (maxValue - minValue) * 0.1;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heart Rate Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) {
                      Color color = Colors.grey.withOpacity(0.3);
                      double strokeWidth = 0.5;
                      
                      // Add reference lines for heart rate zones
                      if (value == 60) {
                        color = Colors.blue.withOpacity(0.3);
                        strokeWidth = 1;
                      } else if (value == 100) {
                        color = Colors.orange.withOpacity(0.3);
                        strokeWidth = 1;
                      } else if (value == 120) {
                        color = Colors.red.withOpacity(0.3);
                        strokeWidth = 1;
                      }
                      
                      return FlLine(
                        color: color,
                        strokeWidth: strokeWidth,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < readings.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('HH:mm').format(readings[value.toInt()].timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(readings.length, (index) {
                        return FlSpot(index.toDouble(), readings[index].value.toDouble());
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: readings[index].categoryColor,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: max(0, minValue - padding),
                  maxY: maxValue + padding,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHeartRateLegendItem(HeartRateCategory.bradycardia),
                _buildHeartRateLegendItem(HeartRateCategory.normal),
                _buildHeartRateLegendItem(HeartRateCategory.elevated),
                _buildHeartRateLegendItem(HeartRateCategory.tachycardia),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ActivityType.values.map((activity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.toString().split('.').last,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateLegendItem(HeartRateCategory category) {
    final reading = HeartRateReading(
      value: 70,
      timestamp: DateTime.now(),
      activity: ActivityType.resting,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: reading.categoryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        reading.categoryText,
        style: TextStyle(
          fontSize: 12,
          color: reading.categoryColor,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
} 
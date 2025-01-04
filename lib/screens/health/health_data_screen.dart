import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../settings/settings_screen.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import './health_report_screen.dart';

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
        return const Color(0xFF80CBC4);
      case BloodPressureCategory.elevated:
        return const Color(0xFFFFB74D);
      case BloodPressureCategory.hypertensionStage1:
        return const Color(0xFFFF9800);
      case BloodPressureCategory.hypertensionStage2:
        return const Color(0xFFF44336);
      case BloodPressureCategory.hypertensiveCrisis:
        return const Color(0xFFD32F2F);
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

enum BloodSugarCategory { low, normal, preDiabetes, diabetes, high }

enum MealTime { fasting, beforeMeal, afterMeal, bedtime }

enum BloodSugarUnit { mgdL, mmolL }

class BloodSugarReading {
  final double value;
  final DateTime timestamp;
  final MealTime mealTime;
  final String notes;
  final BloodSugarUnit unit;

  BloodSugarReading({
    required this.value,
    required this.timestamp,
    required this.mealTime,
    required this.unit,
    this.notes = '',
  });

  static double mgdLToMmolL(double mgdL) {
    return mgdL * 0.0555;
  }

  static double mmolLToMgdL(double mmolL) {
    return mmolL * 18.0182;
  }

  double get valueInMgdL {
    return unit == BloodSugarUnit.mgdL ? value : mmolLToMgdL(value);
  }

  double get valueInMmolL {
    return unit == BloodSugarUnit.mmolL ? value : mgdLToMmolL(value);
  }

  BloodSugarCategory get category {
    final mgdLValue = valueInMgdL;
    switch (mealTime) {
      case MealTime.fasting:
        if (mgdLValue < 70) return BloodSugarCategory.low;
        if (mgdLValue < 100) return BloodSugarCategory.normal;
        if (mgdLValue < 126) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
      case MealTime.beforeMeal:
        if (mgdLValue < 70) return BloodSugarCategory.low;
        if (mgdLValue < 100) return BloodSugarCategory.normal;
        if (mgdLValue < 126) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
      case MealTime.afterMeal:
        if (mgdLValue < 70) return BloodSugarCategory.low;
        if (mgdLValue < 140) return BloodSugarCategory.normal;
        if (mgdLValue < 200) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
      case MealTime.bedtime:
        if (mgdLValue < 70) return BloodSugarCategory.low;
        if (mgdLValue < 120) return BloodSugarCategory.normal;
        if (mgdLValue < 140) return BloodSugarCategory.preDiabetes;
        return BloodSugarCategory.diabetes;
    }
  }

  Color get categoryColor {
    switch (category) {
      case BloodSugarCategory.low:
        return const Color(0xFF9575CD);
      case BloodSugarCategory.normal:
        return const Color(0xFF80CBC4);
      case BloodSugarCategory.preDiabetes:
        return const Color(0xFFFF9800);
      case BloodSugarCategory.diabetes:
        return const Color(0xFFF44336);
      case BloodSugarCategory.high:
        return const Color(0xFF673AB7);
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
      'unit': unit.index,
    };
  }

  factory BloodSugarReading.fromMap(Map<String, dynamic> map) {
    debugPrint('Creating BloodSugarReading from map: $map');
    final timestamp = (map['timestamp'] as Timestamp).toDate();
    final value = (map['value'] as num).toDouble();
    final unit = map['unit'] != null
        ? BloodSugarUnit.values[map['unit']]
        : BloodSugarUnit.mgdL;
    final mealTime = map['mealTime'] != null
        ? MealTime.values[map['mealTime']]
        : MealTime.beforeMeal;

    debugPrint('Creating BloodSugarReading with data:');
    debugPrint('Value: $value');
    debugPrint('Unit: $unit');
    debugPrint('MealTime: $mealTime');

    return BloodSugarReading(
      value: value,
      timestamp: timestamp,
      mealTime: mealTime,
      unit: unit,
      notes: map['notes'] ?? '',
    );
  }
}

enum BMICategory { underweight, normal, overweight, obese, extremelyObese }

class WeightReading {
  final double weight;
  final double? height; // in meters
  final DateTime timestamp;
  final String notes;

  WeightReading({
    required this.weight,
    this.height,
    required this.timestamp,
    this.notes = '',
  });

  double? get bmi => height != null ? weight / (height! * height!) : null;

  BMICategory? get category {
    final currentBmi = bmi;
    if (currentBmi == null) return null;

    if (currentBmi < 18.5) return BMICategory.underweight;
    if (currentBmi < 25) return BMICategory.normal;
    if (currentBmi < 30) return BMICategory.overweight;
    if (currentBmi < 35) return BMICategory.obese;
    return BMICategory.extremelyObese;
  }

  Color? get categoryColor {
    final currentCategory = category;
    if (currentCategory == null) return null;

    switch (currentCategory) {
      case BMICategory.underweight:
        return const Color(0xFF64B5F6);
      case BMICategory.normal:
        return const Color(0xFF80CBC4);
      case BMICategory.overweight:
        return const Color(0xFFFF9800);
      case BMICategory.obese:
        return const Color(0xFFF44336);
      case BMICategory.extremelyObese:
        return const Color(0xFF673AB7);
    }
  }

  String get categoryText {
    final currentCategory = category;
    if (currentCategory == null) return 'No BMI (height not provided)';

    switch (currentCategory) {
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
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'] ?? '',
    );
  }
}

enum HeartRateCategory { bradycardia, normal, elevated, tachycardia }

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
        return const Color(0xFF64B5F6);
      case HeartRateCategory.normal:
        return const Color(0xFF80CBC4);
      case HeartRateCategory.elevated:
        return const Color(0xFFFF9800);
      case HeartRateCategory.tachycardia:
        return const Color(0xFFF44336);
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
      value: (map['value'] as num).toInt(),
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
  final dynamic
      value; // Can be double, BloodPressureReading, BloodSugarReading, WeightReading, or HeartRateReading
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
    debugPrint('Converting HealthMetric to map:');
    debugPrint('Type: $type');
    debugPrint('Value: $value');
    debugPrint('Unit: $unit');

    if (type == 'Blood Sugar') {
      final bloodSugar = value as BloodSugarReading;
      debugPrint('Converting BloodSugarReading:');
      debugPrint('Value: ${bloodSugar.value}');
      debugPrint('Unit: ${bloodSugar.unit}');
      debugPrint('MealTime: ${bloodSugar.mealTime}');

      return {
        'id': id,
        'userId': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type,
        'value': bloodSugar.value,
        'unit': bloodSugar.unit.index,
        'mealTime': bloodSugar.mealTime.index,
        'notes': notes,
      };
    } else if (type == 'Blood Pressure') {
      final bp = value as BloodPressureReading;
      return {
        'id': id,
        'userId': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type,
        'systolic': bp.systolic,
        'diastolic': bp.diastolic,
        'pulse': bp.pulse,
        'notes': notes,
      };
    } else if (type == 'Weight') {
      final weight = value as WeightReading;
      return {
        'id': id,
        'userId': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type,
        'weight': weight.weight,
        'height': weight.height,
        'notes': notes,
      };
    } else if (type == 'Heart Rate') {
      final heartRate = value as HeartRateReading;
      return {
        'id': id,
        'userId': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type,
        'value': heartRate.value,
        'activity': heartRate.activity.index,
        'notes': notes,
      };
    }

    return {
      'id': id,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'value': value,
      'unit': unit,
      'notes': notes,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    debugPrint('Converting map to HealthMetric:');
    debugPrint('Map data: $map');

    final type = map['type'] as String;
    dynamic timestamp = map['timestamp'];
    if (timestamp is int) {
      timestamp = Timestamp.fromMillisecondsSinceEpoch(timestamp);
    }
    final dateTime = (timestamp as Timestamp).toDate();
    dynamic value;

    if (type == 'Blood Sugar') {
      debugPrint('Creating BloodSugarReading with data:');
      debugPrint('Value: ${map['value']}');
      debugPrint('Unit: ${map['unit']}');
      debugPrint('MealTime: ${map['mealTime']}');

      // Handle unit conversion
      int unitIndex;
      if (map['unit'] is String) {
        unitIndex = map['unit'] == 'mg/dL' ? 0 : 1;
      } else {
        unitIndex = (map['unit'] as int?) ?? 0;
      }

      final mealTimeIndex = map['mealTime'] as int? ?? 0;
      final sugarValue = (map['value'] as num).toDouble();

      value = BloodSugarReading(
        value: sugarValue,
        unit: BloodSugarUnit.values[unitIndex],
        mealTime: MealTime.values[mealTimeIndex],
        timestamp: dateTime,
        notes: map['notes'] as String? ?? '',
      );

      debugPrint('Created BloodSugarReading:');
      debugPrint('Value: ${value.value}');
      debugPrint('Unit: ${value.unit}');
      debugPrint('MealTime: ${value.mealTime}');
    } else if (type == 'Blood Pressure') {
      value = BloodPressureReading(
        systolic: map['systolic'] as int,
        diastolic: map['diastolic'] as int,
        pulse: map['pulse'] as int,
        timestamp: dateTime,
        notes: map['notes'] as String? ?? '',
      );
    } else if (type == 'Weight') {
      value = WeightReading(
        weight: (map['weight'] as num).toDouble(),
        height:
            map['height'] != null ? (map['height'] as num).toDouble() : null,
        timestamp: dateTime,
        notes: map['notes'] as String? ?? '',
      );
    } else if (type == 'Heart Rate') {
      final activityIndex = map['activity'] as int? ?? 0;
      value = HeartRateReading(
        value: (map['value'] as num).toInt(),
        activity: ActivityType.values[activityIndex],
        timestamp: dateTime,
        notes: map['notes'] as String? ?? '',
      );
    } else {
      value = map['value'];
    }

    // Convert unit string to proper format
    String unit;
    if (type == 'Blood Sugar') {
      unit = (value as BloodSugarReading).unit == BloodSugarUnit.mgdL
          ? 'mg/dL'
          : 'mmol/L';
    } else {
      unit = map['unit'] as String? ?? '';
    }

    return HealthMetric(
      id: map['id'] as String,
      userId: map['userId'] as String,
      timestamp: dateTime,
      type: type,
      value: value,
      unit: unit,
      notes: map['notes'] as String? ?? '',
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  Map<String, List<HealthMetric>> _healthData = {};
  String _selectedMetric = '';
  bool _isLoading = true;
  double _lastHeight = 1.7; // Default height in meters
  late TabController _tabController;

  // Controllers
  final _valueController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();
  final _heartRateController = TextEditingController();

  // Selection states
  MealTime _selectedMealTime = MealTime.beforeMeal;
  ActivityType _selectedActivity = ActivityType.resting;
  BloodSugarUnit _selectedBloodSugarUnit = BloodSugarUnit.mgdL;

  Future<void> _migrateBloodSugarReadings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      debugPrint('Starting blood sugar readings migration for user: $userId');

      final snapshot = await _firestore
          .collection('health_metrics')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'Blood Sugar')
          .get();

      debugPrint('Found ${snapshot.docs.length} blood sugar readings to check');

      final batch = _firestore.batch();
      var updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('Checking document ${doc.id}:');
        debugPrint('Data: $data');

        if (!data.containsKey('unit')) {
          debugPrint('No unit field found, updating to mg/dL');
          batch.update(doc.reference, {
            'unit': BloodSugarUnit.mgdL.index,
          });
          updatedCount++;
        } else {
          debugPrint('Unit field exists: ${data['unit']}');
        }
      }

      if (updatedCount > 0) {
        debugPrint('Committing batch update for $updatedCount documents');
        await batch.commit();
        debugPrint('Successfully migrated $updatedCount blood sugar readings');
      } else {
        debugPrint('No migration needed');
      }
    } catch (e, stackTrace) {
      debugPrint('Error migrating blood sugar readings: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHealthData();
    _loadHeight();

    // Listen to tab changes and update _selectedMetric
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedMetric = _healthData.keys.elementAt(_tabController.index);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _loadHeight() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore.collection('users').doc(userId).get();

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

  Future<void> _loadHealthData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user ID found. User might not be logged in.');
        return;
      }

      final snapshot = await _firestore
          .collection('health_metrics')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      // Store current selected metric
      final currentSelectedMetric = _selectedMetric;
      final currentTabIndex = _tabController.index;

      // Initialize with empty lists for all supported types
      final newHealthData = {
        'Blood Pressure': <HealthMetric>[],
        'Blood Sugar': <HealthMetric>[],
        'Weight': <HealthMetric>[],
        'Heart Rate': <HealthMetric>[],
      };

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final metric = HealthMetric.fromMap({...data, 'id': doc.id});
          if (newHealthData.containsKey(metric.type)) {
            newHealthData[metric.type]!.add(metric);
          }
        } catch (e, stackTrace) {
          debugPrint('Error processing document ${doc.id}: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      if (mounted) {
        setState(() {
          _healthData = newHealthData;
          _isLoading = false;
          // Restore selected metric
          _selectedMetric = currentSelectedMetric.isNotEmpty
              ? currentSelectedMetric
              : newHealthData.keys.first;
          // Restore tab index
          if (currentTabIndex >= 0) {
            _tabController.index = currentTabIndex;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading health data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addHealthMetric({
    required dynamic value,
    required String unit,
    required String type,
    String notes = '',
  }) async {
    try {
      final user = _auth.currentUser;
      debugPrint('Adding health metric - Auth state check:');
      debugPrint('User: ${user?.uid}');
      debugPrint('Email: ${user?.email}');
      debugPrint('Is Anonymous: ${user?.isAnonymous}');
      debugPrint('Is Email Verified: ${user?.emailVerified}');

      final userId = user?.uid;
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

      debugPrint('Creating new health metric...');
      debugPrint('Type: $type');
      debugPrint('Unit: $unit');
      debugPrint('Value: $value');
      debugPrint('Notes: $notes');
      debugPrint('User ID: $userId');

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
      debugPrint('Saving health metric to Firestore...');
      debugPrint('Document ID: $docId');
      debugPrint('Document data: $data');

      await _firestore.collection('health_metrics').doc(docId).set(data);
      debugPrint('Successfully saved health metric');

      await _loadHealthData();
      debugPrint('Reloaded health data');
    } catch (e, stackTrace) {
      debugPrint('Error adding health metric: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving health data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final Map<String, String> _units = {
    'Blood Pressure': 'mmHg',
    'Heart Rate': 'bpm',
    'Blood Sugar': 'mg/dL',
    'Weight': 'kg',
    'Temperature': '°C',
  };

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _heartRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
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
                      content: Text(
                          'Please enter a realistic heart rate (30-220 BPM)'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _systolicController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Systolic (mmHg)',
                  hintText: 'Enter systolic pressure',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _diastolicController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                  hintText: 'Enter diastolic pressure',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pulseController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
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

              if (systolic < 70 ||
                  systolic > 250 ||
                  diastolic < 40 ||
                  diastolic > 150 ||
                  pulse < 40 ||
                  pulse > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter realistic values'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                debugPrint('Creating new blood pressure reading...');
                final reading = BloodPressureReading(
                  systolic: systolic,
                  diastolic: diastolic,
                  pulse: pulse,
                  timestamp: DateTime.now(),
                  notes: _notesController.text.trim(),
                );

                debugPrint('Blood pressure reading created:');
                debugPrint('Systolic: ${reading.systolic}');
                debugPrint('Diastolic: ${reading.diastolic}');
                debugPrint('Pulse: ${reading.pulse}');

                _addHealthMetric(
                  value: reading,
                  unit: 'mmHg',
                  type: 'Blood Pressure',
                  notes: _notesController.text.trim(),
                );

                Navigator.pop(context);
                _clearControllers();
              } catch (e, stackTrace) {
                debugPrint('Error creating blood pressure reading: $e');
                debugPrint('Stack trace: $stackTrace');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving blood pressure: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBloodSugarInputDialog() async {
    _valueController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Blood Sugar Reading'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _selectedBloodSugarUnit == BloodSugarUnit.mgdL
                        ? 'Blood Sugar (mg/dL)'
                        : 'Blood Sugar (mmol/L)',
                    hintText: _selectedBloodSugarUnit == BloodSugarUnit.mgdL
                        ? 'Enter blood sugar value (normal range: 70-100 mg/dL)'
                        : 'Enter blood sugar value (normal range: 3.9-5.6 mmol/L)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Unit:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Text(
                          'mmol/L',
                          style: TextStyle(
                            color:
                                _selectedBloodSugarUnit == BloodSugarUnit.mmolL
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: _selectedBloodSugarUnit == BloodSugarUnit.mgdL,
                          onChanged: (bool value) {
                            final newUnit = value
                                ? BloodSugarUnit.mgdL
                                : BloodSugarUnit.mmolL;
                            if (_valueController.text.isNotEmpty) {
                              final currentValue =
                                  double.tryParse(_valueController.text);
                              if (currentValue != null) {
                                if (value) {
                                  // Convert from mmol/L to mg/dL
                                  _valueController.text =
                                      BloodSugarReading.mmolLToMgdL(
                                              currentValue)
                                          .toStringAsFixed(0);
                                } else {
                                  // Convert from mg/dL to mmol/L
                                  _valueController.text =
                                      BloodSugarReading.mgdLToMmolL(
                                              currentValue)
                                          .toStringAsFixed(1);
                                }
                              }
                            }
                            setState(() {
                              _selectedBloodSugarUnit = newUnit;
                            });
                          },
                        ),
                        Text(
                          'mg/dL',
                          style: TextStyle(
                            color:
                                _selectedBloodSugarUnit == BloodSugarUnit.mgdL
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  onChanged: (MealTime? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMealTime = newValue;
                      });
                    }
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

                final reading = BloodSugarReading(
                  value: value,
                  timestamp: DateTime.now(),
                  mealTime: _selectedMealTime,
                  unit: _selectedBloodSugarUnit,
                  notes: _notesController.text.trim(),
                );

                _addHealthMetric(
                  value: reading,
                  unit: _selectedBloodSugarUnit == BloodSugarUnit.mgdL
                      ? 'mg/dL'
                      : 'mmol/L',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter your weight',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
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
              if (_valueController.text.isEmpty ||
                  _heightController.text.isEmpty) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: const Text(
            'Health Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
            IconButton(
              icon: const Icon(Icons.summarize),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthReportScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _healthData.keys.map((metric) {
              return Tab(text: metric);
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _healthData.entries.map((entry) {
            final metrics = entry.value;
            return metrics.isEmpty
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: metrics.length + 1, // Add 1 for the chart
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Show appropriate chart based on metric type
                        if (entry.key == 'Blood Sugar') {
                          return _buildBloodSugarGraph();
                        } else if (entry.key == 'Blood Pressure') {
                          return _buildBloodPressureGraph();
                        } else if (entry.key == 'Weight') {
                          return _buildWeightGraph();
                        } else if (entry.key == 'Heart Rate') {
                          return _buildHeartRateGraph();
                        }
                        return const SizedBox
                            .shrink(); // No chart for other metrics
                      }

                      final medication = metrics[index - 1];
                      return Dismissible(
                        key: Key(medication.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text(
                                    "Are you sure you want to delete this item?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("DELETE"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteHealthMetric(medication.id, index - 1);
                        },
                        child: _buildHealthMetricCard(medication),
                      );
                    },
                  );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addHealthData,
          backgroundColor: const Color(0xFF00695C),
          child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildBloodSugarTitle(BloodSugarReading reading) {
    // Convert the value to both units
    double mgdLValue = reading.unit == BloodSugarUnit.mgdL
        ? reading.value
        : BloodSugarReading.mmolLToMgdL(reading.value);
    double mmolLValue = reading.unit == BloodSugarUnit.mmolL
        ? reading.value
        : BloodSugarReading.mgdLToMmolL(reading.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blood Sugar: ${mgdLValue.toStringAsFixed(0)} mg/dL (${mmolLValue.toStringAsFixed(1)} mmol/L)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reading.categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: reading.categoryColor),
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
            const SizedBox(width: 8),
            Text(
              reading.mealTimeText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightTitle(WeightReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Weight: ${reading.weight.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (reading.height != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: reading.categoryColor?.withOpacity(0.2) ??
                      Colors.grey.withOpacity(0.2),
                  border: Border.all(
                    color: reading.categoryColor ?? Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reading.categoryText,
                  style: TextStyle(
                    fontSize: 12,
                    color: reading.categoryColor ?? Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        if (reading.height != null)
          Text(
            'Height: ${reading.height?.toStringAsFixed(2)} m',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        if (reading.height != null)
          Text(
            'BMI: ${reading.bmi?.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
      ],
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

  Widget _buildBloodSugarGraph() {
    final bloodSugarReadings = _healthData['Blood Sugar']!
        .map((metric) => metric.value as BloodSugarReading)
        .toList();

    if (bloodSugarReadings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate min and max for better graph scaling
    final values = bloodSugarReadings.map((r) => r.valueInMgdL).toList();
    final minY = (values.reduce(min) - 10.0).clamp(0.0, double.infinity);
    final maxY = (values.reduce(max) + 10.0).clamp(0.0, double.infinity);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final lineColor =
        isDarkMode ? Colors.white : Theme.of(context).primaryColor;
    final gridColor = isDarkMode ? Colors.white24 : Colors.black12;
    final textColor = isDarkMode ? Colors.white70 : Colors.grey;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: gridColor,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: gridColor,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < bloodSugarReadings.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(
                            bloodSugarReadings[value.toInt()].timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                        ),
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
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: gridColor,
              width: 1,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(bloodSugarReadings.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  bloodSugarReadings[index].valueInMgdL,
                );
              }),
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: bloodSugarReadings[index].categoryColor,
                    strokeWidth: 2,
                    strokeColor: isDarkMode ? Colors.white : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightGraph() {
    if (_selectedMetric != 'Weight' || _healthData['Weight']?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final readings = _healthData['Weight']!
        .map((metric) => metric.value as WeightReading)
        .toList()
        .reversed
        .toList(); // Show oldest to newest

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
                          if (value.toInt() >= 0 &&
                              value.toInt() < readings.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd')
                                    .format(readings[value.toInt()].timestamp),
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
                            color: readings[index].categoryColor ?? Colors.grey,
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
        color: reading.categoryColor?.withOpacity(0.2),
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

  Widget _buildHeartRateGraph() {
    if (_selectedMetric != 'Heart Rate' ||
        _healthData['Heart Rate']?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    final readings = _healthData['Heart Rate']!
        .map((metric) => metric.value as HeartRateReading)
        .toList()
        .reversed
        .toList(); // Show oldest to newest

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
                          if (value.toInt() >= 0 &&
                              value.toInt() < readings.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('HH:mm')
                                    .format(readings[value.toInt()].timestamp),
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
                        return FlSpot(
                            index.toDouble(), readings[index].value.toDouble());
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildBloodSugarReadingCard(BloodSugarReading reading,
      {String? metricId}) {
    return Card(
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, y - h:mm a').format(reading.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            _buildBloodSugarTitle(reading),
          ],
        ),
        subtitle: reading.notes.isNotEmpty
            ? Text(
                'Notes: ${reading.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                if (metricId != null) {
                  _editHealthMetric(HealthMetric(
                    id: metricId,
                    userId: _auth.currentUser!.uid,
                    timestamp: reading.timestamp,
                    value: reading,
                    unit: reading.unit == BloodSugarUnit.mgdL
                        ? 'mg/dL'
                        : 'mmol/L',
                    type: 'Blood Sugar',
                    notes: reading.notes,
                  ));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (metricId != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete this reading?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE"),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await _deleteHealthMetric(
                        metricId,
                        _healthData['Blood Sugar']!
                            .indexWhere((m) => m.id == metricId));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureReadingCard(BloodPressureReading reading,
      {String? metricId}) {
    return Card(
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, y - h:mm a').format(reading.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            _buildBloodPressureTitle(reading),
          ],
        ),
        subtitle: reading.notes.isNotEmpty
            ? Text(
                'Notes: ${reading.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                if (metricId != null) {
                  _editHealthMetric(HealthMetric(
                    id: metricId,
                    userId: _auth.currentUser!.uid,
                    timestamp: reading.timestamp,
                    value: reading,
                    unit: 'mmHg',
                    type: 'Blood Pressure',
                    notes: reading.notes,
                  ));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (metricId != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete this reading?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE"),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await _deleteHealthMetric(
                        metricId,
                        _healthData['Blood Pressure']!
                            .indexWhere((m) => m.id == metricId));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightReadingCard(WeightReading reading, {String? metricId}) {
    return Card(
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, y - h:mm a').format(reading.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            _buildWeightTitle(reading),
          ],
        ),
        subtitle: reading.notes.isNotEmpty
            ? Text(
                'Notes: ${reading.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                if (metricId != null) {
                  _editHealthMetric(HealthMetric(
                    id: metricId,
                    userId: _auth.currentUser!.uid,
                    timestamp: reading.timestamp,
                    value: reading,
                    unit: 'kg',
                    type: 'Weight',
                    notes: reading.notes,
                  ));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (metricId != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete this reading?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE"),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await _deleteHealthMetric(
                        metricId,
                        _healthData['Weight']!
                            .indexWhere((m) => m.id == metricId));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateReadingCard(HeartRateReading reading,
      {String? metricId}) {
    return Card(
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, y - h:mm a').format(reading.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            _buildHeartRateTitle(reading),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity: ${reading.activity.toString().split('.').last}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (reading.notes.isNotEmpty)
              Text(
                'Notes: ${reading.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                if (metricId != null) {
                  _editHealthMetric(HealthMetric(
                    id: metricId,
                    userId: _auth.currentUser!.uid,
                    timestamp: reading.timestamp,
                    value: reading,
                    unit: 'bpm',
                    type: 'Heart Rate',
                    notes: reading.notes,
                  ));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (metricId != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete this reading?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE"),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await _deleteHealthMetric(
                        metricId,
                        _healthData['Heart Rate']!
                            .indexWhere((m) => m.id == metricId));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricCard(HealthMetric metric) {
    if (metric.value is BloodSugarReading) {
      return _buildBloodSugarReadingCard(metric.value as BloodSugarReading,
          metricId: metric.id);
    } else if (metric.value is BloodPressureReading) {
      return _buildBloodPressureReadingCard(
          metric.value as BloodPressureReading,
          metricId: metric.id);
    } else if (metric.value is WeightReading) {
      return _buildWeightReadingCard(metric.value as WeightReading,
          metricId: metric.id);
    } else if (metric.value is HeartRateReading) {
      return _buildHeartRateReadingCard(metric.value as HeartRateReading,
          metricId: metric.id);
    } else {
      return Card(
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, y - h:mm a').format(metric.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(metric.type),
            ],
          ),
          subtitle: Text(metric.value.toString()),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _editHealthMetric(metric);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete this reading?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE"),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await _deleteHealthMetric(
                        metric.id,
                        _healthData[metric.type]!
                            .indexWhere((m) => m.id == metric.id));
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCategoryIndicator(List<HealthMetric> readings, int index) {
    if (readings[index].value is! BloodSugarReading &&
        readings[index].value is! WeightReading) {
      return const SizedBox.shrink();
    }

    Color indicatorColor = Colors.grey;
    String categoryText = '';

    if (readings[index].value is BloodSugarReading) {
      final reading = readings[index].value as BloodSugarReading;
      indicatorColor = reading.categoryColor;
      categoryText = reading.categoryText;
    } else if (readings[index].value is WeightReading) {
      final reading = readings[index].value as WeightReading;
      indicatorColor = reading.categoryColor ?? Colors.grey;
      categoryText = reading.categoryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        categoryText,
        style: TextStyle(
          fontSize: 12,
          color: indicatorColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBloodPressureGraph() {
    final bloodPressureReadings = _healthData['Blood Pressure']!
        .map((metric) => metric.value as BloodPressureReading)
        .toList();

    if (bloodPressureReadings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate min and max for better graph scaling
    final systolicReadings =
        bloodPressureReadings.map((r) => r.systolic.toDouble()).toList();
    final diastolicReadings =
        bloodPressureReadings.map((r) => r.diastolic.toDouble()).toList();
    final minY =
        (diastolicReadings.reduce(min) - 10.0).clamp(0.0, double.infinity);
    final maxY =
        (systolicReadings.reduce(max) + 10.0).clamp(0.0, double.infinity);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < bloodPressureReadings.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(
                            bloodPressureReadings[value.toInt()].timestamp),
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
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Systolic line
            LineChartBarData(
              spots: List.generate(bloodPressureReadings.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  bloodPressureReadings[index].systolic.toDouble(),
                );
              }),
              isCurved: true,
              color: Colors.red,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            // Diastolic line
            LineChartBarData(
              spots: List.generate(bloodPressureReadings.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  bloodPressureReadings[index].diastolic.toDouble(),
                );
              }),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  void _editHealthMetric(HealthMetric metric) {
    if (metric.value is BloodSugarReading) {
      _editBloodSugarReading(metric);
    } else if (metric.value is BloodPressureReading) {
      _editBloodPressureReading(metric);
    } else if (metric.value is WeightReading) {
      _editWeightReading(metric);
    } else if (metric.value is HeartRateReading) {
      _editHeartRateReading(metric);
    }
  }

  void _editBloodSugarReading(HealthMetric metric) {
    final reading = metric.value as BloodSugarReading;
    _valueController.text = reading.value.toString();
    _notesController.text = reading.notes;
    _selectedMealTime = reading.mealTime;
    _selectedBloodSugarUnit = reading.unit;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Blood Sugar Reading'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _selectedBloodSugarUnit == BloodSugarUnit.mgdL
                      ? 'Blood Sugar (mg/dL)'
                      : 'Blood Sugar (mmol/L)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BloodSugarUnit>(
                value: _selectedBloodSugarUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: BloodSugarUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child:
                        Text(unit == BloodSugarUnit.mgdL ? 'mg/dL' : 'mmol/L'),
                  );
                }).toList(),
                onChanged: (BloodSugarUnit? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedBloodSugarUnit = newValue;
                    });
                  }
                },
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
                onChanged: (MealTime? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMealTime = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
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
            onPressed: () async {
              if (_valueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a value'),
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

              try {
                final updatedReading = BloodSugarReading(
                  value: value,
                  timestamp: reading.timestamp,
                  mealTime: _selectedMealTime,
                  unit: _selectedBloodSugarUnit,
                  notes: _notesController.text.trim(),
                );

                await _firestore
                    .collection('health_metrics')
                    .doc(metric.id)
                    .update({
                  'value': value,
                  'mealTime': _selectedMealTime.index,
                  'unit': _selectedBloodSugarUnit.index,
                  'notes': _notesController.text.trim(),
                });

                await _loadHealthData();
                if (mounted) {
                  Navigator.pop(context);
                  _clearControllers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blood sugar reading updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating blood sugar reading: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBloodPressureReading(HealthMetric metric) {
    final reading = metric.value as BloodPressureReading;
    _systolicController.text = reading.systolic.toString();
    _diastolicController.text = reading.diastolic.toString();
    _pulseController.text = reading.pulse.toString();
    _notesController.text = reading.notes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Blood Pressure Reading'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _systolicController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Systolic (mmHg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _diastolicController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pulseController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Pulse (bpm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
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
            onPressed: () async {
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

              try {
                final updatedReading = BloodPressureReading(
                  systolic: systolic,
                  diastolic: diastolic,
                  pulse: pulse,
                  timestamp: reading.timestamp,
                  notes: _notesController.text.trim(),
                );

                await _firestore
                    .collection('health_metrics')
                    .doc(metric.id)
                    .update({
                  'systolic': systolic,
                  'diastolic': diastolic,
                  'pulse': pulse,
                  'notes': _notesController.text.trim(),
                });

                await _loadHealthData();
                if (mounted) {
                  Navigator.pop(context);
                  _clearControllers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Blood pressure reading updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating blood pressure reading: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editWeightReading(HealthMetric metric) {
    final reading = metric.value as WeightReading;
    _valueController.text = reading.weight.toString();
    _heightController.text =
        reading.height?.toString() ?? _lastHeight.toString();
    _notesController.text = reading.notes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight Reading'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
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
            onPressed: () async {
              if (_valueController.text.isEmpty ||
                  _heightController.text.isEmpty) {
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

              try {
                final updatedReading = WeightReading(
                  weight: weight,
                  height: height,
                  timestamp: reading.timestamp,
                  notes: _notesController.text.trim(),
                );

                await _firestore
                    .collection('health_metrics')
                    .doc(metric.id)
                    .update({
                  'weight': weight,
                  'height': height,
                  'notes': _notesController.text.trim(),
                });

                await _saveHeight(height);
                await _loadHealthData();
                if (mounted) {
                  Navigator.pop(context);
                  _clearControllers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Weight reading updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating weight reading: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editHeartRateReading(HealthMetric metric) {
    final reading = metric.value as HeartRateReading;
    _heartRateController.text = reading.value.toString();
    _notesController.text = reading.notes;
    _selectedActivity = reading.activity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Heart Rate Reading'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _heartRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Heart Rate (BPM)',
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
                  onChanged: (ActivityType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedActivity = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
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
              onPressed: () async {
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

                try {
                  final updatedReading = HeartRateReading(
                    value: heartRate,
                    timestamp: reading.timestamp,
                    activity: _selectedActivity,
                    notes: _notesController.text.trim(),
                  );

                  await _firestore
                      .collection('health_metrics')
                      .doc(metric.id)
                      .update({
                    'value': heartRate,
                    'activity': _selectedActivity.index,
                    'notes': _notesController.text.trim(),
                  });

                  await _loadHealthData();
                  if (mounted) {
                    Navigator.pop(context);
                    _clearControllers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Heart rate reading updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating heart rate reading: $e'),
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
      mainAxisSize: MainAxisSize.min,
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

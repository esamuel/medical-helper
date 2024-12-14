import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  bool _allNotifications = true;
  bool _medicationReminders = true;
  bool _healthTracking = true;
  bool _appointments = true;
  bool _emergencyUpdates = true;

  // Getters
  bool get allNotifications => _allNotifications;
  bool get medicationReminders => _medicationReminders;
  bool get healthTracking => _healthTracking;
  bool get appointments => _appointments;
  bool get emergencyUpdates => _emergencyUpdates;

  NotificationProvider() {
    _loadPreferences();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadPreferences() async {
    await _initPrefs();
    _allNotifications = _prefs?.getBool('notifications_all') ?? true;
    _medicationReminders = _prefs?.getBool('notifications_medication') ?? true;
    _healthTracking = _prefs?.getBool('notifications_health') ?? true;
    _appointments = _prefs?.getBool('notifications_appointments') ?? true;
    _emergencyUpdates = _prefs?.getBool('notifications_emergency') ?? true;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    await _initPrefs();
    await _prefs?.setBool('notifications_all', _allNotifications);
    await _prefs?.setBool('notifications_medication', _medicationReminders);
    await _prefs?.setBool('notifications_health', _healthTracking);
    await _prefs?.setBool('notifications_appointments', _appointments);
    await _prefs?.setBool('notifications_emergency', _emergencyUpdates);
  }

  Future<void> toggleAllNotifications(bool value) async {
    _allNotifications = value;
    // When master toggle is turned off, disable all notifications
    if (!value) {
      _medicationReminders = false;
      _healthTracking = false;
      _appointments = false;
      _emergencyUpdates = false;
    }
    await _savePreferences();
    notifyListeners();
  }

  Future<void> toggleMedicationReminders(bool value) async {
    _medicationReminders = value;
    await _savePreferences();
    _updateMasterToggle();
    notifyListeners();
  }

  Future<void> toggleHealthTracking(bool value) async {
    _healthTracking = value;
    await _savePreferences();
    _updateMasterToggle();
    notifyListeners();
  }

  Future<void> toggleAppointments(bool value) async {
    _appointments = value;
    await _savePreferences();
    _updateMasterToggle();
    notifyListeners();
  }

  Future<void> toggleEmergencyUpdates(bool value) async {
    _emergencyUpdates = value;
    await _savePreferences();
    _updateMasterToggle();
    notifyListeners();
  }

  void _updateMasterToggle() {
    // Master toggle is on only if all individual toggles are on
    _allNotifications = _medicationReminders && 
                       _healthTracking && 
                       _appointments && 
                       _emergencyUpdates;
    _savePreferences();
  }
} 
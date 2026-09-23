import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:app_usage/app_usage.dart';
import '../models/activity_record.dart';
import 'database_service.dart';

class ActivityService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final Battery _battery = Battery();
  Timer? _pollingTimer;
  String? _lastAppPackage;
  int? _lastBatteryLevel;
  
  List<ActivityRecord> _recentActivities = [];
  List<ActivityRecord> get recentActivities => _recentActivities;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  ActivityService(this._databaseService);

  Future<void> startTracking(String userId, String userName) async {
    if (_isTracking) return;
    
    _isTracking = true;
    _loadRecentActivities();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkForegroundApp(userId, userName);
      await _checkBattery(userId, userName);
    });
    
    notifyListeners();
  }

  void stopTracking() {
    _pollingTimer?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _checkForegroundApp(String userId, String userName) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(minutes: 1));
      
      final usage = await AppUsage().getAppUsage(startDate, endDate);
      
      if (usage.isNotEmpty) {
        final latestApp = usage.reduce((a, b) => 
          a.endDate.isAfter(b.endDate) ? a : b
        );
        
        if (latestApp.packageName != _lastAppPackage) {
          _lastAppPackage = latestApp.packageName;
          
          final record = ActivityRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            userName: userName,
            type: ActivityType.appOpened,
            appName: latestApp.appName,
            appPackage: latestApp.packageName,
            timestamp: DateTime.now(),
          );
          
          await _databaseService.insertActivity(record);
          await _loadRecentActivities();
        }
      }
    } catch (e) {
      debugPrint('获取前台应用失败: $e');
    }
  }

  Future<void> _checkBattery(String userId, String userName) async {
    try {
      final level = await _battery.batteryLevel;
      
      if (_lastBatteryLevel == null || (level - _lastBatteryLevel!).abs() >= 5) {
        _lastBatteryLevel = level;
        
        final record = ActivityRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          userName: userName,
          type: ActivityType.batteryUpdate,
          batteryLevel: level,
          timestamp: DateTime.now(),
        );
        
        await _databaseService.insertActivity(record);
        await _loadRecentActivities();
      }
    } catch (e) {
      debugPrint('获取电量失败: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    _recentActivities = await _databaseService.getActivities(limit: 50);
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

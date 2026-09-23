class ActivityRecord {
  final String id;
  final String userId;
  final String userName;
  final ActivityType type;
  final String? appName;
  final String? appPackage;
  final int? batteryLevel;
  final DateTime timestamp;

  ActivityRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    this.appName,
    this.appPackage,
    this.batteryLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'type': type.name,
        'appName': appName,
        'appPackage': appPackage,
        'batteryLevel': batteryLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActivityRecord.fromJson(Map<String, dynamic> json) => ActivityRecord(
        id: json['id'],
        userId: json['userId'],
        userName: json['userName'],
        type: ActivityType.values.firstWhere((e) => e.name == json['type']),
        appName: json['appName'],
        appPackage: json['appPackage'],
        batteryLevel: json['batteryLevel'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

enum ActivityType {
  screenOn,
  screenOff,
  appOpened,
  batteryUpdate,
}

import 'package:flutter_test/flutter_test.dart';
import 'package:companionship/models/activity_record.dart';

void main() {
  test('ActivityRecord JSON 序列化往返', () {
    final record = ActivityRecord(
      id: '1',
      userId: 'me',
      userName: '我',
      type: ActivityType.appOpened,
      appName: '微信',
      appPackage: 'com.tencent.mm',
      timestamp: DateTime.parse('2026-09-23T10:00:00.000'),
    );

    final restored = ActivityRecord.fromJson(record.toJson());

    expect(restored.id, record.id);
    expect(restored.type, ActivityType.appOpened);
    expect(restored.appName, '微信');
    expect(restored.timestamp, record.timestamp);
  });
}

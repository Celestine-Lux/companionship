import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/activity_service.dart';
import '../models/activity_record.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activityService = context.watch<ActivityService>();
    final activities = activityService.recentActivities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('活动时间线'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 刷新列表
            },
          ),
        ],
      ),
      body: activities.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无活动记录',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '开始共享后会在这里显示',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isToday = _isToday(activity.timestamp);
                final showDateHeader = index == 0 ||
                    !_isSameDay(activity.timestamp,
                        activities[index - 1].timestamp);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          isToday
                              ? '今天'
                              : DateFormat('yyyy年MM月dd日')
                                  .format(activity.timestamp),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getActivityColor(activity.type),
                        child: Icon(
                          _getActivityIcon(activity.type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(_getActivityTitle(activity)),
                      subtitle: Text(
                        '${activity.userName} · ${DateFormat('HH:mm:ss').format(activity.timestamp)}',
                      ),
                      trailing: activity.type == ActivityType.batteryUpdate
                          ? Text(
                              '${activity.batteryLevel}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                  ],
                );
              },
            ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.appOpened:
        return Icons.apps;
      case ActivityType.batteryUpdate:
        return Icons.battery_charging_full;
      case ActivityType.screenOn:
        return Icons.phone_android;
      case ActivityType.screenOff:
        return Icons.phone_locked;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.appOpened:
        return Colors.blue;
      case ActivityType.batteryUpdate:
        return Colors.green;
      case ActivityType.screenOn:
        return Colors.orange;
      case ActivityType.screenOff:
        return Colors.grey;
    }
  }

  String _getActivityTitle(ActivityRecord activity) {
    switch (activity.type) {
      case ActivityType.appOpened:
        return '打开了 ${activity.appName ?? activity.appPackage ?? '未知应用'}';
      case ActivityType.batteryUpdate:
        return '电量更新';
      case ActivityType.screenOn:
        return '屏幕点亮';
      case ActivityType.screenOff:
        return '屏幕熄灭';
    }
  }
}

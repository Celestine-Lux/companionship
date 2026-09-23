import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_record.dart';
import '../services/activity_service.dart';
import '../services/database_service.dart';
import 'pairing_screen.dart';
import 'timeline_screen.dart';
import 'settings_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TimelineScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.timeline), label: '时间线'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkPairing();
  }

  Future<void> _checkPairing() async {
    final db = context.read<DatabaseService>();
    final companion = await db.getActiveCompanion();
    
    if (companion == null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PairingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityService = context.watch<ActivityService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companionship'),
        actions: [
          IconButton(
            icon: Icon(
              activityService.isTracking ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () async {
              final db = context.read<DatabaseService>();
              final companion = await db.getActiveCompanion();
              
              if (companion != null) {
                if (activityService.isTracking) {
                  activityService.stopTracking();
                } else {
                  activityService.startTracking('me', '我');
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              activityService.isTracking 
                ? Icons.visibility 
                : Icons.visibility_off,
              size: 80,
              color: activityService.isTracking 
                ? Colors.green 
                : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              activityService.isTracking ? '正在共享活动' : '已暂停共享',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            if (activityService.recentActivities.isNotEmpty) ...[
              const Text('最近活动', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ...activityService.recentActivities.take(3).map((activity) {
                return ListTile(
                  leading: Icon(_getActivityIcon(activity.type)),
                  title: Text(_getActivityTitle(activity)),
                  subtitle: Text(_formatTime(activity.timestamp)),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.appOpened:
        return Icons.apps;
      case ActivityType.batteryUpdate:
        return Icons.battery_full;
      case ActivityType.screenOn:
        return Icons.phone_android;
      case ActivityType.screenOff:
        return Icons.phone_locked;
    }
  }

  String _getActivityTitle(ActivityRecord activity) {
    switch (activity.type) {
      case ActivityType.appOpened:
        return '打开了 ${activity.appName ?? activity.appPackage}';
      case ActivityType.batteryUpdate:
        return '电量 ${activity.batteryLevel}%';
      case ActivityType.screenOn:
        return '屏幕点亮';
      case ActivityType.screenOff:
        return '屏幕熄灭';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

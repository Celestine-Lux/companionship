import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';
import '../services/permission_service.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'pairing_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPermission = false;
  late final TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(
      text: context.read<ApiService>().baseUrl,
    );
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissionService = context.read<PermissionService>();
    final hasPermission = await permissionService.hasUsageStatsPermission();
    setState(() => _hasPermission = hasPermission);
  }

  Future<void> _requestPermissions() async {
    final permissionService = context.read<PermissionService>();
    await permissionService.openUsageAccessSettings();

    // 等待用户返回后重新检查
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _saveServerUrl() async {
    try {
      await context.read<ApiService>().setBaseUrl(_serverUrlController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务器地址已保存')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _openPairing() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PairingScreen()),
    );
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除数据'),
        content: const Text('确定要清除所有活动记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<DatabaseService>().clearActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('活动记录已清除')),
        );
      }
    }
  }

  Future<void> _unpair() async {
    final db = context.read<DatabaseService>();
    final activityService = context.read<ActivityService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解除配对'),
        content: const Text('确定要解除当前配对吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final companion = await db.getActiveCompanion();

      if (companion != null) {
        await db.deactivateCompanion(companion.id);

        if (mounted) {
          activityService.stopTracking();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PairingScreen()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '权限设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              _hasPermission ? Icons.check_circle : Icons.warning,
              color: _hasPermission ? Colors.green : Colors.orange,
            ),
            title: const Text('使用情况访问权限'),
            subtitle: Text(
              _hasPermission ? '已授权' : '需要授权才能记录应用使用情况',
            ),
            trailing: _hasPermission
                ? null
                : TextButton(
                    onPressed: _requestPermissions,
                    child: const Text('去设置'),
                  ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '连接设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _serverUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '服务器 URL',
                hintText: '例如 http://192.168.1.100:3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saveServerUrl,
                icon: const Icon(Icons.save),
                label: const Text('保存服务器地址'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('配对设备'),
            subtitle: const Text('生成配对码或输入对方的配对码'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openPairing,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '数据管理',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除活动记录'),
            subtitle: const Text('删除本地存储的所有活动记录'),
            onTap: _clearData,
          ),
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('解除配对'),
            subtitle: const Text('停止共享并解除当前配对关系'),
            onTap: _unpair,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '关于',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('隐私说明'),
            subtitle: Text('所有数据仅存储在本地，双方明确同意后才共享'),
          ),
        ],
      ),
    );
  }
}

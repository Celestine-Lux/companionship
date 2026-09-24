import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/companion.dart';
import 'home_screen.dart';
import 'dart:math';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _nameController = TextEditingController();
  final _pairingCodeController = TextEditingController();
  String? _generatedCode;
  bool _isGenerating = false;
  bool _isJoining = false;

  String _generatePairingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createPairing() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入你的名字')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedCode = _generatePairingCode();
    });

    final companion = Companion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      pairingCode: _generatedCode!,
      pairedAt: DateTime.now(),
    );

    await context.read<DatabaseService>().insertCompanion(companion);
    try {
      await context.read<ApiService>().heartbeat(
            pairingCode: companion.pairingCode,
            userId: companion.id,
            userName: companion.name,
          );
    } catch (_) {
      // 配对码仍保存在本地，可在服务端可用后重新连接。
    }

    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _joinPairing() async {
    final name = _nameController.text.trim();
    final code = _pairingCodeController.text.trim().toUpperCase();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入你的名字')),
      );
      return;
    }
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 6 位配对码')),
      );
      return;
    }

    setState(() => _isJoining = true);
    final companion = Companion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      pairingCode: code,
      pairedAt: DateTime.now(),
    );
    await context.read<DatabaseService>().insertCompanion(companion);
    try {
      await context.read<ApiService>().heartbeat(
            pairingCode: companion.pairingCode,
            userId: companion.id,
            userName: companion.name,
          );
    } catch (_) {
      // 配对码仍保存在本地，可在服务端可用后重新连接。
    }

    if (!mounted) return;
    setState(() => _isJoining = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigator()),
    );
  }

  Future<void> _scanCode() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('二维码扫描功能开发中，请先手动输入配对码')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配对')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.people, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              '开始共享活动',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '需要双方同意才能查看对方的活动记录',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '你的名字',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _createPairing,
              icon: const Icon(Icons.qr_code),
              label: const Text('生成配对码'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_generatedCode != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('配对码', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        _generatedCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '将此码发送给对方',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const MainNavigator()),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('完成并进入首页'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            TextField(
              controller: _pairingCodeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              onChanged: (value) {
                final normalized = value.toUpperCase();
                if (normalized != value) {
                  _pairingCodeController.value =
                      _pairingCodeController.value.copyWith(
                    text: normalized,
                    selection: TextSelection.collapsed(
                      offset: normalized.length,
                    ),
                  );
                }
              },
              decoration: const InputDecoration(
                labelText: '输入对方的配对码',
                hintText: '请输入 6 位字母或数字',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isJoining ? null : _joinPairing,
              icon: const Icon(Icons.link),
              label: Text(_isJoining ? '正在配对...' : '使用配对码加入'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _scanCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('扫描对方的配对码'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pairingCodeController.dispose();
    super.dispose();
  }
}

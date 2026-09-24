import 'package:flutter/services.dart';

class PermissionService {
  static const _usageChannel = MethodChannel('companionship/usage');

  Future<bool> hasUsageStatsPermission() async {
    try {
      return await _usageChannel.invokeMethod<bool>('hasUsagePermission') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() async {
    await _usageChannel.invokeMethod('openUsagePermissionSettings');
  }

  Future<bool> requestCameraPermission() async {
    return true;
  }
}

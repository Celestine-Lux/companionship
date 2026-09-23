import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestUsageStatsPermission() async {
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<bool> hasUsageStatsPermission() async {
    return await Permission.manageExternalStorage.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}

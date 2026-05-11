import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PermissionUtils {
  static final _logger = Logger();

  static Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.microphone].request();

    _logger.i("Permission statuses: $statuses");

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }

  static Future<bool> checkPermissions() async {
    bool cameraGranted = await Permission.camera.isGranted;
    bool microphoneGranted = await Permission.microphone.isGranted;

    _logger.i(
      "Camera permission: $cameraGranted, Microphone permission: $microphoneGranted",
    );

    return cameraGranted && microphoneGranted;
  }
}

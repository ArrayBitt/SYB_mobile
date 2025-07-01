import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PermissionUtils {
  static Future<bool> requestAllPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        var cameraStatus = await Permission.camera.status;
        var photosStatus = await Permission.photos.status;

        if (!cameraStatus.isGranted) {
          cameraStatus = await Permission.camera.request();
        }
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }

        return cameraStatus.isGranted && photosStatus.isGranted;
      } else {
        var cameraStatus = await Permission.camera.status;
        var storageStatus = await Permission.storage.status;

        if (!cameraStatus.isGranted) {
          cameraStatus = await Permission.camera.request();
        }
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        return cameraStatus.isGranted && storageStatus.isGranted;
      }
    } else if (Platform.isIOS) {
      var cameraStatus = await Permission.camera.status;
      var photosStatus = await Permission.photos.status;

      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }
      if (!photosStatus.isGranted) {
        photosStatus = await Permission.photos.request();
      }

      return cameraStatus.isGranted && photosStatus.isGranted;
    }

    return false;
  }
}

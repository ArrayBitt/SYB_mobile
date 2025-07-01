// 📦 upload_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class UploadService {
  static const int _maxSizeBytes = 10 * 1024 * 1024; // 10MB

  static Future<File> compressImageIfNeeded(File file) async {
    final int originalSize = await file.length();
    if (originalSize <= _maxSizeBytes) return file;

    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(
      tempDir.path,
      '${path.basenameWithoutExtension(file.path)}_compressed.jpg',
    );

   final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70, // ลดจาก 80 เป็น 70
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );


    return (compressedFile as File?) ?? file;
  }

  static Future<void> autoUploadIfNeeded({
    required String contractno,
    required List<File?> imageFiles,
    required BuildContext context,
    required ValueNotifier<String> statusNotifier,
  }) async {
    if (contractno.trim().isEmpty || imageFiles.every((f) => f == null)) return;

    _showModernUploadingDialog(context, statusNotifier);

    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (file == null || !await file.exists()) continue;

      statusNotifier.value = '📤 Uploading ${i + 1}/${imageFiles.length}...';

      final compressed = await compressImageIfNeeded(file);

      final uri = Uri.parse( 'https://ss.cjk-cr.com/CJK/api/appfollowup/picupload_api.php',);
      //final uri = Uri.parse('http://192.168.1.15/CJKTRAINING/api/appfollowup/picupload_api.php', );

      final fileName = '${contractno}_${String.fromCharCode(65 + i)}.jpg';
      final fieldName = 'pic${String.fromCharCode(65 + i)}';

      final request =
          http.MultipartRequest('POST', uri)
            ..fields['contractno'] = contractno
            ..files.add(
              await http.MultipartFile.fromPath(
                fieldName,
                compressed.path,
                filename: fileName,
              ),
            );

      try {
        final response = await request.send().timeout(
          const Duration(seconds: 60),
        );
        final respStr = await response.stream.bytesToString();
        debugPrint('✅ [$fieldName] ${response.statusCode}: $respStr');
      } catch (e) {
        debugPrint('❌ Upload failed for $fieldName: $e');
      }
    }

    statusNotifier.value = '✅ Upload complete';
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
  }

  static void _showModernUploadingDialog(
    BuildContext context,
    ValueNotifier<String> statusNotifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.white,
            elevation: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_rounded,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<String>(
                    valueListenable: statusNotifier,
                    builder:
                        (_, value, __) => Text(
                          value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      color: Colors.amber,
                      backgroundColor: Colors.amber.shade50,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'โปรดรอสักครู่... อย่าปิดแอป',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

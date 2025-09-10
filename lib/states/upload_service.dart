// 📦 upload_service.dart
import 'dart:io';
import 'dart:convert';
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
    void Function(int index)? onUploadSuccess, // เพิ่มตรงนี้
  }) async {
    if (contractno.trim().isEmpty || imageFiles.every((f) => f == null)) return;

    _showModernUploadingDialog(context, statusNotifier);

    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (file == null || !await file.exists()) continue;

      statusNotifier.value = '📤 Uploading ${i + 1}/${imageFiles.length}...';

      final compressed = await compressImageIfNeeded(file);

      final uri = Uri.parse(
        'https://syb.cjk-cr.com/SYYSJ/api/appfollowup/picupload_api.php',
      );

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

        if (response.statusCode == 200 && onUploadSuccess != null) {
          onUploadSuccess(i); // เรียก callback ถ้า upload สำเร็จ
        }
      } catch (e) {
        debugPrint('❌ Upload failed for $fieldName: $e');
      }
    }

    statusNotifier.value = '✅ Upload complete';
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
  }

  static Future<void> insertCheckStatusPic({
    required String contractno,
    required List<File?> imageFiles,
  }) async {
    final url =
        'https://syb.cjk-cr.com/SYYSJ/api/appfollowup/checkstatuspic_api.php';

    final payload = {
      'contractno': contractno,
      'pic_a': imageFiles[0] != null ? 'Y' : 'N',
      'pic_b': imageFiles[1] != null ? 'Y' : 'N',
      'pic_c': imageFiles[2] != null ? 'Y' : 'N',
      'pic_d': imageFiles[3] != null ? 'Y' : 'N',
      'pic_e': imageFiles[4] != null ? 'Y' : 'N',
      'pic_f': imageFiles[5] != null ? 'Y' : 'N',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);
      debugPrint('📌 insertCheckStatusPic: $result');
    } catch (e) {
      debugPrint('❌ insertCheckStatusPic error: $e');
    }
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

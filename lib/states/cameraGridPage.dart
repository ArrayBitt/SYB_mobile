import 'dart:async';
import 'dart:io';

import 'package:syb/states/upload_service.dart';
import 'package:syb/states/videoRecordPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;


class CameraGridPage extends StatefulWidget {
  final String contractno;
  const CameraGridPage({Key? key, required this.contractno}) : super(key: key);

  @override
  State<CameraGridPage> createState() => _CameraGridPageState();
}

class _CameraGridPageState extends State<CameraGridPage> {
  final ImagePicker _picker = ImagePicker();
  List<File?> _imageFiles = List.generate(6, (index) => null);
  List<TextEditingController> _textControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  List<bool> _uploadedFlags = List.filled(6, false);

  bool _hasCheckedUploadOnce = false;

  final ValueNotifier<String> _uploadStatusNotifier = ValueNotifier<String>(
    '',
  ); // popup status controller

  String _getUploadFlagsPrefKey() => 'uploadedFlags_${widget.contractno}';

  String _getPrefKey() => 'imagePaths_${widget.contractno}';

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
    _loadUploadedFlags();

    // ✅ เรียก popup ตรวจสอบเฉพาะครั้งแรก
  }

  Future<void> _loadUploadedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> flags =
        prefs.getStringList(_getUploadFlagsPrefKey()) ??
        List.filled(6, 'false');
    setState(() {
      _uploadedFlags = flags.map((e) => e == 'true').toList();
    });
  }

  Future<void> _saveImagePaths(int index, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList(_getPrefKey()) ?? List.filled(6, '');
    savedPaths[index] = imagePath;
    await prefs.setStringList(_getPrefKey(), savedPaths);
  }

  Future<bool> _requestAllPermissions() async {
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

  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return true; // เว็บไม่ต้องขอ permission

    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    } else if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
        return status.isGranted;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return false;
  }

  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList(_getPrefKey()) ?? List.filled(6, '');

    List<File?> tempFiles = List.generate(6, (index) => null);

    for (int i = 0; i < savedPaths.length; i++) {
      String pathStr = savedPaths[i];
      File localFile = File(pathStr);

      if (pathStr.isNotEmpty && await localFile.exists()) {
        tempFiles[i] = localFile;
      } else {
        // โหลดจาก server ถ้าไม่มีในเครื่อง
        File? downloaded = await _downloadImageFromServerIfNeeded(i);
        if (downloaded != null) {
          tempFiles[i] = downloaded;
          await _saveImagePaths(i, downloaded.path);
        }
      }
    }

    setState(() {
      _imageFiles = tempFiles;
    });
  }

  Future<File?> _downloadImageFromServerIfNeeded(int index) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String fileName =
          '${widget.contractno}_${String.fromCharCode(65 + index)}.jpg';
      String url = 'https://syb.cjk-cr.com/Pictures/$fileName';
      String localPath = path.join(directory.path, fileName);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        File file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        print('🔸 ไม่พบรูปจาก server: $url');
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
    }
    return null;
  }
Future<void> _pickImage(int index, ImageSource source) async {
    bool granted = await _requestAllPermissions();
    if (!granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โปรดให้สิทธิ์การเข้าถึงรูปภาพ')));
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        // decode image
        final originalImage = img.decodeImage(bytes);
        if (originalImage == null) {
          throw Exception('ไม่สามารถ decode รูปภาพได้');
        }

        // resize image: ปรับกว้างเป็น 1024 px โดยรักษาสัดส่วน
        final resizedImage = img.copyResize(originalImage, width: 1024);

        // compress image คุณภาพ 85%
        final jpgBytes = img.encodeJpg(resizedImage, quality: 85);

        final directory = await getApplicationDocumentsDirectory();
        final newPath = path.join(
          directory.path,
          '${widget.contractno}_${String.fromCharCode(65 + index)}.jpg',
        );

        final newImage = File(newPath);
        await newImage.writeAsBytes(jpgBytes);

        print('📂 รูปใหม่ถูกบันทึกไว้ที่: $newPath');

        setState(() {
          _imageFiles[index] = newImage;
        });

        await _saveImagePaths(index, newPath);
      } else {
        print('📭 ไม่ได้เลือกรูป');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกภาพ')));
    }
  }

  Future<void> _removeImage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList(_getPrefKey()) ?? List.filled(6, '');
    savedPaths[index] = '';
    await prefs.setStringList(_getPrefKey(), savedPaths);

    setState(() {
      _imageFiles[index] = null;
      _textControllers[index].clear();
    });
  }

  Future<void> _clearAllImages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_getPrefKey(), List.filled(6, ''));

    setState(() {
      _imageFiles = List.generate(6, (index) => null);
      _textControllers.forEach((controller) => controller.clear());
    });
  }

  Future<void> _saveUploadedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> flags =
        _uploadedFlags.map((e) => e ? 'true' : 'false').toList();
    await prefs.setStringList(_getUploadFlagsPrefKey(), flags);
  }

  void _saveImagesAndReturn() async {
    if (widget.contractno.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ข้อมูล contractno ไม่ถูกต้อง')));
      return;
    }

    if (_imageFiles.every((file) => file == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาถ่ายรูปหรือเลือกภาพก่อนบันทึก')),
      );
      return;
    }
  }

  @override
  void dispose() {
    //_triggerAutoUpload();
    super.dispose();
  }

  void _triggerAutoUpload() {
    if (_imageFiles.any((file) => file != null)) {
      UploadService.autoUploadIfNeeded(
        contractno: widget.contractno,
        imageFiles: _imageFiles,
        context: context,
        statusNotifier: _uploadStatusNotifier,
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber.shade700;

    return WillPopScope(
      onWillPop: () async {
        if (_uploadStatusNotifier.value.contains('📸')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('กำลังอัปโหลด กรุณารอสักครู่')),
          );
          return false;
        }

        bool hasPendingUpload = false;
        for (int i = 0; i < _imageFiles.length; i++) {
          if (_imageFiles[i] != null && !_uploadedFlags[i]) {
            hasPendingUpload = true;
            break;
          }
        }

        if (hasPendingUpload) {
          final shouldUpload = await showDialog<bool>(
            context: context,
            barrierDismissible: false, // กดนอก dialog ไม่ปิด
            builder:
                (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 64,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ยังไม่ได้อัปโหลดภาพใหม่',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'คุณต้องการอัปโหลดรูปภาพตอนนี้หรือไม่?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade600,
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('ไม่'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('ใช่'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          );

          if (shouldUpload == true) {
            await UploadService.autoUploadIfNeeded(
              contractno: widget.contractno,
              imageFiles: _imageFiles,
              context: context,
              statusNotifier: _uploadStatusNotifier,
              onUploadSuccess: (index) async {
                setState(() {
                  _uploadedFlags[index] = true;
                });
                await _saveUploadedFlags();
              },
            );

            await UploadService.insertCheckStatusPic(
              contractno: widget.contractno,
              imageFiles: _imageFiles,
            );
          }
        }

        return true;
      },

      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(
            '📷 ภาพถ่าย (${widget.contractno})',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: yellow,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: Icon(Icons.videocam),
              tooltip: 'ถ่ายวิดีโอ',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            VideoRecordPage(contractNo: widget.contractno),
                  ),
                );
                if (result != null) {
                  // ทำอะไรบางอย่างกับวิดีโอ
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('ลบรูปทั้งหมด'),
                        content: Text('คุณต้องการลบรูปภาพทั้งหมดใช่หรือไม่?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('ยกเลิก'),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearAllImages();
                              Navigator.pop(context);
                            },
                            child: Text('ลบทั้งหมด'),
                          ),
                        ],
                      ),
                );
              },
              tooltip: 'ลบทั้งหมด',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: false,
                    physics: AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _pickImage(index, ImageSource.camera),
                        onLongPress: () {
                          if (_imageFiles[index] != null) {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('ลบรูปภาพ'),
                                    content: Text(
                                      'คุณต้องการลบรูปภาพนี้หรือไม่?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('ยกเลิก'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _removeImage(index);
                                          Navigator.pop(context);
                                        },
                                        child: Text('ลบ'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child:
                                      _imageFiles[index] != null
                                          ? Image.file(
                                            _imageFiles[index]!,
                                            key: ValueKey(
                                              DateTime.now()
                                                  .millisecondsSinceEpoch,
                                            ),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                          : Icon(Icons.photo_camera, size: 50),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${widget.contractno}_${String.fromCharCode(65 + index)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:convert';
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

  String _getPrefKey() => 'imagePaths_${widget.contractno}';

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _saveImagePaths(int index, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList(_getPrefKey()) ?? List.filled(6, '');
    savedPaths[index] = imagePath;
    await prefs.setStringList(_getPrefKey(), savedPaths);
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
      if (savedPaths[i].isNotEmpty) {
        final file = File(savedPaths[i]);
        if (await file.exists()) {
          tempFiles[i] = file;
        }
      }
    }

    setState(() {
      _imageFiles = tempFiles;
    });
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    bool granted = await _requestGalleryPermission();
    if (!granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โปรดให้สิทธิ์การเข้าถึงรูปภาพ')));
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        String newPath;
        if (kIsWeb) {
          // Web ยังใช้ path เดิม (อาจยังไม่เหมาะสมสำหรับ Web จริงๆ)
          newPath = pickedFile.path;
        } else {
          final directory = await getTemporaryDirectory();
          newPath = path.join(
            directory.path,
            '${widget.contractno}_${String.fromCharCode(65 + index)}.jpg',
          );
        }

        final newImage = File(newPath);
        await newImage.writeAsBytes(await pickedFile.readAsBytes());

        setState(() {
          _imageFiles[index] = newImage;
        });

        await _saveImagePaths(index, newPath);
      }
    } catch (e) {
      print('Error picking image: $e');
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

  Future<List<String>> _uploadImagesToPicUploadAPI(
    List<File?> imageFiles,
  ) async {
    final uri = Uri.parse(
      'https://ss.cjk-cr.com/CJK/api/appfollowup/picupload_api.php',
    );

    var request = http.MultipartRequest('POST', uri);

    for (int i = 0; i < imageFiles.length; i++) {
      if (imageFiles[i] != null) {
        var pic = await http.MultipartFile.fromPath(
          'file${String.fromCharCode(65 + i)}',
          imageFiles[i]!.path,
        );
        request.files.add(pic);
      }
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final decoded = json.decode(respStr);

      if (decoded['status'] == 'success') {
        print('✅ อัปโหลดเสร็จเรียบร้อย');

        List<String> uploadedFileNames = [];
        if (decoded['files'] != null) {
          for (var f in decoded['files']) {
            uploadedFileNames.add(f['file_name']);
          }
        }

        return uploadedFileNames;
      } else {
        throw Exception('API Error: ${decoded['message']}');
      }
    } else {
      throw Exception('HTTP Error ${response.statusCode}');
    }
  }

  void _saveImagesAndReturn() async {
    if (_imageFiles.any((file) => file != null)) {
      try {
        List<String> uploadedFileNames = await _uploadImagesToPicUploadAPI(
          _imageFiles,
        );

        Map<String, String> imageData = {};
        for (int i = 0; i < uploadedFileNames.length; i++) {
          String key = 'pic${String.fromCharCode(97 + i)}'; // pica, picb, ...
          imageData[key] = uploadedFileNames[i];
        }

        imageData['contractno'] = widget.contractno;

        Navigator.pop(context, imageData);
      } catch (e) {
        print('❌ Error uploading images: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาถ่ายรูปหรือเลือกภาพจากแกลเลอรี่ก่อนบันทึก'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber.shade700;

    return Scaffold(
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
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveImagesAndReturn,
            tooltip: 'บันทึกรูป',
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
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                        : Container(
                                         
                                          child: Icon(
                                            Icons.photo_camera,
                                            size: 50,
                                          ),
                                        ),
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
    );
  }
}

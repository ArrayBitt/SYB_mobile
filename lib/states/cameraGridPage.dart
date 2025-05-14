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
    _requestPermissions();
    _loadSavedImages();
  }

  

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.request();
    if (status.isDenied) {
      print("Storage permission denied");
    }
  }

    // ✅ แก้ไขเพื่อใช้ key แยกตาม contractno
  Future<void> _saveImagePaths(int index, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList(_getPrefKey()) ?? List.filled(6, '');
    savedPaths[index] = imagePath;
    await prefs.setStringList(_getPrefKey(), savedPaths);
  }


  
  // ✅ แก้ไขเพื่อโหลด path ตาม contractno
  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList(_getPrefKey()) ?? List.filled(6, '');

    for (int i = 0; i < savedPaths.length; i++) {
      if (savedPaths[i].isNotEmpty) {
        final file = File(savedPaths[i]);
        if (await file.exists()) {
          setState(() {
            _imageFiles[i] = file;
          });
        }
      }
    }
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        String newPath;
        if (kIsWeb) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โปรดให้สิทธิ์การเข้าถึง Storage')),
      );
    }
  }

  // ✅ แก้ไขเพื่อเคลียร์ path เฉพาะของ contractno นี้
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

  // ✅ แก้ไขให้ลบ path ทั้งหมดเฉพาะของ contractno นี้
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
    final uri = Uri.parse('https://ss.cjk-cr.com/CJK/api/appfollowup/picupload_api.php',);
    //final uri = Uri.parse('http://171.102.194.54/TRAINING/PPWSJ/api/appfollowup/picupload_api.php',);


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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final image = _imageFiles[index];
                  return GestureDetector(
                    onTap: () => _pickImage(index, ImageSource.camera),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                image == null
                                    ? Center(
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                    : Image.file(
                                      image,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                          ),
                          if (image != null)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  path.basename(image.path),
                                  style: GoogleFonts.prompt(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

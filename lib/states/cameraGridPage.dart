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

  Future<void> _saveImagePaths(int index, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList('imagePaths') ?? List.filled(6, '');
    savedPaths[index] = imagePath;
    await prefs.setStringList('imagePaths', savedPaths);
  }

  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList('imagePaths') ?? List.filled(6, '');

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

  Future<void> _removeImage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPaths =
        prefs.getStringList('imagePaths') ?? List.filled(6, '');
    savedPaths[index] = '';
    await prefs.setStringList('imagePaths', savedPaths);

    setState(() {
      _imageFiles[index] = null;
      _textControllers[index].clear();
    });
  }

  Future<void> _clearAllImages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('imagePaths', List.filled(6, ''));

    setState(() {
      _imageFiles = List.generate(6, (index) => null);
      _textControllers.forEach((controller) => controller.clear());
    });
  }
Future<void> _uploadImagesToPicUploadAPI(List<File?> imageFiles) async {
    final uri = Uri.parse(
      'https://ppw.somjai.app/PPWSJ/api/appfollowup/picupload_api.php',
    );

    var request = http.MultipartRequest('POST', uri);

    // ส่งไฟล์จาก _imageFiles ไปยัง API
    for (int i = 0; i < imageFiles.length; i++) {
      if (imageFiles[i] != null) {
        // ใช้ชื่อฟิลด์ตามที่กำหนดใน PHP เช่น fileA, fileB, ...
        var pic = await http.MultipartFile.fromPath(
          'file${String.fromCharCode(65 + i)}', // fileA, fileB, fileC, ...
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
        print('Upload to picupload_api.php successful!');
        List<String> fileNames = [];
        for (int i = 0; i < imageFiles.length; i++) {
          final file = imageFiles[i];
          if (file != null) {
            fileNames.add(path.basename(file.path));
          }
        }

        // ส่งข้อมูลกลับไปยังหน้าถัดไป (saverush.dart)
        Navigator.pop(context, {
          'contractno': widget.contractno,
          'fileNames': fileNames,
        });
      } else {
        print('Failed to upload to picupload_api.php: ${decoded['message']}');
      }
    } else {
      print(
        'Failed to send request to picupload_api.php. Status code: ${response.statusCode}',
      );
    }
  }


  void _saveImagesAndReturn() {
    final fileNames = <String?>[];

    for (int i = 0; i < _imageFiles.length; i++) {
      final file = _imageFiles[i];
      if (file != null) {
        fileNames.add(path.basename(file.path));
      } else {
        fileNames.add(null);
      }
    }

    if (fileNames.any((file) => file != null)) {
      _uploadImagesToPicUploadAPI(_imageFiles)
          .then((_) {
            Navigator.pop(context, {
              'contractno': widget.contractno,
              'fileNames': fileNames,
            });
          })
          .catchError((e) {
            print('Error uploading images: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ')),
            );
          });
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
                  childAspectRatio: 1,
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
                      child:
                          image == null
                              ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey.shade600,
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(image, fit: BoxFit.cover),
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

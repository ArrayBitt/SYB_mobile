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

  Future<void> _uploadImages(List<File?> imageFiles) async {
    final uri = Uri.parse(
      'https://ppw.somjai.app/PPWSJ/api/appfollowup/picupload_api.php',
    );

    for (int i = 0; i < imageFiles.length; i++) {
      if (imageFiles[i] != null) {
        var request = http.MultipartRequest('POST', uri);
        request.fields['contractno'] = widget.contractno;
        request.fields['desc${String.fromCharCode(65 + i)}'] =
            _textControllers[i].text;

        var pic = await http.MultipartFile.fromPath(
          'file${String.fromCharCode(65 + i)}',
          imageFiles[i]!.path,
        );

        request.files.add(pic);

        var response = await request.send();

        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final decoded = json.decode(respStr);

          if (decoded['status'] == 'success') {
            final filename = decoded['file_name'];
            if (filename != null && filename.isNotEmpty) {
              setState(() {
                _textControllers[i].text = filename;
              });
            }
          }
        }
        else {
          print('Failed to upload image ${i + 1}');
        }
      }
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
      _uploadImages(_imageFiles)
          .then((_) {
            Navigator.pop(context, {
              'contractno': widget.contractno,
              'pica': _textControllers[0].text,
              'picb': _textControllers[1].text,
              'picc': _textControllers[2].text,
              'picd': _textControllers[3].text,
              'pice': _textControllers[4].text,
              'picf': _textControllers[5].text,
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
                itemCount: _imageFiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final imageFile = _imageFiles[index];
                  return Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('เลือกแหล่งที่มาของภาพ'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          _pickImage(index, ImageSource.camera);
                                          Navigator.pop(context);
                                        },
                                        child: Text('ถ่ายรูป'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _pickImage(
                                            index,
                                            ImageSource.gallery,
                                          );
                                          Navigator.pop(context);
                                        },
                                        child: Text('เลือกจากแกลเลอรี่'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              border:
                                  imageFile != null
                                      ? Border.all(
                                        color: Colors.green,
                                        width: 3,
                                      )
                                      : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(2, 4),
                                ),
                              ],
                              image:
                                  imageFile != null
                                      ? DecorationImage(
                                        image: FileImage(imageFile),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child: Stack(
                              children: [
                                if (imageFile == null)
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_rounded,
                                          size: 40,
                                          color: yellow,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'กดเพื่อถ่ายรูปหรือเลือกภาพจากแกลเลอรี่',
                                          style: GoogleFonts.prompt(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (imageFile != null) ...[
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent.shade700,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      TextField(
                        controller: _textControllers[index],
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(fontSize: 14),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'ชื่อไฟล์ภาพ',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _saveImagesAndReturn,
              icon: Icon(Icons.save),
              label: Text('บันทึกรูป', style: GoogleFonts.prompt(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

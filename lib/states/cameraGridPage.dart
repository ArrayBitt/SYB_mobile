import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class CameraGridPage extends StatefulWidget {
  final String contractno;
  const CameraGridPage({Key? key, required this.contractno}) : super(key: key);

  @override
  State<CameraGridPage> createState() => _CameraGridPageState();
}

class _CameraGridPageState extends State<CameraGridPage> {
  final ImagePicker _picker = ImagePicker();
  List<File?> _imageFiles = List.generate(6, (index) => null);

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Request permissions for storage
  Future<void> _requestPermissions() async {
    var status = await Permission.storage.request();
    if (status.isDenied) {
      print("Storage permission denied");
      // You can show a dialog or message asking the user to allow permissions
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
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โปรดให้สิทธิ์การเข้าถึง Storage')),
      );
    }
  }

  Future<void> _uploadImages(List<File?> imageFiles) async {
    final uri = Uri.parse(
      'https://ppw.somjai.app/PPWSJ/api/appfollowup/picupload_api.php',
    );

    for (int i = 0; i < imageFiles.length; i++) {
      if (imageFiles[i] != null) {
        var request = http.MultipartRequest('POST', uri);
        request.fields['contractno'] = widget.contractno;

        var pic = await http.MultipartFile.fromPath(
          'image', // ใช้ key เดียวกับที่ Postman ใช้
          imageFiles[i]!.path,
        );

        request.files.add(pic);

        var response = await request.send();

        if (response.statusCode == 200) {
          print('Image ${i + 1} uploaded successfully');
        } else {
          print('Failed to upload image ${i + 1}: ${response.statusCode}');
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
      print('Sending data to SaveRushPage');
      print('Contract No: ${widget.contractno}');
      print('File Names: $fileNames');

      _uploadImages(_imageFiles)
          .then((_) {
            Navigator.pop(context, {
              'contractno': widget.contractno,
              'filenames': fileNames,
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
                  return GestureDetector(
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
                                    _pickImage(index, ImageSource.gallery);
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
                                ? Border.all(color: Colors.green, width: 3)
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                color: Colors.black54,
                                child: Text(
                                  'แตะอีกครั้งเพื่อถ่ายใหม่',
                                  style: GoogleFonts.prompt(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
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

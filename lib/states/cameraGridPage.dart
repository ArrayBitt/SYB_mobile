import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraGridPage extends StatefulWidget {
  const CameraGridPage({Key? key}) : super(key: key);

  @override
  State<CameraGridPage> createState() => _CameraGridPageState();
}

class _CameraGridPageState extends State<CameraGridPage> {
  final ImagePicker _picker = ImagePicker();
  List<File?> _imageFiles = List.generate(6, (index) => null);

  final List<String> _dropdownItems = [
    'ภาพสินค้าหลักประกัน',
    'ภาพเอกสาร',
    'ภาพสถานที่',
    'ภาพอื่น ๆ',
  ];
  String? _selectedItem;

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFiles[index] = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('📷 ภาพถ่าย', style: GoogleFonts.prompt()),
        backgroundColor: yellow,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedItem,
              decoration: InputDecoration(
                labelText: 'เลือกประเภทภาพ',
                labelStyle: GoogleFonts.prompt(),
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items:
                  _dropdownItems
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, style: GoogleFonts.prompt()),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedItem = value;
                });
              },
            ),
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
                    onTap: () => _pickImage(index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
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
                          // ถ้ายังไม่มีภาพ แสดงไอคอน + ข้อความ
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
                                    'กดเพื่อถ่ายรูป',
                                    style: GoogleFonts.prompt(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Label "รูป 1", "รูป 2", ...
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'รูป ${index + 1}',
                                style: GoogleFonts.prompt(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          // ถ้ามีภาพ แสดงข้อความล่าง
                          if (imageFile != null)
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

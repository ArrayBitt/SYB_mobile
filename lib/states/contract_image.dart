import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ContractImagePage extends StatefulWidget {
  final String contractNo;

  const ContractImagePage({Key? key, required this.contractNo})
    : super(key: key);

  @override
  _ContractImagePageState createState() => _ContractImagePageState();
}

class _ContractImagePageState extends State<ContractImagePage> {
  String? _selectedDocumentType;
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
  }

  void _getImagesByType(String documentType) async {
    final url =
        'https://ss.cjk-cr.com/CJK/api/appfollowup/get_cjk_image.php?contractno=${widget.contractNo}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Map<String, dynamic>> filteredImages = [];

        if (data is List) {
          for (var item in data) {
            if (item['images'] != null) {
              for (var imgUrl in item['images']) {
                final imageName = imgUrl.split('/').last;

                // กรองภาพโดยใช้ประเภทเอกสาร เช่น '-10', '-11'
                if (imageName.contains('$documentType.')) {
                  filteredImages.add({
                    'image_url': imgUrl,
                    'image_name': imageName,
                  });
                }
              }
            }
          }

          setState(() {
            _images = filteredImages;
          });
        } else {
          setState(() {
            _images = [];
          });
        }
      } else {
        print('Failed to load data');
        setState(() {
          _images = [];
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _images = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.prompt(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('📷 ภาพสัญญา: ${widget.contractNo}', style: headerStyle),
        backgroundColor: Colors.teal,
        elevation: 5,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDocumentType,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'เลือกประเภทเอกสาร',
                labelStyle: GoogleFonts.prompt(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDocumentType = newValue;
                });
                if (newValue != null) {
                  _getImagesByType(newValue);
                }
              },
              items:
                  <String>[
                    '01.1',
                    '10', // รูปถ่ายคนซื้อ
                    '11', // รูปถ่ายคนใช้
                    '12', // รูปถ่ายคนค้ำ
                    '13', // รูปถ่ายอาชีพ
                  ].map<DropdownMenuItem<String>>((value) {
                    String label = '';
                    switch (value) {
                       case '01.1':
                        label = 'บปช.';
                        break;
                      case '10':
                        label = 'รูปถ่ายคนซื้อ';
                        break;
                      case '11':
                        label = 'รูปถ่ายคนใช้';
                        break;
                      case '12':
                        label = 'รูปถ่ายคนค้ำ';
                        break;
                      case '13':
                        label = 'รูปถ่ายอาชีพ';
                        break;
                    }
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(label, style: GoogleFonts.prompt()),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _images.isEmpty
                      ? Center(
                        child: Text(
                          'ไม่พบรูปภาพในระบบ',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                              shadowColor: Colors.black38,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                 ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child: Image.network(
                                      image['image_url'] != null
                                          ? image['image_url']
                                          : '', // เช็คว่าไม่เป็น null ก่อน
                                      height: 800,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      image['image_name'] != null
                                          ? image['image_name']
                                          : '', // เช็คว่าไม่เป็น null ก่อน
                                      style: GoogleFonts.prompt(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal[800],
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

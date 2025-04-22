import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // เพิ่มการ import สำหรับการแปลงวันที่
import 'package:test_app/states/cameraGridPage.dart';

class SaveRushPage extends StatefulWidget {
  final String contractNo;
  final String hpprice;

  const SaveRushPage({
    Key? key,
    required this.contractNo,
    required this.hpprice,
  }) : super(key: key);

  @override
  _SaveRushPageState createState() => _SaveRushPageState();
}

class _SaveRushPageState extends State<SaveRushPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _followFeeController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  int _selectedIndex = 0;
  bool _isSaving = false;

  bool _loadingFollowTypes = true;
  List<Map<String, String>> _followTypes = [];
  String? _selectedFollowType;

  // ✅ เพิ่มตรงนี้ เพื่อเก็บชื่อไฟล์รูปจากกล้อง
  List<String?> imageFilenames = List.filled(6, null);

  @override
  void initState() {
    super.initState();
    _fetchFollowTypes();
  }

  String formatThaiDate(String input) {
    try {
      final parts = input.split('/'); // ['18','03','2568']
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0'); // '18'
        final month = parts[1].padLeft(2, '0'); // '03'
        final year = parts[2].padLeft(4, '0'); // '2568'

        return '$year$month$day'; // คืนเป็น '25680318'
      }
    } catch (e) {
      print('Error in date format: $e');
    }
    return input; // fallback ถ้ารูปแบบไม่ถูกต้อง
  }

  Future<void> _fetchFollowTypes() async {
    const url =
        'https://ppw.somjai.app/PPWSJ/api/appfollowup/get_followtype.php?followtype=M-1';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _followTypes =
              data
                  .map<Map<String, String>>(
                    (item) => {
                      'code': item['followtype'].toString(),
                      'label': item['meaning'].toString(),
                    },
                  )
                  .toList();
          _loadingFollowTypes = false;
        });
      } else {
        setState(() => _loadingFollowTypes = false);
      }
    } catch (_) {
      setState(() => _loadingFollowTypes = false);
    }
  }

  Future<bool> _saveRush() async {
    final String url =
        'https://ppw.somjai.app/PPWSJ/api/appfollowup/up_saverush.php?contractno=${widget.contractNo}';

    final data = {
      'contractno': widget.contractNo,
      'memo': _noteController.text,
      'followtype': _selectedFollowType ?? '',
      'meetingdate': formatThaiDate(_dueDateController.text), // ใช้แปลงวันที่
      'meetingamount': _amountController.text,
      'followamount': _followFeeController.text,
      'mileages': _mileageController.text,
      'maplocations': _locationController.text,
      'pica': imageFilenames.length > 0 ? imageFilenames[0] : '',
      'picb': imageFilenames.length > 1 ? imageFilenames[1] : '',
      'picc': imageFilenames.length > 2 ? imageFilenames[2] : '',
      'picd': imageFilenames.length > 3 ? imageFilenames[3] : '',
      'pice': imageFilenames.length > 4 ? imageFilenames[4] : '',
      'picf': imageFilenames.length > 5 ? imageFilenames[5] : '',
    };

    print('📤 ส่งข้อมูลไปยัง: $url');
    print('📦 Payload: $data');

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      print('📥 Response Code: ${res.statusCode}');
      print('📥 Response Body: ${res.body}');

      return res.statusCode == 200;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดขณะส่งข้อมูล: $e');
      return false;
    }
  }

  void _submitForm() async {
    print('เริ่มบันทึกข้อมูล...');

    if (_selectedFollowType == null) {
      print('ยังไม่ได้เลือกประเภทการตาม');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('กรุณาเลือกประเภทการตาม')));
      return;
    }

    // ✅ ตรวจสอบว่ามีการถ่ายภาพอย่างน้อย 1 ภาพ
    final hasAtLeastOneImage = imageFilenames.any(
      (filename) => filename != null && filename.trim().isNotEmpty,
    );

    if (!_formKey.currentState!.validate()) {
      print('Form validation ไม่ผ่าน');
      return;
    }

    setState(() => _isSaving = true);
    final success = await _saveRush();
    setState(() => _isSaving = false);

    print('บันทึกสำเร็จหรือไม่: $success');

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ โปรดลองใหม่')));
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder:
            (BuildContext dialogContext) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'บันทึกสำเร็จ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    _buildInfoRow('ข้อความ', _noteController.text),
                    _buildInfoRow(
                      'ประเภทการตาม',
                      _followTypes.firstWhere(
                        (e) => e['code'] == _selectedFollowType,
                      )['label']!,
                    ),
                    _buildInfoRow('วันนัดชำระ', _dueDateController.text),
                    _buildInfoRow('จำนวนเงิน', _amountController.text),
                    _buildInfoRow('ค่าติดตาม', _followFeeController.text),
                    _buildInfoRow('ระยะไมล์', _mileageController.text),
                    _buildInfoRow('สถานที่', _locationController.text),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(Icons.check),
                      label: Text('ตกลง', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    });
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        _submitForm(); // เรียกบันทึกข้อมูล
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraGridPage(contractno: widget.contractNo),
          ),
        ).then((result) {
          if (result != null && result is Map) {
            setState(() {
              // รับค่าที่ส่งกลับจาก CameraGridPage
              imageFilenames = [
                result['pica'],
                result['picb'],
                result['picc'],
                result['picd'],
                result['pice'],
                result['picf'],
              ];
            });
          }
        });
        break;
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator, // 👈 เพิ่มบรรทัดนี้
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.prompt(),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.amber.shade800),
          labelText: label,
          labelStyle: GoogleFonts.prompt(color: Colors.grey.shade800),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.amber.shade800, width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'กรุณากรอก $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber.shade700;
    final grey = Colors.grey.shade900;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('📋 ระบบจัดเก็บเร่งรัด', style: GoogleFonts.prompt()),
        backgroundColor: yellow,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Card(
                    color: Colors.amber.shade50,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.receipt_long, color: grey),
                      title: Text(
                        'เลขสัญญา: ${widget.contractNo}',
                        style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'ยอดจัด: ${widget.hpprice} บาท',
                        style: GoogleFonts.prompt(),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'ข้อความ',
                    icon: Icons.notes,
                    controller: _noteController,
                    maxLines: 3,
                  ),
                  _loadingFollowTypes
                      ? CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'ประเภทการตาม',
                          labelStyle: GoogleFonts.prompt(color: grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: yellow, width: 1.5),
                          ),
                        ),
                        items:
                            _followTypes.map((followType) {
                              return DropdownMenuItem<String>(
                                value: followType['code'],
                                child: Text(followType['label']!),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedFollowType = value);
                        },
                      ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'วันนัดชำระ',
                    icon: Icons.date_range,
                    controller: _dueDateController,
                    keyboardType: TextInputType.datetime,
                  ),
                  _buildTextField(
                    label: 'จำนวนเงิน',
                    icon: Icons.money,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'ค่าติดตาม',
                    icon: Icons.attach_money,
                    controller: _followFeeController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'ระยะไมล์',
                    icon: Icons.location_on,
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'สถานที่',
                    icon: Icons.location_on,
                    controller: _locationController,
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.save),
            label: 'บันทึก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'ถ่ายภาพ',
          ),
        ],
      ),
    );
  }
}

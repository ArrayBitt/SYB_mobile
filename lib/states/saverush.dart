import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // เพิ่มการ import สำหรับการแปลงวันที่
import 'package:cjk/states/cameraGridPage.dart';

class SaveRushPage extends StatefulWidget {
  final String contractNo;
  final String hpprice;
  final String username;

  const SaveRushPage({
    Key? key,
    required this.contractNo,
    required this.hpprice,
    required this.username,
  }) : super(key: key);

  @override
  _SaveRushPageState createState() => _SaveRushPageState();
}

class _SaveRushPageState extends State<SaveRushPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPersonType;
  String fperson = ''; // เก็บค่าประเภทบุคคลที่เลือกหรือกรอกเอง
  bool _isOtherPerson = false;
  TextEditingController _otherPersonController = TextEditingController();

  String? _selectedaddressType;
  String faddress = '';
  bool _isOtherAdress = false;
  TextEditingController _otherAdressController = TextEditingController();

  String? _selectedfdatacarType;
  String fdatacar = '';
  bool _isOtherDatacar = false;
  TextEditingController _otherDatacarController = TextEditingController();


  String? _selectedareaType;
  String farea = '';
  bool _isOtherArea = false;
  TextEditingController _otherAreaController = TextEditingController();

  String? _selectedproperType;
  String fproperty = '';
  bool _isOtherProperty = false;
  TextEditingController _otherPropertyController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _followFeeController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // ฟังก์ชันแปลงวันที่จาก ค.ศ. เป็น พ.ศ.
  String convertToThaiDate(DateTime date) {
    int year = date.year + 543; // เพิ่ม 543 ปี
    return DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime(year, date.month, date.day));
  }

  String getStatusText(bool status) {
    return status ? 'สำเร็จ' : 'รอดำเนินการ';
  }

  // ฟังก์ชันสำหรับเลือกวันที่
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dueDateController.text = convertToThaiDate(picked);
      });
    }
  }

  int _selectedIndex = 0;
  bool _isSaving = false;
  bool _isCompleted = false;

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
    // const url = 'https://ss.cjk-cr.com/CJK/api/appfollowup/get_followtype.php?followtype=M-1';

    const url =
        'http://192.168.1.15/CJKTRAINING/api/appfollowup/get_followtype.php?followtype=M-1';

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

  Future<void> _getCurrentLocationAndSetAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าเปิด location service หรือยัง
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // แจ้งเตือนให้เปิด GPS
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('กรุณาเปิด GPS')));
      return;
    }

    // ขอสิทธิ์เข้าถึง location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่ได้รับสิทธิ์ใช้งาน GPS')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สิทธิ์การใช้งาน GPS ถูกปฏิเสธถาวร')),
      );
      return;
    }

    // ดึงตำแหน่งพิกัด
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // แปลงพิกัดเป็นชื่อสถานที่
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String address =
          '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';

      _locationController.text = address.trim();
    }
  }

  Future<bool> _saveRush() async {
    DateTime now = DateTime.now();
    String entryDate =
        '${now.year + 543}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    String timeUpdate = DateFormat('HH:mm:ss').format(now);

    double? latitude;
    double? longitude;

    String fperson =
        _isOtherPerson
            ? _otherPersonController.text
            : (_selectedPersonType ?? '');

    String faddress =
        _isOtherAdress
            ? _otherAdressController.text
            : (_selectedaddressType ?? '');

    String fdatacar =
        _isOtherDatacar
            ? _otherDatacarController.text
            : (_selectedfdatacarType ?? '');


     String farea =
        _isOtherArea
            ? _otherAreaController.text
            : (_selectedareaType ?? '');


              String fproperty =
        _isOtherProperty
            ? _otherPropertyController.text
            : (_selectedproperType ?? '');

    // ✅ ดึงตำแหน่งปัจจุบัน
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      print('⚠️ ไม่สามารถดึงตำแหน่งได้: $e');
    }

    final String url =
        'https://ss.cjk-cr.com/CJK/api/appfollowup/up_saverush.php?contractno=${widget.contractNo}';

    final data = {
      'contractno': widget.contractNo,
      'memo': _noteController.text,
      'followtype': _selectedFollowType ?? '',
      'meetingdate': formatThaiDate(_dueDateController.text),
      'entrydate': entryDate,
      'timeupdate': timeUpdate,
      'meetingamount': _amountController.text,
      'followamount': _followFeeController.text,
      'mileages': _mileageController.text,
      'maplocations': locationController.text,
      'checkrush': _isCompleted.toString(),
      'latitude': latitude?.toString() ?? '',
      'longtitude': longitude?.toString() ?? '',
      'fperson': fperson,
      'faddress': faddress,
      'fdatacar': fdatacar,
      'farea': farea,
      'fproperty': fproperty,
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

      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);
        if (responseData['status'] == 'success') {
          return true;
        } else {
          final msg = responseData['message'] ?? 'เกิดข้อผิดพลาดในการบันทึก';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('การเชื่อมต่อกับเซิร์ฟเวอร์ล้มเหลว')),
        );
        return false;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดขณะส่งข้อมูล: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
                child: ListView(
                   padding: EdgeInsets.all(16),
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

                    _buildInfoRow('เลขที่สัญญา', widget.contractNo),
                    _buildInfoRow('ประเภทบุคคล', fperson),
                    _buildInfoRow('ที่อยู่ติดตาม', faddress),
                    _buildInfoRow('ข้อมูลรถ', fdatacar),
                    _buildInfoRow('ผลการลงพื้นที่', farea),
                    _buildInfoRow('ผลทรัพย์สิน', fproperty),
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
                    _buildInfoRow('สถานที่', locationController.text),
                    _buildInfoRow('สถานะการดำเนินการ',getStatusText(_isCompleted), ),

                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final amount = _amountController.text.trim();
                        final followFee = _followFeeController.text.trim();

                        // ตรวจสอบว่ามีทศนิยม 2 ตำแหน่งเท่านั้น
                        final regex = RegExp(r'^\d+\.\d{2}$');

                        if (!regex.hasMatch(amount) ||
                            !regex.hasMatch(followFee)) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                backgroundColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                title: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'บันทึกสำเร็จ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  'ข้อมูลถูกบันทึกเรียบร้อย',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      'ตกลง',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          return; // ยกเลิกการส่งฟอร์ม
                        }

                        if (_formKey.currentState!.validate()) {
                          // ... ทำการ submit ตามเดิม
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text('บันทึกข้อมูล'),
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
          if (result != null && result is Map<String, String>) {
            setState(() {
              // รับค่าที่ส่งกลับมาและเก็บไว้ใน imageFilenames
              imageFilenames = [
                result['pica'] ?? '',
                result['picb'] ?? '',
                result['picc'] ?? '',
                result['picd'] ?? '',
                result['pice'] ?? '',
                result['picf'] ?? '',
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
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
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
          suffixIcon: suffixIcon,
        ),
        validator:
            validator ??
            (value) {
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
    final grey = Colors.grey.shade300;

    List<String> personTypes = [
      'ผู้เช่าซื้อ',
      'ผู้ค้ำประกัน',
      'คนใช้รถ',
      'ผู้ซื้อร่วม',
      'อื่นๆ',
    ];

    List<String> adressTypes = [
      'ที่อยู่ปัจจุบัน',
      'ที่อยู่ตามทะเบียนราฎ',
      'ที่ทำงาน',
      'อื่นๆ',
    ];

     List<String> datacarTypes = [
      'พบรถ',
      'ไม่พบรถ',
      'รถใช้นอกพื้นที่',
      'รถจำนำ/ขาย',
      'รถพังเสียหายไม่สามารถรับคืนได้',
      'อื่นๆ',
    ];


      List<String> fareaTypes = [
      'นัดชำระ',
      'ติดตามต่อ',
      'ส่งต่อสายงานอื่น',
      'รถจำนำ/ขาย',
      'ส่งเรื่องฝ่ายกฎหมาย',
      'อื่นๆ',
    ];


    List<String> fproperTypes = [
      'ไม่มีทรัพย์สิน',
      'มีทรัพย์สิน',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: yellow,
        title: Text(
          'บันทึกข้อมูลการตามหนี้',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  //_selectedPersonType
                  DropdownButtonFormField<String>(
                    value: _isOtherPerson ? 'อื่นๆ' : _selectedPersonType,
                    items:
                        personTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPersonType = value;
                        if (value == 'อื่นๆ') {
                          _isOtherPerson = true;
                          _otherPersonController.text = '';
                          fperson = ''; // เคลียร์ค่า fperson ก่อนกรอกใหม่
                        } else {
                          _isOtherPerson = false;
                          fperson =
                              value ??
                              ''; // **อัพเดต fperson ให้เท่ากับค่าที่เลือก**
                        }
                      });
                    },

                    decoration: InputDecoration(
                      labelText: 'ประเภทบุคคล',
                      labelStyle: GoogleFonts.prompt(
                        color: Colors.amber.shade700,
                      ),
                      prefixIcon: Icon(Icons.person, color: yellow),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  if (_isOtherPerson) ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _otherPersonController,
                      decoration: InputDecoration(
                        labelText: 'กรุณาระบุประเภทบุคคล',
                        prefixIcon: Icon(Icons.edit, color: yellow),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: yellow, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          fperson = val;
                          print('กรอกอื่นๆ: $fperson');
                        });
                      },
                      validator: (value) {
                        if (_isOtherPerson &&
                            (value == null || value.isEmpty)) {
                          return 'กรุณาระบุประเภทบุคคล';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 12),

                  //_selectedPersonType

                  //_selectedaddressType
                  DropdownButtonFormField<String>(
                    value: _isOtherAdress ? 'อื่นๆ' : _selectedaddressType,
                    items:
                        adressTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedaddressType = value;
                        if (value == 'อื่นๆ') {
                          _isOtherAdress = true;
                          _otherAdressController.text = '';
                          faddress = ''; // เคลียร์ค่า faddress
                        } else {
                          _isOtherAdress = false;
                          faddress = value ?? ''; // ← ตรงนี้ควรอัปเดต faddress
                        }
                      });
                    },

                    decoration: InputDecoration(
                      labelText: 'ที่อยู่ติดตาม',
                      labelStyle: GoogleFonts.prompt(
                        color: Colors.amber.shade700,
                      ),
                      prefixIcon: Icon(Icons.add_reaction_sharp, color: yellow),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  if (_isOtherAdress) ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _otherAdressController,
                      decoration: InputDecoration(
                        labelText: 'กรุณาระบุที่อยู่ติดตาม',
                        prefixIcon: Icon(Icons.edit, color: yellow),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: yellow, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          faddress = val;
                          print('กรอกอื่นๆ ที่อยู่ติดตาม: $faddress');
                        });
                      },

                      validator: (value) {
                        if (_isOtherAdress &&
                            (value == null || value.isEmpty)) {
                          return 'กรุณาระบุประเภทบุคคล';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 12),

                  //datacar

                   DropdownButtonFormField<String>(
                    value: _isOtherAdress ? 'อื่นๆ' : _selectedfdatacarType,
                    items:
                        datacarTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedfdatacarType = value;
                        if (value == 'อื่นๆ') {
                          _isOtherDatacar = true;
                          _otherDatacarController.text = '';
                          fdatacar = ''; // เคลียร์ค่า fdatacar
                        } else {
                          _isOtherDatacar = false;
                          fdatacar = value ?? ''; // ← ตรงนี้ควรอัปเดต fdatacar
                        }
                      });
                    },

                    decoration: InputDecoration(
                      labelText: 'ข้อมูลรถ',
                      labelStyle: GoogleFonts.prompt(
                        color: Colors.amber.shade700,
                      ),
                      prefixIcon: Icon(Icons.car_crash, color: yellow),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  if (_isOtherDatacar) ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _otherDatacarController,
                      decoration: InputDecoration(
                        labelText: 'กรุณาระบุข้อมูลรถ',
                        prefixIcon: Icon(Icons.edit, color: yellow),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: yellow, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          fdatacar = val;
                          print('กรอกอื่นๆ  ข้อมูลรถ: $fdatacar');
                        });
                      },

                      validator: (value) {
                        if (_isOtherDatacar &&
                            (value == null || value.isEmpty)) {
                          return 'กรุณาระบุประข้อมูลรถ';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 12),

                  //area

                  DropdownButtonFormField<String>(
                    value:  _isOtherArea? 'อื่นๆ' : _selectedareaType,
                    items:
                        fareaTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedareaType = value;
                        if (value == 'อื่นๆ') {
                          _isOtherArea = true;
                          _otherAreaController.text = '';
                          farea = ''; // เคลียร์ค่า farea
                        } else {
                          _isOtherArea = false;
                          farea = value ?? ''; // ← ตรงนี้ควรอัปเดต farea
                        }
                      });
                    },

                    decoration: InputDecoration(
                      labelText: 'ผลการลงพื้นที่',
                      labelStyle: GoogleFonts.prompt(
                        color: Colors.amber.shade700,
                      ),
                      prefixIcon: Icon(Icons.area_chart, color: yellow),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  if (_isOtherArea) ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _otherAreaController,
                      decoration: InputDecoration(
                        labelText: 'กรุณาระบุผลการลงพื้นที่',
                        prefixIcon: Icon(Icons.edit, color: yellow),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: yellow, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          farea = val;
                          print('กรอกอื่นๆ ผลการลงพื้นที่: $farea');
                        });
                      },

                      validator: (value) {
                        if (_isOtherArea &&
                            (value == null || value.isEmpty)) {
                          return 'กรุณาระบุประผลการลงพื้นที่';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 12),

                  //fproperty
                    DropdownButtonFormField<String>(
                    value: _isOtherProperty ? 'มีทรัพย์สิน' : _selectedproperType,
                    items:
                        fproperTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedproperType = value;
                        if (value == 'มีทรัพย์สิน') {
                          _isOtherProperty = true;
                          _otherPropertyController.text = '';
                          fproperty = ''; // เคลียร์ค่า fproperty
                        } else {
                          _isOtherProperty = false;
                          fproperty = value ?? ''; // ← ตรงนี้ควรอัปเดต fproperty
                        }
                      });
                    },

                    decoration: InputDecoration(
                      labelText: 'ผลทรัพย์สิน',
                      labelStyle: GoogleFonts.prompt(
                        color: Colors.amber.shade700,
                      ),
                      prefixIcon: Icon(Icons.money_off, color: yellow),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  if (_isOtherProperty) ...[
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _otherPropertyController,
                      decoration: InputDecoration(
                        labelText: 'กรุณาระบุทรัพย์สิน',
                        prefixIcon: Icon(Icons.edit, color: yellow),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: yellow, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          fproperty = val;
                          print('มีทรัพย์สิน: $fproperty');
                        });
                      },

                      validator: (value) {
                        if (_isOtherProperty && (value == null || value.isEmpty)) {
                          return 'กรุณาระบุประทรัพย์สิน';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 12),

                  //_selectedaddressType
                  _buildTextField(
                    label: 'ข้อความ',
                    icon: Icons.note,
                    controller: _noteController,
                    maxLines: 3,
                    validator:
                        (value) => value!.isEmpty ? 'กรุณากรอกหมายเหตุ' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedFollowType,
                    items:
                        _followTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['code'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFollowType = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'ประเภทการตาม',
                      labelStyle: GoogleFonts.prompt(color: Colors.black),
                      prefixIcon: Icon(
                        Icons.assignment_turned_in,
                        color: yellow,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _dueDateController,
                    decoration: InputDecoration(
                      labelText: 'วันที่นัดชำระ',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color:
                            _dueDateController.text.isEmpty
                                ? Colors.orange
                                : Colors.orange, // ไอคอนจะเป็นสีส้มถ้าเลือกแล้ว
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade300, // สีขอบเมื่อไม่ได้เลือก
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.orange, // สีขอบเมื่อมีโฟกัส
                          width: 2.0,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color:
                            _dueDateController.text.isEmpty
                                ? const Color.fromARGB(255, 15, 15, 15)
                                : Colors.orange, // สีตัวอักษรของ label
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    label: 'จำนวนเงิน',
                    icon: Icons.money,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกจำนวนเงิน';
                      }
                      if (!RegExp(r'^\d+\.00$').hasMatch(value)) {
                        return 'จำนวนเงินต้องลงท้ายด้วย .00';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'ค่าติดตาม',
                    icon: Icons.attach_money,
                    controller: _followFeeController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกค่าติดตาม';
                      }
                      if (!RegExp(r'^\d+\.00$').hasMatch(value)) {
                        return 'ค่าติดตามต้องลงท้ายด้วย .00';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'ระยะไมล์',
                    icon: Icons.directions_car,
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'สถานที่',
                    icon: Icons.location_on,
                    controller: locationController,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.location_on),
                      onPressed: () async {
                        try {
                          // ขอ permission
                          LocationPermission permission =
                              await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                            if (permission == LocationPermission.denied ||
                                permission ==
                                    LocationPermission.deniedForever) {
                              print('Permission denied');
                              return;
                            }
                          }

                          // ตรวจสอบว่าเปิด Location Service อยู่ไหม
                          bool serviceEnabled =
                              await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) {
                            print('Location service disabled');
                            return;
                          }

                          // ดึงพิกัด
                          Position position =
                              await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );

                          double latitude = position.latitude;
                          double longitude = position.longitude;
                          print('latitude: $latitude, longtitude: $longitude');

                          // ดึงข้อมูลที่อยู่
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                                latitude,
                                longitude,
                                localeIdentifier: "th", // ใช้ locale ภาษาไทย
                              );

                          if (placemarks.isNotEmpty) {
                            Placemark place = placemarks.first;

                            print('locality: ${place.locality}');
                            print(
                              'subAdministrativeArea: ${place.subAdministrativeArea}',
                            );
                            print(
                              'administrativeArea: ${place.administrativeArea}',
                            );
                            print('postalCode: ${place.postalCode}');
                            print('country: ${place.country}');

                            String placeName =
                                '${place.locality ?? ''} ${place.subAdministrativeArea ?? ''} '
                                '${place.administrativeArea ?? ''} ${place.postalCode ?? ''} ${place.country ?? ''}\n'
                                'ละติจูด: $latitude, ลองจิจูด: $longitude';

                            // เซ็ตข้อความลง TextField
                            locationController.text = placeName.trim();
                          }
                        } catch (e) {
                          print('เกิดข้อผิดพลาดในการดึงตำแหน่ง: $e');
                        }
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  DropdownButtonFormField<bool>(
                    value: _isCompleted,
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('รอดำเนินการ'),
                      ),
                      DropdownMenuItem(value: true, child: Text('สำเร็จ')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isCompleted = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'สถานะการดำเนินการ',
                      labelStyle: GoogleFonts.prompt(color: Colors.black),
                      prefixIcon: Icon(
                        Icons.check_circle_outline,
                        color: yellow,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: yellow, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.prompt(),
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (!_isSaving) {
            _onItemTapped(index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'บันทึก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'ถ่ายภาพ',
          ),
        ],
      ),
    );
  }
}

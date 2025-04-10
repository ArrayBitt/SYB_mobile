import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // เพิ่มการนำเข้า intl
import 'package:test_app/states/authen.dart';

class MainMobile extends StatefulWidget {
  final String username;
  MainMobile({required this.username}); // รับ username จาก AuthenPage

  @override
  _MainMobileState createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  int _selectedIndex = 0;
  dynamic _data; // ประกาศตัวแปร _data เพื่อเก็บข้อมูลจาก API
  bool _isLoading = false; // ตัวแปรเช็คสถานะการโหลดข้อมูล

  static const List<Widget> _widgetOptions = <Widget>[
    Center(
      child: Text(
        'หน้าหลัก',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ),
    Center(
      child: Text(
        'ค้นหา',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ),
    Center(
      child: Text(
        'โปรไฟล์',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ),
  ];

  Future<void> _fetchData() async {
    final username = widget.username; // รับค่าจาก MainMobile
    final url =
        'https://ppw.somjai.app/PPWSJ/api/appfollowup/contract_api.php?username=${widget.username}';
    // URL API ของคุณ

    setState(() {
      _isLoading = true; // ตั้งสถานะการโหลดข้อมูลเป็น true
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'username': username},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // ตรวจสอบว่า data เป็น List หรือ Map
        if (data is List) {
          setState(() {
            _data = data; // กำหนด _data เป็นข้อมูลจาก List
          });
        } else if (data is Map) {
          // ถ้าเป็น Map แสดงข้อผิดพลาดจาก API
          if (data.containsKey('error')) {
            _showError(data['error']); // แสดงข้อความข้อผิดพลาด
          } else {
            _showError('ข้อมูลไม่ถูกต้อง');
          }
        } else {
          _showError('ข้อมูลไม่ถูกต้อง');
        }
      } else {
        _showError('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false; // ปรับสถานะการโหลดเป็น false หลังจากเสร็จสิ้น
      });
    }
  }

  // ฟังก์ชันแสดงข้อผิดพลาด
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ข้อผิดพลาด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ตกลง',
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchData(); // เรียกใช้งานเมื่อหน้าถูกโหลดขึ้นมา
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 20,
      color: Colors.black87,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('ระบบจัดเก็บและเร่งรัด', style: titleStyle),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlue[100]!, Colors.pink[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child:
                      _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : _selectedIndex == 0
                          ? _data != null
                              ? ListView.builder(
                                itemCount: _data.length,
                                itemBuilder: (context, index) {
                                  // แปลงวันที่เป็น วัน/เดือน/ปี
                                  String formattedDate = _formatDate(
                                    _data[index]['contractdate'],
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        // เมื่อกดที่ Box จะเรียกแสดงรายละเอียดสัญญา
                                        _showContractDetails(
                                          context,
                                          _data[index],
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Contract No: ${_data[index]['contractno']}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Username: ${_data[index]['username']}',
                                            ),
                                            Text(
                                              'Contract Date: $formattedDate', // แสดงวันที่ที่แปลงแล้ว
                                            ),
                                            Text(
                                              'HP Price: ${_data[index]['hpprice']}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                              : Center(child: Text('ไม่พบข้อมูล'))
                          : _widgetOptions.elementAt(_selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // เปลี่ยนหน้าตามที่เลือก
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'ค้นหา'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  // ฟังก์ชันแปลงวันที่
  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(
        date,
      ); // แปลงจาก string เป็น DateTime
      return DateFormat(
        'dd/MM/yyyy',
      ).format(parsedDate); // แปลงเป็น วัน/เดือน/ปี
    } catch (e) {
      return date; // ถ้าเกิดข้อผิดพลาดจะคืนค่าเดิม
    }
  }
// ฟังก์ชันแสดงรายละเอียดสัญญาใน AlertDialog
  void _showContractDetails(BuildContext context, dynamic contract) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              '📋 รายละเอียดสัญญา',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('📄 Contract No:', contract['contractno']),
                _buildDetailRow('👤 Username:', contract['username']),
                _buildDetailRow(
                  '📅 Date:',
                  _formatDate(contract['contractdate']),
                ),
                _buildDetailRow('💰 HP Price:', contract['hpprice']),
              ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // ไปยังระบบจัดเก็บเร่งรัด
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
                child: Text(
                  '🚀 ระบบจัดเก็บเร่งรัด',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // ไปยังรายละเอียดสัญญา
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.teal.withOpacity(0.4),
                ),
                child: Text(
                  '📄 รายละเอียดสัญญา',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // แยก Widget สำหรับแถวรายละเอียด
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 6),
          Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }


  // ฟังก์ชันออกจากระบบ
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // ทำให้มุมมนขึ้น
          ),
          title: Center(
            child: Container(
              child: Text(
                'ออกจากระบบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          content: Text(
            'คุณต้องการออกจากระบบจริงๆ หรือไม่?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            // ปรับให้ปุ่มดูเรียบง่ายขึ้น
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ), // เว้นระยะให้ปุ่มห่างจากขอบ
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceEvenly, // จัดตำแหน่งปุ่มให้ห่างกันพอสมควร
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // ปิด dialog
                    },
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue, // สีที่ดูสบายตามากขึ้น
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // ปิด dialog
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => AuthenPage()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'ตกลง',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red, // สีที่เด่นขึ้น
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

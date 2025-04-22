import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_app/states/authen.dart';
import 'package:test_app/states/saverush.dart';
import 'package:test_app/states/show_contract.dart';
import 'package:url_launcher/url_launcher.dart';

class MainMobile extends StatefulWidget {
  final String username;
  MainMobile({required this.username});

  @override
  _MainMobileState createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  int _selectedIndex = 0;
  dynamic _data;
  bool _isLoading = false;
  TextEditingController _searchController =
      TextEditingController(); // Controller สำหรับค้นหา
  String _searchQuery = '';

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถโทรออกได้')));
    }
  }

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
    final username = widget.username;
    final url =
        'https://ppw.somjai.app/PPWSJ/api/appfollowup/contract_api.php?username=${widget.username}';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'username': username},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is List) {
          setState(() {
            _data = data;
          });
        } else if (data is Map) {
          if (data.containsKey('error')) {
            _showError(data['error']);
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
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ข้อผิดพลาด',
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: GoogleFonts.prompt(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ตกลง',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
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
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.prompt(
      fontSize: 20,
      color: Colors.black87,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        title: Text('ระบบจัดเก็บและเร่งรัด', style: titleStyle),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
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
                  colors: [Color(0xFFFFF8DC), Color(0xFFB0B0B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'ค้นหาจากเลขที่สัญญา',
                      hintText: 'กรอกเลขที่สัญญา',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : _data != null
                          ? RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              physics:
                                  AlwaysScrollableScrollPhysics(), // ให้สามารถเลื่อนแม้ list สั้น
                              itemCount: _data.length,
                              itemBuilder: (context, index) {
                                String contractNo = _data[index]['contractno'];
                                if (_searchQuery.isNotEmpty &&
                                    !contractNo.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    )) {
                                  return Container();
                                }

                                String formattedDate = _formatDate(
                                  _data[index]['contractdate'],
                                );

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap:
                                        () => _showContractDetails(
                                          context,
                                          _data[index],
                                        ),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 6,
                                      shadowColor: Colors.black26,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.description,
                                                  color: Colors.amber[800],
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'เลขที่สัญญา: $contractNo',
                                                  style: GoogleFonts.prompt(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            _buildDetailRow(
                                              'ผู้ใช้:',
                                              _data[index]['username'],
                                            ),
                                            _buildDetailRow(
                                              'วันที่ทำสัญญา:',
                                              formattedDate,
                                            ),
                                            _buildDetailRow(
                                              'ยอดผ่อน:',
                                              '${_data[index]['hpprice']} บาท',
                                            ),

                                            Row(
                                              children: [
                                                Text(
                                                  'เบอร์โทร:',
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                GestureDetector(
                                                  onTap:
                                                      () => _makePhoneCall(
                                                        _data[index]['mobileno'],
                                                      ),
                                                  child: Text(
                                                    _data[index]['mobileno'],
                                                    style: GoogleFonts.prompt(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.blue,
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            _buildDetailRow(
                                              'ที่อยู่:',
                                              '${_data[index]['addressis']}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : Center(child: Text('ไม่พบข้อมูล')),
                ),
              ],
            ),
          ),
        ],
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
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String buddhistYear = (parsedDate.year + 543).toString();
      return '$day/$month/$buddhistYear';
    } catch (e) {
      return date;
    }
  }

  void _showContractDetails(BuildContext context, dynamic contract) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'รายละเอียดสัญญา',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contract No: ${contract['contractno']}'),
              Text('Username: ${contract['username']}'),
              Text('Contract Date: ${_formatDate(contract['contractdate'])}'),
              Text('HP Price: ${contract['hpprice']}'),
              Text('MobileNumber : ${contract['mobileno']}'),
              Text('Address : ${contract['addressis']}'),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => SaveRushPage(
                            contractNo: contract['contractno'],
                            hpprice: contract['hpprice'],
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
                child: Text(
                  'ระบบจัดเก็บเร่งรัด',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ShowContractPage(
                            contractNo: contract['contractno'],
                          ),
                    ),
                  );
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
                  'รายละเอียดสัญญา',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.prompt(fontSize: 16)),
          SizedBox(width: 10),
          Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthenPage()),
      (Route<dynamic> route) => false,
    );
  }
}

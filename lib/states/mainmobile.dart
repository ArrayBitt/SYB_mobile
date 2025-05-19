import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cjk/states/authen.dart';
import 'package:cjk/states/saverush.dart';
import 'package:cjk/states/show_contract.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class MainMobile extends StatefulWidget {
  final String username;
  MainMobile({required this.username});

  @override
  _MainMobileState createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  List<List<dynamic>> _pagedData = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchData();
    }
  }

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

 Future<void> _fetchData() async {
    final username = widget.username;
    final url = 'https://ss.cjk-cr.com/CJK/api/appfollowup/contract_api.php?username=$username';

    //final url ='http://192.168.1.15/CJKTRAINING/api/appfollowup/contract_api.php?username=$username';

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
          final filtered =
              data.where((item) {
                final checkrush = item['checkrush'];
                print('checkrush: "$checkrush" (${checkrush.runtimeType})');

                if (checkrush == null) return true;

                final value = checkrush.toString().toLowerCase().trim();
                return value != 'true'; // กรองออกเฉพาะที่เป็น true เท่านั้น
              }).toList();

          print('จำนวนรายการหลังกรอง: ${filtered.length}');

          final chunked = _chunkData(filtered, 2500); // ถ้ามีฟังก์ชันแบ่งหน้า

          setState(() {
            _pagedData = chunked;
            _currentPage = 0;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(0);
            }
          });
        } else {
          _showError('ข้อมูลไม่ถูกต้อง');
        }
      } else {
        _showError('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  List<List<dynamic>> _chunkData(List<dynamic> data, int chunkSize) {
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < data.length; i += chunkSize) {
      chunks.add(data.sublist(i, min(i + chunkSize, data.length)));
    }
    return chunks;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'ข้อผิดพลาด',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.prompt()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'ตกลง',
                  style: GoogleFonts.prompt(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
    );
  }

  String formatDateToThaiDDMMYYYY(String? input) {
    if (input == null || input.length != 8) return 'ไม่ระบุ'; // กันความผิดพลาด

    try {
      String year = input.substring(0, 4);
      String month = input.substring(4, 6);
      String day = input.substring(6, 8);

      return '$day-$month-$year';
    } catch (e) {
      return 'ไม่ระบุ';
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
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contract No: ${contract['contractno']}'),
              Text('Username: ${contract['username'] ?? 'ไม่ระบุ'}'),
              Text(
                'Contract Date: ${formatDateToThaiDDMMYYYY(contract['contractdate'] ?? '')}',
              ),
              Text('HP Price: ${contract['hpprice'] ?? 'ไม่ระบุ'}'),
              Text('MobileNumber : ${contract['mobileno'] ?? 'ไม่ระบุ'}'),
              Text('Address : ${contract['addressis'] ?? 'ไม่ระบุ'}'),
            ],
          ),
          actions: [
            _buildDialogButton(
              context,
              label: 'ระบบจัดเก็บเร่งรัด',
              color: Colors.amber[800]!,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => SaveRushPage(
                          contractNo: contract['contractno'],
                          hpprice: contract['hpprice'],
                          username: contract['username'],
                        ),
                  ),
                );
              },
            ),
            _buildDialogButton(
              context,
              label: 'รายละเอียดสัญญา',
              color: Colors.teal,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => ShowContractPage(
                          contractNo: contract['contractno'],
                        ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
        ),
        child: Text(
          label,
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.prompt(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
      (route) => false,
    );
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
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'ค้นหาจากเลขที่สัญญา',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              _isLoading
                  ? Expanded(child: Center(child: CircularProgressIndicator()))
                  : _pagedData.isEmpty
                  ? Expanded(child: Center(child: Text('ไม่พบข้อมูล')))
                  : Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged:
                          (index) => setState(() => _currentPage = index),
                      itemCount: _pagedData.length,
                      itemBuilder: (context, pageIndex) {
                        final contracts =
                            _pagedData[pageIndex].where((contract) {
                              final contractNo =
                                  contract['contractno']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              final arName =
                                  contract['arname']?.toLowerCase() ?? '';
                              final checkrush = contract['checkrush'];

                              if (checkrush == null ||
                                  checkrush.toString().toLowerCase() !=
                                      'true') {
                                return _searchQuery.isEmpty ||
                                    contractNo.contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    arName.contains(_searchQuery.toLowerCase());
                              }
                              return false;
                            }).toList();

                        return RefreshIndicator(
                          onRefresh: _fetchData,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: contracts.length,
                            itemBuilder: (context, index) {
                              final contract = contracts[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap:
                                      () => _showContractDetails(
                                        context,
                                        contract,
                                      ),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 6,
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
                                                color: Colors.amber,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'เลขที่สัญญา: ${contract['contractno']}',
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
                                            contract['username'],
                                          ),
                                          _buildDetailRow(
                                            'ชื่อลูกค้า:',
                                            contract['arname'],
                                          ),
                                          _buildDetailRow(
                                            'วันที่ทำสัญญา:',
                                            formatDateToThaiDDMMYYYY(
                                              contract['contractdate']
                                                  as String?,
                                            ),
                                          ),
                                          _buildDetailRow(
                                            'ยอดผ่อน:',
                                            '${contract['hpprice']} บาท',
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
                                                      contract['mobileno'] ??
                                                          'ไม่ระบุ',
                                                    ),
                                                child: Text(
                                                  contract['mobileno'] ??
                                                      'ไม่ระบุ',
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
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
                                            contract['addressis'] ?? 'ไม่ระบุ',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              if (_pagedData.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      'หน้า ${_currentPage + 1} / ${_pagedData.length}',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.prompt(),
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
}

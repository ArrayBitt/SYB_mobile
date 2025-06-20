import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cjk/states/authen.dart';
import 'package:cjk/states/saverush.dart';
import 'package:cjk/states/show_contract.dart';
import 'package:url_launcher/url_launcher.dart';

class MainMobile extends StatefulWidget {
  final String username;
  MainMobile({required this.username});

  @override
  _MainMobileState createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> with WidgetsBindingObserver {
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
List<String?> videoFileNames = ['', '', '', '', '', ''];

  List<dynamic> _contracts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
  
   final username = widget.username;
  
   final url = 'https://ss.cjk-cr.com/CJK/api/appfollowup/contract_api.php?username=$username';
   
    //final url ='http://192.168.1.15/CJKTRAINING/api/appfollowup/contract_api.php?username=$username';
    

    setState(() {
      _isLoading = true;
      _contracts = [];
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
                if (checkrush == null) return true;
                final value = checkrush.toString().toLowerCase().trim();
                return value != 'true'; // กรองเฉพาะ checkrush != true
              }).toList();

          setState(() {
            _contracts = filtered;
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

 Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    print('>>> โทรออก: $launchUri');

    try {
      final result = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!result) {
        throw 'เปิดโทรศัพท์ไม่ได้';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถโทรออกได้: $e')));
    }
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
    if (input == null || input.length != 8) return 'ไม่ระบุ';

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey[50],
          title: Center(
            child: Text(
              '📄 รายละเอียดสัญญา',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.teal[800],
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('เลขที่สัญญา', contract['contractno']),
                _buildDetailRow(
                  'รหัสผู้ติดตาม',
                  contract['username'] ?? 'ไม่ระบุ',
                ),
                _buildDetailRow(
                  'วันที่ทำสัญญา',
                  formatDateToThaiDDMMYYYY(contract['contractdate'] ?? ''),
                ),
                _buildDetailRow('ยอดชำระ', contract['hpprice'] ?? 'ไม่ระบุ'),
                _buildDetailRow(
                  'หมายเหตุ',
                  contract['followremark'] ?? 'ไม่ระบุ',
                ),
                _buildDetailRow(
                  'เบอร์มือถือ',
                  contract['mobileno'] ?? 'ไม่ระบุ',
                ),
                _buildDetailRow('ที่อยู่', contract['addressis'] ?? 'ไม่ระบุ'),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              icon: Icon(Icons.assignment, color: Colors.white),
              label: Text('ระบบจัดเก็บเร่งรัด', style: GoogleFonts.prompt()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => SaveRushPage(
                          contractNo: contract['contractno'],
                          hpprice: contract['hpprice'],
                          username: contract['username'],
                          hpIntAmount: contract['hp_intamount'],
                          aMount408: contract['amount408'],
                          aRname: contract['arname'],
                          tranferdate: contract['tranferdate'],
                          estmdate: contract['estm_date'], 
                          videoFilenames: videoFileNames, 

                        ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.info_outline, color: Colors.white),
              label: Text('รายละเอียดสัญญา', style: GoogleFonts.prompt()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => ShowContractPage(
                          contractNo: contract['contractno'],
                          username: '',
                          hpprice: null,
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

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value, style: GoogleFonts.prompt())),
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

    List<dynamic> filteredContracts =
        _contracts.where((contract) {
          final contractNo =
              (contract['contractno'] ?? '').toString().toLowerCase();
          final arName = (contract['arname'] ?? '').toString().toLowerCase();
          final tAmbol = (contract['tambol'] ?? '').toString().toLowerCase();
          final amPhon = (contract['amphon'] ?? '').toString().toLowerCase();
          final proVince =
              (contract['province'] ?? '').toString().toLowerCase();
          if (_searchQuery.isEmpty) return true;
          return contractNo.contains(_searchQuery.toLowerCase()) ||
              arName.contains(_searchQuery.toLowerCase()) ||
              tAmbol.contains(_searchQuery.toLowerCase()) ||
              amPhon.contains(_searchQuery.toLowerCase()) ||
              proVince.contains(_searchQuery.toLowerCase());
        }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        title: Text('สัญญาเร่งรัด (V 1.8)', style: titleStyle),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.teal),
            tooltip: 'รีเฟรช',
            onPressed: _fetchData,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'ออกจากระบบ',
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'ค้นหาข้อมูลสัญญา',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child:
                        filteredContracts.isEmpty
                            ? Center(
                              child: Text(
                                'ไม่พบข้อมูล',
                                style: GoogleFonts.prompt(fontSize: 18),
                              ),
                            )
                            : ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filteredContracts.length,
                              separatorBuilder:
                                  (_, __) =>
                                      Divider(color: Colors.grey.shade400),
                              itemBuilder: (context, index) {
                                final contract = filteredContracts[index];
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      'เลขที่สัญญา : ${contract['contractno'] ?? ''}',
                                      style: GoogleFonts.prompt(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.teal[700],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ชื่อลูกค้า: ${contract['arname'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'วันที่ทำสัญญา: ${contract['contractdate'] != null ? formatDateToThaiDDMMYYYY(contract['contractdate']) : ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                          SizedBox(height: 4),
                                        Text(
                                          'เบอร์โทร: ${contract['mobileno'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        SizedBox(height: 4),
                                        Text(
                                          'หมายเหตุ: ${contract['followremark'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'ที่อยู่: ${contract['addressis'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),

                                        Text(
                                          'ค่าทวงถาม: ${contract['amount408'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'ค่าปรับ: ${contract['hp_intamount'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),

                                        SizedBox(height: 4),
                                        Text(
                                          'วันที่จ่ายงาน: ${contract['tranferdate'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),

                                        SizedBox(height: 4),
                                        Text(
                                          'เวลาจ่ายงาน: ${contract['estm_date'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),

                                        Text(
                                          'ยอดค้างชำระ: ${contract['hpprice'] ?? ''}',
                                          style: GoogleFonts.prompt(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                      ],
                                    ),
                                   trailing: Wrap(
                                      spacing: 8,
                                      children: [
                                        if (contract['mobileno'] != null &&
                                            contract['mobileno']
                                                .toString()
                                                .trim()
                                                .isNotEmpty)
                                          IconButton(
                                            icon: Icon(
                                              Icons.phone,
                                              color: Colors.green[700],
                                            ),
                                            tooltip: 'โทรออก',
                                            onPressed: () {
                                              final rawPhone =
                                                  contract['mobileno']
                                                      .toString();
                                             final cleanedPhone = rawPhone
                                                  .replaceAll(
                                                    RegExp(r'[^0-9+]'),
                                                    '',
                                                  );
                                              print(
                                                'เบอร์ที่ล้างแล้ว: $cleanedPhone',
                                              );


                                              if (cleanedPhone.isNotEmpty) {
                                                _makePhoneCall(
                                                  context,
                                                  cleanedPhone,
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'ไม่พบเบอร์ในระบบ',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.description,
                                            color: Colors.teal[700],
                                          ),
                                          tooltip: 'รายละเอียด',
                                          onPressed: () {
                                          _showContractDetails(
                                              context,
                                              contract,
                                            );
                                          },
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
    );
  }
}

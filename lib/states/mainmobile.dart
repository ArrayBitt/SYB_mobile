import 'dart:convert';
import 'package:syb/widgets/contract_detail_dialog.dart';
import 'package:syb/widgets/contract_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../states/authen.dart';

class MainMobile extends StatefulWidget {
  final String username;
  MainMobile({required this.username});

  @override
  _MainMobileState createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  bool _isLoading = false;
  List<dynamic> _contracts = [];
  String _searchQuery = '';

  int _limit = 50;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchData(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool isLoadMore = false}) async {
    if (_isLoading || (isLoadMore && !_hasMore)) return;

    setState(() {
      if (!isLoadMore) _isLoading = true;
      if (isLoadMore) _isLoadingMore = true;
    });

    final url =
        'https://syb.cjk-cr.com/SYYSJ/api/appfollowup/api_50_contract.php?username=${widget.username}&limit=$_limit&offset=$_offset&t=${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
      if (data is List) {
          setState(() {
            if (isLoadMore) {
              _contracts.addAll(data);
            } else {
              _contracts = data;
            }
            _hasMore = data.length == _limit;
            _offset += data.length;
          });
        } else {
          _showError('ข้อมูลไม่ถูกต้องจากเซิร์ฟเวอร์');
        }
      } else {
        _showError('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
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

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthenPage()),
      (route) => false,
    );
  }

  void _setSearchQuery(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      final result = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!result) throw 'เปิดโทรศัพท์ไม่ได้';
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถโทรออกได้: $e')));
    }
  }

  void _showContractDetails(dynamic contract) {
    showDialog(
      context: context,
      builder:
          (_) => ContractDetailDialog(
            contract: contract,
            username: widget.username,
          ),
    );
  }

String formatToDDMMYYYYThai(String? input) {
    if (input == null || input.length != 8) return '-';
    try {
      String day = input.substring(6, 8);
      String month = input.substring(4, 6);
      int yearInt = int.parse(input.substring(0, 4));

      // ถ้าปี < 2500 ถือว่าเป็น ค.ศ. ให้บวก 543
      int year = yearInt < 2500 ? yearInt + 543 : yearInt;

      return '$day-$month-$year';
    } catch (e) {
      return '-';
    }
  }

  Widget buildInfoBox(String label, String? value, {bool highlight = false}) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlight ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Text(
            value ?? '-',
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.redAccent : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredContracts =
        _contracts.where((contract) {
          final search = _searchQuery.toLowerCase();
          return contract.values.any(
            (value) =>
                value != null &&
                value.toString().toLowerCase().contains(search),
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'สัญญาเร่งรัด(SYB V.10)',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.teal),
            onPressed: () {
              _offset = 0;
              _hasMore = true;
              _fetchData();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading && _contracts.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  ContractSearchBar(onChanged: _setSearchQuery),
                  Expanded(
                    child:
                        filteredContracts.isEmpty
                            ? Center(
                              child: Text(
                                'ไม่พบข้อมูล',
                                style: GoogleFonts.prompt(fontSize: 18),
                              ),
                            )
                            : ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  filteredContracts.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredContracts.length) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final contract = filteredContracts[index];

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                             buildInfoBox(
                                              'เลขที่สัญญา',
                                              contract['contractno'],
                                            ),
                                            buildInfoBox(
                                              'ชื่อลูกค้า',
                                              contract['arname'],
                                            ),
                                            buildInfoBox(
                                              'วันที่ทำสัญญา',
                                              formatToDDMMYYYYThai(
                                                contract['contractdate'],
                                              ),
                                            ),
                                            buildInfoBox(
                                              'รหัสไอดี',
                                              contract['id'],
                                            ),
                                            buildInfoBox(
                                              'เบอร์โทร',
                                              contract['mobileno'],
                                            ),
                                            buildInfoBox(
                                              'หมายเหตุ',
                                              contract['followremark'],
                                            ),
                                            buildInfoBox(
                                              'ที่อยู่',
                                              contract['addressis'],
                                            ),
                                            buildInfoBox(
                                              'วันที่จ่ายงาน',
                                              formatToDDMMYYYYThai(
                                                contract['tranferdate'],
                                              ),
                                            ),
                                            buildInfoBox(
                                              'เวลาจ่ายงาน',
                                              contract['estm_date'],
                                            ),
                                            buildInfoBox(
                                              'ค่าติดตาม',
                                              contract['follow400'],
                                            ),
                                            buildInfoBox(
                                              'ยี่ห่อรถ',
                                              contract['brandname'],
                                            ),
                                            buildInfoBox(
                                              'ยอดค้างชำระ',
                                              contract['hpprice'],
                                              highlight: true,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed:
                                                  () => _makePhoneCall(
                                                    contract['mobileno'] ?? '',
                                                  ),
                                              icon: Icon(Icons.phone),
                                              label: Text(
                                                'โทรออก',
                                                style: GoogleFonts.prompt(),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green[400],
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed:
                                                  () => _showContractDetails(
                                                    contract,
                                                  ),
                                              icon: Icon(Icons.description),
                                              label: Text(
                                                'รายละเอียด',
                                                style: GoogleFonts.prompt(),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.teal[400],
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ],
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

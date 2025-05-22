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
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> _contracts = [];
  final int _perPage = 50;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      print('pixels: ${_scrollController.position.pixels}');
      print('maxExtent: ${_scrollController.position.maxScrollExtent}');
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 1000) {
        if (!_isLoadingMore && _hasMore && !_isLoading) {
          loadMoreData();
        }
      }
    });

    _fetchData(page: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({int page = 1}) async {
    print('page: ${page}');
    final username = widget.username;
    final url =
        'https://ss.cjk-cr.com/CJK/api/appfollowup/contract_api.php?username=$username&page=$page&perPage=$_perPage';

    if (page == 1) {
      setState(() {
        _isLoading = true;
        _hasMore = true;
        _contracts = [];
        _currentPage = 1;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

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
                return value != 'true'; // กรองเอาเฉพาะ checkrush != true
              }).toList();

          if (page == 1) {
            _contracts = filtered;
          } else {
            _contracts.addAll(filtered);
          }

          if (filtered.length < _perPage) {
            _hasMore = false;
          } else {
            _currentPage = page;
            _hasMore = true;
          }
        } else {
          _showError('ข้อมูลไม่ถูกต้อง');
          _hasMore = false;
        }
      } else {
        _showError('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์');
        _hasMore = false;
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: ${e.toString()}');
      _hasMore = false;
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void loadMoreData() {
    print('loadMoreData: ${loadMoreData}');
    if (_hasMore && !_isLoadingMore && !_isLoading) {
      _fetchData(page: _currentPage + 1);
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
    //seacch bar
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
        title: Text('ระบบจัดเก็บและเร่งรัด', style: titleStyle),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: () => _fetchData(page: 1),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.redAccent),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    hintText: 'กรอกข้อมูลที่ต้องการค้นหา',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
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
                    _isLoading && _contracts.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: () => _fetchData(page: 1),
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                filteredContracts.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredContracts.length) {
                                if (_isLoadingMore) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else {
                                  return SizedBox.shrink();
                                }
                              }

                              final contract = filteredContracts[index];

                              return InkWell(
                                onTap:
                                    () =>
                                        _showContractDetails(context, contract),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'เลขที่สัญญา: ${contract['contractno']}',
                                          style: GoogleFonts.prompt(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'ชื่อลูกค้า: ${contract['arname'] ?? 'ไม่ระบุ'}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'ยอดผ่อน: ${contract['hpprice'] ?? 'ไม่ระบุ'} บาท',
                                          style: GoogleFonts.prompt(
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'หมายเหตุ: ${contract['followremark'] ?? 'ไม่ระบุ'}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'ที่อยู่: ${contract['addressis'] ?? 'ไม่ระบุ'}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'วันที่สัญญา: ${formatDateToThaiDDMMYYYY(contract['contractdate'] ?? '')}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              icon: Icon(Icons.call),
                                              label: Text(
                                                contract['mobileno'] ??
                                                    'โทรออกไม่ได้',
                                              ),
                                              onPressed:
                                                  (contract['mobileno'] !=
                                                              null &&
                                                          contract['mobileno']
                                                              .toString()
                                                              .trim()
                                                              .isNotEmpty)
                                                      ? () => _makePhoneCall(
                                                        contract['mobileno'],
                                                      )
                                                      : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

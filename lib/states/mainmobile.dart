import 'dart:convert';
import 'package:cjk/widgets/contract_detail_dialog.dart';
import 'package:cjk/widgets/contract_list.dart';
import 'package:cjk/widgets/contract_search_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
   final url ='https://ss.cjk-cr.com/CJK/api/appfollowup/contract_api.php?username=${widget.username}';
   //final url = 'http://192.168.1.15/CJKTRAINING/api/appfollowup/contract_api.php?username=${widget.username}';

    setState(() {
      _isLoading = true;
      _contracts = [];
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'username': widget.username},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final filtered =
              data.where((item) {
                final checkrush = item['checkrush'];
                if (checkrush == null) return true;
                return checkrush.toString().toLowerCase().trim() != 'true';
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
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isLoading = false;
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
      if (!result) {
        throw 'เปิดโทรศัพท์ไม่ได้';
      }
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

  @override
  Widget build(BuildContext context) {
    final filteredContracts =
        _contracts.where((contract) {
          final search = _searchQuery.toLowerCase();
          // Search เช็คทุกค่าใน contract ว่ามีคำค้นไหม
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
          'สัญญาเร่งรัด (V 1.15)',
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
            onPressed: _fetchData,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
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
                            : ContractList(
                              contracts: filteredContracts,
                              onPhoneCall: _makePhoneCall,
                              onShowDetail: _showContractDetails,
                            ),
                  ),
                ],
              ),
    );
  }
}

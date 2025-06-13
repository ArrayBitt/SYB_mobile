import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowContractPage extends StatefulWidget {
  final String contractNo;

  const FollowContractPage({Key? key, required this.contractNo})
    : super(key: key);

  @override
  _FollowContractPageState createState() => _FollowContractPageState();
}

class _FollowContractPageState extends State<FollowContractPage> {
  List<dynamic> followData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFollowData();
  }

  Future<void> fetchFollowData() async {
    
    final url = Uri.parse('https://ss.cjk-cr.com/CJK/api/appfollowup/follow_contract.php?contractno=${widget.contractNo}', );

    //final url = Uri.parse( 'http://192.168.1.15/CJKTRAINING/api/appfollowup/follow_contract.php?contractno=${widget.contractNo}',);


    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        followData = jsonResponse;
        isLoading = false;
      });
    } else {
      setState(() {
        followData = [];
        isLoading = false;
      });
    }
  }

  String formatThaiDate(String? yyyymmdd) {
    if (yyyymmdd == null || yyyymmdd.length != 8) return '-';
    final year = yyyymmdd.substring(0, 4);
    final month = yyyymmdd.substring(4, 6);
    final day = yyyymmdd.substring(6, 8);

    const monthNames = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    int m = int.tryParse(month) ?? 0;
    int d = int.tryParse(day) ?? 0;
    String monthName = m >= 1 && m <= 12 ? monthNames[m] : '';
    return '$d $monthName $year';
  }

  Widget buildTableRow(
    String date,
    String time,
    String followAmount,
    String memo,
    String follower,
    String followType,
    String meetingDate,
    String meetingAmount,
    String username,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(date, style: GoogleFonts.mitr(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: time,
              child: Text(
                time,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: followAmount,
              child: Text(
                followAmount,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Tooltip(
              message: memo,
              child: Text(
                memo,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: follower,
              child: Text(
                follower,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: followType,
              child: Text(
                followType,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Tooltip(
              message: meetingDate,
              child: Text(
                meetingDate,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: meetingAmount,
              child: Text(
                meetingAmount,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: username,
              child: Text(
                username,
                style: GoogleFonts.mitr(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'วันที่บันทึก',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'เวลา',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ค่าติดตาม',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'รายละเอียด',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ผู้ติดตาม',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ประเภท',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'วันที่นัด',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ยอดนัด',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ผู้บันทึก',
              style: GoogleFonts.mitr(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

 Color iconColor = Colors.teal.shade600;
  TextStyle textStyle = GoogleFonts.mitr(fontSize: 14, color: Colors.black87);

  Widget buildFollowCardModern(dynamic item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text(
                  'วันที่: ${formatThaiDate(item['entrydate'])}',
                  style: textStyle,
                ),
                Spacer(),
                Icon(Icons.access_time, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text('เวลา: ${item['times'] ?? '-'}', style: textStyle),
              ],
            ),
            Divider(height: 16),
            Row(
              children: [
                Icon(Icons.notes, size: 18, color: iconColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'รายละเอียด: ${item['memo'] ?? '-'}',
                    style: textStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text('ผู้ติดตาม: ${item['follower'] ?? '-'}', style: textStyle),
              ],
            ),
            Row(
              children: [
                Icon(Icons.assignment, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text('ประเภท: ${item['followtype'] ?? '-'}', style: textStyle),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text(
                  'นัดหมาย: ${formatThaiDate(item['meetingdate'])}',
                  style: textStyle,
                ),
                Spacer(),
                Icon(Icons.attach_money, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text('${item['meetingamount'] ?? '-'}', style: textStyle),
              ],
            ),
            Divider(height: 16),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 18, color: iconColor),
                SizedBox(width: 8),
                Text('ผู้บันทึก: ${item['username'] ?? '-'}', style: textStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '📋 การติดตามสัญญา',
          style: GoogleFonts.mitr(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : followData.isEmpty
              ? Center(
                child: Text(
                  'ไม่พบข้อมูลการติดตาม',
                  style: GoogleFonts.mitr(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: followData.length,
                itemBuilder: (context, index) {
                  return buildFollowCardModern(followData[index]);
                },
              ),
    );
  }
}

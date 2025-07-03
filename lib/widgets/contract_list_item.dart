import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContractListItem extends StatelessWidget {
  final dynamic contract;
  final Function(String) onPhoneCall;
  final VoidCallback onShowDetail;

  ContractListItem({
    required this.contract,
    required this.onPhoneCall,
    required this.onShowDetail,
  });

  // แปลงวันที่เป็น DDMMYYYY (แบบพ.ศ.)
  String formatToDDMMYYYYThai(String? input) {
    if (input == null || input.length != 8) return 'ไม่ระบุ';
    try {
      String day = input.substring(6, 8);
      String month = input.substring(4, 6);
      String year = input.substring(0, 4);
      return '$day-$month-$year';
    } catch (e) {
      return 'ไม่ระบุ';
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
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อ
            Text(
              'เลขที่สัญญา: ${contract['contractno'] ?? ''}',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            SizedBox(height: 12),
            // กล่องข้อมูล
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                buildInfoBox('ชื่อลูกค้า', contract['arname']),
                buildInfoBox(
                  'วันที่ทำสัญญา',
                  formatToDDMMYYYYThai(contract['contractdate']),
                ),
                buildInfoBox('เบอร์โทร', contract['mobileno']),
                buildInfoBox('หมายเหตุ', contract['followremark']),
                buildInfoBox('ที่อยู่', contract['addressis']),
                buildInfoBox('ค่าทวงถาม', contract['amount408']),
                buildInfoBox('ค่าปรับ', contract['hp_intamount']),
                buildInfoBox(
                  'วันที่จ่ายงาน',
                  formatToDDMMYYYYThai(contract['tranferdate']),
                ),
                buildInfoBox('เวลาจ่ายงาน', contract['estm_date']),
                buildInfoBox('ค่าติดตาม', contract['follow400']),
                buildInfoBox('SEQ No.', contract['seqno']),
                buildInfoBox(
                  'ยอดค้างชำระ',
                  contract['hpprice'],
                  highlight: true,
                ),
              ],
            ),
            SizedBox(height: 12),
            // ปุ่มด้านล่างขวา
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (contract['mobileno'] != null &&
                    contract['mobileno'].toString().trim().isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.phone, color: Colors.green[700]),
                    tooltip: 'โทรออก',
                    onPressed: () {
                      final rawPhone = contract['mobileno'].toString();
                      final cleanedPhone = rawPhone.replaceAll(
                        RegExp(r'[^0-9+]'),
                        '',
                      );
                      if (cleanedPhone.isNotEmpty) {
                        onPhoneCall(cleanedPhone);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ไม่พบเบอร์ในระบบ')),
                        );
                      }
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.description, color: Colors.teal[700]),
                  tooltip: 'รายละเอียด',
                  onPressed: onShowDetail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

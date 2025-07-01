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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          'เลขที่สัญญา : ${contract['contractno'] ?? ''}',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[700],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชื่อลูกค้า: ${contract['arname'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'วันที่ทำสัญญา: ${formatDateToThaiDDMMYYYY(contract['contractdate'] ?? '')}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'เบอร์โทร: ${contract['mobileno'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'หมายเหตุ: ${contract['followremark'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'ที่อยู่: ${contract['addressis'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'ค่าทวงถาม: ${contract['amount408'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'ค่าปรับ: ${contract['hp_intamount'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'วันที่จ่ายงาน: ${contract['tranferdate'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'เวลาจ่ายงาน: ${contract['estm_date'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'ค่าติดตามตามงวดดิว : ${contract['follow400'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'seqno : ${contract['seqno'] ?? ''}',
              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              'ยอดค้างชำระ: ${contract['hpprice'] ?? ''}',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('ไม่พบเบอร์ในระบบ')));
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
      ),
    );
  }
}

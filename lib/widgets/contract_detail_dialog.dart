import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../states/saverush.dart';
import '../states/show_contract.dart';

class ContractDetailDialog extends StatelessWidget {
  final dynamic contract;
  final String username;

  ContractDetailDialog({required this.contract, required this.username});

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

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.8; // กำหนด dialog กว้าง 80% ของหน้าจอ

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey[50],
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.1,
      ), // เว้นขอบซ้ายขวา 10%
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
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          // กำหนด maxHeight ได้ถ้าต้องการ scrollable
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
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
                formatDateToThaiDDMMYYYY(contract['contractdate']),
              ),
              _buildDetailRow(
                'วันที่จ่ายงาน',
                formatDateToThaiDDMMYYYY(contract['tranferdate']),
              ),
              _buildDetailRow('ยอดชำระ', contract['hpprice'] ?? 'ไม่ระบุ'),
              _buildDetailRow(
                'หมายเหตุ',
                contract['followremark'] ?? 'ไม่ระบุ',
              ),
              _buildDetailRow('เบอร์มือถือ', contract['mobileno'] ?? 'ไม่ระบุ'),
              _buildDetailRow('ที่อยู่', contract['addressis'] ?? 'ไม่ระบุ'),
            ],
          ),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => SaveRushPage(
                      contractNo: contract['contractno'] ?? '',
                      hpprice: contract['hpprice'] ?? '',
                      username: contract['username'] ?? '',
                      hpIntAmount: contract['hp_intamount'] ?? '',
                      aMount408: contract['amount408'] ?? '',
                      aRname: contract['arname'] ?? '',
                      tranferdate: contract['tranferdate'] ?? '',
                      estmdate: contract['estm_date'] ?? '',
                      videoFilenames: [],
                      hp_overdueamt: contract['hp_overdueamt'] ?? '',
                      seqno: contract['seqno'] ?? '',
                      follow400: contract['follow400'] ?? '',
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => ShowContractPage(
                      contractNo: contract['contractno'] ?? '',
                      username: '',
                      hpprice: null,
                    ),
              ),
            );
          },
        ),
      ],
    );
  }
}

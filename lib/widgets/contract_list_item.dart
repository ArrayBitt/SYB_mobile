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
            RichText(
              text: TextSpan(
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700], // สีของ "เลขที่สัญญา:"
                ),
                children: [
                  TextSpan(
                    text: 'เลขที่สัญญา: ${contract['contractno'] ?? ''} ',
                  ),
                  // แสดงรูปถ้า groupleve เป็น A01 หรือ B08
                  if ((contract['grouplevel'] ?? '').toString().toUpperCase() ==
                          'A01' ||
                      (contract['grouplevel'] ?? '').toString().toUpperCase() ==
                          'B08')
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 2),
                        child: Image.asset(
                          'assets/icon/sidecar.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.error,
                              size: 20,
                              color: Colors.red,
                            );
                          },
                        ),
                      ),
                    ),
                  if (contract['restatus'] == 'Y')
                    TextSpan(
                      text: ' (❗️หลุดนัด)',
                      style: TextStyle(
                        color: Colors.red,
                      ), // สีแดงสำหรับ "หลุดนัด"
                    ),
                ],
              ),
            ),

            SizedBox(height: 5),
            // กล่องข้อมูล
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                buildInfoBox('ชื่อลูกค้า', contract['arname']),
                buildInfoBox(
                  'วันที่ทำสัญญา',
                  formatToDDMMYYYYThai(contract['contractdate']),
                ),
                buildInfoBox('เบอร์โทร', contract['mobileno']),
                buildInfoBox('หมายเหตุ', contract['followremark']),
                buildInfoBox('ที่อยู่', contract['addressis']),
                // buildInfoBox('ค่าทวงถาม', contract['amount408']),
                // buildInfoBox('ค่าปรับ', contract['hp_intamount']),
                buildInfoBox(
                  'วันที่จ่ายงาน',
                  formatToDDMMYYYYThai(contract['tranferdate']),
                ),

                buildInfoBox('เวลาจ่ายงาน', contract['estm_date']),
                buildInfoBox('ค่าติดตาม', contract['follow400']),
                buildInfoBox('ยี่ห่อรถ', contract['brandname']),
                // buildInfoBox('SEQ No.', contract['seqno']),
                buildInfoBox(
                  'ยอดค้างชำระ',
                  contract['hpprice'],
                  highlight: true,
                ),
              ],
            ),
            SizedBox(height: 12),
            // ปุ่มด้านล่างขวา
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                final buttonWidth =
                    isNarrow ? (constraints.maxWidth / 2) - 20 : 150.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center, // จัดกลางแนวนอน
                  children: [
                    if (contract['mobileno'] != null &&
                        contract['mobileno'].toString().trim().isNotEmpty)
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(Icons.phone, size: 20),
                          label: Text(
                            'โทรออก',
                            style: GoogleFonts.prompt(fontSize: 14),
                          ),
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
                      ),
                    if (contract['mobileno'] != null &&
                        contract['mobileno'].toString().trim().isNotEmpty)
                      SizedBox(width: 16),
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[400],
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(Icons.description, size: 20),
                        label: Text(
                          'รายละเอียด',
                          style: GoogleFonts.prompt(fontSize: 14),
                        ),
                        onPressed: onShowDetail,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

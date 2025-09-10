import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart'; // ✅ เพิ่ม import

class PayAS400Page extends StatefulWidget {
  final String contractNo;

  const PayAS400Page({super.key, required this.contractNo});

  @override
  State<PayAS400Page> createState() => _PayAS400PageState();
}

class _PayAS400PageState extends State<PayAS400Page> {
  String? qrData;
  String? barcodeData;
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? firstItem;

  @override
  void initState() {
    super.initState();
    fetchQRData();
  }

  Future<void> fetchQRData() async {
    final url = Uri.parse( 'https://syb.cjk-cr.com/SYYSJ/api/appfollowup/pay_as400.php?contractno=${widget.contractNo}',);

    //final url = Uri.parse('http://192.168.1.15/CJKTRAINING/api/appfollowup/pay_as400.php?contractno=${widget.contractNo}', );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          firstItem = data[0];
          if (firstItem!['qrcode'] != null &&
              firstItem!['qrcode'].toString().trim().isNotEmpty) {
            String rawQr = firstItem!['qrcode'].toString();
            String rawBarcode = firstItem!['barcode5']?.toString() ?? '';

            String formattedQr = rawQr.replaceAll('%0D', '\r');
            String formattedBarcode = rawBarcode.replaceAll('\r', '');

            setState(() {
              qrData = formattedQr;
              barcodeData = formattedBarcode;
              isLoading = false;
              errorMessage = null;
            });
            return;
          }
        }

        setState(() {
          isLoading = false;
          qrData = null;
          errorMessage = 'ไม่พบ QR Code ในข้อมูลที่ได้รับ';
        });
      } else {
        setState(() {
          isLoading = false;
          qrData = null;
          errorMessage = 'โหลดข้อมูลไม่สำเร็จ (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        qrData = null;
        errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.red[700];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'หน้าชำระเงิน',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : qrData != null && firstItem != null
                ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ข้อมูลสัญญา',
                        style: GoogleFonts.prompt(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.contractNo,
                        style: GoogleFonts.prompt(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _moneyInfoItem(
                            'ดอกเบี้ย',
                            firstItem!['hp_intamount'] ?? '-',
                          ),
                          _moneyInfoItem(
                            'ยอดต่องวด',
                            firstItem!['amtperperiod'] ?? '-',
                          ),
                          _moneyInfoItem(
                            'จำนวนงวด',
                            firstItem!['totalperiod'] ?? '-',
                            isInteger: true, // ✅ ใช้เฉพาะจำนวนงวด
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // QR Code
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: QrImageView(
                            data: qrData!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: primaryColor!,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Colors.red[700]!,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✅ Barcode (แสดงจริง)
                      Text(
                        'Barcode',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children:
                            (barcodeData ?? '-')
                                .split('\n')
                                .where((line) => line.trim().isNotEmpty)
                                .map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: line,
                                      width: 280,
                                      height: 70,
                                      drawText: true,
                                      style: GoogleFonts.prompt(),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                )
                : Center(
                  child: Text(
                    errorMessage ?? 'ไม่พบ QR Code',
                    style: GoogleFonts.prompt(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
      ),
    );
  }

  Widget _moneyInfoItem(String label, String value, {bool isInteger = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isInteger ? _formatInteger(value) : _formatCurrency(value),
          style: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
      ],
    );
  }

  String _formatInteger(String val) {
    try {
      return int.parse(double.parse(val).toStringAsFixed(0)).toString();
    } catch (_) {
      return val;
    }
  }

  String _formatCurrency(String val) {
    try {
      double amount = double.parse(val);
      return '${amount.toStringAsFixed(2)} ฿';
    } catch (_) {
      return val;
    }
  }
}

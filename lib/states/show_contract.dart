import 'package:cjk/states/pay_as400.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cjk/states/card_cut_page.dart';
import 'package:cjk/states/contract_image.dart';
import 'package:cjk/states/followContract.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ เพิ่มตรงนี้

class ShowContractPage extends StatefulWidget {
  final String contractNo;

  const ShowContractPage({
    Key? key,
    required this.contractNo,
    required String username,
    required hpprice,
  }) : super(key: key);

  @override
  _ShowContractPageState createState() => _ShowContractPageState();
}

class _ShowContractPageState extends State<ShowContractPage> {
  Map<String, dynamic>? contractData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchContractDetails();
  }

  Future<void> fetchContractDetails() async {
   // final url = Uri.parse( 'https://ss.cjk-cr.com/CJK/api/appfollowup/show_contract.php?contractno=${widget.contractNo}',);

  final url = Uri.parse( 'http://192.168.1.15/CJKTRAINING/api/appfollowup/show_contract.php?contractno=${widget.contractNo}',);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse.isNotEmpty) {
        setState(() {
          contractData = jsonResponse[0];
          isLoading = false;
        });
      } else {
        setState(() {
          contractData = null;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        contractData = null;
        isLoading = false;
      });
    }
  }

  Future<void> _openCardCutPDF() async {
    final contractNo = contractData?['contractno'];
    if (contractNo != null && contractNo.toString().isNotEmpty) {

      final url = Uri.parse('https://ss.cjk-cr.com/Formspdf/frm_hp_cardcut.php?p_dbmsname=MotorBikeDBMS&p_docno=$contractNo', );

      //final url = Uri.parse( 'http://192.168.1.15/Formspdf/frm_hp_cardcut.php?p_dbmsname=MotorBikeDBMS&p_docno=$contractNo', );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่สามารถเปิดลิงก์ได้')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่พบเลขที่สัญญา')));
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📄 รายละเอียดสัญญา', style: GoogleFonts.prompt()),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : contractData != null
                    ? SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle('📌 ข้อมูลสัญญา'),
                              Divider(),
                              _buildDetailTile(
                                Icons.receipt_long,
                                'Contract No',
                                contractData!['contractno'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.car_rental,
                                'Chassis No',
                                contractData!['chassisno'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.person,
                                'Sale No',
                                contractData!['saleno'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.assignment,
                                'Job Description',
                                contractData!['jobdescription'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.car_crash,
                                'Return Car',
                                contractData!['returncar'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.monetization_on,
                                'Return Amount',
                                contractData!['returnamt'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.payments,
                                'Amount Per Period',
                                contractData!['amtperperiod'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.timeline,
                                'Total Period',
                                contractData!['totalperiod'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.percent,
                                'HP Rate',
                                contractData!['hprate'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.event_available,
                                'First Paid',
                                contractData!['firstpaid'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.event_busy,
                                'Last Paid',
                                contractData!['lastpaid'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.warning,
                                'Overdue Days',
                                contractData!['max_nodays'],
                              ),
                              Divider(),
                              _buildDetailTile(
                                Icons.map,
                                'Maplocation',
                                contractData!['maplocations'],
                              ),
                              Divider(),
                            ],
                          ),
                        ),
                      ),
                    )
                    : Center(
                      child: Text(
                        'ไม่พบข้อมูลสัญญา',
                        style: GoogleFonts.prompt(fontSize: 16),
                      ),
                    ),
          ),

          // ปุ่มล่างทั้งหมด
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final contractNo = contractData?['contractno'];
                          if (contractNo != null &&
                              contractNo.toString().isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ContractImagePage(
                                      contractNo: contractNo,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ไม่พบเลขที่สัญญา')),
                            );
                          }
                        },
                        icon: Icon(Icons.image, size: 18),
                        label: Text(
                          'ภาพสัญญา',
                          style: GoogleFonts.prompt(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[300],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final contractNo = contractData?['contractno'];
                          if (contractNo != null &&
                              contractNo.toString().isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PayAS400Page(contractNo: contractNo),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ไม่พบเลขที่สัญญา')),
                            );
                          }
                        },
                        icon: Icon(Icons.payment, size: 18),
                        label: Text(
                          'ชำระเงิน',
                          style: GoogleFonts.prompt(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final contractNo = contractData?['contractno'];
                          if (contractNo != null &&
                              contractNo.toString().isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        CardCutPage(contractNo: contractNo),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ไม่พบเลขที่สัญญา')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[800],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'การ์ดชำระลูกหนี้',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final contractNo = contractData?['contractno'];
                          if (contractNo != null &&
                              contractNo.toString().isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => FollowContractPage(
                                      contractNo: contractNo,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ไม่พบเลขที่สัญญา')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'การติดตาม',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.prompt(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal[800],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, dynamic value) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        label,
        style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value?.toString() ?? '-',
        style: GoogleFonts.prompt(fontSize: 15),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}

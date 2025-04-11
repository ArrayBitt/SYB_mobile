import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ShowContractPage extends StatefulWidget {
  final String contractNo;

  const ShowContractPage({Key? key, required this.contractNo})
    : super(key: key);

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
    final url = Uri.parse(
      'https://ppw.somjai.app/PPWSJ/api/appfollowup/show_contract.php?contractno=${widget.contractNo}',
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📄 รายละเอียดสัญญา', style: GoogleFonts.prompt()),
        backgroundColor: Colors.teal,
      ),
      body:
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
                          contractData!['overduedays'],
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

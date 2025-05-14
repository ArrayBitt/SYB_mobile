import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class CardCutPage extends StatefulWidget {
  final String contractNo;

  const CardCutPage({Key? key, required this.contractNo}) : super(key: key);

  @override
  _CardCutPageState createState() => _CardCutPageState();
}

class _CardCutPageState extends State<CardCutPage> {
  String? localFilePath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  Future<void> loadPDF() async {
    final url ='https://ss.cjk-cr.com/Formspdf/frm_hp_cardcut.php?p_dbmsname=MotorBikeDBMS&p_docno=${widget.contractNo}';

    //final url ='http://171.102.194.54/TRAINING/PPWSJ/Formspdf/frm_hp_cardcut.php?p_dbmsname=ppwsjdbms&p_docno=${widget.contractNo}';

    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cardcut.pdf');
    await file.writeAsBytes(bytes, flush: true);

    setState(() {
      localFilePath = file.path;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('การ์ดชำระลูกหนี้')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : PDFView(filePath: localFilePath!),
    );
  }
}

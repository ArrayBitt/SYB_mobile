import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const HomePage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'หน้าหลัก\nชื่อผู้ใช้: ${userData?['username'] ?? "ไม่พบข้อมูล"}',
        style: TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }
}

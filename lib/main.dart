// lib/main.dart
import 'package:flutter/material.dart';
import 'states/authen.dart'; // นำเข้าจากโฟลเดอร์ states

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthenPage(), // เริ่มต้นที่หน้า AuthenPage
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Main Page')),
      body: Center(child: Text('ยินดีต้อนรับสู่หน้าแรกหลังจากล็อกอิน')),
    );
  }
}

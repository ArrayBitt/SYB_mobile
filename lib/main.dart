import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart'; // เพิ่มตรงนี้
import 'states/authen.dart'; // นำเข้าจากโฟลเดอร์ states

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // เพิ่มเพื่อให้ async ใน main ทำงานได้
  await GetStorage.init(); // เรียกใช้งาน GetStorage ก่อนเริ่ม app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthenPage(),
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

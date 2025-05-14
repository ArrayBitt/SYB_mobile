import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cjk/states/authen.dart'; // นำเข้าหน้าล็อกอิน
import 'package:cjk/states/mainmobile.dart'; // นำเข้าหน้าหลัก

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   final userJson = await getUserJson(); // ใช้ฟังก์ชันที่คุณเขียนไว้

  final prefs = await SharedPreferences.getInstance();
  final String? username = userJson?['username']; 

  runApp(MyApp(username: username));
}

class MyApp extends StatelessWidget {
  final String? username;

  MyApp({this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: username == null ? AuthenPage() : MainMobile(username: username!),
    );
  }
}

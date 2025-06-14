import 'package:cjk/utils/check_version.dart';
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

  const MyApp({this.username, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          username == null
              ? AuthenPage()
              : AppWithVersionCheck(username: username!),
    );
  }
}

// ✅ สร้าง widget ใหม่เพื่อรัน checkAppVersion หลัง context สร้างเสร็จ
class AppWithVersionCheck extends StatefulWidget {
  final String username;
  const AppWithVersionCheck({super.key, required this.username});

  @override
  State<AppWithVersionCheck> createState() => _AppWithVersionCheckState();
}

class _AppWithVersionCheckState extends State<AppWithVersionCheck> {
  @override
  void initState() {
    super.initState();
    // เรียกเช็คเวอร์ชันเมื่อโหลด widget นี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppVersion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainMobile(username: widget.username);
  }
}

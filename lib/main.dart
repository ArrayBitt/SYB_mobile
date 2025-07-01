import 'package:cjk/utils/user_prefs.dart'; // เพิ่มบรรทัดนี้
import 'package:cjk/states/authen.dart';
import 'package:cjk/states/mainmobile.dart';
import 'package:cjk/utils/check_version.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userJson = await getUserJson();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppVersion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainMobile(username: widget.username);
  }
}

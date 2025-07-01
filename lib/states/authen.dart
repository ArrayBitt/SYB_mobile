import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cjk/states/mainmobile.dart';
import 'package:cjk/widgets/login_logo.dart';
import 'package:cjk/widgets/login_form.dart';
import 'package:cjk/widgets/login_button.dart';
import 'package:cjk/widgets/loading_indicator.dart';

class AuthenPage extends StatefulWidget {
  @override
  _AuthenPageState createState() => _AuthenPageState();
}

class _AuthenPageState extends State<AuthenPage> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> saveUserJson(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user);
    await prefs.setString('username', jsonString);
  }

  Future<void> _login() async {
    if ((_formKey.currentState?.validate()) ?? false) {
      setState(() {
        _isLoading = true;
      });

      final username = _userController.text;
      final password = _passwordController.text;
     final url = 'https://ss.cjk-cr.com/CJK/api/appfollowup/users.php';

     //final url = 'http://192.168.1.15/CJKTRAINING/api/appfollowup/users.php';

      try {
        final response = await http.post(
          Uri.parse(url),
          body: {'username': username, 'passwords': password},
        );

        if (response.statusCode == 200) {
          final dynamic data = json.decode(response.body);
          bool loginSuccess = false;

          if (data is List && data.isNotEmpty) {
            for (var user in data) {
              if (user['username'] == username &&
                  user['passwords'] == password) {
                loginSuccess = true;
                break;
              }
            }
          }

          if (loginSuccess) {
            await saveUserJson({'username': username});
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainMobile(username: username),
              ),
            );
          } else {
            _showError('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
          }
        } else {
          _showError('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์');
        }
      } catch (e) {
        _showError('เกิดข้อผิดพลาด: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'ข้อผิดพลาด',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.prompt()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'ตกลง',
                  style: GoogleFonts.prompt(color: Colors.amber[800]),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LoginLogo(),
                  SizedBox(height: 20),
                  Text(
                    'เข้าสู่ระบบ',
                    style: GoogleFonts.prompt(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        LoginForm(
                          userController: _userController,
                          passwordController: _passwordController,
                          isPasswordVisible: _isPasswordVisible,
                          onTogglePassword: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        SizedBox(height: 30),
                        _isLoading
                            ? LoadingIndicator()
                            : LoginButton(onPressed: _login),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

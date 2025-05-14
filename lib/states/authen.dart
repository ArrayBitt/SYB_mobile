import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cjk/states/mainmobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';



Future<void> saveUserJson(Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = jsonEncode(user);
  await prefs.setString('username', jsonString);
}

Future<Map<String, dynamic>?> getUserJson() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('username');
  if (jsonString != null) {
    return jsonDecode(jsonString);
  }
  return null;
}



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

  

  Future<void> _login() async {
    if ((_formKey.currentState?.validate()) ?? false) {
      setState(() {
        _isLoading = true;
      });

      final username = _userController.text;
      final password = _passwordController.text;
      final url = 'https://ss.cjk-cr.com/CJK/api/appfollowup/users.php';
      //final url = 'http://171.102.194.54/TRAINING/PPWSJ/api/appfollowup/users.php';

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
    final inputTextStyle = GoogleFonts.prompt(
      color: Colors.grey[900],
      fontSize: 16,
    );
    final hintStyle = GoogleFonts.prompt(color: Colors.grey[500], fontSize: 16);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [

                 Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/icon/somjai.png',
                      fit: BoxFit.contain, // หรือ BoxFit.cover แล้วแต่ต้องการ
                    ),
                  ),


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
                        // Username
                        TextFormField(
                          controller: _userController,
                          style: inputTextStyle,
                          decoration: InputDecoration(
                            hintText: 'ชื่อผู้ใช้',
                            hintStyle: hintStyle,
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.grey[700],
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'กรุณากรอกชื่อผู้ใช้'
                                      : null,
                        ),
                        SizedBox(height: 20),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: inputTextStyle,
                          decoration: InputDecoration(
                            hintText: 'รหัสผ่าน',
                            hintStyle: hintStyle,
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.grey[700],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[700],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'กรุณากรอกรหัสผ่าน'
                                      : null,
                        ),
                        SizedBox(height: 30),
                        // Login button
                        _isLoading
                            ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber[700]!,
                              ),
                            )
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color.fromARGB(255, 255, 43, 1),
                                  foregroundColor: Colors.grey[900],
                                  elevation: 4,
                                  shadowColor: Colors.amber.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'เข้าสู่ระบบ',
                                  style: GoogleFonts.prompt(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
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

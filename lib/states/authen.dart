import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_app/states/mainmobile.dart';

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
      final url = 'https://ppw.somjai.app/PPWSJ/api/appfollowup/users.php';

      // Debug: แสดงค่าที่กรอก
      print("Username: $username");
      print("Password: $password");

      try {
        final response = await http.post(
          Uri.parse(url),
          body: {'username': username, 'passwords': password},
        );

        print("Response Status: ${response.statusCode}");
        print("Response Body: ${response.body}");

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
            print("Login successful");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainMobile()),
            );
          } else {
            print("Login failed: Username and password do not match");
            _showError('ผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
          }
        } else {
          print("Unable to connect to server");
          _showError('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์');
        }
      } catch (e) {
        print("Error: $e");
        _showError('เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}');
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
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ข้อผิดพลาด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ตกลง',
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // กำหนด TextStyle ทั้งหมดที่ใช้ใน UI
    final hintStyle = TextStyle(color: Colors.grey[600], fontSize: 16);
    final inputTextStyle = TextStyle(color: Colors.black87, fontSize: 16);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'เข้าสู่ระบบ',
          style: TextStyle(fontSize: 20, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                // ใช้ gradient โทนสีอ่อน
                gradient: LinearGradient(
                  colors: [Colors.lightBlue[100]!, Colors.pink[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_circle,
                      size: 100,
                      color: Colors.black54,
                    ),
                    SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ช่องกรอกชื่อผู้ใช้
                          TextFormField(
                            controller: _userController,
                            style: inputTextStyle,
                            decoration: InputDecoration(
                              hintText: 'ชื่อผู้ใช้',
                              hintStyle: hintStyle,
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อผู้ใช้';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // ช่องกรอกรหัสผ่าน
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: inputTextStyle,
                            decoration: InputDecoration(
                              hintText: 'รหัสผ่าน',
                              hintStyle: hintStyle,
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 30),
                          // ปุ่มเข้าสู่ระบบ
                          _isLoading
                              ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black54,
                                ),
                              )
                              : AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black87, backgroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: Text(
                                    'เข้าสู่ระบบ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
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
        ],
      ),
    );
  }
}

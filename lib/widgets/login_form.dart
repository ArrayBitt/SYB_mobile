import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController userController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;

  const LoginForm({
    required this.userController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    final inputTextStyle = GoogleFonts.prompt(
      color: Colors.grey[900],
      fontSize: 16,
    );
    final hintStyle = GoogleFonts.prompt(color: Colors.grey[500], fontSize: 16);

    return Column(
      children: [
        TextFormField(
          controller: userController,
          style: inputTextStyle,
          decoration: InputDecoration(
            hintText: 'ชื่อผู้ใช้',
            hintStyle: hintStyle,
            prefixIcon: Icon(Icons.person, color: Colors.grey[700]),
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          style: inputTextStyle,
          decoration: InputDecoration(
            hintText: 'รหัสผ่าน',
            hintStyle: hintStyle,
            prefixIcon: Icon(Icons.lock, color: Colors.grey[700]),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[700],
              ),
              onPressed: onTogglePassword,
            ),
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
        ),
      ],
    );
  }
}

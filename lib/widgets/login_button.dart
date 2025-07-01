import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
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
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

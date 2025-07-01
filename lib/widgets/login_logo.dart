import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      padding: const EdgeInsets.all(8.0),
      child: Image.asset('assets/icon/somjai.png', fit: BoxFit.contain),
    );
  }
}

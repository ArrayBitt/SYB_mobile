import 'dart:convert';
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

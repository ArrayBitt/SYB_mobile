import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://syb.cjk-cr.com/SYYSJ/api/appfollowup/';

  Future<Map<String, dynamic>> saveRushData(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${baseUrl}up_saverush.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save rush data');
    }
  }

  Future<Map<String, dynamic>> updateCheckRush(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${baseUrl}update_checkrush.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update check rush');
    }
  }

  Future<Map<String, dynamic>> uprushTest(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${baseUrl}uprush_test.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to call uprush test');
    }
  }
}

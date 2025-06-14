import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkAppVersion(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  try {
    final response = await http.post(
      Uri.parse('https://ss.cjk-cr.com/CJK/api/appfollowup/check_version.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"version": currentVersion}),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == 'update_required') {
      final latestVersion = data['latest_version'] ?? 'ไม่ทราบ';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => WillPopScope(
              onWillPop: () async => false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double dialogWidth = constraints.maxWidth * 0.8;

                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: dialogWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.system_update,
                              color: Colors.redAccent,
                              size: 50,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              "มีเวอร์ชันใหม่",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "เวอร์ชันปัจจุบัน : $currentVersion",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['message'] ?? 'กรุณาอัปเดตแอปเพื่อใช้งานต่อ',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 20,
                                ),
                                label: const Text("Update Version"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                                onPressed: () async {
                                  final url = Uri.parse(data['url']);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      );
    }
  } catch (e) {
    debugPrint("❌ Version check failed: $e");
  }
}

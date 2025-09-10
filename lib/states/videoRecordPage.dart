import 'dart:async';
import 'dart:io';

import 'package:syb/states/video_compress_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'video_capture_screen.dart';
import 'video_preview_upload_screen.dart';

class VideoRecordPage extends StatefulWidget {
  final String contractNo;
  const VideoRecordPage({Key? key, required this.contractNo}) : super(key: key);

  @override
  State<VideoRecordPage> createState() => _VideoRecordPageState();
}

class _VideoRecordPageState extends State<VideoRecordPage> {
  List<String?> videoPaths = List.generate(6, (_) => null);
  final List<String> contractLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
  bool isUploading = false;
  bool _isCompressing = false; // สถานะบีบอัด

  final VideoCompressHelper _videoCompressHelper = VideoCompressHelper();

  @override
  void initState() {
    super.initState();
    _loadVideoPaths();
  }

  @override
  void dispose() {
    _videoCompressHelper.dispose();
    super.dispose();
  }

  Future<void> _loadVideoPaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 6; i++) {
        videoPaths[i] = prefs.getString('${widget.contractNo}_video_$i');
      }
    });
  }

  Future<void> _saveVideoPath(int index, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${widget.contractNo}_video_$index', filePath);
  }

  Future<void> _uploadAllVideos() async {
    setState(() {
      isUploading = true;
    });

    bool allSuccess = true;

    for (int i = 0; i < 6; i++) {
      final path = videoPaths[i];
      if (path != null) {
        final success = await _uploadVideo(path, i);
        if (!success) {
          allSuccess = false;
        }
      }
    }

    setState(() {
      isUploading = false;
    });

    final message =
        allSuccess ? 'อัปโหลดสำเร็จทั้งหมด' : 'อัปโหลดมีข้อผิดพลาดบางรายการ';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _uploadVideo(String filePath, int index) async {
    try {
      setState(() {
        _isCompressing = true;
      });

      // บีบอัดวิดีโอก่อนอัปโหลด
      final compressedPath = await _videoCompressHelper.compressVideo(filePath);
      setState(() {
        _isCompressing = false;
      });

      final uploadPath = compressedPath ?? filePath; // ใช้ไฟล์บีบอัด ถ้าได้

      final file = File(uploadPath);
      final fileSize = await file.length();
      const maxSizeInBytes = 50 * 1024 * 1024;

      if (fileSize > maxSizeInBytes) {
        debugPrint('Video $index ขนาดไฟล์เกิน 50MB ไม่สามารถอัปโหลดได้');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'วิดีโอ ${index + 1} ขนาดเกิน 50MB ไม่สามารถอัปโหลดได้',
            ),
          ),
        );
        return false;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://syb.cjk-cr.com/SYYSJ/api/appfollowup/upload_video.php'),
      );

      // final request = http.MultipartRequest(
      //   'POST',
      //   Uri.parse('http://192.168.1.15/CJKTRAINING/api/appfollowup/upload_video.php'),
      // );

      debugPrint('Uploading video index: $index');
      debugPrint('File path: $uploadPath');
      debugPrint('File size (bytes): $fileSize');
      debugPrint('Fields: contract_no=${widget.contractNo}, index=$index');

      request.files.add(
        await http.MultipartFile.fromPath('video_file', uploadPath),
      );
      request.fields['contract_no'] = widget.contractNo;
      request.fields['index'] = index.toString();

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        debugPrint('Upload video $index success');
        debugPrint('Server response: $responseBody');
        return true;
      } else {
        debugPrint(
          'Upload video $index failed with status: ${streamedResponse.statusCode}',
        );
        debugPrint('Server response: $responseBody');
        return false;
      }
    } on TimeoutException catch (_) {
      debugPrint('Upload video $index timeout');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('วิดีโอ ${index + 1} อัปโหลด timeout')),
      );
      return false;
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });
      debugPrint('Upload video $index error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัปโหลดวิดีโอ ${index + 1}'),
        ),
      );
      return false;
    }
  }

  Future<void> _goToVideoCapture(int index) async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                VideoCaptureScreen(contractNo: widget.contractNo, index: index),
      ),
    );

    if (result != null) {
      setState(() {
        videoPaths[index] = result;
      });
      await _saveVideoPath(index, result);
    }
  }

  void _playVideo(String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VideoPreviewUploadScreen(
              videoPath: filePath,
              contractNo: widget.contractNo,
              index: videoPaths.indexOf(filePath),
            ),
      ),
    );
  }

  Future<void> _deleteAllVideos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: const Text('คุณต้องการลบวิดีโอทั้งหมดใช่หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ลบ'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // ลบไฟล์ทั้งหมด
      for (int i = 0; i < videoPaths.length; i++) {
        final path = videoPaths[i];
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // เคลียร์ shared preferences
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < videoPaths.length; i++) {
        await prefs.remove('${widget.contractNo}_video_$i');
      }

      setState(() {
        videoPaths = List.generate(6, (_) => null);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบวิดีโอทั้งหมดเรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ถ่ายวิดีโอ (${widget.contractNo})'),
        centerTitle: true,
        elevation: 3,
        actions: [
          IconButton(
            tooltip: 'ลบวิดีโอทั้งหมด',
            icon: const Icon(Icons.delete_forever),
            onPressed:
                videoPaths.any((e) => e != null) ? _deleteAllVideos : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  itemCount: 6,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final hasVideo = videoPaths[index] != null;
                    final label = contractLabels[index];

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (hasVideo) {
                            _playVideo(videoPaths[index]!);
                          } else {
                            _goToVideoCapture(index);
                          }
                        },
                        splashColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: hasVideo ? Colors.green[50] : Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasVideo
                                    ? Icons.play_circle_fill
                                    : Icons.videocam,
                                size: 72,
                                color:
                                    hasVideo
                                        ? Colors.green[700]
                                        : Colors.grey[700],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${widget.contractNo}_$label',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasVideo
                                    ? 'แตะเพื่อดูวิดีโอ'
                                    : 'ยังไม่มีวิดีโอ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
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
              if (_isCompressing) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text('กำลังบีบอัดวิดีโอ... กรุณารอสักครู่'),
                const SizedBox(height: 20),
              ],
              if (isUploading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('กำลังอัปโหลดวิดีโอทั้งหมด...'),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      videoPaths.any((e) => e != null) &&
                              !isUploading &&
                              !_isCompressing
                          ? _uploadAllVideos
                          : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('อัปโหลดวิดีโอทั้งหมด'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

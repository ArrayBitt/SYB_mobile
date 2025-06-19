import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class VideoPreviewUploadScreen extends StatefulWidget {
  final String videoPath;
  final String contractNo;
  final int index;

  const VideoPreviewUploadScreen({
    Key? key,
    required this.videoPath,
    required this.contractNo,
    required this.index,
  }) : super(key: key);

  @override
  State<VideoPreviewUploadScreen> createState() =>
      _VideoPreviewUploadScreenState();
}

class _VideoPreviewUploadScreenState extends State<VideoPreviewUploadScreen> {
  late VideoPlayerController _videoController;
  bool isInitialized = false;
  bool isUploading = false;
  String? uploadResult;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() => isInitialized = true);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _uploadVideo() async {
    setState(() {
      isUploading = true;
      uploadResult = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://ss.cjk-cr.com/CJK/api/appfollowup/upload_video.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('video_file', widget.videoPath),
      );
      request.fields['contract_no'] = widget.contractNo;
      request.fields['index'] = widget.index.toString();

      var response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          uploadResult = "อัปโหลดสำเร็จ!";
        });
      } else {
        setState(() {
          uploadResult = "อัปโหลดล้มเหลว: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        uploadResult = "เกิดข้อผิดพลาด: $e";
      });
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ดูวิดีโอและอัปโหลด')),
      body: Column(
        children: [
          Expanded(
            child:
                isInitialized
                    ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                    : const Center(child: CircularProgressIndicator()),
          ),
          if (uploadResult != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                uploadResult!,
                style: TextStyle(
                  color:
                      uploadResult == "อัปโหลดสำเร็จ!"
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : _uploadVideo,
              icon: const Icon(Icons.cloud_upload),
              label: Text(
                isUploading ? 'กำลังอัปโหลด...' : 'อัปโหลดวิดีโอไปยัง Server',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_videoController.value.isPlaying) {
              _videoController.pause();
            } else {
              _videoController.play();
            }
          });
        },
        child: Icon(
          _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}

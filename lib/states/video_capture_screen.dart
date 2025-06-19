import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class VideoCaptureScreen extends StatefulWidget {
  final String contractNo;
  final int index;

  const VideoCaptureScreen({
    Key? key,
    required this.contractNo,
    required this.index,
  }) : super(key: key);

  @override
  State<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      final rawFile = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);

      final label = ['A', 'B', 'C', 'D', 'E', 'F'][widget.index];
      final directory = await getApplicationDocumentsDirectory();
      final newPath = path.join(
        directory.path,
        '${widget.contractNo}_$label.mp4',
      );

      final recordedFile = File(rawFile.path);
      final renamedFile = await recordedFile.copy(newPath);

      if (mounted) Navigator.pop(context, renamedFile.path);
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('กำลังโหลดกล้อง...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ถ่ายวิดีโอ'),
        centerTitle: true,
        elevation: 3,
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 48),
                backgroundColor: _isRecording ? Colors.red : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
              label: Text(_isRecording ? 'หยุดบันทึก' : 'เริ่มบันทึก'),
              onPressed: _isRecording ? _stopRecording : _startRecording,
            ),
          ),
        ],
      ),
    );
  }
}

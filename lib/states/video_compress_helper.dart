import 'package:video_compress/video_compress.dart';

class VideoCompressHelper {
  /// ฟังก์ชันบีบอัดวิดีโอ รับ path ของวิดีโอต้นฉบับ
  Future<String?> compressVideo(String filePath) async {
    final MediaInfo? info = await VideoCompress.compressVideo(
      filePath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false, // ไม่ลบไฟล์ต้นฉบับ
    );
    return info?.path; // คืน path ของไฟล์ที่ถูกบีบอัด หรือ null ถ้าล้มเหลว
  }

  /// ฟังก์ชันเรียกตอนไม่ใช้แล้ว เพื่อยกเลิก compression และล้าง resource
  Future<void> dispose() async {
    await VideoCompress.cancelCompression();
  }
}

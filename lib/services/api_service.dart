import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/model.dart';

class ApiService {
  static const String baseUrl = 'https://f1x3r.org/pv';

  // Helper Header สำหรับ Request ทั่วไป
  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Helper เช็ก Response Status
  static bool _isSuccessStatus(dynamic status) {
    return status == true || status == 'success' || status == 'true' || status == 1;
  }

  // ==================================================================
  // APP VERSION MANAGEMENT API
  // ==================================================================

  /// ดึงข้อมูลการตั้งค่าเวอร์ชันแอปปัจจุบัน
  static Future<AppVersionConfig> fetchAppVersion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_version_admin.php'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return AppVersionConfig.fromJson(jsonResponse['data'] ?? {});
    } else {
      throw Exception(jsonResponse['message'] ?? 'ไม่สามารถดึงข้อมูลเวอร์ชันแอปได้');
    }
  }

  /// บันทึก/อัปเดตเวอร์ชันแอป พร้อมรองรับการอัปโหลดไฟล์ .ipa (Multipart Request)
  static Future<bool> updateAppVersion({
    required String bundleID,
    required String appName,
    required String latestVersion,
    required List<String> allowedVersions,
    required String releaseNotes,
    String? downloadUrl,
    File? ipaFile,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api_save_version.php'),
    );

    // แนบ Form Fields
    request.fields['bundleID'] = bundleID;
    request.fields['appName'] = appName;
    request.fields['latestVersion'] = latestVersion;
    request.fields['allowedVersions'] = allowedVersions.join(',');
    request.fields['releaseNotes'] = releaseNotes;
    if (downloadUrl != null) {
      request.fields['downloadUrl'] = downloadUrl;
    }

    // หากมีการเลือกไฟล์ .ipa ให้อัปโหลดแนบไปกับ Request
    if (ipaFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('app_file', ipaFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'บันทึกข้อมูลเวอร์ชันแอปไม่สำเร็จ');
    }
  }
}

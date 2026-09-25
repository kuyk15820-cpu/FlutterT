import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/model.dart';

class ApiService {
  static const String baseUrl = 'https://f1x3r.org/pv';
  static const String patchesBaseUrl = 'https://f1x3r.org/patches';

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

    request.fields['bundleID'] = bundleID;
    request.fields['appName'] = appName;
    request.fields['latestVersion'] = latestVersion;
    request.fields['allowedVersions'] = allowedVersions.join(',');
    request.fields['releaseNotes'] = releaseNotes;
    if (downloadUrl != null) {
      request.fields['downloadUrl'] = downloadUrl;
    }

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

  // ==================================================================
  // TARGET GAMES MANAGEMENT API (games.json)
  // ==================================================================

  /// ดึงรายการ Target Games ทั้งหมด
  static Future<List<TargetGame>> fetchGames() async {
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/games.json'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => TargetGame.fromJson(item)).toList();
    } else {
      throw Exception('ไม่สามารถดึงข้อมูลเกมเป้าหมายได้');
    }
  }

  /// เพิ่ม หรือแก้ไข Target Game
  static Future<bool> addOrUpdateGame({
    required String gameName,
    required String bundleID,
  }) async {
    final response = await http.post(
      Uri.parse('$patchesBaseUrl/save3.php?api=1'),
      body: {
        'action': 'add_game',
        'game_name': gameName,
        'bundle_id': bundleID,
      },
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'บันทึกข้อมูลเกมไม่สำเร็จ');
    }
  }

  /// เปิด / ปิด การใช้งาน Target Game รายตัว
  static Future<bool> toggleGameStatus(String bundleID) async {
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/save3.php?action=toggle_game&bundle_id=${Uri.encodeComponent(bundleID)}&api=1'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'สลับสถานะเกมไม่สำเร็จ');
    }
  }

  /// เปิด / ปิด การใช้งาน Target Game ทั้งหมด (status: true = เปิด, false = ปิด)
  static Future<bool> toggleAllGamesStatus(bool status) async {
    final statusCode = status ? '1' : '0';
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/save3.php?action=toggle_all_games&status=$statusCode&api=1'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'สลับสถานะเกมทั้งหมดไม่สำเร็จ');
    }
  }

  /// ลบ Target Game
  static Future<bool> deleteGame(String bundleID) async {
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/save3.php?action=delete_game&bundle_id=${Uri.encodeComponent(bundleID)}&api=1'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'ลบเกมไม่สำเร็จ');
    }
  }

  // ==================================================================
  // PATCHES MANAGEMENT API (catalog.json)
  // ==================================================================

  /// ดึงรายการ Patch ทั้งหมด
  static Future<List<PatchItem>> fetchPatches() async {
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/catalog.json'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => PatchItem.fromJson(item)).toList();
    } else {
      throw Exception('ไม่สามารถดึงข้อมูล Patch ได้');
    }
  }

  /// เพิ่ม Patch ใหม่ (พร้อมไฟล์ .c4)
  static Future<bool> addPatch({
    required String id,
    required String title,
    required String category,
    required String bundleID,
    File? applyFile,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$patchesBaseUrl/save3.php?api=1'),
    );

    request.fields['action'] = 'add';
    request.fields['id'] = id;
    request.fields['title'] = title;
    request.fields['category'] = category;
    request.fields['bundleID'] = bundleID;

    if (applyFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('apply_file', applyFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'เพิ่ม Patch ไม่สำเร็จ');
    }
  }

  /// แก้ไขข้อมูล Patch (รองรับการเปลี่ยนไฟล์ .c4 ใหม่)
  static Future<bool> updatePatch({
    required String id,
    required String title,
    required String category,
    required String bundleID,
    File? applyFile,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$patchesBaseUrl/save3.php?api=1'),
    );

    request.fields['action'] = 'update';
    request.fields['id'] = id;
    request.fields['title'] = title;
    request.fields['category'] = category;
    request.fields['bundleID'] = bundleID;

    if (applyFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('apply_file', applyFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'แก้ไข Patch ไม่สำเร็จ');
    }
  }

  /// เปิด / ปิด การใช้งาน Patch รายตัว
  static Future<bool> togglePatchStatus(String id) async {
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/save3.php?action=toggle&id=${Uri.encodeComponent(id)}&api=1'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'สลับสถานะ Patch ไม่สำเร็จ');
    }
  }

  /// เปิด / ปิด การใช้งาน Patch ทั้งหมด (status: true = เปิด, false = ปิด)
  static Future<bool> toggleAllPatchesStatus(bool status) async {
    final statusCode = status ? '1' : '0';
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/save3.php?action=toggle_all_patches&status=$statusCode&api=1'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'สลับสถานะ Patch ทั้งหมดไม่สำเร็จ');
    }
  }

  /// ลบ Patch
  static Future<bool> deletePatch(String id) async {
    final response = await http.get(
      Uri.parse('$patchesBaseUrl/save3.php?action=delete&id=${Uri.encodeComponent(id)}&api=1'),
      headers: _defaultHeaders,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else {
      throw Exception(jsonResponse['message'] ?? 'ลบ Patch ไม่สำเร็จ');
    }
  }
}

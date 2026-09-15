import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../models/key_model.dart'; // 📌 เพิ่ม Model Key ที่สร้างไว้

class ApiService {
  static const String baseUrl = 'https://f1x3r.org/api/webserver/app';

  // ------------------------------------------------------------------
  // 1. DASHBOARD STATS
  // ------------------------------------------------------------------
  static Future<DashboardStats> fetchDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/get_dashboard_stats.php'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        return DashboardStats.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load stats');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ------------------------------------------------------------------
  // 2. KEY MANAGEMENT API
  // ------------------------------------------------------------------

  // 🟢 ดึงรายการ Key ตาม Tab ('active', 'banned', 'expired', 'deleted')
  static Future<List<KeyItem>> fetchKeys(String tab) async {
    final response = await http.get(Uri.parse('$baseUrl/get_keys.php?tab=$tab'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        final List list = jsonResponse['data'];
        return list.map((item) => KeyItem.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load keys');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ⚡ ฟังก์ชันกลางสำหรับส่ง Action ไปที่ manage_key.php
  static Future<bool> manageKey(Map<String, dynamic> bodyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/manage_key.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        return true;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Action failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ➕ สร้าง Key ใหม่
  static Future<bool> createKey({
    required int projectId,
    required String type,
    required int maxDevices,
    required String prefixType,
    String? customPrefix,
    String? staticDate,
    int? durationNum,
    String? durationUnit,
  }) async {
    return await manageKey({
      'action': 'create',
      'project_id': projectId,
      'type': type,
      'max_devices': maxDevices,
      'prefix_type': prefixType,
      'custom_prefix': customPrefix,
      'static_date': staticDate,
      'duration_num': durationNum,
      'duration_unit': durationUnit,
    });
  }

  // 🚫 แบน Key
  static Future<bool> banKey({
    required int keyId,
    required String banType, // 'permanent' หรือ 'temp'
    int? banHours,
    String? reason,
  }) async {
    return await manageKey({
      'action': 'ban',
      'key_id': keyId,
      'ban_type': banType,
      'ban_hours': banHours,
      'ban_reason': reason,
    });
  }

  // 🟢 ปลดแบน Key
  static Future<bool> unbanKey(int keyId) async {
    return await manageKey({
      'action': 'unban',
      'key_id': keyId,
    });
  }

  // ⏳ ต่ออายุ Key
  static Future<bool> renewKey({
    required int keyId,
    required int renewNum,
    required String renewUnit, // 'hour', 'day', 'week', 'month', 'year'
  }) async {
    return await manageKey({
      'action': 'renew',
      'key_id': keyId,
      'renew_num': renewNum,
      'renew_unit': renewUnit,
    });
  }

  // 🔄 รีเซ็ต Device Bound
  static Future<bool> resetDevice(int keyId) async {
    return await manageKey({
      'action': 'reset_device',
      'key_id': keyId,
    });
  }

  // 🗑️ ลบ Key
  static Future<bool> deleteKey(int keyId) async {
    return await manageKey({
      'action': 'delete',
      'key_id': keyId,
    });
  }
}

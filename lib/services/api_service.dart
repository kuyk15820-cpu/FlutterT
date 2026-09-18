import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/model.dart'; // Import Data Models ทั้งหมด

class ApiService {
  static const String baseUrl = 'https://f1x3r.org/api/webserver/app';

  // Helper Headers กลางสำหรับ HTTP Requests
  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ==================================================================
  // 1. AUTHENTICATION API
  // ==================================================================

  /// เข้าสู่ระบบ Admin
  static Future<AdminUser> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth.php'),
      headers: _defaultHeaders,
      body: jsonEncode({
        'action': 'login',
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        return AdminUser.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ==================================================================
  // 2. DASHBOARD STATS API
  // ==================================================================

  /// ดึงข้อมูลสถิติภาพรวม Dashboard
  static Future<DashboardStats> fetchDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_dashboard_stats.php'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        return DashboardStats.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? ' Failed to load stats');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ==================================================================
  // 3. KEY MANAGEMENT API
  // ==================================================================

  /// ดึงรายการ Key ตาม Tab ('active', 'banned', 'expired', 'deleted')
  static Future<List<KeyItem>> fetchKeys(String tab) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_keys.php?tab=$tab'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        final List list = jsonResponse['data'] ?? [];
        return list.map((item) => KeyItem.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load keys');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// ⚡ ฟังก์ชันกลางสำหรับส่ง Request ไปที่ manage_key.php
  static Future<dynamic> manageKey(Map<String, dynamic> bodyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/manage_key.php'),
      headers: _defaultHeaders,
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        // หากมี data คืนกลับมา (เช่น รายการคีย์สร้างใหม่) ให้ส่ง data กลับ
        return jsonResponse['data'] ?? true;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Key action failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// ➕ 1. สร้าง Key ใหม่ (คืนค่าเป็น dynamic เพื่อรองรับ Array Key ที่ถูกสร้าง)
  static Future<dynamic> createKey({
    required int projectId,
    required String type, // 'dynamic', 'static', 'lifetime'
    required int maxDevices,
    required String prefixType, // 'package', 'custom'
    int quantity = 1,
    String? customPrefix,
    String? staticDate,
    String? presetDuration, // '1hour', '3hour', '6hour', '12hour', '1day', '3day', '1week', '2week', '1month', '1year'
  }) async {
    return await manageKey({
      'action': 'create',
      'project_id': projectId,
      'type': type,
      'max_devices': maxDevices,
      'prefix_type': prefixType,
      'quantity': quantity,
      'custom_prefix': customPrefix,
      'static_date': staticDate,
      'preset_duration': presetDuration,
    });
  }

  /// 🔴 2. สั่งแบน / แก้ไขการแบน Key
  static Future<bool> banKey({
    required int keyId,
    required String banType, // 'permanent', 'temp'
    int? banHours,
    String? reason,
  }) async {
    final res = await manageKey({
      'action': 'ban',
      'key_id': keyId,
      'ban_type': banType,
      'ban_hours': banHours,
      'ban_reason': reason,
    });
    return res != null;
  }

  /// 🟢 3. ปลดแบน Key เดี่ยว
  static Future<bool> unbanKey(int keyId) async {
    final res = await manageKey({
      'action': 'unban',
      'key_id': keyId,
    });
    return res != null;
  }

  /// ⏳ 4. ต่ออายุ Key เดี่ยว (ปรับใช้ Preset Duration)
  static Future<bool> renewKey({
    required int keyId,
    required String presetDuration,
  }) async {
    final res = await manageKey({
      'action': 'renew',
      'key_id': keyId,
      'preset_duration': presetDuration,
    });
    return res != null;
  }

  /// 🔄 5. รีเซ็ต Device เดี่ยว
  static Future<bool> resetDevice(int keyId) async {
    final res = await manageKey({
      'action': 'reset_device',
      'key_id': keyId,
    });
    return res != null;
  }

  /// 🔄 6. รีเซ็ต Device ทั้งหมดของ Key ในระบบที่ Active
  static Future<bool> resetAllDevices() async {
    final res = await manageKey({
      'action': 'reset_all_devices',
    });
    return res != null;
  }

  /// 🗑️ 7. ลบคีย์เดี่ยว
  static Future<bool> deleteKey(int keyId) async {
    final res = await manageKey({
      'action': 'delete',
      'key_id': keyId,
    });
    return res != null;
  }

  /// ⚡ 8. จัดการแบบกลุ่ม (Bulk Actions)
  static Future<bool> bulkKeyAction({
    required String bulkAction, // 'delete_selected', 'ban_selected', 'unban_selected', 'reset_selected_devices', 'purge_selected_history', 'renew_selected'
    required List<int> ids,
    String? presetDuration,
  }) async {
    final res = await manageKey({
      'action': 'bulk_action',
      'bulk_action': bulkAction,
      'ids': ids,
      'preset_duration': presetDuration,
    });
    return res != null;
  }

  /// 🧹 9. เคลียร์ข้อมูลทั้งหมดตามหมวดหมู่ (Clear All)
  static Future<bool> clearAllKeys(String targetTab) async {
    final res = await manageKey({
      'action': 'clear_all',
      'target_tab': targetTab,
    });
    return res != null;
  }

  // ==================================================================
  // 4. PACKAGE MANAGEMENT API
  // ==================================================================

  /// ดึงรายการ Package ตาม Tab ('active', 'maint', 'deleted')
  static Future<List<PackageItem>> fetchPackages(String tab) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_packages.php?tab=$tab'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        final List list = jsonResponse['data'] ?? [];
        return list.map((item) => PackageItem.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load packages');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// ⚡ ฟังก์ชันกลางสำหรับส่ง Request ไปที่ manage_package.php
  static Future<bool> managePackage(Map<String, dynamic> bodyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/manage_package.php'),
      headers: _defaultHeaders,
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        return true;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Package action failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// ➕ 1. สร้าง Package ใหม่
  static Future<bool> createPackage({
    required String name,
    String? contact,
  }) async {
    return await managePackage({
      'action': 'add',
      'name': name,
      'contact': contact ?? '',
    });
  }

  /// ✏️ 2. แก้ไข Package
  static Future<bool> editPackage({
    required int id,
    required String name,
    String? contact,
  }) async {
    return await managePackage({
      'action': 'edit',
      'id': id,
      'name': name,
      'contact': contact ?? '',
    });
  }

  /// 🛠️ 3. สลับสถานะ Maintenance (เปิด/ปิด)
  static Future<bool> togglePackageMaintenance(int id, int currentStatus) async {
    return await managePackage({
      'action': 'toggle_maint',
      'id': id,
      'current_status': currentStatus,
    });
  }

  /// 🗑️ 4. ลบ Package เดี่ยว
  static Future<bool> deletePackage(int id) async {
    return await managePackage({
      'action': 'delete',
      'id': id,
    });
  }

  /// ♻️ 5. กู้คืน Package เดี่ยว
  static Future<bool> restorePackage(int id) async {
    return await managePackage({
      'action': 'restore',
      'id': id,
    });
  }

  /// ⚡ 6. จัดการกลุ่ม Package (Bulk Actions - แก้ไข typo สbulk_action แล้ว)
  static Future<bool> bulkPackageAction({
    required String bulkAction, // 'delete_selected', 'maint_selected', 'restore_selected', 'purge_selected_history'
    required List<int> ids,
  }) async {
    return await managePackage({
      'action': 'bulk_action',
      'bulk_action': bulkAction,
      'ids': ids,
    });
  }

  /// 🧹 7. ล้างข้อมูล Package ทั้งหมดตามหมวดหมู่ (Clear All)
  static Future<bool> clearAllPackages(String targetTab) async {
    return await managePackage({
      'action': 'clear_all',
      'target_tab': targetTab,
    });
  }
}

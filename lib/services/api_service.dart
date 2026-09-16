import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/model.dart'; // Import รวม Data Models ทั้งหมด

class ApiService {
  static const String baseUrl = 'https://f1x3r.org/api/webserver/app';

  // ==================================================================
  // 1. DASHBOARD STATS API
  // ==================================================================
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

  // ==================================================================
  // 2. KEY MANAGEMENT API
  // ==================================================================

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

  // ⚡ ฟังก์ชันกลางสำหรับส่ง Request ไปที่ manage_key.php
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
        throw Exception(jsonResponse['message'] ?? 'Key action failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ➕ 1. สร้าง Key ใหม่ (รองรับทั้งแบบเดี่ยว และ Bulk Creation ด้วย quantity)
  static Future<bool> createKey({
    required int projectId,
    required String type, // 'dynamic', 'static', 'lifetime'
    required int maxDevices,
    required String prefixType, // 'package', 'custom'
    int quantity = 1, // 🟢 เพิ่มพารามิเตอร์ quantity ตรงนี้ (Default คือ 1)
    String? customPrefix,
    String? staticDate,
    int? durationNum,
    String? durationUnit, // 'hour', 'day', 'week', 'month', 'year'
  }) async {
    return await manageKey({
      'action': 'create',
      'project_id': projectId,
      'type': type,
      'max_devices': maxDevices,
      'prefix_type': prefixType,
      'quantity': quantity, // 🟢 ส่งค่า quantity ไปยัง PHP
      'custom_prefix': customPrefix,
      'static_date': staticDate,
      'duration_num': durationNum,
      'duration_unit': durationUnit,
    });
  }

  // 🔴 2. สั่งแบน / แก้ไขการแบน Key
  static Future<bool> banKey({
    required int keyId,
    required String banType, // 'permanent', 'temp'
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

  // 🟢 3. ปลดแบน Key เดี่ยว
  static Future<bool> unbanKey(int keyId) async {
    return await manageKey({
      'action': 'unban',
      'key_id': keyId,
    });
  }

  // ⏳ 4. ต่ออายุ Key เดี่ยว
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

  // 🔄 5. รีเซ็ต Device เดี่ยว
  static Future<bool> resetDevice(int keyId) async {
    return await manageKey({
      'action': 'reset_device',
      'key_id': keyId,
    });
  }

  // 🔄 6. รีเซ็ต Device ทั้งหมดของ Key ในระบบที่ Active
  static Future<bool> resetAllDevices() async {
    return await manageKey({
      'action': 'reset_all_devices',
    });
  }

  // 🗑️ 7. ลบคีย์เดี่ยว
  static Future<bool> deleteKey(int keyId) async {
    return await manageKey({
      'action': 'delete',
      'key_id': keyId,
    });
  }

  // ⚡ 8. จัดการแบบกลุ่ม (Bulk Actions)
  static Future<bool> bulkKeyAction({
    required String bulkAction, // 'delete_selected', 'ban_selected', 'unban_selected', 'reset_selected_devices', 'purge_selected_history'
    required List<int> ids,
  }) async {
    return await manageKey({
      'action': 'bulk_action',
      'bulk_action': bulkAction,
      'ids': ids,
    });
  }

  // 🧹 9. เคลียร์ข้อมูลทั้งหมดตามหมวดหมู่ (Clear All)
  static Future<bool> clearAllKeys(String targetTab) async {
    return await manageKey({
      'action': 'clear_all',
      'target_tab': targetTab, // 'clear_active_keys', 'unban_all_keys', 'clear_banned_keys', 'clear_expired_keys', 'clear_deleted_history'
    });
  }

  // ==================================================================
  // 3. PACKAGE MANAGEMENT API
  // ==================================================================

  // 🟢 ดึงรายการ Package ตาม Tab ('active', 'maint', 'deleted')
  static Future<List<PackageItem>> fetchPackages(String tab) async {
    final response = await http.get(Uri.parse('$baseUrl/get_packages.php?tab=$tab'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        final List list = jsonResponse['data'];
        return list.map((item) => PackageItem.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load packages');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // ⚡ ฟังก์ชันกลางสำหรับส่ง Request ไปที่ manage_package.php
  static Future<bool> managePackage(Map<String, dynamic> bodyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/manage_package.php'),
      headers: {'Content-Type': 'application/json'},
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

  // ➕ 1. สร้าง Package ใหม่
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

  // ✏️ 2. แก้ไข Package
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

  // 🛠️ 3. สลับสถานะ Maintenance (เปิด/ปิด)
  static Future<bool> togglePackageMaintenance(int id, int currentStatus) async {
    return await managePackage({
      'action': 'toggle_maint',
      'id': id,
      'current_status': currentStatus,
    });
  }

  // 🗑️ 4. ลบ Package เดี่ยว
  static Future<bool> deletePackage(int id) async {
    return await managePackage({
      'action': 'delete',
      'id': id,
    });
  }

  // ♻️ 5. กู้คืน Package เดี่ยว
  static Future<bool> restorePackage(int id) async {
    return await managePackage({
      'action': 'restore',
      'id': id,
    });
  }

  // ⚡ 6. จัดการกลุ่ม Package (Bulk Actions)
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

  // 🧹 7. ล้างข้อมูล Package ทั้งหมดตามหมวดหมู่ (Clear All)
  static Future<bool> clearAllPackages(String targetTab) async {
    return await managePackage({
      'action': 'clear_all',
      'target_tab': targetTab, // 'clear_active_packages', 'clear_maint_packages', 'clear_deleted_packages'
    });
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/model.dart';

class ApiService {
  static const String baseUrl = 'https://f1x3r.org/api/webserver/app';

  // 📌 Helper ดึง Header แบบแนบ Bearer Token จาก SharedPreferences อัตโนมัติ
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Helper Header สำหรับ Request ทั่วไปที่ไม่ต้องแนบ Token
  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Helper เช็ก Response Status
  static bool _isSuccessStatus(dynamic status) {
    return status == true || status == 'success' || status == 'true' || status == 1;
  }

  // ==================================================================
  // 1. AUTHENTICATION API
  // ==================================================================

  /// เข้าสู่ระบบ (Login)
  static Future<AdminUser> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: _defaultHeaders,
      body: jsonEncode({
        'user_login': usernameOrEmail,
        'user_password': password,
      }),
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      final userData = jsonResponse['data'] ?? {};
      final user = AdminUser.fromJson(userData);

      // 🟢 บันทึก Session & Role ลง SharedPreferences ทันทีที่ Login สำเร็จ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', user.token);
      await prefs.setInt('user_id', user.id);
      await prefs.setString('username', user.username);
      await prefs.setString('email', user.email);
      await prefs.setString('plan_type', user.planType);
      await prefs.setString('role', user.role);

      return user;
    } else {
      throw Exception(jsonResponse['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
    }
  }

  /// สมัครสมาชิก (Register)
  static Future<AdminUser?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: _defaultHeaders,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      // 🟢 หากมี data และ session_token ส่งกลับมา ให้ทำการ Auto-Login ได้ทันที
      if (jsonResponse['data'] != null && jsonResponse['data']['session_token'] != null) {
        final user = AdminUser.fromJson(jsonResponse['data']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', user.token);
        await prefs.setInt('user_id', user.id);
        await prefs.setString('username', user.username);
        await prefs.setString('email', user.email);
        await prefs.setString('plan_type', user.planType);
        await prefs.setString('role', user.role);
        return user;
      }
      return null;
    } else {
      throw Exception(jsonResponse['message'] ?? 'การลงทะเบียนล้มเหลว');
    }
  }

  /// เช็กสถานะล็อกอิน (Check Auth Status)
  static Future<bool> checkAuthStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check_auth.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['is_authenticated'] == true || _isSuccessStatus(jsonResponse['status']);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// ออกจากระบบ (Logout)
  static Future<bool> logout() async {
    try {
      final headers = await _getAuthHeaders();

      // 🟢 เคลียร์ข้อมูล Session ในเครื่องออกทันที
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final response = await http.post(
        Uri.parse('$baseUrl/logout.php'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return _isSuccessStatus(jsonResponse['status']);
      }
      return true;
    } catch (e) {
      return true; // ล้าง Session ฝั่งเครื่องแม้เรียก API ไม่สำเร็จ
    }
  }

  // ==================================================================
  // 2. DASHBOARD STATS API
  // ==================================================================

  /// ดึงข้อมูลสถิติภาพรวม Dashboard
  static Future<DashboardStats> fetchDashboardStats() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/get_dashboard_stats.php'),
      headers: headers,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return DashboardStats.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load stats');
    }
  }

  // ==================================================================
  // 3. KEY MANAGEMENT API
  // ==================================================================

  /// ดึงรายการ Key ตาม Tab ('active', 'banned', 'expired', 'deleted')
  static Future<List<KeyItem>> fetchKeys(String tab) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/get_keys.php?tab=$tab'),
      headers: headers,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      final List list = jsonResponse['data'] ?? [];
      return list.map((item) => KeyItem.fromJson(item)).toList();
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load keys');
    }
  }

  /// ⚡ ฟังก์ชันกลางสำหรับส่ง Request ไปที่ manage_key.php
  static Future<dynamic> manageKey(Map<String, dynamic> bodyData) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/manage_key.php'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return jsonResponse['data'] ?? true;
    } else if (response.statusCode == 403) {
      // 🔴 ติด Limit Quota รายแพ็กเกจ
      throw Exception(jsonResponse['message'] ?? 'Quota limit exceeded');
    } else {
      throw Exception(jsonResponse['message'] ?? 'Key action failed');
    }
  }

  /// ➕ 1. สร้าง Key ใหม่
  static Future<dynamic> createKey({
    required int projectId,
    required String type,
    required int maxDevices,
    required String prefixType,
    int quantity = 1,
    String? customPrefix,
    String? staticDate,
    String? presetDuration,
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
    required String banType,
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

  /// ⏳ 4. ต่ออายุ Key เดี่ยว
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
    required String bulkAction,
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
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/get_packages.php?tab=$tab'),
      headers: headers,
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      final List list = jsonResponse['data'] ?? [];
      return list.map((item) => PackageItem.fromJson(item)).toList();
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load packages');
    }
  }

  /// ⚡ ฟังก์ชันกลางสำหรับส่ง Request ไปที่ manage_package.php
  static Future<bool> managePackage(Map<String, dynamic> bodyData) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/manage_package.php'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && _isSuccessStatus(jsonResponse['status'])) {
      return true;
    } else if (response.statusCode == 403) {
      // 🔴 ติด Limit Quota รายแพ็กเกจ (เช่น บัญชี Free สร้างได้ไม่เกิน 1 Package)
      throw Exception(jsonResponse['message'] ?? 'Package quota limit exceeded');
    } else {
      throw Exception(jsonResponse['message'] ?? 'Package action failed');
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

  /// ⚡ 6. จัดการกลุ่ม Package (Bulk Actions)
  static Future<bool> bulkPackageAction({
    required String bulkAction,
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

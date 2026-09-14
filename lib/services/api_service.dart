import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';

class ApiService {
  // ⚠️ เปลี่ยน URL ให้ตรงกับ Backend PHP ของคุณ
  static const String baseUrl = 'https://f1x3r.org/api/webserver/app';

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
}

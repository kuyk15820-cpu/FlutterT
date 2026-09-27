import 'dart:convert';

// ==================================================================
// APP VERSION MODEL
// ==================================================================
class AppVersionConfig {
  final String latestVersion;
  final List<String> allowedVersions;
  final String bundleID;
  final String appName;
  final String downloadUrl;
  final String releaseNotes;
  final String? updatedAt;

  AppVersionConfig({
    required this.latestVersion,
    required this.allowedVersions,
    required this.bundleID,
    required this.appName,
    required this.downloadUrl,
    required this.releaseNotes,
    this.updatedAt,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) {
    List<String> allowed = [];
    if (json['allowedVersions'] != null && json['allowedVersions'] is List) {
      allowed = List<String>.from(json['allowedVersions']);
    }

    return AppVersionConfig(
      latestVersion: json['latestVersion'] ?? '0.0.0',
      allowedVersions: allowed,
      bundleID: json['bundleID'] ?? '',
      appName: json['appName'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'allowedVersions': allowedVersions,
      'bundleID': bundleID,
      'appName': appName,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'updatedAt': updatedAt,
    };
  }
}

// ==================================================================
// TARGET GAME MODEL
// ==================================================================
class TargetGame {
  final String name;
  final String bundleID;
  final String? icon; // 🟢 เพิ่ม icon (URL หรือ Path)
  final bool active;
  final String? updatedAt;

  TargetGame({
    required this.name,
    required this.bundleID,
    this.icon, // 🟢 เพิ่มใน constructor
    this.active = true,
    this.updatedAt,
  });

  factory TargetGame.fromJson(Map<String, dynamic> json) {
    return TargetGame(
      name: json['name'] ?? '',
      bundleID: json['bundleID'] ?? '',
      icon: json['icon'], // 🟢 ดึงค่า icon จาก JSON
      active: json['active'] ?? true,
      updatedAt: json['updatedAt'] ?? json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bundleID': bundleID,
      'icon': icon, // 🟢 ส่งค่า icon แปลงกลับเป็น JSON
      'active': active,
      'updatedAt': updatedAt,
    };
  }

  static List<TargetGame> fromJsonList(String jsonString) {
    final List<dynamic> parsed = json.decode(jsonString);
    return parsed.map((json) => TargetGame.fromJson(json)).toList();
  }
}

// ==================================================================
// PATCH ITEM MODEL
// ==================================================================
class PatchItem {
  final String id;
  final String title;
  final String category;
  final String bundleID;
  final String downloadUrl;
  final bool active;
  final String? updatedAt;

  PatchItem({
    required this.id,
    required this.title,
    required this.category,
    required this.bundleID,
    required this.downloadUrl,
    this.active = true,
    this.updatedAt,
  });

  factory PatchItem.fromJson(Map<String, dynamic> json) {
    return PatchItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      bundleID: json['bundleID'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      active: json['active'] ?? true,
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'bundleID': bundleID,
      'downloadUrl': downloadUrl,
      'active': active,
      'updatedAt': updatedAt,
    };
  }

  static List<PatchItem> fromJsonList(String jsonString) {
    final List<dynamic> parsed = json.decode(jsonString);
    return parsed.map((json) => PatchItem.fromJson(json)).toList();
  }
}

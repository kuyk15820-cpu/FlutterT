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

import 'dart:convert';

// ==================================================================
// 1. API RESPONSE & AUTH MODELS
// ==================================================================
class ApiResponse<T> {
  final String status;
  final String? message;
  final T? data;

  ApiResponse({
    required this.status,
    this.message,
    this.data,
  });

  bool get isSuccess => status == 'success';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] ?? 'error',
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
    );
  }
}

class AdminUser {
  final int id;
  final String username;
  final String token;

  AdminUser({
    required this.id,
    required this.username,
    required this.token,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: int.parse((json['id'] ?? 0).toString()),
      username: json['username'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'token': token,
    };
  }
}

// ==================================================================
// 2. DASHBOARD STATS MODELS
// ==================================================================
class DashboardStats {
  final int totalDevices;
  final PackageStats packages;
  final KeyStats keys;

  DashboardStats({
    required this.totalDevices,
    required this.packages,
    required this.keys,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // รองรับทั้งแบบครอบด้วย data และไม่ครอบ
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    
    return DashboardStats(
      totalDevices: int.parse((data['devices']?['total'] ?? 0).toString()),
      packages: PackageStats.fromJson(data['packages'] ?? {}),
      keys: KeyStats.fromJson(data['keys'] ?? {}),
    );
  }
}

class PackageStats {
  final int total;
  final int active;
  final int maintenance;
  final int deleted;

  PackageStats({
    required this.total,
    required this.active,
    required this.maintenance,
    required this.deleted,
  });

  factory PackageStats.fromJson(Map<String, dynamic> json) {
    return PackageStats(
      total: int.parse((json['total'] ?? 0).toString()),
      active: int.parse((json['active'] ?? 0).toString()),
      maintenance: int.parse((json['maintenance'] ?? 0).toString()),
      deleted: int.parse((json['deleted'] ?? 0).toString()),
    );
  }
}

class KeyStats {
  final int total;
  final int active;
  final int banned;
  final int expired;
  final int deleted;

  KeyStats({
    required this.total,
    required this.active,
    required this.banned,
    required this.expired,
    required this.deleted,
  });

  factory KeyStats.fromJson(Map<String, dynamic> json) {
    return KeyStats(
      total: int.parse((json['total'] ?? 0).toString()),
      active: int.parse((json['active'] ?? 0).toString()),
      banned: int.parse((json['banned'] ?? 0).toString()),
      expired: int.parse((json['expired'] ?? 0).toString()),
      deleted: int.parse((json['deleted'] ?? 0).toString()),
    );
  }
}

// ==================================================================
// 3. KEY ITEM MODEL
// ==================================================================
class KeyItem {
  final int id;
  final int? originalId;
  final int projectId;
  final String projectName;
  final String tokenCode;
  final String type; // dynamic, static, lifetime
  final int duration;
  final String? expireDate;
  final int maxDevices;
  final int usedDevices;
  final bool isBanned;
  final String? banExpire;
  final String? banReason;
  final String? reason;
  final String? deletedAt;
  final List<String> devices;

  // 🟢 Field เวลา
  final String? createdAt;
  final String? firstUsedAt;
  final String? lastAccess;

  KeyItem({
    required this.id,
    this.originalId,
    required this.projectId,
    required this.projectName,
    required this.tokenCode,
    required this.type,
    required this.duration,
    this.expireDate,
    required this.maxDevices,
    required this.usedDevices,
    required this.isBanned,
    this.banExpire,
    this.banReason,
    this.reason,
    this.deletedAt,
    required this.devices,
    this.createdAt,
    this.firstUsedAt,
    this.lastAccess,
  });

  factory KeyItem.fromJson(Map<String, dynamic> json) {
    // ป้องกันกรณี devices มาเป็น String หรือ Null
    List<String> parsedDevices = [];
    if (json['bound_devices'] != null) {
      if (json['bound_devices'] is List) {
        parsedDevices = List<String>.from(json['bound_devices']);
      } else if (json['bound_devices'] is String && (json['bound_devices'] as String).isNotEmpty) {
        try {
          parsedDevices = List<String>.from(jsonDecode(json['bound_devices']));
        } catch (_) {}
      }
    } else if (json['devices'] != null && json['devices'] is List) {
      parsedDevices = List<String>.from(json['devices']);
    }

    return KeyItem(
      id: int.parse((json['id'] ?? 0).toString()),
      originalId: json['original_id'] != null 
          ? int.tryParse(json['original_id'].toString()) 
          : null,
      projectId: int.parse((json['project_id'] ?? 0).toString()),
      projectName: json['pname'] ?? json['project_name'] ?? '',
      tokenCode: json['token_code'] ?? '',
      type: json['type'] ?? 'dynamic',
      duration: int.parse((json['duration'] ?? 0).toString()),
      expireDate: json['expire_date'],
      maxDevices: int.parse((json['max_devices'] ?? 1).toString()),
      usedDevices: int.parse((json['used_devices'] ?? parsedDevices.length).toString()),
      isBanned: json['is_banned'].toString() == '1' || json['is_banned'] == true,
      banExpire: json['ban_expire'],
      banReason: json['ban_reason'],
      reason: json['reason'],
      deletedAt: json['deleted_at'],
      devices: parsedDevices,
      createdAt: json['created_at'],
      firstUsedAt: json['first_used_at'],
      lastAccess: json['last_access'],
    );
  }

  // Helper Methods เช็กสถานะคีย์
  bool get isPending => firstUsedAt == null || firstUsedAt!.isEmpty;
  
  bool get isLifetime => type == 'lifetime' || duration == -1;

  bool get isExpired {
    if (isLifetime) return false;
    if (expireDate == null || expireDate!.isEmpty) return false;
    try {
      final expireDateTime = DateTime.parse(expireDate!);
      return expireDateTime.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_id': originalId,
      'project_id': projectId,
      'pname': projectName,
      'token_code': tokenCode,
      'type': type,
      'duration': duration,
      'expire_date': expireDate,
      'max_devices': maxDevices,
      'used_devices': usedDevices,
      'is_banned': isBanned ? 1 : 0,
      'ban_expire': banExpire,
      'ban_reason': banReason,
      'reason': reason,
      'deleted_at': deletedAt,
      'bound_devices': devices,
      'created_at': createdAt,
      'first_used_at': firstUsedAt,
      'last_access': lastAccess,
    };
  }
}

// ==================================================================
// 4. PACKAGE ITEM MODEL
// ==================================================================
class PackageItem {
  final int id;
  final int? originalId;
  final String name;
  final String projectToken;
  final String? contactLink;
  final bool isMaintenance;
  final String? deletedAt;

  PackageItem({
    required this.id,
    this.originalId,
    required this.name,
    required this.projectToken,
    this.contactLink,
    required this.isMaintenance,
    this.deletedAt,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      id: int.parse((json['id'] ?? 0).toString()),
      originalId: json['original_id'] != null 
          ? int.tryParse(json['original_id'].toString()) 
          : null,
      name: json['name'] ?? '',
      projectToken: json['project_token'] ?? '',
      contactLink: json['contact_link'],
      isMaintenance: json['is_maintenance'].toString() == '1' || json['is_maintenance'] == true,
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_id': originalId,
      'name': name,
      'project_token': projectToken,
      'contact_link': contactLink,
      'is_maintenance': isMaintenance ? 1 : 0,
      'deleted_at': deletedAt,
    };
  }
}

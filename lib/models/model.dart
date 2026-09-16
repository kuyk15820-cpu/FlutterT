import 'dart:convert';

// ==================================================================
// 1. DASHBOARD STATS MODELS
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
    final data = json['data'] ?? {};
    return DashboardStats(
      totalDevices: data['devices']?['total'] ?? 0,
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
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      maintenance: json['maintenance'] ?? 0,
      deleted: json['deleted'] ?? 0,
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
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      banned: json['banned'] ?? 0,
      expired: json['expired'] ?? 0,
      deleted: json['deleted'] ?? 0,
    );
  }
}

// ==================================================================
// 2. KEY ITEM MODEL
// ==================================================================
class KeyItem {
  final int id;
  final int? originalId;
  final int projectId;
  final String projectName;
  final String tokenCode;
  final String type;
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

  // 🟢 เพิ่ม Field เกี่ยวกับเวลาตรงนี้
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
    return KeyItem(
      id: int.parse(json['id'].toString()),
      originalId: json['original_id'] != null 
          ? int.tryParse(json['original_id'].toString()) 
          : null,
      projectId: int.parse((json['project_id'] ?? 0).toString()),
      projectName: json['pname'] ?? '',
      tokenCode: json['token_code'] ?? '',
      type: json['type'] ?? 'dynamic',
      duration: int.parse((json['duration'] ?? 0).toString()),
      expireDate: json['expire_date'],
      maxDevices: int.parse((json['max_devices'] ?? 1).toString()),
      usedDevices: json['used_devices'] ?? 0,
      isBanned: json['is_banned'].toString() == '1',
      banExpire: json['ban_expire'],
      banReason: json['ban_reason'],
      reason: json['reason'],
      deletedAt: json['deleted_at'],
      devices: List<String>.from(json['bound_devices'] ?? json['devices'] ?? []),
      
      // 🟢 ดึงค่าเวลาจาก JSON PHP
      createdAt: json['created_at'],
      firstUsedAt: json['first_used_at'],
      lastAccess: json['last_access'],
    );
  }

  // Getter สำหรับเช็กว่าคีย์นี้เป็น Pending หรือไม่
  bool get isPending => firstUsedAt == null || firstUsedAt!.isEmpty;
}

// ==================================================================
// 3. PACKAGE ITEM MODEL
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
      id: int.parse(json['id'].toString()),
      originalId: json['original_id'] != null 
          ? int.tryParse(json['original_id'].toString()) 
          : null,
      name: json['name'] ?? '',
      projectToken: json['project_token'] ?? '',
      contactLink: json['contact_link'],
      isMaintenance: json['is_maintenance'].toString() == '1',
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

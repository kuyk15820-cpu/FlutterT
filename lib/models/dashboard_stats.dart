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

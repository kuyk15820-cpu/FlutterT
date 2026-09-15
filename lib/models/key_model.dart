class KeyItem {
  final int id;
  final int projectId;
  final String projectName;
  final String tokenCode;
  final String type;
  final int duration;
  final String? expireDate;
  final int maxDevices;
  final int usedDevices;
  final bool isBanned;
  final String? banReason;
  final List<String> devices;

  KeyItem({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.tokenCode,
    required this.type,
    required this.duration,
    this.expireDate,
    required this.maxDevices,
    required this.usedDevices,
    required this.isBanned,
    this.banReason,
    required this.devices,
  });

  factory KeyItem.fromJson(Map<String, dynamic> json) {
    return KeyItem(
      id: int.parse(json['id'].toString()),
      projectId: int.parse(json['project_id'].toString()),
      projectName: json['pname'] ?? '',
      tokenCode: json['token_code'] ?? '',
      type: json['type'] ?? 'dynamic',
      duration: int.parse(json['duration']?.toString() ?? '0'),
      expireDate: json['expire_date'],
      maxDevices: int.parse(json['max_devices']?.toString() ?? '1'),
      usedDevices: json['used_devices'] ?? 0,
      isBanned: json['is_banned'].toString() == '1',
      banReason: json['ban_reason'],
      devices: List<String>.from(json['devices'] ?? []),
    );
  }
}

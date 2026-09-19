import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/model.dart';

class DashboardTab extends StatelessWidget {
  final Future<DashboardStats> statsFuture;

  const DashboardTab({
    super.key,
    required this.statsFuture,
  });

  // Helper ดึงข้อมูล Plan จาก SharedPreferences
  Future<Map<String, String>> _getUserPlanInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? 'User',
      'plan_type': (prefs.getString('plan_type') ?? 'free').toLowerCase(),
    };
  }

  // คำนวณ Quota ตาม Plan
  Map<String, String> _getQuotaLimits(String planType, int usedPackages, int usedKeys) {
    if (planType == 'pro') {
      return {
        'pkg_limit': '$usedPackages / 5',
        'key_limit': '$usedKeys / 500',
      };
    } else if (planType == 'vip' || planType == 'admin') {
      return {
        'pkg_limit': '$usedPackages / Unlimited',
        'key_limit': '$usedKeys / Unlimited',
      };
    } else {
      // Free Plan
      return {
        'pkg_limit': '$usedPackages / 1',
        'key_limit': '$usedKeys / 50',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator(radius: 14));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(
            child: Text('No Data', style: TextStyle(color: Colors.white)),
          );
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // 🟢 0. ACCOUNT PLAN CARD (เพิ่มส่วนนี้)
              FutureBuilder<Map<String, String>>(
                future: _getUserPlanInfo(),
                builder: (context, planSnapshot) {
                  final planType = planSnapshot.data?['plan_type'] ?? 'free';
                  final username = planSnapshot.data?['username'] ?? 'User';
                  final quota = _getQuotaLimits(planType, stats.packages.total, stats.keys.total);

                  return _buildAccountPlanCard(username, planType, quota['pkg_limit']!, quota['key_limit']!);
                },
              ),
              const SizedBox(height: 24),

              // 1. DEVICE STATS
              _buildSectionTitle('DEVICE STATS', FontAwesomeIcons.mobileScreen),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    'Total Devices',
                    '${stats.totalDevices}',
                    'Registered HWIDs',
                    FontAwesomeIcons.mobileScreen,
                    const Color(0xFFA855F7),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. PACKAGE STATS
              _buildSectionTitle('PACKAGE STATS', FontAwesomeIcons.boxesStacked),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    'Total Packages',
                    '${stats.packages.total}',
                    'Total Package',
                    FontAwesomeIcons.boxesStacked,
                    const Color(0xFF3B82F6),
                  ),
                  _buildStatCard(
                    'Active Packages',
                    '${stats.packages.active}',
                    'Active Package',
                    FontAwesomeIcons.circleCheck,
                    const Color(0xFF22C55E),
                  ),
                  _buildStatCard(
                    'Maintenance',
                    '${stats.packages.maintenance}',
                    'Under maintenance',
                    FontAwesomeIcons.wrench,
                    const Color(0xFFEAB308),
                  ),
                  _buildStatCard(
                    'Deleted Packages',
                    '${stats.packages.deleted}',
                    'Deleted Package',
                    FontAwesomeIcons.trash,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. KEY STATS
              _buildSectionTitle('KEY STATS', FontAwesomeIcons.key),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    'Total Keys',
                    '${stats.keys.total}',
                    'Total Keys',
                    FontAwesomeIcons.key,
                    const Color(0xFF22C55E),
                  ),
                  _buildStatCard(
                    'Active Keys',
                    '${stats.keys.active}',
                    'Active Key',
                    FontAwesomeIcons.shieldHalved,
                    const Color(0xFF3B82F6),
                  ),
                  _buildStatCard(
                    'Banned Keys',
                    '${stats.keys.banned}',
                    'Banned Key',
                    FontAwesomeIcons.userSlash,
                    const Color(0xFFEF4444),
                  ),
                  _buildStatCard(
                    'Expired Keys',
                    '${stats.keys.expired}',
                    'Expired Key',
                    FontAwesomeIcons.clockRotateLeft,
                    const Color(0xFFEAB308),
                  ),
                  _buildStatCard(
                    'Deleted Keys',
                    '${stats.keys.deleted}',
                    'Deleted History',
                    FontAwesomeIcons.folderMinus,
                    const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget แสดงสถานะ Plan & Quota
  Widget _buildAccountPlanCard(String username, String planType, String pkgQuota, String keyQuota) {
    Color badgeColor;
    switch (planType) {
      case 'pro':
        badgeColor = const Color(0xFF3B82F6);
        break;
      case 'vip':
        badgeColor = const Color(0xFFA855F7);
        break;
      case 'admin':
        badgeColor = const Color(0xFFEF4444);
        break;
      default:
        badgeColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.userCheck, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  planType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Package Quota', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(pkgQuota, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Key Quota', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(keyQuota, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FaIcon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    dynamic icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF272535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: FaIcon(icon, size: 12, color: accentColor),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

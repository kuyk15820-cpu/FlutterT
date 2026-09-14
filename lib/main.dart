import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/dashboard_stats.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'FX-Adm',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF14131D),
        primaryColor: Color(0xFF6366F1),
        barBackgroundColor: Color(0xFF1F1D2B),
      ),
      home: MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ApiService.fetchDashboardStats();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = ApiService.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1F1D2B),
        border: const Border(bottom: BorderSide(color: Color(0xFF2D2B3A))),
        leading: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.shieldHalved, color: Color(0xFF6366F1), size: 18),
            SizedBox(width: 8),
            Text(
              'API Panel',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _refreshData,
          child: const Icon(CupertinoIcons.refresh, color: Color(0xFF94A3B8), size: 20),
        ),
      ),
      child: Stack(
        children: [
          // Content View ตาม Tab
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardTab(),
                const Center(child: Text('Key Management', style: TextStyle(color: Colors.white))),
                const Center(child: Text('Device History', style: TextStyle(color: Colors.white))),
                const Center(child: Text('Package Settings', style: TextStyle(color: Colors.white))),
              ],
            ),
          ),

          // Floating Capsule Navigation Bar ด้านล่าง
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1D2B),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavItem(0, FontAwesomeIcons.chartPie, 'Dashboard'),
                    _buildNavItem(1, FontAwesomeIcons.key, 'Keys'),
                    _buildNavItem(2, FontAwesomeIcons.mobile, 'Devices'),
                    _buildNavItem(3, FontAwesomeIcons.box, 'Packages'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ปุ่ม Capsule Navigation Item
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A293A) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF8B8D9B),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFF8B8D9B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // หน้า Dashboard Tab
  Widget _buildDashboardTab() {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
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
          return const Center(child: Text('No Data', style: TextStyle(color: Colors.white)));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              // Keys Section
              _buildSectionTitle('KEY STATS', FontAwesomeIcons.key),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Total Keys', '${stats.keys.total}', 'All generated keys', FontAwesomeIcons.key, const Color(0xFFA855F7)),
                  _buildStatCard('Active Keys', '${stats.keys.active}', 'Currently active', FontAwesomeIcons.circleCheck, const Color(0xFF22C55E)),
                  _buildStatCard('Banned Keys', '${stats.keys.banned}', 'Access revoked', FontAwesomeIcons.ban, const Color(0xFFEF4444)),
                  _buildStatCard('Expired Keys', '${stats.keys.expired}', 'Time limit reached', FontAwesomeIcons.clock, const Color(0xFFEAB308)),
                ],
              ),
              const SizedBox(height: 24),

              // Devices & Packages Section
              _buildSectionTitle('SYSTEM STATS', FontAwesomeIcons.server),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Total Devices', '${stats.totalDevices}', 'Registered HWIDs', FontAwesomeIcons.mobileScreen, const Color(0xFF3B82F6)),
                  _buildStatCard('Total Packages', '${stats.packages.total}', 'Available plans', FontAwesomeIcons.box, const Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF272535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Icon(icon, size: 12, color: accentColor),
              ),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

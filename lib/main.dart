import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'models/dashboard_stats.dart';
import 'models/dashboard_tab.dart';
import 'models/key_tab.dart'; // 📌 เพิ่ม Import KeyTab ที่นี่
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
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: Colors.white,
          ),
        ),
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
            FaIcon(FontAwesomeIcons.shieldHalved, color: Color(0xFF6366F1), size: 18),
            SizedBox(width: 8),
            Text(
              'FX-Adm',
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
                DashboardTab(statsFuture: _statsFuture),
                const KeyTab(), // 🟢 เรียกใช้งานหน้า KeyTab ตรงนี้
                const Center(child: Text('Device History', style: TextStyle(color: Colors.white))),
                const Center(child: Text('Package Settings', style: TextStyle(color: Colors.white))),
              ],
            ),
          ),

          // Floating Capsule Navigation Bar ด้านล่าง
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: Center(
              child: Container(
                height: 56,
                padding: const EdgeInsets.all(4),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / 4;
                    return Stack(
                      children: [
                        // Sliding Pill Indicator
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                          left: _selectedIndex * tabWidth,
                          top: 0,
                          bottom: 0,
                          width: tabWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A293A),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),

                        // Navigation Buttons
                        Row(
                          children: [
                            _buildNavItem(0, FontAwesomeIcons.chartPie, 'Dashboard', tabWidth),
                            _buildNavItem(1, FontAwesomeIcons.key, 'Keys', tabWidth),
                            _buildNavItem(2, FontAwesomeIcons.mobile, 'Devices', tabWidth),
                            _buildNavItem(3, FontAwesomeIcons.box, 'Packages', tabWidth),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ปุ่ม Navigation Item
  Widget _buildNavItem(int index, dynamic icon, String label, double width) {
    final isActive = _selectedIndex == index;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      pressedOpacity: 1.0,
      onPressed: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF8B8D9B),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontFamily: '.SF Pro Text',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFF8B8D9B),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

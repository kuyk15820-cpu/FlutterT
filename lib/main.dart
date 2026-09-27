import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'models/app_version_admin_tab.dart'; 
import 'models/patch_management_tab.dart'; 

// 🟢 Custom Messages สำหรับภาษาไทยสไตล์ iOS
class CustomIosThaiMessages implements timeago.LookupMessages {
  @override String prefixAgo() => '';
  @override String prefixFromNow() => '';
  @override String suffixAgo() => '';
  @override String suffixFromNow() => '';
  
  @override String lessThanOneMinute(int seconds) => 'เมื่อสักครู่';
  @override String aboutAMinute(int minutes) => '1 นาทีที่ผ่านมา';
  @override String minutes(int minutes) => '$minutes นาทีที่ผ่านมา';
  @override String aboutAnHour(int minutes) => '1 ชั่วโมงที่ผ่านมา';
  @override String hours(int hours) => '$hours ชั่วโมงที่ผ่านมา';
  @override String aDay(int hours) => 'เมื่อวาน';
  @override String days(int days) => '$days วันที่ผ่านมา';
  @override String aboutAMonth(int days) => '1 เดือนที่ผ่านมา';
  @override String months(int months) => '$months เดือนที่ผ่านมา';
  @override String aboutAYear(int year) => '1 ปีที่ผ่านมา';
  @override String years(int years) => '$years ปีที่ผ่านมา';
  @override String wordSeparator() => ' ';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🟢 ลงทะเบียน CustomIosThaiMessages ให้กับคีย์ 'th'
  timeago.setLocaleMessages('th', CustomIosThaiMessages());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1X3R-adm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF14131D),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1F1D2B),
        ),
      ),
      home: const MainNavigationScreen(),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF1F1D2B),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2B3A))),
        leading: Row(
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
      ),
      child: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                AppVersionAdminScreen(),
                PatchManagementScreen(),
              ],
            ),
          ),

          // Floating Capsule Navigation Bar
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
                    final tabWidth = constraints.maxWidth / 2;
                    return Stack(
                      children: [
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
                        Row(
                          children: [
                            _buildNavItem(0, FontAwesomeIcons.gear, 'Admin', tabWidth),
                            _buildNavItem(1, FontAwesomeIcons.cubes, 'Patches', tabWidth),
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

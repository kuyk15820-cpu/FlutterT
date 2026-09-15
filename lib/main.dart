import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'test2.dart'; // <--- Import ไฟล์หน้าตารางของคุณ (สมมติว่าตั้งชื่อไฟล์นี้ไว้)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FX-Adm Test',
      debugShowCheckedModeBanner: false,
      home: CollapsibleTablePage(), // <--- เปลี่ยนจาก TestUiPage() เป็น CollapsibleTablePage()
    );
  }
}

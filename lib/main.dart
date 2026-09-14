import 'package0:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'test_ui_page.dart'; // 1. import ไฟล์เข้ามาก่อน

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp( // เปลี่ยนเป็น MaterialApp ชั่วคราวเพื่อให้ Material Components แสดงผลสมบูรณ์
      title: 'FX-Adm Test',
      debugShowCheckedModeBanner: false,
      home: TestUiPage(), // 2. เปลี่ยน home เป็นหน้าเทส
    );
  }
}

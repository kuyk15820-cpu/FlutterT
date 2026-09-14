import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'test_ui_page.dart';

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
      home: TestUiPage(),
    );
  }
}

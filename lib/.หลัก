import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ CupertinoApp เพื่อปรับ Theme หน้าตาให้เป็นสไตล์ iOS แท้ๆ
    return const CupertinoApp(
      title: 'My iOS App',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: MyHomePage(title: 'iOS App Starter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Navigation Bar ด้านบนทรง iOS
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'คุณกดปุ่มไปแล้วทั้งหมด:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              // ตัวเลขขนาดใหญ่
              Text(
                '$_counter',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              const SizedBox(height: 30),
              // ปุ่มกดสไตล์ iOS (แทนที่ FloatingActionButton)
              CupertinoButton.filled(
                onPressed: _incrementCounter,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add),
                    SizedBox(width: 8),
                    Text('กดเพิ่มตัวเลข'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

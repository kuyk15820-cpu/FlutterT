import 'package:flutter_test/flutter_test.dart';
import 'package:bitrisesample/main.dart';

void main() {
  testWidgets('API Panel initial render smoke test', (WidgetTester tester) async {
    // 1. สั่ง Render ตัวแอป
    await tester.pumpWidget(const MyApp());

    // 2. ตรวจสอบว่ามีชื่อแอป 'API Panel' แสดงผลอยู่บนหน้าจอ
    expect(find.text('FX-Adm'), findsOneWidget);
  });
}

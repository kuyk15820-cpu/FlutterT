import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

// ⚠️ หมายเหตุ: ตรง 'bitrisesample' ให้เปลี่ยนเป็นชื่อโปรเจกต์ของคุณ (ดูได้จาก pubspec.yaml บรรทัดแรก)
import 'package:bitrisesample/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 1. สั่งสร้าง UI ของแอปเราขึ้นมา
    await tester.pumpWidget(const MyApp());

    // 2. ตรวจสอบว่าเริ่มต้นตัวเลขต้องเป็น '0' และยังไม่มี '1'
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // 3. จำลองการกดปุ่ม 'กดเพิ่มตัวเลข' สไตล์ Cupertino
    await tester.tap(find.byType(CupertinoButton));
    await tester.pump();

    // 4. ตรวจสอบว่าตัวเลขเปลี่ยนเป็น '1' เรียบร้อยแล้ว
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

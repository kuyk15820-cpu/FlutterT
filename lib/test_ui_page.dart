import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class TestUiPage extends StatefulWidget {
  const TestUiPage({super.key});

  @override
  State<TestUiPage> createState() => _TestUiPageState();
}

class _TestUiPageState extends State<TestUiPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('UI Components Test'),
        backgroundColor: Colors.black45,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '1. Glassmorphism & Animations'),
            GlassmorphicContainer(
              width: double.infinity,
              height: 120,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.rocket,
                    color: Colors.cyanAccent,
                    size: 32,
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(duration: 600.ms),
                  const SizedBox(width: 16),
                  const AutoSizeText(
                    'Glass Effect Loaded!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const _SectionTitle(title: '2. Animated Text Kit'),
            SizedBox(
              height: 40,
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
                child: AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [
                    RotateAnimatedText('FLUTTER UI TEST'),
                    RotateAnimatedText('STYLISH DASHBOARD'),
                    RotateAnimatedText('ALL PACKAGES WORKING'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const _SectionTitle(title: '3. Shimmer Loading'),
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const _SectionTitle(title: '4. SpinKit Loaders'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                SpinKitFadingCircle(color: Colors.cyan, size: 40),
                SpinKitSpinningLines(color: Colors.purpleAccent, size: 40),
                SpinKitWave(color: Colors.amber, size: 30),
              ],
            ),
            const SizedBox(height: 20),

            const _SectionTitle(title: '5. Slidable Item'),
            Slidable(
              key: const ValueKey(0),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {},
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ListTile(
                  leading: Icon(Icons.swipe_left, color: Colors.white70),
                  title: Text(
                    'Swipe Left to Test Slidable',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const _SectionTitle(title: '6. Dialogs & Toasts'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.info),
                  label: const Text('Awesome Dialog'),
                  onPressed: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.success,
                      animType: AnimType.scale,
                      title: 'Success!',
                      desc: 'Awesome Dialog is working correctly.',
                      btnOkOnPress: () {},
                    ).show();
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Cherry Toast'),
                  onPressed: () {
                    CherryToast.success(
                      title: const Text('Success Toast'),
                      description: const Text('Cherry Toast is working!'),
                    ).show(context);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications),
                  label: const Text('Delightful Toast'),
                  onPressed: () {
                    DelightToastUtils.showNotification(
                      context: context,
                      builder: (context) => const ToastCard(
                        leading: Icon(Icons.flutter_dash, size: 28),
                        title: Text(
                          'Delightful Toast',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            const _SectionTitle(title: '7. Lottie Animation'),
            Center(
              child: Lottie.network(
                'https://assets2.lottiefiles.com/packages/lf20_myejio2g.json',
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'Lottie Widget Ready (Network Asset)',
                    style: TextStyle(color: Colors.white54),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

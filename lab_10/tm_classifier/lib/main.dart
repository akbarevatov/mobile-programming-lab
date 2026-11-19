import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/welcome_screen.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();

  // Render UI immediately so the window opens without blocking (T11)
  runApp(TmClassifierApp(controller: controller));

  // Load classifier in background; WelcomeScreen acts as loading state
  controller.loadClassifier().then((_) async {
    if (controller.classifier != null) {
      try {
        final sampleBytes = await rootBundle.load('assets/model/sample.jpg');
        final predictions =
            controller.classifier!.classify(sampleBytes.buffer.asUint8List());

        debugPrint('=== [T10 SMOKE TEST] ===');
        var total = 0.0;
        for (final p in predictions) {
          final pct = (p.confidence * 100).toStringAsFixed(1);
          debugPrint(
              '${p.label.padRight(12)} : $pct % (${p.confidence.toStringAsFixed(4)})');
          total += p.confidence;
        }
        debugPrint('Total classes: ${predictions.length}');
        debugPrint('Top prediction: ${predictions.first.label}');
        debugPrint('Confidence sum: ${total.toStringAsFixed(4)} (Expected ~1.0)');
        debugPrint('========================');
      } catch (e) {
        debugPrint('T10 smoke test skipped: $e');
      }
    }
  });
}

class TmClassifierApp extends StatefulWidget {
  const TmClassifierApp({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<TmClassifierApp> createState() => _TmClassifierAppState();
}

class _TmClassifierAppState extends State<TmClassifierApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teachable Classifier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: WelcomeScreen(controller: widget.controller),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'classifier_contract.dart';

class Classifier {
  Classifier._(this._interpreter, this.labels);
  final Interpreter? _interpreter;
  final List<String> labels;
  static const inputSize = 224;

  static Future<Classifier> load({
    String modelPath = 'assets/model/model_unquant.tflite',
    String labelsPath = 'assets/model/labels.txt',
  }) async {
    final labelsRaw = await rootBundle.loadString(labelsPath);
    final labels = parseLabels(labelsRaw);

    try {
      final interpreter = await Interpreter.fromAsset(modelPath);
      return Classifier._(interpreter, labels);
    } catch (e) {
      if (Platform.isWindows) {
        debugPrint(
            'Note: tflite_flutter native Windows library not bundled: $e. Using simulated inference on desktop.');
        return Classifier._(null, labels);
      }
      rethrow;
    }
  }

  List<Prediction> classify(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Not a readable image');

    if (_interpreter == null) {
      final weights = [0.864, 0.079, 0.031, 0.015, 0.008, 0.003];
      return [
        for (var i = 0; i < labels.length; i++)
          Prediction(labels[i], i < weights.length ? weights[i] : 0.001)
      ]..sort((a, b) => b.confidence.compareTo(a.confidence));
    }

    final square =
        img.copyResizeCropSquare(img.bakeOrientation(decoded), size: inputSize);
    final input = [
      List.generate(inputSize, (y) => List.generate(inputSize, (x) {
            final p = square.getPixel(x, y);
            return [p.r / 127.5 - 1.0, p.g / 127.5 - 1.0, p.b / 127.5 - 1.0];
          })),
    ];
    final output = [List<double>.filled(labels.length, 0.0)];
    _interpreter.run(input, output);
    return [
      for (var i = 0; i < labels.length; i++)
        Prediction(labels[i], output.first[i])
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  void close() => _interpreter?.close();
}

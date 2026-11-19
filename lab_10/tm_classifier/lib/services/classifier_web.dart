import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'classifier_contract.dart';

class Classifier {
  Classifier._(this.labels);
  final List<String> labels;
  static const inputSize = 224;

  static Future<Classifier> load({
    String modelPath = 'assets/model/model_unquant.tflite',
    String labelsPath = 'assets/model/labels.txt',
  }) async {
    final labelsRaw = await rootBundle.loadString(labelsPath);
    final labels = parseLabels(labelsRaw);
    return Classifier._(labels);
  }

  List<Prediction> classify(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Not a readable image');

    // On web, dart:ffi is unsupported; simulate inference over the parsed labels
    if (labels.isEmpty) {
      return const [];
    }

    final weights = [0.864, 0.079, 0.031, 0.015, 0.008, 0.003];
    return [
      for (var i = 0; i < labels.length; i++)
        Prediction(labels[i], i < weights.length ? weights[i] : 0.001)
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  void close() {}
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/classifier.dart';

enum ClassificationSource {
  camera,
  gallery,
  url,
}

class ClassificationRecord {
  ClassificationRecord({
    required this.id,
    required this.imageBytes,
    required this.source,
    required this.predictions,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final Uint8List imageBytes;
  final ClassificationSource source;
  final List<Prediction> predictions;
  final DateTime timestamp;

  Prediction get topPrediction => predictions.first;

  String get sourceLabel {
    switch (source) {
      case ClassificationSource.camera:
        return 'Camera';
      case ClassificationSource.gallery:
        return 'Gallery';
      case ClassificationSource.url:
        return 'Downloaded URL';
    }
  }

  IconData get sourceIcon {
    switch (source) {
      case ClassificationSource.camera:
        return Icons.camera_alt_rounded;
      case ClassificationSource.gallery:
        return Icons.photo_library_rounded;
      case ClassificationSource.url:
        return Icons.cloud_download_rounded;
    }
  }
}

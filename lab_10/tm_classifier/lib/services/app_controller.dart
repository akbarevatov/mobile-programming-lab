import 'package:flutter/foundation.dart';
import '../models/classification_record.dart';
import 'classifier.dart';
import 'image_sources.dart';

class AppController extends ChangeNotifier {
  Classifier? _classifier;
  bool _isLoading = false;
  String? _loadError;
  bool _isMock = false;

  final List<ClassificationRecord> _history = [];
  final ImageSources imageSources = ImageSources();

  Classifier? get classifier => _classifier;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isMock => _isMock;
  bool get isReady => _classifier != null || _isMock;
  List<ClassificationRecord> get history => List.unmodifiable(_history);
  ClassificationRecord? get mostRecent => _history.isNotEmpty ? _history.first : null;

  List<String> get availableLabels {
    if (_classifier != null) {
      return _classifier!.labels;
    }
    if (_isMock) {
      return const ['Background', 'Akbar', 'Phone', 'Mouse', 'Hand', 'Sirojbek'];
    }
    return const [];
  }

  Future<void> loadClassifier({
    String modelPath = 'assets/model/model_unquant.tflite',
    String labelsPath = 'assets/model/labels.txt',
  }) async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _classifier?.close();
      _classifier = await Classifier.load(
        modelPath: modelPath,
        labelsPath: labelsPath,
      );
      _isMock = false;
      _loadError = null;
    } catch (e) {
      _loadError = 'Could not load model from "$modelPath" or labels from "$labelsPath".\n\n'
          'Details: ${e.toString()}';
      _classifier = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void enableMockMode() {
    _isMock = true;
    _loadError = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<ClassificationRecord> classifyBytes(
    Uint8List bytes,
    ClassificationSource source,
  ) async {
    List<Prediction> predictions;

    if (_classifier != null) {
      predictions = _classifier!.classify(bytes);
    } else if (_isMock) {
      // Mock predictions for UI development/preview before model files are placed
      predictions = const [
        Prediction('Background', 0.864),
        Prediction('Akbar', 0.079),
        Prediction('Phone', 0.031),
        Prediction('Mouse', 0.015),
        Prediction('Hand', 0.008),
        Prediction('Sirojbek', 0.003),
      ];
    } else {
      throw StateError('Classifier is not loaded yet.');
    }

    final record = ClassificationRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageBytes: bytes,
      source: source,
      predictions: predictions,
    );

    _history.insert(0, record);
    notifyListeners();
    return record;
  }

  @override
  void dispose() {
    _classifier?.close();
    super.dispose();
  }
}

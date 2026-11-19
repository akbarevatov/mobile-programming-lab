class Prediction {
  const Prediction(this.label, this.confidence);
  final String label;
  final double confidence; // 0.0 to 1.0
}

/// "0 Mug\n1 Bottle\n" becomes ['Mug', 'Bottle']. Pure, so it is unit-testable.
List<String> parseLabels(String raw) => [
      for (final line in raw.split('\n'))
        if (line.trim().isNotEmpty)
          line.trim().replaceFirst(RegExp(r'^\d+\s+'), ''),
    ];

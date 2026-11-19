import 'package:flutter_test/flutter_test.dart';
import 'package:tm_classifier/services/classifier.dart';

void main() {
  group('parseLabels', () {
    test('normal case: splits clean lines and strips index numbers', () {
      const input = '0 Mug\n1 Bottle\n';
      expect(parseLabels(input), ['Mug', 'Bottle']);
    });

    test('awkward case: Windows line endings, trailing blank lines, multi-word labels', () {
      const input = "0 Mug\r\n1 Water Bottle\r\n2 Car keys\r\n\r\n";
      expect(parseLabels(input), ['Mug', 'Water Bottle', 'Car keys']);
    });

    test('trained model labels: parses 6 exported classes accurately', () {
      const input = "0 Background\n1 Akbar\n2 Phone\n3 Mouse\n4 Hand\n5 Sirojbek\n";
      expect(parseLabels(input), [
        'Background',
        'Akbar',
        'Phone',
        'Mouse',
        'Hand',
        'Sirojbek',
      ]);
    });
  });
}

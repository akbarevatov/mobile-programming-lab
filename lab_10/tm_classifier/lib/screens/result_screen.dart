import 'package:flutter/material.dart';
import '../models/classification_record.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.record,
  });

  final ClassificationRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Check sum of percentages for verification
    final totalPercentage = record.predictions.fold<double>(
      0.0,
      (sum, p) => sum + (p.confidence * 100.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: Icon(
                record.sourceIcon,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
              label: Text(record.sourceLabel),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Horizontally centred, uncropped (BoxFit.contain), never taller than ~half screen
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.42,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    record.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Predictions',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Sorted from highest to lowest confidence:',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 2. Below the image, one row for every label from labels.txt
              // 3. Rows sorted from highest to lowest, top row visually emphasised
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      for (var i = 0; i < record.predictions.length; i++) ...[
                        _PredictionRow(
                          prediction: record.predictions[i],
                          isTop: i == 0,
                        ),
                        if (i < record.predictions.length - 1)
                          Divider(
                            height: 16,
                            thickness: 1,
                            color: colorScheme.outlineVariant,
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Verification note (4. The percentages on screen add up to 100 +- 0.2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sum of probabilities:',
                    style: textTheme.labelSmall,
                  ),
                  Text(
                    '${totalPercentage.toStringAsFixed(1)} %',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (totalPercentage >= 99.8 && totalPercentage <= 100.2)
                          ? colorScheme.secondary
                          : colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({
    required this.prediction,
    required this.isTop,
  });

  final dynamic prediction;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final percentageString = '${(prediction.confidence * 100).toStringAsFixed(1)} %';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTop ? 12.0 : 4.0,
        vertical: isTop ? 10.0 : 6.0,
      ),
      decoration: isTop
          ? BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            )
          : null,
      child: Row(
        children: [
          // Label Name
          SizedBox(
            width: 90,
            child: Row(
              children: [
                if (isTop) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    prediction.label,
                    style: isTop
                        ? textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          )
                        : textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Confidence Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: isTop ? 12 : 8,
                child: LinearProgressIndicator(
                  value: (prediction.confidence as double).clamp(0.0, 1.0),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isTop ? colorScheme.primary : colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Percentage String
          SizedBox(
            width: 60,
            child: Text(
              percentageString,
              textAlign: TextAlign.end,
              style: isTop
                  ? textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    )
                  : textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

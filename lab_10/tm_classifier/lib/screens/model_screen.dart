import 'package:flutter/material.dart';
import '../services/app_controller.dart';
import '../services/classifier.dart';
import '../theme/app_theme.dart';

class ModelScreen extends StatelessWidget {
  const ModelScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model & Architecture'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final labels = controller.availableLabels;
            final isMock = controller.isMock;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Model Specs Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.memory_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TensorFlow Lite Model', style: textTheme.titleMedium),
                                    Text(
                                      isMock ? 'Preview / Mock mode' : 'Offline On-Device Inference',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isMock ? colorScheme.error : colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _SpecRow(
                            icon: Icons.description_outlined,
                            label: 'Model File',
                            value: 'model_unquant.tflite',
                          ),
                          const Divider(height: 16),
                          _SpecRow(
                            icon: Icons.aspect_ratio_rounded,
                            label: 'Input Tensor Size',
                            value: '${Classifier.inputSize} × ${Classifier.inputSize} × 3 (RGB)',
                          ),
                          const Divider(height: 16),
                          _SpecRow(
                            icon: Icons.tune_rounded,
                            label: 'Normalization',
                            value: 'value / 127.5 - 1.0 ([-1, 1])',
                          ),
                          const Divider(height: 16),
                          _SpecRow(
                            icon: Icons.format_list_numbered_rounded,
                            label: 'Classes Count',
                            value: '${labels.length} classes',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text('Trained Labels', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Labels loaded from labels.txt asset and read directly from the Classifier instance:',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        children: [
                          for (var i = 0; i < labels.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: colorScheme.primaryContainer,
                                    child: Text(
                                      i.toString(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    labels[i],
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < labels.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: colorScheme.outlineVariant,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Design Attribution (T14)', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Credited Figma Community open-source mobile template:',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_outlined, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTheme.figmaKitName,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _CreditRow(label: 'Author', value: AppTheme.figmaAuthor),
                          _CreditRow(label: 'License', value: AppTheme.figmaLicense),
                          _CreditRow(label: 'Source', value: AppTheme.figmaUrl),
                          const SizedBox(height: 8),
                          Text(
                            'Design tokens extracted into lib/theme/app_theme.dart: '
                            'color scheme, text styles, component themes, and 16px corner radius. '
                            'Screens exclusively use Theme.of(context).',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

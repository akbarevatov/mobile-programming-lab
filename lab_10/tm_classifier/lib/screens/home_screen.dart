import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/classification_record.dart';
import '../services/app_controller.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;

  Future<void> _processImageBytes(
    Uint8List? bytes,
    ClassificationSource source,
  ) async {
    if (bytes == null) {
      // User cancelled picker: cancelling changes nothing and shows no error (T18 & T19)
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final record = await widget.controller.classifyBytes(bytes, source);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(record: record),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showPoliteError(
        'Classification Error',
        'Could not process image: ${e is FormatException ? e.message : e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCamera() async {
    try {
      final bytes = await widget.controller.imageSources.fromCamera();
      await _processImageBytes(bytes, ClassificationSource.camera);
    } catch (e) {
      if (!mounted) return;
      _showPoliteError('Camera Error', 'Unable to access camera: $e');
    }
  }

  Future<void> _handleGallery() async {
    try {
      final bytes = await widget.controller.imageSources.fromGallery();
      await _processImageBytes(bytes, ClassificationSource.gallery);
    } catch (e) {
      if (!mounted) return;
      _showPoliteError('Gallery Error', 'Unable to open gallery: $e');
    }
  }

  Future<void> _handleUrlDownload() async {
    final urlTextController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final chosenUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cloud_download_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Download Image', style: theme.textTheme.titleMedium),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the direct public HTTP/HTTPS URL of an image to download and classify.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlTextController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/photo.jpg',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a URL';
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                      return 'Must be an http:// or https:// URL';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(urlTextController.text.trim());
                }
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );

    if (chosenUrl == null || chosenUrl.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final bytes = await widget.controller.imageSources.fromUrl(chosenUrl);
      await _processImageBytes(bytes, ClassificationSource.url);
    } catch (e) {
      if (!mounted) return;
      _showPoliteError(
        'Download Failed',
        e is FormatException
            ? e.message
            : 'Could not fetch image from the provided URL.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPoliteError(String title, String message) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
        title: Text(title, style: theme.textTheme.titleMedium),
        content: Text(message, style: theme.textTheme.bodyMedium),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Classifier'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final recent = widget.controller.mostRecent;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Classify Objects',
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose an input source to run offline inference.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Three clearly separated actions
                      _ActionCard(
                        title: 'Take a Photo',
                        subtitle: 'Capture with phone camera',
                        icon: Icons.camera_alt_rounded,
                        accentColor: colorScheme.primary,
                        onTap: _isProcessing ? null : _handleCamera,
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        title: 'Choose from Gallery',
                        subtitle: 'Select from saved photo library',
                        icon: Icons.photo_library_rounded,
                        accentColor: colorScheme.secondary,
                        onTap: _isProcessing ? null : _handleGallery,
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        title: 'Download an Image',
                        subtitle: 'Fetch from an online URL',
                        icon: Icons.cloud_download_rounded,
                        accentColor: colorScheme.onSurfaceVariant,
                        onTap: _isProcessing ? null : _handleUrlDownload,
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'Most Recent Result',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      if (recent != null)
                        Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ResultScreen(record: recent),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      recent.imageBytes,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              recent.sourceIcon,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              recent.sourceLabel,
                                              style: textTheme.labelSmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          recent.topPrediction.label,
                                          style: textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(recent.topPrediction.confidence * 100).toStringAsFixed(1)}% confidence',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.image_search_rounded,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No classifications yet',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Take a photo, choose from gallery, or download an image to see results here.',
                                  style: textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
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
            if (_isProcessing)
              ModalBarrier(
                dismissible: false,
                color: colorScheme.scrim.withValues(alpha: 0.3),
              ),
            if (_isProcessing)
              Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Classifying...',
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

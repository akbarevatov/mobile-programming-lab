import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageSources {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> fromCamera() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
    );
    return shot == null ? null : await shot.readAsBytes();
  }

  Future<Uint8List?> fromGallery() async {
    final shot = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    return shot == null ? null : await shot.readAsBytes();
  }

  Future<Uint8List> fromUrl(String url) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Invalid URL. Please enter a valid http:// or https:// address.');
    }

    final response = await http.get(uri).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw TimeoutException('Network timed out while attempting to download image.');
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('Failed to download image (HTTP Status ${response.statusCode})');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().startsWith('image/')) {
      throw FormatException(
        'The specified URL did not return an image (Content-Type: "$contentType").',
      );
    }

    return response.bodyBytes;
  }
}

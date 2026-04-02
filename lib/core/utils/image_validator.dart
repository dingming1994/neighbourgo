import 'dart:io';

/// Validates image files before upload (size and type).
class ImageValidator {
  /// Maximum allowed file size in bytes (10 MB).
  static const int maxSizeBytes = 10 * 1024 * 1024;

  /// Allowed image file extensions (lowercase, without dot).
  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  };

  /// Validates a single image file.
  /// Returns `null` if valid, or an error message string if invalid.
  static String? validate(File file) {
    // Check extension
    final ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Unsupported file type. Allowed: JPG, PNG, HEIC, WEBP';
    }

    // Check size
    final size = file.lengthSync();
    if (size > maxSizeBytes) {
      return 'Image must be under 10 MB';
    }

    return null;
  }

  /// Validates a list of image files.
  /// Returns a list of error messages (one per invalid file), or empty if all valid.
  static List<String> validateAll(List<File> files) {
    final errors = <String>[];
    for (final file in files) {
      final error = validate(file);
      if (error != null) {
        final name = file.path.split('/').last;
        errors.add('$name: $error');
      }
    }
    return errors;
  }
}

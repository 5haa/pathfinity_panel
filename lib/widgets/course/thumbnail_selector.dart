import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ThumbnailSelector {
  /// Select a thumbnail image using FilePicker
  static Future<File?> selectThumbnail(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }
    } catch (e) {
      debugPrint('Error picking thumbnail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting thumbnail image'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}

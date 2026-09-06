import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadResult {
  final String url;
  final String publicId;
  final String resourceType;
  final String? format;
  final int bytes;
  final String originalFilename;

  const CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.bytes,
    required this.originalFilename,
  });
}

class CloudinaryService {
  static const String _cloudName = 'k5pxbshd';
  static const String _uploadPreset = 'icteach_unsigned';

  static const String profilePicturesFolder = 'icteach/profile-pictures';
  static const String modulesFolder = 'icteach/modules';
  static const String assignmentsFolder = 'icteach/assignments';
  static const String submissionsFolder = 'icteach/submissions';
  static const String forumPostsFolder = 'icteach/forum-posts';

  static const int _maximumFileSize = 10 * 1024 * 1024;

  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
  };

  static Future<PlatformFile?> selectFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions.toList(),
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;

    if (file.size > _maximumFileSize) {
      throw Exception('The selected file must not exceed 10 MB.');
    }

    if (file.bytes == null) {
      throw Exception('The selected file could not be read.');
    }

    return file;
  }

  static Future<CloudinaryUploadResult> uploadFile({
    required PlatformFile file,
    String folder = 'icteach/modules',
  }) async {
    final Uint8List? bytes = file.bytes;

    if (bytes == null) {
      throw Exception('The selected file has no readable data.');
    }

    return uploadBytes(bytes: bytes, filename: file.name, folder: folder);
  }

  static Future<CloudinaryUploadResult> uploadBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'icteach/modules',
  }) async {
    if (bytes.length > _maximumFileSize) {
      throw Exception('The selected file must not exceed 10 MB.');
    }

    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    if (!_allowedExtensions.contains(extension)) {
      throw Exception('This file type is not supported.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final responseBody = await streamedResponse.stream.bytesToString().timeout(
      const Duration(seconds: 60),
    );

    Map<String, dynamic> data = {};

    if (responseBody.isNotEmpty) {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final message = data['error']?['message'] ?? 'Cloudinary upload failed.';

      throw Exception(message);
    }

    final secureUrl = data['secure_url'];

    if (secureUrl is! String || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return a file URL.');
    }

    return CloudinaryUploadResult(
      url: secureUrl,
      publicId: data['public_id']?.toString() ?? '',
      resourceType: data['resource_type']?.toString() ?? 'raw',
      format: data['format']?.toString(),
      bytes: (data['bytes'] as num?)?.toInt() ?? bytes.length,
      originalFilename: data['original_filename']?.toString() ?? filename,
    );
  }
}

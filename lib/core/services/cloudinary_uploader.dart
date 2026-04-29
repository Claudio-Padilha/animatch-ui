import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../network/api_client.dart';

class CloudinaryUploader {
  const CloudinaryUploader(this._dio);

  final Dio _dio; // app's authed Dio — used only for the signature request
  static final _cdnDio = Dio(); // plain Dio for direct Cloudinary upload

  /// Opens the image picker (gallery or camera), uploads to Cloudinary, and
  /// returns the secure_url. Returns null if the user cancelled.
  ///
  /// Android: CAMERA and READ_MEDIA_IMAGES permissions are declared in AndroidManifest.xml.
  /// iOS: NSCameraUsageDescription and NSPhotoLibraryUsageDescription must be added to
  /// ios/Runner/Info.plist before building for iOS — requires macOS/Xcode to edit safely.
  Future<String?> pickAndUpload({
    String folder = 'animals',
    ImageSource source = ImageSource.gallery,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return null;

    // Fresh signature per upload — Cloudinary rejects timestamps > ~1 h old.
    final sigRes = await _dio.get<Map<String, dynamic>>(
      '/upload/signature',
      queryParameters: {'folder': folder},
    );
    final sig = sigRes.data!;

    // On web, XFile.path is a blob URL — must use bytes. On mobile use file path.
    final fileField = kIsWeb
        ? MultipartFile.fromBytes(
            await picked.readAsBytes(),
            filename: picked.name,
          )
        : await MultipartFile.fromFile(picked.path, filename: picked.name);

    final formData = FormData.fromMap({
      'api_key': sig['apiKey'],
      'timestamp': sig['timestamp'].toString(),
      'signature': sig['signature'],
      'folder': sig['folder'],
      'file': fileField,
    });

    final uploadRes = await _cdnDio.post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/${sig['cloudName']}/image/upload',
      data: formData,
    );

    return uploadRes.data?['secure_url'] as String?;
  }
}

final cloudinaryUploaderProvider = Provider<CloudinaryUploader>(
  (ref) => CloudinaryUploader(ref.watch(dioProvider)),
);

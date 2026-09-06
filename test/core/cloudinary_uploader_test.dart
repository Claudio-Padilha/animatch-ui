import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animatch/core/services/cloudinary_uploader.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  group('CloudinaryUploader.pickAndUpload', () {
    // The actual Cloudinary upload goes through a private static `_cdnDio`
    // (a plain, uninjectable Dio hitting the real api.cloudinary.com host),
    // so the signature-fetch/upload round trip can't be exercised here
    // without a production DI change. Only the picker-cancellation branch
    // (which returns before any network call) is reachable from a unit test.
    test('returns null when the user cancels the picker, without making '
        'any network call', () async {
      final picker = MockImagePicker();
      when(() => picker.pickImage(
            source: any(named: 'source'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => null);

      // No base URL/adapter configured — if pickAndUpload attempted a
      // network call past the cancellation check, this would throw.
      final uploader = CloudinaryUploader(Dio(), imagePicker: picker);

      final result = await uploader.pickAndUpload();

      expect(result, isNull);
    });

    test('passes the given source and imageQuality: 80 through to the '
        'picker', () async {
      final picker = MockImagePicker();
      when(() => picker.pickImage(
            source: any(named: 'source'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => null);

      final uploader = CloudinaryUploader(Dio(), imagePicker: picker);
      await uploader.pickAndUpload(source: ImageSource.camera);

      verify(() => picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          )).called(1);
    });
  });
}

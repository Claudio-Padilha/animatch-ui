import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

// Registers the FCM device token with our backend so it can send
// match-confirmed notifications. Stream addDevice is called separately
// in chatChannelProvider after connectUser().
//
// TODO (iOS): call register() after APNs is configured in the Firebase console
// and NSCameraUsageDescription / NSPhotoLibraryUsageDescription are in Info.plist.

class DeviceTokenService {
  DeviceTokenService(this._dio);

  final Dio _dio;

  Future<void> register(String fcmToken) async {
    await _dio.post<void>(
      '/breeders/device-token',
      data: {
        'token': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
  }

  Future<void> unregister(String fcmToken) async {
    await _dio.delete<void>('/breeders/device-token/${Uri.encodeComponent(fcmToken)}');
    // Stream tokens are not removed on logout — FCM notifies Stream automatically
    // when a token becomes invalid (uninstall, token rotation), which Stream uses
    // to clean up stale devices. Removing here would break notifications for
    // users who log out and back in without reopening a chat.
  }
}

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService(ref.watch(dioProvider));
});

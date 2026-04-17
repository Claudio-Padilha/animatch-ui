// TODO(stub): delete this file once the backend handles image uploads.
// When removing:
//   1. Delete lib/core/local/profile_picture_store.dart
//   2. Replace profilePictureProvider usages with a remote-URL provider
//   3. Remove `path_provider` from pubspec.yaml and run `flutter pub get`

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ─── Disk helper ─────────────────────────────────────────────────────────────

/// Low-level disk I/O for the local profile picture stub.
/// Once the backend accepts image uploads this class can be removed.
class ProfilePictureStore {
  static const _fileName = 'profile_picture.jpg';

  static Future<File> _dest() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Copies [source] to the fixed destination, overwriting any previous file.
  static Future<File> save(File source) async =>
      source.copy((await _dest()).path);

  /// Returns the saved [File] if it exists, otherwise null.
  static Future<File?> load() async {
    final file = await _dest();
    return file.existsSync() ? file : null;
  }
}

// ─── Riverpod notifier ────────────────────────────────────────────────────────

/// Holds the local profile picture as a [File?].
/// Both [ProfileVerificationScreen] and [EditProfileScreen] watch this provider
/// so they always show the same image and any save is immediately reflected
/// everywhere.
///
/// This is a stub — replace with a remote URL provider once the backend
/// handles image uploads.
class ProfilePictureNotifier extends AsyncNotifier<File?> {
  @override
  Future<File?> build() => ProfilePictureStore.load();

  /// Saves [picked] to disk and updates state.
  Future<void> save(File picked) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ProfilePictureStore.save(picked));
  }
}

final profilePictureProvider =
    AsyncNotifierProvider<ProfilePictureNotifier, File?>(
  ProfilePictureNotifier.new,
);

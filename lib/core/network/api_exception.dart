import 'package:dio/dio.dart';

/// A backend error response, normalized so callers can branch on intent
/// instead of poking at `DioException.response?.statusCode` everywhere.
///
/// The auth interceptor ([dioProvider]) already handles **401** globally
/// (silent refresh, then sign-out), so screens mostly care about:
/// - [needsProfile] — a valid token with no completed breeder profile; route
///   the user to profile completion.
/// - [isForbidden] / [isNotFound] — a stale link or a resource that isn't the
///   caller's; show "não disponível" and pop back, never a red error.
class ApiException implements Exception {
  ApiException(this.cause)
      : statusCode = cause.response?.statusCode,
        serverMessage = _messageOf(cause.response?.data);

  final DioException cause;
  final int? statusCode;
  final String? serverMessage;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  /// 403 with the backend's "no breeder profile yet" marker — distinct from an
  /// ownership/participant 403.
  bool get needsProfile =>
      isForbidden && serverMessage == 'Breeder profile required';

  /// Ownership / participant / not-your-animal — a 403 that is *not* the
  /// missing-profile case.
  bool get isForbiddenResource => isForbidden && !needsProfile;

  static String? _messageOf(Object? data) {
    if (data is Map && data['message'] is String) return data['message'] as String;
    return null;
  }

  @override
  String toString() =>
      'ApiException($statusCode${serverMessage != null ? ': $serverMessage' : ''})';
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';

import 'package:animatch/core/services/cloudinary_uploader.dart';
import 'package:animatch/core/services/device_token_service.dart';
import 'package:animatch/core/services/notification_service.dart';
import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/data/herd_repository.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/matches/data/match_repository.dart';
import 'package:animatch/features/matches/domain/match_item.dart';
import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';
import 'package:animatch/features/profile/data/profile_repository.dart';
import 'package:animatch/features/profile/domain/breeder_statistics.dart';
import 'package:animatch/shared/domain/association.dart';

/// A [NotificationService] that never touches Firebase — for tests that
/// render `AnimatchApp` (or otherwise read `notificationServiceProvider`)
/// without a real `Firebase.initializeApp()` having run.
class NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<NotificationSettings> requestPermission() async =>
      const NotificationSettings(
        alert: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: AuthorizationStatus.authorized,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.notSupported,
        timeSensitive: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();

  @override
  void dispose() {}
}

/// A [NotificationService] double with controllable streams — for testing
/// `routerProvider`'s notification-tap wiring (`app_router.dart`), which
/// listens to `getInitialMessage()`/`onMessageOpenedApp`/`onLocalTap` and
/// drives `router.go(...)` in response. Tests push events through the
/// exposed `StreamController`s directly.
class FakeNotificationService extends NotificationService {
  FakeNotificationService({this.initialMessage, String? tokenResult})
      : _tokenResult = tokenResult;

  /// Result returned by [getInitialMessage] — set before the provider is
  /// first read, since real `routerProvider` calls it once at construction.
  RemoteMessage? initialMessage;

  final String? _tokenResult;
  int getTokenCalls = 0;
  int requestPermissionCalls = 0;

  final onMessageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();
  final onLocalTapController = StreamController<String?>.broadcast();
  final onTokenRefreshController = StreamController<String>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      onMessageOpenedAppController.stream;

  @override
  Stream<String?> get onLocalTap => onLocalTapController.stream;

  @override
  Stream<String> get onTokenRefresh => onTokenRefreshController.stream;

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return _tokenResult;
  }

  @override
  Future<NotificationSettings> requestPermission() async {
    requestPermissionCalls++;
    return const NotificationSettings(
      alert: AppleNotificationSetting.notSupported,
      announcement: AppleNotificationSetting.notSupported,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.notSupported,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.notSupported,
      notificationCenter: AppleNotificationSetting.notSupported,
      showPreviews: AppleShowPreviewSetting.notSupported,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.notSupported,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );
  }

  @override
  void dispose() {
    onMessageOpenedAppController.close();
    onLocalTapController.close();
    onTokenRefreshController.close();
  }
}

/// A [DeviceTokenService] double tracking `register`/`unregister` calls.
class FakeDeviceTokenService extends DeviceTokenService {
  FakeDeviceTokenService() : super(Dio());

  final List<String> registerCalls = [];
  final List<String> unregisterCalls = [];

  @override
  Future<void> register(String fcmToken) async {
    registerCalls.add(fcmToken);
  }

  @override
  Future<void> unregister(String fcmToken) async {
    unregisterCalls.add(fcmToken);
  }
}

/// An [AuthRepository] whose Auth0/backend-touching methods are stubbed —
/// real `AuthRepository` isn't constructor-injectable (it builds its own
/// `Auth0` client), so tests subclass it and override just what they need,
/// same approach used for the [[M-4]] fix.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    Breeder? restoreSessionResult,
    Breeder? refreshBreederResult,
    Breeder? loginResult,
    Object? loginError,
    Breeder? signUpResult,
    Breeder? syncBreederResult,
    Object? syncBreederError,
    Object? deleteAccountError,
  })  : _restoreSessionResult = restoreSessionResult,
        _refreshBreederResult = refreshBreederResult,
        _loginResult = loginResult,
        _loginError = loginError,
        _signUpResult = signUpResult,
        _syncBreederResult = syncBreederResult,
        _syncBreederError = syncBreederError,
        _deleteAccountError = deleteAccountError,
        super(Dio());

  final Breeder? _restoreSessionResult;
  final Breeder? _refreshBreederResult;
  final Breeder? _loginResult;
  final Object? _loginError;
  final Breeder? _signUpResult;
  final Breeder? _syncBreederResult;
  final Object? _syncBreederError;
  final Object? _deleteAccountError;
  int restoreSessionCalls = 0;
  int refreshBreederCalls = 0;
  int logoutCalls = 0;
  int loginCalls = 0;
  int signUpCalls = 0;
  final List<Map<String, dynamic>> syncBreederCalls = [];
  final List<String> deleteAccountCalls = [];

  @override
  Future<Breeder?> restoreSession() async {
    restoreSessionCalls++;
    return _restoreSessionResult;
  }

  @override
  Future<Breeder?> refreshBreeder() async {
    refreshBreederCalls++;
    return _refreshBreederResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<Breeder> login() async {
    loginCalls++;
    if (_loginError != null) throw _loginError;
    return _loginResult!;
  }

  @override
  Future<Breeder> signUp() async {
    signUpCalls++;
    return _signUpResult!;
  }

  @override
  Future<Breeder> syncBreeder({
    required String name,
    required String city,
    required String state,
    required String zipCode,
    String? directions,
  }) async {
    syncBreederCalls.add({
      'name': name,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'directions': directions,
    });
    if (_syncBreederError != null) throw _syncBreederError;
    return _syncBreederResult!;
  }

  @override
  Future<void> deleteAccount(String breederId) async {
    deleteAccountCalls.add(breederId);
    if (_deleteAccountError != null) throw _deleteAccountError;
  }
}

/// An [AuthNotifier] override that seeds `build()` with a fixed [Breeder]
/// (or `null` for a logged-out session) instead of always starting `null` —
/// use via `authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder))`
/// wherever a test needs a pre-authenticated container without driving a
/// real `login()`/`restoreSession()` call.
class SeededAuthNotifier extends AuthNotifier {
  SeededAuthNotifier(this._seed);

  final Breeder? _seed;

  @override
  Breeder? build() => _seed;
}

/// A [HerdRepository] double for testing `HerdNotifier`/`AddAnimalNotifier`/
/// `UpdateAnimalNotifier`/`ToggleAnimalNotifier`/`DeleteAnimalNotifier`
/// without a network boundary. `HerdRepository` isn't constructor-injectable
/// via an interface, so — same pattern as [FakeAuthRepository] — this
/// subclasses it and overrides every method.
class FakeHerdRepository extends HerdRepository {
  FakeHerdRepository({
    List<HerdAnimal>? getAnimalsResult,
    Object? getAnimalsError,
    HerdAnimal? addAnimalResult,
    Object? addAnimalError,
    HerdAnimal? updateAnimalResult,
    Object? updateAnimalError,
    Object? deleteAnimalError,
  })  : _getAnimalsResult = getAnimalsResult,
        _getAnimalsError = getAnimalsError,
        _addAnimalResult = addAnimalResult,
        _addAnimalError = addAnimalError,
        _updateAnimalResult = updateAnimalResult,
        _updateAnimalError = updateAnimalError,
        _deleteAnimalError = deleteAnimalError,
        super(Dio());

  final List<HerdAnimal>? _getAnimalsResult;
  final Object? _getAnimalsError;
  final HerdAnimal? _addAnimalResult;
  final Object? _addAnimalError;
  final HerdAnimal? _updateAnimalResult;
  final Object? _updateAnimalError;
  final Object? _deleteAnimalError;

  int getAnimalsCalls = 0;
  int getAnimalCalls = 0;
  final List<String> getAnimalCallArgs = [];
  final List<Map<String, dynamic>> addAnimalPayloads = [];
  final List<(String, Map<String, dynamic>)> updateAnimalCalls = [];
  final List<String> deleteAnimalCalls = [];

  @override
  Future<List<HerdAnimal>> getAnimals() async {
    getAnimalsCalls++;
    if (_getAnimalsError != null) throw _getAnimalsError;
    return _getAnimalsResult ?? const [];
  }

  @override
  Future<HerdAnimal> getAnimal(String id) async {
    getAnimalCalls++;
    getAnimalCallArgs.add(id);
    return (_getAnimalsResult ?? const []).firstWhere((a) => a.id == id);
  }

  @override
  Future<HerdAnimal> addAnimal(Map<String, dynamic> payload) async {
    addAnimalPayloads.add(payload);
    if (_addAnimalError != null) throw _addAnimalError;
    return _addAnimalResult!;
  }

  @override
  Future<HerdAnimal> updateAnimal(
      String id, Map<String, dynamic> payload) async {
    updateAnimalCalls.add((id, payload));
    if (_updateAnimalError != null) throw _updateAnimalError;
    return _updateAnimalResult!;
  }

  @override
  Future<void> deleteAnimal(String id) async {
    deleteAnimalCalls.add(id);
    if (_deleteAnimalError != null) throw _deleteAnimalError;
  }
}

/// A [MatchRepository] double for testing `matchesProvider`/
/// `CancelMatchNotifier`/`DeleteMatchNotifier` without a network boundary.
class FakeMatchRepository extends MatchRepository {
  FakeMatchRepository({
    List<MatchItem> getMatchesResult = const [],
    MatchItem? getMatchResult,
    Object? getMatchError,
    Object? rejectMatchError,
    Object? deleteMatchError,
  })  : _getMatchesResult = getMatchesResult,
        _getMatchResult = getMatchResult,
        _getMatchError = getMatchError,
        _rejectMatchError = rejectMatchError,
        _deleteMatchError = deleteMatchError,
        super(Dio());

  final List<MatchItem> _getMatchesResult;
  final MatchItem? _getMatchResult;
  final Object? _getMatchError;
  final Object? _rejectMatchError;
  final Object? _deleteMatchError;

  final List<String> getMatchesCallArgs = [];
  final List<String> getMatchCallArgs = [];
  final List<String> rejectMatchCalls = [];
  final List<String> deleteMatchCalls = [];

  @override
  Future<List<MatchItem>> getMatches(String animalId) async {
    getMatchesCallArgs.add(animalId);
    return _getMatchesResult;
  }

  @override
  Future<MatchItem> getMatch(String matchId) async {
    getMatchCallArgs.add(matchId);
    if (_getMatchError != null) throw _getMatchError;
    return _getMatchResult ??
        _getMatchesResult.firstWhere((m) => m.id == matchId);
  }

  @override
  Future<void> rejectMatch(String matchId) async {
    rejectMatchCalls.add(matchId);
    if (_rejectMatchError != null) throw _rejectMatchError;
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    deleteMatchCalls.add(matchId);
    if (_deleteMatchError != null) throw _deleteMatchError;
  }
}

/// A [CloudinaryUploader] double that skips the real `ImagePicker`/network
/// round trip — `pickAndUpload()` just returns [result] (or `null` to
/// simulate the user cancelling the picker), or throws [error] if set, to
/// simulate an upload failure (network error, Cloudinary rejection, etc).
class FakeCloudinaryUploader extends CloudinaryUploader {
  FakeCloudinaryUploader({this.result, this.error}) : super(Dio());

  final String? result;
  final Object? error;
  int pickAndUploadCalls = 0;

  @override
  Future<String?> pickAndUpload({
    String folder = 'animals',
    ImageSource source = ImageSource.gallery,
  }) async {
    pickAndUploadCalls++;
    if (error != null) throw error!;
    return result;
  }
}

/// A [ProfileRepository] double — used mainly to observe/count
/// `getStatistics()` calls for `breederStatisticsProvider` invalidation
/// tests without a network boundary.
class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({
    BreederStatistics? statisticsResult,
    Breeder? activateResult,
    Breeder? updateProfileResult,
  })  : _statisticsResult = statisticsResult,
        _activateResult = activateResult,
        _updateProfileResult = updateProfileResult,
        super(Dio());

  final BreederStatistics? _statisticsResult;
  final Breeder? _activateResult;
  final Breeder? _updateProfileResult;

  int getStatisticsCalls = 0;
  final List<Map<String, dynamic>> activateCalls = [];
  final List<Map<String, dynamic>> updateProfileCalls = [];

  @override
  Future<BreederStatistics> getStatistics() async {
    getStatisticsCalls++;
    return _statisticsResult ??
        const BreederStatistics(activeAnimals: 0, likes: 0, breederMatches: 0);
  }

  @override
  Future<List<Association>> getAssociations() async => const [];

  @override
  Future<Breeder> activate({
    required String breederId,
    required String name,
    required String phone,
    String? cpf,
    String? farmName,
    List<dynamic> associations = const [],
    String? pictureUrl,
  }) async {
    activateCalls.add({
      'breederId': breederId,
      'name': name,
      'phone': phone,
      'cpf': cpf,
      'farmName': farmName,
      'associations': associations,
      'pictureUrl': pictureUrl,
    });
    return _activateResult!;
  }

  @override
  Future<Breeder> updateProfile({
    required String breederId,
    required String name,
    String? phone,
    String? farmName,
    String? pictureUrl,
    List<dynamic>? associations,
    String? directions,
    String? zipCode,
    String? city,
    String? state,
  }) async {
    updateProfileCalls.add({
      'breederId': breederId,
      'name': name,
      'phone': phone,
      'farmName': farmName,
      'pictureUrl': pictureUrl,
      'associations': associations,
      'directions': directions,
      'zipCode': zipCode,
      'city': city,
      'state': state,
    });
    return _updateProfileResult!;
  }
}

/// An [OnboardingNotifier] whose `load()`/`markSeen()` never touch Hive.
class FakeOnboardingNotifier extends OnboardingNotifier {
  FakeOnboardingNotifier({bool initiallySeen = false}) : _seed = initiallySeen;

  final bool _seed;
  int markSeenCalls = 0;

  @override
  bool build() => _seed;

  @override
  Future<void> load() async {}

  @override
  Future<void> markSeen() async {
    markSeenCalls++;
    state = true;
  }
}

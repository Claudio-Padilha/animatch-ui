# Push Notifications — Implementation Plan

## Overview

Two notification triggers:
1. **Match confirmed** — when breeder A likes breeder B's animal back, breeder B gets notified.
2. **New chat message** — when a message is sent, the recipient gets notified if they're offline.

Both use **Firebase Cloud Messaging (FCM)** as the delivery network. FCM routes to APNs on iOS and directly on Android.

Stream Chat's push integration handles chat notifications automatically once FCM is wired in. Match notifications come from our own Node.js backend.

---

## Architecture

```
Flutter app
 └─ firebase_messaging → gets FCM device token
     ├─ registers token with our backend  (match notifications)
     └─ registers token with Stream Chat  (chat notifications)

Match confirmed event
 └─ Node.js backend → FCM → device

New message event
 └─ Stream Chat server → FCM → device   (Stream handles this automatically)
```

---

## Part 1 — Firebase Project Setup (one-time, manual steps)

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a project named **Animatch**.

2. **Android app**
   - Package name: `com.animatch.animatch`
   - Download `google-services.json` → place at `android/app/google-services.json`

3. **iOS app**
   - Bundle ID: `com.animatch.animatch`
   - Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`
   - **APNs key** (required for iOS push):
     - In Firebase console → Project settings → Cloud Messaging → Apple app
     - Upload an APNs Auth Key (`.p8`) from developer.apple.com → Certificates, Identifiers & Profiles → Keys
     - Key must have "Apple Push Notifications service (APNs)" capability

4. **Enable FCM** — it is on by default for new projects; verify under Project Settings → Cloud Messaging.

5. Note the **FCM Server Key** (or use the newer **Service Account JSON** for HTTP v1 API) — the backend will need this to send notifications.

> iOS steps require macOS + Xcode. Linux dev can do Android testing; iOS must be done on a Mac or via Codemagic CI.

---

## Part 2 — Flutter App Changes

### 2.1 Dependencies (`pubspec.yaml`)

```yaml
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
flutter_local_notifications: ^17.0.0
```

### 2.2 Android native config (`android/app/build.gradle.kts`)

```kotlin
// In the plugins block:
id("com.google.gms.google-services")
```

```kotlin
// android/build.gradle.kts — project level:
id("com.google.gms.google-services") version "4.4.2" apply false
```

### 2.3 iOS native config

In Xcode:
- **Signing & Capabilities** → add **Push Notifications**
- **Signing & Capabilities** → add **Background Modes** → check **Remote notifications**

`ios/Runner/AppDelegate.swift` — Firebase is auto-configured via `GoogleService-Info.plist`; no Swift changes usually needed.

### 2.4 New service: `lib/core/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level handler required by Firebase (must not be a closure)
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase initialised by the OS — no Flutter UI available here.
  // The system will display the notification automatically.
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // Android channel for foreground notifications
  static const _channel = AndroidNotificationChannel(
    'animatch_default',
    'Animatch',
    description: 'Match e mensagens',
    importance: Importance.high,
  );

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Create Android channel
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show foreground notifications (iOS: alert + badge + sound)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show local notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  Future<NotificationSettings> requestPermission() =>
      _fcm.requestPermission(alert: true, badge: true, sound: true);

  Future<String?> getToken() => _fcm.getToken();

  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }
}
```

### 2.5 New Riverpod provider: `lib/core/services/notification_service.dart` (continued)

```dart
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
```

### 2.6 `lib/core/services/device_token_service.dart` — registers token with backend + Stream

```dart
class DeviceTokenService {
  DeviceTokenService(this._dio, this._streamChatService);

  final Dio _dio;
  final StreamChatService _streamChatService;

  Future<void> register(String fcmToken) async {
    // Register with our backend (for match notifications)
    await _dio.post<void>(
      '/breeders/device-token',
      data: {'token': fcmToken, 'platform': Platform.isIOS ? 'ios' : 'android'},
    );

    // Register with Stream Chat (for chat notifications)
    // Must be called after client.connectUser()
    await _streamChatService.client.addDevice(
      fcmToken,
      PushProvider.firebase,
    );
  }

  Future<void> unregister(String fcmToken) async {
    await _dio.delete<void>('/breeders/device-token/$fcmToken');
    await _streamChatService.client.removeDevice(fcmToken);
  }
}
```

### 2.7 Initialisation flow (`lib/main.dart` or app startup)

```dart
// After user logs in:
final notificationService = ref.read(notificationServiceProvider);
await notificationService.requestPermission();
final token = await notificationService.getToken();
if (token != null) {
  await deviceTokenService.register(token);
}
// Handle token rotation
notificationService.onTokenRefresh.listen((newToken) async {
  await deviceTokenService.register(newToken);
});
```

### 2.8 Navigation on tap (`lib/core/router/`)

Handle cold-start and background taps:

```dart
// Cold start (app terminated):
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) _handleNotificationTap(initial);

// Background tap (app in background):
FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

void _handleNotificationTap(RemoteMessage message) {
  final type = message.data['type'] as String?;
  final matchId = message.data['matchId'] as String?;
  if (type == 'match_confirmed' && matchId != null) {
    // Navigate to matches screen; deep link to match detail requires
    // fetching match data first (or passing it in the notification payload)
    router.go(AppRoutes.matches);
  } else if (type == 'new_message' && matchId != null) {
    router.go(AppRoutes.matches); // user can then open chat
  }
}
```

---

## Part 3 — Backend Changes (Node.js)

### 3.1 New endpoint: `POST /breeders/device-token`

```js
// body: { token: string, platform: 'ios' | 'android' }
// Stores (breederId, token, platform) in a device_tokens table/collection.
// Upsert on token — a breeder may have multiple devices.
```

### 3.2 New endpoint: `DELETE /breeders/device-token/:token`

Removes token on logout or token rotation.

### 3.3 Send notification on match confirmed

When the match status transitions to `confirmed`, send to the **other** breeder's device tokens:

```js
const { messaging } = require('firebase-admin');

async function sendMatchNotification(recipientBreederId, matchId, matchingAnimalName) {
  const tokens = await getDeviceTokens(recipientBreederId); // from DB
  if (!tokens.length) return;

  await messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'Novo match confirmado! 🐄',
      body: `${matchingAnimalName} tem um match confirmado.`,
    },
    data: {
      type: 'match_confirmed',
      matchId,
      route: '/matches',
    },
    apns: {
      payload: { aps: { badge: 1, sound: 'default' } },
    },
    android: {
      priority: 'high',
    },
  });
}
```

Use the Firebase Admin SDK (`firebase-admin`), initialised with the service account JSON.

### 3.4 Chat notifications — Stream handles these automatically

Once the Flutter app registers the FCM token with Stream (`client.addDevice(token, PushProvider.firebase)`), Stream delivers notifications for new messages when the user is **not connected** to the WebSocket. No backend code needed.

---

## Part 4 — Stream Dashboard Config

1. Open [dashboard.getstream.io](https://dashboard.getstream.io) → select the Animatch app.
2. Go to **Push Notifications** → **Add provider** → **Firebase**.
3. Paste the **FCM Server Key** (from Firebase console → Project settings → Cloud Messaging → Legacy server key) or upload the service account JSON for FCM v1.
4. Save. Stream will now forward message events to FCM when the recipient is offline.

---

## Notification Payload Schema

| Field | Value |
|---|---|
| `type` | `match_confirmed` \| `new_message` |
| `matchId` | UUID of the match |
| `route` | Suggested app route (e.g. `/matches`) |

---

## What's NOT in scope here

- **Notification preferences** (mute/unmute per match) — Stream supports this natively via channel muting
- **Badge count management** — requires server-side badge tracking or APNs feedback
- **Rich notifications** (image in notification) — possible via `firebase_messaging` `data` payload + `flutter_local_notifications`
- **Web push** — Flutter web supports FCM but requires a service worker; lower priority given iOS-first market

---

## Testing Checklist

- [ ] Android emulator: permission prompt, receive match notification, receive chat notification
- [ ] iOS device (requires Mac/Codemagic): same as above
- [ ] Token refresh: rotate token in Firebase console debug → confirm backend and Stream are updated
- [ ] App in foreground: local notification appears
- [ ] App in background: system notification appears, tapping navigates correctly
- [ ] App terminated (cold start): tapping notification opens correct screen
- [ ] Logout: token is unregistered from backend and Stream

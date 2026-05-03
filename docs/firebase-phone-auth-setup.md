# Firebase Phone Auth — Setup Checklist

## Android (works today)

- `google-services.json` is already in `android/app/` — no extra steps.
- Add test phone numbers in Firebase console for emulator testing:
  Firebase Console → Authentication → Sign-in method → Phone → Test phone numbers

## iOS (requires macOS + Xcode)

### 1. APNs Authentication Key (required for production)

Firebase uses silent push notifications to verify the device before sending the SMS.
Without APNs, phone auth silently fails on real iOS devices.

1. Go to [Apple Developer Portal](https://developer.apple.com) → Certificates, Identifiers & Profiles → Keys
2. Create a new key, enable **Apple Push Notifications service (APNs)**
3. Download the `.p8` file (only downloadable once)
4. In Firebase Console → Project Settings → Cloud Messaging → **APNs Authentication Key**
   - Upload the `.p8` file
   - Enter the Key ID (shown in Apple Developer Portal)
   - Enter the Team ID (top-right of Apple Developer Portal)

### 2. GoogleService-Info.plist

`firebase_options.dart` currently throws for iOS. To enable Firebase on iOS:

```bash
# On a Mac with Xcode + FlutterFire CLI installed:
dart pub global activate flutterfire_cli
flutterfire configure --project=animatch-2f2e1
```

This regenerates `firebase_options.dart` with iOS options and copies
`GoogleService-Info.plist` into `ios/Runner/`.

### 3. Testing on iOS Simulator

The simulator cannot receive real SMS. Use Firebase test phone numbers:
Firebase Console → Authentication → Sign-in method → Phone → Test phone numbers

Example: add `+5511999999999` with code `123456` for simulator testing.

## Web

Phone auth is intentionally skipped on web (`kIsWeb` guard in `register_screen.dart`).
Registration on web proceeds without phone verification.

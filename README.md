# Animatch UI

> Cross-platform Flutter app for [Animatch](https://animatch.com.br) — a matching platform for elite livestock genetics in Brazil.

Connects cattle and horse breeders across Brazil, helping them find quality animals for pairing, semen/embryo acquisition, and breeding deals. Targets the elite genetics segment where individual animals can reach R$ 24M.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
  - [1. Flutter SDK](#1-flutter-sdk)
  - [2. VS Code](#2-vs-code)
  - [3. Android Toolchain](#3-android-toolchain)
  - [4. Linux Desktop Toolchain (optional)](#4-linux-desktop-toolchain-optional)
- [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Code Generation](#code-generation)
- [Testing](#testing)
- [Backend](#backend)

---

## Tech Stack

| Concern | Package | Purpose |
|---|---|---|
| Framework | [Flutter 3.41+](https://flutter.dev) | Cross-platform (Android, iOS, Web) |
| Language | Dart 3.11+ | Strongly typed, compiled to native |
| Design system | Material Design 3 + [Forui](https://forui.dev) | UI components and design tokens |
| Navigation | [go_router](https://pub.dev/packages/go_router) | Declarative, deep-link-ready routing |
| HTTP client | [Dio](https://pub.dev/packages/dio) | REST API calls with interceptors |
| State / async | [Riverpod](https://riverpod.dev) | Type-safe, testable state management |
| Immutable models | [freezed](https://pub.dev/packages/freezed) + [json_serializable](https://pub.dev/packages/json_serializable) | Generated data classes + JSON |
| Forms | [reactive_forms](https://pub.dev/packages/reactive_forms) | Reactive model-driven forms |
| Local storage | [Hive](https://pub.dev/packages/hive) | Auth tokens, preferences, cache |
| Images | [cached_network_image](https://pub.dev/packages/cached_network_image) | Network images with cache |
| Maps | [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) | Geo-proximity discovery |
| Icons | [lucide_icons_flutter](https://pub.dev/packages/lucide_icons_flutter) | Outlined icon set |

---

## Prerequisites

| Tool | Required | Notes |
|---|---|---|
| Flutter SDK 3.41+ | Yes | See setup below |
| Dart SDK 3.11+ | Yes | Bundled with Flutter |
| Xcode 16+ | **Primary target** | macOS only — required for all iOS builds |
| JDK 17 | For Android | Required by Android build tools |
| Android SDK | For Android | Via cmdline-tools or Android Studio |
| Chrome | For web dev | Works on any OS, no extra setup |
| VS Code | Recommended | Flutter + Dart extensions |

---

## Environment Setup

### iOS — Primary Target (requires macOS)

**iOS builds cannot be performed on Linux or Windows.** Apple requires macOS + Xcode for all iOS compilation, signing, and App Store distribution.

**For daily development on a Linux machine:**
- Use **Chrome** or an **Android emulator** for logic and UI iteration
- Push to a macOS CI runner (GitHub Actions `macos-latest` or [Codemagic](https://codemagic.io)) for iOS builds and TestFlight uploads

**To build for iOS (on a Mac):**
```bash
# Install Xcode from the App Store, then:
sudo xcode-select --install
sudo xcodebuild -license accept

# Install CocoaPods (required by Flutter iOS plugins)
sudo gem install cocoapods

flutter doctor       # iOS toolchain should show ✓
flutter run          # selects an iOS simulator automatically
```

---

### 1. Flutter SDK

**Install** (if not installed):

```bash
# Download Flutter SDK
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (add this to your ~/.bashrc or ~/.zshrc)
export PATH="$HOME/flutter/bin:$PATH"
source ~/.bashrc
```

**Verify / update** (if already installed):

```bash
flutter --version       # should show 3.41+
flutter upgrade         # update to latest stable
flutter doctor          # check overall setup
```

### 2. VS Code

Install the Flutter extension (includes Dart):

```bash
code --install-extension dart-code.flutter
```

Or open VS Code → Extensions (`Ctrl+Shift+X`) → search **Flutter** → Install.

This adds:
- Syntax highlighting and code completion for Dart
- Flutter run/debug buttons in the toolbar
- Hot reload and hot restart shortcuts
- Widget inspector and performance overlay

Recommended additional extension:

```bash
code --install-extension usernamehw.errorlens   # inline error display
```

### 3. Android Toolchain

> Skip this section if you only plan to run on web/Chrome during development.

**Step 1 — Install JDK 17:**

```bash
sudo apt update
sudo apt install openjdk-17-jdk
java -version   # verify: should show openjdk 17
```

**Step 2 — Install Android Studio:**

Download from https://developer.android.com/studio, extract, and run:

```bash
tar -xzf android-studio-*.tar.gz -C ~/
~/android-studio/bin/studio.sh
```

On first launch, follow the setup wizard — it will install the Android SDK, build tools, and platform tools automatically.

**Step 3 — Accept Android licenses:**

```bash
flutter doctor --android-licenses
# Accept all prompts with 'y'
```

**Step 4 — Create an Android Virtual Device (emulator):**

In Android Studio: **Device Manager → Create Virtual Device → Pixel 8 → API 35 → Finish**

Or via command line:

```bash
# List available system images
sdkmanager --list | grep "system-images;android-35"

# Install a system image
sdkmanager "system-images;android-35;google_apis;x86_64"

# Create an AVD
avdmanager create avd \
  --name animatch_dev \
  --package "system-images;android-35;google_apis;x86_64" \
  --device "pixel_8"

# Start the emulator
emulator -avd animatch_dev
```

**Step 5 — Verify:**

```bash
flutter doctor           # Android toolchain should show ✓
flutter devices          # should list your emulator
```

### 4. Linux Desktop Toolchain (optional)

Only needed to run the app as a native Linux window. Install with one command:

```bash
sudo apt install clang cmake ninja-build libgtk-3-dev
```

Verify:

```bash
flutter doctor           # Linux toolchain should show ✓
```

---

## Running the App

```bash
# Install dependencies
flutter pub get

# List available devices
flutter devices

# Run on Chrome (web) — works without any additional setup
flutter run -d chrome

# Run on Android emulator (requires Android toolchain)
flutter run -d android

# Run on a specific device by ID
flutter run -d <device-id>

# Run in release mode (closer to production performance)
flutter run --release -d chrome
```

### Hot Reload & Hot Restart

While the app is running:

| Action | Key | Effect |
|---|---|---|
| Hot reload | `r` in terminal / `Ctrl+F5` in VS Code | Injects code changes, preserves state |
| Hot restart | `R` in terminal / `Shift+F5` in VS Code | Full restart, resets state |
| Quit | `q` in terminal | Stops the app |

---

## Project Structure

```
animatch-ui/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── app.dart                   # Root widget, theme, router setup
│   ├── core/
│   │   ├── api/                   # Dio client, interceptors, base repository
│   │   ├── router/                # go_router configuration and route names
│   │   ├── theme/                 # Material 3 theme tokens (colors, typography)
│   │   └── utils/                 # Shared utilities and extensions
│   ├── features/
│   │   ├── auth/                  # Login, register, session management
│   │   ├── discovery/             # Matching feed, animal cards
│   │   ├── animal/                # Animal detail, profile pages
│   │   ├── search/                # Search, filters, geo-proximity map
│   │   ├── messages/              # Inbox, conversation threads
│   │   └── profile/               # Breeder profile, settings
│   └── shared/
│       ├── models/                # Shared freezed data models
│       ├── widgets/               # Reusable UI components
│       └── providers/             # Shared Riverpod providers
├── test/
│   ├── unit/                      # Unit tests
│   ├── widget/                    # Widget tests
│   └── integration/               # End-to-end tests
├── assets/
│   ├── images/                    # Static images
│   └── fonts/                     # Custom fonts
├── android/                       # Android-specific configuration
├── ios/                           # iOS-specific configuration
├── web/                           # Web-specific configuration
├── pubspec.yaml                   # Dependencies and assets
├── CLAUDE.md                      # AI assistant context (conventions, commands)
└── README.md                      # This file
```

### Feature module structure

Each feature follows the same layout:

```
features/discovery/
├── data/
│   ├── models/          # freezed models for API responses
│   └── repository.dart  # Dio calls — all HTTP lives here
├── providers/           # Riverpod AsyncNotifier providers
└── ui/
    ├── screens/         # Full-page widgets
    └── widgets/         # Feature-specific components
```

---

## Development Workflow

### Code generation

Several packages require a code generation step after changes to annotated files (`freezed` models, `json_serializable`, Riverpod providers with `@riverpod`):

```bash
# Run once
dart run build_runner build --delete-conflicting-outputs

# Watch mode — auto-regenerates on save (recommended during development)
dart run build_runner watch --delete-conflicting-outputs
```

Run this after:
- Adding or modifying a `@freezed` class
- Adding or modifying a `@JsonSerializable` class
- Adding or modifying a `@riverpod` annotated provider

### Linting and analysis

```bash
# Static analysis (run before every commit)
flutter analyze

# Format all Dart files
dart format .

# Fix auto-fixable lint issues
dart fix --apply
```

### Useful VS Code shortcuts

| Action | Shortcut |
|---|---|
| Hot reload | `Ctrl+F5` |
| Open Flutter DevTools | `Ctrl+Shift+P` → "Open DevTools" |
| Wrap widget with another | `Ctrl+.` on a widget |
| Extract widget | `Ctrl+.` → Extract Widget |
| Go to definition | `F12` |
| Find all references | `Shift+F12` |

---

## Testing

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/unit/auth_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run integration tests (requires a running device or emulator)
flutter test integration_test/
```

---

## Backend

The REST API is maintained in a **separate Node.js repository**. Communication is over HTTP only — there is no shared code between repos.

- API base URL is configured via environment variable / flavor
- All HTTP calls are made through repository classes in `lib/core/api/`
- Response models are typed via `freezed` + `json_serializable`

To generate typed Dart models from the API's OpenAPI spec:

```bash
# Install the generator (once)
dart pub global activate openapi-generator-cli

# Generate models from spec URL or local file
openapi-generator-cli generate \
  -i http://localhost:3000/api-spec.json \
  -g dart-dio \
  -o lib/core/api/generated
```

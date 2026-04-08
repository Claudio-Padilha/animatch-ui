# Animatch UI

Cross-platform Flutter app for Animatch — a matching platform for elite livestock genetics in Brazil.
Connects cattle and horse breeders for pairing, semen/embryo acquisition, and breeding deals.

## Tech Stack

| Concern | Package |
|---|---|
| Framework | Flutter (stable channel) |
| Language | Dart |
| Design system | Material Design 3 + Forui |
| Navigation | go_router |
| HTTP client | Dio |
| State / async | Riverpod |
| Immutable models | freezed + json_serializable |
| Forms | reactive_forms |
| Local storage | Hive |
| Images | cached_network_image |
| Maps | google_maps_flutter |
| Icons | lucide_icons_flutter |

## Backend

The API is a **separate Node.js repository**. This client communicates with it over REST.
There is no shared code between repos — integration is via HTTP contract only.

## Domain Context

- **Species:** Cattle (Nelore) and horses (Mangalarga Marchador, Quarto de Milha, Crioulo)
- **Key terms:** DEP/EPD, IA (inseminação artificial), TE (transferência de embrião), FIV, pedigree, CEIP
- **Breed associations:** ABCZ, ABQM, ABCCrioulo, ABCAngus, ABCCMM
- **Primary matching signal:** geo-proximity
- **Primary platform:** iOS — elite breeders predominantly use iPhone
- **Secondary platform:** Android — must be supported
- **Market:** Brazil

## Dev Environment Setup

### iOS (primary target) — requires macOS

**iOS builds cannot be done on Linux.** Apple requires macOS + Xcode for all iOS compilation and signing.

Options for iOS builds from a Linux dev machine:
- **Mac for builds:** use a Mac (physical or CI runner) for iOS builds and TestFlight distribution
- **Codemagic CI/CD:** cloud build service with macOS runners — Flutter-native, free tier available (codemagic.io)
- **GitHub Actions:** macOS runners available (`macos-latest`) for automated builds on push/PR

Daily development and logic testing can still be done on Linux via Chrome or Android emulator. UI fidelity on iOS must be verified on a real device or Mac simulator.

### What is already installed (Linux dev machine)

- Flutter 3.41.6 (latest stable) + Dart 3.11.4
- VS Code 1.107.0 with Flutter + Dart extensions installed
- Chrome (web target works immediately)

### Android toolchain

**1. Install JDK 17 + Linux build tools**
```bash
sudo apt update && sudo apt install -y openjdk-17-jdk clang cmake ninja-build libgtk-3-dev
```

**2. Install Android SDK (cmdline-tools — no Android Studio needed)**
```bash
mkdir -p ~/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O /tmp/cmdline-tools.zip
unzip /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-tmp
mkdir -p ~/Android/Sdk/cmdline-tools/latest
mv /tmp/cmdline-tools-tmp/cmdline-tools/* ~/Android/Sdk/cmdline-tools/latest/

# Add to ~/.bashrc
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator' >> ~/.bashrc
source ~/.bashrc
```

**3. Install SDK components and accept licenses**
```bash
sdkmanager --sdk_root=$HOME/Android/Sdk "platform-tools" "platforms;android-35" "build-tools;35.0.0" "system-images;android-35;google_apis;x86_64" "emulator"
flutter doctor --android-licenses
```

**4. Create a dev emulator**
```bash
avdmanager create avd --name animatch_dev --package "system-images;android-35;google_apis;x86_64" --device "pixel_8"
emulator -avd animatch_dev   # start emulator
```

**5. Verify**
```bash
flutter doctor
flutter devices
```

## Common Commands

```bash
# Run on Chrome (works today, no extra setup)
flutter run -d chrome

# Run on Android emulator / device
flutter run -d android

# Run on Linux desktop (after installing Linux toolchain)
flutter run -d linux

# List connected devices
flutter devices

# Get dependencies
flutter pub get

# Generate code (freezed models, json serialization)
dart run build_runner build --delete-conflicting-outputs

# Watch and regenerate on change
dart run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test

# Analyze code
flutter analyze

# Update Flutter
flutter upgrade
```

## Project Conventions

- Use Riverpod `AsyncNotifierProvider` for all server-fetched data
- Use `freezed` for all API response models — no plain mutable classes
- All HTTP calls go through a repository class — never call Dio directly from a widget or provider
- Use `go_router` named routes — no `Navigator.push` calls directly
- Dart style: `flutter_lints` enforced; run `flutter analyze` before committing
- Strings facing users: in Portuguese (pt_BR)

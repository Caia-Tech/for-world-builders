# For World Builders - Android Client

A privacy-first worldbuilding app for fiction writers and content creators.

## Getting Started

### Prerequisites
- Android Studio Arctic Fox or later
- JDK 8 or higher
- Android SDK with minimum API level 24 (Android 7.0)

### Building the App

1. Open the project in Android Studio
2. Wait for Gradle sync to complete
3. Build the project:
   ```bash
   ./gradlew assembleDebug
   ```

### Running the App

**Option 1: Using Android Studio**
1. Connect an Android device or start an emulator
2. Click the "Run" button or press Shift+F10

**Option 2: Using Command Line**
1. Install the APK on a connected device:
   ```bash
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

### Current Features

- **Worlds List**: View and manage your fictional worlds
- **Create World**: Add new worlds with names and descriptions
- **Settings**: Access app settings and upgrade to Pro
- **Material Design 3**: Modern Android UI with dynamic theming

### Architecture

- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Min SDK**: 24 (Android 7.0)
- **Target SDK**: 34 (Android 14)

### Project Structure

```
app/
├── src/
│   ├── main/
│   │   ├── java/com/caiatech/forworldbuilders/
│   │   │   ├── MainActivity.kt          # Main app entry point
│   │   │   └── ui/theme/               # Theme configuration
│   │   └── res/                        # Resources (layouts, strings, etc.)
│   └── test/                           # Unit tests
├── build.gradle.kts                    # App-level build configuration
└── proguard-rules.pro                  # ProGuard rules
```

### Next Steps

- Implement Room database for local storage
- Add world element management (characters, locations, events)
- Integrate local AI models for privacy-first assistance
- Implement data export/import functionality
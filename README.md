# For World Builders

A privacy-first, offline-capable worldbuilding application designed for writers, game masters, and creative storytellers who need to organize complex fictional universes.

## ⚠️ IMPORTANT NOTICE

**This project is 90% complete and nearing completion. It will be sold as a commercial product once finished.**

**STRICT LICENSE - NO DISTRIBUTION ALLOWED**: This source code is provided for review and contribution purposes only. You may NOT distribute, sell, sublicense, or use this code for any commercial purposes without explicit written permission from the copyright holder.

**Why Open Source?** I don't have a phone to test the mobile applications, so I'm welcoming contributions to help complete the final 10% of the project. Contributors will be acknowledged, but all intellectual property rights remain with the original author.

## 🌟 Project Overview

For World Builders is a comprehensive suite of applications that help creators build, organize, and manage detailed fictional worlds. The project emphasizes privacy, user control, and offline functionality while providing powerful tools for creative work.

### Core Philosophy
- **Privacy First**: Your creative work stays on your device
- **User Control**: Bring your own API keys for AI features
- **Offline Capable**: Full functionality without internet connection
- **Cross-Platform**: Native applications for different platforms

## 📁 Project Structure

```
for-world-builders/
├── forworldbuilders-apple-client/    # iOS/macOS native client
│   ├── forworldbuilders-apple-client/
│   │   ├── ContentView.swift         # Main UI implementation
│   │   ├── forworldbuilders_apple_clientApp.swift  # App entry point & models
│   │   └── Assets.xcassets/          # App icons and assets
│   ├── forworldbuilders-apple-clientTests/
│   │   ├── forworldbuilders_apple_clientTests.swift
│   │   ├── ExportTests.swift
│   │   ├── EdgeCaseTests.swift
│   │   └── APIKeyTests.swift
│   └── forworldbuilders-apple-clientUITests/
├── docs/                             # Project documentation (planned)
├── web-client/                       # Web application (planned)
├── desktop-client/                   # Electron/Tauri desktop app (planned)
└── README.md                         # This file
```

## 🚀 Features

### Apple Client (iOS/macOS)
- **World Management**: Create and organize multiple fictional worlds
- **Element System**: Track characters, locations, events, cultures, languages, timelines, plots, organizations, items, and concepts
- **Relationship Mapping**: Define connections between world elements with typed relationships
- **Activity Tracking**: Monitor recent changes and modifications
- **Element Mentions**: Automatic detection and linking of element references
- **Premium Element Templates**: Pre-built templates for common world-building elements

### Export System
- **JSON Export**: Machine-readable format for data portability
- **Plain Text Export**: Human-readable format
- **Markdown Export**: Structured format for documentation
- **PDF Export**: Professional presentation format
- **CSV Export**: Spreadsheet-compatible format
- **XML Export**: Structured data format

### Theme System
- **Built-in Themes**: 9 carefully crafted light and dark themes
- **Custom Theme Creator**: Build your own color schemes with live preview
- **Theme Persistence**: Your preferences are saved across sessions

### AI Integration (Bring Your Own Keys)
- **Multi-Provider Support**: OpenAI, Anthropic, Google (Gemini), and Grok (X.AI)
- **Secure Key Storage**: API keys stored in iOS Keychain with device-only access
- **Model Selection**: Choose from available models for each provider
- **Privacy Focused**: No telemetry or usage tracking
- **Offline First**: AI features are optional enhancements

### Subscription System
- **Freemium Model**: Core features available for free
- **Premium Features**:
  - Unlimited worlds (Free: 3 worlds)
  - Advanced export formats (PDF, XML, CSV)
  - Custom themes
  - AI-powered suggestions
  - Collaborative editing (planned)
  - Cloud sync & backup (planned)
  - Visual relationship graph (planned)
  - Advanced search & filters (planned)
  - Priority support
  - Premium element templates

## 🛠 Technology Stack

### Apple Client
- **Language**: Swift 5
- **Framework**: SwiftUI
- **Minimum Version**: iOS 17.5, macOS 14.0
- **Architecture**: MVVM with ObservableObject
- **Storage**: UserDefaults + iOS Keychain
- **Testing**: XCTest with 80%+ code coverage

### Security & Privacy
- **Data Storage**: Local device only (UserDefaults, Keychain)
- **API Keys**: Secure Keychain storage with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **No Telemetry**: Zero data collection or analytics
- **No Backend**: Fully client-side application
- **User Control**: All data remains under user control

## 🏗 Setup Instructions

### Apple Client (iOS/macOS)

#### Prerequisites
- Xcode 15.0 or later
- iOS 17.5+ or macOS 14.0+
- Apple Developer account (for device testing)

#### Building from Source
1. Clone the repository:
   ```bash
   git clone https://gitlab.com/owner51/for-world-builders.git
   cd for-world-builders/forworldbuilders-apple-client
   ```

2. Open the project in Xcode:
   ```bash
   open forworldbuilders-apple-client.xcodeproj
   ```

3. Select your target device/simulator

4. Build and run (⌘+R)

#### Running Tests
```bash
# Run all tests
xcodebuild -scheme forworldbuilders-apple-client -destination 'platform=iOS Simulator,name=iPhone 15' test

# Run specific test suite
xcodebuild -scheme forworldbuilders-apple-client -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:forworldbuilders-apple-clientTests/APIKeyTests
```

## 🔐 API Key Configuration

To enable AI features, you'll need API keys from supported providers:

1. **OpenAI**: Get your key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. **Anthropic**: Get your key at [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
3. **Google (Gemini)**: Get your key at [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
4. **Grok (X.AI)**: Get your key at [console.x.ai](https://console.x.ai/)

### Configuration Steps
1. Open the app and navigate to Settings
2. Tap "AI Providers"
3. Select a provider and tap the "+" button
4. Enter your API key and select a model
5. Save the configuration

All API keys are stored securely in the iOS Keychain and never leave your device.

## 📊 Test Coverage

The Apple client maintains 80%+ test coverage across:
- **Core Models**: World, Element, Relationship data structures
- **Data Store**: Persistence and retrieval operations
- **Export System**: All export formats and edge cases
- **Theme System**: Theme management and custom theme creation
- **API Key Management**: Validation, storage, and security
- **Subscription System**: Feature access control
- **Edge Cases**: Error handling and data validation

## 🤝 Contributing

We welcome contributions to help complete the final 10% of For World Builders! By contributing, you agree that all contributions become the property of the project owner.

**Important**: Contributors will be acknowledged but do not gain any ownership rights or commercial interests in the project.

### Development Guidelines
- Follow Swift/SwiftUI best practices
- Maintain test coverage above 80%
- Use descriptive commit messages
- Document new features thoroughly
- Respect privacy-first principles

### Coding Standards
- Use SwiftUI for all UI components
- Follow MVVM architecture patterns
- Implement comprehensive error handling
- Write unit tests for new functionality
- Use meaningful variable and function names

### Submission Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Merge Request

### Areas for Contribution
- **UI/UX Improvements**: Enhanced user interface and experience
- **Export Formats**: Additional export options
- **AI Features**: New AI-powered functionality
- **Performance**: Optimization and efficiency improvements
- **Documentation**: Tutorials, guides, and examples
- **Testing**: Expanded test coverage
- **Accessibility**: VoiceOver and accessibility improvements

## 🗺 Roadmap

### Phase 1: Foundation (Current)
- ✅ Core world-building features
- ✅ Basic export system
- ✅ Theme system
- ✅ API key management
- ✅ Subscription model

### Phase 2: Enhancement (Next)
- 🔄 AI-powered content generation
- 🔄 Visual relationship mapping
- 🔄 Advanced search and filtering
- 🔄 Collaborative features
- 🔄 Cloud sync (optional)

### Phase 3: Expansion (Future)
- 📋 Web application
- 📋 Desktop applications
- 📋 Mobile apps for other platforms
- 📋 Plugin system
- 📋 Community features

## 📄 License

**PROPRIETARY LICENSE - ALL RIGHTS RESERVED**

This project is NOT open source. The source code is provided for review and contribution purposes only under the following strict terms:

1. **NO DISTRIBUTION**: You may not distribute, share, or republish this code in any form
2. **NO COMMERCIAL USE**: You may not use this code for any commercial purposes
3. **NO DERIVATIVE WORKS**: You may not create derivative works based on this code
4. **CONTRIBUTIONS ONLY**: You may only use this code to make contributions back to the original project
5. **ALL RIGHTS RESERVED**: All intellectual property rights remain with the copyright holder

By accessing this code, you agree to these terms. Violation of these terms may result in legal action.

See the [LICENSE](LICENSE) file for full legal details.

## 📞 Support

- **Issues**: [GitLab Issues](https://gitlab.com/owner51/for-world-builders/-/issues)
- **Discussions**: [GitLab Discussions](https://gitlab.com/owner51/for-world-builders/-/issues)
- **Email**: support@caiatech.com

## 🙏 Acknowledgments

- The Swift and SwiftUI communities for excellent documentation and examples
- Beta testers and early adopters for valuable feedback
- Open source projects that inspired the architecture and design decisions

---

**For World Builders** - Empowering creators to build amazing fictional worlds while maintaining complete control over their creative work.
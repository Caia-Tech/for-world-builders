# For World Builders

A revolutionary privacy-first worldbuilding application with intelligent AI assistance, built natively for Apple platforms.

## Project Overview

**For World Builders** is a groundbreaking worldbuilding application that revolutionizes how writers create and manage fictional worlds. By combining native app performance with intelligent AI assistance (both local and cloud options), we're creating the first worldbuilding tool where AI truly understands and can interact with your world data while giving users complete control over their privacy.

### Core Value Proposition

- **Revolutionary AI Choice**: Local AI (100% private) or cloud AI (your keys, your control)
- **True Offline**: Full functionality anywhere, anytime, including AI assistance
- **Freemium Model**: Free version for 3 worlds, Pro for unlimited everything ($19.99)
- **Native Performance**: Built specifically for each platform with native tools
- **Honest Privacy**: Clear about trade-offs, user controls what data is shared

## Project Structure

This repository contains the For World Builders client applications. The project is organized to support multiple platform-specific implementations:

```
forworldbuilders-apple-client/
├── forworldbuilders-apple-client/    # iOS/macOS source code
│   ├── ContentView.swift             # Main content view
│   ├── MinimalApp.swift              # App entry point
│   ├── CoreData/                     # Core Data models and persistence
│   ├── Views/                        # SwiftUI views
│   ├── Theme/                        # App theming and styling
│   └── Assets.xcassets/              # Image and color assets
├── forworldbuilders-apple-clientTests/   # Unit tests
├── forworldbuilders-apple-clientUITests/ # UI tests
└── forworldbuilders-apple-client.xcodeproj/ # Xcode project

Additional clients (planned):
├── android-client/                   # Android app (Kotlin/Jetpack Compose)
├── windows-client/                   # Windows desktop app
└── linux-client/                     # Linux desktop app
```

## Apple Client Features

### Core Worldbuilding
- Create and manage multiple fictional worlds
- Support for various element types:
  - Characters
  - Locations
  - Events
  - Cultures
  - Languages
  - Timelines
  - Plots
  - Organizations
  - Items
  - Concepts
  - Custom elements
- Relationship management between elements
- Tag-based organization
- Rich text editing with markdown support

### Data Management
- **Core Data Integration**: Robust local storage with automatic conflict resolution
- **CloudKit Sync**: Seamless synchronization across all Apple devices
- **Export Options**: JSON export for backup and sharing
- **Version Control**: Track changes and maintain history

### User Interface
- **SwiftUI**: Modern, responsive interface following Apple design guidelines
- **Dark Mode Support**: Full dark mode implementation
- **Search & Filter**: Fast, full-text search across all world elements
- **Intuitive Navigation**: Tab-based interface with contextual navigation

### Privacy & Security
- **Local-First Storage**: All data stored on device by default
- **Optional Cloud Sync**: User controls when and what syncs
- **Encrypted Storage**: Sensitive data encrypted at rest
- **No Analytics**: Zero telemetry or tracking without explicit opt-in

## Technology Stack

### iOS/macOS Development
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data with CloudKit
- **Minimum iOS Version**: iOS 17.0
- **Minimum macOS Version**: macOS 14.0
- **Architecture**: MVVM with Combine

### Build Tools
- **Xcode**: 15.0 or later
- **Swift Package Manager**: For dependency management
- **Git**: Version control

## Setup Instructions

### Prerequisites
1. macOS 14.0 or later
2. Xcode 15.0 or later
3. Apple Developer Account (for CloudKit and device testing)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://gitlab.com/owner51/for-world-builders.git
   cd for-world-builders/forworldbuilders-apple-client
   ```

2. **Open in Xcode**
   ```bash
   open forworldbuilders-apple-client.xcodeproj
   ```

3. **Configure Signing**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team
   - Update bundle identifier if needed

4. **Enable CloudKit (Optional)**
   - In "Signing & Capabilities", add CloudKit capability
   - Configure CloudKit container
   - Set up record types in CloudKit Dashboard

5. **Build and Run**
   - Select target device (iPhone, iPad, or Mac)
   - Press Cmd+R to build and run

### Development Configuration

1. **Environment Setup**
   - Copy `Config.template.swift` to `Config.swift` (if applicable)
   - Configure API endpoints and keys for development

2. **Core Data Schema**
   - Schema migrations handled automatically
   - See `ForWorldBuilders.xcdatamodeld` for entity definitions

## Privacy and Security Features

### Data Privacy Principles
1. **Local-First Architecture**: All worldbuilding data stored locally on device
2. **User-Controlled Sync**: CloudKit sync is optional and user-initiated
3. **No Third-Party Analytics**: No tracking or telemetry without explicit consent
4. **Transparent Data Handling**: Clear privacy policy and data usage disclosure

### Security Implementation
- **Encryption at Rest**: Core Data encryption for sensitive content
- **Secure API Key Storage**: Keychain Services for cloud AI API keys
- **Network Security**: Certificate pinning for API communications
- **Access Control**: Biometric authentication support

### AI Privacy Modes
1. **Maximum Privacy Mode**: Local AI models only, no external data transmission
2. **Controlled Sharing Mode**: User selects specific data to share with cloud AI
3. **Full AI Access Mode**: Cloud AI with user's own API keys

## Contribution Guidelines

### Getting Started
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Merge Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code consistency
- Write self-documenting code with clear naming
- Add comments for complex logic

### Testing
- Write unit tests for new features
- Ensure UI tests pass for critical user flows
- Test on multiple device sizes and orientations
- Verify CloudKit sync functionality

### Pull Request Process
1. Update documentation for new features
2. Add tests for new functionality
3. Ensure all tests pass
4. Update CHANGELOG.md
5. Request review from maintainers

### Reporting Issues
- Use GitLab issue templates
- Include device information and iOS version
- Provide steps to reproduce
- Attach relevant logs or screenshots

## Development Roadmap

### Phase 1: Foundation (Complete)
- ✅ Core Data models and persistence
- ✅ Basic CRUD operations for world elements
- ✅ SwiftUI interface foundation
- ✅ CloudKit integration setup

### Phase 2: Enhanced Features (In Progress)
- 🔄 Advanced search and filtering
- 🔄 Relationship visualization
- 🔄 Export functionality
- 🔄 Theme customization

### Phase 3: AI Integration (Planned)
- 📋 Local AI model integration
- 📋 Cloud AI provider support
- 📋 Natural language world queries
- 📋 AI-assisted content generation

### Phase 4: Cross-Platform (Future)
- 📋 Mac Catalyst optimization
- 📋 iPadOS-specific features
- 📋 Apple Watch companion app
- 📋 Siri Shortcuts integration

## Support

### Documentation
- [User Guide](https://forworldbuilders.com/docs)
- [API Reference](https://forworldbuilders.com/api)
- [Video Tutorials](https://forworldbuilders.com/tutorials)

### Community
- [Discord Server](https://discord.gg/forworldbuilders)
- [Community Forum](https://forum.forworldbuilders.com)
- [Feature Requests](https://gitlab.com/owner51/for-world-builders/issues)

### Contact
- Email: support@forworldbuilders.com
- Twitter: @ForWorldBuilder
- Website: https://forworldbuilders.com

## License

Copyright © 2025 Caia Tech. All rights reserved.

This is proprietary software. Unauthorized copying, modification, distribution, or use of this software, via any medium, is strictly prohibited.

---

Built with ❤️ for writers, by writers.
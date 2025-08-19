# JetVPN

A high-performance Flutter VPN application built with clean architecture principles and optimized for exceptional user experience.

## 🚀 Features

### Core Functionality
- **Secure V2Ray VPN Connection** - Connect to VPN servers using V2Ray protocol
- **Real-time Speed Monitoring** - Live upload/download speed tracking with smart formatting
- **Server Management** - Browse, filter, and select from available VPN servers
- **IP Address Monitoring** - Intelligent IP tracking with geolocation information
- **Connection Status** - Real-time connection state updates and monitoring

### Performance Optimizations
- **Smart Caching** - Reduced API calls through intelligent caching strategies
- **Adaptive Polling** - Dynamic IP checking frequency based on connection state
- **Memory Efficient** - Optimized widget rebuilds and memory usage
- **Background Optimization** - Reduced resource usage when app is inactive

### User Experience
- **Material Design 3** - Modern UI with dynamic color theming
- **Accessibility** - Full screen reader support and semantic labels
- **Responsive Design** - Optimized for different screen sizes
- **Error Handling** - Graceful error handling with user-friendly messages

## 🏗️ Architecture

JetVPN follows **Clean Architecture** principles with a modular BLoC pattern for optimal performance and maintainability.

### Architecture Layers

```
📁 lib/src/
├── 📁 core/           # Core configuration and utilities
│   ├── config/        # App configuration, DI, theming
│   ├── routes/        # Navigation and routing
│   └── utils/         # Helper utilities
├── 📁 data/           # Data layer implementation
│   ├── datasources/   # External data sources (API, local)
│   ├── models/        # Data transfer objects
│   ├── repositories/  # Repository implementations
│   └── services/      # External services (IP, VPN config)
├── 📁 domain/         # Business logic layer
│   ├── entities/      # Core business entities
│   ├── repositories/  # Repository interfaces
│   └── usecases/      # Business use cases
├── 📁 presentations/  # Presentation layer
│   ├── bloc/          # State management (BLoC)
│   ├── pages/         # UI screens
│   └── widgets/       # Reusable UI components
└── 📁 shared/         # Shared models and utilities
```

### State Management Architecture

JetVPN uses a **specialized BLoC pattern** for optimal performance:

- **VpnBloc** - Main coordinator managing inter-bloc communication
- **VpnConnectionBloc** - Handles VPN connection operations
- **VpnServersBloc** - Manages server loading and pagination
- **IpBloc** - Intelligent IP monitoring with adaptive polling

This separation ensures:
- ✅ **Single Responsibility** - Each BLoC has a focused purpose
- ✅ **Performance** - Heavy operations are isolated
- ✅ **Testability** - Easy to unit test individual components
- ✅ **Maintainability** - Clear separation of concerns

## 🛠️ Technologies Used

### Core Dependencies
- **Flutter SDK** - Cross-platform mobile framework
- **flutter_v2ray** - V2Ray VPN protocol implementation
- **bloc/flutter_bloc** - State management solution
- **get_it** - Dependency injection
- **dartz** - Functional programming utilities
- **equatable** - Value equality comparisons

### UI/UX Dependencies
- **flutter_screenutil** - Responsive design utilities
- **dynamic_color** - Material Design 3 theming
- **go_router** - Advanced navigation

### Development Tools
- **logger** - Enhanced logging capabilities
- **http** - Network requests

## 📱 Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Android SDK for Android builds
- Xcode for iOS builds (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jetvpn
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # Development mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Configuration

The app uses environment-based configuration. Update the following files:

- `lib/src/core/config/app_config.dart` - API endpoints and app settings
- `lib/src/core/config/locator.dart` - Dependency injection setup

## 🏃‍♂️ Running the App

### Development Mode
```bash
flutter run --debug
```

### Production Build
```bash
# Android
flutter build apk --release

# iOS  
flutter build ios --release
```

### Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## 🎯 Performance Features

### Intelligent IP Monitoring
- **Adaptive Polling**: Adjusts frequency based on VPN connection state
  - Normal: Every 2 minutes when stable
  - VPN Transition: Every 10 seconds during connection changes
  - Inactive: Every 10 minutes when app is backgrounded
- **Smart Caching**: Avoids redundant API calls
- **Fallback Strategy**: Multiple IP service endpoints with automatic failover

### Optimized Server Management
- **Pagination**: Load servers efficiently with infinite scrolling
- **Caching**: 15-minute server data cache with automatic refresh
- **Filtering**: Client-side filtering to reduce API calls
- **Background Updates**: Automatic cache refresh without blocking UI

### Connection Performance
- **Specialized BLoCs**: Separate connection logic from server management
- **Stream Management**: Efficient VPN status monitoring
- **Error Recovery**: Graceful handling of connection failures
- **Resource Cleanup**: Proper disposal of resources and timers

## 🔧 Development Guidelines

### Code Style
- Follow Dart/Flutter best practices
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Maintain consistent code formatting

### State Management
- Use BLoC pattern for all state management
- Keep BLoCs focused on single responsibilities
- Use events for all state changes
- Implement proper error handling

### Performance Best Practices
- Minimize widget rebuilds using const constructors
- Cache expensive calculations
- Use proper ListView builders for large lists
- Implement proper resource disposal

## 📊 Monitoring & Debugging

The app includes comprehensive debugging capabilities:

```dart
// Access debug information
final debugInfo = vpnBloc.debugInfo;
print('VPN Debug Info: $debugInfo');
```

Debug information includes:
- Connection state details
- Server management statistics  
- IP monitoring cache status
- Performance metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the coding standards and add tests
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review the [V2Ray documentation](https://www.v2ray.com/)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- V2Ray community for the protocol implementation
- Contributors and maintainers of all dependencies

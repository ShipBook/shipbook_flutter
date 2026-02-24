# Shipbook Flutter SDK

[![pub package](https://img.shields.io/pub/v/shipbook_flutter.svg)](https://pub.dev/packages/shipbook_flutter)

Shipbook SDK for Flutter applications. Capture logs, errors, and exceptions from your Flutter apps and view them in the [Shipbook console](https://console.shipbook.io/).

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shipbook_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:shipbook_flutter/shipbook_flutter.dart';
import 'package:shipbook_flutter/log.dart';

void main() {
  runApp(const MyApp());

  // Initialize Shipbook (do this once at app startup, after runApp)
  Shipbook.start('YOUR_APP_ID', 'YOUR_APP_KEY');
}

// Get a logger for your class/component
final log = Shipbook.getLogger('MyWidget');

// Log messages at different severity levels
log.v('Detailed trace information');
log.d('Debug information');
log.i('General information');
log.w('Warning message');
log.e('Error message');

// Log with an error object
try {
  throw StateError('Something failed');
} catch (error) {
  log.e('Operation failed', error);
}
```

## Features

- **Remote Logging** - View all your app logs in the Shipbook console
- **Error Tracking** - Automatically captures uncaught exceptions and Flutter errors
- **Session Tracking** - Group logs by user session
- **Offline Support** - Logs are queued and sent when connectivity is restored
- **Dynamic Configuration** - Change log levels remotely without redeploying
- **User Identification** - Associate logs with specific users

## Configuration

### Enable Inner Logging (Debug Mode)

```dart
Shipbook.enableInnerLog(true);
```

### Register User

```dart
Shipbook.registerUser(
  'user-123',
  userName: 'johndoe',
  fullName: 'John Doe',
  email: 'john@example.com',
  phoneNumber: '+1234567890',
  additionalInfo: {'role': 'admin'},
);
```

### Logout

```dart
Shipbook.logout();
```

### Screen Tracking

```dart
Shipbook.screen('HomePage');
```

### Static Log Methods

You can also use static methods without creating a logger instance. The tag is automatically inferred from the caller's file name:

```dart
Log.error('Something went wrong');
Log.warning('This is a warning');
Log.info('General info');
Log.debug('Debug info');
Log.verbose('Trace info');
```

## Getting Your App ID and Key

1. Sign up at [shipbook.io](https://www.shipbook.io/)
2. Create a new application in the console
3. Copy your App ID and App Key from the application settings

For full setup instructions, see the [Flutter documentation](https://docs.shipbook.io/flutter-log-integration).

## Links

- [Shipbook Website](https://www.shipbook.io/)
- [Shipbook Console](https://console.shipbook.io/)
- [Documentation](https://docs.shipbook.io/)
- [GitHub Repository](https://github.com/ShipBook/shipbook_flutter)

## Author

Elisha Sterngold ([ShipBook Ltd.](https://www.shipbook.io))

## License

ShipBook SDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

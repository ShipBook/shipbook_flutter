import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipbook_flutter/log_manager.dart';
import 'package:shipbook_flutter/networking/session_manager.dart';
import 'package:shipbook_flutter/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const customConfig = '''
    {
      "appenders": [ { "type": "ConsoleAppender", "name": "cachedConsole" } ],
      "loggers": [ { "name": "", "severity": "Verbose", "appenderRef": "cachedConsole" } ]
    }
  ''';

  const packageInfoChannel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      packageInfoChannel,
      (call) async => call.method == 'getAll'
          ? <String, dynamic>{'appName': 'test', 'packageName': 'com.test', 'version': '1.0.0', 'buildNumber': '1', 'buildSignature': '', 'installerStore': ''}
          : null,
    );
    LogManager().clear();
    SessionManager().loginObj = null;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(packageInfoChannel, null);
  });

  Future<void> seedConfig(String? value) async {
    SharedPreferences.setMockInitialValues(value == null ? {} : {'config': value});
    await Storage().initialized;
    if (value == null) {
      Storage().remove('config');
    } else {
      Storage().setString('config', value);
    }
  }

  test('corrupt cached config is discarded and login still happens', () async {
    await seedConfig('\u{FFFD}\u{FFFD}not json');

    await SessionManager().login('appId', 'appKey');

    expect(SessionManager().loginObj, isNotNull, reason: 'login must be set up even when the cached config is unreadable');
    expect(Storage().getString('config'), isNull, reason: 'corrupt cache must be deleted');
    expect(LogManager().appenders.keys, contains('cloud'), reason: 'default config must be loaded as the fallback');
  });

  test('valid cached config is used', () async {
    await seedConfig(customConfig);

    await SessionManager().login('appId', 'appKey');

    expect(SessionManager().loginObj, isNotNull);
    expect(Storage().getString('config'), customConfig);
    expect(LogManager().appenders.keys, contains('cachedConsole'));
    expect(LogManager().appenders.keys, isNot(contains('cloud')));
  });

  test('missing cached config falls back to the default config', () async {
    await seedConfig(null);

    await SessionManager().login('appId', 'appKey');

    expect(SessionManager().loginObj, isNotNull);
    expect(LogManager().appenders.keys, contains('cloud'));
  });
}

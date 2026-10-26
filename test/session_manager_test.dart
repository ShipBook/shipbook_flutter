import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipbook_flutter/log_manager.dart';
import 'package:shipbook_flutter/networking/session_manager.dart';
import 'package:shipbook_flutter/shipbook_flutter.dart';
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
    SessionManager().sessionLink = null;
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

  Future<void> loginWithResponse(Map<String, dynamic> body) async {
    await seedConfig(null);
    await http.runWithClient(
      () => SessionManager().login('appId', 'appKey'),
      () => MockClient((request) async => http.Response(jsonEncode(body), 200)),
    );
  }

  final configJson = jsonDecode(customConfig);

  test('session headers carry the session link from login', () async {
    await loginWithResponse({
      'token': 'token',
      'sessionUrl': 'https://console.shipbook.io/session',
      'sessionLink': '1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4',
      'config': configJson,
    });

    expect(Shipbook.getSessionHeaders(), {'x-shipbook-session': '1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4'});
  });

  test('session headers are empty before login completes', () {
    expect(Shipbook.getSessionHeaders(), isEmpty);
  });

  test('a new login without a session link clears the previous one', () async {
    SessionManager().sessionLink = '1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4';

    await loginWithResponse({'token': 'token', 'sessionUrl': 'https://console.shipbook.io/session', 'config': configJson});

    expect(Shipbook.getSessionHeaders(), isEmpty, reason: 'a silenced login carries no link, and the old session is gone');
  });
}

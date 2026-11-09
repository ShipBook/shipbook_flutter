import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipbook_flutter/log_manager.dart';
import 'package:shipbook_flutter/models/appenders/sbcloud_appender.dart';
import 'package:shipbook_flutter/models/login.dart';
import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/severity.dart';
import 'package:shipbook_flutter/networking/connection_client.dart';
import 'package:shipbook_flutter/networking/session_manager.dart';
import 'package:shipbook_flutter/shipbook_flutter.dart';
import 'package:shipbook_flutter/storage.dart';

import 'helpers/test_appender.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const customConfig = '''
    {
      "appenders": [ { "type": "ConsoleAppender", "name": "cachedConsole" } ],
      "loggers": [ { "name": "", "severity": "Verbose", "appenderRef": "cachedConsole" } ]
    }
  ''';

  const packageInfoChannel = MethodChannel('dev.fluttercommunity.plus/package_info');
  const sessionUrl = 'https://console.shipbook.io/session';
  final cloudConfig = jsonDecode(defaultConfig);
  final requests = <http.Request>[];
  final printed = <String>[];
  final cloudAppenders = <SBCloudAppender>[];

  setUpAll(() {
    Shipbook.registerAppender('SBCloudAppender', (name, config) {
      final appender = SBCloudAppender(name, config);
      cloudAppenders.add(appender);
      return appender;
    });
  });

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
    SessionManager().appId = null;
    SessionManager().token = null;
    SessionManager().pausedUntil = null;
    SessionManager().isInLoginRequest = false;
    SharedPreferences.setMockInitialValues({});
    await Storage().initialized;
    for (final key in ['config', 'pause', SESSION_DATA]) {
      Storage().remove(key);
    }
    requests.clear();
    printed.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(packageInfoChannel, null);
    Shipbook.enableInnerLog(false);
    for (final appender in cloudAppenders) {
      appender.timer?.cancel();
    }
    cloudAppenders.clear();
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

  Future<T> withServer<T>(http.Response Function(http.Request request) respond, Future<T> Function() body) => http.runWithClient(
        body,
        () => MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => printed.add(line)),
      );

  http.Response loginOk([String url = sessionUrl]) => http.Response(jsonEncode({'token': 'token', 'sessionUrl': url, 'config': cloudConfig}), 200);

  http.Response numberedLogin(http.Request request) => loginOk('$sessionUrl/${requests.length}');

  void log(Severity severity) => LogManager().push(Message('message', severity, 'test', null, null, 'function', 'file.dart', 1));

  int savedLogs() => Storage().getList(SESSION_DATA)?.where((item) => item['type'] == 'log').length ?? 0;

  Iterable<String> paths() => requests.map((request) => request.url.path);

  test('login and upload identify the app and the SDK in headers', () async {
    await withServer((request) => loginOk(), () async {
      await Shipbook.start('appId', 'appKey');
      log(Severity.Error);
      Shipbook.flush();
      await pumpEventQueue();
    });

    expect(paths(), ['/v2/auth/loginSdk', '/v2/sessions/uploadSavedData']);
    final sdkVersion = jsonDecode(requests.first.body)['sdkVersion'];
    expect(sdkVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    for (final request in requests) {
      expect(request.headers['x-shipbook-app-id'], 'appId');
      expect(request.headers['x-shipbook-sdk'], 'flutter/$sdkVersion', reason: 'the header carries the version the login body reports');
    }
  });

  group('pause signal', () {
    const hour = 60 * 60;
    const cap = 30 * 24 * 60 * 60;

    Future<Duration?> pauseAfter(int status, String? retryAfter) async {
      SessionManager().appId = 'appId';
      await withServer(
        (request) => http.Response('', status, headers: {if (retryAfter != null) 'retry-after': retryAfter}),
        () => ConnectionClient.request('sessions/uploadSavedData', '[]', HttpMethod.post),
      );
      return SessionManager().pausedUntil?.difference(DateTime.now());
    }

    for (final (status, retryAfter, seconds) in [
      (401, '120', 120),
      (503, '120', 120),
      (429, '120', 120),
      (401, '5184000', cap),
      (401, '9223372036854775807', cap),
      (429, null, hour),
      (429, 'soon', hour),
      (429, '0', hour),
    ]) {
      test('$status with Retry-After $retryAfter pauses for $seconds seconds', () async {
        final pause = await pauseAfter(status, retryAfter);

        expect(pause!.inSeconds, closeTo(seconds, 2));
        expect(requests, hasLength(1));
      });
    }

    for (final (status, retryAfter) in [
      (401, null),
      (401, 'soon'),
      (401, 'Wed, 21 Oct 2026 07:28:00 GMT'),
      (401, '1.5'),
      (401, '0x10'),
      (401, '0'),
      (401, '-30'),
      (500, null),
      (200, '120'),
    ]) {
      test('$status with Retry-After $retryAfter does not pause', () async {
        expect(await pauseAfter(status, retryAfter), isNull);
        expect(Storage().getString('pause'), isNull);
      });
    }

    test('a pause clears the token and session link, is saved, and is reported in the inner log', () async {
      Shipbook.enableInnerLog(true);
      SessionManager().token = 'token';
      SessionManager().sessionLink = '1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4';

      await pauseAfter(401, '120');

      final until = SessionManager().pausedUntil!;
      expect(SessionManager().token, isNull);
      expect(Shipbook.getSessionHeaders(), isEmpty);
      expect(jsonDecode(Storage().getString('pause')!), {'appId': 'appId', 'sdkVersion': Login.currentSdkVersion, 'until': until.millisecondsSinceEpoch});
      expect(printed, contains(contains('Shipbook paused until ${until.toUtc().toIso8601String()}: the server answered 401 with Retry-After 120')));
    });

    test('a 429 without Retry-After is reported in the inner log', () async {
      Shipbook.enableInnerLog(true);

      await pauseAfter(429, null);

      final until = SessionManager().pausedUntil!.toUtc().toIso8601String();
      expect(printed, contains(contains('Shipbook paused until $until: the server answered 429 without Retry-After')));
    });

    test('an expired token answered with a pause is not refreshed', () async {
      SessionManager().loginObj = Login('appId', 'appKey');
      SessionManager().token = 'token';

      final response = await withServer(
        (request) => requests.length == 1 ? http.Response('', 401, reasonPhrase: 'TokenExpired', headers: {'retry-after': '120'}) : loginOk(),
        () => ConnectionClient.request('sessions/uploadSavedData', '[]', HttpMethod.post),
      );

      expect(response.statusCode, 401);
      expect(paths(), ['/v2/sessions/uploadSavedData']);
    });
  });

  group('while paused', () {
    test('nothing is sent and logs are dropped, local appenders keep working', () async {
      await withServer(
        (request) => request.url.path.endsWith('auth/loginSdk') ? loginOk() : http.Response('', 429, headers: {'retry-after': '120'}),
        () async {
          await Shipbook.start('appId', 'appKey');
          final local = TestAppender('local');
          LogManager().add(local, 'local');
          LogManager().loggers.add(Logger('', Severity.Verbose, Severity.Off, local));
          log(Severity.Error);
          Shipbook.flush();
          await pumpEventQueue();
          expect(SessionManager().paused, isTrue, reason: 'the upload was answered with a pause');
          requests.clear();

          log(Severity.Error);
          log(Severity.Debug);
          Shipbook.screen('home');
          Shipbook.registerUser('user');
          Shipbook.flush();
          Shipbook.logout();
          await pumpEventQueue();
          final response = await ConnectionClient.request('sessions/uploadSavedData', '[]', HttpMethod.post);

          expect(response.statusCode, 429);
          expect(await SessionManager().innerLogin(), isNull);
          expect(await SessionManager().refreshToken(), isFalse);
          expect(requests, isEmpty);
          expect(Storage().getListSize(SESSION_DATA), 0);
          expect(local.messages, hasLength(3));
        },
      );
    });

    test('an unknown app is asked once, however often start is called', () async {
      await withServer((request) => http.Response('', 401, headers: {'retry-after': '2592000'}), () async {
        for (var i = 0; i < 3; i++) {
          expect(await Shipbook.start('appId', 'appKey'), isNull);
        }
        expect(await Shipbook.start('appId', 'otherKey'), isNull);
      });

      expect(paths(), ['/v2/auth/loginSdk']);
      expect(SessionManager().pausedUntil!.difference(DateTime.now()).inDays, closeTo(30, 1));
    });

    test('when the pause ends, the next log logs in once and logs are kept again', () async {
      await withServer((request) => loginOk(), () async {
        await Shipbook.start('appId', 'appKey');
        SessionManager().pause(DateTime.now().add(const Duration(hours: 1)));
        log(Severity.Error);
        log(Severity.Debug);
        Shipbook.screen('home');
        await pumpEventQueue();
        expect(paths(), ['/v2/auth/loginSdk']);

        SessionManager().pausedUntil = DateTime.now().subtract(const Duration(seconds: 1));
        log(Severity.Error);
        log(Severity.Error);
        await pumpEventQueue();
      });

      expect(paths(), ['/v2/auth/loginSdk', '/v2/auth/loginSdk']);
      expect(SessionManager().token, 'token');
      expect(SessionManager().pausedUntil, isNull);
      expect(savedLogs(), 2, reason: 'only the logs after the pause, nothing from during it');
    });
  });

  group('saved pause', () {
    String saved({String appId = 'appId', String sdkVersion = Login.currentSdkVersion, Duration remaining = const Duration(hours: 1)}) =>
        jsonEncode({'appId': appId, 'sdkVersion': sdkVersion, 'until': DateTime.now().add(remaining).millisecondsSinceEpoch});

    test('a valid one keeps the SDK silent from the start', () async {
      Shipbook.enableInnerLog(true);
      final pause = saved();
      Storage().setString('pause', pause);

      final url = await withServer((request) => loginOk(), () async {
        final url = await Shipbook.start('appId', 'appKey');
        log(Severity.Error);
        Shipbook.flush();
        await pumpEventQueue();
        return url;
      });

      final until = DateTime.fromMillisecondsSinceEpoch(jsonDecode(pause)['until']).toUtc().toIso8601String();
      expect(url, isNull);
      expect(requests, isEmpty);
      expect(SessionManager().paused, isTrue);
      expect(Storage().getString('pause'), pause);
      expect(Storage().getListSize(SESSION_DATA), 0);
      expect(LogManager().appenders.keys, containsAll(['console', 'cloud']), reason: 'local logging is still configured');
      expect(printed, contains(contains('Shipbook is paused until $until (from an earlier run); nothing will be sent')));
      expect(printed, isNot(contains(contains('loginSdk'))), reason: 'login must not even be attempted');
    });

    for (final (name, pause) in [
      ('for another appId', saved(appId: 'otherApp')),
      ('for another SDK version', saved(sdkVersion: '0.0.1')),
      ('already in the past', saved(remaining: const Duration(seconds: -1))),
      ('that is not JSON', '\u{FFFD}\u{FFFD}not json'),
      ('with the wrong shape', '[1, 2]'),
      ('without a usable time', jsonEncode({'appId': 'appId', 'sdkVersion': Login.currentSdkVersion, 'until': 'tomorrow'})),
    ]) {
      test('one $name is removed and login happens', () async {
        Storage().setString('pause', pause);

        final url = await withServer((request) => loginOk(), () => Shipbook.start('appId', 'appKey'));

        expect(url, sessionUrl);
        expect(paths(), ['/v2/auth/loginSdk']);
        expect(SessionManager().paused, isFalse);
        expect(Storage().getString('pause'), isNull);
      });
    }
  });

  group('start', () {
    test('a second start with the same credentials does not log in again', () async {
      await withServer(numberedLogin, () async {
        final first = Shipbook.start('appId', 'appKey');
        final second = Shipbook.start('appId', 'appKey');

        expect(second, same(first));
        expect(await first, '$sessionUrl/1');
        expect(await Shipbook.start('appId', 'appKey'), '$sessionUrl/1');
      });

      expect(paths(), ['/v2/auth/loginSdk']);
    });

    test('other credentials log in again', () async {
      await withServer(numberedLogin, () async {
        expect(await Shipbook.start('appId', 'appKey'), '$sessionUrl/1');
        expect(await Shipbook.start('appId', 'otherKey'), '$sessionUrl/2');
        expect(await Shipbook.start('otherApp', 'otherKey'), '$sessionUrl/3');
      });

      expect(requests.map((request) => jsonDecode(request.body)['appKey']), ['appKey', 'otherKey', 'otherKey']);
      expect(requests.map((request) => request.headers['x-shipbook-app-id']), ['appId', 'appId', 'otherApp']);
    });

    test('logout creates a new session, except while paused', () async {
      await withServer(numberedLogin, () async {
        await Shipbook.start('appId', 'appKey');
        Shipbook.logout();
        await pumpEventQueue();
        expect(paths(), ['/v2/auth/loginSdk', '/v2/auth/loginSdk']);

        SessionManager().pause(DateTime.now().add(const Duration(hours: 1)));
        Shipbook.logout();
        await pumpEventQueue();
        expect(requests, hasLength(2));

        SessionManager().pausedUntil = DateTime.now().subtract(const Duration(seconds: 1));
        Shipbook.logout();
        log(Severity.Error);
        await pumpEventQueue();
        expect(requests, hasLength(3), reason: 'the logout login settles the ended pause, the log does not log in again');
      });
    });
  });
}

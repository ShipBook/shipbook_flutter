import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipbook_flutter/event_manager.dart';
import 'package:shipbook_flutter/log_manager.dart';
import 'package:shipbook_flutter/models/app_event.dart';
import 'package:shipbook_flutter/models/base_log.dart';
import 'package:shipbook_flutter/models/response/config_response.dart';
import 'package:shipbook_flutter/models/screen_event.dart';
import 'package:shipbook_flutter/networking/session_manager.dart';

import 'helpers/test_appender.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late TestAppender appender;

  // The framework fills in the states between two lifecycle messages, as it does on a device.
  Future<void> lifecycle(AppLifecycleState state) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle', const StringCodec().encodeMessage(state.toString()), (_) {});
  }

  List<String> states() => appender.events.map((event) => (event as AppEvent).state).toList();

  ConfigResponse config({required bool eventLoggingDisabled}) => ConfigResponse(
      additionalProperties: {},
      eventLoggingDisabled: eventLoggingDisabled,
      exceptionReportDisabled: true,
      appenders: [],
      loggers: []);

  setUp(() async {
    await lifecycle(AppLifecycleState.resumed);
    EventManager().enableAppState();
    appender = TestAppender('test');
    LogManager().add(appender, 'test');
  });

  tearDown(() {
    EventManager().removeAppState();
    LogManager().clear();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
  });

  test('going to the background and coming back sends one event per state', () async {
    await lifecycle(AppLifecycleState.paused);
    expect(states(), ['inactive', 'background']);

    await lifecycle(AppLifecycleState.resumed);
    expect(states(), ['inactive', 'background', 'inactive', 'active']);
    expect(appender.events.map((event) => (event as AppEvent).event).toSet(), {'change'});
  });

  test('a detached app that was already in the background sends nothing more', () async {
    await lifecycle(AppLifecycleState.paused);
    await lifecycle(AppLifecycleState.detached);

    expect(states(), ['inactive', 'background']);
  });

  test('enabling twice does not double the events', () async {
    EventManager().enableAppState();

    await lifecycle(AppLifecycleState.inactive);

    expect(states(), ['inactive']);
  });

  test('the event carries the orientation of the view', () async {
    binding.platformDispatcher.implicitView!.physicalSize = const Size(400, 800);
    await lifecycle(AppLifecycleState.inactive);
    binding.platformDispatcher.implicitView!.physicalSize = const Size(800, 400);
    await lifecycle(AppLifecycleState.resumed);

    expect(appender.events.map((event) => (event as AppEvent).orientation), ['portrait', 'landscape']);
  });

  test('the config turns the events off and on again', () async {
    SessionManager().readConfig(config(eventLoggingDisabled: true));
    LogManager().add(appender, 'test');
    await lifecycle(AppLifecycleState.paused);
    expect(states(), isEmpty);

    await lifecycle(AppLifecycleState.resumed);
    SessionManager().readConfig(config(eventLoggingDisabled: false));
    LogManager().add(appender, 'test');
    await lifecycle(AppLifecycleState.inactive);
    expect(states(), ['inactive']);
  });

  group('an event read back from storage', () {
    final stored = {'time': '2026-11-22T10:00:00.000Z', 'orderId': 7};

    test('a screen event keeps the time and order it happened in', () {
      final event = BaseLog.fromJson({...stored, 'type': 'screenEvent', 'name': 'Checkout'}) as ScreenEvent;

      expect(event.name, 'Checkout');
      expect(event.time.toUtc().toIso8601String(), '2026-11-22T10:00:00.000Z');
      expect(event.orderId, 7);
    });

    test('an app event comes back as it was saved', () {
      final saved = AppEvent('change', 'background', 'portrait');
      final event = BaseLog.fromJson(saved.toJson()) as AppEvent;

      expect(event.toJson(), saved.toJson());
      expect(event.toJson(), containsPair('type', 'appEvent'));
      expect([event.event, event.state, event.orientation], ['change', 'background', 'portrait']);
    });
  });
}

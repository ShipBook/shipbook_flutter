import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:shipbook_flutter/models/login.dart';
import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/severity.dart';
import 'package:shipbook_flutter/models/base_log.dart';
import 'package:shipbook_flutter/models/appenders/base_appender.dart';
import 'package:shipbook_flutter/models/common_types.dart';
import 'package:shipbook_flutter/log.dart';
import 'package:shipbook_flutter/log_manager.dart';

class TestAppender implements BaseAppender {
  @override
  final String name;
  final List<Message> messages = [];

  TestAppender(this.name, [Json? config]);

  @override
  void update(Json config) {}

  @override
  void push(BaseLog log) {
    if (log is Message) messages.add(log);
  }

  @override
  void flush() {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Login toJSON and fromJSON', () async {
    final login = Login('appId', 'appKey');
    await login.initializationDone;
    final jsonMap = login.toJson();
    final json = jsonEncode(jsonMap);
    final jsonMap2 = jsonDecode(json);
    final login2 = Login.fromJson(jsonMap2);
    expect(login.appId, login2.appId);
    expect(login.appKey, login2.appKey);
  });

  group('Caller info', () {
    late TestAppender testAppender;

    setUp(() {
      testAppender = TestAppender('test');
      LogManager().add(testAppender, 'test');
      LogManager().loggers.add(Logger('', Severity.Verbose, Severity.Off, testAppender));
    });

    tearDown(() {
      LogManager().clear();
      Message.stackOffset = 0;
    });

    test('log.d() reports correct caller', () {
      final log = Log('test');
      log.d('hello'); final expectedLine = _currentLine();

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.fileName, contains('shipbook_flutter_test.dart'));
      expect(msg.lineNumber, expectedLine);
    });

    test('log.message() reports correct caller', () {
      final log = Log('test');
      log.message('hello', Severity.Debug, null); final expectedLine = _currentLine();

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.fileName, contains('shipbook_flutter_test.dart'));
      expect(msg.lineNumber, expectedLine);
    });

    test('Log.error() static reports correct caller', () {
      Log.error('hello'); final expectedLine = _currentLine();

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.fileName, contains('shipbook_flutter_test.dart'));
      expect(msg.lineNumber, expectedLine);
    });

    test('Log.staticMessage() reports correct caller', () {
      Log.staticMessage('hello', Severity.Debug, null); final expectedLine = _currentLine();

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.fileName, contains('shipbook_flutter_test.dart'));
      expect(msg.lineNumber, expectedLine);
    });

    test('setStackOffset shifts the frame for wrappers', () {
      Message.stackOffset = 1;
      final log = Log('test');
      _wrapper(log); final expectedLine = _currentLine();

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.fileName, contains('shipbook_flutter_test.dart'));
      expect(msg.lineNumber, expectedLine);
    });
  });


}

/// Helper: wrapper function that adds one extra frame
void _wrapper(Log log) {
  log.d('from wrapper');
}

/// Helper: returns the current line number
int _currentLine() {
  final trace = StackTrace.current.toString();
  final lines = trace.split('\n');
  // Frame 0 is _currentLine itself, frame 1 is the caller
  final regex = RegExp(r':(\d+):');
  final match = regex.firstMatch(lines[1]);
  return int.parse(match!.group(1)!);
}

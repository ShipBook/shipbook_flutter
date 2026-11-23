import 'package:flutter_test/flutter_test.dart';

import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/severity.dart';
import 'package:shipbook_flutter/log.dart';
import 'package:shipbook_flutter/log_manager.dart';

import 'helpers/test_appender.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Caught exception (MessageException)', () {
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

    test('log.e() with error creates MessageException', () {
      final log = Log('test');
      final error = StateError('test error');
      log.e('something failed', error);

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.severity, Severity.Error);
      expect(msg.message, 'something failed');
      expect(msg.exception, isNotNull);
      expect(msg.exception!.name, 'StateError');
      expect(msg.exception!.reason, contains('test error'));
    });

    test('log.e() without error has no MessageException', () {
      final log = Log('test');
      log.e('just a message');

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.exception, isNull);
    });

    test('MessageException serializes to JSON correctly', () {
      final log = Log('test');
      final error = StateError('test error');
      log.e('something failed', error);

      final msg = testAppender.messages.first;
      final json = msg.toJson();

      expect(json['exception'], isA<Map>());
      expect(json['exception']['name'], 'StateError');
      expect(json['exception']['reason'], contains('test error'));
      expect(json['exception']['stackTrace'], isA<List>());
    });

    test('MessageException deserializes from JSON correctly', () {
      final log = Log('test');
      final error = StateError('test error');
      log.e('something failed', error);

      final msg = testAppender.messages.first;
      final json = msg.toJson();
      final restored = Message.fromJson(json);

      expect(restored.exception, isNotNull);
      expect(restored.exception!.name, 'StateError');
      expect(restored.exception!.reason, contains('test error'));
    });

    test('static Log.error() with error creates MessageException', () {
      final error = ArgumentError('bad arg');
      Log.error('static error', error);

      expect(testAppender.messages.length, 1);
      final msg = testAppender.messages.first;
      expect(msg.exception, isNotNull);
      expect(msg.exception!.name, 'ArgumentError');
      expect(msg.exception!.reason, contains('bad arg'));
    });

    test('log.e() takes a caught Exception and its stack trace', () {
      final log = Log('test');
      try {
        _Checkout().pay();
      } catch (error, stack) {
        log.e('payment failed', error, stack);
      }

      final exception = testAppender.messages.single.exception!;
      expect(exception.name, 'FormatException');
      expect(exception.reason, contains('bad card'));
      expect(exception.stackTrace.first.declaringClass, '_Checkout');
      expect(exception.stackTrace.first.methodName, 'pay');
    });

    test('log.e() without a stack trace uses a thrown Error\'s own stack', () {
      final log = Log('test');
      try {
        _Checkout().validate();
      } catch (error) {
        log.e('validation failed', error);
      }

      final exception = testAppender.messages.single.exception!;
      expect(exception.name, 'StateError');
      expect(exception.stackTrace.first.methodName, 'validate');
    });

    test('static Log.warning() takes a caught Exception and its stack trace', () {
      try {
        _Checkout().pay();
      } catch (error, stack) {
        Log.warning('payment retry', error, stack);
      }

      final msg = testAppender.messages.single;
      expect(msg.severity, Severity.Warning);
      expect(msg.exception!.name, 'FormatException');
      expect(msg.exception!.stackTrace.first.methodName, 'pay');
    });
  });
}

class _Checkout {
  void pay() => throw const FormatException('bad card');
  void validate() => throw StateError('empty cart');
}

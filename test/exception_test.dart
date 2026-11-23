import 'package:flutter_test/flutter_test.dart';

import 'package:shipbook_flutter/models/base_log.dart';
import 'package:shipbook_flutter/models/exception.dart';
import 'package:shipbook_flutter/models/severity.dart';
import 'package:shipbook_flutter/log_manager.dart';

import 'helpers/test_appender.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Uncaught exception (SBException)', () {
    late TestAppender testAppender;

    setUp(() {
      testAppender = TestAppender('test');
      LogManager().add(testAppender, 'test');
      LogManager().loggers.add(Logger('', Severity.Verbose, Severity.Off, testAppender));
    });

    tearDown(() {
      LogManager().clear();
    });

    test('SBException.fromError creates correct exception', () {
      final error = StateError('uncaught');
      final stack = StackTrace.current;
      final exception = SBException.fromError(error, stack);

      expect(exception.name, 'StateError');
      expect(exception.reason, contains('uncaught'));
      expect(exception.type, LogType.exception);
    });

    test('SBException.fromError with context includes it in reason', () {
      final error = StateError('uncaught');
      final stack = StackTrace.current;
      final exception = SBException.fromError(error, stack, context: 'while building Widget');

      expect(exception.reason, contains('while building Widget'));
      expect(exception.reason, contains('uncaught'));
    });

    test('SBException pushed to LogManager reaches all appenders', () {
      final error = StateError('uncaught');
      final stack = StackTrace.current;
      final exception = SBException.fromError(error, stack);
      LogManager().push(exception);

      expect(testAppender.exceptions.length, 1);
      expect(testAppender.exceptions.first.name, 'StateError');
    });

    test('SBException serializes to JSON correctly', () {
      const error = FormatException('bad format');
      final stack = StackTrace.current;
      final exception = SBException.fromError(error, stack);
      final json = exception.toJson();

      expect(json['name'], 'FormatException');
      expect(json['reason'], contains('bad format'));
      expect(json['type'], 'exception');
      // Should have either stackTrace or callStackSymbols
      expect(json.containsKey('stackTrace') || json.containsKey('callStackSymbols'), isTrue);
    });

    test('SBException.fromError keeps the frame that threw', () {
      late Object error;
      late StackTrace stack;
      try {
        _Checkout().pay();
      } catch (e, s) {
        error = e;
        stack = s;
      }
      final exception = SBException.fromError(error, stack);

      expect(exception.stackTrace!.first.declaringClass, '_Checkout');
      expect(exception.stackTrace!.first.methodName, 'pay');
    });

    test('SBException deserializes from JSON correctly', () {
      const error = FormatException('bad format');
      final stack = StackTrace.current;
      final exception = SBException.fromError(error, stack);
      final json = exception.toJson();
      final restored = SBException.fromJson(json);

      expect(restored.name, 'FormatException');
      expect(restored.reason, contains('bad format'));
      expect(restored.type, LogType.exception);
    });
  });
}

class _Checkout {
  void pay() => throw const FormatException('bad card');
}

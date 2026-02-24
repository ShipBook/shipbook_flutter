import 'package:flutter/foundation.dart';

import 'log_manager.dart';
import 'models/exception.dart';

class ExceptionManager {
  static final ExceptionManager _instance = ExceptionManager._internal();
  factory ExceptionManager() => _instance;
  ExceptionManager._internal();

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = SBException.fromError(
        details.exception,
        details.stack ?? StackTrace.current,
        context: details.context?.toString(),
      );
      LogManager().push(exception);
      if (previousFlutterError != null) {
        previousFlutterError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final previousPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      final exception = SBException.fromError(error, stack);
      LogManager().push(exception);
      if (previousPlatformError != null) {
        return previousPlatformError(error, stack);
      }
      return false;
    };
  }
}



import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/response/config_response.dart';

import '/models/appenders/base_appender.dart';
import 'models/severity.dart';
import 'models/base_log.dart';

abstract class Logger {
  String get key;
  Severity get severity;
  Severity get callStackSeverity;
  BaseAppender get appender;
}


class LogManager {
  final Map<String, BaseAppender> appenders = {};
  final List<Logger> loggers = [];

  void clear() {
    appenders.forEach((_, appender) => appender.destructor());  
    appenders.clear();
    loggers.clear();
  }

  void add(BaseAppender appender, String name) {
    final origAppender = appenders[name];
    if (origAppender != null) {
      origAppender.destructor();
    }
    appenders[name] = appender;
  }

  void remove(String name) {
    final appender = appenders[name];
    if (appender != null) {
      appender.destructor();
      appenders.remove(name);
    }
  }

  void push(BaseLog log) {
    if (log.type == LogType.message) {
      final message = log as Message;
      Set<String> appenderNames = {};
      for (final logger in loggers) {
        if (message.tag!.startsWith(logger.key) && message.severity.index <= logger.severity.index) {
          appenderNames.add(logger.appender.name);
        }
        for (final name in appenderNames) {
          appenders[name]!.push(log);
        }
      }
    } else {
      appenders.forEach((_, appender) => appender.push(log));
    }
  }

  void flush() {
    appenders.forEach((_, appender) => appender.flush());
  }

  Severity getSeverity(String tag) {
    var severity = Severity.Off;
    for (final logger in loggers) {
      if (tag.startsWith(logger.key) && logger.severity.index > severity.index) {
        severity = logger.severity;
      }
    }

    return severity;
  }

  Severity getCallStackSeverity(String tag) {
    var callStackSeverity = Severity.Off;
    for (final logger in loggers) {
      if (tag.startsWith(logger.key) && logger.callStackSeverity.index > callStackSeverity.index) {
        callStackSeverity = logger.callStackSeverity;
      }
    }

    return callStackSeverity;
  }

  void config(ConfigResponse config) {
    clear();
    for (final appender in config.appenders) {
      add(appender, appender.name);
    }
    for (final logger in config.loggers) {
      loggers.add(logger);
    }
  }
}
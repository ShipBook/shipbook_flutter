

import 'models/appenders/appender_factory.dart';
import 'models/message.dart';
import 'models/response/config_response.dart';
import 'models/appenders/base_appender.dart';
import 'inner_log.dart';
import 'models/severity.dart';
import 'models/base_log.dart';

class Logger {
  String key;
  Severity severity;
  Severity callStackSeverity;
  BaseAppender appender;

  Logger(this.key, this.severity, this.callStackSeverity, this.appender);
}


class LogManager {
  static final LogManager _instance = LogManager._internal();

  factory LogManager() {
    return _instance;
  }

  LogManager._internal();

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
      try {
        final config = appender.config ?? {};
        final base = AppenderFactory.create(appender.type, appender.name, config);
        appenders[appender.name] = base;
      } catch (e) {
        InnerLog().e('Error creating appender: $appender.name');
      }
    }

    for (final logger in config.loggers) {
      final appender = appenders[logger.appenderRef];
      if (appender != null) {
        final log = Logger(
          logger.name ?? '', 
          stringToSeverity(logger.severity), 
          stringToSeverity(logger.callStackSeverity ?? 'Off'), 
          appender
        );
        loggers.add(log);
      }
    }

    // TODO: Add event emitter
  }
}
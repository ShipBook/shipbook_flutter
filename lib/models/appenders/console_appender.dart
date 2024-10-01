import 'package:shipbook_flutter/inner_log.dart';

import '../base_log.dart';
import '../message.dart';

import '../response/config_response.dart';
import 'base_appender.dart';

class ConsoleAppender implements BaseAppender {
  @override
  final String name;
  final String? pattern;
  ConsoleAppender(this.name, JsonMap? config) : pattern = config?['pattern'] {
    innerLog.i('ConsoleAppender pattern: $pattern');
  }
  
  @override
  void update(JsonMap? config) {
    // Do nothing
  }

  @override
  void push(log) {
    if (log.type == LogType.message) {
      final message = log as Message;
      final text = '${message.fileName} ${message.lineNumber} ${message.message}';
      // ignore: avoid_print
      print('${message.severity} $text');
    }
    
  }

  @override
  void flush() {
    // Do nothing
  }

  @override
  void destructor() {
    // Do nothing
  }
}
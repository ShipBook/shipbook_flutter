import '../../inner_log.dart';

import '../base_log.dart';
import '../common_types.dart';
import '../message.dart';

import 'base_appender.dart';

class ConsoleAppender implements BaseAppender {
  @override
  final String name;
  final String? pattern;
  ConsoleAppender(this.name, Json? config) : pattern = config?['pattern'] {
    InnerLog().i('ConsoleAppender pattern: $pattern');
  }
  
  @override
  void update(Json? config) {
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
  void dispose() {
    // Do nothing
  }
}
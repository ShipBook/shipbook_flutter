import '../base_log.dart';
import '../message.dart';
import '../response/config_response.dart';

import 'base_appender.dart';

class ConsoleAppender implements BaseAppender {
  final String name;
  final String? pattern;
  ConsoleAppender(this.name, ConfigResponse? config) : pattern = config?.appenders.firstWhere((element) => element.name == name).config?['pattern'];


  @override
  void update(ConfigResponse? config) {
    // Do nothing
  }

  @override
  void push(log) {
    if (log.type == LogType.message) {
      final message = log as Message;
      final text = '$message.fileName $message.lineNumber $message.message';
      print('$message.severity $text');
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
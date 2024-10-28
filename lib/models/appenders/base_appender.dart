import '../base_log.dart';
import '../common_types.dart';
import 'console_appender.dart';
import 'sbcloud_appender.dart';

abstract class BaseAppender {
  String get name;
  void update(Json config);
  void push(BaseLog log);
  void flush();
  void dispose();

  factory BaseAppender.create(String type, String name, Json? config) {
    switch (type) {
      case 'ConsoleAppender':
        return ConsoleAppender(name, config);
      case 'SBCloudAppender':
        return SBCloudAppender(name, config);
      default:
        throw ArgumentError('Unknown appender type: $type');
    }
  }
}
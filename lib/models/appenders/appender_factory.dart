import '../common_types.dart';
import 'base_appender.dart';
import 'console_appender.dart';
import 'sbcloud_appender.dart';

class AppenderFactory {
  static BaseAppender create(String type, String name, Json config) {
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
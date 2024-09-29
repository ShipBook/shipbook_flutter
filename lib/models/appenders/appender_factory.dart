import 'base_appender.dart';
import 'console_appender.dart';
import 'sbcloud_appender.dart';
import '../response/config_response.dart';


class AppenderFactory {
  static BaseAppender create(String type, String name, ConfigResponse config) {
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
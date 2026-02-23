import '../base_log.dart';
import '../common_types.dart';
import 'console_appender.dart';
import 'sbcloud_appender.dart';

typedef AppenderCreator = BaseAppender Function(String name, Json? config);

abstract class BaseAppender {
  String get name;
  void update(Json config);
  void push(BaseLog log);
  void flush();
  void dispose();

  static final Map<String, AppenderCreator> _registry = {
    'ConsoleAppender': (name, config) => ConsoleAppender(name, config),
    'SBCloudAppender': (name, config) => SBCloudAppender(name, config),
  };

  static void register(String type, AppenderCreator creator) {
    _registry[type] = creator;
  }

  factory BaseAppender.create(String type, String name, Json? config) {
    final creator = _registry[type];
    if (creator == null) throw ArgumentError('Unknown appender type: $type');
    return creator(name, config);
  }
}

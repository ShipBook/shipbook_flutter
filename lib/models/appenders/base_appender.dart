import '../base_log.dart';
import '../response/config_response.dart';

abstract class BaseAppender {
  String get name;
  void update(ConfigResponse? config);
  void push(BaseLog log);
  void flush();
  void destructor();
}
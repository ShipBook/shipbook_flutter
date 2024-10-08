import '../base_log.dart';
import '../common_types.dart';

abstract class BaseAppender {
  String get name;
  void update(Json config);
  void push(BaseLog log);
  void flush();
  void destructor();
}
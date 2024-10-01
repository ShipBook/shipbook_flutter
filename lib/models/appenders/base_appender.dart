import 'package:shipbook_flutter/models/response/config_response.dart';

import '../base_log.dart';

abstract class BaseAppender {
  String get name;
  void update(JsonMap config);
  void push(BaseLog log);
  void flush();
  void destructor();
}
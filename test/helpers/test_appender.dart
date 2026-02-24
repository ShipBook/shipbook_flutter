import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/base_log.dart';
import 'package:shipbook_flutter/models/exception.dart';
import 'package:shipbook_flutter/models/appenders/base_appender.dart';
import 'package:shipbook_flutter/models/common_types.dart';

class TestAppender implements BaseAppender {
  @override
  final String name;
  final List<Message> messages = [];
  final List<SBException> exceptions = [];

  TestAppender(this.name, [Json? config]);

  @override
  void update(Json config) {}

  @override
  void push(BaseLog log) {
    if (log is Message) messages.add(log);
    if (log is SBException) exceptions.add(log);
  }

  @override
  void flush() {}

  @override
  void dispose() {}
}

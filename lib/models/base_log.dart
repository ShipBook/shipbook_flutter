import 'common_types.dart';

import 'message.dart';

enum LogType {
  message, 
  exception,
  appEvent,
  screenEvent
}

class BaseLog {
  static int count = 0;
  late DateTime time;
  late int orderId;
  late LogType type;

  BaseLog(this.type, [Json? json]) {
    if (json != null) {
      time = DateTime.parse(json['time']);
      orderId = json['orderId'];
    } else {
      time = DateTime.now();
      orderId = ++BaseLog.count;
    }
  }

  Json toJson() {
    return {
      'time': time.toIso8601String(),
      'orderId': orderId,
      'type': type.toString().split('.').last
    };
  }

  factory BaseLog.fromJson(Json json) {
    switch (json['logType']) {
      case 'message':
        return Message.fromJson(json);
      // Add cases for other subclasses here
      default:
        throw Exception('Unknown log type');
    }
  }
}
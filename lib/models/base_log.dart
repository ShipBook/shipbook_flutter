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

  BaseLog(this.type) {
    time = DateTime.now();
    orderId = ++BaseLog.count;
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'time': time.toIso8601String(),
      'orderId': orderId,
      'type': type.toString().split('.').last
    };
  }

  factory BaseLog.fromJsonMap(Map<String, dynamic> json) {
    return BaseLog(
      LogType.values.firstWhere((e) => e.toString().split('.').last == json['type']),
    )
    ..time = DateTime.parse(json['time'])
    ..orderId = json['orderId'];    
  }
}


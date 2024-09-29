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
}


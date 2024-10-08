// ignore_for_file: avoid_print
class InnerLog {
  static final InnerLog _instance = InnerLog._internal();
  bool enabled = false;

  factory InnerLog() {
    return _instance;
  }

  InnerLog._internal();

  void e(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print("Shipbook: $message ${optionalParams?.join(' ')}");
  }

  void w(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print("Shipbook: $message ${optionalParams?.join(' ')}");
  }

  void i(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print("Shipbook: $message ${optionalParams?.join(' ')}");
  }

  void d(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print("Shipbook: $message ${optionalParams?.join(' ')}");
  }
}
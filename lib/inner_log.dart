// ignore_for_file: avoid_print
class InnerLog {
  bool enabled = false;

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

final innerLog = InnerLog();


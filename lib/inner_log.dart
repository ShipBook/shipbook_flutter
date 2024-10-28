// ignore_for_file: avoid_print
class InnerLog {
  static final InnerLog _instance = InnerLog._internal();
  bool enabled = false;

  factory InnerLog() {
    return _instance;
  }

  InnerLog._internal();

  String _message(String? message, [List<Object>? optionalParams]) {
    String optionalParamsString = '';
    if (optionalParams != null && optionalParams.isNotEmpty) {
      optionalParamsString = optionalParams.join(' ');
    }
    return "Shipbook: $message $optionalParamsString";
  }
  void e(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print(_message(message, optionalParams));
  }

  void w(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print(_message(message, optionalParams));
  }

  void i(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print(_message(message, optionalParams));
  }

  void d(String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    print(_message(message, optionalParams));
  }
}
// ignore_for_file: avoid_print
import 'package:shipbook_flutter/models/severity.dart';

class InnerLog {
  static final InnerLog _instance = InnerLog._internal();
  bool enabled = false;

  factory InnerLog() {
    return _instance;
  }

  InnerLog._internal();

  void _message(Severity severity,  String? message, [List<Object>? optionalParams]) {
    if (!enabled) return;
    String optionalParamsString = '';
    if (optionalParams != null && optionalParams.isNotEmpty) {
      optionalParamsString = optionalParams.join(' ');
    }
    String severityString = severity.name.toUpperCase();
    print('Shipbook [$severityString]: $message $optionalParamsString');
  }
  void e(String? message, [List<Object>? optionalParams]) {
    _message(Severity.Error, message, optionalParams);
  }

  void w(String? message, [List<Object>? optionalParams]) {
    _message(Severity.Warning, message, optionalParams);
  }

  void i(String? message, [List<Object>? optionalParams]) {
    _message(Severity.Info, message, optionalParams);
  }

  void d(String? message, [List<Object>? optionalParams]) {
    _message(Severity.Debug, message, optionalParams);
  }
}
import 'package:shipbook_flutter/event_emitter.dart';

import './models/message.dart';
import './models/severity.dart';

import 'log_manager.dart';

class Log {
  final String tag;
  Severity _severity;
  Severity _callStackSeverity;

  Log(this.tag) : _severity = LogManager().getSeverity(tag),
                  _callStackSeverity = LogManager().getCallStackSeverity(tag) {
    EventEmitter().on(EventType.configChange, (dynamic config) {
      _severity = LogManager().getSeverity(tag);
      _callStackSeverity = LogManager().getCallStackSeverity(tag);
    });
  }

  static error(String message, [Object? error, StackTrace? stackTrace]){
    Log._staticMessage(message, Severity.Error, error, stackTrace);
  }

  static warning(String message, [Object? error, StackTrace? stackTrace]){
    Log._staticMessage(message, Severity.Warning, error, stackTrace);
  }

  static info(String message, [Object? error, StackTrace? stackTrace]){
    Log._staticMessage(message, Severity.Info, error, stackTrace);
  }

  static debug(String message, [Object? error, StackTrace? stackTrace]){
    Log._staticMessage(message, Severity.Debug, error, stackTrace);
  }

  static verbose(String message, [Object? error, StackTrace? stackTrace]){
    Log._staticMessage(message, Severity.Verbose, error, stackTrace);
  }

  static void _attachStackTrace(Message message) {
    final stackTraceString = StackTrace.current.toString();
    final stackTrace = StackTraceParser.parse(stackTraceString);
    if (stackTrace != null && stackTrace.isNotEmpty) {
      message.stackTrace = stackTrace;
    } else {
      message.callStackSymbols = stackTraceString.split('\n').where((l) => l.isNotEmpty).toList();
    }
  }

  // Both staticMessage and the convenience methods (error, warning, etc.) route
  // through _staticMessage so the call depth to Message is always the same (3 frames).
  static void staticMessage(String msg, Severity severity, Object? error, {StackTrace? stackTrace, String? func, String? file, int? line, String? className, String? tag}){
    Log._staticMessage(msg, severity, error, stackTrace, func: func, file: file, line: line, className: className, tag: tag);
  }

  static void _staticMessage(String msg, Severity severity, Object? error, StackTrace? stackTrace, {String? func, String? file, int? line, String? className, String? tag}){
    Message? message;
    if (tag == null)  {
      message = Message(msg, severity, null, null, error, stackTrace, func, file, line);
      if (severity.index > LogManager().getSeverity(message.tag!).index) return;
    } else {
      if (severity.index > LogManager().getSeverity(tag).index) return;
      message = Message(msg, severity, tag, null, error, stackTrace, func, file, line);
    }

    if (severity.index <= LogManager().getCallStackSeverity(message.tag!).index) _attachStackTrace(message);
    LogManager().push(message);
  }

  e(String message, [Object? error, StackTrace? stackTrace]){
    _message(message, Severity.Error, error, stackTrace);
  }
  w(String message, [Object? error, StackTrace? stackTrace]){
    _message(message, Severity.Warning, error, stackTrace);
  }
  i(String message, [Object? error, StackTrace? stackTrace]){
    _message(message, Severity.Info, error, stackTrace);
  }
  d(String message, [Object? error, StackTrace? stackTrace]){
    _message(message, Severity.Debug, error, stackTrace);
  }
  v(String message, [Object? error, StackTrace? stackTrace]){
    _message(message, Severity.Verbose, error, stackTrace);
  }

  // Both message and the convenience methods (e, w, i, d, v) route through
  // _message so the call depth to Message is always the same (3 frames).
  void message(String msg, Severity severity, Object? error, {StackTrace? stackTrace, String? func, String? file, int? line, String? className}){
    _message(msg, severity, error, stackTrace, func: func, file: file, line: line, className: className);
  }

  void _message(String msg, Severity severity, Object? error, StackTrace? stackTrace, {String? func, String? file, int? line, String? className}){
    if (severity.index > _severity.index ) return;
    final message = Message(msg, severity, tag, null, error, stackTrace, func, file, line);
    if (severity.index <= _callStackSeverity.index) _attachStackTrace(message);
    LogManager().push(message);
  }
}

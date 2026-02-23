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

  static error(String message, [Error? e]){
    Log._staticMessage(message, Severity.Error, e);
  }

  static warning(String message, [Error? e]){
    Log._staticMessage(message, Severity.Warning, e);
  }

  static info(String message, [Error? e]){
    Log._staticMessage(message, Severity.Info, e);
  }

  static debug(String message, [Error? e]){
    Log._staticMessage(message, Severity.Debug, e);
  }

  static verbose(String message, [Error? e]){
    Log._staticMessage(message, Severity.Verbose, e);
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
  static void staticMessage(String msg, Severity severity, Error? e, {String? func, String? file, int? line, String? className, String? tag}){
    Log._staticMessage(msg, severity, e, func: func, file: file, line: line, className: className, tag: tag);
  }

  static void _staticMessage(String msg, Severity severity, Error? e, {String? func, String? file, int? line, String? className, String? tag}){
    Message? message;
    if (tag == null)  {
      message = Message(msg, severity,null, null, e, func, file, line);
      if (severity.index > LogManager().getSeverity(message.tag!).index) return;
    } else {
      if (severity.index > LogManager().getSeverity(tag).index) return;
      message = Message(msg, severity, tag, null, e, func, file, line);
    }

    if (severity.index <= LogManager().getCallStackSeverity(message.tag!).index) _attachStackTrace(message);
    LogManager().push(message);
  }

  e(String message, [Error? e]){
    _message(message, Severity.Error, e);
  }
  w(String message, [Error? e]){
    _message(message, Severity.Warning, e);
  }
  i(String message, [Error? e]){
    _message(message, Severity.Info, e);
  }
  d(String message, [Error? e]){
    _message(message, Severity.Debug, e);
  }
  v(String message, [Error? e]){
    _message(message, Severity.Verbose, e);
  }

  // Both message and the convenience methods (e, w, i, d, v) route through
  // _message so the call depth to Message is always the same (3 frames).
  void message(String msg, Severity severity, Error? e, {String? func, String? file, int? line, String? className}){
    _message(msg, severity, e, func: func, file: file, line: line, className: className);
  }

  void _message(String msg, Severity severity, Error? e, {String? func, String? file, int? line, String? className}){
    if (severity.index > _severity.index ) return;
    final message = Message(msg, severity, tag, null, e, func, file, line);
    if (severity.index <= _callStackSeverity.index) _attachStackTrace(message);
    LogManager().push(message);
  }
}

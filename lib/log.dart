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
    Log.staticMessage(message, Severity.Error, e);
  }

  static warning(String message, [Error? e]){
    Log.staticMessage(message, Severity.Warning, e);
  }

  static info(String message, [Error? e]){
    Log.staticMessage(message, Severity.Info, e);
  }

  static debug(String message, [Error? e]){
    Log.staticMessage(message, Severity.Debug, e);
  }

  static verbose(String message, [Error? e]){
    Log.staticMessage(message, Severity.Verbose, e);
  }

  static void staticMessage(String msg, Severity severity, Error? e, {String? func, String? file, int? line, String? className, String? tag}){ 
    Message? message;
    if (tag == null)  {
      message = Message(msg, severity,null, null, e, func, file, line);
      if (message.tag == null) return;

      if (severity.index > LogManager().getSeverity(message.tag!).index) return;
      final stackTraceString = severity.index <= LogManager().getSeverity(message.tag!).index ? StackTrace.current.toString() : null;
      message.stackTrace = StackTraceParser.parse(stackTraceString);

    } else {
      if (severity.index > LogManager().getSeverity(tag).index) return;
      final stackTraceString = severity.index <= LogManager().getSeverity(tag).index ? StackTrace.current.toString() : null;
      final stackTrace = StackTraceParser.parse(stackTraceString);
      
      message = Message(msg, severity, tag, stackTrace, e, func, file, line);
    }

    LogManager().push(message);
  }

  e(String message, [Error? e]){
    this.message(message, Severity.Error, e);
  }
  w(String message, [Error? e]){
    this.message(message, Severity.Warning, e);
  }
  i(String message, [Error? e]){
    this.message(message, Severity.Info, e);
  }
  d(String message, [Error? e]){
    this.message(message, Severity.Debug, e);
  }
  v(String message, [Error? e]){
    this.message(message, Severity.Verbose, e);
  }

  void message(String msg, Severity severity, Error? e, {String? func, String? file, int? line, String? className}){ 
    if (severity.index > _severity.index ) return;
    final stackTraceString = severity.index <= _callStackSeverity.index ? StackTrace.current.toString() : null;
    final stackTrace = StackTraceParser.parse(stackTraceString);
    final message = Message(msg, severity, tag, stackTrace, e, func, file, line);
    LogManager().push(message);
  }
}
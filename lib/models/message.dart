import 'package:shipbook_flutter/models/severity.dart';

import 'base_log.dart';

class Message extends BaseLog {
  static Set<String> ignoreClasses = <String>{};
  String message;
  Severity severity;
  String? tag; // it is initialized after the promise.
  String? stackTrace;
  Error? error;
  String? function;
  String? fileName;
  int? lineNumber;
  
  Message(this.message, 
          this.severity,
          this.tag,
          this.stackTrace,
          this.error,
          this.function,
          this.fileName,
          this.lineNumber) : super(LogType.message) {
    if (fileName == null) {
      // TODO: implement this
    }
  }


  // @override
  // Map<String, dynamic> toJson() {
  //   final json = super.toJson();
  //   json['tag'] = tag;
  //   json['message'] = message;
  //   if (stackTrace != null) json['stackTrace'] = stackTrace;
  //   if (exception != null) json['exception'] = exception;
  //   if (exceptionType != null) json['exceptionType'] = exceptionType;
  //   return json;
  // }
}
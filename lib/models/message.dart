import 'package:shipbook_flutter/inner_log.dart';

import 'severity.dart';

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
      final stackTrace = StackTrace.current.toString();
      innerLog.d('StackTrace: $stackTrace');
      final line = stackTrace.split('\n')[3];
      innerLog.d('Line: $line');
      final regex = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+):(\d+)\)');
      final match = regex.firstMatch(line);

      if (match != null) {
        function = match.group(1);
        fileName = match.group(2);
        lineNumber = int.parse(match.group(3)!);
        innerLog.d('Function: $function FileName: $fileName LineNumber: $lineNumber');
      } 
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
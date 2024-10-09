import '../inner_log.dart';
import 'common_types.dart';

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
          this.lineNumber,
          [Json? json]) : super(LogType.message, json) {
    if (fileName == null) {
      final stackTrace = StackTrace.current.toString();
      final line = stackTrace.split('\n')[3];
      final regex = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+):(\d+)\)');
      final match = regex.firstMatch(line);

      if (match != null) {
        function = match.group(1);
        fileName = match.group(2);
        lineNumber = int.parse(match.group(3)!);
        InnerLog().d('Function: $function FileName: $fileName LineNumber: $lineNumber');
      } 
    }
  }

  @override
  factory Message.fromJson(Json json) {
    return Message(
      json['message'],
      json['severity'],
      json['tag'],
      json['stackTrace'],
      json['error'],
      json['function'],
      json['fileName'],
      json['lineNumber'],
      json
    );
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
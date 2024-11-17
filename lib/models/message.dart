import '../inner_log.dart';
import 'common_types.dart';

import 'severity.dart';

import 'base_log.dart';

class Message extends BaseLog {
  static Set<String> ignoreClasses = <String>{};
  String message;
  Severity severity;
  String? tag; // it is initialized after the promise.
  List<StackTraceElement>? stackTrace;
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

      final stackTraceElement = StackTrace.current.toString();
      final line = stackTraceElement.split('\n')[3];
      final regex = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+):(\d+)\)');
      final match = regex.firstMatch(line);

      if (match != null) {
        function = match.group(1);
        fileName = match.group(2);
        lineNumber = int.parse(match.group(3)!);
        InnerLog().d('Function: $function FileName: $fileName LineNumber: $lineNumber');
      }

      if (tag == null || tag!.isEmpty) {
        // get the substring from the first character to the first dot.
        tag = fileName?.substring(0, fileName!.indexOf('.')) ?? '<unknown>';
      }
    }
  }

  @override
  factory Message.fromJson(Json json) {
    final stackTrace = StackTraceParser.fromJsonList(
       (json['stackTrace'] as List?)?.cast<Map<String, dynamic>>()
    );
    return Message(
      json['message'],
      Severity.values.byName(json['severity']),
      json['tag'],
      stackTrace,
      json['error'],
      json['function'],
      json['fileName'],
      json['lineNumber'],
      json
    );
  }


  @override
  Json toJson() {
    final json = super.toJson();
    json['tag'] = tag;
    json['message'] = message;
    json['severity'] = severity.name;
    json['function'] = function;
    json['fileName'] = fileName;
    json['lineNumber'] = lineNumber;
    
    if (stackTrace != null) json['stackTrace'] = stackTrace;
    if (error != null) json['error'] = error;

    // if (exception != null) json['exception'] = exception;
    // if (exceptionType != null) json['exceptionType'] = exceptionType;
    return json;
  }
}

class StackTraceParser {
  static List<StackTraceElement>? parse(String? stackTrace) {
    if (stackTrace == null) return null;
    final lines = stackTrace.split('\n');
    final elements = <StackTraceElement>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      elements.add(StackTraceElement.fromString(line));
    }

    return elements;
  }

  static List<StackTraceElement>? fromJsonList(List<Json>? json) {
    if (json == null) return null;
    final elements = <StackTraceElement>[];
    for (final element in json as List) {
      elements.add(StackTraceElement.fromJson(element));
    }
    return elements;
  }
}

class StackTraceElement {
  String declaringClass;
  String methodName;
  String fileName;
  int lineNumber;
  // column?: number;
  // arguments?: string[];

  // static parseStackTrace(String? stackTrace) {
  //   if (stackTrace == null) return null;
  //   final lines = stackTrace.split('\n');
  //   final elements = <StackTraceElement>[];

  //   for (var i = 1; i < lines.length; i++) {
  //     final line = lines[i];
  //     if (line.isEmpty) continue;
  //     elements.add(StackTraceElement.fromString(line));
  //   }

  //   return elements;
  // }

  StackTraceElement(this.declaringClass, this.methodName, this.fileName, this.lineNumber);

  factory StackTraceElement.fromJson(Json json) {
    return StackTraceElement(
      json['declaringClass'],
      json['methodName'],
      json['fileName'],
      json['lineNumber'],
    );
  }

  factory StackTraceElement.fromString(String line) {
    final regex = RegExp(r'#\d+\s+(\w+)\.(\w+)\s+\((.+):(\d+):(\d+)\)');
    final match = regex.firstMatch(line);

    if (match != null) {
      return StackTraceElement(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
        int.parse(match.group(4)!),
      );
    }

    return StackTraceElement('<unknown>', '<unknown>', '<unknown>', 0);
  }

  Json toJson() {
    return {
      'declaringClass': declaringClass,
      'methodName': methodName,
      'fileName': fileName,
      'lineNumber': lineNumber,
    };
  }
}
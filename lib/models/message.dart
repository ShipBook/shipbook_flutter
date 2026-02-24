import '../inner_log.dart';
import 'common_types.dart';

import 'severity.dart';

import 'base_log.dart';

class MessageException {
  String? name;
  String? reason;
  List<StackTraceElement> stackTrace;

  MessageException(this.name, this.reason, this.stackTrace);

  factory MessageException.fromJson(Json json) {
    final stackTrace = StackTraceParser.fromJsonList(
        (json['stackTrace'] as List?)?.cast<Map<String, dynamic>>());
    return MessageException(
      json['name'],
      json['reason'],
      stackTrace ?? [],
    );
  }

  Json toJson() {
    return {
      'name': name,
      'reason': reason,
      'stackTrace': stackTrace.map((e) => e.toJson()).toList(),
    };
  }
}

class Message extends BaseLog {
  static int stackOffset = 0;
  String message;
  Severity severity;
  String? tag; // it is initialized after the promise.
  List<StackTraceElement>? stackTrace;
  Error? error;
  MessageException? exception;
  String? function;
  String? fileName;
  int? lineNumber;
  String? callerRawFrame; // Raw caller frame for server-side DWARF symbolication (single frame)
  List<String>? callStackSymbols; // Full raw stack trace for server-side DWARF symbolication

  Message(this.message,
          this.severity,
          this.tag,
          this.stackTrace,
          this.error,
          this.function,
          this.fileName,
          this.lineNumber,
          [Json? json]) : super(LogType.message, json) {
    if (error != null) {
      final errorStackTrace = StackTraceParser.parse(StackTrace.current.toString());
      exception = MessageException(
        error.runtimeType.toString(),
        error.toString(),
        errorStackTrace ?? [],
      );
    }

    if (fileName == null) {
      // Frame 0: Message constructor, 1: Log._message, 2: Log.d/message, 3: caller
      final frameIndex = 3 + stackOffset;
      final stackTraceString = StackTrace.current.toString();
      final lines = stackTraceString.split('\n');
      if (lines.length > frameIndex) {
        final line = lines[frameIndex];
        final regex = RegExp(r'#\d+\s+(.+)\s+\((.+?):(\d+)(?::(\d+))?\)');
        final match = regex.firstMatch(line);

        if (match != null) {
          function = match.group(1);
          fileName = match.group(2);
          lineNumber = int.parse(match.group(3)!);
          InnerLog().d('Function: $function FileName: $fileName LineNumber: $lineNumber');
        }
      }

      // Fallback for release builds where stack traces aren't parseable.
      // Store the raw caller frame for server-side DWARF symbolication.
      if (fileName == null && lines.length > frameIndex && lines[frameIndex].isNotEmpty) {
        callerRawFrame = lines[frameIndex];
      }

      if ((tag == null || tag!.isEmpty) && fileName != null) {
        final dotIndex = fileName!.indexOf('.');
        tag = dotIndex > 0 ? fileName!.substring(0, dotIndex) : fileName;
      }

      fileName ??= '';
      lineNumber ??= -1;
      tag ??= '';
    }
  }

  @override
  factory Message.fromJson(Json json) {
    final stackTrace = StackTraceParser.fromJsonList(
       (json['stackTrace'] as List?)?.cast<Map<String, dynamic>>()
    );
    final msg = Message(
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
    msg.callerRawFrame = json['callerRawFrame'];
    msg.callStackSymbols = (json['callStackSymbols'] as List?)?.cast<String>();
    if (json['exception'] is Map<String, dynamic>) {
      msg.exception = MessageException.fromJson(json['exception']);
    }
    return msg;
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
    
    if (callerRawFrame != null) json['callerRawFrame'] = callerRawFrame;
    if (callStackSymbols != null) {
      json['callStackSymbols'] = callStackSymbols;
    } else if (stackTrace != null) {
      json['stackTrace'] = stackTrace;
    }
    if (exception != null) json['exception'] = exception!.toJson();
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
      final element = StackTraceElement.tryParse(line);
      if (element != null) elements.add(element);
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

  static StackTraceElement? tryParse(String line) {
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

    return null;
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
import 'base_log.dart';
import 'common_types.dart';
import 'message.dart';

class SBException extends BaseLog {
  String name;
  String reason;
  List<StackTraceElement>? stackTrace;
  List<String>? callStackSymbols;

  SBException(this.name, this.reason, {this.stackTrace, this.callStackSymbols, Json? json})
      : super(LogType.exception, json);

  factory SBException.fromError(Object error, StackTrace stackTrace, {String? context}) {
    final stackTraceString = stackTrace.toString();
    final parsed = StackTraceParser.parse(stackTraceString);
    final symbols = stackTraceString.split('\n').where((l) => l.isNotEmpty).toList();
    final reason = context != null ? '$context: $error' : error.toString();

    return SBException(
      error.runtimeType.toString(),
      reason,
      stackTrace: (parsed != null && parsed.isNotEmpty) ? parsed : null,
      callStackSymbols: (parsed == null || parsed.isEmpty) ? symbols : null,
    );
  }

  @override
  factory SBException.fromJson(Json json) {
    final stackTrace = StackTraceParser.fromJsonList(
        (json['stackTrace'] as List?)?.cast<Map<String, dynamic>>());
    return SBException(
      json['name'],
      json['reason'],
      stackTrace: stackTrace,
      callStackSymbols: (json['callStackSymbols'] as List?)?.cast<String>(),
      json: json,
    );
  }

  @override
  Json toJson() {
    final json = super.toJson();
    json['name'] = name;
    json['reason'] = reason;
    if (callStackSymbols != null) {
      json['callStackSymbols'] = callStackSymbols;
    } else if (stackTrace != null) {
      json['stackTrace'] = stackTrace;
    }
    return json;
  }
}

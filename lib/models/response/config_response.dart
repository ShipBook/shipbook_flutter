import '../common_types.dart';

class ConfigResponse {
  Json additionalProperties = {};
  bool eventLoggingDisabled = false;
  bool exceptionReportDisabled = false;
  List<AppenderResponse> appenders = [];
  List<LoggerResponse> loggers = [];
  RootResponse? root;

  ConfigResponse({
    required this.additionalProperties,
    required this.eventLoggingDisabled,
    required this.exceptionReportDisabled,
    required this.appenders,
    required this.loggers,
    this.root,
  });

  // Factory method to create a ConfigResponse from JSON
  factory ConfigResponse.fromJson(Json json) {
    return ConfigResponse(
      additionalProperties: json['additionalProperties'] ?? {},
      eventLoggingDisabled: json['eventLoggingDisabled'] ?? false,
      exceptionReportDisabled: json['exceptionReportDisabled'] ?? false,
      appenders: (json['appenders'] as List<dynamic>?)
              ?.map((item) => AppenderResponse.fromJson(item))
              .toList() ??
          [],
      loggers: (json['loggers'] as List<dynamic>?)
              ?.map((item) => LoggerResponse.fromJson(item))
              .toList() ??
          [],
      root: json['root'] != null ? RootResponse.fromJson(json['root']) : null,
    );
  }
}

class AppenderResponse {
  String type;
  String name;
  Json? config;

  AppenderResponse({
    required this.type,
    required this.name,
    this.config,
  });

  // Factory method to create an AppenderResponse from JSON
  factory AppenderResponse.fromJson(Json json) {
    return AppenderResponse(
      type: json['type'],
      name: json['name'],
      config: json['config'],
    );
  }
}

class LoggerResponse {
  String? name;
  String severity;
  String? callStackSeverity;
  String appenderRef;

  LoggerResponse({
    this.name,
    required this.severity,
    this.callStackSeverity,
    required this.appenderRef,
  });
  
  // Factory method to create a LoggerResponse from JSON
  factory LoggerResponse.fromJson(Json json) {
    return LoggerResponse(
      name: json['name'],
      severity: json['severity'],
      callStackSeverity: json['callStackSeverity'],
      appenderRef: json['appenderRef'],
    );
  }

}

class RootResponse {
  String severity;
  String appenderRef;

  RootResponse({
    required this.severity,
    required this.appenderRef,
  });

  // Factory method to create a RootResponse from JSON
  factory RootResponse.fromJson(Json json) {
    return RootResponse(
      severity: json['severity'],
      appenderRef: json['appenderRef'],
    );
  }
}
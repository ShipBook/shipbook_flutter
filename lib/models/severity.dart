enum Severity {
  Off, 
  Error,
  Warning,
  Info,
  Debug,
  Verbose,
}


Severity stringToSeverity(String severity) {
  return Severity.values.firstWhere((e) => e.toString().split('.').last == severity);
}
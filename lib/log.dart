import './models/message.dart';
import './models/severity.dart';

import 'log_manager.dart';

class Log {
  final String tag;
  
  Log(this.tag)  {
    print("Shipbook: $tag");
  }
  // static e(String message){
  //   print("Shipbook: $message");
  // }
  // static w(String message){
  //   print("Shipbook: $message");
  // }
  // static i(String message){
  //   print("Shipbook: $message");
  // }
  // static d(String message){
  //   print("Shipbook: $message");
  // }
  // static v(String message){
  //   print("Shipbook: $message");
  // }

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
    if (severity.index > severity.index ) return;
    final stackTrace = e?.stackTrace.toString();
    final message = Message(msg, severity, tag, stackTrace, e, func, file, line);
    LogManager().push(message);
  }
}
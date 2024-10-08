library shipbook_flutter;

import 'models/common_types.dart';
import '../networking/session_manager.dart';

import 'inner_log.dart';
import 'log.dart';
// import 'log_manager.dart';
// import 'models/screen_event.dart';
// import 'networking/connection_client.dart';
// import 'networking/session_manager.dart';

class Shipbook {
  static Future<String?> start(String appId, String appKey, [String? url]) async {
    return await sessionManager.login(appId, appKey);
  }

  static void enableInnerLog(bool enable) {
    InnerLog().enabled = enable;
  }

  static void setConnectionUrl(String url) {
    // connectionClient.BASE_URL = url;
  }

  static void registerUser(String userId, {String? userName, String? fullName, String? email, String? phoneNumber, Json? additionalInfo}) {
    // sessionManager.registerUser(userId, userName, fullName, email, phoneNumber, additionalInfo);
  }

  static void logout() {
    // sessionManager.logout();
  }

  static Log getLogger(String tag) {
    return Log(tag);
  }

  static void flush() {
    // logManager.flush();
  }

  static void screen(String name) {
    // final event = ScreenEvent(name);
    // logManager.push(event);
  }

  // static String getUUID() {
    // return sessionManager.getUUID();
  // }
}


import 'dart:convert';
import 'dart:math';
// import '../event_emitter.dart';
import 'package:shipbook_flutter/event_emitter.dart';

import '../exception_manager.dart';
import '../log_manager.dart';
import '../models/common_types.dart';
import '../storage.dart';

import '../models/user.dart';

import '../models/response/config_response.dart';
import '../inner_log.dart';
import '../models/login.dart';
import 'connection_client.dart';

const defaultConfig = 
    '''
    {
      "appenders": [{
        "type": "ConsoleAppender",
        "name": "console",
        "config": {"pattern":"\$message"}
      }, {
        "type": "SBCloudAppender",
        "name": "cloud", 
        "config": {"maxTime":5,"flushSeverity":"Warning"}
      }],
      "loggers": [{
        "name": "",
        "severity": "Verbose",
        "appenderRef": "console"
      },{
        "name": "",
        "severity": "Verbose",
        "appenderRef": "cloud"
      }]}
    '''
;

class SessionManager {
  static const _sessionLinkHeader = 'x-shipbook-session';
  static const _pauseKey = 'pause';
  static const _maxPause = Duration(days: 30);
  static const _maxBackoffSeconds = 60 * 60;
  static const _defaultBackoffSeconds = 5 * 60;

  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? token;
  String? sessionLink;
  Login? _loginObj;

  Login? get loginObj {
    if (_loginObj != null) _loginObj!.user = user;
    return _loginObj;
  }

  set loginObj(Login? loginObj) {
    _loginObj = loginObj;
  }

  User? user;
  String? appId;
  String? appKey;

  bool isInLoginRequest = false;
  DateTime? pausedUntil;
  DateTime? backoffUntil;

  bool get paused => pausedUntil?.isAfter(DateTime.now()) ?? false;
  bool get stopped => paused || (backoffUntil?.isAfter(DateTime.now()) ?? false);

  Future<String?> login(String appId, String appKey) async {
    this.appId = appId;
    this.appKey = appKey;
    loginObj = Login(appId, appKey);

    ConfigResponse config;
    try {
      config = ConfigResponse.fromJson(jsonDecode(Storage().getString('config') ?? defaultConfig));
    } catch (e) {
      // A corrupt cached config must never block login, otherwise the SDK stays silent until app data is cleared.
      InnerLog().w('cached config is corrupt, deleting it and falling back to the default config: $e');
      Storage().remove('config');
      config = ConfigResponse.fromJson(jsonDecode(defaultConfig));
    }
    readConfig(config);

    final savedPause = Storage().getString(_pauseKey);
    pausedUntil = null;
    try {
      final pause = jsonDecode(savedPause ?? '{}');
      if (pause['appId'] == appId && pause['sdkVersion'] == Login.currentSdkVersion) {
        pausedUntil = DateTime.fromMillisecondsSinceEpoch(pause['until']);
      }
    } catch (e) {
      InnerLog().w('saved pause is corrupt, deleting it: $e');
    }
    if (paused && !pausedUntil!.isAfter(DateTime.now().add(_maxPause))) {
      InnerLog().w('paused until ${pausedUntil!.toUtc().toIso8601String()} (from an earlier run); nothing will be sent');
    } else if (savedPause != null) {
      pausedUntil = null;
      Storage().remove(_pauseKey);
    }
    return await innerLogin();
  }

  Future<String?> innerLogin() async {
    if (stopped) return null;

    await loginObj!.initializationDone;
    if (isInLoginRequest || loginObj == null) return null;

    isInLoginRequest = true;
    token = null;
    sessionLink = null;
    try {
      var loginObjData = loginObj!.toJson();
      InnerLog().d('loginObjData: $loginObjData');

      var resp = await ConnectionClient.request('auth/loginSdk', loginObjData, HttpMethod.post);
      InnerLog().d('resp: $resp');
      isInLoginRequest = false;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        var json = jsonDecode(resp.body);
        InnerLog().i('Succeeded!: $json');
        token = json['token'];
        sessionLink = json['sessionLink']; // absent when the device is silenced

        readConfig(ConfigResponse.fromJson(json['config']));

        // eventEmitter.emit(CONNECTED);
        Storage().setString('config', jsonEncode(json['config']));

        return json['sessionUrl'];
      } else if (stopped) {
        // the pause or back-off line already says what the server answered
        return null;
      } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
        // 4xx on loginSdk = integration error (bad appId/appKey, app deleted). Retrying won't help — caller must fix the integration.
        InnerLog().e('loginSdk rejected with ${resp.statusCode} — check appId/appKey. Will not retry. body: ${resp.body}');
        return null;
      } else {
        InnerLog().e('didn\'t succeed to log');
        var text = resp.body;
        if (text.isNotEmpty) {
          InnerLog().e('the info that was received: $text');
        }
        return null;
      }
    } catch (e) {
      InnerLog().e('there was an error with the request: $e');
    }
    return null;
  }

  void readConfig(ConfigResponse config) {
    if (!config.exceptionReportDisabled) ExceptionManager().start();
    if (!config.eventLoggingDisabled) {
      InnerLog().i('event loggint enabled');//eventManager.enableAppState();
    }
    else {
      InnerLog().i('event logging disabled'); //eventManager.removeAppState();
    }

    LogManager().config(config);
  }

  void pause(int seconds, int status) {
    final until = DateTime.now().add(Duration(seconds: min(seconds, _maxPause.inSeconds)));
    pausedUntil = until;
    token = null;
    sessionLink = null;
    Storage().setString(_pauseKey, jsonEncode({'appId': appId, 'sdkVersion': Login.currentSdkVersion, 'until': until.millisecondsSinceEpoch}));
    InnerLog().w('paused until ${until.toUtc().toIso8601String()}: the server answered $status with x-shipbook-pause $seconds');
  }

  void backOff(int retryAfter, int status) {
    final until = DateTime.now().add(Duration(seconds: retryAfter > 0 ? min(retryAfter, _maxBackoffSeconds) : _defaultBackoffSeconds));
    backoffUntil = until;
    InnerLog().w('backing off until ${until.toUtc().toIso8601String()}: the server answered $status');
  }

  void loginAfterStop() {
    if (stopped || (pausedUntil == null && backoffUntil == null)) return;
    pausedUntil = null;
    backoffUntil = null;
    if (token == null) innerLogin();
  }

  void logout() {
    token = null;
    user = null;
    if (loginObj != null) loginObj = Login(appId!, appKey!);
    innerLogin();
  }

  void registerUser(String userId,  {String? userName, String? fullName, String? email, String? phoneNumber, Json? additionalInfo}) {
    user = User(userId:userId, userName: userName, fullName: fullName, email: email, phoneNumber: phoneNumber, additionalInfo: additionalInfo);
    if (_loginObj != null) EventEmitter().emit(EventType.userChange, user);
  }

  Future<bool> refreshToken() async {
    var refresh = {
      "token": token,
      "appKey": loginObj!.appKey,
    };
    token = null;
    var resp = await ConnectionClient.request("auth/refreshSdkToken", refresh, HttpMethod.post);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      var json = jsonDecode(resp.body);
      token = json['token'];
      return true;
    } else {
      return false;
    }
  }

  String? getUUID() {
    return loginObj?.udid;
  }

  // Empty until login completes and on silenced devices, so callers can always spread it.
  Map<String, String> getSessionHeaders() {
    final link = sessionLink;
    if (link == null) return {};
    return {_sessionLinkHeader: link};
  }
}


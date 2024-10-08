// import 'package:your_package/event_emitter.dart';
// import 'package:your_package/event_manager.dart';
// import 'package:your_package/exception_manager.dart';
// import 'package:your_package/inner_log.dart';
// import 'package:your_package/log_manager.dart';
// import 'package:your_package/models/login.dart';
// import 'package:your_package/models/user.dart';
// import 'package:your_package/storage.dart';
// import 'package:your_package/connection_client.dart';

import 'dart:convert';
// import '../event_emitter.dart';
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
  String? token;
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

  Future<String?> login(String appId, String appKey) async {
    var configString = Storage().getString('config');
    configString ??= defaultConfig;
    final config = ConfigResponse.fromJson(jsonDecode(configString));
    readConfig(config);

    this.appId = appId;
    this.appKey = appKey;
    loginObj = Login(appId, appKey);
    await loginObj!.initializationDone;
    return await innerLogin();
  }

  Future<String?> innerLogin() async {
    if (isInLoginRequest || loginObj == null) return null;

    isInLoginRequest = true;
    token = null;
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

        readConfig(ConfigResponse.fromJson(json['config']));

        // eventEmitter.emit(CONNECTED);
        Storage().setString('config', jsonEncode(json['config']));

        return json['sessionUrl'];
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
    if (!config.exceptionReportDisabled)  InnerLog().i('exception enabled');//exceptionManager.start();
    if (!config.eventLoggingDisabled) {
      InnerLog().i('event loggint enabled');//eventManager.enableAppState();
    }
    else {
      InnerLog().i('event logging disabled'); //eventManager.removeAppState();
    }

    LogManager().config(config);
  }

  void logout() {
    token = null;
    user = null;
    if (loginObj != null) loginObj = Login(appId!, appKey!);
    innerLogin();
  }

  void registerUser(String userId,  {String? userName, String? fullName, String? email, String? phoneNumber, Json? additionalInfo}) {
    user = User(userId:userId, userName: userName, fullName: fullName, email: email, phoneNumber: phoneNumber, additionalInfo: additionalInfo);
    // if (_loginObj != null) eventEmitter.emit(USER_CHANGE);
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
}

final sessionManager = SessionManager();


import 'dart:async';
import 'dart:convert';

import 'package:shipbook_flutter/models/base_log.dart';
import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/severity.dart';
import 'package:shipbook_flutter/networking/session_manager.dart';
import 'package:shipbook_flutter/storage.dart';

import '../../networking/connection_client.dart';
import '../common_types.dart';
import '../login.dart';

import '../../inner_log.dart';
import '../user.dart';
import 'base_appender.dart';


enum DataType {
  token,
  login,
  user
}

class StorageData {
  final String type;
  final dynamic data;

  StorageData({required this.type, required this.data});
}

class SessionData {
  String? token;
  Login? login;
  List<BaseLog>? logs;
  User? user;

  SessionData({this.token, this.login, this.logs, this.user});
}



// ignore: constant_identifier_names
const SESSION_DATA = 'session_data';
class SBCloudAppender implements BaseAppender {
  var maxTime = 4;
  var flushSeverity = Severity.Verbose;
  var flushSize = 1000;
  var maxLogSize = 5000;

  var flushQueue = <BaseLog>[];
  Timer? timer;
  var hasLog = false;
  // appstatesubsicription
  // var appStateSubscription;
  // eventlistener

  static var started = false;
  @override
  final String name;
  SBCloudAppender(this.name, Json? config){
    update(config);
    started = true;
    InnerLog().i('SBCloudAppender created');
  }  

  @override
  void update(Json? config) {
    maxTime = config?['maxTime'] ?? maxTime;
    flushSeverity = config?['flushSeverity'] ? stringToSeverity(config!['flushSeverity']) : flushSeverity;
    flushSize = config?['flushSize'] ?? flushSize;
  }

  @override
  Future<void> push(log) async {    
    if (log.type == LogType.message) {
      final message = log as Message;
      if (message.severity.index >= flushSeverity.index) {
        flushQueue.add(message);
        if (flushQueue.length >= flushSize) {
          flush();
        }
      }
    }
  }

   Future<void> pushMessage(Message log) async {
    // send message to server
    final Message message = log;
    flushQueue.add(message);
    if (flushSeverity.index < message.severity.index) {
      InnerLog().d('entered flush queue');
      if (flushQueue.length > flushSize) flushQueue.removeAt(0);
    }
    else { // the info must be flushed and saved 
      InnerLog().d('entered save ');
      final flushQueueTemp = [...flushQueue];
      flushQueue = [];
      saveToStorage(flushQueueTemp);
      createTimer();
    }
  }

  @override
  void flush() {
    InnerLog().d('flushed logs');
    send();
  }

  Future<void> send() async {
    InnerLog().d('entered send');
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }

    if (sessionManager.token != null) return; 

    final sessionsData = _loadSessionData();

    if (sessionsData.isEmpty) return;

    final data = jsonEncode(sessionsData);

    final resp = await ConnectionClient.request('sessions/uploadSavedData', data, HttpMethod.post);
    if (ConnectionClient.isOk(resp)) {
      InnerLog().d('got ok of upload ${resp.body}');

    } else {
      InnerLog().e('failed upload ${resp.body}');
    }
  }

  List<SessionData> _loadSessionData() {
    InnerLog().d('entered load session data');
    final storageData = Storage().getList(SESSION_DATA);
    if (storageData == null) return [];

    final List<SessionData> sessionData = [];
    for (var data in storageData) {
      if (data.type == DataType.token.toString()) {

        sessionData.add(SessionData(token: data.data));
      } else if (data.type == DataType.login.toString()) {
        sessionData.add(SessionData(login: data.data));
      } else if (data.type == DataType.user.toString()) {
        sessionData.add(SessionData(user: data.data));
      } else { // it is a log
        sessionData.add(SessionData(logs: [BaseLog.fromJson(data.data)]));
      }
    }
    return sessionData;
  }


  void saveToStorage(dynamic data) {
    InnerLog().d('entered save to storage');

    // first delete all if there are more than maxLogSize
    var storageData = Storage().getList(SESSION_DATA);
    storageData ??= [];
    if (storageData.length > maxLogSize) {
      Storage().remove(SESSION_DATA);
      storageData.clear();
    }

    if (!hasLog) {
      hasLog = true;
      final token = SessionManager().token;
      if (token != null) storageData.add(StorageData(type: DataType.token.toString(), data: token));
      final login = SessionManager().loginObj;
      if (login != null) storageData.add(StorageData(type: DataType.login.toString(), data: login.toJson()));
    }

    if (data is List<BaseLog>) {
      for (var log in data) {
        storageData.add(StorageData(type: log.type.toString(), data: log.toJson()));
      }
    } else if (data is User) {
      storageData.add(StorageData(type: DataType.user.toString(), data: data.toJson()));
    } else {
      throw ArgumentError('Invalid data type. Expected List<BaseLog> or User.');
    }

    Storage().addAllList(SESSION_DATA, storageData);
  }

  void createTimer() {
    if (timer != null) return;
    timer = Timer(Duration(seconds: maxTime), () {
      send();
      timer = null;
    });
  }

  @override
  void destructor() {
    // Do nothing
  }
}
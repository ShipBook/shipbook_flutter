import 'dart:async';
import 'dart:convert';

import 'package:shipbook_flutter/event_emitter.dart';
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
  user,
  log
}

class StorageData implements JsonEncodable {
  final DataType type;
  final dynamic data;

  StorageData({required this.type, required this.data});

  @override
  Json toJson() {
    return {
      'type': type.name,
      'data': data,
    };
  }
}

class SessionData implements JsonEncodable {
  String? token;
  Login? login;
  List<BaseLog> logs = [];
  User? user;

  SessionData({this.token, this.login, this.user, List<BaseLog>? logs}) {
    if (logs != null) this.logs = logs;
  }

  @override
  Json toJson() {
    final json = <String, dynamic>{};
    if (token != null) json['token'] = token;
    if (login != null) json['login'] = login!.toJson();
    if (user != null) json['user'] = user!.toJson();
    json['logs'] = logs.map((e) => e.toJson()).toList();
    return json;
  }
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
    
    // add event listener for user change
    EventEmitter().on(EventType.userChange).listen(_userChangeController);

    InnerLog().i('SBCloudAppender created');
  }  

  @override
  void dispose() {
    EventEmitter().off(EventType.userChange, _userChangeController);
  }

  void _userChangeController(dynamic data) {
    InnerLog().d('user change event');
    if (data is User) { 
      saveToStorage(data);
    }
  }

  @override
  void update(Json? config) {
    maxTime = config?['maxTime'] ?? maxTime;
    flushSeverity = (config?['flushSeverity'] != null) ? stringToSeverity(config!['flushSeverity']) : flushSeverity;
    flushSize = config?['flushSize'] ?? flushSize;
  }

  @override
  Future<void> push(log) async {    
    if (log.type == LogType.message) {
      await pushMessage(log as Message);
    } else {
      InnerLog().e('Invalid log type: ${log.type}');
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

    if (SessionManager().token == null) return; 

    final sessionsData = loadSessionData();

    if (sessionsData.isEmpty) return;

    final json = sessionsData.map((e) => e.toJson()).toList();
    final data = jsonEncode(json);

    final resp = await ConnectionClient.request('sessions/uploadSavedData', data, HttpMethod.post);
    if (ConnectionClient.isOk(resp)) {
      InnerLog().d('got ok of upload ${resp.body}');

    } else {
      InnerLog().e('failed upload ${resp.body}');
    }
  }

  List<SessionData> loadSessionData() { // should be private but for testing it is public
    InnerLog().d('entered load session data');
    final storageData = Storage().getList(SESSION_DATA);
    Storage().remove(SESSION_DATA);
    if (storageData == null || storageData.isEmpty) return [];

    final List<SessionData> sessionsData = [];
    SessionData? sessionData;
    InnerLog().d('dataType values: ${DataType.values}');
    for (var data in storageData) {
      // DataType type = DataType.values.firstWhere((e) => e.toString().split('.').last == data['type']);
      DataType type = DataType.values.byName(data['type']);
      switch(type) {
        case DataType.token:
          if (sessionData != null) sessionsData.add(sessionData);
          sessionData = SessionData(token: data['data']);
          break;
        case DataType.login:
          if (sessionData != null) sessionsData.add(sessionData);
          sessionData = SessionData(login: Login.fromJson(data['data']));
          break;
        case DataType.user:
          sessionData!.user = User.fromJson(data['data']);
          InnerLog().d('user: ${sessionData.user}');
          break;
        case DataType.log: 
          if (sessionData == null) {
            InnerLog().e('session data is null $storageData');
          } else {
            final logs = BaseLog.fromJson(data['data']);
            sessionData.logs.add(logs);
          }
          break;
      }
    }

    if (sessionData != null) sessionsData.add(sessionData);

    return sessionsData;
  }


  void saveToStorage(dynamic data) {
    InnerLog().d('entered save to storage');

    // first delete all if there are more than maxLogSize
    var storageData = Storage().getList(SESSION_DATA) as List<Json>?;
    if (storageData != null && storageData.length > maxLogSize) {
      Storage().remove(SESSION_DATA);
      storageData = [];
    }
    
    storageData ??= [];
    if (storageData.length > maxLogSize) {
      Storage().remove(SESSION_DATA);
      storageData.clear();
    }

    if (!hasLog) {
      hasLog = true;
      final token = SessionManager().token;
      if (token != null) storageData.add(StorageData(type: DataType.token, data: token).toJson());
      final login = SessionManager().loginObj;
      if (login != null) storageData.add(StorageData(type: DataType.login, data: login.toJson()).toJson());
    }

    if (data is List<BaseLog>) {
      for (var log in data) {
        storageData.add(StorageData(type: DataType.log, data: log.toJson()).toJson());
      }
    } else if (data is User) {
      storageData.add(StorageData(type: DataType.user, data: data.toJson()).toJson());
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

    InnerLog().i('Timer created');
  }
  
}
import 'dart:io';
import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'user.dart';

class Login {
  String appId;
  String appKey;
  String bundelIdentifier = '';
  String appName = '';
  String udid = '';
  DateTime time = DateTime.now();
  DateTime deviceTime = DateTime.now();
  String os = Platform.operatingSystem;
  String platform = 'flutter';
  String osVersion = '';
  String appVersion = '';
  String appBuild = '';
  String sdkVersion = '0.0.1';
  String manufacturer = '';
  String deviceName = '';
  String deviceModel = '';
  String language = Platform.localeName;
  User? user;

  final Completer<void> _initializationCompleter = Completer<void>();

  Login(this.appId, this.appKey) {
    _initialize().then((_) {
      _initializationCompleter.complete();
    });
  }  

  Future<void> _initialize() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      udid = androidInfo.id;
      manufacturer = androidInfo.manufacturer;
      deviceName = androidInfo.display;
      deviceModel = androidInfo.model;  
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      udid = iosInfo.identifierForVendor ?? '';
      manufacturer = "Apple";
      deviceName = iosInfo.name;
      deviceModel = iosInfo.model;
      osVersion = iosInfo.systemVersion;

    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    bundelIdentifier = packageInfo.packageName;
    appVersion = packageInfo.version;
    appBuild = packageInfo.buildNumber;
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'appId': appId,
      'appKey': appKey,
      'bundelIdentifier': bundelIdentifier,
      'appName': appName,
      'udid': udid,
      'time': time.toIso8601String(),
      'deviceTime': deviceTime.toIso8601String(),
      'os': os,
      'platform': platform,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'appBuild': appBuild,
      'sdkVersion': sdkVersion,
      'manufacturer': manufacturer,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'language': language,
      'user': user?.toJsonMap(),
    };
  }

    // Create a Login object from a JSON map
  factory Login.fromJsonMap(Map<String, dynamic> jsonMap) {
    return Login(
      jsonMap['appId'],
      jsonMap['appKey'],
    )
      ..bundelIdentifier = jsonMap['bundelIdentifier']
      ..appName = jsonMap['appName']
      ..udid = jsonMap['udid']
      ..time = DateTime.parse(jsonMap['time'])
      ..deviceTime = DateTime.parse(jsonMap['deviceTime'])
      ..os = jsonMap['os']
      ..platform = jsonMap['platform']
      ..osVersion = jsonMap['osVersion']
      ..appVersion = jsonMap['appVersion']
      ..appBuild = jsonMap['appBuild']
      ..sdkVersion = jsonMap['sdkVersion']
      ..manufacturer = jsonMap['manufacturer']
      ..deviceName = jsonMap['deviceName']
      ..deviceModel = jsonMap['deviceModel']
      ..language = jsonMap['language']
      ..user = User.fromJsonMap(jsonMap['user']);
  }

  Future<void> get initializationDone => _initializationCompleter.future;
}
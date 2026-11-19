import 'dart:async';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../inner_log.dart';
import '../storage.dart';
import 'common_types.dart';
import 'user.dart';

class Login {
  static const currentSdkVersion = '2.0.0';
  static const _udidKey = 'udid';

  String appId;
  String appKey;
  String bundelIdentifier = '';
  String appName = '';
  String udid = '';
  DateTime time = DateTime.now();
  DateTime deviceTime = DateTime.now();
  String os = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
  String platform = 'flutter';
  String osVersion = '';
  String appVersion = '';
  String appBuild = '';
  String sdkVersion = currentSdkVersion;
  String manufacturer = '';
  String deviceName = '';
  String deviceModel = '';
  String language = PlatformDispatcher.instance.locale.toString();
  User? user;

  final Completer<void> _initializationCompleter = Completer<void>();

  Login(this.appId, this.appKey) {
    _initialize().then((_) {
      _initializationCompleter.complete();
    });
  }  

  Future<void> _initialize() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceModel = webInfo.browserName.name;
        osVersion = webInfo.platform ?? '';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final androidInfo = await deviceInfo.androidInfo;
            udid = androidInfo.id;
            manufacturer = androidInfo.manufacturer;
            deviceName = androidInfo.display;
            deviceModel = androidInfo.model;
            osVersion = androidInfo.version.release;
          case TargetPlatform.iOS:
            final iosInfo = await deviceInfo.iosInfo;
            udid = iosInfo.identifierForVendor ?? '';
            manufacturer = 'Apple';
            deviceName = iosInfo.name;
            deviceModel = iosInfo.model;
            osVersion = iosInfo.systemVersion;
          case TargetPlatform.macOS:
            final macInfo = await deviceInfo.macOsInfo;
            udid = macInfo.systemGUID ?? '';
            manufacturer = 'Apple';
            deviceName = macInfo.computerName;
            deviceModel = macInfo.model;
            osVersion = '${macInfo.majorVersion}.${macInfo.minorVersion}.${macInfo.patchVersion}';
          case TargetPlatform.windows:
            final windowsInfo = await deviceInfo.windowsInfo;
            udid = windowsInfo.deviceId;
            deviceName = windowsInfo.computerName;
            deviceModel = windowsInfo.productName;
            osVersion = windowsInfo.displayVersion;
          case TargetPlatform.linux:
            final linuxInfo = await deviceInfo.linuxInfo;
            udid = linuxInfo.machineId ?? '';
            deviceModel = linuxInfo.prettyName;
            osVersion = linuxInfo.versionId ?? '';
          case TargetPlatform.fuchsia:
            break;
        }
      }
    } catch (e) {
      // A failing plugin must not stall login forever; the stored random udid below stands in.
      InnerLog().w('could not read the device info: $e');
    }

    if (udid.isEmpty) {
      // The server rejects a login without a udid, and web or some desktops have no device id.
      await Storage().initialized;
      final storedUdid = Storage().getString(_udidKey);
      if (storedUdid != null) {
        udid = storedUdid;
      } else {
        final random = Random.secure();
        final bytes = List.generate(16, (_) => random.nextInt(256));
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        udid = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
        Storage().setString(_udidKey, udid);
      }
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      bundelIdentifier = packageInfo.packageName;
      appVersion = packageInfo.version;
      appBuild = packageInfo.buildNumber;
    } catch (e) {
      InnerLog().w('could not read the package info: $e');
    }
  }

  Json toJson() {
    return {
      'appId': appId,
      'appKey': appKey,
      'bundelIdentifier': bundelIdentifier,
      'appName': appName,
      'udid': udid,
      'time': time.toUtc().toIso8601String(),
      'deviceTime': deviceTime.toUtc().toIso8601String(),
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
      'user': user?.toJson(),
    };
  }

    // Create a Login object from a JSON map
  factory Login.fromJson(Json jsonMap) {
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
      ..user = jsonMap['user'] != null ? User.fromJson(jsonMap['user']) : null;
  }

  Future<void> get initializationDone => _initializationCompleter.future;
}
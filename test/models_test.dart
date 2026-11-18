import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipbook_flutter/models/login.dart';

void main() {
    // Ensure Flutter bindings are initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'shipbook_flutter_test',
            'packageName': 'com.test.shipbook',
            'version': '1.0.0',
            'buildNumber': '1',
            'buildSignature': '',
            'installerStore': '',
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      null,
    );
  });

    test('Login toJSON and fromJSON', () async {
      final login = Login('appId', 'appKey');
      await login.initializationDone; // Wait for the initialization to complete
      final jsonMap = login.toJson();
      final json = jsonEncode(jsonMap);
      // ignore: avoid_print
      print('the json: $json');
      final jsonMap2 = jsonDecode(json);
      final login2 = Login.fromJson(jsonMap2);
      expect(login.appId, login2.appId);
      expect(login.appKey, login2.appKey);
    });

    test('a desktop without a device id logs in with a stored random udid', () async {
      // No device_info channel is mocked, so the plugin fails as it would on a machine without an id.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final login = Login('appId', 'appKey');
        await login.initializationDone;
        expect(login.os, 'windows');
        expect(login.udid, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));

        final nextStart = Login('appId', 'appKey');
        await nextStart.initializationDone;
        expect(nextStart.udid, login.udid);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('the SDK version sent to the server matches pubspec.yaml', () {
      final pubspecVersion = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
      expect(Login.currentSdkVersion, pubspecVersion, reason: 'bump Login.currentSdkVersion together with the pubspec version');
    });

}
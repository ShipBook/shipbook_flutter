import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipbook_flutter/models/login.dart';

void main() {
    // Ensure Flutter bindings are initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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

}
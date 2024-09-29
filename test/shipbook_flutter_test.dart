import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:shipbook_flutter/shipbook_flutter.dart';
import 'package:shipbook_flutter/models/login.dart';


void main() {
  // Ensure Flutter bindings are initialized
  TestWidgetsFlutterBinding.ensureInitialized();
  test('adds one to input values', () {
    final log = Shipbook.getLogger("test tag");
    log.e("test error");
  });

  test('Login toJSON and fromJSON', ()  async{
      final login = Login('appId', 'appKey');
       await login.initializationDone; // Wait for the initialization to complete
      final jsonMap = login.toJsonMap();
      final json = jsonEncode(jsonMap);
      print('the json: $json');
      final jsonMap2 = jsonDecode(json);
      final login2 = Login.fromJsonMap(jsonMap2);
      expect(login.appId, login2.appId);
      expect(login.appKey, login2.appKey);
    });
}

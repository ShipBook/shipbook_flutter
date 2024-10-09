import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shipbook_flutter/models/appenders/base_appender.dart';
import 'package:shipbook_flutter/models/appenders/sbcloud_appender.dart';
import 'package:shipbook_flutter/models/base_log.dart';
import 'package:shipbook_flutter/models/message.dart';
import 'package:shipbook_flutter/models/severity.dart';
import 'package:shipbook_flutter/networking/session_manager.dart';
import 'package:shipbook_flutter/storage.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Add the shared_preferences plugin to the test environment
  SharedPreferences.setMockInitialValues({});  

  late SBCloudAppender cloudAppender;

  group('SharedPreferences Tests', () {
    setUp(() async {
      await Storage().initialized;
      BaseAppender baseAppender = BaseAppender.create('SBCloudAppender', 'testAppender', null);
      cloudAppender = baseAppender as SBCloudAppender;
      
    });

    test('SBCloudAppender initialization', () async {
      await Storage().initialized;
      expect(cloudAppender, isA<SBCloudAppender>());
      expect(cloudAppender.name, 'testAppender');
      expect(cloudAppender.maxTime, 4);
    });

    test('SBCloudAppender logs', () {
      const token = 'testing'; 
      SessionManager().token = token;
      List<BaseLog> logs = [];
      logs.add(Message('message 1', Severity.Debug, 'tag', null, null, 'test', 'sbcloud_appender_test.dart', 1));
      logs.add(Message('message 2', Severity.Debug, 'tag', null, null, 'test', 'sbcloud_appender_test.dart', 2));
      logs.add(Message('message 3', Severity.Debug, 'tag', null, null, 'test', 'sbcloud_appender_test.dart', 3));
      logs.add(Message('message 4', Severity.Debug, 'tag', null, null, 'test', 'sbcloud_appender_test.dart', 4));
      logs.add(Message('message 5', Severity.Debug, 'tag', null, null, 'test', 'sbcloud_appender_test.dart', 5));

      for (var log in logs) {
        cloudAppender.saveToStorage(log);
      }

      final sessionsData = cloudAppender.loadSessionData();
      expect(sessionsData.length, 1);
      final sessionData = sessionsData[0];
      expect(sessionData.token, token);
      expect(sessionData.login, isNull);
      expect(sessionData.user, isNull);
      expect(sessionData.logs!.length, 5);
      for (var i = 0; i < logs.length; i++) {
        expect(sessionData.logs![i].toJson(), logs[i].toJson());
      }
    });

    // Add more tests as needed
  });
}
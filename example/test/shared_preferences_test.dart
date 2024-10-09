import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  late SharedPreferencesWithCache _prefs;
  group('SharedPreferences Tests', () {
    setUp(() async {
          _prefs =  await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        // When an allowlist is included, any keys that aren't included cannot be used.
        // allowList: <String>{'testKey', 'testIntKey'},
      ));
      // _prefs = SharedPreferencesAsync();
      SharedPreferences.setMockInitialValues({});

      // SharedPreferencesWithCache.setMockInitialValues({});
    });

    test('Save and retrieve a string', () async {
      
      await _prefs.setString('testKey', 'testValue');
      String? value = await _prefs.getString('testKey');
      expect(value, 'testValue');
    });

    test('Save and retrieve an int', () async {
      // SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.getInstance();
      await _prefs.setInt('testIntKey', 123);
      int? value = await _prefs.getInt('testIntKey');
      expect(value, 123);
    });

    test('Save and retrieve a bool', () async {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      await _prefs.setBool('testBoolKey', true);
      bool? value = await _prefs.getBool('testBoolKey');
      expect(value, true);
    });

    test('Save and retrieve a double', () async {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      await _prefs.setDouble('testDoubleKey', 1.23);
      double? value = await _prefs.getDouble('testDoubleKey');
      expect(value, 1.23);
    });

    test('Save and retrieve a list of strings', () async {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      await _prefs.setStringList('testListKey', ['one', 'two', 'three']);
      List<String>? value = await _prefs.getStringList('testListKey');
      expect(value, ['one', 'two', 'three']);
    });

    test('Remove a key', () async {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      await _prefs.setString('testKey', 'testValue');
      await _prefs.remove('testKey');
      String? value = await _prefs.getString('testKey');
      expect(value, isNull);
    });

    test('Clear all keys', () async {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      await _prefs.setString('testKey1', 'testValue1');
      await _prefs.setString('testKey2', 'testValue2');
      await _prefs.clear();
      String? value1 = await _prefs.getString('testKey1');
      String? value2 = await _prefs.getString('testKey2');
      expect(value1, isNull);
      expect(value2, isNull);
    });
  });
}
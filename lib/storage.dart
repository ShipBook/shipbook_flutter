import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipbook_flutter/models/common_types.dart';



class Storage {
  static final Storage _instance = Storage._internal();
  factory Storage() => _instance;
  
  // late SharedPreferencesWithCache _prefs;

  late SharedPreferences _prefs;
  final Completer<void> _completer = Completer<void>();

  Storage._internal() {
    _init();
  }

  Future<void> _init() async {
    // _prefs =  await SharedPreferencesWithCache.create(
    //   cacheOptions: const SharedPreferencesWithCacheOptions(
    //     // When an allowlist is included, any keys that aren't included cannot be used.
    //     allowList: <String>{'repeat', 'action'},
    //   )
    // );

    _prefs = await SharedPreferences.getInstance();
    _completer.complete();
  }

  Future<void> get initialized => _completer.future;

  // Save a string value
  void setString(String key, String value) {
    _prefs.setString(key, value);
  }

  // Retrieve a string value
  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Save a boolean value
  void setBool(String key, bool value) {
    _prefs.setBool(key, value);
  }

  // Retrieve a boolean value
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Save an integer value
  void setInt(String key, int value) {
    _prefs.setInt(key, value);
  }

  // Retrieve an integer value
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Save a list of strings
  void setStringList(String key, List<String> value) {
    _prefs.setStringList(key, value);
  }

  // Retrieve a list of strings
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // push list to list
  void addToObjectList(String key, String value) {
    List<String>? currentList = getStringList(key);
    currentList ??= [];
    currentList.add(value);
    setStringList(key, currentList);
  }

  // Add an object to a list of objects
  void addList(String key, JsonEncodable value) {
    List<dynamic>? currentList = getList(key);
    currentList ??= [];
    currentList.add(value.toJson());
    setList(key, currentList);
  }

  void addAllList(String key, List<Json> value) {
    List<dynamic>? currentList = getList(key);
    currentList ??= [];
    currentList.addAll(value);
    setList(key, currentList);
  }

  dynamic _decodeIfJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      // If jsonDecode succeeds, return the decoded value
      return decoded;
    } catch (e) {
      // If jsonDecode fails, return the original string
      return jsonString;
    }
  }

  // Save a list of objects
  void setList(String key, List value) {
    List<String> jsonStringList = value.map((item) {
      if (item is String) {
        return item;
      } else {
        return jsonEncode(item);
      }
    }).toList();
    _prefs.setStringList(key, jsonStringList);
  }

  // Retrieve a list of objects
  List<Json>? getList(String key) {
    List<String>? jsonStringList = _prefs.getStringList(key);
    if (jsonStringList == null) return null;

    return jsonStringList.map<Json>((jsonString) => _decodeIfJsonString(jsonString)).toList();
  }

  int getListSize(String key) {
    List<String>? jsonStringList = _prefs.getStringList(key);
    return jsonStringList?.length ?? 0;
  }

  void remove(String key) {
    _prefs.remove(key);
  }
}
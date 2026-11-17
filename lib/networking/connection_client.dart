import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../models/login.dart';
import './session_manager.dart';

enum HttpMethod { get, post, put, delete }

class ConnectionClient {
  // ignore: non_constant_identifier_names
  static var BASE_URL = "https://api.shipbook.io/v2/";

  static Future<Response> request(String url, [Object? body, HttpMethod method = HttpMethod.get]) async {
    if (SessionManager().stopped) return Response('', 429);

    Response resp;
    final uri = Uri.parse(BASE_URL + url);
    final appId = SessionManager().appId;
    final headers = {
      'Content-Type': 'application/json',
      'x-shipbook-sdk': 'flutter/${Login.currentSdkVersion}',
      if (appId != null) 'x-shipbook-app-id': appId,
    };
    if (SessionManager().token != null) {
      headers['Authorization'] = 'Bearer ${SessionManager().token}';
    }


    String? stringBody ;
    if (body is String ) {
      stringBody = body;
    } else if (body != null) {
      stringBody = jsonEncode(body);
    }
    switch (method) {
      case HttpMethod.get:
        resp = await http.get(uri, headers: headers);
        break;
      case HttpMethod.post:
        resp = await http.post(uri, headers:headers, body: stringBody);
        break;
      case HttpMethod.put:
        resp = await http.put(uri, headers:headers, body: stringBody);
        break;
      case HttpMethod.delete:
        resp = await http.delete(uri, headers:headers);
        break;
    }

    final pauseSeconds = resp.statusCode < 400 ? 0 : int.tryParse(resp.headers['x-shipbook-pause'] ?? '', radix: 10) ?? 0;
    if (pauseSeconds > 0) {
      SessionManager().pause(pauseSeconds, resp.statusCode);
    } else if (resp.statusCode == 429 || resp.statusCode == 503) {
      SessionManager().backOff(int.tryParse(resp.headers['retry-after'] ?? '', radix: 10) ?? 0, resp.statusCode);
    }

    if (resp.statusCode == 401 && resp.reasonPhrase == 'TokenExpired') { // call refresh token
      if (! await SessionManager().refreshToken())  return resp;
      resp = await request(url, body, method);
    }
    return resp;    
  }

  static bool isOk(Response resp) {
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }
}
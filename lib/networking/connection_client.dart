import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import './session_manager.dart';

enum HttpMethod { get, post, put, delete }

class ConnectionClient {
  static const BASE_URL = "https://api.shipbook.io/v1/";

  Future<Response> request(String url, [Map<String, dynamic>? body, HttpMethod method = HttpMethod.get]) async {
    Response resp;
    final uri = Uri.parse(BASE_URL + url);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (sessionManager.token != null) {
      headers['Authorization'] = 'Bearer ${sessionManager.token}';
    }

    switch (method) {
      case HttpMethod.get:
        resp = await http.get(uri, headers: headers);
        break;
      case HttpMethod.post:
        resp = await http.post(uri, headers:headers, body: jsonEncode(body));
        break;
      case HttpMethod.put:
        resp = await http.put(uri, headers:headers, body: jsonEncode(body));
        break;
      case HttpMethod.delete:
        resp = await http.delete(uri, headers:headers);
        break;
    }

    if (resp.statusCode == 401 && resp.reasonPhrase == 'TokenExpired') { // call refresh token
      if (! await sessionManager.refreshToken())  return resp;
      resp = await request(url, body, method);
    }
    return resp;    
  }
}


final connectionClient = ConnectionClient();
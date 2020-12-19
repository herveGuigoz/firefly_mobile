import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import 'server.dart';
import 'models/token.dart';

export 'models/token.dart';

class Oauth with DartServerMixin {
  static const _platform = const MethodChannel(
    'com.herveguigoz.firefly_app/authenticate',
  );

  final _authorizationEndpoint = 'https://firefly.herve-guigoz.com';
  final _clientId = '90';
  final _clientSecret = 'ax7itj684cZrbPY7v8pb6fGOugYPf6fSOnMzFFqC';
  final _redirectUri = 'http://localhost:8888/';

  Uri get _tokenUrl => Uri.https(_authorizationEndpoint, 'oauth/token');

  Future<Token> getToken() async {
    Stream<String> onCode = await runDartServer();

    await _invokeMethodChannel();

    final String code = await onCode.first;
    print(code);

    final response = await _getAuthorizationCode(code);

    return Token.fromMap(json.decode(response.data) as Map<String, Object>);
  }

  Future<void> _invokeMethodChannel() async {
    await _platform.invokeMethod(
      'authenticate',
      {
        'clientId': _clientId,
        'clientSecret': _clientSecret,
        'authorizationEndpoint': _authorizationEndpoint,
        'redirectUri': _redirectUri,
      },
    );
  }

  Future<Response<String>> _getAuthorizationCode(String code) async {
    final dioResponse = await Dio().post<String>(
      '$_authorizationEndpoint/oauth/token',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: json.encode(<String, Object>{
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'redirect_uri': _redirectUri,
      }),
    );

    return dioResponse;
  }
}
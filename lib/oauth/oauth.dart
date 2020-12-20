import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/all.dart';

import '../constants.dart';
import 'server.dart';

export 'models/token.dart';

final oauth = Provider<Oauth>((ref) {
  final service = Oauth();
  ref.onDispose(service.dispose);

  return service;
});

class Oauth extends DartServerMixin {
  final _authorizationEndpoint = 'https://firefly.herve-guigoz.com';
  final _clientId = '90';
  final _clientSecret = 'ax7itj684cZrbPY7v8pb6fGOugYPf6fSOnMzFFqC';
  final _redirectUri = 'http://localhost:8888/';

  Future<void> getAuthorizationCode() async {
    await runDartServer();

    await Constants.methodChannel.invokeMethod(
      'authenticate',
      {
        'clientId': _clientId,
        'clientSecret': _clientSecret,
        'authorizationEndpoint': _authorizationEndpoint,
        'redirectUri': _redirectUri,
      },
    );
  }

  /// ```dart
  /// final response = await getOauthToken(code);
  /// return Token.fromMap(json.decode(response.data) as Map<String, Object>);
  /// ```
  Future<Response<String>> getOauthToken(String code) async {
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

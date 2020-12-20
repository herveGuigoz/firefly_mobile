import 'package:dio/dio.dart';
import 'package:firefly/core/platform/authorize.dart';
import 'package:hooks_riverpod/all.dart';

import '../constants.dart';

export 'models/token.dart';

final oauth = Provider.autoDispose<Oauth>((ref) => Oauth());

class Oauth {
  final oauthModel = OauthModel(
    clientId: '90',
    clientSecret: 'ax7itj684cZrbPY7v8pb6fGOugYPf6fSOnMzFFqC',
    authorizationEndpoint: 'https://firefly.herve-guigoz.com',
  );

  Future<void> getAuthorizationCode() async {
    await Constants.methodChannel.invokeMethod(
      'authenticate',
      oauthModel.toMap(),
    );
  }

  /// ```dart
  /// final response = await getOauthToken(code);
  /// return Token.fromMap(json.decode(response.data) as Map<String, Object>);
  /// ```
  Future<Response<String>> getOauthToken(String code) async {
    final dioResponse = await Dio().post<String>(
      '${oauthModel.authorizationEndpoint}/oauth/token',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: oauthModel.toAuthorizationCodeRequestBody(code),
    );

    return dioResponse;
  }
}

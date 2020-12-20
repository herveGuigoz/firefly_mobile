import 'dart:convert';

import 'package:flutter/material.dart';

@immutable
class OauthModel {
  OauthModel({
    @required this.clientId,
    @required this.clientSecret,
    @required this.authorizationEndpoint,
    this.toolbarColor = '#16C79E',
  });

  final String clientId;
  final String clientSecret;
  final String authorizationEndpoint;
  final String toolbarColor;
  final String redirectUri = 'http://localhost:8888/';

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'authorizationEndpoint': authorizationEndpoint,
      'redirectUri': redirectUri,
      'toolbarColor': toolbarColor,
    };
  }

  String toAuthorizationCodeRequestBody(String code) {
    return json.encode(<String, Object>{
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': code,
      'redirect_uri': redirectUri,
    });
  }

  OauthModel copyWith({
    String clientId,
    String clientSecret,
    String authorizationEndpoint,
  }) {
    return OauthModel(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      authorizationEndpoint:
          authorizationEndpoint ?? this.authorizationEndpoint,
      toolbarColor: this.toolbarColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OauthModel &&
        other.clientId == clientId &&
        other.clientSecret == clientSecret &&
        other.authorizationEndpoint == authorizationEndpoint &&
        other.toolbarColor == toolbarColor;
  }

  @override
  int get hashCode {
    return clientId.hashCode ^
        clientSecret.hashCode ^
        authorizationEndpoint.hashCode ^
        toolbarColor.hashCode;
  }

  @override
  String toString() {
    return 'OauthModel(clientId: $clientId, clientSecret: $clientSecret, authorizationEndpoint: $authorizationEndpoint, toolbarColor: $toolbarColor)';
  }
}

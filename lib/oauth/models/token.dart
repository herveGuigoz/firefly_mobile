import 'package:flutter/material.dart';

@immutable
class Token {
  const Token(
      this.type,
      this.expiresIn,
      this.accessToken,
      this.refreshToken,
      );

  final String type;
  final int expiresIn;
  final String accessToken;
  final String refreshToken;

  Token.fromMap(Map<String, dynamic> json)
      : type = json['token_type'] as String,
        expiresIn = json['expires_in'] as int,
        accessToken = json['access_token'] as String,
        refreshToken = json['refresh_token'] as String;
}
import 'package:flutter/services.dart';

mixin Constants {
  // Method channel creation
  static const methodChannel = const MethodChannel(
    'com.herveguigoz.firefly/channel',
  );

  // Event Channel creation
  static const eventChannel = const EventChannel(
    'com.herveguigoz.firefly/events',
  );
}

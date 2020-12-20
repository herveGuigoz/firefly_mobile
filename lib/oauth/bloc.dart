import 'dart:async';

import 'package:firefly/constants.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/all.dart';

abstract class _Bloc {
  void dispose();
}

class DeepLinkBloc extends _Bloc {
  // Adding the listener into contructor
  DeepLinkBloc() {
    // Checking application start by deep link
    startUri().then(_onRedirected);
    // Checking broadcast stream, if deep link was clicked in opened appication
    Constants.eventChannel
        .receiveBroadcastStream()
        .listen((d) => _onRedirected(d));
  }

  StreamController<String> _stateController = StreamController();

  Stream<String> get state => _stateController.stream;

  _onRedirected(String uri) {
    // Throw deep link URI into the BloC's stream
    _stateController.sink.add(uri);
  }

  Future<String> startUri() async {
    try {
      return Constants.methodChannel.invokeMethod('initialLink');
    } on PlatformException catch (e) {
      return "Failed to Invoke: '${e.message}'.";
    }
  }

  @override
  void dispose() {
    _stateController.close();
  }
}

final deepLinkBloc = StreamProvider<String>((ref) {
  final bloc = DeepLinkBloc();
  ref.onDispose(bloc.dispose);

  return bloc.state;
});

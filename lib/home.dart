import 'package:firefly/oauth/bloc.dart';
import 'package:firefly/oauth/oauth.dart';
import 'package:firefly/oauth/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/all.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DartServer server;
  @override
  void initState() {
    server = DartServer()..runDartServer();
    super.initState();
  }

  @override
  void dispose() {
    server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Body();
  }
}

class _Body extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final deepLinkState = useProvider(deepLinkBloc);

    return Scaffold(
      body: deepLinkState.maybeWhen(data: (link) {
        return Container(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Redirected: $link',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        );
      }, orElse: () {
        return Container(
          child: Center(
            child: Text(
              'No deep link was used  ',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => context.read(oauth).getAuthorizationCode(),
      ),
    );
  }
}

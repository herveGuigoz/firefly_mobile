import 'package:firefly/oauth/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/all.dart';

class Home extends HookWidget {
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
    );
  }
}

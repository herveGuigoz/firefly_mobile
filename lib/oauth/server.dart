import 'dart:async';
import 'dart:io';

abstract class DartServerMixin {
  HttpServer server;

  Future<void> runDartServer() async {
    server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      8888,
    );
    server.listen((HttpRequest request) async {
      final String code = request.uri.queryParameters["code"];
      final uri = Uri.parse('com.herveguigoz.firefly://oauth?code=$code');
      request.response.redirect(uri);

      // request.response
      //   ..statusCode = 200
      //   ..headers.set("Content-Type", 'text/html')
      //   ..write(_htmlResponse);
      await request.response.close();
    });
  }

  Future<void> dispose() async {
    await server?.close(force: true);
  }
}

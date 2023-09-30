import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

import 'package:localtunnel/localtunnel.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });

  test('create a localtunnel', ()  async {

    final router = shelf_router.Router()
      ..get('/helloworld', helloWorldHandler);

    final server = await shelf_io.serve(
      shelf.logRequests()
      .addHandler(router),
      InternetAddress.anyIPv4, // Allows external connections
      11978,
    );

    final lt = Tunnel({
      'local_host': 'localhost',
      'local_port', 11978
    });

    await Future.delayed(const Duration(seconds: 15));
    server.close(force: true);

  });
}

shelf.Response helloWorldHandler(shelf.Request request) =>
    shelf.Response.ok('Hello, World!');

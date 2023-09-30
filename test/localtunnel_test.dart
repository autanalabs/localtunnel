import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'package:http/http.dart' as http;

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
    await Future.delayed(const Duration(seconds: 1));
    print("Dart Shelf server listening at 0.0.0.0:11978");

    print('creating localtunnel to localhost:11978...');
    final lt = Tunnel(opts: {
      'local_host': 'localhost',
      'local_port': 11978
    });
    await lt.open();
    print ("localtunnel created and exposed URL=${lt.url}");
    await Future.delayed(const Duration(seconds: 1));

    print ("trying GET ${lt.url}/helloworld ...");
    final response = await http.get(Uri.parse('${lt.url}/helloworld'));

    print("received status = ${response.statusCode}");
    if (response.statusCode == 200) {
      print("body = ${response.body}");
    } else {
      print('Error: ${response.statusCode}');
    }

    await Future.delayed(const Duration(seconds: 1));
    lt.close();
    print("localtunnel closed.");
    server.close(force: true);
    print("Dart Shelf server closed.");

  });
}

shelf.Response helloWorldHandler(shelf.Request request) {
  print ("helloWorldHandler: received request!");
  print ("helloWorldHandler: method = ${request.method}");
  print ("helloWorldHandler: url = ${request.url}");
  print ("helloWorldHandler: params = ${request.params}");
  print ("helloWorldHandler: headers = ${request.headers}");
  return shelf.Response.ok('Hello, World!');
}


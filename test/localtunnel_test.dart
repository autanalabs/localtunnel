import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:http/http.dart' as http;

import 'package:localtunnel/localtunnel.dart';

void main() {

  test('create a localtunnel', ()  async {

    final router = shelf_router.Router()
      ..get('/helloworld', helloWorldHandler);

    final server = await shelf_io.serve(
      shelf.logRequests()
      .addHandler(router),
      InternetAddress.anyIPv4, // Allows external connections
      11978,
    );
    print("Dart Shelf server listening at 0.0.0.0:11978");

    print('creating localtunnel to localhost:11978...');
    final lt = Tunnel(opts: {
      'local_host': 'localhost',
      'local_port': 11978
    });
    await lt.open();
    print ("localtunnel created and exposed URL=${lt.url}");

    print ("trying GET ${lt.url}/helloworld ...");
    final response = await http.get(Uri.parse('${lt.url}/helloworld'));

    print("received status = ${response.statusCode}");
    if (response.statusCode == 200) {
      print("body = ${response.body}");
    } else {
      print('Error: ${response.statusCode}');
    }

    await lt.close();
    print("localtunnel closed.");
    await server.close(force: true);
    print("Dart Shelf server closed.");

  });

  test('create a tunnelSocket', ()  async {

    print('creating a tunnel socket');
    final tSocket = TunnelSocket();
    await tSocket.open();
    print ("tunnel socket created and exposed URL=${tSocket.url}");

    tSocket.listen((event) {
      String httpRequest = String.fromCharCodes(event);
      print("tunnel socket request received: $httpRequest");

      String httpResponse = 'HTTP/1.1 200 OK\r\n'
          'Content-Type: text/plain\r\n'
          'Content-Length: 12\r\n'
          '\r\n'
          'Hello, World';

      Uint8List buffer = Uint8List.fromList(httpResponse.codeUnits);
      tSocket.add(buffer);
      print("tunnel socket response sent");
    });

    print ("trying to send data to ${tSocket.url}");
    final response = await http.get(Uri.parse('${tSocket.url}'));

    print("received status = ${response.statusCode}");
    if (response.statusCode == 200) {
      print("body = ${response.body}");
    } else {
      print('Error: ${response.statusCode}');
    }

    await tSocket.close();
    print("tunnel socket closed.");

  });
}

shelf.Response helloWorldHandler(shelf.Request request) {
  print ("helloWorldHandler: received request!");
  print ("helloWorldHandler: method = ${request.method}");
  print ("helloWorldHandler: url = ${request.requestedUri.toString()}");
  print ("helloWorldHandler: params = ${request.params}");
  print ("helloWorldHandler: headers = ${request.headers}");
  return shelf.Response.ok('Hello, World!');
}



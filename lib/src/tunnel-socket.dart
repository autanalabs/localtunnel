
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class TunnelSocket {

  final dynamic opts;
  static const maxWait = Duration(seconds: 10);
  Socket? _socket;
  StreamController<Uint8List>? _stream;
  late final String clientId;
  late final String url;

  TunnelSocket({this.opts = const {
    'host': 'https://localtunnel.me'
  }});
  
  dynamic _getInfo(dynamic body) {
    final id = body['id'];
    final ip = body['ip'];
    final port = body['port'];
    final url = body['url'];
    final cachedUrl = body['cached_url'];
    final maxConnCount = body['max_conn_count'];

    final host = opts['host'];
    final localPort = opts['local_port'];
    final localHost = opts['local_host'];
    final localHttps = opts['local_https'];
    final localCert = opts['local_cert'];
    final localKey = opts['local_key'];
    final localCa = opts['local_ca'];
    final allowInvalidCert = opts['allow_invalid_cert'];

    return {
      'name': id,
      'url': url,
      'cachedUrl': cachedUrl,
      'maxConn': maxConnCount ?? 1,
      'remoteHost': Uri.parse(host).host,
      'remoteIp': ip,
      'remotePort': port,
      'localPort': localPort,
      'localHost': localHost,
      'localHttps': localHttps,
      'localCert': localCert,
      'localKey': localKey,
      'localCa': localCa,
      'allowInvalidCert': allowInvalidCert,
    };
  }

  Future<dynamic> _init() async {
    final baseUri = '${opts['host']}/';
    final assignedDomain = opts['subdomain'];
    final uri = '$baseUri${assignedDomain ?? '?new'}';

    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode != 200) {
        throw Exception('Error del servidor localtunnel');
      }

      final body = jsonDecode(response.body);
      final info = _getInfo(body);
      return info;

    } catch (e) {
      print('Error: $e');
      // Reintentar o manejar el error
    }
  }

  Future<void> open() async {

    dynamic info = await _init();
    clientId = info['name'];
    url = info['url'];

    final remoteHostOrIp = info['remoteIp'] ?? info['remoteHost'];
    final remotePort = info['remotePort'];
    _socket = await _createSocket(remoteHostOrIp, remotePort);
    _stream = StreamController<Uint8List>();
    _socket!.listen((data) {
      _stream!.add(data);
    });
  }

  Future<Socket> _createSocket(host, port) async => Socket.connect(host, port, timeout: maxWait)
      .timeout(maxWait, onTimeout: () {
    print("ERROR ON SOCKET TIMEOUT");
    return Socket.connect(host, port);
  }).catchError((e) {
    print("ERROR ON SOCKET $e");
    return Socket.connect(host, port);
  }).onError((error, stackTrace) {
    print("ERROR ON SOCKET $error");
    return Socket.connect(host, port);
  });

  Future<void> close() async {
    if (_socket != null) {
      await Future.wait([_socket!.close(), _stream!.close()]);
      _socket!.destroy();
      _socket = null;
      _stream = null;
    }
  }

  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    if (_stream != null) {
      return _stream!.stream.listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError
      );
    } else {
      throw Exception("Socket not open");
    }
  }

  void add(Uint8List data) {
    if (_socket != null) {
      _socket!.add(data);
    } else {
      throw Exception("Socket not open");
    }
  }

}
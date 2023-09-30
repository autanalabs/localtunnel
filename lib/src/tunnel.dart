
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './tunnel-cluster.dart';

class Tunnel {
  final dynamic opts;
  bool _closed = true;
  late final String clientId;
  late final String url;
  late final String cachedUrl;
  late final TunnelCluster cluster;

  Tunnel({this.opts = const {}}) {
    if (opts['host'] == null) {
      opts['host'] = 'https://localtunnel.me';
    }
  }

  bool get closed => _closed;

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
    final params = {'responseType': 'json'};
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

  void _stablish(dynamic info) {
    cluster = TunnelCluster(info);
    cluster.open();
    _closed = false;
  }

  Future<void> open() async {
    try {
      dynamic info = await _init();
      clientId = info['name'];
      url = info['url'];
      _stablish(info);
    } catch (e) {
      print('Error: $e');
    }
  }

  void close() {
    if (!_closed) {
      cluster.close();
      _closed = true;
    }
  }
}

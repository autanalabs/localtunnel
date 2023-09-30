
import 'dart:io';

class TunnelCluster {
  static const maxWait = Duration(seconds: 10);
  dynamic _opts;
  List<Socket> _bridge = [];

  TunnelCluster([this._opts = const {}]);

  void open() async {

    final opt = _opts;

    final remoteHostOrIp = opt['remoteIp'] ?? opt['remoteHost'];
    final remotePort = opt['remotePort'];
    final localHost = opt['localHost'] ?? 'localhost';
    final localPort = opt['localPort'];

    Future<Socket> remote = _createSocket(remoteHostOrIp, remotePort);
    Future<Socket> local = _createSocket(localHost, localPort);

    _bridge = await Future.wait([remote, local]);
    _bridgeSockets(_bridge[0], _bridge[1]);
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

  void _bridgeSockets(Socket socket1, Socket socket2) {
    socket1.listen((data) {
      socket2.add(data);
    });

    socket2.listen((data) {
      socket1.add(data);
    });
  }

  void close() {
    if (_bridge.isNotEmpty) {
      _bridge[0].close();
      _bridge[1].close();
    }
  }

}
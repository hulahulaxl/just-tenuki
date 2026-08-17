import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tree.dart';
import 'protocol.dart';

class EngineClient {
  WebSocketChannel? _channel;
  final _responseController = StreamController<EngineResponse>.broadcast();
  int _nextQueryId = 1;
  bool _isConnected = false;

  /// Exposes the live stream of KataGo evaluations to the UI
  Stream<EngineResponse> get updates => _responseController.stream;

  bool get isConnected => _isConnected;

  /// Connects to the local Go server
  void connect({String url = 'ws://localhost:8080/ws'}) {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          if (message is Uint8List) {
            _handleBinaryMessage(message);
          } else if (message is List<int>) {
            // Some platforms return List<int> instead of Uint8List
            _handleBinaryMessage(Uint8List.fromList(message));
          }
        },
        onDone: () {
          _isConnected = false;
          _channel = null;
        },
        onError: (error) {
          _isConnected = false;
          _channel = null;
        },
      );
    } catch (e) {
      _isConnected = false;
      _channel = null;
    }
  }

  int _latestQueryId = 0;

  void _handleBinaryMessage(Uint8List bytes) {
    if (bytes.isEmpty) return;

    // OpCode 0x02 = Analysis Response
    if (bytes[0] == 0x02) {
      EngineResponse? response = BinaryProtocol.decodeAnalyzeResponse(bytes);
      // Ignore trailing responses from older queries in KataGo's pipeline!
      if (response != null && response.queryId == _latestQueryId) {
        _responseController.add(response);
      }
    }
  }

  /// Sends the current board state to the server to begin infinite analysis
  void analyze(GameSession session) {
    if (!_isConnected || _channel == null) return;

    _latestQueryId = _nextQueryId++;
    Uint8List payload = BinaryProtocol.encodeAnalyzeRequest(
      _latestQueryId,
      session,
    );

    _channel!.sink.add(payload);
  }

  /// Disconnects from the server
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
  }
}

// Global singleton instance for easy access anywhere in the app
final engineClient = EngineClient();

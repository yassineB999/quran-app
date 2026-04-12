import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketDataSource {
  WebSocketChannel? _channel;
  final String _url;
  StreamController<Map<String, dynamic>>? _responseController;

  WebSocketDataSource({required String url}) : _url = url;

  Stream<Map<String, dynamic>> get responseStream {
    _responseController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _responseController!.stream;
  }

  Future<void> connect({int? surahId, List<Map<String, dynamic>>? words}) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      // Send session initialization if surahId is provided
      if (surahId != null) {
        final initMsg = <String, dynamic>{'type': 'init', 'surah_id': surahId};
        // Include word data so the AI service uses the same Warsh text
        // source as the Flutter UI, preventing text source mismatch
        if (words != null && words.isNotEmpty) {
          initMsg['words'] = words;
        }
        _channel!.sink.add(jsonEncode(initMsg));
      }

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _responseController?.add(data);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _responseController?.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _responseController?.close();
        },
      );
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
  }

  void sendAudioChunk(Uint8List data) {
    if (_channel != null) {
      _channel!.sink.add(data);
    }
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close(status.normalClosure);
      _channel = null;
    }
    await _responseController?.close();
    _responseController = null;
  }
}

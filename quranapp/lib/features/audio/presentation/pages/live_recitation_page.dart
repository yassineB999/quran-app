import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:quranapp/features/audio/data/datasources/websocket_data_source.dart';

class LiveRecitationPage extends StatefulWidget {
  const LiveRecitationPage({super.key});

  @override
  State<LiveRecitationPage> createState() => _LiveRecitationPageState();
}

class _LiveRecitationPageState extends State<LiveRecitationPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late WebSocketDataSource _webSocketDataSource;
  bool _isRecording = false;
  String _recognizedText = "Start reciting...";
  final List<String> _words = [];
  final Set<int> _errorIndices = {};

  // Changed to 192.168.3.153 to match your local network setup
  // This works regarding if you use Emulator or Real Device
  final String _wsUrl = 'ws://192.168.1.9:8000/ws/recite';

  @override
  void initState() {
    super.initState();
    _webSocketDataSource = WebSocketDataSource(url: _wsUrl);
  }

  @override
  void dispose() {
    _stopRecording();
    _webSocketDataSource.disconnect();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _webSocketDataSource.connect();

        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        setState(() {
          _isRecording = true;
          _recognizedText = "Listening...";
          _words.clear();
          _errorIndices.clear();
        });

        stream.listen((data) {
          _webSocketDataSource.sendAudioChunk(data);
        });

        _webSocketDataSource.responseStream.listen((data) {
          if (data['type'] == 'partial_result') {
            setState(() {
              _recognizedText = data['text'] ?? '';
              _updateWordsAndErrors();
            });
          }
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _updateWordsAndErrors() {
    // This is a mock logic for error highlighting based on the response
    // In a real scenario, the backend would send 'mistakes' indices
    _words.clear();
    _words.addAll(_recognizedText.split(' '));

    // Example: Highlight every 5th word as a "mistake" for demonstration
    // if backend logic isn't fully ready to send specific indices
    // Real implementation: _errorIndices = Set.from(data['mistakes']);
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    await _webSocketDataSource.disconnect();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Recitation (Tarteel-like)')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildQuranText(),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildQuranText() {
    if (_words.isEmpty) {
      return Center(
        child: Text(
          _recognizedText,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        runSpacing: 12,
        spacing: 8,
        children: List.generate(_words.length, (index) {
          final isError = _errorIndices.contains(index);
          return Text(
            _words[index],
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Amiri', // Assuming you have a Quran font
              color: isError ? Colors.red : Colors.black,
              fontWeight: isError ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        child: GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : Colors.green).withOpacity(
                    0.4,
                  ),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

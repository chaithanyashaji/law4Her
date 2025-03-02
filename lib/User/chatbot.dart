import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  List<Map<String, dynamic>> messages = [];
  bool _isListening = false;
  bool _isSpeaking = false;
  double _buttonSize = 56.0; // Default size of the button

  // Use your Hugging Face Spaces backend URL
  final String apiUrl = "https://chaithanyashaji-lawapi.hf.space/chat";

  // Function to send a message and get a response from the backend
  Future<void> sendMessage(String userMessage) async {
    setState(() {
      messages.insert(0, {
        'message': userMessage,
        'isUserMessage': true,
      });
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botMessage = data['answer'];

        setState(() {
          messages.insert(0, {
            'message': botMessage,
            'isUserMessage': false,
          });
        });
      } else {
        setState(() {
          messages.insert(0, {
            'message': "Error: Could not fetch response from the server.",
            'isUserMessage': false,
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.insert(0, {
          'message': "Error: Unable to connect to the server.",
          'isUserMessage': false,
        });
      });
    }
  }

  // Start listening for speech input
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (error) => print("Speech error: $error"),
    );

    if (available) {
      setState(() {
        _isListening = true;
        _buttonSize = 70.0; // Increase size when recording starts
      });
      _speech.listen(onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      });
    }
  }

  // Stop listening for speech input
  void _stopListening() {
    setState(() {
      _isListening = false;
      _buttonSize = 56.0; // Reset to default size when recording stops
    });
    _speech.stop();
  }

  // Speak the bot's response
  Future<void> _speak(String text) async {
    setState(() {
      _isSpeaking = true;
    });
    await _flutterTts.speak(text);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Stop speaking
  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF416d6d),
        iconTheme: const IconThemeData(color: Color(0xFFc5d0d3)),
        centerTitle: true,
        title: Image.asset(
          'assets/whitelogo.png',
          height: 80,
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message['isUserMessage']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message['isUserMessage']
                            ? const Color(0xFF416d6d).withOpacity(0.8)
                            : const Color(0xFF608e8e).withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: message['isUserMessage']
                              ? const Radius.circular(16)
                              : const Radius.circular(0),
                          bottomRight: message['isUserMessage']
                              ? const Radius.circular(0)
                              : const Radius.circular(16),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'],
                            style: TextStyle(
                              color: message['isUserMessage']
                                  ? Colors.white
                                  : const Color(0xFF1e1e2a),
                              fontSize: 14,
                            ),
                          ),
                          if (!message['isUserMessage'])
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _speak(message['message']),
                                  icon: const Icon(
                                    Icons.volume_up,
                                    color: Color(0xFF416d6d),
                                  ),
                                  label: const Text(
                                    "Read Out",
                                    style: TextStyle(color: Color(0xFF416d6d)),
                                  ),
                                ),
                                if (_isSpeaking)
                                  TextButton.icon(
                                    onPressed: _stopSpeaking,
                                    icon: const Icon(
                                      Icons.stop,
                                      color: Color(0xFF416d6d),
                                    ),
                                    label: const Text(
                                      "Stop",
                                      style: TextStyle(color: Color(0xFF416d6d)),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input Bar
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF416d6d),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                // Speech Input Button
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFF608e8e)
                          : const Color(0xFF416d6d),
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                        BoxShadow(
                          color:
                          const Color(0xFF608e8e).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: const Color(0xFFc5d0d3),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                // TextField
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFFc5d0d3)),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Color(0xFFc5d0d3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                // Send Button
                GestureDetector(
                  onTap: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF608e8e),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Color(0xFFc5d0d3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
